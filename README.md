# Check Point CloudGuard WAF deployment on Kubernetes and Microk8S 
 
 The purpose of this repository is to provided a deployment demonstration of Check Points WAF and API protection in a Kubernetes(K8s) environment.  
   
 Some of the optional enhancement include tweeaks to allow to run this demonstration on a Standard Windows Ubuntu WSL system. 
 
The repository also includes a Client Host Pod used to generations web traffic, malicous web traffic, API training tool and API attach tool in order to show case the functional of the Check Point WAF/API Protect system.   
<Add more about design and Pods>

![image](https://github.com/user-attachments/assets/9f06c8e2-9f6b-4acb-a8ba-fdea3ad23fd7)



## Instructions:
 
* Clone the repository
* From a machine with docker-compose to build the testhost and microK8s be installed, run:  
```
source cpalias.sh          << Load Aliase commands
 


```
[DEMO HERE]

cphelp     - Will show alias command useful for this demo

cpnano -s			       # Check status of the WAF - needs to say "CloudGuard AppSec is up-to-date and ready"

cpnanol				       # Check to see if policy has been push and updated
                                       
cptrgood http://juiceshop.lab:80     # Use to generate good traffic 
                                         - This just does a simple crawl of the Juiceshop website
cptrbad http://juiceshop.lab:80      # Use to generate questionable traffic on the Juiceshop website

cpapitrainer                           # Used to train the WAF API gateway and with -m to create malicious traffic 


