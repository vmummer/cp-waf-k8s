#/usr/bin/bash
#DOCKER_HOST="`hostname -I| awk ' {print $1}'`"
#25-APR-29 Adapted to for K8S lab - Vince Mammolit - vincem@checkpoint.com

host="http://juiceshop.lab:80"
repeat=1
if [ -z "$1" ]; then
	echo "Usage  cptrbad <URL> <repeat>  - Create Malicous Traffic against Test Host. "
	echo "Defaulting to Test Host URL:$host and repeat $repeat"
        echo " "	
else
	if [[ ! ${1,,} == *"http"* ]]; then
                echo "ERROR: URL must be http:// or https:// - You have provided url of $host"
                echo "Usage:  cptrbad <URL> optional <repeat> - defauts to $host and repeat $repeat"
                exit
        fi
	host=$1
	repeat=$2
	if [ -z "$repeat" ]; then repeat=1 ;fi 
fi

for (( i=0; i<$repeat; ++i)); do
	loop=$(($i+1))
	echo "$loop of $repeat) Testing Against URL: $host"
	cd /home/juice-shop-solver && python main.py $host


done

