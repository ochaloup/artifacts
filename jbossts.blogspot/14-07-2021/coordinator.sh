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

rm -rf src/main/java src/test

# place the transaction logs in the target directory
cat << EOF >> src/main/resources/jbossts-properties.xml
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
    <!-- unique id of an LRA coordinator -->
    <entry key="CoreEnvironmentBean.nodeIdentifier">1</entry>
    <!-- location of the LRA logs -->
    <entry key="ObjectStoreEnvironmentBean.objectStoreDir">tmp/narayana-lra-coordinator/target/lra-logs</entry>
    <!-- location of the communications store -->
    <entry key="ObjectStoreEnvironmentBean.communicationStore.objectStoreDir">tmp/narayana-lra-coordinator/target/lra-logs</entry>
</properties>
EOF

./mvnw clean package
