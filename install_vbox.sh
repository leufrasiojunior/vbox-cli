#!/bin/bash

# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 70 ? 70 : c ))

#Se tiver algum erro, sai do configurador.
set -e

####VARIABLES####

####### FUNCTIONS ##########
spinner()
{
    local pid=$1
    local delay=0.50
    local spinstr='/-\|'
    while [ "$(ps a | awk '{print $1}' | grep "${pid}")" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "${spinstr}"
        local spinstr=${temp}${spinstr%"$temp"}
        sleep ${delay}
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

Distro_check(){
	
	dist=$($SUDO cat /etc/*-release | grep -i code | tail -n 1 | cut -d"=" -f2)
	release=$($SUDO cat /etc/*-release | grep -i release | cut -d "=" -f 2)
	ver=$(echo "$release > 16.04" | bc)
	
	if ! whiptail --backtitle "Ubuntu Version is $release $dist" \
	--title "VirtualBox Startup" --yesno "You are using $dist Ubuntu Version. It is correct?\nWill be used to configure APT." ${r} ${c}; then
	dist=$(whiptail --backtitle "Codename Ubuntu" \
	--title "VirtualBox Startup" --inputbox "Please, insert codename system." ${r} ${c} 3>&1 1>&2 2>&3) || \
	#If cancel select, exit...
	{ printf "Process canceled. Exiting...\\n" ; exit 1; }
	fi
	cat  >> /etc/apt/sources.list << EOF
	#Virtualbox
	deb https://download.virtualbox.org/virtualbox/debian $dist contrib 
EOF
#	$SUDO apt update
#	$SUDO apt-get install virtualbox-6.1
	

	if [[ ${ver} -eq 1 ]]; then
		echo "\n::: System Version is é $release. Install certificate...". 
		wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
	else
		echo "\nSystem Version is é $release. Install certificate..". 
		wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
	fi	
	echo "::: Wait... Apt update in progress..."
	sudo apt-get update -qq & spinner $!
	$SUDO apt update
        $SUDO apt-get install virtualbox-6.0
	update_expack
}

update_expack(){
VERSION=$(VBoxManage --version | sed 's/r/\-/')
MAIN=$(VBoxManage --version | cut -d"r" -f1)
EXTPACK=Oracle_VM_VirtualBox_Extension_Pack-$VERSION.vbox-extpack

if [ -f $EXTPACK ]; then
   #echo "$EXTPACK foi encontrado. Instalando..."
   sudo VBoxManage extpack install --replace $EXTPACK
else
   #echo "Arquivo não encontrado. Baixando o $EXTPACK da internet"
   wget http://download.virtualbox.org/virtualbox/$MAIN/$EXTPACK
   if [ $? -eq 0 ]; then
      #echo "Arquivo baixado. Instalando..."
      yes | sudo VBoxManage extpack install --replace $EXTPACK
   else
      echo "::: Expack install fail! Try Again..."
      exit
   fi
fi
}

main() {

    ######## FIRST CHECK ########
    # Must be root to install
    echo ":::"
    if [[ $EUID -eq 0 ]];then
        echo "::: You are root."
    else
        echo "::: sudo will be used for the install."
        # Check if it is actually installed
        # If it isn't, exit because the install cannot complete
        if [[ $(dpkg-query -s sudo) ]];then
            export SUDO="sudo"
            export SUDOE="sudo -E"
        else
            echo "::: Please install sudo or run this as root."
            exit 1
        fi
    fi
	
	OPTIN=$(whiptail --backtitle "Install Virtualbox" --title "VirtualBox" --menu "Select Option" ${r} ${c} 3 \
	"1" "Fazer Tudo" \
	"2" "Instalar VirtualBox" \
	"3" "Instalar Pacote de Extenção" \
	"4" "Sair" 3>&2 2>&1 1>&3) || \
    { echo "::: Cancel selected. Exiting"; exit 1; }
	
	case $OPTIN in
		1) Distro_check; update_expack;;
		2) Distro_check;;
		3) update_expack;;
		4) exit;;
		
	esac
}

main
