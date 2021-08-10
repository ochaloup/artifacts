package io.narayana;

import io.quarkus.test.junit.QuarkusTest;
import org.hamcrest.text.IsEmptyString;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.not;

@QuarkusTest
@ExtendWith(LRACoordinatorStarter.class)
public class LRAParticipantResourceTest {
    @Test
    public void testHelloEndpoint() {
        given()
          .when().get("/participant")
          .then()
             .statusCode(200)
             .body(not(IsEmptyString.emptyOrNullString()));
    }
}