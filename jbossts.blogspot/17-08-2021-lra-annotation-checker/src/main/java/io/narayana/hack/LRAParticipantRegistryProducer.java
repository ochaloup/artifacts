package io.narayana.hack;

/**
 * Until the Narayana LRA Quarkus extension is merged
 * this is a way how to workaround LRA to work on Quarkus.
 */

import io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantRegistry;

import javax.enterprise.context.Dependent;
import javax.enterprise.inject.Produces;

@Dependent
public class LRAParticipantRegistryProducer {
    @Produces
    public LRAParticipantRegistry lraParticipantRegistry() {
        return new LRAParticipantRegistry();
    }
}
