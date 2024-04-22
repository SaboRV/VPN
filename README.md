# Цель домашнего задания
Создать домашнюю сетевую лабораторию. Научится настраивать VPN-сервер в Linux-based системах.


# Описание домашнего задания
Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях
Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ.


# Введение

## 1. TUN/TAP режимы VPN

Для выполнения первого пункта необходимо написать Vagrantfile, который будет поднимать 2 виртуальные машины server и client. 
Типовой пример Vagrantfile для данной задачи: 

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


 config.vm.define "server" do |server| 
 server.vm.box = "ubuntu/jammy64"
 server.vm.network "private_network", ip: "192.168.56.10",   virtualbox__intnet: "net1" 
 server.vm.hostname = "server" 
 server.vm.provision "shell", path: "server_script.sh"
 server.vm.provider :virtualbox do |vb|
      vb.name = "server"
      vb.memory = 2048
      vb.cpus = 2
    end
 end 
 config.vm.define "client" do |client| 
 client.vm.box = "ubuntu/jammy64"
 client.vm.network "private_network", ip: "192.168.56.21",  virtualbox__intnet: "net1" 
 client.vm.hostname = "client"
 client.vm.provision "shell", path: "client_script.sh"
 client.vm.provider :virtualbox do |vb|
      vb.name = "client"
      vb.memory = 2048 
      vb.cpus = 2 
    end
 end 
end 


После запуска машин из Vagrantfile необходимо выполнить следующие действия на server и client машинах:

#### Устанавливаем нужные пакеты и отключаем SELinux  
apt update
apt install openvpn iperf3 selinux-utils
setenforce 0

### Настройка хоста 1: 
	
#### Cоздаем файл-ключ 
openvpn --genkey secret /etc/openvpn/static.key
#### Cоздаем конфигурационный файл OpenVPN 
vim /etc/openvpn/server.conf
	
#### Содержимое файла server.conf
dev tap 
ifconfig 10.10.10.1 255.255.255.0 
topology subnet 
secret /etc/openvpn/static.key 
comp-lzo 
status /var/log/openvpn-status.log 
log /var/log/openvpn.log  
verb 3 
     # Создаем service unit для запуска OpenVPN
     vim /etc/systemd/system/openvpn@.service
     # Содержимое файла-юнита
[Unit] 
Description=OpenVPN Tunneling Application On %I 
After=network.target 
[Service] 
Type=notify 
PrivateTmp=true 
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf 
[Install] 
WantedBy=multi-user.target


#### Запускаем сервис 
systemctl start openvpn@server 
systemctl enable openvpn@server


### Настройка хоста 2: 

#### Cоздаем конфигурационный файл OpenVPN 
vim /etc/openvpn/server.conf

#### Содержимое конфигурационного файла  
dev tap 
remote 192.168.56.10 
ifconfig 10.10.10.2 255.255.255.0 
topology subnet 
route 192.168.56.0 255.255.255.0 
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log 
log /var/log/openvpn.log 
verb 3 


На хост 2 в директорию /etc/openvpn необходимо скопировать файл-ключ static.key, который был создан на хосте 1.  

#### Создаем service unit для запуска OpenVPN
vim /etc/systemd/system/openvpn@.service

#### Содержимое файла-юнита
[Unit] 
Description=OpenVPN Tunneling Application On %I 
After=network.target 
[Service] 
Type=notify 
PrivateTmp=true 
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf 
[Install] 
WantedBy=multi-user.target

#### Запускаем сервис 
systemctl start openvpn@server 
systemctl enable openvpn@server


#### Далее необходимо замерить скорость в туннеле: 

На хосте 1 запускаем iperf3 в режиме сервера: iperf3 -s & 
На хосте 2 запускаем iperf3 в режиме клиента и замеряем  скорость в туннеле: iperf3 -c 10.10.10.1 -t 40 -i 5 

