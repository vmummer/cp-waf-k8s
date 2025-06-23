# Check Point CloudGuard WAF deployment on Kubernetes and Microk8S 
 
 The purpose of this repository is to provided a deployment demonstration of Check Points WAF and API protection in a Kubernetes(K8s) environment.  
   
 Some of the optional enhancement include tweeaks to allow to run this demonstration on a Standard Windows Ubuntu WSL system. 
 
The repository also includes a Client Host Pod used to generations web traffic, malicous web traffic, API training tool and API attach tool in order to show case the functional of the Check Point WAF/API Protect system.   
<Add more about design and Pods>

![Screenshot 2025-06-19 162922](https://github.com/user-attachments/assets/0c787b44-14dc-4671-aa2d-dad45521db71)




## Instructions:
 
* Clone the repository
* From a machine with docker and docker-compose installed, run:  
```
source cpalias.sh          << Load Aliase commands
 

<Can use newer docker compose <commands> as compared to the older docker-compose.  Compose plugin needs to be install.
```
[DEMO HERE]

cphelp     - Will show alias command useful for this demo

cpnano -s			       # Check status of the WAF - needs to say "CloudGuard AppSec is up-to-date and ready"

cpnanol				       # Check to see if policy has been push and updated
                                       
cptrgood http://juiceshop.local:80     # Use to generate good traffic 
                                         - This just does a simple crawl of the Juiceshop website

cptrbad http://juiceshop.local:80      # Use to generate questionable traffic on the Juiceshop website

cpapitrainer                           # Used to train the WAF API gateway and with -m to create malicious traffic 
docker-compose down
```
> Notes:

On the Infinity Portal when setting up the Assets Note the Reverse Proxy for the Juice Shop will be:   http://juiceshop:3000  and for API  http://vampi:5000.  The host name are the docker container names of the applications. Docker will do a look up on the host names juiceshop and vampi and will forward the traffic to the containers running the application on the assigned ports.

Suggest you add juiceshop.local into your local systems /etc/hosts file. You can use the cphost to provide you with the local host IP address. 

ie: 

/home/lab/cp-waf-demo# cphost
Docker Host IP address used: 172.29.126.121
add into /etc/hosts
172.29.126.121 juiceshop.local 

> The Vampi Database needs to be initialized. This can be done by issuing cpapitrainer --initdb http://juiceshop.local:5000   

