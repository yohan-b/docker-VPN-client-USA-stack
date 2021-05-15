#!/bin/bash
# The commands below fix iptables -j MARK not working:
#type=AVC msg=audit(1546362201.768:148429): avc:  denied  { module_request } for  pid=11415 comm="iptables" kmod="ipt_MARK" scontext=system_u:system_r:container_t:s0:c283,c766 tcontext=system_u:system_r:kernel_t:s0 tclass=system
#
#       Was caused by:
#       The boolean domain_kernel_load_modules was set incorrectly. 
#       Description:
#       Allow domain to kernel load modules
#
#       Allow access by executing:
#       # setsebool -P domain_kernel_load_modules 1

sudo modprobe ipt_MARK
sudo modprobe l2tp_ppp
MODULE_FILE=/etc/modules-load.d/docker.conf
sudo bash -c "test -f $MODULE_FILE || touch $MODULE_FILE"
sudo bash -c "grep -q ipt_MARK $MODULE_FILE \
|| { echo '# Loading ipt_MARK at boot is needed to use iptables -j MARK in docker containers' >> $MODULE_FILE; \
     echo 'ipt_MARK' >> $MODULE_FILE; }"
sudo bash -c "grep -q l2tp_ppp $MODULE_FILE \
|| { echo '# Loading l2tp_ppp at boot is needed to use xl2tpd with kernel drivers in docker containers' >> $MODULE_FILE; \
     echo 'l2tp_ppp' >> $MODULE_FILE; }"

source vars
test -z $1 || HOST="_$1"
test -z $2 || INSTANCE="_$2"
sudo rm -f keys_privateinternetaccess/* 
test -f ~/secrets.tar.gz.enc || curl -o ~/secrets.tar.gz.enc "https://${CLOUD_SERVER}/s/${KEY}/download?path=%2F&files=secrets.tar.gz.enc"
openssl enc -aes-256-cbc -d -in ~/secrets.tar.gz.enc | sudo tar -zxv --strip 2 secrets/docker-VPN-client-USA-stack${HOST}${INSTANCE}/keys_privateinternetaccess secrets/docker-VPN-client-USA-stack${HOST}${INSTANCE}/users

rm -rf ~/config
git clone https://${GIT_SERVER}/yohan/config.git ~/config
test -f ~/config/docker-VPN-client-stack_serveur-appart_PIA-USA/post-up.sh \
&& sudo cp -a ~/config/docker-VPN-client-stack_serveur-appart_PIA-USA/post-up.sh ./ \
|| sudo bash -c 'echo "#!/bin/bash" > post-up.sh'
rm -rf ~/config

sudo chown root:13 users
sudo chown root:root entrypoint.sh post-up.sh
sudo chmod +x entrypoint.sh post-up.sh
sudo chown -R root. client_privateinternetaccess_US_East.conf keys_privateinternetaccess

# --force-recreate is used to recreate container when crontab file has changed
unset VERSION_PROXY VERSION_VPN_CLIENT VERSION_L2TP_CLIENT
VERSION_PROXY=$(git ls-remote https://${GIT_SERVER}/yohan/docker-proxy.git| head -1 | cut -f 1|cut -c -10) \
VERSION_VPN_CLIENT=$(git ls-remote https://${GIT_SERVER}/yohan/docker-VPN-client.git| head -1 | cut -f 1|cut -c -10) \
VERSION_L2TP_CLIENT=$(git ls-remote https://${GIT_SERVER}/yohan/docker-l2tp-client.git| head -1 | cut -f 1|cut -c -10) \
 sudo -E bash -c 'docker-compose up -d --force-recreate'

