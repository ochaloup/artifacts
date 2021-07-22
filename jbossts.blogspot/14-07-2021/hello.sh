#/bin/sh

cd tmp
mvn io.quarkus:quarkus-maven-plugin:2.0.1.Final:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=narayana-lra-quickstart \
    -Dextensions="resteasy-jackson,rest-client"
cd narayana-lra-quickstart

# update the generated hello resource to include support for Long Running Actions
cat << EOF > src/main/java/org/acme/GreetingResource.java
package org.acme;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

// import annotation definitions
import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;
import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
// import the definition of the LRA context header
import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;

// import some JAX-RS types
import javax.ws.rs.PUT;
import javax.ws.rs.core.Response;
import javax.ws.rs.HeaderParam;

@Path("/hello")
public class GreetingResource {

    @GET
    @Produces(MediaType.TEXT_PLAIN) 
    @LRA(value = LRA.Type.REQUIRED) // an LRA will be started before method execution if none exists and will end after method returns
    public String hello(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("GreetingResource.hello: %s%n", lraId);
        return "Hello RESTEasy";
    }

    // ask to be notified if the LRA closes:
    @PUT // must be PUT
    @Path("/complete")
    @Complete
    public Response completeWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("GreetingResource.completeWork: %s%n", lraId);
        return Response.ok().build();
    }

    // ask to be notified if the LRA cancels:
    @PUT // must be PUT
    @Path("/compensate")
    @Compensate
    public Response compensateWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("GreetingResource.compensateWork: %s%n", lraId);
        return Response.ok().build();
    }
}
EOF

# configure the greeting service to run on port 8081:
cat << EOF >> src/main/resources/application.properties
quarkus.arc.exclude-types=io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantRegistry,io.narayana.lra.filter.ServerLRAFilter,io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantResource
quarkus.http.port=8081
quarkus.http.test-port=8081
EOF

# skip the tests
rm src/test/java/org/acme/*

# add microprofile LRA to the pom:

read -r -d '' TXT << EOM
    <dependencies>
      <dependency>
        <groupId>org.eclipse.microprofile.lra<\/groupId>
        <artifactId>microprofile-lra-api<\/artifactId>
        <version>1.0<\/version>
      <\/dependency>
      <dependency>
        <groupId>org.jboss.narayana.rts<\/groupId>
        <artifactId>narayana-lra<\/artifactId>
        <version>5.12.0.Final<\/version>
      <\/dependency>
EOM

TXT=$(echo $TXT|tr -d '\n')

sed -i  "0,/<dependencies>/! {0,/<dependencies>/ s/<dependencies>/$TXT/}" pom.xml

./mvnw clean package -DskipTests
