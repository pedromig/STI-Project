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
COIMBRA_CA_CERT_ENTITIES="apache"
COIMBRA_CA_CERT_ENTITIES_PKCS12="apache"
COIMBRA_SSL_CONF="coimbra/openssl.cnf"

## Lisbon
LISBON_APACHE_SSL_CONF="lisbon/apache-ssl.conf"
LISBON_APACHE_CONF="lisbon/apache.conf"
LISBON_APACHE_INDEX_HTML="lisbon/index.html"
LISBOA_HOSTS_FILE="lisbon/hosts"
LISBOA_APACHE_CERT="apache.crt"
LISBOA_APACHE_CERT_KEY="apache.key"
LISBOA_APACHE_CA_FILE="cacert.pem"

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

  # CA Files
  keybits=2048                    # Number of bits for the private key 
  days=3650                       # Certificate validity
  capk="cakey.pem"                # CA RSA private key file name
  cacert="cacert.pem"             # CA certificate
  cacsr="ca.crt"                  # CA CSR (Certificates Signing Request)

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

  # Enable Apache2 modules
  sudo e2enmod ssl
  
  # System Directories 
  etc="/etc"

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

# Road Warriot Configurations
warrior() {
  echo "Road Warrior"
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
