 TOPT

## No server de Coimbra

1. Install 

```sh
apt-get install -y libqrencode4 libpam-google-authenticator
```

2. Adicionar um user chamado gauth que vai gerir todo o processo de authenticação 

```sh
sudo addgroup gauth
sudo useradd -g gauth gauth
sudo mkdir /etc/openvpn/google-authenticator
sudo chown gauth:gauth /etc/openvpn/google-authenticator
sudo chmod 0700 /etc/openvpn/google-authenticator
```
3. No server.conf colocar no fim do ficheiro o seguinte:

```sh
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so openvpn
```

4. Na pasta /etc/pam.d criar o ficheiro openvpn `sudo touch openvpn` e colocar
  lá o seguinte:

```sh
auth requisite /lib/x86_64-linux-gnu/security/pam_google_authenticator.so secret=/etc/openvpn/google-authenticator/${USER} user=gauth forward_pass
```

5. Criar o seguinte utilizador que depois iremos usar no futuro no warrior a fim
  de nos autenticarmos com OTP: vou usar um user com nome `warrior` e dar-lhe uma
  password `sti2022` para demostração.
```sh
sudo useradd -d /home/warrior -s /bin/false warrior 
sudo passwd warrior sti2022 
```

6. Instalar a app do Google Authenticator 

7. Gerar um QR code com este comando (mais uma vez estou a usar o user de 
nome `warrior`) e seguir as instruções

```sh
su -c "google-authenticator -t -d -r3 -R30 -f -l 'OpenVPN Server' -s/etc/openvpn/google-authenticator/warrior" - gauth
```
8. Ligar a vpn and there you go!!!

# No Road Warrior

1. Adicionar a seguinte linha no ficheiro de configuração do cliente

```txt
auth-user-pass
```

2. Ligar a vpn!!
  - Vai aparece as cenas para autenticar antes de iniciar a vpn. 
  Para o user warrior que criamos lá cima terias os campos da seguinte forma:
  Imagina que o token do OTP é: `123 456`

```txt
  username: warrior
  password: sti2022123456 (password do user concatenada com o token)
```  
 
