#!/bin/bash
#install and configure NO-IP DUC.
#Licente: GNU
set -e


install(){
	wget -c -P /usr/local/src https://www.noip.com/client/linux/noip-duc-linux.tar.gz
	tar xf noip-duc-linux.tar.gz -C /usr/local/src --strip-components=1
	cd /usr/local/src
	make
	make install
configure
}


configure(){
cat  >> /etc/systemd/system/noip2.service << EOF
[Unit]
Description=No-ip.com dynamic IP address updater
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target
Alias=noip.service

[Service]
#Start main service
ExecStart=/usr/local/bin/noip2
Restart=always
Type=forking
EOF

#Reload Systemd Service
systemctl daemon-reload

#Enable start on boot.
systemctl enable noip2

#Start service
systemctl start noip2
}

main(){
    ######## FIRST CHECK ########
    # Must be root to install
    echo ":::"
    if [[ $EUID -eq 0 ]];then
        echo "::: Você é root"
		install
    else
		echo "::: Execute como sudo ou root."
    fi

}

main
