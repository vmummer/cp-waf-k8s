# Check Point CloudGuard WAF deployment on Kubernetes and Microk8S 
 
 The purpose of this repository is to provided a deployment demonstration of Check Points WAF and API protection in a Kubernetes(K8s) environment.  
   
 Some of the optional enhancement include tweeaks to allow to run this demonstration on a Standard Windows Ubuntu WSL system. 
 
The repository also includes a Client Host Pod used to generations web traffic, malicous web traffic, API training tool and API attach tool in order to show case the functional of the Check Point WAF/API Protect system.   
<Add more about design and Pods>

<img width="1239" height="796" alt="image" src="https://github.com/user-attachments/assets/4a554cd0-5add-4821-8f8a-e07f9c4fdcf2" />


Instructions:
 
* Clone the repository
* microK8s be installed, and run the following minimually:

* update apps and upgrade
sudo apt update && sudo apt upgrade -y
* Install git and jq
sudo apt install git jq -y

*Clone this repository
git clone https://github.com/vmummer/cp-waf-k8s.git

*Change into the cp-waf-k8s directory
cd cp-waf-k8s

*Load up alias file used in the lab to simplify command


source cpalias.sh          << Load Aliase commands
 
*Enable MicroK8s Add-ons:
microk8s enable dns  
microk8s enable ingress 
microk8s enable hostpath-storage

* Configure the Metallb - Load Balancer with the following command.  It fills in the address required.
cpmetallb

* Setup the namespaces used for this enviornment.

k apply -f namespace.yaml

* From the Check Point Infinity Portal - Create a WAF assset
* Fetch the Cloud Guard Helm Chart

wget https://cloudguard-waf.i2.checkpoint.com/downloads/helm/ingress-nginx/cp-k8s-appsec-nginx-ingress-4.12.1.tgz -O cp-k8s-appsec-nginx-ingress-4.12.1.tgz

* Install the Cloud Guard WAF Helm Chart

helm install cp-k8s-appsec-nginx-ingress-4.12.1.tgz --name-template cp-appsec \
--set appsec.agentToken="cp-us-<Removed>"    << Replace with your own key


```
[DEMO HERE]

cphelp     - Will show alias command useful for this demo

cpnano -s			       # Check status of the WAF - needs to say "CloudGuard AppSec is up-to-date and ready"

cpnanol				       # Check to see if policy has been push and updated
                                       
cpwafciser http://juiceshop.lab:80        # Use to generate good traffic 
                                         - This just does a simple crawl of the Juiceshop website
cpwafciser http://juiceshop.lab:80 -m     # Use to generate questionable traffic on the Juiceshop website

cpwafciser http://vampi.lab:00            # Used to train the WAF API gateway and with -m to create malicious traffic 


