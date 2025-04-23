FROM jasonrivers/nagios
RUN apt update && apt install -y nagios-nrpe-plugin vim iproute2 iputils-ping tcpdump iptables dnsutils curl
COPY sasl_passwd /etc/postfix/sasl_passwd
COPY sasl_passwd.db /etc/postfix/sasl_passwd.db
RUN rm /etc/postfix/main.cf
COPY main.cf /etc/postfix/main.cf
