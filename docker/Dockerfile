FROM ubuntu:trusty
  RUN \
    apt-get update && \
    apt-get install -yq software-properties-common && \
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
    add-apt-repository 'deb [arch=amd64,i386] http://mirror.edatel.net.co/mariadb/repo/10.1/ubuntu trusty main' && \
    apt-get update && \
    apt-get install -yq \
      mariadb-server 
