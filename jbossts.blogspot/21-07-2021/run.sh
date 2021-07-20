#/bin/sh 

#Start a coordinator and both applications:
java -Dquarkus.http.port=8080 -jar tmp/narayana-lra-coordinator/target/quarkus-app/quarkus-run.jar &
pid1=$!
java -jar tmp/ticket/target/quarkus-app/quarkus-run.jar &
pid2=$!
java -jar tmp/trip/target/quarkus-app/quarkus-run.jar &
pid3=$!

#And test the bookTrip method using curl. We set the property `quarkus.http.port` to 8082 in the application.properties file and the endpoint in the TripResource.java file is "/trips/book":
sleep 2
# The book ticket method will be available on port 8081 with the path /tickets/book. Test it using curl:
#curl http://localhost:8081/tickets/book
# The book trip method will be available on port 8082 with the path /ttrips/book. Test it using curl:
curl http://localhost:8082/trips/book
kill $pid1 $pid2 $pid3

