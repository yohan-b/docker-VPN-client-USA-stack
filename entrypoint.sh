#!/bin/bash
# stop service and clean up here
function shut_down() {
/etc/init.d/squid stop
reset
echo "exited $0"
exit 0
}

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "shut_down" SIGINT SIGTERM SIGKILL

/bin/ip route change default via ${subnet}.2 dev eth0
bash -c '> /etc/resolv.conf'
echo "nameserver 80.67.169.12" >> /etc/resolv.conf
echo "100     toengine" >> /etc/iproute2/rt_tables
iptables -t mangle -A OUTPUT -p tcp --sport 3128 -j MARK --set-mark 01
ip rule add fwmark 01 lookup toengine
ip route add default via ${subnet}.1 table toengine
# start service in background here
/etc/init.d/squid start
while pidof squid > /dev/null
do
        sleep 3
done
shut_down