root@server:~# iperf3 -s &
[2] 1116
root@server:~# iperf3: error - unable to start listener for connections: Address already in use
iperf3: exiting
Accepted connection from 10.10.10.2, port 33972
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 33980
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  21.5 MBytes   180 Mbits/sec                  
[  5]   1.00-2.00   sec  22.8 MBytes   191 Mbits/sec                  
[  5]   2.00-3.00   sec  19.9 MBytes   167 Mbits/sec                  
[  5]   3.00-4.00   sec  18.6 MBytes   156 Mbits/sec                  
[  5]   4.00-5.00   sec  16.5 MBytes   138 Mbits/sec                  
[  5]   5.00-6.00   sec  20.0 MBytes   168 Mbits/sec                  
[  5]   6.00-7.00   sec  18.2 MBytes   153 Mbits/sec                  
[  5]   7.00-8.00   sec  18.3 MBytes   153 Mbits/sec                  
[  5]   8.00-9.00   sec  18.8 MBytes   158 Mbits/sec                  
[  5]   9.00-10.00  sec  18.5 MBytes   155 Mbits/sec                  
[  5]  10.00-11.00  sec  18.7 MBytes   157 Mbits/sec                  
[  5]  11.00-12.00  sec  18.3 MBytes   153 Mbits/sec                  
[  5]  12.00-13.00  sec  17.9 MBytes   150 Mbits/sec                  
[  5]  13.00-14.00  sec  18.6 MBytes   156 Mbits/sec                  
[  5]  14.00-15.00  sec  18.4 MBytes   155 Mbits/sec                  
[  5]  15.00-16.00  sec  18.2 MBytes   153 Mbits/sec                  
[  5]  16.00-17.00  sec  18.2 MBytes   153 Mbits/sec                  
[  5]  17.00-18.00  sec  18.3 MBytes   154 Mbits/sec                  
[  5]  18.00-19.00  sec  18.4 MBytes   154 Mbits/sec                  
[  5]  19.00-20.00  sec  19.5 MBytes   163 Mbits/sec                  
[  5]  20.00-21.00  sec  22.5 MBytes   188 Mbits/sec                  
[  5]  21.00-22.00  sec  23.4 MBytes   196 Mbits/sec                  
[  5]  22.00-23.00  sec  23.5 MBytes   197 Mbits/sec                  
[  5]  23.00-24.00  sec  23.1 MBytes   194 Mbits/sec                  
[  5]  24.00-25.00  sec  24.1 MBytes   202 Mbits/sec                  
[  5]  25.00-26.00  sec  23.4 MBytes   196 Mbits/sec                  
[  5]  26.00-27.00  sec  23.2 MBytes   195 Mbits/sec                  
[  5]  27.00-28.00  sec  23.4 MBytes   196 Mbits/sec                  
[  5]  28.00-29.00  sec  22.9 MBytes   192 Mbits/sec                  
[  5]  29.00-30.00  sec  23.2 MBytes   195 Mbits/sec                  
[  5]  30.00-31.00  sec  22.3 MBytes   187 Mbits/sec                  
[  5]  31.00-32.00  sec  19.7 MBytes   165 Mbits/sec                  
[  5]  32.00-33.00  sec  22.6 MBytes   190 Mbits/sec                  
[  5]  33.00-34.00  sec  23.4 MBytes   196 Mbits/sec                  
[  5]  34.00-35.00  sec  22.9 MBytes   192 Mbits/sec                  
[  5]  35.00-36.00  sec  22.8 MBytes   191 Mbits/sec                  
[  5]  36.00-37.00  sec  22.8 MBytes   191 Mbits/sec                  
[  5]  37.00-38.00  sec  23.3 MBytes   196 Mbits/sec                  
[  5]  38.00-39.00  sec  23.2 MBytes   195 Mbits/sec                  
[  5]  39.00-40.00  sec  24.3 MBytes   203 Mbits/sec                  
[  5]  40.00-40.05  sec  1.20 MBytes   207 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-40.05  sec   839 MBytes   176 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
^C
[2]+  Exit 1                  iperf3 -s
root@server:~# 



root@client:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 33980 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec   103 MBytes   172 Mbits/sec  486    833 KBytes       
[  5]   5.00-10.00  sec  93.8 MBytes   157 Mbits/sec  832   1.30 MBytes       
[  5]  10.00-15.00  sec  91.2 MBytes   153 Mbits/sec   48   1.10 MBytes       
[  5]  15.00-20.00  sec  93.8 MBytes   157 Mbits/sec    0   1.12 MBytes       
[  5]  20.00-25.00  sec   116 MBytes   195 Mbits/sec  664    369 KBytes       
[  5]  25.00-30.00  sec   116 MBytes   195 Mbits/sec    0    548 KBytes       
[  5]  30.00-35.00  sec   111 MBytes   187 Mbits/sec  151    337 KBytes       
[  5]  35.00-40.00  sec   116 MBytes   195 Mbits/sec    0    526 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.00  sec   842 MBytes   176 Mbits/sec  2181             sender
[  5]   0.00-40.05  sec   839 MBytes   176 Mbits/sec                  receiver

iperf Done.
root@client:~# 



