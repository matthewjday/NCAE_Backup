#!/usr/bin/bash

function start {
	echo -e"\n\n###### Welcome to Auto DNS! ######\n\n"
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
	echo -e "\n"
 	echo -e	"firewall_setup		install			zone_create		new_record_forward"
 	echo -e "new_record_reverse	forward_record_edit	reverse_record_edit	record_delete"
  	echo -e "list_one_record	list_all_records	exit\n"
}

#This is the function that is used to auto setup a UFW firewall intended for securing a DNS server.
#It will include rules such as Default Deny Incoming, Default Allow Outgoing, and allowing DNS traffic on port 53 over UDP
function firewall_setup {
	#Validates if UFW is already installed
	if ! command -v ufw &> /dev/null; then
		echo "Installing..."
		sudo apt install -y ufw
		echo "Setting default incoming policy to 'deny'..."
		sudo ufw default deny incoming
		echo "Setting default outgoing to 'allow'..."
		sudo ufw default allow outgoing
		echo "Allowing DNS traffic over port 53..."
		sudo ufw allow 53
		echo "Enabling UFW..."
		sudo ufw enable
	else
		echo "UFW is already installed."
	fi
}

#This is the finction that is used to auto install DNS on a system that if it is not installed yet.
#First, it will check for an install of Bind. If it is there, it will say, "Bind already installed"
#and exit. Otherwise, it will install.
function install {
	#validates if Bind is already installed
	if ! command -v named &> /dev/null; then
		echo "Installing..."
		sudo apt install -y bind9
  		echo "Enabling DNS..."
		sudo systemctl enable named
		echo "Starting DNS..."
		sudo systemctl start named
	else
		echo "Bind is already installed."
	fi
}

#This will edit the config file and add a zone to the file according to the name provided from user input
function zone_create {
	read -p "Enter New Zone Name: " ZONE_NAME
	CONFIG_FILE="/etc/bind/named.conf.local"

	#Validates the existance of the zone first
	if grep -q "zone \"$ZONE_NAME\"" "$CONFIG_FILE"; then
		echo "Error: Zone '$ZONE_NAME' already exists in '$CONFIG_FILE'."
	else
 		echo -e "\n"
		echo -e "zone \"$ZONE_NAME\" {\n	type master;\n	file \"/var/named/$ZONE_NAME.zone\";\n	allow-update { none; };\n};" | sudo tee -a "$CONFIG_FILE"
		echo "Zone Configuration for '$ZONE_NAME' added to $CONFIG_FILE"
 	fi
}

#This will create an entirely new forward record with the name given and the area specified
function new_record_forward {
	read -p "Enter Date (YYYYMMDD): " DATE
 	read -p "Enter Forward Record Name: " FORWARD_RECORD_NAME
 	FORWARD_RECORD_FILE="/var/named/${FORWARD_RECORD_NAME}.zone"
  
	#Validates the existance of the record first
	if [[ -f "$FORWARD_RECORD_FILE" ]]; then
        	echo "Error: Forward record file '$FORWARD_RECORD_FILE' already exists."
        else
	 	echo "Creating new Forward Record of '$FORWARD_RECORD_NAME'" 
	   	sudo touch $FORWARD_RECORD_FILE

		sudo bash -c "echo '\$TTL    86400' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo '@	IN	SOA	ns1.$FORWARD_RECORD_NAME.	admin.$FORWARD_RECORD_NAME. (' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo '	${DATE}01	; Serial' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo '	3600		; Refresh' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo '	1800		; Retry' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo '	1209600		; Expire' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo '	86400		; Minimum TTL' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo ')' >> $FORWARD_RECORD_FILE"
		sudo bash -c "echo -e '	IN	NS	ns1.$FORWARD_RECORD_NAME.\n' >> $FORWARD_RECORD_FILE"

		echo "Forward Record created at '$FORWARD_RECORD_FILE'"
	fi
}

