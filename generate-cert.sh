#!/bin/bash
mkdir -p /etc/ssl/novnc
openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/novnc/key.pem -out /etc/ssl/novnc/cert.pem -days 365 -nodes -subj "/CN=localhost"
