#!/usr/bin/bash

function start {
	echo "###### Welcome to Auto DNS! ######"
	while true; do
		echo -e "Type \"options\" for help\nPlease choose an option: "
		read function_name

		if [ "$function_name" == "exit" ]; then
			echo "Exiting..."
			break
		fi

		if declare -f "$function_name" > /dev/null; then
			$function_name
			continue
		else
			echo -e "Error: Function '$function_name' not found.\n"
		fi
	done
}

#This function lists every option able to be run by the system
function options {
	echo -e "firewall_setup			dns_install		dns_zone_create		dns_new_record_forward\ndns_new_record_reverse		dns_forward_record_add	dns_reverse_record_add	dns_forward_record_delete\ndns_reverse_record_delete		exit\n"
}

#This is the function that is used to auto setup a UFW firewall intended for securing a DNS server.
#It will include rules such as Default Deny Incoming, Default Allow Outgoing, and allowing DNS traffic on port 53 over UDP
function firewall_setup {

	if ! command -v ufw &> /dev/null; then
		echo "UFW is not installed. Installing..."
		sudo apt install -y ufw
	else
		echo "UFW is already installed."
	fi

	echo "Setting default incoming policy to \"deny\"..."
	sudo ufw default deny incoming

	echo "Setting default outgoing to \"allow\"..."
	sudo ufw default allow outgoing

	echo "Allowing DNS traffic over port 53..."
	sudo ufw allow 53

	echo "Enabling UFW..."
	sudo ufw enable
}

#This is the finction that is used to auto install DNS on a system that if it is not installed yet.
#First, it will check for an install of Bind. If it is there, it will say, "Bind already installed"
#and exit. Otherwise, it will install.
function dns_install {
	if ! command -v named &> /dev/null; then
		echo "Bind is not installed. Installing..."
		sudo apt install -y bind9
	else
		echo "Bind is already installed."
	fi

	echo "Enabling DNS"
	sudo systemctl enable named

	echo "Starting DNS"
	sudo systemctl start named
}

#This will edit the config file and add a zone to the file according to the name provided from user input
function dns_zone_create {
	read -p "Enter New Zone Name: " ZONE_NAME
	CONFIG_FILE="/etc/bind/named.conf.local"

	echo -e "\n"

	echo -e "zone \"$ZONE_NAME\" {\n	type master;\n	file \"/var/named/$ZONE_NAME.zone\";\n	allow-update { none; };\n};" | sudo tee -a "$CONFIG_FILE"

	echo "Zone Configuration for '$ZONE_NAME' added to $CONFIG_FILE"

}

#This will create an entirely new forward record based on the name given and the area specified
function dns_new_record_forward {
	read -p "Enter Date (YYYYMMDD): " DATE
 	read -p "Enter Forward Record Name: " FORWARD_RECORD_NAME
 	FORWARD_RECORD_FILE="/var/named/$FORWARD_RECORD_NAME"

   	sudo touch $FORWARD_RECORD_FILE

	# Write the zone file using echo statements
	sudo bash -c "echo '\$TTL    86400' > $FORWARD_RECORD_FILE"
	sudo bash -c "echo '@	IN	SOA	ns1.$FORWARD_RECORD_NAME.	admin.$FORWARD_RECORD_NAME. (' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo '	${DATE}01	; Serial' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo '	3600	; Refresh' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo '	1800	; Retry' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo '	604800	; Expire' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo '	86400	; Minimum TTL' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo ')' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo '    IN	NS	ns1.$FORWARD_RECORD_NAME.' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo 'ns1	IN	A	192.168.0.1' >> $FORWARD_RECORD_FILE"
	sudo bash -c "echo 'www IN	A	192.168.0.2' >> $FORWARD_RECORD_FILE"

	echo "Zone file for '$ZONE_NAME' created at $ZONE_FILE"
}

#This will create an entirely new reverse record
function dns_new_record_reverse {
	echo "not yet implemented"
}

#This will add a line to the forward record named
function dns_forward_record_add {
	echo "not yet implemented"
}

#This function can be used to add a line to the DNS reverse file named
function dns_reverse_record_add {
	echo "not yet implemented"
}

#This will delete a line from the forward record named
function dns_forward_record_delete {
	echo "not yet implemented"
}

#This will delete a line from the reverse record named
function dns_reverse_record_delete {
	echo "not yet implemented"
}

start
