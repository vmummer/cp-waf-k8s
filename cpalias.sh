#/usr/bin/bash
#export TOKEN=
# Dec 3, 2024 added K8S Ingress IP address
# Mar 31, 2025 Added 
# April 17, 2025 - Adding the user of helm chart and dynamic Pod names.

echo "Adding Check Point CNAP & WAF on Kubernetes Lab Alias Commands.  Use cphelp for list of commands"
DOCKER_HOST="`hostname -I| awk ' {print $1}'`"
WAPAPP=cp-appsec-cloudguard-waf-ingress-nginx-controller
INGRESS_IP="`microk8s.kubectl get  svc $WAPAPP -o json | jq -r  .status.loadBalancer.ingress[].ip`"
WAFPOD="`microk8s.kubectl get pods -o=jsonpath='{.items..metadata.name}' | grep cp-appsec`"
alias cptrbad='_cptrbad() { echo "Dec 2024  - Adapted for K8S Lab" ; url=$1 ;microk8s.kubectl exec -it  testhost  -n testhost -- bash -c "url=$url && cd /home/juice-shop-solver && python main.py $url";}; _cptrbad'
alias cptrgood='bash cp/cp_test_good.sh'
alias cpapi='bash cp/cp_api_trainer.sh'
alias cpapitrainer='microk8s.kubectl exec -it testhost -n testhost -- bash /home/lab/k8s/cp/cp_api_tester.sh'
alias cptesthost='microk8s.kubectl exec -it testhost -n testhost -- bash'
alias cpnano='microk8s.kubectl exec -it $WAFPOD -- cpnano'
alias cpuninstall='microk8s.kubectl exec -it $WAFPOD --  /usr/sbin/cpnano --uninstall'
alias cpagenttoken='microk8s.kubectl exec -it $WAFPOD --  ./cp-nano-agent.sh --token $TOKEN'
alias cptoken="bash cp/cp_token.sh"
alias cpnanol='microk8s.kubectl exec -it $WAFPOD -- cpnano -s |grep -E "Policy|Last" ' 
#alias cpwipe='docker-compose down &&  docker system prune -a'
alias cpcert='sh cp/cp_get_cert.sh'
alias cpfetch='git  config --global http.sslverify false && git clone https://github.com/vmummer/appsec-demo.git'
alias cphost='printf "Docker Host IP address used: $DOCKER_HOST \n"'
alias cpingress='printf "Ingress IP address used: $INGRESS_IP \n"'
alias cphelp='printf "Check Point Lab Commands:\n
cpnano        Show detail status of AppSec Agent ( use as cpnano -s)
cpnanol       Show last update of the AppSec Agent
cpuninstall   Uninstall AppSec Agent
cpagenttoken  Install AppSec Agent and assign Token
cptoken       Display and update AppSec Agent Token Variable
cpcert        Fetch Cert required to load docker images
cptrbad       Juiceshop Bad  Traffic Generator
cptrgrood     Juiceshop Good Traffic Generator
cpfetch       Fetches Clone from GitHub Lab Files appsec-demo.git
cphost        Shows the IP address of the Docker Host used
cpingress     Shows the IP address of the Ingress Controller used
cphelp        Alias Command to help with Check Point Lab
cpapitrainer  Create API traffic to train WAF API gateway. Use -h for options
"'
# Kubernetes alias.
alias k='microk8s.kubectl'
