# Check Point CloudGuard WAF deployment on Kubernetes and Microk8S 
 
 The purpose of this repository is to provided a deployment demonstration of Check Points WAF and API protection in a Kubernetes(K8s) environment.  
   
 Some of the optional enhancement include tweeaks to allow to run this demonstration on a Standard Windows Ubuntu WSL system. 
 
The repository also includes a Client Host Pod used to generations web traffic, malicous web traffic, API training tool and API attach tool in order to show case the functional of the Check Point WAF/API Protect system.   
<Add more about design and Pods>

<img width="1239" height="796" alt="image" src="https://github.com/user-attachments/assets/4a554cd0-5add-4821-8f8a-e07f9c4fdcf2" />

```
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
 
*Enable MicroK8s Add-on by running the following setup.sh:

./setup.sh


* From the Check Point Infinity Portal - Create a WAF asset
* Fetch the Cloud Guard WAF nginx based ingress controller image and the Helm Chart 

wget https://cloudguard-waf.i2.checkpoint.com/downloads/helm/ingress-nginx/cp-k8s-appsec-nginx-ingress-4.12.1.tgz -O cp-k8s-appsec-nginx-ingress-4.12.1.tgz

* Install the Cloud Guard WAF Helm Chart

helm install cp-k8s-appsec-nginx-ingress-4.12.1.tgz --name-template cp-appsec \
--set appsec.agentToken="cp-us-<Removed>"    << Replace with your own key

* Configure the Metallb - Load Balancer with the following command.  It fills in the address required.

cpmetallb

*Create the coredns.yaml file by this aliase command to subsitute the ingress IP address for DNS resolution:

cpuptemp   >> uses the template and replace with the HOST_IP to allow juiceshop.lab and vampi.lab to reslove to ingress controller

k apply -f coredns.yaml     >> This should be done before loading the juiceshop.yaml and vampi.yaml, so you don't need to wait for
                               DNS update.
k apply -f ingress.yaml

* Load the remainder pods:

k apply -f juiceshop.yaml
k apply -f vampi.yaml
k apply -f wafciser.yaml

cpdnscheck                >> Validates that both host are pointing to the external IP of the WAF
cpurltest                 >> Check that both Juiceshop and Vampi are reachable via the WAF

[DEMO HERE]

cphelp                     # Will show alias command useful for this demo

cpnano -s			       # Check status of the WAF - needs to say "CloudGuard AppSec is up-to-date and ready"

cpnanol				       # Check to see if policy has been push and updated
                                       
cpwafciser                 # Use to generate good traffic - defaults to http://juiceshop.lab  
                              - This just does a simple crawl of the Juiceshop website
cpwafciser  -m     i       # Use to generate questionable traffic on the Juiceshop website

cpwafciser -a api          # Used to train the WAF API gateway and with -m to create malicious traffic   -s SQL testing -v verbose
                              Defaults to http://vampi.lab

cpwafciser -h for other options


