FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update && apt install -y \
    git \
    curl \
    net-tools \
    iputils-ping \
    python3 \
    python3-pip \
    python3-setuptools \
    openvswitch-switch \
    mininet \
    && apt clean

# Install Ryu from pip
RUN pip3 install ryu

# Copy scripts
COPY start_mininet.py /start_mininet.py
COPY flows.sh /flows.sh

CMD ["bash"]

