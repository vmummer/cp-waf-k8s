#/usr/bin/bash
DOCKER_HOST="`hostname -I| awk ' {print $1}'`"
if [ -z "$1" ]; then
        echo "Usage  cptrgood <URL> <repeat>  - Create Good Traffic against Test Host. " 
	echo "Defaulting to Test Host URL:  http://juiceshop.local:80 and repeat 1"
	host="http://juiceshop.local:80"
	repeat=1
else
	host=$1
	repeat=$2
	if [ -z "$repeat" ]; then repeat=1 ;fi 
fi

for (( i=0; i<$repeat; ++i)); do
	loop=$(($i+1))
	echo "$loop of $repeat) Testing Against URL: $host"
	microk8s.kubectl exec -it  testerhost  -n testhost -- bash -c 'cd /home/juice-shop-solver && python main.py $host'


done

