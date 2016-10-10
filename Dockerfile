FROM ubuntu:14.04
ENV DEBIAN_FRONTEND noninteractive
RUN sudo apt-get update && sudo apt-get install -yq software-properties-common && \
  apt-key adv --keyserver keyserver.ubuntu.com \
  --recv BC19DDBA &&\
  add-apt-repository 'deb http://releases.galeracluster.com/ubuntu trusty main' &&\
  apt-get update && \
  apt-get install -yq socat &&\
  apt-get install -yq galera-arbitrator-3  
  
ENTRYPOINT ["/usr/bin/garbd"]
