#/bin/sh 

rm -rf tmp
mkdir tmp

./coordinator.sh
./ticket.sh
./trip.sh
./run.sh
