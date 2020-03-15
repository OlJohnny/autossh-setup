#!/usr/bin/env bash
# github.com/OlJohnny | 2019

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace		# uncomment the previous statement for debugging



### global variables ###
autossh_server_ip="<SERVER NAME>"
autossh_server_user="<USER NAME>"
autossh_server_port="<SSH PORT>"


### text output colors ###
text_cyan="\e[96m"
text_green="\e[96m"
text_red="\e[91m"
text_reset="\e[0m"


### loop question: clear known hosts ###
_var1func(){
read -p $'\e[96mClear current known hosts and Key-Pairs? (y|n): \e[0m' var1
if [[ "${var1}" == "y" ]]
then
	echo -e "\e[92mClearing current known hosts and Key-Pairs...\e[0m"
	rm -rf /root/.ssh
elif [[ "${var1}" == "n" ]]
then
	echo -e "\e[91mNot clearing current known hosts and Key-Pairs\e[0m"
else
	_var1func
fi
}


### loop question: key-pair generation and copying ###
_var2func(){
read -p $'\e[96mGenerate & Copy a new Key-Pair to a server? (y|n): \e[0m' var2
if [[ "${var2}" == "y" ]]
then
	# generate key pair with: ECDSA, 384 bit and "Username@Server" as comment
	ssh-keygen -f /root/.ssh/autossh_id_ecdsa -t ecdsa -b 384 -C "${autossh_server_user}"@"${autossh_server_ip}"
	echo -e "\e[92mGenerating new Key-Pair (Hit Enter for default values, recommended)...\e[0m"
	echo -e "\e[92mCopying Key-Pair to a server...\e[0m"
	# create ".ssh" in your home directory to prevent mktemp errors
	mkdir --parents "${HOME}"/.ssh
	# copy key to given server
	ssh-copy-id -i /root/.ssh/autossh_id_ecdsa -p "${autossh_server_port}" "${autossh_server_user}"@"${autossh_server_ip}"
elif [[ "${var2}" == "n" ]]
then
	echo -e "\e[91mNot Copying Key-Pair to a server\e[0m"
else
	_var2func
fi
}


### loop question: install autossh ###
_var3func(){
read -p $'\e[96mDo you want to install autossh? (Package is needed to complete the run of this script) (y|n): \e[0m' var1
if [[ "${var1}" == "y" ]]
then
	echo -e "\e[92mInstalling autossh...\e[0m"
	apt-get update
	apt-get --yes install autossh
elif [[ "${var1}" == "n" ]]
then
	echo -e "\e[91mPackage is needed to complete the run of this script.\e[0m"
	echo "Exiting..."
	exit
else
	_var3func
fi
}

### loop question: enable at system startup ###
_var4func(){
read -p $'\e[96mEnable script at system startup? (y|n): \e[0m' var4
if [[ "${var4}" == "y" ]]
then
	echo -e "\e[92mEnabling script at system startup...\e[0m"
	systemctl enable autossh-"${autossh_service_name}".service
elif [[ "${var4}" == "n" ]]
then
	echo -e "\e[91mNot Enabling script at system startup\e[0m"
else
	_var4func
fi
}


### check for root privilges ###
if [[ "${EUID}" != 0 ]]
then
	echo -e "\e[91mPlease run as root.\e[39m Root privileges are needed to move and delete files"
	exit
fi


### install autossh ###
echo "Checking if autossh is installed..."
if [[ $(dpkg-query --show --showformat='${Status}' autossh 2>/dev/null | grep --count "ok installed") == 0 ]];
then
	_var3func
else
	echo -e "\e[92mPackage autossh is already installed\e[0m"
fi


### clear current known hosts and key-pairs ###
echo ""
_var1func
echo ""


### get server-ip, -ip and -ssh-port ###
read -p $'\e[96mEnter the Domain/IP of the server to connect to: \e[0m' autossh_server_ip
read -p $'\e[96mEnter the Username to the server to connect to: \e[0m' autossh_server_user
read -p $'\e[96mEnter the SSH port to the server: \e[0m' autossh_server_port


### generate & copy key-pair to a server ###
echo ""
_var2func
echo ""


### finishing touches ###
read -p $'\n\e[96mCustom ssh command to be used with autossh, if needed (e.g. "-R 8870:localhost:80") : \e[0m' autossh_custom_command
read -p $'\e[96mName of the created script (e.g. Input "cloud" results in "autossh-cloud.service"): \e[0m' autossh_service_name
echo -e "\e[92mSetting up script in /etc/systemd/system/autossh-"${autossh_service_name}".service...\e[0m"
echo "[Unit]
Description=Opens SSH Tunnel to "${autossh_server_ip}"
After=network.target

[Service]
Environment=\"AUTOSSH_GATETIME=0\"
ExecStart=/usr/bin/autossh -M 0 -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 3\" -N "${autossh_custom_command}" "${autossh_server_user}"@"${autossh_server_ip}" -p "${autossh_server_port}" -i /root/.ssh/autossh_id_ecdsa

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/autossh-"${autossh_service_name}".service


### adding "ServerAliveInterval" & "ServerAliveCountMax" to config ###
echo -e "\e[96mAdding ServerAliveInterval to ssh config...\e[0m"
(cat /etc/ssh/ssh_config | grep "^ *ServerAliveInterval [0-9]*$" || echo "### AUTO GENERATED CONFIG ADDITION BY autossh-setup.sh ON <"$(date +"%T")">
ServerAliveInterval 40
ServerAliveCountMax 5" >> /etc/ssh/ssh_config)
echo -e "\e[92mServerAliveInterval was added to ssh config\e[0m"


### applying config by reloading ssh service ###
echo ""
echo -e "\e[96mReloading ssh client...\e[0m"
(service ssh reload || :)


### starting script ###
echo ""
echo -e "\e[92mStarting script...\e[0m"
systemctl daemon-reload
service autossh-"${autossh_service_name}" start
service autossh-"${autossh_service_name}" status


### enable script at startup ###
echo ""
_var4func


### exiting ###
echo -e ""${text_cyan}"\nFinished\nExiting..."${text_reset}""
