#!/bin/bash

password=`date +%s | sha256sum | base64 | head -c 32 ; echo`

if [ -z "$1" ]; then
    template="default"
else
    template="$1"
fi

if [ -z "$2" ]; then
    pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`
    privDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/hostname | sed "s/.compute.internal//"`
else
    # hostname.domain
    pubDNS="$2"
    privDNS=`echo "$2" | sed "s/\..*$//"`
fi

cat << EOF > inventory
127.0.0.1
EOF

cat << EOF > "deploy.yml"
---
- hosts: 127.0.0.1
  connection: local

  vars:
    hostname: '$privDNS'
    password: '$password'
    #domain: '$pubDNS'
    sitename: '$pubDNS'
    template: '$template'
    type: 'prod'
    web_server: 'cherokee'
    db_type: 'postgresql'
    db_ip: '127.0.0.1'

  roles:
    - swap
    - common
    - cherokee
    - uwsgi
    - postgresql
    - configure
EOF

echo "Now running ansible-playbook"

# HOME=/root required due to https://github.com/ansible/ansible/issues/21562
HOME=/root /usr/local/bin/ansible-playbook -i inventory deploy.yml