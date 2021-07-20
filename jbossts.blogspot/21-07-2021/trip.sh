#/bin/sh

cd tmp
# Now we will create a second microservice that will inovoke the bookTrip method:
mvn io.quarkus:quarkus-maven-plugin:2.0.1.Final:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=trip \
    -DclassName="org.acme.trip.TripResource" \
    -Dpath="/trips" \
    -Dextensions="resteasy,rest-client"

cd trip

# we need a Ticket interface for making remote calls on the Ticket service we created in the Ticket app (quarkus supports MicroProfile REST Client):

cat << EOF > src/main/java/org/acme/trip/TicketService.java
package org.acme.trip;

import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

@Path("/tickets")
@Produces(MediaType.APPLICATION_JSON)
@RegisterRestClient
public interface TicketService {

    @GET
    @Path("/book")
    String bookTicket();
}
EOF

cat << EOF > src/main/java/org/acme/trip/TripResource.java
package org.acme.trip;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Response;

import static javax.ws.rs.core.MediaType.APPLICATION_JSON;

// import annotation definitions
import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;
import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
// import the definition of the LRA context header
import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;

// import some JAX-RS types
import javax.ws.rs.PUT;
import javax.ws.rs.HeaderParam;

@Path("/trips")
@Produces(APPLICATION_JSON)
public class TripResource {

    @Inject
    TripService service;

    // annotate the bookTrip method so that it will run in an LRA:
    @GET
    @LRA(LRA.Type.REQUIRED) // an LRA will be started before method execution and ended after method execution
    @Path("/book")
    public Response bookTrip(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("TripResource.bookTrip: %s%n", lraId);
        String ticket = service.bookTrip();
        return Response.ok(ticket).build();
    }

    // ask to be notified if the LRA closes:
    @PUT // must be PUT
    @Path("/complete")
    @Complete
    public Response completeWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("TripResource.completeWork: %s%n", lraId);
        return Response.ok().build();
    }

    // ask to be notified if the LRA cancels:
    @PUT // must be PUT
    @Path("/compensate")
    @Compensate
    public Response compensateWork(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) String lraId) {
        System.out.printf("TripResource.compensateWork: %s%n", lraId);
        return Response.ok().build();
    }
}
EOF

# and we need also need a TripService. The TripService will make calls on the remote TicketService using an injected @RestClient that implements the TicketService we have just defined:

cat << EOF > src/main/java/org/acme/trip/TripService.java
package org.acme.trip;

import org.eclipse.microprofile.rest.client.inject.RestClient;
import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;

@ApplicationScoped
public class TripService {

    @Inject
    @RestClient
    TicketService ticketService;

    String bookTrip() {
        return ticketService.bookTicket();
    }
}
EOF

# skip the tests
rm src/test/java/org/acme/trip/*

cat << EOF >> src/main/resources/application.properties
quarkus.arc.exclude-types=io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantRegistry,io.narayana.lra.filter.ServerLRAFilter,io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantResource
quarkus.http.port=8082
quarkus.http.test-port=8082

org.acme.trip.TicketService/mp-rest/url=http://localhost:8081
org.acme.trip.TicketService/mp-rest/scope=javax.inject.Singleton
EOF

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
