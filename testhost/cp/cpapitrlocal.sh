##!/usr/bin/env bash
#
# 2024 - Check Point Software - WAF LAB
# cp_api_trainer.sh 
# The following script was created to train the WAF API to learn the API Scheme of VAMPI application to demontrate
# the auto learning
# Write by Vince Mammoliti - vincem@checkpoint.com
# Version 0.6  - Sept 25, 2024
# Version 0.7  - Dec  10, 2024 - Modified to support microK8s 
# Version 0.8  - May   1, 2025 - Added sqlmap --update functionality 
# Version 0.9  - July  8, 2025 - Added check for symbolic link for /usr/bin/python 
#

set -euo pipefail

declare vResponse='silentResponse'   # This is method for creating verbose debug info. When more verbose is required this will be set to the 'echo' command
function silentResponse () {
       	:
}

VERS=0.9
VFLAG=0
REPEAT=1
HOST="http://vampi.lab"
DOCKER_HOST="`hostname -I| awk ' {print $1}'`"
LINE=10
CHAR=$(( 80 * $LINE))
RED='\033[0;31m'
NC='\033[0m' # No Color
BFLAG=0
INITDB=0
SFLAG=0	
SUPDATE=0

usage(){
>&2 cat << EOF
$0 is an API training tool to demonstrate the API learning capability of the Check Point Cloud Guard WAF
Written by Vince Mammoliti - vincem@checkpoint.com -  July 2025 

Usage: $0 [OPTIONS...] [URL of VAMPI host - defaults to $HOST] 
  -v | --verbose             provides details of commands excuited against host  
  -m | --malicious           send malicious type traffic (Default will be know good training traffic)
  -r | --repeat              repeat the number of times to send api training requests. defaults to 1 
  -s | --sql		     uses sqlmap to attempt to dump database
  -u | --sqlupdate	     update sqlmap  
  -i | --initdb              initialize Vampi Database
  -h | --help                this help screen is displayed
EOF
exit 1
}

gettoken(){
TOKEN=$(curl -sS -X POST   ${HOST}/users/v1/login   -H 'accept: application/json' \
	                  -H 'Content-Type: application/json'  \
                          -d '{ "password": "pass1", "username": "admin" }' \
			   | jq -r '.auth_token')		       
return 0
} 

checkdb(){
#This check to see if the Vampi DB has been initilized. By default its not and needs to be.
   $vResponse -e "Checking Vampi DB has been initilized\n"
   OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' ${HOST}/users/v1)
   if echo "$OUTPUT" |  grep -q -o  'no such table: users'; then
	            echo -e "${RED}VAMPI DB has NOT been Initialized - Please Initialize to Continue.  You can use the $0 --initdb option to initialize the Vampi DB. ${NC}"
		    exit 1
     fi
}


initdb(){
  echo -e "Initilizing VampiDB\n"
  OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' ${HOST}/users/v1)   # Checking to see if has been initialized first
     if echo "$OUTPUT" |  grep -q -o  'no such table: users'; then
	     OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' ${HOST}/createdb)
	     if echo "$OUTPUT" |  grep -q -o -P '.{0,20}Application Security.{0,4}'; then
	            echo -e "${RED}Check Point - Application Security Blocked ${NC}"
		    echo -e "Reexecute the command directly the non protected host URL ie: $0 --initdb http://vampi.lab:5000"
		    exit 1
	     fi	       
     else 
	 echo -e "VampiDB is already Initilized"	     
         exit 1
     fi
}



sqldump(){
# The follow was removed because sqlmap was added to the tester container to run
if ! [ -x "$(command -v sqlmap)" ]; then
	        echo "sqlmap is not installed - please install 'apt-get install sqlmap'" >&2
	        exit 1
fi 
$vResponse "HOST: ${HOST}"
gettoken
#sqlmap -u ${HOST}"/users/v1/*name1*" --method=GET --headers="Accept: application/json\nAuthorization: Bearer $TOKEN \nHost: ${TOKEN} " --dbms=sqlite --dump

sqlmap -u $HOST"/users/v1/*name1*" --method=GET --headers="Accept: application/json\nAuthorization: Bearer $TOKEN Host: ${TOKEN} " --dbms=sqlite --dump --batch 

exit 0
}

