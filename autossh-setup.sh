#!/bin/bash

echo hi
read -p 'Clear current known hosts and Key-Pairs? (y|n):  ' var1

if [[ $var1 == "y" ]]
then
	echo "yes, I did that"
	#/home/$username$/.ssh/* löschen
	#/root/.ssh/known_hosts Inhalt löschen
elif [[ $var1 == "n" ]]
then
	echo "no, I did NAHT do that"
fi
echo ""


echo "Generating new Key-Pair..."
#ssh-keygen
echo ""


read -p 'Copy Key-Pair to a server? (y|n):  ' var2

if [[ $var1 == "y" ]]
then
	echo "yeet" $var2
	read -p 'Enter the Domain/IP of the server:  ' var2server
	read -p 'Enter the Username of the server:  ' var2username
	#ssh-copy-id $var2username@$var2server
	echo "Adding Server to known_hosts..."
	#ssh-keyscan -H $var2server >> ~/.ssh/known_hosts
elif [[ $var1 == "n" ]]
then
	echo "no, I did NAHT do that"
fi
echo ""


echo "Checking if autossh is installed..."

if [ $(dpkg-query -W -f='${Status}' autossh 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
	echo "Installing autossh..."
#	sudo apt-get --yes install autossh;
 else
	echo "Package autossh is already installed"
fi
echo ""


read -p 'Custom ssh command (e.g. "-R 8820:localhost:22") to be used with autossh:  ' var3custom
read -p 'Name of the script (e.g. autossh-"stuff-you-enter"):  ' var3name
echo "Setting up scipt in /etc/systemd/system/autossh-"$var3name
#bli bla blub


echo "Starting script..."
sudo systemctl daemon-reload
#sudo service autossh-$var3name start
#sudo service autossh-$var3name status
echo ""


read -p "Enable script at system startup? (y|n):  " var4
if [[ $var4 == "y" ]]
then
	echo "yes, I did that"
	#sudo systemctl enable autossh-$var3name.service
elif [[ $var4 == "n" ]]
then
	echo "no, I did NAHT do that"
fi
echo ""