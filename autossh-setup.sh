#!/usr/bin/env bash
# github.com/OlJohnny | 2019

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace		# uncomment the previous statement for debugging



##### GLOBAL VARIABLES #####
varxserver="<SERVER NAME>"
varxuser="<USER NAME>"
varxport="<SSH PORT>"



##### FUNCTIONS #####
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
read -p $'\e[96mGenerate & Copy Key-Pair to a server? (y|n): \e[0m' var2
if [[ "${var2}" == "y" ]]
then
	read -p $'\e[96mEnter the Domain/IP of the server: \e[0m' var2server
	read -p $'\e[96mEnter the Username to the server: \e[0m' var2user
	read -p $'\e[96mEnter the SSH port to the server: \e[0m' var2port
	# generate key pair with: ECDSA, 384 bit and "Username@Server" as comment
	ssh-keygen -f /root/.ssh/autossh_id_ecdsa -t ecdsa -b 384 -C "${var2user}"@"${var2server}"
	echo -e "\e[92mGenerating new Key-Pair (Hit Enter for default values, recommended)...\e[0m"
	echo -e "\e[92mCopying Key-Pair to a server...\e[0m"
	# create ".ssh" in your home directory to prevent mktemp errors
	mkdir "${HOME}"/.ssh
	# copy key to given server
	ssh-copy-id -i /root/.ssh/autossh_id_ecdsa -p "${var2port}" "${var2user}"@"${var2server}"
elif [[ "${var2}" == "n" ]]
then
	echo -e "\e[91mNot Copying Key-Pair to a server\e[0m\n"
	read -p $'\e[96mEnter the Domain/IP of the server to connect to: \e[0m' var2server
	read -p $'\e[96mEnter the Username to the server to connect to: \e[0m' var2user
	read -p $'\e[96mEnter the SSH port to the server: \e[0m' var2port
else
	_var2func
fi
varxserver="${var2server}"
varxuser="${var2user}"
varxport="${var2port}"
}


### install autossh function ###
_var3func(){
read -p $'\e[96mDo you want to install autossh? (Errors can occur, when files are in the wrong format) (y|n): \e[0m' var1
if [[ "${var1}" == "y" ]]
then
	echo -e "\e[92mInstalling autossh...\e[0m"
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
	systemctl enable autossh-"${var3name}".service
elif [[ "${var4}" == "n" ]]
then
	echo -e "\e[91mNot Enabling script at system startup\e[0m"
else
	_var4func
fi
}



##### PREPARATION #####
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



##### ACTUAL CODE #####
### Clear current known hosts and Key-Pairs ###
echo ""
_var1func


### Generate & Copy Key-Pair to a server ###
echo ""
_var2func


### Finishing touches ###
read -p $'\n\e[96mCustom ssh command to be used with autossh, if needed (e.g. "-R 8870:localhost:80") : \e[0m' var3custom
read -p $'\e[96mName of the created script (e.g. Input "cloud" results in "autossh-cloud.service"): \e[0m' var3name
echo -e "\e[92mSetting up scipt in /etc/systemd/system/autossh-"${var3name}".service...\e[0m"
echo "[Unit]
Description=Opens SSH Tunnel to "${varxserver}"
After=network.target

[Service]
Environment=\"AUTOSSH_GATETIME=0\"
ExecStart=/usr/bin/autossh -M 0 -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 3\" -N "${var3custom}" "${varxuser}"@"${varxserver}" -p "${varxport}" -i /root/.ssh/autossh_id_rsa

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/autossh-"${var3name}".service


### Adding ServerAliveInterval to config ###
echo -e "\e[96mAdding ServerAliveInterval to ssh config...\e[0m"
(cat /etc/ssh/ssh_config | grep "^ *ServerAliveInterval [0-9]*$" || echo "
### AUTO GENERATED CONFIG ADDITION BY autossh-setup.sh
ServerAliveInterval 120" >> /etc/ssh/ssh_config)
echo -e "\e[92mServerAliveInterval was added to ssh config\e[0m"
echo -e "\e[96mRestarting ssh daemon...\e[0m"
service sshd reload


### Starting script ###
echo -e "\n\e[92mStarting script...\e[0m"
systemctl daemon-reload
service autossh-"${var3name}" start
service autossh-"${var3name}" status


### Enable script at startup ###
echo ""
_var4func



##### FINISHING #####
echo -e "\n<$(date +"%T")> Finished\nExiting..."