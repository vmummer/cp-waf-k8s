#!/usr/bin/env bash
#export TOKEN=
# Dec 3, 2024 added K8S Ingress IP address
# Mar 31, 2025 Added 
# April 17, 2025 - Adding the user of helm chart and dynamic Pod names.
# June 2, 2025 - Added hostname Capitals check.
# July 18, 2025 - Updated aliase to reflect the updated selfcontained testhost
# Aug 20, 2025 - Added check to see if cp-appsec was enabled before trying to get variables.
# Aug 15, 2025 - Added variable $HOST_IP and command cpmetallb 
# Aug 28, 2025 - Added cpcurljuiceshop & cpcurlvampi 
# Sept 5, 2025 - Added to run just the TestHost in Docker Container and passing DEFAULT URL
# Sept 11, 2025 - Added Aliases for cpwafciser 
# Sept 12  2025 - Fixed Metallb command
# Sept 22, 2025 - Moved to namespace - webapps (juiceshop and Vampi) - wafciser (wafciser)
# Sept 26, 2025 - Add cpuptemp alias command to create the coredns.yaml file
# Oct  28, 2025 - 3.5 changed metallb to use HOST_IP
# Nov  05, 2055 - 3.6 Added Microk8s check.
if [[ hostname =~ [A-Z] ]]; then  echo ">>> WARNING <<< hostname contains Capital Letters. When using microk8s the capital letters in the hostname will cause many different type of failures. Rename host name to all lower case to continue!"; exit 1; fi

VER=3.6
export DEFAULT_URL_CPTRAFFIC="http://juiceshop.lab"
export DEFAULT_URL_CPAPI="http://vampi.lab"
echo "Check Point WAF on Kubernetes Lab Alias Commands.  Use cphelp for list of commands. Ver: $VER"
#!/bin/bash

check_microk8s() {
    if command -v microk8s >/dev/null 2>&1; then
#        echo "✅ MicroK8s is installed"
        # Check if MicroK8s is running
        if microk8s status | grep -q "microk8s is running"; then
            echo "✅ MicroK8s is intstalled and running"
	    alias kubectl=microk8s.kubectl
            alias helm='/snap/bin/microk8s.helm'
            return 0
        else
            echo "❌ MicroK8s is installed but not running"
            return 1
        fi
    else
        echo "❌ MicroK8s is not installed"
        echo "Please install MicroK8s using: sudo snap install microk8s --classic"
        return 1
    fi
}

# Call the function
check_microk8s



alias k="kubectl"
alias ka="kubectl apply"
alias kd="kubectl delete"
alias kp="kubectl get pods -A"
alias ks="kubectl get svc -A --output wide"
export HOST_IP="`hostname -I| awk ' {print $1}'`"
WAPAPP=cp-appsec-cloudguard-waf-ingress-nginx-controller

if k get pods -A | grep -q -o 'cp-appsec' ; then 
	export	INGRESS_IP="`microk8s.kubectl get  svc $WAPAPP -o json | jq -r  .status.loadBalancer.ingress[].ip`"
	get_WAFPOD ()  {
	WAFPOD="`microk8s.kubectl get pods -o=jsonpath='{.items..metadata.name}' | grep cp-appsec`"
	}
fi

alias wafciser='k exec -it wafciser -n wafciser -- bash /home/cp/cpwafciser.sh'
alias cptraffic='k exec -it wafciser -n wafciser -- bash /home/cp/cp_traffic.sh'
alias cpapitrainer='k exec -it wafciser -n wafciser -- bash /home/cp/cpapitrlocal.sh'
alias wafciserhost='k exec -it wafciser  -n wafciser -- bash'
alias cpsqlmapupdate='k exec -it wafciser -n wafciser -- sqlmap --update'
alias cpnano='get_WAFPOD && k exec -it $WAFPOD -- cpnano'
alias cpnanoc='get_WAFPOD && k exec -it $WAFPOD -- bash'
alias cpuninstall='get_WAFPOD && k exec -it $WAFPOD --  /usr/sbin/cpnano --uninstall'
alias cpagenttoken='get_WAFPOD && k exec -it $WAFPOD --  ./cp-nano-agent --token $TOKEN'
# alias cptoken="bash cp/cp_token.sh"
alias cpnanol='get_WAFPOD && k exec -it $WAFPOD -- cpnano -s |grep -E "Policy|Last" ' 

