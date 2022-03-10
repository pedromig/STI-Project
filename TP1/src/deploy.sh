#!/usr/bin/env sh
#  Copyright © 2022 Pedro Rodrigues
#            © 2022 Joana Brás
#       __  _            _                   _     
#      / /_| | ___ _ __ | | ___  _   _   ___| |__  
#     / / _` |/ _ \ '_ \| |/ _ \| | | | / __| '_ \ 
#  _ / / (_| |  __/ |_) | | (_) | |_| |_\__ \ | | |
# (_)_/ \__,_|\___| .__/|_|\___/ \__, (_)___/_| |_|
#                 |_|            |___/             

# Paths to the configuration files and global variables

## Coimbra
### CA
COIMBRA_SSL_CONF="coimbra/openssl.cnf"

COIMBRA_CA_CERT_ENTITIES="apache coimbra-vpn warrior-client lisboa-vpn coimbra-client"
COIMBRA_CA_CERT_ENTITIES_PKCS12="test-user"

### VPN
COIMBRA_VPN_SERVER_CONF="coimbra/server.conf"
COIMBRA_VPN_CLIENT_CONF="coimbra/client.conf"

COIMBRA_VPN_SERVER_KEY="coimbra-vpn.key"
COIMBRA_VPN_CLIENT_KEY="coimbra-client.key"
COIMBRA_VPN_SERVER_CERT="coimbra-vpn.crt"
COIMBRA_VPN_CLIENT_CERT="coimbra-client.crt"

## Lisbon

### Apache
LISBON_APACHE_SSL_CONF="lisbon/apache-ssl.conf"
LISBON_APACHE_CONF="lisbon/apache.conf"
LISBON_HOSTS_FILE="lisbon/hosts"
LISBON_APACHE_INDEX_HTML="lisbon/index.html"

LISBON_APACHE_CERT="apache.crt"
LISBON_APACHE_CERT_KEY="apache.key"
LISBON_APACHE_CA_FILE="cacert.pem"

### VPN
LISBON_VPN_SERVER_KEY="lisboa-vpn.key"
LISBON_VPN_SERVER_CERT="lisboa-vpn.crt"
LISBON_VPN_TA_KEY="ta.key"

# Required Programs (packages downloadable with apt-get, 
# may be different for # other package managers)
# TODO: check requirements before running script
REQUIREMENTS="apache2 ssl a2enmod openvpn"

# Script output colorization
if echo "${TERM}" | grep -q "term" ; then
  RED=$(tput -Txterm setaf 1)
  GREEN=$(tput -Txterm setaf 2)
  BLUE=$(tput -Txterm setaf 4)
  RESET=$(tput -Txterm sgr0)
  BOLD=$(tput bold)
  NORM=$(tput sgr0)
fi

# Print terminal help text
help() {
  echo "${BOLD}Automate the deployment of MV/Machine configurations for this assignment.${NORM}"
  echo "${BOLD}Usage: ${BLUE}$0 [OPTION]... ${RESET}${NORM}\n"
  echo "OPTIONS:"
  echo "  -h, --help        Print this help message and exit"
  echo "  -c, --coimbra     Configure Coimbra CA/OCSP/VPN (server) VM/Machine"
  echo "  -l, --lisbon      Configure Lisbon Apache/VPN (server) VM/Machine"
  echo "  -w, --warrior     Configure Road Warrior VM/Machine"
  echo "\nCopyright © 2022 Pedro Rodrigues © 2022 Joana Brás" 
}