### Повторяем пункты 1-2 для режима работы tun. 
Конфигурационные файлы сервера и клиента изменятся только в директиве dev.

root@server:~# iperf3 -s &
[2] 1094
root@server:~# iperf3: error - unable to start listener for connections: Address already in use
iperf3: exiting
Accepted connection from 10.10.10.2, port 53828
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 53840
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  36.0 MBytes   302 Mbits/sec                  
[  5]   1.00-2.00   sec  38.7 MBytes   325 Mbits/sec                  
[  5]   2.00-3.00   sec  37.8 MBytes   317 Mbits/sec                  
[  5]   3.00-4.00   sec  37.9 MBytes   318 Mbits/sec                  
[  5]   4.00-5.00   sec  38.7 MBytes   325 Mbits/sec                  
[  5]   5.00-6.00   sec  38.4 MBytes   322 Mbits/sec                  
[  5]   6.00-7.00   sec  38.1 MBytes   320 Mbits/sec                  
[  5]   7.00-8.00   sec  38.6 MBytes   323 Mbits/sec                  
[  5]   8.00-9.00   sec  38.2 MBytes   321 Mbits/sec                  
[  5]   9.00-10.00  sec  38.5 MBytes   323 Mbits/sec                  
[  5]  10.00-11.00  sec  38.0 MBytes   319 Mbits/sec                  
[  5]  11.00-12.00  sec  25.0 MBytes   210 Mbits/sec                  
[  5]  12.00-13.00  sec  23.3 MBytes   196 Mbits/sec                  
[  5]  13.00-14.00  sec  23.5 MBytes   197 Mbits/sec                  
[  5]  14.00-15.00  sec  23.4 MBytes   196 Mbits/sec                  
[  5]  15.00-16.00  sec  23.3 MBytes   195 Mbits/sec                  
[  5]  16.00-17.00  sec  23.2 MBytes   195 Mbits/sec                  
[  5]  17.00-18.00  sec  19.4 MBytes   162 Mbits/sec                  
[  5]  18.00-19.00  sec  18.5 MBytes   155 Mbits/sec                  
[  5]  19.00-20.00  sec  18.8 MBytes   158 Mbits/sec                  
[  5]  20.00-21.00  sec  21.7 MBytes   182 Mbits/sec                  
[  5]  21.00-22.00  sec  23.8 MBytes   200 Mbits/sec                  
[  5]  22.00-23.00  sec  23.6 MBytes   198 Mbits/sec                  
[  5]  23.00-24.00  sec  23.7 MBytes   199 Mbits/sec                  
[  5]  24.00-25.00  sec  23.8 MBytes   200 Mbits/sec                  
[  5]  25.00-26.00  sec  23.8 MBytes   200 Mbits/sec                  
[  5]  26.00-27.00  sec  23.6 MBytes   198 Mbits/sec                  
[  5]  27.00-28.00  sec  22.9 MBytes   192 Mbits/sec                  
[  5]  28.00-29.00  sec  20.8 MBytes   174 Mbits/sec                  
[  5]  29.00-30.00  sec  22.3 MBytes   187 Mbits/sec                  
[  5]  30.00-31.00  sec  20.8 MBytes   174 Mbits/sec                  
[  5]  31.00-32.00  sec  22.8 MBytes   191 Mbits/sec                  
[  5]  32.00-33.00  sec  23.3 MBytes   195 Mbits/sec                  
[  5]  33.00-34.00  sec  23.5 MBytes   198 Mbits/sec                  
[  5]  34.00-35.00  sec  19.1 MBytes   160 Mbits/sec                  
[  5]  35.00-36.00  sec  18.7 MBytes   157 Mbits/sec                  
[  5]  36.00-37.00  sec  19.2 MBytes   161 Mbits/sec                  
[  5]  37.00-38.00  sec  18.5 MBytes   156 Mbits/sec                  
[  5]  38.00-39.00  sec  18.6 MBytes   156 Mbits/sec                  
[  5]  39.00-40.00  sec  18.6 MBytes   156 Mbits/sec                  
[  5]  40.00-40.04  sec   840 KBytes   159 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-40.04  sec  1.03 GBytes   220 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
^C
[2]+  Exit 1                  iperf3 -s
root@server:~# 


