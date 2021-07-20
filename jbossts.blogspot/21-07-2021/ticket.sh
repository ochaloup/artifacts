#/bin/sh

cd tmp
mvn io.quarkus:quarkus-maven-plugin:2.0.1.Final:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=ticket \
    -DclassName="org.acme.ticket.TicketResource" \
    -Dpath="/tickets" \
    -Dextensions="resteasy,rest-client"

cd ticket

# we need a ticket service so that remote clients can invoke the application using MicroProfile Client:
cat << EOF > src/main/java/org/acme/ticket/TicketService.java
package org.acme.ticket;

import javax.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class TicketService {
    public String bookTicket() {
        return "1234";
    }
}
EOF

# inject this service into the generated resource source file (src/main/java/org/acme/ticket/TicketResource.java) and add a bookTicket method which uses the injected service (don't forget to inlcude the relevant import statements):
cat << EOF > src/main/java/org/acme/ticket/TicketResource.java
package org.acme.ticket;

import javax.inject.Inject;

import static javax.ws.rs.core.MediaType.APPLICATION_JSON;

// import annotation definitions
import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;
import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
// import the definition of the LRA context header
import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;

// import some JAX-RS types
import javax.ws.rs.GET;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Response;
import javax.ws.rs.HeaderParam;

@Path("/tickets")
@Produces(APPLICATION_JSON)
public class TicketResource {

    @Inject
    TicketService service;

    @GET
    @Path("/book")
    @LRA(value = LRA.Type.REQUIRED, end = false) // an LRA will be started before method execution if none exists and will not be ended after method execution
    public Response bookTicket(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("TicketResource.bookTicket: %s%n", lraId);
        String ticket = service.bookTicket();
        return Response.ok(ticket).build();
    }

    // ask to be notified if the LRA closes:
    @PUT // must be PUT
    @Path("/complete")
    @Complete
    public Response completeWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("TicketResource.completeWork: %s%n", lraId);
        return Response.ok().build();
    }

    // ask to be notified if the LRA cancels:
    @PUT // must be PUT
    @Path("/compensate")
    @Compensate
    public Response compensateWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("TicketResource.compensateWork: %s%n", lraId);
        return Response.ok().build();
    }
}
EOF

cat << EOF > src/test/java/org/acme/ticket/TicketResourceTest.java
package org.acme.ticket;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class TicketResourceTest {

    @Test
    public void testHelloEndpoint() {
        given()
          .when().get("/tickets/book")
          .then()
             .statusCode(200)
             .body(is("1234"));
    }
}
EOF

# we will need two microservices, let's configure the ticket service to run on port 8081:

cat << EOF >> src/main/resources/application.properties
quarkus.arc.exclude-types=io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantRegistry,io.narayana.lra.filter.ServerLRAFilter,io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantResource
quarkus.http.port=8081
quarkus.http.test-port=8081
EOF

# skip the tests
rm src/test/java/org/acme/ticket/*

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