# Coimbra CA/OCSP/VPN Server Configurations
coimbra() {   
  # OpenSSL Config Directory
  ssldir="/etc/ssl"               # Path to the ssl config file directory

  # Openvpn Config Directory
  vpndir="/etc/openvpn"

  # OCSP Service Settings
  port=81
  logfile="log.txt"

  # VPN Settings
  dhbits=2048
  dhk="dh${dhbits}.pem"
  tak="ta.key"

  # CA Files
  keybits=2048                    # Number of bits for the private key 
  days=3650                       # Certificate validity
  capk="cakey.pem"                # CA RSA private key file name
  cacert="cacert.pem"             # CA certificate
  cacsr="ca.crt"                  # CA CSR (Certificates Signing Request)
  index="index.txt"

  # CA Directories
  cadir="/etc/pki/CA";            # Path to the CA main directory
  newcerts="/etc/pki/CA/newcerts" # Newly generated ceritificates go here
  certsdir="/etc/pki/CA/certs"    # Certitificates directory
  capriv="/etc/pki/CA/private"    # Path to the CA private key directory
  exportdir="/etc/pki/CA/export"  # Directory where pk12 certificates

  # Openssl and CA configuration deployment
  sudo cp -f "${COIMBRA_SSL_CONF}" "${ssldir}"
  sudo mkdir -p "${capriv}" "${certsdir}" "${newcerts}" "${exportdir}"

  # Private CA creation

  ## Generate CA RSA private key
  cd "${capriv}"
  sudo openssl genrsa \
      -out cakey.pem \
      -des3 "${keybits}"

  ## Create CA CSR (Certificate Signing Request)
  cd "${cadir}"
  sudo openssl req \
      -new -key "${privdir}/${capk}" \
      -out "${cacsr}" 

  ## Create self-signed CA certificate
  sudo openssl x509 \
      -req \
      -days "${days}" \
      -in "${cacsr}" \
      -out "${cacert}" \
      -signkey "${privdir}/${capk}"

  ## Setup files before issuing certificates
  sudo touch "${cadir}/index.txt ${cadir}/serial ${cadir}/crlnumber"
  sudo sh -c 'echo 01 > "${cadir}/serial"'
  sudo sh -c 'echo 01 > "${cadir}/crlnumber"'
 
  # Generate X.509 certificates for all the entities 
  for entity in ${COIMBRA_CA_CERT_ENTITIES}; do 

    ## Create entity private key
    cd "${capriv}"
    sudo openssl genrsa \
        -out "${entity}.key" \
        -des3 "${keybits}"
    
    ## Create Entity CSR (Certificate Signing Request) 
    cd "${cadir}"
    sudo openssl req \
        -new \
        -key "${privdir}/${entity}.key" \
        -out "${entity}.csr"

    ## Create X.509 certificate for this entity
    sudo openssl ca \
        -in "${entity}.csr" \
        -cert "${cacert}" \
        -keyfile "${capriv}/${capk}" \
        -out "${certsdir}/${entity}.crt"
  done 

  # Generate X.509 PKCS##12 certificates for all entities who need it 
  for entity in ${COIMBRA_CA_CERT_ENTITIES_PKCS12}; do 

    ## Export Key in the PKCS##12 format
    sudo openssl pkcs12 \
        -export \
        -out "${exportdir}/${entity}.p12" \
        -inkey "${capriv}/${entity}.key" \
        -in "${certs}/${entity}.crt" \
        -certfile "${cacert}"      
  done 

  # Setup VPN
  cd "${vpndir}"

  ## Copy requried files/certificates to the apropriate directories
  sudo openssl dhparam -out ${dhk} ${dhbits} 
  sudo openvpn --genkey tls-auth "${tak}"

  sudo cp -f "${certsdir}/${COIMBRA_VPN_SERVER_CONF}" "${vpndir}/server"
  sudo cp -f "${certsdir}/${COIMBRA_VPN_SERVER_CERT}" "${vpndir}/server"
  sudo cp -f "${capriv}/${COIMBRA_VPN_SERVER_KEY}" "${vpndir}/server"
  sudo cp -f "${tak}" "${vpndir}/server"
  sudo cp -f "${cadir}/${cacert}" "${vpndir}/server/ca.crt"
  sudo cp -f "${dhk}" "${vpndir}/server"
 
  sudo cp -f "${certsdir}/${COIMBRA_VPN_CLIENT_CONF}" "${vpndir}/client"
  sudo cp -f "${certsdir}/${COIMBRA_VPN_CLIENT_CERT}" "${vpndir}/client"
  sudo cp -f "${capriv}/${COIMBRA_VPN_CLIENT_KEY}" "${vpndir}/client"
  sudo cp -f "${LISBON_VPN_TA_KEY}" "${vpndir}/client"
  sudo cp -f "${cadir}/${cacert}" "${vpndir}/client/ca.crt"

  # Start systemd service daemon's
  sudo systemctl enable openvpn && sudo systemctl start openvpn

  ## NOTE: For the authentication required while setting up the 
  ## openvpn service you will be prompted for some passwords
  ## that can be inputed using the following tool:
  ## sudo systemd-tty-ask-password-agent
  sudo systemctl enable openvpn-server@server.service
  sudo systemctl start openvpn-server@server.service

  sudo systemctl enable openvpn-client@client.service
  sudo systemctl start openvpn-client@client.service

  # Activate OCSP Server (blocking process - exiting the shell will kill it)
  cd "${cadir}"
  sudo openssl ocsp \
      -index "${index}" \
      -port  "${port}" \
      -rsigner "${cacert}" \
      -rkey "${capriv}/${capk}" \
      -CA "${cacert}" \
      -text \
      -out "${logfile}" 
}