#This will create an entirely new reverse record with the name given and the area specified
function new_record_reverse {
	read -p "Enter Date (YYYYMMDD): " DATE
 	read -p "Enter IP Range in Reverse Order: " REVERSE_RECORD_IP
 	REVERSE_RECORD_FILE="/var/named/${REVERSE_RECORD_IP}.in-addr.arpa.zone"

	if [[ -f "$REVERSE_RECORD_FILE" ]]; then
        	echo "Error: Reverse record file '$REVERSE_RECORD_FILE' already exists."
        else
	 	read -p "Enter Zone Name: " REVERSE_RECORD_NAME
   		echo "Creating new Reverse Record of '$REVERSE_RECORD_NAME'" 
	   	sudo touch $REVERSE_RECORD_FILE

		sudo bash -c "echo '\$TTL    86400' > $REVERSE_RECORD_FILE"
		sudo bash -c "echo '@	IN	SOA	ns1.$REVERSE_RECORD_NAME.	admin.$REVERSE_RECORD_NAME. (' >> $REVERSE_RECORD_FILE"
		sudo bash -c "echo '	${DATE}01	; Serial' >> $REVERSE_RECORD_FILE"
		sudo bash -c "echo '	3600		; Refresh' >> $REVERSE_RECORD_FILE"
		sudo bash -c "echo '	1800		; Retry' >> $REVERSE_RECORD_FILE"
		sudo bash -c "echo '	1209600		; Expire' >> $REVERSE_RECORD_FILE"
		sudo bash -c "echo '	86400		; Minimum TTL' >> $REVERSE_RECORD_FILE"
		sudo bash -c "echo ')' >> $REVERSE_RECORD_FILE"
		sudo bash -c "echo '	IN	NS	ns1.$REVERSE_RECORD_NAME.' >> $REVERSE_RECORD_FILE"

		echo "Reverse Record created at '$REVERSE_RECORD_FILE'"
  	fi
}

#This will add a line to the forward record named. It first checks to see if the file exists
function forward_record_edit {
	read -p "Enter Forward Record Name: " RECORD_NAME
 	FILE_NAME="/var/named/$RECORD_NAME"

	#Validates the existance of the record first
	if [[ ! -f "$FILE_NAME" ]]; then
    		echo "Error: File '$FILE_NAME' does not exist."
    	else
	     	echo "You are editing $FILE_NAME"
	 	read -p "Please enter subdomain: " SUB_DOMAIN
	  	read -p "Please enter record type: " RECORD_TYPE
	   	read -p "Please enter full IP Address: " IP_ADDRESS
	
	    	sudo bash -c "echo '$SUB_DOMAIN	IN	$RECORD_TYPE	$IP_ADDRESS' >> $FILE_NAME"
	
	     	echo "Line \"$SUB_DOMAIN	IN	$RECORD_TYPE	$IP_ADDRESS\" has been added to file $FILE_NAME"
	fi
}

#This function can be used to add a line to the DNS reverse record named. It will not edit a file if that file does not exist previously
function reverse_record_edit {
	read -p "Enter Reverse Record Name: " RECORD_NAME
 	FILE_NAME="/var/named/$RECORD_NAME"

	#Validates the existance of the record first
	if [[ ! -f "$FILE_NAME" ]]; then
    		echo "Error: File '$FILE_NAME' does not exist."
    	else
		echo "You are editing $FILE_NAME"
	 	read -p "Please enter final IP space: " IP_SPACE
	  	read -p "Please enter record type: " RECORD_TYPE
	   	read -p "Please enter full url: " URL
	
	    	sudo bash -c "echo '$IP_SPACE	IN	$RECORD_TYPE	$URL.' >> $FILE_NAME"
	
	     	echo "Line \"$IP_SPACE	IN	$RECORD_TYPE	$URL.\" has been added to file $FILE_NAME"
       fi
}

#This will delete a dns record from /var/named/
function record_delete {
	echo "WARNING: THIS WILL DELETE A FULL DNS RECORD. THERE IS NO RECOVERY"
	read -p "Enter Record Name: " RECORD_NAME
 	RECORD_FILE="/var/named/$RECORD_NAME"
	if [[ ! -f "$RECORD_FILE" ]]; then
	        echo "Error: Record file '$RECORD_FILE' does not exist."
	elif
 		read -p "Are you sure you want to delete '$RECORD_NAME'? Type 'yes' to continue: " CONFIRMATION
   		if [[ "$CONFIRMATION" != "yes" ]]; then
     			echo "Canceled."
		else
  			sudo rm $RECORD_FILE
 			echo "Record '$RECORD_NAME' Deleted"	
  		fi
	fi
}

#This functions lists every record located in /var/named
function list_all_records {
	echo -e "Listing all DNS Records...\n"
 	sudo ls /var/named/
  	echo -e "\n"
}

#This function prints a full record to the screen
function list_one_record {
	read -p "List record name: " RECORD_NAME
 	FILE_NAME="/var/named/$RECORD_NAME"

  	echo "Outputting record to screen: "
   	sudo cat $FILE_NAME
}

start
