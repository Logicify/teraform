#!/bin/bash -x

function link_external_storage() {
    STORAGE_PATH="$1"
    TARGET_PATH="$2"

    mkdir -p "$STORAGE_PATH"
    if [ -d "$TARGET_PATH" ] && [ "$(ls -A "$STORAGE_PATH")" ]; then
        echo "Skip $TARGET_PATH"
    else
        cp -r $TARGET_PATH/* "$STORAGE_PATH"
    fi
    rm -rf "$TARGET_PATH"
    ln -s $STORAGE_PATH $TARGET_PATH
}

(
ARCH=`arch`

# Storage config
# PKI
link_external_storage "/store/pki" "/etc/pki"

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

yum install -y app-openvpn app-openldap-directory app-administrators app-dns app-storage app-firewall app-firewall-custom

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

# LDAP
#link_external_storage "/store/ldap/data" "/var/lib/ldap"
#link_external_storage "/store/ldap/config" "/etc/openldap"
#mkdir -p /store/ldap/config/slapd.d
#chown -R ldap:ldap /store/ldap/data/*
#chown -R ldap:ldap /store/ldap/data
#chown -R ldap:ldap /store/ldap/config/*
#chown -R ldap:ldap /store/ldap/config
#chmod -R o+rw /store/ldap/data/
#chmod -R o+rw /var/lib/ldap/*
#setfacl -R -m u:ldap:rw /store/ldap
#setfacl -R -d -m u:ldap:rwx /store/ldap
#setfacl -R -m o:rwx /store/ldap
#setfacl -R -d -m o:rw /store/ldap
# Clearos
link_external_storage "/store/clearos_config" "/etc/clearos"
link_external_storage "/store/clearos_data" "/var/clearos"
chmod -R o+rw /store/clearos_data
chmod -R o+rw /store/clearos_config
# OpenVPN
link_external_storage "/store/openvpn" "/etc/openvpn"
# Dnsmasq
link_external_storage "/store/dnsmasq" "/etc/dnsmasq.d"

# Reboot
reboot

# Stop wizard: /app/base/wizard/stop