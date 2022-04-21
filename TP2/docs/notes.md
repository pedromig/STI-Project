# Usefulness

## Change iptables log file locations
```sh
echo "kern.warning /var/log/iptables.log" | sudo tee -a /etc/rsyslog.conf
sudo systemctl restart rsyslog.service
```

## Activate ftp connection tracking module permanently
```sh
sudo echo "nf_conntrack_ftp" | sudo tee /etc/modules-load.d/mod_ftp.cof
```

# IPTables
  * Assuming that the VPN service is powered by OpenVPN (uses udp, tcp)
  * Assuming that the SSH service is powered by OpenSSH (uses tcp)
  * HTTP and HTTPS (uses udp(HTTP /3), tcp)

## Filter 

### INPUT
  
  * DNS name resolution requests sent to outside servers — (responses)
  sudo iptables -A INPUT -p udp --sport domain -j ACCEPT
  sudo iptables -A INPUT -p tcp --sport domain -j ACCEPT

  * SSH connections to the router system, originated at the VPN gateway 
  (vpn-gw). — (responses)
  sudo iptables -A INPUT -p tcp -s ${vpn-gw} --dport ssh -j ACCEPT

  * SSH connections to the router system, originated at the internal network 
  sudo iptables -A INPUT -p tcp -i ens36 --dport ssh -j ACCEPT

  * Login INPUT chain events
  sudo iptables -A INPUT -j LOG \
      --log-level 4 --log-prefix 'IP INPUT DROP: '

  * INPUT chain policy
  sudo iptables -P INPUT DROP

### OUTPUT

  * DNS name resolution requests sent to outside servers.
  sudo iptables -A OUTPUT -p udp --dport domain -j ACCEPT
  sudo iptables -A OUTPUT -p tcp --dport domain -j ACCEPT

  * SSH connections to the router system, originated at the VPN gateway 
  (vpn-gw)
  sudo iptables -A OUTPUT -p tcp -d ${vpn-gw} --sport ssh -j ACCEPT

  * SSH connections to the router system, originated at the internal network 
  sudo iptables -A OUTPUT -p tcp --sport ssh -o ens36 -j ACCEPT

  * Log OUTPUT chain events
  sudo iptables -A OUTPUT -j LOG \
      --log-level 4 --log-prefix 'IP OUTPUT DROP: '

  * OUTPUT chain policy
   sudo iptables -P OUTPUT DROP

### Forward 

  * Domain name resolutions using the `dns` server.
  * The dns server should be able to resolve names using DNS servers 
    on the Internet (dns2 and others).

  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      --dport domain -j ACCEPT  
  sudo iptables -A FORWARD -p udp -d 10.10.10.4 -o ens34 \
      --dport domain -j ACCEPT

  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      --dport domain -j ACCEPT  
  sudo iptables -A FORWARD -p udp -s 10.10.10.4 -i ens34 \
      --dport domain -j ACCEPT

  * The dns and dns2 servers should be able to synchronize the 
    contents of DNS zones.

  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      -s 193.137.16.75 -i ens33 -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      -d 193.137.16.75 -o ens33 -j ACCEPT

  * SMTP connections to the smtp server.
  
  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      --dport smtp -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      --dport stmp -j ACCEPT

  * POP and IMAP connections to the mail server.

  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      --dport pop3 -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      --dport pop3s -j ACCEPT

  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      --dport imap -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      --dport imaps -j ACCEPT

  * HTTP and HTTPS connections to the www server.

  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      --dport http -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      --dport http -j ACCEPT

  sudo iptables -A FORWARD -p udp -d 10.10.10.4 -o ens34 \
      --dport https -j ACCEPT
  sudo iptables -A FORWARD -p udp -s 10.10.10.4 -i ens34 \
      --dport https -j ACCEPT

  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      --dport https -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      --dport https -j ACCEPT

  * OpenVPN connections to the vpn-gw server

  sudo iptables -A FORWARD -p tcp -d 10.10.10.4 -o ens34 \
      --dport openvpn -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
      --dport openvpn -j ACCEPT

  sudo iptables -A FORWARD -p udp -d 10.10.10.4 -o ens34 \
      --dport openvpn -j ACCEPT
  sudo iptables -A FORWARD -p udp -s 10.10.10.4 -i ens34 \
      --dport openvpn -j ACCEPT

  * VPN clients connected to vpn-gw server should be able to 
    connect to the PostgreSQL service on the datastore server.

  sudo iptables -A FORWARD -p tcp -d 10.20.20.4 -o ens36 \
      -s 10.10.10.4 -i ens34 --dport postgres -j ACCEPT
  sudo iptables -A FORWARD -p tcp -s 10.20.20.4 -i ens34 \
      -d 10.20.20.4 -o ens36 --dport postgres -j ACCEPT

  * VPN clients connected to vpn-gw server should be able to connect 
    to Kerberos v5 service on the kerberos server. A maximum of 10 
    simultaneous connections are allowed.

   sudo iptables -A FORWARD -p tcp -m connlimit --connlimit-upto 10 \
       -d 10.20.20.4 -o ens36 -s 10.10.10.4 -i ens34 \
       --dport kerberos -j ACCEPT

   sudo iptables -A FORWARD -p udp -m connlimit --connlimit-upto 10 \
        -d 10.20.20.4 -o ens36 -s 10.10.10.4 -i ens34 \
        --dport kerberos -j ACCEPT

   sudo iptables -A FORWARD -p tcp -s 10.20.20.4 -i ens36 \
       -d 10.10.10.4 -o ens34 --dport kerberos -j ACCEPT

   sudo iptables -A FORWARD -p udp -s 10.20.20.4 -i ens36 \
       -d 10.10.10.4 -o ens34 --dport kerberos -j ACCEPT

  * FTP connections (active modes) to the ftp server.
  sudo iptables -A FORWARD -p tcp -i ens33 \
      -d 10.20.20.4 -o ens36 --dport ftp -j ACCEPT

  sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens36 \
      -d 193.137.128.1 -o ens33 --sport ftp-data -j ACCEPT

  * FTP connections (passive mode) to the ftp server.
     sudo iptables -A FORWARD -p tcp -m state \
         --state RELATED,ESTABLISHED -j ACCEPT 

  * SSH connections to the datastore sever, but onl if originated at
    the eden or dns2 servers.

  sudo itables-A FORWARD -p tcp -i ens33 -s 193.137.136.75 \
      -d 10.20.20.4 -o ens34 --dport ssh -j ACCEPT

  sudo itables-A FORWARD -p tcp -i ens33 -s 193.136.212.1 \
      -d 10.20.20.4 -o ens34 --dport ssh -j ACCEPT

  * Domain name resolutions using DNS (internal to outside)

  >> sudo iptables -A FORWARD -p tcp -d 10.20.20.4 -o ens34 \
  >>     -i ens33 --dport domain -j ACCEPT  
  >> sudo iptables -A FORWARD -p udp -d 10.20.20.4 -o ens34 \
  >>     -e ens33 --dport domain -j ACCEPT

  >> sudo iptables -A FORWARD -p tcp -s 10.10.10.4 -i ens34 \
  >>     -o ens33 --dport domain -j ACCEPT  
  >> sudo iptables -A FORWARD -p udp -s 10.10.10.4 -i ens34 \
  >>     -o ens33 --dport domain -j ACCEPT

  * Log FORWARD chain events
  >> sudo iptables -A FORWARD -j LOG \
  >>     --log-level 4 --log-prefix 'IP FORWARD DROP: '

  * FORWARD chain policy
  >> sudo iptables -P FORWARD DROP

