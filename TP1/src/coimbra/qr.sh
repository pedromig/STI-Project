#!/usr/bin/env sh


su -c "google-authenticator -t -d -r3 -R30 -f -l 'OpenVPN Server' -s/etc/openvpn/google-authenticator/auth" - gauth