alias cpnanos='get_WAFPOD && k exec -it $WAFPOD -- cpnano -s  ' 
alias cpnanor='get_WAFPOD && k exec -it $WAFPOD -- cpnano -s | grep -E "^Registration status:" '
#alias cpwipe='docker-compose down &&  docker system prune -a'
alias cphost='printf "Host IP address used: $HOST_IP \n"'
alias cpingress='printf "Ingress IP address used: $INGRESS_IP \n"'
#alias cpmetallb='microk8s enable metallb:$INGRESS_IP-$INGRESS_IP'
alias cpmetallb='microk8s enable metallb:$HOST_IP-$HOST_IP'
alias cpurltest='echo "Testing URL for Juiceshop Host" && curl -s -H "Host: juiceshop.lab"  $INGRESS_IP | grep -i -m 1 "OWASP" && 
		 echo "Testing URL for VAMPI Host" && curl -s -H "Host: vampi.lab" $INGRESS_IP | grep -i -m 1 "VAmPI" |cut -c 15-86 '
alias cpuptemp='echo "Updating coredns.yaml using coredns.yaml.template with local Host IP address of ${INGRESS_IP}" && \
	         envsubst  < coredns.yaml.template > coredns.yaml '

alias cpdnscheck='printf "DNS Values Check\n" && \
	printf "CoreDNS service ClusterIP: " && \
	kubectl get svc -n kube-system kube-dns -o=jsonpath="{.spec.clusterIP}" && \
	printf "\nTesthost Resolv.conf: " && \
	kubectl exec -it wafciser -n wafciser -- cat /etc/resolv.conf | grep -oP "nameserver\s*\K[^,]+" | tr -d "\n" &&  \
	printf "\nValues should match\n" && \
	printf "\nHost IP: ${HOST_IP}  Ingress IP: ${INGRESS_IP}"
	printf "\nChecking the WAFciser containers DNS for juiceshop.lab and vampi.lab \n" && \
	k exec -it wafciser -n wafciser -- getent hosts juiceshop.lab && \
	k exec -it wafciser -n wafciser -- getent hosts vampi.lab && \
	printf "The hosts IP resolution should match the Host or Ingress IP\n"'



alias cphelp='printf "Check Point Lab Commands:     Ver: $VER
written by - Vince Mammoliti - vincem@checkpoint.com \n
cpnano           Show detail status of AppSec Agent ( use as cpnano -s)
cpnanol          Show last update of the AppSec Agent
cpuninstall      Uninstall AppSec Agent
cpagenttoken     Install AppSec Agent and assign Token
cphost           Shows the IP address of the Host used
cpingress        Shows the IP address of the Ingress Controller used
cphelp           Alias Command to help with Check Point Lab
cpmetallb        Enables the MicroK8s Metallb with the External IP of the Host system
cpcurltest       Fetches Juiceshop and VAmPI website via Exposed Ingress Controller
cpdnscheck       Show CoreDNS Service IP and Resolve.conf for Testhost    
cpuptemp         Update the local yaml files using templates and update with local IPs (coredns.yaml)

wafciser         WAF - WEB and API Exerciser (Juiceshop and Vampi). user -h for usage and options

Kubectl Short Cuts
k                kubectl
ka               kubectl apply
kd               kubectl delete
kp               kubectl get pods -A 
ks               kubectl get svc -A --output wide
"' 
# remote cpdtraffic and cpdapitrainer too confusing
# cpdtraffic    Docker Based Testhost of cptraffic
#cpdapitrainer Docker Based Testhost of cpapitrainer
