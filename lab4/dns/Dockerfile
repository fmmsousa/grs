FROM ubuntu/bind9
RUN apt update && apt install -y vim iproute2 iputils-ping tcpdump iptables dnsutils curl nagios-nrpe-server nagios-plugins 
RUN rm /etc/nagios/nrpe.cfg
COPY nrpe.cfg /etc/nagios/nrpe.cfg

COPY start.sh /root/start.sh
ENTRYPOINT []
CMD /root/start.sh

