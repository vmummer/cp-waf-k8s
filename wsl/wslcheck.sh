#!/bin/bash
# June 18, 2025
# Write by Vince Mammoliti - vincem@checkpoint.com
#
# This script is used to check the wls setup when working with microK8S
# It reads in the /etc/wsl.conf and provides suggestions.
# Included in this scripts is items I learned need to be set for the setup to function properly.  There maybe other 
# methods, but these are what I found work for me.  If you have suggestion, please forward.

declare -A config
section=""
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'        # Green

# This section reads in the /etc/wsl.conf file into an array called 'config' 
#
while IFS= read -r line || [[ -n "$line" ]]; do
    # Remove comments and trim whitespace
    line="${line%%#*}"
    line="${line%%;*}"
    line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Section header
    if [[ "$line" =~ \[(.*)\] ]]; then
        section="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        key="$(echo -e "${key}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        value="$(echo -e "${value}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        config["$section.$key"]="$value"
    fi
done < "/etc/wsl.conf"

# Now that we have the information in a array, we will being checking 

echo "Check Point WAF Lab - WSL & MicroK8S setup check - 2025-06"

# Check to see if the system's host name has any capital letters.  If it does this causes issues with microk8s and RBAC

echo -n "1) Check if host has only lower case letters: "
if [[ hostname =~ [A-Z] ]]; 
	then  echo -e "${RED}FAILED >>> WARNING <<< hostname contains Capital Letters. ${NC} When using microk8s the capital letters in the hostname will cause RBAC errors which will lead to services not starting."
echo "Rename host name to all lower case to continue!";
 exit 1;

else
	echo -e "${GREEN}PASS${NC}"
fi

# Check to see if systemd is enabled on the system.  This is required.
echo -n "2) Check if [boot] systemd=true in wsl.conf: "

if [[ ${config[boot.systemd]} == "true" ]]; then  echo -e "${GREEN}PASS${NC}"; else  echo -e "${RED}FAILED ${NC} - Please add systemd = true in wsl.conf and restart wsl";
  fi

# Check the following in the [network] settings

echo -n "3) Check if [network] hostname={defined name} in wsl.conf: "

if [[ ${config[network.hostname]} ]]; then  echo -e "${GREEN}${config[network.hostname]}${NC}"; else  echo -en "No hostname defined. System will use laptop host name: "; hostname;
  fi

# Check to see if generateResolvConf is disabled
#

echo -n "4) Check if auto update of /etc/resolve.conf has been disabled: "
if [[ ${config[network.generateResolvConf]} == "false" ]]; then  echo -e "${GREEN}PASS${NC}"; else  echo -e "${RED}FAILED ${NC}- Please add generateResolvConf=false.  We don't want WSL to change this setting, as we will do it manually";
  fi


echo -n "5) Check if auto update of /etc/hosts has been disabled: "
if [[ ${config[network.generateHosts]} == "false" ]]; then  echo -e "${GREEN}PASS${NC}"; else  echo -e "${RED}FAILED${NC} - Please add generateHosts=false.  We don't want WSL to change this setting, as we will do it manually";
  fi


echo -n "6) Check if a nameserver is defined in the /etc/resolv.conf "
if cat /etc/resolv.conf | grep -q -o 'nameserver'; then echo -e "${GREEN}PASS${NC}"; echo -n "    "; cat /etc/resolv.conf; 
	else echo -e "${RED}FAILED${NC} - No nameserver defined.  Please add 'nameserver 1.1.1.1 to resolve"
fi


echo -n "7) Check if the file /etc/resolv.conf has the Immutable attribute set to prevent modification, deletion or renaming: "
if lsattr -l /etc/resolv.conf |  grep -q -o 'Immutable'; then echo -e "${GREEN}PASS${NC}";
else echo -e  "${RED}FAILED${NC} - The Immutable file attribute is not set on /etc/resolv.conf.  Use chatter +i /etc/resolv.conf to correct. "
  fi

echo -n "8) Check if the defined host name is in /etc/hosts file: "
if cat /etc/hosts |grep  '127.0.1.1' |grep -q -o [hostname]; then  echo -e "${GREEN}PASS${NC}";
	else echo -e "${RED}FAILED${NC} - Add hostname to the /etc/hosts file";
	     echo "Example:  127.0.1.1 lab"
fi


