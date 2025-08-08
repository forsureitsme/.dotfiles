#!/usr/bin/bash

echo Disabling unecessary services

sudo systemctl disable avahi-daemon.service

