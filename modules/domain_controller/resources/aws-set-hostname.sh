#!/usr/bin/env bash

#    Utility for setting hostname defined explicitly or by prefix and AWS instance id.
#    Copyright (C) 2017 Dmitry Berezovsky
#
#    The MIT License (MIT)
#    Permission is hereby granted, free of charge, to any person obtaining
#    a copy of this software and associated documentation files
#    (the "Software"), to deal in the Software without restriction,
#    including without limitation the rights to use, copy, modify, merge,
#    publish, distribute, sublicense, and/or sell copies of the Software,
#    and to permit persons to whom the Software is furnished to do so,
#    subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be
#    included in all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


HOSTNAME_PREFIX=""
if [ $# -ge 1 ]
then
    HOSTNAME_PREFIX="$1"
else
    echo "Utility allows to set hostname defined explicitly or by prefix and AWS instance id.
It might be very useful for auto scaling groups when you want to name your VMs according to some convention.
    "
    echo ""
    echo "Usage: aws-set-hostname <prefix> [-s]"
    echo "       aws-set-hostname app-node         -> app-node-i-3225"
    echo "       aws-set-hostname app-node -s      -> app-node"
    exit 0
fi

if [ "$2" = "-s" ]; then
    HOSTNAME="${HOSTNAME_PREFIX}"
else
    INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
    HOSTNAME="${HOSTNAME_PREFIX}-${INSTANCE_ID}"
fi

echo "Hostname set to: ${HOSTNAME}"
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain
127.0.0.1   ${HOSTNAME}
EOF

sed -i "s|^HOSTNAME=.*$|HOSTNAME=${HOSTNAME}|" /etc/sysconfig/network

hostname "${HOSTNAME}"