root@client:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 53840 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec   193 MBytes   324 Mbits/sec   23    548 KBytes       
[  5]   5.00-10.00  sec   191 MBytes   321 Mbits/sec    3    606 KBytes       
[  5]  10.00-15.00  sec   132 MBytes   222 Mbits/sec  246    366 KBytes       
[  5]  15.00-20.00  sec   102 MBytes   172 Mbits/sec    0    532 KBytes       
[  5]  20.00-25.00  sec   117 MBytes   197 Mbits/sec   13    444 KBytes       
[  5]  25.00-30.00  sec   112 MBytes   189 Mbits/sec   19    447 KBytes       
[  5]  30.00-35.00  sec   110 MBytes   184 Mbits/sec   32    480 KBytes       
[  5]  35.00-40.00  sec  93.5 MBytes   157 Mbits/sec    0    567 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.00  sec  1.03 GBytes   221 Mbits/sec  336             sender
[  5]   0.00-40.04  sec  1.03 GBytes   220 Mbits/sec                  receiver

iperf Done.
root@client:~# 


## Выводы о режимах, их достоинствах и недостатках:

В терминологии компьютерных сетей, TUN и TAP — виртуальные сетевые драйверы ядра системы. Они представляют собой программные сетевые устройства, которые отличаются от обычных аппаратных сетевых карт.

TAP эмулирует Ethernet-устройство и работает на канальном уровне модели OSI, оперируя кадрами Ethernet. TUN (сетевой туннель) работает на сетевом уровне модели OSI, оперируя IP-пакетами. TAP используется для создания сетевого моста, тогда как TUN — для маршрутизации.

В нашем случае TUN быстрее.


# Вы можете использовать TUN, если вы просто используете VPN для подключения к Интернету.
# Вам нужно использовать TAP, если вы хотите подключиться к реальной удаленной сети (принтеры, удаленные рабочие столы и т. Д.)


## 2. RAS на базе OpenVPN 

