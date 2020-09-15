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
text_info="\e[96m"
text_yes="\e[92m"
text_no="\e[91m"
text_reset="\e[0m"
read_question=$'\e[93m'
read_reset=$'\e[0m'


### loop question: clear known hosts ###
_var1func(){
read -p ""${read_question}"Clear current Known-Hosts and Key-Pairs? (y|n): "${read_reset}"" var1
if [[ "${var1}" == "y" ]]
then
	echo -e ""${text_yes}"Clearing current Known-Hosts and Key-Pairs..."${text_reset}""
	rm -rf /root/.ssh
elif [[ "${var1}" == "n" ]]
then
	echo -e ""${text_no}"Not clearing current Known-Hosts and Key-Pairs"${text_reset}""
else
	_var1func
fi
}


### loop question: key-pair generation and copying ###
_var2func(){
read -p ""${read_question}"Generate & Copy a new Key-Pair to a server? (y|n): "${read_reset}"" var2
if [[ "${var2}" == "y" ]]
then
	# generate key pair with: ECDSA, 384 bit and "Username@Server" as comment
	ssh-keygen -f /root/.ssh/autossh_id_ecdsa -t ecdsa -b 384 -C "${autossh_server_user}"@"${autossh_server_ip}"
	echo -e ""${text_yes}"Generating new Key-Pair (Hit Enter for default values, recommended)..."${text_reset}""
	echo -e ""${text_yes}"Copying Key-Pair to a server..."${text_reset}""
	# create ".ssh" in your home directory to prevent mktemp errors
	mkdir --parents "${HOME}"/.ssh
	# copy key to given server
	ssh-copy-id -i /root/.ssh/autossh_id_ecdsa -p "${autossh_server_port}" "${autossh_server_user}"@"${autossh_server_ip}"
elif [[ "${var2}" == "n" ]]
then
	echo -e ""${text_no}"Not Copying Key-Pair to a server"${text_reset}""
else
	_var2func
fi
}


### loop question: install autossh ###
_var3func(){
read -p ""${read_question}"Do you want to install autossh? (Package is needed to complete the run of this script) (y|n): "${read_reset}"" var1
if [[ "${var1}" == "y" ]]
then
	echo -e ""${text_yes}"Installing autossh..."${text_reset}""
	apt-get update
	apt-get --yes install autossh
elif [[ "${var1}" == "n" ]]
then
	echo -e ""${text_no}"Package is needed to complete the run of this script."${text_reset}""
	echo -e ""${text_no}"Exiting..."${text_reset}""
	exit
else
	_var3func
fi
}


### loop question: enable at system startup ###
_var4func(){
read -p ""${read_question}"Enable script at system startup? (y|n): "${read_reset}"" var4
if [[ "${var4}" == "y" ]]
then
	echo -e ""${text_yes}"Enabling script at system startup..."${text_reset}""
	systemctl enable autossh-"${autossh_service_name}".service
elif [[ "${var4}" == "n" ]]
then
	echo -e ""${text_no}"Not Enabling script at system startup"${text_reset}""
else
	_var4func
fi
}


### check for root privilges ###
if [[ "${EUID}" != 0 ]]
then
	echo -e ""${text_no}"Please run as root. Root privileges are needed to create and modify configurations/files"${text_reset}""
	exit
fi


### install autossh ###
echo -e ""${text_info}"Checking if autossh is installed..."${text_reset}""
if [[ $(dpkg-query --show --showformat='${Status}' autossh 2>/dev/null | grep --count "ok installed") == 0 ]];
then
	_var3func
else
	echo -e ""${text_info}"Package autossh is already installed"${text_reset}""
fi


### clear current known-hosts and key-pairs ###
echo ""
_var1func


### get server-ip, -ssh-port and -user ###
echo ""
read -p ""${read_question}"Enter the Domain/IP of the server to connect to: "${read_reset}"" autossh_server_ip
read -p ""${read_question}"Enter the SSH port to the server: "${read_reset}"" autossh_server_port
read -p ""${read_question}"Enter the Username to the server to connect to: "${read_reset}"" autossh_server_user


### generate & copy key-pair to a server ###
echo ""
_var2func


### finishing touches ###
echo ""
read -p ""${read_question}"Additional ssh options (e.g. '-R 8870:localhost:80'): "${read_reset}"" autossh_custom_command
read -p ""${read_question}"Name of the created script (e.g. Input 'cloud' results in 'autossh-cloud.service'): "${read_reset}"" autossh_service_name
echo -e ""${text_info}"Setting up script in /etc/systemd/system/autossh-"${autossh_service_name}".service..."${text_reset}""
echo "[Unit]
Description=Maintains a SSH Tunnel to "${autossh_server_user}"@"${autossh_server_ip}":"${autossh_server_port}" for "${autossh_service_name}"
After=network.target

[Service]
Environment=\"AUTOSSH_GATETIME=0\"
ExecStart=/usr/bin/autossh -M 0 -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 3\" -N "${autossh_custom_command}" "${autossh_server_user}"@"${autossh_server_ip}" -p "${autossh_server_port}" -i /root/.ssh/autossh_id_ecdsa

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/autossh-"${autossh_service_name}".service


### adding "ServerAliveInterval" & "ServerAliveCountMax" to config ###
echo ""
echo -e ""${text_info}"Adding ServerAliveInterval to ssh client config..."${text_reset}""
(cat /etc/ssh/ssh_config | grep "^ *ServerAliveInterval [0-9]*$" || echo "### AUTO GENERATED CONFIG ADDITION BY autossh-setup.sh ON $(date +"%Y.%m.%d %T")
ServerAliveInterval 40
ServerAliveCountMax 5" >> /etc/ssh/ssh_config)
echo -e ""${text_info}"ServerAliveInterval was added to ssh client config"${text_reset}""


### applying config by reloading ssh service ###
echo ""
echo -e ""${text_info}"Reloading ssh client to apply updated config..."${text_reset}""
(service ssh reload || :)


### starting script ###
echo ""
echo -e ""${text_info}"Starting script..."${text_reset}""
systemctl daemon-reload
service autossh-"${autossh_service_name}" start
service autossh-"${autossh_service_name}" status


### enable script at startup ###
echo ""
_var4func


### exiting ###
echo ""
echo -e ""${text_info}"Finished\nExiting..."${text_reset}""
