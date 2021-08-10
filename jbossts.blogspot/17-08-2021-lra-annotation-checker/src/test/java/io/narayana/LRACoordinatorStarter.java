package io.narayana;

import org.jboss.logging.Logger;
import org.jboss.shrinkwrap.resolver.api.maven.Maven;
import org.junit.jupiter.api.extension.AfterAllCallback;
import org.junit.jupiter.api.extension.BeforeAllCallback;
import org.junit.jupiter.api.extension.ExtensionContext;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.concurrent.TimeUnit;

public class LRACoordinatorStarter implements BeforeAllCallback, AfterAllCallback {
    private static final Logger log = Logger.getLogger(LRACoordinatorStarter.class);

    private static final String NARAYANA_VERSION = "5.12.0.Final";
    private static Process process;

    @Override
    public void beforeAll(ExtensionContext extensionContext) throws Exception {
        File lraCoordinatorJar = Maven
                .resolver()
                .resolve("org.jboss.narayana.rts:lra-coordinator-quarkus:jar:runner:" + NARAYANA_VERSION)
                .withoutTransitivity()
                .asSingleFile();

        try {
            log.info("Starting " + lraCoordinatorJar.getAbsolutePath());
            process = Runtime.getRuntime().exec(
                    "java -jar " + lraCoordinatorJar.getAbsolutePath());

            process.waitFor(1, TimeUnit.SECONDS);
            BufferedReader output = new BufferedReader(new InputStreamReader(process.getInputStream()));
            boolean started = false; // waiting till lra coordinator is started
            while(!started) {
                while (output.ready()) {
                    String line = output.readLine();
                    log.info(line);
                    if (line.contains("lra-coordinator-quarkus")) started = true;
                }
            }
        } catch (IOException ioe) {
            throw new IllegalStateException("Cannot start lra coordinator " + lraCoordinatorJar, ioe);
        }
    }

    @Override
    public void afterAll(ExtensionContext extensionContext) throws Exception {
        if (process != null) {
            BufferedReader output = new BufferedReader(new InputStreamReader(process.getInputStream()));
            while (output.ready()) {
                log.info(output.readLine());
            }
            BufferedReader error = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            while (error.ready()) {
                log.error(error.readLine());
            }

            process.destroy();
            if (process.waitFor(5, TimeUnit.SECONDS)) {
                process.destroyForcibly();
            }
        }
    }
}
