#!/bin/sh

apk update
apk add --no-cache sshpass openssh-client bash

rc-update add sshd
service sshd start

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh

# generate keys on VM (optional, for VM-to-VM SSH)
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -C "vagrant@host" -b 2048 -f /home/vagrant/.ssh/id_rsa -N ""
fi

sudo chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
