#!/bin/bash

##### GLOBAL VARIABLES #####
varxserver="<SERVER NAME>"
varxuser="<USER NAME>"



##### FUNCTIONS #####

var1func(){
read -p 'Clear current known hosts and Key-Pairs? (y|n): ' var1
if [[ $var1 == "y" ]]
then
	echo -e "\e[92mClearing current known hosts and Key-Pairs...\e[0m"
	echo -e "\tsudo rm -rf /root/.ssh"	#actually a command
elif [[ $var1 == "n" ]]
then
	echo -e "\e[91mNot clearing current known hosts and Key-Pairs\e[0m"
else
	var1func
fi
}


var2func(){
read -p 'Generate & Copy Key-Pair to a server? (y|n): ' var2

if [[ $var2 == "y" ]]
then
	echo -e "\e[92mGenerating new Key-Pair...\e[0m"
	echo -e "\tsudo ssh-keygen"	#actually a command
	read -p 'Enter the Domain/IP of the server: ' var2server
	read -p 'Enter the Username to the server: ' var2user
	echo -e "\e[92mCopying Key-Pair to a server\e[0m"
	echo -e "\tssh-copy-id $var2user@$var2server"	#actually a command
	echo -e "\e[92mAdding Server to known_hosts...\e[0m"
	echo -e "\tssh-keyscan -H $var2server >> ~/.ssh/known_hosts"	#actually a command
	varxserver=$var2server
	varxuser=$var2user
elif [[ $var2 == "n" ]]
then
	echo -e "\e[91mNot Copying Key-Pair to a server\e[0m"
else
	var2func
fi
}


var4func(){
read -p "Enable script at system startup? (y|n): " var4
if [[ $var4 == "y" ]]
then
	echo -e "\e[92mEnabling script at system startup...\e[0m"
	echo -e "\tsudo systemctl enable autossh-$var3name.service"	#actually a command
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
	echo -e "\tsudo apt-get --yes install autossh"	#actually a command
else
	echo -e "\e[92mPackage autossh is already installed\e[0m"
fi


echo ""
### Finishing touches ###
read -p 'Custom ssh command, if needed (e.g. "-R 443:localhost:80") to be used with autossh: ' var3custom
read -p 'Name of the to be created script (autossh-<stuff-you-enter>.service): ' var3name
echo -e "\e[92mSetting up scipt in /etc/systemd/system/autossh-"$var3name".service\e[0m"
echo "[Unit]
Description=Opens SSH Tunnel to "$varxserver"
After=network.target

[Service]
Environment=\"AUTOSSH_GATETIME=0\"
ExecStart=/usr/bin/autossh -M 0 -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 3\" -N "$var3custom" "$varxuser"@"$varxserver" -p 22 -i /root/.ssh/id_rsa

[Install]
WantedBy=multi-user.target" #> /etc/systemd/system/autossh-$var3name.service


echo -e ""
### Starting script ###
echo -e "\e[92mStarting script...\e[0m"
echo -e "\tsudo systemctl daemon-reload"	#actually a command
echo -e "\tsudo service autossh-$var3name start"	#actually a command
echo -e "\tsudo service autossh-$var3name status"	#actually a command


echo ""
### Enable script at startup ###
var4func
