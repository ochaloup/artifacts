#/bin/sh 

#Start a coordinator and both applications:
java -Dquarkus.http.port=8080 -jar tmp/narayana-lra-coordinator/target/quarkus-app/quarkus-run.jar &
pid1=$!
java -Dquarkus.http.port=8081 -jar tmp/narayana-lra-quickstart/target/quarkus-app/quarkus-run.jar &
pid2=$!

sleep 2

#And test the hello method using curl.
curl http://localhost:8081/hello
# terminate the coordinator and hello services
kill $pid1 $pid2

