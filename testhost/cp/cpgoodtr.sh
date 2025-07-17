#/usr/bin/bash
DOCKER_HOST="`hostname -I| awk ' {print $1}'`"
if [ -z "$1" ]; then
	host="http://juiceshop.lab:80"
        echo "Usage  cptrgood <URL> <repeat>  - Create Good Traffic against Test Host. " 
	echo "Defaulting to Test Host URL: $host and repeat 1"
	repeat=1
else
	host=$1
	repeat=$2
	if [ -z "$repeat" ]; then repeat=1 ;fi 
fi

for (( i=0; i<$repeat; ++i)); do
	loop=$(($i+1))
	echo "$loop of $repeat) Testing Against URL: $host"
	microk8s.kubectl exec -it -n testhost testhost -- python /home/web-scraper/websitescrap.py $host
	 


done

