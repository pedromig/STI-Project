#!/usr/bin/env sh
#  Copyright © 2022 Pedro Rodrigues
#            © 2022 Joana Brás
#       __  _            _                   _     
#      / /_| | ___ _ __ | | ___  _   _   ___| |__  
#     / / _` |/ _ \ '_ \| |/ _ \| | | | / __| '_ \ 
#  _ / / (_| |  __/ |_) | | (_) | |_| |_\__ \ | | |
# (_)_/ \__,_|\___| .__/|_|\___/ \__, (_)___/_| |_|
#                 |_|            |___/             

# Paths to the configuration files
LOLXD="lolxd"

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
  echo "  -c, --coimbra     Configure Coimbra (server) VM/Machine"
  echo "  -l, --lisbon      Configure Lisbon (server) VM/Machine"
  echo "  -w, --warrior     Configure Road Warrior VM/Machine"
  echo "\nCopyright © 2022 Pedro Rodrigues\n\t  © 2022 Joana Brás" 
}

# Coimbra Server Configurations
coimbra() {
  echo "Coimbra"
}

# Lisbon Server Configurations
lisbon() {
  echo "Lisbon"
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