# Описываем Виртуальные машины
MACHINES = {
  # Указываем имя ВМ "RPM"
  :"RPM" => {
              #Какой vm box будем использовать
              :box_name => "ubuntu/jammy64",
              :ip_addr => '192.168.56.10',
              #Указываем количество ядер ВМ
              :cpus => 4,
              #Указываем количество ОЗУ в мегабайтах
              :memory => 4096,
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Применяем конфигурацию ВМ
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.provision "shell", path: "script.sh"
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.network "private_network", ip: boxconfig[:ip_addr]
      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
    end
  end
end



Настройка сервера: 

### Устанавливаем необходимые пакеты 
apt update
apt-get install -y openvpn easy-rsa selinux-utils
setenforce 0

## Настройка центра сертификации

Первое что нужно сделать, это создать правильную инфраструктуру для генерации открытых ключей на сервере. Сервером мы считаем ту машину, к которой будут подключаться пользователи. Обратите внимание, что все секретные ключи должны находится в надежном месте. В OpenVPN открытый ключ называется сертификатом и имеет расширение .crt, а закрытый ключ так и называется ключом, его расширение - .key. Обслуживать всё это мы будем с помощью набора скриптов Easy-RSA.

Для того чтобы после обновления системы все ваши сертификаты и настройки не были стёрты, надо скопировать набор скриптов из каталога /usr/share/easy-rsa куда-нибудь, например, в /etc/openvpn/:
 sudo mkdir /etc/openvpn/easy-rsa

Затем скопируем в эту папку все необходимые скрипты easy-rsa:
 sudo cp -R /usr/share/easy-rsa /etc/openvpn/

Далее нам нужно создать центр сертификации в этой папке. Для этого сначала перейдите в неё:
cd /etc/openvpn/easy-rsa/

Эта команда создаст папку pki и и необходимые файлы для генерации сертификатов. Алгоритм шифрования можно настраивать, но с параметрами по умолчанию тоже всё будет работать:
sudo ./easyrsa init-pki

Следующая команда создаёт ключ центра сертификации, для него понадобится придумать пароль:
sudo ./easyrsa build-ca

Далее надо создать ключи Диффи-Хафмана, которые используются при обмене ключами между клиентом и сервером. Для этого выполните:
sudo ./easyrsa gen-dh

Команда создаст файл /etc/openvpn/easy-rsa/pki/dh.pem. Если вы хотите использовать TLS авторизацию, то вам ещё понадобится ключ Hash-based Message Authentication Code (HMAC). Он используется для предотвращения DoS атаки при использовании протокола UDP. Для его создания выполните:
sudo openvpn --genkey secret /etc/openvpn/easy-rsa/pki/ta.key

Для отзыва уже подписанных сертификатов нам понадобится сертификат отзыва. Для его создания выполните команду:
sudo ./easyrsa gen-crl

Будет создан файл ./pki/crl.pem.

## Создание сертификатов сервера

Для создания сертификатов, которые будут использоваться сервером надо выполнить команду:
sudo ./easyrsa build-server-full server nopass

Здесь server - это имя нашего сервера, а опция nopass отключает использование пароля. Теперь все полученные ключи надо скопировать в папку /etc/openvpn:
cp ./pki/ca.crt /etc/openvpn/ca.crt
cp ./pki/dh.pem /etc/openvpn/dh.pem
cp ./pki/crl.pem /etc/openvpn/crl.pem
cp ./pki/ta.key /etc/openvpn/ta.key
cp ./pki/issued/server.crt /etc/openvpn/server.crt
cp ./pki/private/server.key /etc/openvpn/server.key

Все эти сертификаты надо будет использовать позже, при создании конфигурационного файла сервера.
Наши ключи хранятся по адресу /etc/openvpn, в самой папке с конфигурационным файлом, поэтому можно не прописывать к ним полный путь.

### Зададим параметр iroute для клиента
echo 'iroute 10.10.10.0 255.255.255.0' > /etc/openvpn/client/client

### Создаем конфигурационный файл сервера 
vim /etc/openvpn/server.conf



### Содержимое файла server.conf
port 1194
proto udp
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/vpn-server.crt
key /etc/openvpn/easy-rsa/pki/private/vpn-server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
server 10.10.10.0 255.255.255.0
ifconfig-pool-persist ipp.txt
client-to-client
client-config-dir /etc/openvpn/client
tls-auth /etc/openvpn/easy-rsa/pki/ta.key 0
cipher AES-256-CBC
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log         /var/log/openvpn/openvpn.log
log-append  /var/log/openvpn/openvpn.log
verb 3
explicit-exit-notify 1



### Запускаем сервис (при необходимости создать файл юнита как в задании 1) 
systemctl daemon-reload
service openvpn start
service openvpn@server start

## Создание сертификатов для клиента
Создадим ключи для клиента на сервере. Для этого в той же директории /etc/openvpn/easy-rsa/ выполните такую команду:
sudo ./easyrsa build-client-full user nopass

Сертификат будет называться user, а опция nopass аналогично генерации ключей для сервера отключает использование пароля.

Давайте создадим папку /etc/openvpn/clients, куда будем складывать все ключи
sudo mkdir /etc/openvpn/clients
sudo mkdir /etc/openvpn/clients/user
Затем перейдите в папку клиента:
cd /etc/openvpn/clients/user

Затем туда надо скопировать ca.crt, ta.key и ключи клиента user.crt и user.key:
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/clients/user/
cp /etc/openvpn/easy-rsa/pki/ta.key /etc/openvpn/clients/user/
cp /etc/openvpn/easy-rsa/pki/issued/user.crt /etc/openvpn/clients/user/
cp /etc/openvpn/easy-rsa/pki/private/user.key /etc/openvpn/clients/user/

Теперь папку user скопируем на хост-машину.


### На хост-машине: 

1) Необходимо создать файл client.conf со следующим содержимым: 

dev tun 
proto udp 
remote 192.168.56.10 1207 
client 
resolv-retry infinite 
remote-cert-tls server 
ca ca.crt 
cert user.crt 
key user.key
tls-auth ta.key 1 
route 192.168.56.0 255.255.255.0 
persist-key 
persist-tun 
comp-lzo 
verb 3 

2) Скопировать в одну директорию с client.conf файлы с папки user:     	   


Далее можно проверить подключение с помощью: sudo openvpn --config client.conf

