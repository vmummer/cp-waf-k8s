#/usr/bin/bash
#DOCKER_HOST="`hostname -I| awk ' {print $1}'`"
# 2025-Apr-29 Modified from docker to K8S Lab
host="http://juiceshop.lab:80"
repeat=1
if [ -z "$1" ]; then
        echo "Usage  cptrgood <URL> <repeat>  - Create Good Traffic against Test Host. " 
	echo "Defaulting to Test Host URL: $host and repeat $repeat"
else
	if [[ ! ${1,,} == *"http"* ]]; then
		echo "ERROR: URL must be http:// or https:// - You have provided url of $host"
		echo "Usage:  cptrgood <URL> optional <repeat> - defauts to $host and repeat $repeat"
		exit
	fi
	host=$1
	repeat=$2
	if [ -z "$repeat" ]; then repeat=1 ;fi 
fi

for (( i=0; i<$repeat; ++i)); do
	loop=$(($i+1))
	echo "$loop of $repeat) Testing Against URL: $host"
	python /home/web-scraper/websitescrap.py $host


done

