#!/bin/bash

##### check for root privilges #####
if [ "$EUID" -ne 0 ]
then
  echo -e "\e[91mPlease run as root.\e[39m Root privileges are needed to execute ssh commands."
  exit
fi

##### GLOBAL VARIABLES #####
varxserver="<SERVER NAME>"
varxuser="<USER NAME>"



##### FUNCTIONS #####

var1func(){
read -p $'\e[96mClear current known hosts and Key-Pairs? (y|n): \e[0m' var1
if [[ $var1 == "y" ]]
then
	echo -e "\e[92mClearing current known hosts and Key-Pairs...\e[0m"
	sudo rm -rf /root/.ssh
elif [[ $var1 == "n" ]]
then
	echo -e "\e[91mNot clearing current known hosts and Key-Pairs\e[0m"
else
	var1func
fi
}


var2func(){
read -p $'\e[96mGenerate & Copy Key-Pair to a server? (y|n): \e[0m' var2

if [[ $var2 == "y" ]]
then
	echo -e "\e[92mGenerating new Key-Pair (Hit Enter for default values, recommended)...\e[0m"
	sudo ssh-keygen	-f /root/.ssh/autossh_id_rsa #actually a command
	read -p $'\e[96mEnter the Domain/IP of the server: \e[0m' var2server
	read -p $'\e[96mEnter the Username to the server: \e[0m' var2user
	echo -e "\e[92mCopying Key-Pair to a server...\e[0m"
	sudo ssh-copy-id -i /root/.ssh/autossh_id_rsa $var2user@$var2server	#actually a command
elif [[ $var2 == "n" ]]
then
	echo -e "\e[91mNot Copying Key-Pair to a server\e[0m"
	echo ""
	read -p $'\e[96mEnter the Domain/IP of the server to connect to: \e[0m' var2server
	read -p $'\e[96mEnter the Username to the server to connect to: \e[0m' var2user
else
	var2func
fi
echo -e "\e[92mAdding Server to known_hosts...\e[0m"
sudo ssh-keyscan -H $var2server >> ~/.ssh/known_hosts	#actually a command
varxserver=$var2server
varxuser=$var2user
}


var4func(){
read -p $'\e[96mEnable script at system startup? (y|n): \e[0m' var4
if [[ $var4 == "y" ]]
then
	echo -e "\e[92mEnabling script at system startup...\e[0m"
	sudo systemctl enable autossh-$var3name.service	#actually a command
elif [[ $var4 == "n" ]]
then
	echo -e "\e[91mNot Enabling script at system startup\e[0m"
else
	var4func
fi
}



##### ACTUAL CODE #####

### Clear current known hosts and Key-Pairs ###
var1func


echo ""
### Generate & Copy Key-Pair to a server ###
var2func


echo ""
### Install autossh ###
echo "Checking if autossh is installed..."

if [ $(dpkg-query -W -f='${Status}' autossh 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
	echo -e "\e[92mInstalling autossh...\e[0m"
	sudo apt-get --yes install autossh	#actually a command
else
	echo -e "\e[92mPackage autossh is already installed\e[0m"
fi


echo ""
### Finishing touches ###
read -p $'\e[96mCustom ssh command to be used with autossh, if needed (e.g. "-R 443:localhost:80") : \e[0m' var3custom
read -p $'\e[96mName of the created script (e.g. Input "443-80" results in "autossh-443-80.service"): \e[0m' var3name
echo -e "\e[92mSetting up scipt in /etc/systemd/system/autossh-"$var3name".service...\e[0m"
echo "[Unit]
Description=Opens SSH Tunnel to "$varxserver"
After=network.target

[Service]
Environment=\"AUTOSSH_GATETIME=0\"
ExecStart=/usr/bin/autossh -M 0 -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 3\" -N "$var3custom" "$varxuser"@"$varxserver" -p 22 -i /root/.ssh/autossh_id_rsa

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/autossh-$var3name.service


echo -e ""
### Starting script ###
echo -e "\e[92mStarting script...\e[0m"
sudo systemctl daemon-reload	#actually a command
sudo service autossh-$var3name start	#actually a command
sudo service autossh-$var3name status	#actually a command


echo ""
### Enable script at startup ###
var4func
