#/usr/bin/bash
# April 21 2025 - Modified to run in K8S pod.
# Written by Vince Mammoliti - vincem@checkpoint.com

HOST="http://juiceshop.lab"
REPEAT=1


usage(){
	>&2 cat << EOF
$0 is traffic generator to create non malicious web traffic against a Web Test Host
Scripted by Vince Mammoliti - vincem@checkpoint.com - April 2025

Usage: $0 [OPTIONS....] URL of Web Host - defaults to $HOST]
  -r | --repeat          repeat the number of times to crawl the Web Host
  -h | --help           this help screen is displayed

EOF
exit 1
}



# Start of main script

args=$(getopt -a -o vr:smi --long help,verbose,repeat:,sql,malicious,initdb -- "$@")

eval set -- ${args}
while :
do
	case $1 in
		-h | --help)    usage	; shift ;;
		-r | --repeat)  REPEAT=$2 ; shift 2 ;;
		--) shift; break ;;
		*)  usage; exit 1;;
	esac

done


if [ ! -z "$@" ]; then     # Check to see if there is a URL on the command, if so replace
		 HOST=$@
fi


echo "HOST: ${HOST}"











for (( i=0; i<$REPEAT; ++i)); do
	loop=$(($i+1))
	echo "$loop of $REPEAT) Testing Against URL: $HOST"
	python /home/web-scraper/websitescrap.py $HOST
done
