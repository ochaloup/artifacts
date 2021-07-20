#/bin/sh

cd tmp
mvn io.quarkus:quarkus-maven-plugin:2.0.1.Final:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=narayana-lra-coordinator \
    -Dextensions="resteasy-jackson,rest-client"
cd narayana-lra-coordinator

# add narayana LRA to the pom:

read -r -d '' TXT << EOM
    <dependencies>
      <dependency>
        <groupId>org.jboss.narayana.rts<\/groupId>
        <artifactId>lra-coordinator-jar<\/artifactId>
        <version>5.12.0.Final<\/version>
      <\/dependency>
EOM

TXT=$(echo $TXT|tr -d '\n')

sed -i  "0,/<dependencies>/! {0,/<dependencies>/ s/<dependencies>/$TXT/}" pom.xml

rm -rf src
./mvnw clean package
