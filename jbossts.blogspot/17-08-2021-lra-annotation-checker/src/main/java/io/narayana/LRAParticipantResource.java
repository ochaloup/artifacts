package io.narayana;

import io.narayana.lra.client.NarayanaLRAClient;
import org.eclipse.microprofile.lra.annotation.AfterLRA;
import org.eclipse.microprofile.lra.annotation.Compensate;
import org.eclipse.microprofile.lra.annotation.Complete;
import org.eclipse.microprofile.lra.annotation.Forget;
import org.eclipse.microprofile.lra.annotation.LRAStatus;
import org.eclipse.microprofile.lra.annotation.Status;
import org.eclipse.microprofile.lra.annotation.ws.rs.LRA;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.net.URI;

import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_CONTEXT_HEADER;
import static org.eclipse.microprofile.lra.annotation.ws.rs.LRA.LRA_HTTP_ENDED_CONTEXT_HEADER;

@Path("/participant")
public class LRAParticipantResource {

    @Inject
    NarayanaLRAClient narayanaLRAClient;

    @LRA
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String lraParticipantMethod(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) URI lraId) {
        System.out.println("Joining LRA " + lraId);
        return lraId.toASCIIString();
    }

    @Complete
    @GET // -- replace with JAX-RS @PUT annotation
    @Path("/complete")
    public void complete(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) URI lraId) {
        System.out.println("LRA " + lraId.toASCIIString() + " was completed");
    }

    // @Compensate // -- uncomment the annotation --
    @PUT
    @Path("/compensate")
    public void compensate(@HeaderParam(LRA_HTTP_CONTEXT_HEADER) URI lraId) {
        System.out.println("LRA " + lraId.toASCIIString() + " was compensated");
    }

    // @AfterLRA // -- uncomment the annotation --
    @PUT
    @Path("/afterlra")
    public void afterLRA(@HeaderParam(LRA_HTTP_ENDED_CONTEXT_HEADER) URI lraId, LRAStatus status) {
        System.out.println("LRA " + lraId.toASCIIString() + " was after LRA status " + status.toString()  + " reported");
    }

    @Status
    @GET
    @Path("/status")
    public Response status(@HeaderParam(LRA_HTTP_ENDED_CONTEXT_HEADER) URI lraId) {
        LRAStatus lraStatus = narayanaLRAClient.getStatus(lraId);
        System.out.println("LRA " + lraId + " status " + lraStatus);
        return Response.ok().entity(lraStatus.toString()).build();
    }

    @Forget
    public void forget() { // add method parameter: java.net.URI lraId
        // this method can be called by LRA coordinator to ensure the LRA can be forgotten
        // when the call is returned to coordinator it's considered that the participant finished cleaning
        // and do not mind the LRA instance
    }

    @Status
    @GET
    public void status2(@HeaderParam(LRA_HTTP_ENDED_CONTEXT_HEADER) URI lraId) { // -- delete this method completely --
    }
}