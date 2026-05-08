#!/bin/sh

apk update
apk add --no-cache sshpass openssh-client bash

rc-update add sshd
service sshd start

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
