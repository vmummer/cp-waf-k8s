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
# Sept 5, 2025 - Added to run just the TestHost in Docker Container
if [[ hostname =~ [A-Z] ]]; then  echo ">>> WARNING <<< hostname contains Capital Letters. When using microk8s the capital letters in the hostname will cause many different type of failures. Rename host name to all lower case to continue!"; exit 1; fi

VER=2.4
echo "Check Point WAF on Kubernetes Lab Alias Commands.  Use cphelp for list of commands. Ver: $VER"
alias k=microk8s.kubectl
alias kubectl=microk8s.kubectl
alias helm='/snap/bin/microk8s.helm'
export HOST_IP="`hostname -I| awk ' {print $1}'`"
WAPAPP=cp-appsec-cloudguard-waf-ingress-nginx-controller

if k get pods -A | grep -q -o 'cp-appsec' ; then 
	INGRESS_IP="`microk8s.kubectl get  svc $WAPAPP -o json | jq -r  .status.loadBalancer.ingress[].ip`"
	get_WAFPOD ()  {
	WAFPOD="`microk8s.kubectl get pods -o=jsonpath='{.items..metadata.name}' | grep cp-appsec`"
	}
fi

#alias cptrbad='_cptrbad() { echo "Dec 2024  - Adapted for K8S Lab" ; url=$1 ;k exec -it  testhost  -n testhost -- bash -c "url=$url && cd /home/juice-shop-solver && python main.py $url";}; _cptrbad'
alias cptraffic='k exec -it testhost -n testhost -- bash /home/cp/cp_traffic.sh'
alias cpapi='bash cp/cp_api_trainer.sh'
alias cpapitrainer='k exec -it testhost -n testhost -- bash /home/cp/cpapitrlocal.sh'
alias cptesthost='k exec -it testhost -n testhost -- bash'
alias cpsqlmapupdate='k exec -it testhost -n testhost -- sqlmap --update'
alias cpnano='get_WAFPOD && k exec -it $WAFPOD -- cpnano'
alias cpnanoc='get_WAFPOD && k exec -it $WAFPOD -- bash'
alias cpuninstall='get_WAFPOD && k exec -it $WAFPOD --  /usr/sbin/cpnano --uninstall'
alias cpagenttoken='get_WAFPOD && k exec -it $WAFPOD --  ./cp-nano-agent --token $TOKEN'
# alias cptoken="bash cp/cp_token.sh"
alias cpnanol='get_WAFPOD && k exec -it $WAFPOD -- cpnano -s |grep -E "Policy|Last" ' 

alias cpnanos='get_WAFPOD && k exec -it $WAFPOD -- cpnano -s  ' 
alias cpnanor='get_WAFPOD && k exec -it $WAFPOD -- cpnano -s | grep -E "^Registration status:" '
#alias cpwipe='docker-compose down &&  docker system prune -a'
alias cpcert='sh cp/cp_get_cert.sh'
alias cpfetch='git  config --global http.sslverify false && git clone https://github.com/vmummer/cp-waf-k8s.git'
alias cphost='printf "Host IP address used: $HOST_IP \n"'
alias cpingress='printf "Ingress IP address used: $INGRESS_IP \n"'
alias cpmetallb='microk8s enable metallb:$HOST_IP-$INGRESS_IP'
alias cpcurljuiceshop='curl -s -H "Host: juiceshop.lab"  $INGRESS_IP | head -n 5 ; echo "<Remainder Delete>"'
alias cpcurlvampi='curl -s -H "Host: vampi.lab" $INGRESS_IP | head -n 5 '
alias cpdtraffic='docker run -it vmummer/cpwaftesthost /home/cp/cp_traffic.sh'
alias cpdapitrainer='docker run -it vmummer/cpwaftesthost bash /home/cp/cpapitrlocal.sh'

alias cpdnscheck='printf "DNS Values Check\n" && \
	printf "CoreDNS service ClusterIP: " && \
	kubectl get svc -n kube-system kube-dns -o=jsonpath="{.spec.clusterIP}" && \
	printf "\nTesthost Resolv.conf: " && \
	kubectl exec -it testhost -n testhost -- cat /etc/resolv.conf | grep -oP "nameserver\s*\K[^,]+" | tr -d "\n" &&  \
	printf "\nValues should match\n"'



alias cphelp='printf "Check Point Lab Commands:     Ver: $VER\n
cpnano        Show detail status of AppSec Agent ( use as cpnano -s)
cpnanol       Show last update of the AppSec Agent
cpuninstall   Uninstall AppSec Agent
cpagenttoken  Install AppSec Agent and assign Token
cptraffic     Juiceshop Traffic Generator
cphost        Shows the IP address of the Host used
cpingress     Shows the IP address of the Ingress Controller used
cphelp        Alias Command to help with Check Point Lab
cpapitrainer  Create API traffic to train WAF API gateway. Use -h for options
cpmetallb     Enables the MicroK8s Metallb with the External IP of the Host system
cpcurljuiceshop Fetches Juiceshop Website via Exposed Ingress Controller
cpcurlvampi   Fetches Vampi website via Exposed Ingress Controller
cpdnscheck    Show CoreDNS Service IP and Resolve.conf for Testhost    
cpdtraffic    Docker Based Testhost of cptraffic
cpdapitrainer Docker Based Testhost of cpapitrainer
"' 
