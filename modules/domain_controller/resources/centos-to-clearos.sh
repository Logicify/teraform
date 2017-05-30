#!/bin/bash -x

(
ARCH=`arch`

# Storage config
mkdir -p /store/clearos_config
mkdir -p /store/clearos_data
ln -s /store/clearos_config /etc/clearos
ln -s /store/clearos_data /var/clearos
mkdir -p /store/openvpn
ln -s /store/openvpn /etc/openvpn
# PKI
mkdir -p /store/pki
if [ -d /etc/pki ]; then
    cp -r /etc/pki/* /store/pki/
    rm -rf /etc/pki
fi
ln -s /store/pki /etc/pki

# Prep release and repos
rpm -Uvh http://download2.clearsdn.com/marketplace/cloud/7/noarch/clearos-release-7-current.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-ClearOS-7

# Install and upgrade
yum --enablerepo=* clean all
yum --enablerepo=clearos-centos install -y --nogpgcheck app-base
yum --enablerepo=* clean all
service webconfig stop

yum --enablerepo=clearos-centos,clearos-centos-updates install -y --nogpgcheck app-accounts app-configuration-backup app-date app-groups app-language app-log-viewer app-marketplace app-process-viewer app-software-updates app-user-profile app-users app-ssh-server

yum-config-manager --enable clearos-epel
yum-config-manager --enable clearos-centos-extras
yum-config-manager --enable clearos-centos
yum-config-manager --enable clearos-centos-fasttrack clearos-centos-updates

yum install -y app-openvpn app-openldap-directory app-administrators app-dns app-storage

# Default networking
yum -y remove NetworkManager
echo "DEVICE=eth0" > /etc/sysconfig/network-scripts/ifcfg-eth0
echo "TYPE=\"Ethernet\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "ONBOOT=\"yes\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "USERCTL=\"no\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "BOOTPROTO=\"dhcp\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "PEERDNS=\"no\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i -e 's/^GATEWAYDEV=.*/GATEWAYDEV="eth0"/' /etc/sysconfig/network
sed -i -e 's/^EXTIF=.*/EXTIF="eth0"/' /etc/clearos/network.conf

//  echo "mode = standalone" > /var/clearos/mode/mode.conf
//  echo "driver = simple_mode" > /var/clearos/mode/driver.conf

service syswatch restart

sed -i -e 's/^MODE=.*/MODE="standalone"/' /etc/clearos/network.conf

# Start webconfig
service webconfig start

) 2>&1 | tee /var/log/clearos-installer.log

# Reboot
reboot

# Stop wizard: /app/base/wizard/stop