sqlupdate(){
# 25-05-01 added sqlmap update feature - allows for updating of the sqlmap info from sript 
if ! [ -x "$(command -v sqlmap)" ]; then
                echo "sqlmap is not installed - please install 'apt-get install sqlmap'" >&2
                exit 1
fi

sqlmap --update

                                                                                                                        exit 0
}





ifblocked(){
  if echo "$OUTPUT" |  grep -q -o -P '.{0,20}Application Security.{0,4}'; then
        echo -e "${RED}Check Point - Application Security Blocked ${NC}"
  fi
}


traffic_bad(){
if [ ! -z "$@" ]; then     # Check to see if there is a URL on the command, if so replace
		         HOST=$@
fi
$vResponse "REPEAT: ${REPEAT}" 
echo -e "\n WAF API - Training Traffic - Simulator - $0 -h for options \n"
echo -e " Sending Malicious API Traffic"

for (( i=0; i < $REPEAT ; ++i));
do
  loop=$(($i+1))
  echo "Loop: $loop"
  gettoken
  # Create a Bad Book Lookup
  echo "1) Send a bad book lookup - sending /books/v1/cp-GCWAF-102x "
  OUTPUT=$(curl -sS -X GET  ${HOST}/books/v1/cp-GCWAF-102x   -H 'accept: application/json'  -H "Authorization: Bearer $TOKEN" )
  ifblocked
  $vResponse -e ${OUTPUT:0:$CHAR} "\n"

  #Create and account attact "user1'"
  echo "2) Send an attempt to exploit account - send /users/v1/user1' "
  OUTPUT=$(curl -sS -X GET "${HOST}/users/v1/user1'"  -H 'Content-Type: application/json' \
               -H "Authorization: Bearer $TOKEN"
                )
  ifblocked
  $vResponse -e ${OUTPUT:0:$CHAR} "\n"


  #Create and account attact /users/v1/_debug'"
  echo "3) Send an attempt to exploit of developer testing tool send /users/v1/_debug "
  OUTPUT=$(curl -sS -X GET "${HOST}/users/v1/_debug"  -H 'Content-Type: application/json' \
         -H "Authorization: Bearer $TOKEN"
               )
  ifblocked
  $vResponse -e ${OUTPUT:0:$CHAR} "\n"

  echo "4) DELETE /users/v1/cgwaf2 "
  OUTPUT=$(curl -sS -X DELETE   ${HOST}/users/v1/cgwaf2  -H 'Content-Type: application/json' \
         -H "Authorization: Bearer $TOKEN"
           )
  ifblocked
  $vResponse $OUTPUT

  echo "5) /ui "
  OUTPUT=$(curl -sS ${HOST}/ui)
  ifblocked
  $vResponse $OUTPUT

done
exit 1
}

args=$(getopt -a -o vr:smiu --long help,verbose,repeat:,sql,malicious,initdb,sqlupdate -- "$@")



#if [[ $? -gt 0 ]]; then
#if [[ $# -eq 0 ]]; then
#  usage
#fi

eval set -- ${args}
while :
do
  case $1 in
	-v | --verbose)   VFLAG=1 ; vResponse='echo' ; shift   ;;
	-h | --help)      usage   ; shift   ;;
	-r | --repeat)    REPEAT=$2  ; shift 2 ;;
	-s | --sql )      SFLAG=1 ; shift  ;;
	-u | --sqlupdate) SUPDATE=1 ; shift ;;
	-m | --malicious) BFLAG=1  ; shift ;; 
	-i | --initdb)	  INITDB=1 ; shift ;;
	--) shift; break ;;
	 *)   usage; exit 1 ;;
   esac
done

if [ ! -z "$@" ]; then     # Check to see if there is a URL on the command, if so replace
	 HOST=$@
fi

# 25-07-08 after updating sqlmap, sometime it is looking for /usr/bin/python. If it does not exist, you will see an error
if ! [ -x "$(command -v python)" ]; then
                echo -e "\n${RED}[sqlmap] application requires python and system only has python3 installed.${NC}\nTo overcome create a symbolic link for /usr/bin/python by issuing the following: \nsudo ln -s /usr/bin/python3 /usr/bin/python\n"  >&2
                exit 1
