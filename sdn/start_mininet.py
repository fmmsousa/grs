#!/usr/bin/env python3

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.log import setLogLevel

class SimpleTopo(Topo):
    def build(self):
        switch = self.addSwitch('s1')
        for i in range(1, 4):
            host = self.addHost(f'h{i}')
            self.addLink(host, switch)

if __name__ == '__main__':
    setLogLevel('info')
    topo = SimpleTopo()
    net = Mininet(topo=topo, controller=None)
    net.addController('ryu', controller=RemoteController, ip='127.0.0.1', port=6653)
    net.start()
    net.pingAll()
    CLI(net)
    net.stop()

