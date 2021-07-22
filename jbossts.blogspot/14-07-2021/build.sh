#/bin/sh 

if [ -d tmp ]; then
  echo about to delete the directory tmp in the current working directory
  echo "is this okay (y/n)?"
  read ok

  if [ $ok != y ]; then
    echo exiting immediately
    exit 1
  fi
fi

rm -rf tmp
mkdir tmp

./coordinator.sh
./hello.sh
./run.sh
