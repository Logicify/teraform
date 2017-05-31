#!/bin/bash

FSTAB_RECORD=`cat /etc/fstab | grep store`
CLEAR_OS_INSTALLED=`cat /etc/centos-release | grep ClearOS`

echo ""
if [ -z "$FSTAB_RECORD" ] || [ -z "$CLEAR_OS_INSTALLED" ]; then
    echo "Welcome, in order to start initialization process run the following as root:"
    if [ -z "$FSTAB_RECORD" ]; then
        echo "  * mount-ebs /dev/xvdb /store"
    fi
    if [ -z "$CLEAR_OS_INSTALLED" ]; then
        echo "  * centos-to-clearos"
    fi
else
    echo "Welcome to ClearOS"
    echo ""
    echo "Configuration location:"
    echo "  * LDAP: /store/ldap"
    echo "  * DNS: /store/dnsmasq"
    echo "  * VPN: /store/openvpn"
    echo ""
fi
