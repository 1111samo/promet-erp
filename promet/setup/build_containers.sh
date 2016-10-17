#!/bin/bash
cd /tmp
git clone http://192.168.177.120:10080/promet/promet-client-docker.git
cd promet-client-docker
cat ./Dockerfile.template | \
  sed -e "s/VERSION/$BUILD_VERSION/g"
  > Dockerfile
git commit -a -m "Dockerfile with Version updated"
git push origin master