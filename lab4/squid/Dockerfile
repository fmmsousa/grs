FROM ubuntu/squid:latest
RUN apt update && apt install -y vim iproute2 iputils-ping

COPY squid.conf /etc/squid/squid.conf
