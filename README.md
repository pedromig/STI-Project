# STI-Project

Information Technology Security course projects

## TP1

### Virtualization Software Configurations
  * Configure VMware so the VM's external network interface IP is in one of the 
  IP's in the network 192.168.172.0/24, as required by the assignment's statement.
  [DHCP Conventions for Assigning IP Addresses in Host-Only and NAT Networks](
  https://docs.vmware.com/en/VMware-Workstation-Pro/16.0/com.vmware.ws.using
  .doc/GUID-9831F49E-1A83-4881-BB8A-D4573F2C6D91.html)

  - To do this follow the steps bellow:
    1. Go to VMWare Workstation > Edit > Virtual Network Editor **or** `sudo vmware-netcfg`
    2. Select Virtual Network Adaptor with *Name: vmnet8* and *Type: NAT* and set
    3. Set `Subnet IP: 192.168.172.0` and `Subnet mask: 255.255.255.0`

### (Private) Certificate Authority and OCSP (Online Certificate Status Protocol) setup

  TODO: check if we need to add this to the hosts file 
  * For the identification of the *ocsp* service we chose the URI `ocsp.coimbra.pt`
  adding the correspondent entry in the `/etc/hosts` name resolution database file.
   
  * For the configuration of the certificate generation process we defined the following 
  settings in the *openssl* configuration located at `/etc/ssl/openssl.cnf`.
    - Under the `CA_default` section: `dir = /etc/pki/CA` 
    (Where all the openssl files are kept)
    - Under the `usr_cert` section: `authorityInfoAccess = OCSP;URI:http://ocsp.coimbra.pt`
    (To setup the OCSP service using *openssl* extension)  
    - Under the `policy` section set: `policy = policy_anything` (in order to accept
    the generation of certificates that have attibutes that are different from those 
    used in the the CA certificate creation.)

  * In the creation of the (private) certificate authority (CA), and for the emission 
  of the CSR (certificate signing request) we used (for demonstration purposes) the )
  following configuration.
    ```txt
      Enter pass phrase for private/cakey.pem:
      You are about to be asked to enter information that will be incorporated
      into your certificate request.
      What you are about to enter is what is called a Distinguished Name or a DN.
      There are quite a few fields but you can leave some blank
      For some fields there will be a default value,
      If you enter '.', the field will be left blank.
      -----
      Country Name (2 letter code) [PT]:PT
      State or Province Name (full name) [Some-State]:Coimbra
      Locality Name (eg, city) []:Coimbra
      Organization Name (eg, company) [Internet Widgits Pty Ltd]:UC
      Organizational Unit Name (eg, section) []:DEI
      Common Name (e.g. server FQDN or YOUR name) []:CA
      Email Address []:ca@dei.uc.pt

      Please enter the following 'extra' attributes
      to be sent with your certificate request
      A challenge password []: *******
      An optional company name []:DEI
    ```
#### Issuing Certificates

  * For the emission of the certificate used by the *apache* service running 
  in the *lisbon* machine, we used (for demonstration purposes) the following 
  configuration.
  ```txt
      Enter pass phrase for private/apache.key:
      You are about to be asked to enter information that will be incorporated
      into your certificate request.
      What you are about to enter is what is called a Distinguished Name or a DN.
      There are quite a few fields but you can leave some blank
      For some fields there will be a default value,
      If you enter '.', the field will be left blank.
      -----
      Country Name (2 letter code) [PT]:PT
      State or Province Name (full name) [Some-State]:Lisboa
      Locality Name (eg, city) []:Lisboa
      Organization Name (eg, company) [Internet Widgits Pty Ltd]:IST
      Organizational Unit Name (eg, section) []:DEI
      Common Name (e.g. server FQDN or YOUR name) []:www.apache.lisboa.pt
      Email Address []:apache@dei.ist.pt

      Please enter the following 'extra' attributes
      to be sent with your certificate request
      A challenge password []: *******
      An optional company name []:DEI
  ```


  * For the emission of the certificate used by the coimbra-vpn server running 
  in the *coimbra* machine, we used (for demonstration purposes) the following 
  configuration.
  ```txt
    Enter pass phrase for private/coimbra-vpn.key:
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [PT]:PT
    State or Province Name (full name) [Some-State]:Coimbra
    Locality Name (eg, city) []:Coimbra
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:UC
    Organizational Unit Name (eg, section) []:DEI
    Common Name (e.g. server FQDN or YOUR name) []:VPN Server Coimbra
    Email Address []:ca@dei.uc.pt

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:*******
    An optional company name []:DEI
  ```

  * For the emission of the certificate used by the *coimbra* machine which (in 
  our scenario) will work as client of the *lisbon* machine regarding the VPN 
  service, we used (for demonstration purposes) the following configuration.
  ```txt
    Enter pass phrase for private/coimbra-client.key:
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [PT]:PT
    State or Province Name (full name) [Some-State]:Coimbra
    Locality Name (eg, city) []:Coimbra
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:UC
    Organizational Unit Name (eg, section) []:DEI
    Common Name (e.g. server FQDN or YOUR name) []:VPN Client Coimbra
    Email Address []:ca@dei.uc.pt

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:*******
    An optional company name []:DEI
  ```


  * For the emission of the certificate used by the lisboa-vpn server running 
  in the *lisboa* machine, we used (for demonstration purposes) the following 
  configuration.

  ```txt
    Enter pass phrase for private/lisboa-vpn.key:
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [PT]:PT
    State or Province Name (full name) [Some-State]:Lisboa
    Locality Name (eg, city) []:Lisboa
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:IST
    Organizational Unit Name (eg, section) []:DEI
    Common Name (e.g. server FQDN or YOUR name) []:Lisboa VPN Server
    Email Address []:lisboa@dei.ist.pt

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:*******
    An optional company name []:DEI
  ```

  * For the emission of the certificate used by the *road warrior* machine which (in 
  our scenario) will work as client of the *coimbra* machine regarding the VPN 
  service, we used (for demonstration purposes) the following configuration.
  ```txt
    Enter pass phrase for private/warrior-client.key:
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [PT]:PT
    State or Province Name (full name) [Some-State]:Coimbra
    Locality Name (eg, city) []:Coimbra
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:UC
    Organizational Unit Name (eg, section) []:DEI
    Common Name (e.g. server FQDN or YOUR name) []:Road Warrior VPN client
    Email Address []:warrior@dei.uc.pt

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:*******
    An optional company name []:DEI
  ```

# Colaborators
  - [Joana Brás](https://github.com/joanaa-b)
