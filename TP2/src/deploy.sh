#!/usr/bin/env sh
#  Copyright © 2022 Pedro Rodrigues
#            © 2022 Joana Brás
#       __  _            _                   _     
#      / /_| | ___ _ __ | | ___  _   _   ___| |__  
#     / / _` |/ _ \ '_ \| |/ _ \| | | | / __| '_ \ 
#  _ / / (_| |  __/ |_) | | (_) | |_| |_\__ \ | | |
# (_)_/ \__,_|\___| .__/|_|\___/ \__, (_)___/_| |_|
#                 |_|            |___/             

SNORT_CONF="/home/sti/Documents/snort.conf"

# Network Scenario IPs

## Router Public IP
PUBLIC="193.137.128.1"
INTERNAL="10.20.20.4"
DMZ="10.10.10.4"

## External Service IPs
DNS2="193.137.16.75"
EDEN="193.136.212.1"

## Internal Network Service IPs
VPN_GW="10.10.10.4"
DNS="10.10.10.4"
SMTP="10.10.10.4"
MAIL="10.10.10.4"
WWW="10.10.10.4"

# DMZ IPs
DATASTORE="10.20.20.4"
KERBEROS="10.20.20.4"
FTP="10.20.20.4"

# Script output colorization
if echo "${TERM}" | grep -q "term" ; then
  RED=$(tput -Txterm setaf 1)
  GREEN=$(tput -Txterm setaf 2)
  YELLOW=$(tput -Txterm setaf 3)
  BLUE=$(tput -Txterm setaf 4)
  RESET=$(tput -Txterm sgr0)
  BOLD=$(tput bold)
  NORM=$(tput sgr0)
fi


# Print terminal help text
help() {
  echo -n "${BOLD}Automate the deployment of VM/Machine configurations for"
  echo    " this assignment.${NORM}"
  echo "${BOLD}Usage: ${BLUE}$0 [OPTION]... ${RESET}${NORM}\n"
  echo "OPTIONS:"
  echo "  -h, --help        Print this help message and exit"
  echo "  -s, --snort       Install the snort tool          " 
  echo "\nCopyright © 2022 Pedro Rodrigues © 2022 Joana Brás" 
}

[ $(whoami) = "root" ] || SUDO="/usr/bin/sudo"