sabo@sabo-virtual-machine:~/LESSONS/VPN$ sudo openvpn --config client.ovpn
2024-04-22 12:24:44 WARNING: Compression for receiving enabled. Compression has been used in the past to break encryption. Sent packets are not compressed unless "allow-compression yes" is also set.
2024-04-22 12:24:44 --cipher is not set. Previous OpenVPN version defaulted to BF-CBC as fallback when cipher negotiation failed in this case. If you need this fallback please add '--data-ciphers-fallback BF-CBC' to your configuration and/or add BF-CBC to --data-ciphers.
2024-04-22 12:24:44 OpenVPN 2.5.9 x86_64-pc-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Sep 29 2023
2024-04-22 12:24:44 library versions: OpenSSL 3.0.2 15 Mar 2022, LZO 2.10
2024-04-22 12:24:44 WARNING: No server certificate verification method has been enabled.  See http://openvpn.net/howto.html#mitm for more info.
2024-04-22 12:24:44 Outgoing Control Channel Authentication: Using 160 bit message hash 'SHA1' for HMAC authentication
2024-04-22 12:24:44 Incoming Control Channel Authentication: Using 160 bit message hash 'SHA1' for HMAC authentication
2024-04-22 12:24:44 TCP/UDP: Preserving recently used remote address: [AF_INET]192.168.56.10:1194
2024-04-22 12:24:44 Socket Buffers: R=[212992->212992] S=[212992->212992]
2024-04-22 12:24:44 UDP link local: (not bound)
2024-04-22 12:24:44 UDP link remote: [AF_INET]192.168.56.10:1194
2024-04-22 12:24:44 NOTE: UID/GID downgrade will be delayed because of --client, --pull, or --up-delay
2024-04-22 12:24:44 TLS: Initial packet from [AF_INET]192.168.56.10:1194, sid=6d88ae32 67d5113e
2024-04-22 12:24:44 VERIFY OK: depth=1, CN=rpm
2024-04-22 12:24:44 VERIFY OK: depth=0, CN=vpn-server
2024-04-22 12:24:44 WARNING: 'link-mtu' is used inconsistently, local='link-mtu 1542', remote='link-mtu 1558'
2024-04-22 12:24:44 WARNING: 'keysize' is used inconsistently, local='keysize 128', remote='keysize 256'
2024-04-22 12:24:44 Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, peer certificate: 2048 bit RSA, signature: RSA-SHA256
2024-04-22 12:24:44 [vpn-server] Peer Connection Initiated with [AF_INET]192.168.56.10:1194
2024-04-22 12:24:44 PUSH: Received control message: 'PUSH_REPLY,route 10.10.10.0 255.255.255.0,topology net30,ifconfig 10.10.10.6 10.10.10.5,peer-id 0,cipher AES-256-GCM'
2024-04-22 12:24:44 OPTIONS IMPORT: --ifconfig/up options modified
2024-04-22 12:24:44 OPTIONS IMPORT: route options modified
2024-04-22 12:24:44 OPTIONS IMPORT: peer-id set
2024-04-22 12:24:44 OPTIONS IMPORT: adjusting link_mtu to 1625
2024-04-22 12:24:44 OPTIONS IMPORT: data channel crypto options modified
2024-04-22 12:24:44 Data Channel: using negotiated cipher 'AES-256-GCM'
2024-04-22 12:24:44 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
2024-04-22 12:24:44 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
2024-04-22 12:24:44 net_route_v4_best_gw query: dst 0.0.0.0
2024-04-22 12:24:44 net_route_v4_best_gw result: via 192.168.0.1 dev ens33
2024-04-22 12:24:44 ROUTE_GATEWAY 192.168.0.1/255.255.255.0 IFACE=ens33 HWADDR=00:0c:29:14:67:5e
2024-04-22 12:24:44 TUN/TAP device tun0 opened
2024-04-22 12:24:44 net_iface_mtu_set: mtu 1500 for tun0
2024-04-22 12:24:44 net_iface_up: set tun0 up
2024-04-22 12:24:44 net_addr_ptp_v4_add: 10.10.10.6 peer 10.10.10.5 dev tun0
2024-04-22 12:24:44 net_route_v4_add: 10.10.10.0/24 via 10.10.10.5 dev [NULL] table 0 metric -1
2024-04-22 12:24:44 GID set to nogroup
2024-04-22 12:24:44 UID set to nobody
2024-04-22 12:24:44 Initialization Sequence Completed




При успешном подключении проверяем пинг по внутреннему IP адресу  сервера в туннеле: ping -c 4 10.10.10.1 

root@sabo-virtual-machine:~# ping -c 4 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.856 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.556 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.497 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=0.975 ms

--- 10.10.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3055ms
rtt min/avg/max/mdev = 0.497/0.721/0.975/0.200 ms



Также проверяем командой ip r (netstat -rn) на хостовой машине что сеть туннеля импортирована в таблицу маршрутизации. 

oot@sabo-virtual-machine:~# netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         192.168.0.1     0.0.0.0         UG        0 0          0 ens33
10.10.10.0      10.10.10.5      255.255.255.0   UG        0 0          0 tun0
10.10.10.5      0.0.0.0         255.255.255.255 UH        0 0          0 tun0
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 ens33
192.168.0.0     0.0.0.0         255.255.255.0   U         0 0          0 ens33
192.168.56.0    0.0.0.0         255.255.255.0   U         0 0          0 vboxnet1

















