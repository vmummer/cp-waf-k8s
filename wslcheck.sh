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
echo "systemd.enabled = ${config[boot.systemd]}"
echo "network.hostname =  ${config[network.hostname]}"

echo "network.generateResolvConf =  ${config[network.generateResolvConf]}"
echo "network.generateHosts =  ${config[network.generateHosts]}"

# Check to see if the system's host name has any capital letters.  If it does this causes issues with microk8s and RBAC

echo -n "1) Check if host has only lower case letters: "
if [[ hostname =~ [A-Z] ]]; 
	then  echo "FAILED >>> WARNING <<< hostname contains Capital Letters. When using microk8s the capit
al letters in the hostname will cause many different type of failures. Rename host name to all lower case to continue!";
 exit 1;

else
	echo "PASS"
fi

# Check to see if systemd is enabled on the system.  This is required.
echo -n "2) Check if systemd is enabled in wsl.conf: "

if [[ ${config[boot.systemd]} == "true" ]]; then  echo "PASS"; else  echo "FAILED - Please add systemd = true in wsl.conf and restart wsl";
  fi

lsattr -l /etc/resolv.conf