if [ $# -eq 0 ]; then
  echo "${BOLD}Usage: ${BLUE}$0 [OPTION]...${RESET}${NORM}"
  echo "For more information run: $0 --help"
  exit 1;
fi

run-snort() {
${SUDO}
}

snort() {

echo "${BLUE}${BOLD}INSTALLING SNORT!${RESET}${NORM}"

echo "${GREEN}=> Installing required dependencies...${RESET}"
${SUDO} apt-get install -y libpcap-dev \
    libpcre2-dev libdnet-dev \
    libdnet libnetfilter-queue1 \
    libnetfilter-queue-dev \
    zlib1g-dev \
    build-essential \
    flex \
    bison \
    libdumbnet-dev \
    libdumbnet1 \
    libpcre++-dev \
    luajit \
    libluajit-5.1-dev \
    libssl-dev \
    wget

echo "${GREEN}=> Installing libdaq...${RESET}"
cd /usr/local/src

if [ ! -d "/usr/local/src/daq-2.0.7" ]; then 
	echo -n " ${YELLOW}-> Fetching libdaq source code...${RESET}"
	${SUDO} wget https://www.snort.org/downloads/snort/daq-2.0.7.tar.gz >/dev/null 2>&1
	echo "${GREEN} DONE!${RESET}"
	
	echo -n " ${YELLOW}-> Extracting libdaq source code tarball...${RESET}"
	${SUDO} tar zxvf daq-2.0.7.tar.gz > /dev/null
	${SUDO} rm -rf daq-2.0.7.tar.gz
	echo "${GREEN} DONE!${RESET}"
fi
cd daq-2.0.7

echo -n " ${YELLOW}-> Configuring libdaq build and enabling nfq module...${RESET}"
${SUDO} ./configure \
	--enable-sourcefire \
	--enable-nfq > /dev/null 2>&1
echo "${GREEN} DONE!${RESET}"

echo -n " ${YELLOW}-> Compiling and installing libdaq...${RESET}"
${SUDO} make -s --no-print-directory > /dev/null 2>&1 
${SUDO} make install -s > /dev/null 2>&1
echo "/usr/local/lib/daq" | ${SUDO} tee -a /etc/ld.so.conf > /dev/null 2>&1
${SUDO} ldconfig
echo "${GREEN} DONE!${RESET}"

echo "${GREEN}=> Installing Snort...${RESET}"
cd /usr/local/src

if [ ! -d "/usr/local/src/snort-2.9.19" ]; then 	
	echo -n " ${YELLOW}-> Fetching snort source code...${RESET}"
	${SUDO} wget https://www.snort.org/downloads/snort/snort-2.9.19.tar.gz \
		> /dev/null 2>&1
	echo "${GREEN} DONE!${RESET}"

	echo -n " ${YELLOW}-> Extracting libdaq source code tarball...${RESET}"
	${SUDO} tar zxvf snort-2.9.19.tar.gz > /dev/null
	${SUDO} rm -rf snort-2.9.19.tar.gz
	echo "${GREEN} DONE!${RESET}"
fi
cd snort-2.9.19

echo -n " ${YELLOW}-> Configuring snort build...${RESET}"
./configure \
    --enable-sourcefire \
    --with-daq-includes=/usr/local/lib \
    --with-daq-libraries=/usr/local/lib/daq \
    --prefix=/usr/local/snort > /dev/null 2>&1
echo "${GREEN} DONE!${RESET}"

echo -n " ${YELLOW}-> Compiling and installing snort...${RESET}"
${SUDO} make -s --no-print-directory > /dev/null 2>&1 
${SUDO} make install -s > /dev/null 2>&1
${SUDO} ln -sf /usr/local/snort/bin/snort /usr/sbin/snort
${SUDO} ln -sf /usr/local/snort/bin/snort /usr/bin
echo "${GREEN} DONE!${RESET}"

echo -n " ${YELLOW}-> Setup snort initial (default) configuration...${RESET}"
${SUDO} cp -R etc/ /etc/snort
echo "${GREEN} DONE!${RESET}"

echo -n " ${YELLOW}-> Create snort default folders...${RESET}"
${SUDO} mkdir -p /etc/snort/rules
${SUDO} mkdir -p /etc/snort/preproc_rules
${SUDO} mkdir -p /usr/local/lib/snort_dynamicpreprocessor
${SUDO} mkdir -p /usr/local/lib/snort_dynamicrules
${SUDO} mkdir -p /usr/local/lib/snort_dynamicengine
echo "${GREEN} DONE!${RESET}"

echo -n " ${YELLOW}-> Populating default folders with the default config...${RESET}"
${SUDO} touch /etc/snort/rules/white_list.rules
${SUDO} touch /etc/snort/rules/black_list.rules

${SUDO} cp src/dynamic-plugins/sf_engine/.libs/libsf_engine.* \
	/usr/local/lib/snort_dynamicengine/
${SUDO} cp src/dynamic-preprocessors/build/usr/local/snort/lib/snort_dynamicpreprocessor/* \
	/usr/local/lib/snort_dynamicpreprocessor/

${SUDO} cp "${SNORT_CONF}" /etc/snort/


echo "${GREEN} DONE!${RESET}"
echo "${BLUE}${BOLD}INSTALLATION COMPLETE!${RESET}${NORM}"
}

iptables_flush() {
  ${SUDO} iptables -F INPUT
  ${SUDO} iptables -P INPUT ACCEPT
  ${SUDO} iptables -F OUTPUT
  ${SUDO} iptables -P OUTPUT ACCEPT
  ${SUDO} iptables -F FORWARD
  ${SUDO} iptables -P FORWARD ACCEPT
  ${SUDO} iptables -t nat -F PREROUTING
  ${SUDO} iptables -t nat -F POSTROUTING
}

router_config() {
	echo "${BLUE}${BOLD}ROUTER SETUP!${RESET}${NORM}"

	$(command -v /usr/sbin/snort > /dev/null) || snort

	echo -n "${YELLOW}=> Enabling IPV4 forwarding...${RESET}"
  echo 1 | ${SUDO} tee /proc/sys/net/ipv4/ip_forward > /dev/null
	echo "${GREEN} DONE!${RESET}"

	echo -n "${YELLOW}=> Enabling ftp connection tracking module...${RESET}"
  ${SUDO} modprobe ip_conntrack_ftp
  ${SUDO} modprobe ip_nat_ftp
  ${SUDO} modprobe nfnetlink_queue
  echo 1 | ${SUDO} tee /proc/sys/net/netfilter/nf_conntrack_helper > /dev/null
	echo "${GREEN} DONE!${RESET}"
  
	echo -n "${YELLOW}=> Flushing firewall tables...${RESET}"
  iptables_flush && echo "${GREEN} DONE!${RESET}"

  # INPUT 
	echo -n "${YELLOW}=> Loading IPtables INPUT chain rules...${RESET}"

  ## DNS name resolution requests sent to outside servers — (responses)
  ${SUDO} iptables -A INPUT -p udp --sport domain -j ACCEPT
  ${SUDO} iptables -A INPUT -p tcp --sport domain -j ACCEPT

  ## SSH connections to the router system, originated at the VPN gateway 
  ## (vpn-gw). — (responses)
  ${SUDO} iptables -A INPUT -p tcp -s ${VPN_GW} --dport ssh -j ACCEPT

  ## SSH connections to the router system, originated at the internal network 
  ${SUDO} iptables -A INPUT -p tcp -i ens36 --dport ssh -j ACCEPT

  ## Login INPUT chain events
  ${SUDO} iptables -A INPUT -j LOG -m limit --limit 5/min\
       --log-level 4 --log-prefix 'IP INPUT DROP: '

  ## INPUT chain policy
  ${SUDO} iptables -P INPUT DROP
	echo "${GREEN} DONE!${RESET}"

  # OUTPUT
	echo -n "${YELLOW}=> Loading IPtables OUTPUT chain rules...${RESET}"

  ## DNS name resolution requests sent to outside servers.
  ${SUDO} iptables -A OUTPUT -p udp --dport domain -j ACCEPT
  ${SUDO} iptables -A OUTPUT -p tcp --dport domain -j ACCEPT

  ## SSH connections to the router system, originated at the VPN gateway 
  ## (vpn-gw)
  ${SUDO} iptables -A OUTPUT -p tcp -d ${VPN_GW} --sport ssh -j ACCEPT

  ## SSH connections to the router system, originated at the internal network 
  ${SUDO} iptables -A OUTPUT -p tcp --sport ssh -o ens36 -j ACCEPT

  ## Log OUTPUT chain events
  ${SUDO} iptables -A OUTPUT -j LOG -m limit --limit 5/min\
      --log-level 4 --log-prefix 'IP OUTPUT DROP: '

  ## OUTPUT chain policy
  ${SUDO} iptables -P OUTPUT DROP
	echo "${GREEN} DONE!${RESET}"

  # FORWARD 
	echo -n "${YELLOW}=> Loading IPtables FORWARD chain rules...${RESET}"

  ## NFQUEUE FORWARD chain rule (send packets for snort analysis)
  ${SUDO} iptables -A FORWARD -j NFQUEUE --queue-num 0

  ## The dns and dns2 servers should be able to synchronize the 
  ## contents of DNS zones. (already covered but for the sake of
  ## completeness)

  ${SUDO} iptables -A FORWARD -p tcp --dport domain \
      -d ${DNS} -o ens34 -s ${DNS2} -i ens33 -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp --dport domain \
      -s ${DNS} -i ens34 -d ${DNS2} -o ens33 -j ACCEPT

  ## Domain name resolutions using the `dns` server.
  ## The dns server should be able to resolve names using DNS servers 
  ## on the Internet (dns2 and others).

  ${SUDO} iptables -A FORWARD -p tcp -d ${DNS} -o ens34 \
      --dport domain -j ACCEPT  

  ${SUDO} iptables -A FORWARD -p udp -d ${DNS} -o ens34 \
      --dport domain -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -s ${DNS} -i ens34 \
      --sport domain -j ACCEPT  

  ${SUDO} iptables -A FORWARD -p udp -s ${DNS} -i ens34 \
      --sport domain -j ACCEPT


  ## SMTP connections to the smtp server. 
  ${SUDO} iptables -A FORWARD -p tcp -d ${SMTP} -o ens34 \
      --dport smtp -j ACCEPT

  ## POP and IMAP connections to the mail server.
  ${SUDO} iptables -A FORWARD -p tcp -d ${MAIL} -o ens34 \
      --dport pop3 -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -d ${MAIL} -o ens34 \
      --dport pop3s -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -d ${MAIL} -o ens34 \
      --dport imap -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -d ${MAIL} -o ens34 \
      --dport imaps -j ACCEPT

  ## HTTP and HTTPS connections to the www server.
  ${SUDO} iptables -A FORWARD -p tcp -d ${WWW} -o ens34 \
      --dport http -j ACCEPT

  ${SUDO} iptables -A FORWARD -p udp -d ${WWW} -o ens34 \
      --dport https -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -d ${WWW} -o ens34 \
      --dport https -j ACCEPT

  ## OpenVPN connections to the vpn-gw server
  ${SUDO} iptables -A FORWARD -p tcp -d ${VPN_GW} -o ens34 \
      --dport openvpn -j ACCEPT

  ${SUDO} iptables -A FORWARD -p udp -d ${VPN_GW} -o ens34 \
      --dport openvpn -j ACCEPT

  ## VPN clients connected to vpn-gw server should be able to 
  ## connect to the PostgreSQL service on the datastore server.
  ${SUDO} iptables -A FORWARD -p tcp -d ${DATASTORE} -o ens36 \
      -s ${VPN_GW} -i ens34 --dport postgres -j ACCEPT

  ## VPN clients connected to vpn-gw server should be able to connect 
  ## to Kerberos v5 service on the kerberos server. A maximum of 10 
  ## simultaneous connections are allowed.
  ${SUDO} iptables -A FORWARD -p tcp -m connlimit --connlimit-upto 10 \
      -d ${KERBEROS} -o ens36 -s ${VPN_GW} -i ens34 \
      --dport kerberos5 -j ACCEPT

  ${SUDO} iptables -A FORWARD -p udp -m connlimit --connlimit-upto 10 \
       -d ${KERBEROS} -o ens36 -s ${VPN_GW} -i ens34 \
       --dport kerberos5 -j ACCEPT

  ## FTP connections (active mode) to the ftp server.
  ${SUDO} iptables -A FORWARD -p tcp -i ens33 \
       -d ${FTP} -o ens36 --dport ftp -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -s ${FTP} -i ens36 \
       -o ens33 --sport ftp-data -j ACCEPT

  ## SSH connections to the datastore sever, but onl if originated at
  ## the eden or dns2 servers.
  ${SUDO} iptables -A FORWARD -p tcp -i ens33 -s ${DNS2} \
      -d ${DATASTORE} -o ens36 --dport ssh -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -i ens33 -s ${EDEN} \
      -d ${DATASTORE} -o ens36 --dport ssh -j ACCEPT

  ## Domain name resolutions using DNS (internal to outside)
  ${SUDO} iptables -A FORWARD -p tcp -s ${INTERNAL} -i ens36 \
      -o ens33 --dport domain -j ACCEPT  
  ${SUDO} iptables -A FORWARD -p udp -s ${INTERNAL} -i ens36 \
      -o ens33 --dport domain -j ACCEPT

  ## HTTP, HTTPS and SSH connections (internal to outside)
  ${SUDO} iptables -A FORWARD -p tcp -s ${INTERNAL} -i ens36 \
      -o ens33 --dport http -j ACCEPT

  ${SUDO} iptables -A FORWARD -p udp -s ${INTERNAL} -i ens36 \
      -o ens33 --dport https -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -s ${INTERNAL} -i ens36 \
      -o ens33 --dport https -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -s ${INTERNAL} -i ens36 \
      -o ens33 --dport ssh -j ACCEPT

  # FTP connections (in passive and active modes) to external FTP servers.
  ${SUDO} iptables -A FORWARD -p tcp -i ens36 \
        -s ${INTERNAL} -o ens33 --dport ftp -j ACCEPT

  ${SUDO} iptables -A FORWARD -p tcp -d ${INTERNAL} -o ens36 \
       -i ens33 --dport ftp-data -j ACCEPT

  ## FTP connections (passive mode), 
  ## Allow return of already established and related tcp 
  ## connections
  ${SUDO} iptables -A FORWARD -p tcp -m state \
      --state RELATED,ESTABLISHED -j ACCEPT 

  ## Allow return of already established and related udp
  ## connections
  ${SUDO} iptables -A FORWARD -p udp -m state \
      --state RELATED,ESTABLISHED -j ACCEPT 

  ## Log FORWARD chain events
  ${SUDO} iptables -A FORWARD -j LOG -m limit --limit 5/min\
      --log-level 4 --log-prefix 'IP FORWARD DROP: '

  ## FORWARD chain policy
  ${SUDO} iptables -P FORWARD DROP
	echo "${GREEN} DONE!${RESET}"


  # POSTROUTING (SNAT)
  echo -n "${YELLOW}=> Loading IPtables NAT POSTROUTING chain rules...${RESET}"
  
  ## The dns server should be able to resolve names using DNS servers 
  ## on the Internet (dns2 and others)
  ## The dns and dns2 servers should be able to synchronize the 
  ## contents of DNS zones.

  ${SUDO} iptables -t nat -A POSTROUTING -p tcp -o ens33 -s ${DNS} \
    --dport domain -j SNAT --to-source ${PUBLIC} 

  ${SUDO} iptables -t nat -A POSTROUTING -p udp -o ens33 -s ${DNS} \
    --dport domain -j SNAT --to-source ${PUBLIC} 

  ## Domain name resolutions using DNS (internal to outside)
  ${SUDO} iptables -t nat -A POSTROUTING -p tcp -o ens33 -s ${INTERNAL} \
        --dport domain -j SNAT --to-source ${PUBLIC}

  ${SUDO} iptables -t nat -A POSTROUTING -p udp -o ens33 -s ${INTERNAL} \
        --dport domain -j SNAT --to-source ${PUBLIC} 

  ## HTTP, HTTPS and SSH connections (internal to outside)
  ${SUDO} iptables -t nat -A POSTROUTING -p tcp -o ens33 -s ${INTERNAL} \
      --dport http -j SNAT --to-source ${PUBLIC} 

  ${SUDO} iptables -t nat -A POSTROUTING -p udp -o ens33 -s ${INTERNAL} \
      --dport http -j SNAT --to-source ${PUBLIC} 

  ${SUDO} iptables -t nat -A POSTROUTING -p tcp -o ens33 -s ${INTERNAL} \
      --dport https -j SNAT --to-source ${PUBLIC} 

  ${SUDO} iptables -t nat -A POSTROUTING -p tcp -o ens33 -s ${INTERNAL} \
      --dport ssh -j SNAT --to-source ${PUBLIC} 

  ## FTP connections (in passive and active modes) to external FTP servers.
  ${SUDO} iptables -t nat -A POSTROUTING -p tcp -o ens33 -s ${INTERNAL} \
      --dport ftp -j SNAT --to-source ${PUBLIC} 

  ## Log POSTROUTING chain events
  ${SUDO} iptables -t nat -A POSTROUTING -j LOG -m limit --limit 5/min\
        --log-level 4 --log-prefix 'POSTROUTING EVENT: '
	echo "${GREEN} DONE!${RESET}"

  # PREROUTING (DNAT)
  echo -n "${YELLOW}=> Loading IPtables NAT PREROUTING chain rules...${RESET}"

  ## Domain name resolutions using the `dns` server.
  ## The dns and dns2 servers should be able to synchronize the 
  ## contents of DNS zones.
  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport domain -j DNAT --to-destination ${DNS}  

  ${SUDO} iptables -t nat -A PREROUTING -p udp -i ens33 -d ${PUBLIC} \
      --dport domain -j DNAT --to-destination ${DNS}

  ## SMTP connections to the smtp server.
  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport smtp -j DNAT --to-destination ${SMTP} 

  ## POP and IMAP connections to the mail server.
  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport pop3 -j DNAT --to-destination ${MAIL} 

  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport pop3s -j DNAT --to-destination ${MAIL} 

  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport imap -j DNAT --to-destination ${MAIL} 

  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport imaps -j DNAT --to-destination ${MAIL}

  ## HTTP and HTTPS connections to the www server.
  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport http -j DNAT --to-destination ${WWW} 

  ${SUDO} iptables -t nat -A PREROUTING -p udp -i ens33 -d ${PUBLIC} \
      --dport http -j DNAT --to-destination ${WWW} 

  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport https -j DNAT --to-destination ${WWW} 

  ## OpenVPN connections to the vpn-gw server
  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport openvpn -j DNAT --to-destination ${VPN_GW}

  ${SUDO} iptables -t nat -A PREROUTING -p udp -i ens33 -d ${PUBLIC} \
      --dport openvpn -j DNAT --to-destination ${VPN_GW} 

  ## FTP connections (passive and active modes) to the ftp server.
  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
     --dport ftp -j DNAT --to-destination ${FTP} 

  ## SSH connections to the datastore sever, but onl if originated at
  ## the eden or dns2 servers.
  ${SUDO} iptables -t nat -A PREROUTING -p tcp -i ens33 -d ${PUBLIC} \
      --dport ssh -j DNAT --to-destination ${DATASTORE}

  ## Log PREROUTING chain events
  ${SUDO} iptables -t nat -A PREROUTING -j LOG -m limit --limit 5/min \
      --log-level 4 --log-prefix 'PREROUTING EVENT: '

	echo "${GREEN} DONE!${RESET}"

	echo "${BLUE}${BOLD}SETUP COMPLETE!${RESET}${NORM}"
}

while [ $# -gt 0 ]; do
  option="$1";
  case "${option}" in
    -h | --help) help && shift ;;
    -s | --snort) snort && shift ;;
		-rc | --router-config) router_config && shift ;;
    -rf | --router-flush) iptables_flush && shift ;;
  esac
done && exit 0