fi

echo -e "Check Point WAF - API Trainer - by Vince Mammoliti - Version ${VERS} 2025"
echo "HOST: ${HOST}"
$vResponse "BFLAG: ${BFLAG}"
if [ $INITDB -eq 1 ]; then
	initdb
	exit 1
elif	[ $BFLAG -eq  1 ]; then 
	checkdb  # Check added to validate that the Vampi dB has been initized 
	traffic_bad
	exit 1
elif [ $SFLAG -eq 1 ] ; then
	checkdb
	sqldump
	exit 1
elif [ $SUPDATE -eq 1 ] ; then
        sqlupdate 
        exit 1
else 
checkdb
echo -e "\n WAF API - Training Traffic - Simulator - $0 -h for options \n"
for (( i=0; i < $REPEAT ; ++i));
do
   loop=$(($i+1))
   echo "Loop: $loop"
   echo "1) GET /"
   OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' ${HOST}/)
   $vResponse $OUTPUT ; # If -v is enabled - prints out result of curl

   echo "2) GET /books/v1"
   OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' ${HOST}/books/v1)
   $vResponse $OUTPUT
   
   echo "3) GET /users/v1"
   OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' ${HOST}/users/v1)
   $vResponse $OUTPUT

   echo "4) POST /user/v1/login"
   TOKEN=$(curl -sS -X POST   ${HOST}/users/v1/login   -H 'accept: application/json' \
	        -H 'Content-Type: application/json'  \
			-d '{ "password": "pass1", "username": "name1" }' \
				| jq -r '.auth_token')
   $vResponse $OUTPUT 
   
   echo "5) GET /users/v1/admin"
   OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' ${HOST}/users/v1/admin)
   $vResponse $OUTPUT


   echo "6) POST /books/v1 - new book added"
   OUTPUT=$(curl -sS -X 'POST'   ${HOST}/books/v1   -H 'accept: application/json' -H 'Content-Type: application/json'          -d '{
               "book_title": "cp-GCWAF-102",
               "secret": "cp-secret"
             }' -H "Authorization: Bearer $TOKEN "
	   )
   $vResponse $OUTPUT  

   echo "7) books/v1/cp-GCWAF-102 - book details"
   OUTPUT=$(curl -sS -X GET  ${HOST}/books/v1/cp-GCWAF-102   -H 'accept: application/json'  -H "Authorization: Bearer $TOKEN" )
   $vResponse $OUTPUT

   echo "9) POST /users/v1/register - add a new users "
   OUTPUT=$(curl -sS -X 'POST'   ${HOST}/users/v1/register   -H 'accept: application/json' -H 'Content-Type: application/json'          -d '{
  			"email": "user@cpcgwaf.com",
    			"password": "pass1",
      			"username": "cgwaf2"
		      }'
	  )
   $vResponse $OUTPUT

   echo "10) PUT /users/v1/cpgwaf2/email - update email of user "
   OUTPUT=$(curl -s -w "%{http_code}\n" -X PUT   ${HOST}/users/v1/cgwaf2/email   -H 'accept: */*' -H 'Content-Type: application/json' \
	 -d '{
          	"email": "use3@cp.com"
	     }' -H "Authorization: Bearer $TOKEN"
	  )
  if echo "$OUTPUT" |  grep -q -o '204'; then
	          $vResponse -e "Update successfull - 204 code"
	  else 	
 		$vResponse -e "${RED}User update email - Failed - Did receive 204 doe ${NC}"
  fi


   echo "11) POST /user/v1/login - login as admin user"
   TOKEN=$(curl -sS -X POST   ${HOST}/users/v1/login   -H 'accept: application/json' \
	         -H 'Content-Type: application/json'  \
		         -d '{ "password": "pass1", "username": "admin" }' \
			         | jq -r '.auth_token')

   echo "12) DELETE /users/v1/cgwaf2 - as an admin user"
   OUTPUT=$(curl -sS -X DELETE   ${HOST}/users/v1/cgwaf2  -H 'Content-Type: application/json' \
                 -H "Authorization: Bearer $TOKEN"
                )
   $vResponse $OUTPUT


done
fi
exit 0