## NAT

### POSTROUTING (SNAT)
  
  * The dns server should be able to resolve names using DNS servers 
    on the Internet (dns2 and others).

  sudo iptables -t nat -A POSTROUTING -p tcp -o ens33 -s 10.10.10.4 \
     --sport domain -j SNAT --to-source 193.137.128.1
  sudo iptables -t nat -A POSTROUTING -p udp -o ens33 -s 10.10.10.4 \
     --sport domain -j SNAT --to-source 193.137.128.1

  * The dns and dns2 servers should be able to synchronize the 
    contents of DNS zones.

  sudo iptables -t nat -A POSTROUTING -p tcp -o ens33 -s 10.10.10.4 \
    -j SNAT --to-source 193.137.128.1

  * Domain name resolutions using DNS (internal to outside)

  >> sudo iptables -t nat -A POSTROUTING -p tcp -o ens33 -s 10.20.20.4 \
  >>   --sport domain -j SNAT --to-source 193.137.128.1
  >> sudo iptables -t nat -A POSTROUTING -p udp -o ens33 -s 10.20.20.4 \
  >>   --sport domain -j SNAT --to-source 193.137.128.1

### PREROUTING (DNAT)

  * Domain name resolutions using the `dns` server.
  * The dns server should be able to resolve names using DNS servers 
    on the Internet ( dns2 and others).

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport domain -j DNAT --to-destination 10.10.10.4
  sudo iptables -t nat -A PREROUTING -p udp -i ens33 -d 193.137.128.1 \
      --dport domain -j DNAT --to-destination 10.10.10.4

  * The dns and dns2 servers should be able to synchronize the 
    contents of DNS zones.

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      -j DNAT --to-destination 10.10.10.4

  * SMTP connections to the smtp server.

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport smtp -j DNAT --to-destination 10.10.10.4

  * POP and IMAP connections to the mail server.

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport pop3 -j DNAT --to-destination 10.10.10.4

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport pop3s -j DNAT --to-destination 10.10.10.4

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport imap -j DNAT --to-destination 10.10.10.4

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport imaps -j DNAT --to-destination 10.10.10.4


  * HTTP and HTTPS connections to the www server.

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport http -j DNAT --to-destination 10.10.10.4
  sudo iptables -t nat -A PREROUTING -p udp -i ens33 -d 193.137.128.1 \
      --dport http -j DNAT --to-destination 10.10.10.4

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport https -j DNAT --to-destination 10.10.10.4

  * OpenVPN connections to the vpn-gw server

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport openvpn -j DNAT --to-destination 10.10.10.4
  sudo iptables -t nat -A PREROUTING -p udp -i ens33 -d 193.137.128.1 \
      --dport openvpn -j DNAT --to-destination 10.10.10.4

  * FTP connections (passive and active modes) to the ftp server.
  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
     --dport ftp -j DNAT --to-destination 10.20.20.4
  
  * SSH connections to the datastore sever, but onl if originated at
    the eden or dns2 servers.

  sudo iptables -t nat -A PREROUTING -p tcp -i ens33 -d 193.137.128.1 \
      --dport ssh -j DNAT --to-destination 10.20.20.4