# Lisbon Server Configurations
lisbon() { 
  # Apache Config Directories
  sites="/etc/apache2/sites-available"
  public_html="/var/www/apache/public_html"

  # Certificate Related Directories 
  certdir="/etc/pki/CA/certs"
  keydir="/etc/pki/CA/private"
  cadir="/etc/pki/CA/"

  # Openvpn Config Directory
  vpndir="/etc/openvpn"

  # Enable Apache2 modules
  sudo e2enmod ssl
  
  # System Directories 
  etc="/etc"

  # VPN Settings
  keybits=2048                    # Number of bits for the private key 
  dhbits=2048
  dhk="dh${dhbits}.pem"
  tak="ta.key"

  ## Copy requried files/certificates to the apropriate directories
  sudo openssl dhparam -out "dh${dhbits}.pem" ${dhbits} 
  sudo openvpn --genkey tls-auth "${LISBON_VPN_TA_KEY}"


  sudo cp -f "${certdir}/${LISBON_VPN_SERVER_CONF}" "${vpndir}/server"
  sudo cp -f "${certdir}/${LISBON_VPN_SERVER_CERT}" "${vpndir}/server"
  sudo cp -f "${keydir}/${LISBON_VPN_SERVER_KEY}" "${vpndir}/server"
  sudo cp -f "${tak}" "${vpndir}/server"
  sudo cp -f "${cadir}/${LISBON_APACHE_CA_FILE}" "${vpndir}/server/ca.crt"
  sudo cp -f "${dhk}" "${vpndir}/server"

  # Start systemd service daemon's
  sudo systemctl enable openvpn && sudo systemctl start openvpn

  ## NOTE: For the authentication required while setting up the 
  ## openvpn service you will be prompted for some passwords
  ## that can be inputed using the following tool:
  ## sudo systemd-tty-ask-password-agent
  sudo systemctl enable openvpn-server@server.service
  sudo systemctl start openvpn-server@server.service

  # Setup VPN

  # Setup folders/files needed for the configuration deployment
  sudo mkdir -p "${certdir}" "${keydir}" "${cadir}"
  sudo cp -f "${LISBON_APACHE_SSL_CONF}" "${sites}"
  sudo cp -f "${LISBON_APACHE_CONF}" "${sites}"

  sudo mkdir -p "${public_html}"
  sudo cp -f ${LISBON_APACHE_INDEX_HTML} "${public_html}"
  sudo chown -R $USER:$USER "${public_html}" 
  sudo chmod -R 755 "${public_html}" 

  sudo cp -f "${LISBON_APACHE_CERT}" "${certdir}"
  sudo cp -f "${LISBON_APACHE_CERT_KEY}" "${keydir}"
  sudo cp -f "${LISBON_APACHE_CA_FILE}" "${cadir}"
  sudo cp -f "${LISBON_HOSTS_FILE}" "${etc}"

  # Start/Restart apache2 service after setting up config files
  sudo a2ensite "${LISBON_APACHE_SLL_CONF}"
  sudo a2ensite "${LISBON_APACHE_CONF}"
  sudo systemctl start apache2.service || sudo systemctl reload apache2.service
}

# Road Configurations
warrior() {
  # Certificate Related Directories 
  certdir="/etc/pki/CA/certs"
  keydir="/etc/pki/CA/private"
  cadir="/etc/pki/CA/"

  # System Directories 
  etc="/etc"

  # VPN Settings
  keybits=2048                    # Number of bits for the private key 
  dhbits=2048
  dhk="dh${dhbits}.pem"
  tak="ta.key"

  sudo cp -f "${WARRIOR_SSL_CONF}" "${ssldir}"
  sudo mkdir -p "${capriv}" "${certsdir}" "${newcerts}"

  sudo cp -f "${certsdir}/${WARRIOR_VPN_CLIENT_CONF}" "${vpndir}/client"
  sudo cp -f "${certsdir}/${WARRIOR_VPN_CLIENT_CERT}" "${vpndir}/client"
  sudo cp -f "${capriv}/${WARRIOR_VPN_CLIENT_KEY}" "${vpndir}/client"
  sudo cp -f "${WARRIOR_VPN_TA_KEY}" "${vpndir}/client"
  sudo cp -f "${cadir}/${cacert}" "${vpndir}/client/ca.crt"
}

if [ $# -eq 0 ]; then
  echo "${BOLD}Usage: ${BLUE}$0 [OPTION]...${RESET}${NORM}"
  echo "For more information run: $0 --help"
  exit 1;
fi

while [ $# -gt 0 ]; do
  option="$1";
  case "${option}" in
    -h | --help) help && shift       ;;
    -c | --coimbra) coimbra && shift ;;
    -l | --lisbon) lisbon && shift   ;;
    -w | --warrior) warrior && shift ;;
  esac
done && exit 0
