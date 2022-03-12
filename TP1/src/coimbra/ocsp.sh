#!/usr/bin/env sh

######## SETTINGS #######

CADIR="/etc/pki/CA"
VPNDIR="/etc/openvpn"
OCSP="http://ocsp.coimbra.pt:81"

########################

[ "$1" -ne 0 ] && exit 0

cd "${VPNDIR}" 

if [ -n "{tls_serial_0}" ]; then
	status=$(openssl ocsp \
						-issuer "${CADIR}/cacert.pem" \
						-CA "${CADIR}/cacert.pem" \
						-url ${OCSP} \
						-serial "0x${tls_serial_0}" 2> /dev/null)
	if [ $? -eq 0 ]; then
		echo "[INFO]: OCSP Server Status: ${status}"
		echo "${status}" | grep -Fq "0x${tls_serial_0}: good" && exit 0
	fi
	echo "[ERROR]: openssl ocsp command failed!!"	
fi
exit 1

