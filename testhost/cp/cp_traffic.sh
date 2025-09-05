#!/usr/bin/env bash
#
#2025 - Check Point Software - WAF Lab
# cp_traffic.sh
# The following script was created to train the WAF used to protect Juiceshop Webstore
# Written by Vince Mammoliti - vincem@checkpoint.com
# Version 0.1 - July 17, 2025 - Newly created joint
# Version 1.0 - September 5, 2025 - Added the functionality of passing URL HOST from host system
#               Added DEFAULT_URL_CPTRAFFIC 

# Default values
VER=1.0
#Check to see if DEFAULT_URL_CPTRAFFIC URL has been passed.
#
if [ -z "${DEFAULT_URL_CPTRAFFIC:-}" ]; then
	echo "IF - Vince" 
	HOST="http://juiceshop.lab:80"
else
	HOST=$DEFAULT_URL_CPTRAFFIC
	echo "ELSE" 
fi
REPEAT=1
MODE="good"
DELAY=1
RED='\033[0;31m'
NC='\033[0m' # No Color 



# Help message
usage() {
>&2 cat << EOF
$0 is a test tool to demostrate Check Point WAF offering
Written by Vince Mammoliti - vincem@checkpoint.com - Sept 2025

Usage: $0 [-m ] [-R] [URL] [-r repeat] [-d delay]
    
Options:
  -m            Run in malicious traffic mode (default is good traffic)
  -R            Generates CURL requests to demonstrate Ratelimit of WAF
  -d            Delay in sec for Ratelimiting Testing (default: $DELAY)
  -r repeat     Number of times to repeat the request (default: $REPEAT)
  -h            Show this help message

Positional Arguments


  URL           Target URL (default: $HOST)

Examples:
  $0                                          # Good traffic to default URL $HOST
  $0 http://juiceshop.juiceshop:3000          # Good traffic to custom URL
  $0 -m                                       # Malicious traffic to default URL
  $0 -m http://juiceshop.juiceshop:3000 -r 5  # Malicious traffic to custom URL, repeated 5 times
  $0 -R                                       # CURL requests to demonstrate Rateliming of the WAF
                                                             default to URL $HOST
  $0 -R -d 10 -r 100                          # CURL requests every 10 sec for 100 requests
EOF
exit 0
}

# Function to describe HTTP status codes
get_http_status_description() {
  case $1 in
    # 1xx Informational
    100) echo "Continue" ;;
    101) echo "Switching Protocols" ;;
    102) echo "Processing" ;;

    # 2xx Success
    200) echo "OK ✅" ;;
    201) echo "Created" ;;
    202) echo "Accepted" ;;
    204) echo "No Content" ;;

    # 3xx Redirection
    301) echo "Moved Permanently" ;;
    302) echo "Found" ;;
    304) echo "Not Modified" ;;
    307) echo "Temporary Redirect" ;;

    # 4xx Client Error
    400) echo "Bad Request 👎" ;;
    401) echo "Unauthorized" ;;
    403) echo "Forbidden 🚫" ;;
    404) echo "Not Found" ;;
    408) echo "Request Timeout" ;;
    429) echo "Too Many Requests" ;;

    # 5xx Server Error
    500) echo "Internal Server Error 💥" ;;
    501) echo "Not Implemented" ;;
    502) echo "Bad Gateway" ;;
    503) echo "Service Unavailable" ;;
    504) echo "Gateway Timeout" ;;

    # Default
    *) echo "Unknown Status Code" ;;
  esac
}




ratelimit() {
echo "----------------------------------------------------------------"
echo "Sending $REPEAT requests to $HOST with a ${DELAY}s delay between each request."
echo "----------------------------------------------------------------"

for (( i=1; i<=REPEAT; i++ ))
do
  echo "Request #$i at $(date +%T)"

  # Execute curl and capture both the HTTP code and total time into a variable
  CURL_OUTPUT=$(curl -s -o /dev/null -w "%{http_code}|||%{time_total}" "$HOST")

  # Extract the http_code and time_total from the output
  HTTP_CODE=$(echo "$CURL_OUTPUT" | cut -d'|' -f1)
  TIME_TOTAL=$(echo "$CURL_OUTPUT" | cut -d'|' -f4)
  echo $CURL_OUTPUT
  # Get the description for the HTTP status code
  STATUS_DESCRIPTION=$(get_http_status_description "$HTTP_CODE")

  # Print the formatted output
  printf "Status: %s (%s) | Time: %ss\n" "$HTTP_CODE" "$STATUS_DESCRIPTION" "$TIME_TOTAL"
  echo "------------------------"

  # Don't sleep after the last request
  if [ $i -lt $REPEAT ]; then
    sleep $DELAY
  fi
done

echo "Finished sending all requests."

}


# Parse options
while getopts "mRd:r:h" opt; do
  case ${opt} in
    m )
      MODE="misc"
      ;;
    R )
      MODE="rate"
      ;;
    r )
      REPEAT="$OPTARG"
      ;;
    d )
      DELAY="$OPTARG"
      ;;
    h )
      usage
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    : )
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done
shift $((OPTIND -1))

echo -e "$0 is a test tool to demostrate Check Point WAF offering
Written by Vince Mammoliti - vincem@checkpoint.com - Sept 2025 (-h) for usage \n"


# Positional argument for URL
if [ -n "$1" ]; then
  if [[ "$1" != http* ]]; then
    echo -e "${RED}ERROR: URL must start with http:// or https://${NC}"
    exit 2 
  fi
  HOST="$1"
fi

stripped_host="${HOST#http://}" && stripped_host="${stripped_host#https://}" &&  stripped_host="${stripped_host%%:*}"

if getent hosts "$stripped_host" > /dev/null; then
  echo "✅ Hostname '$stripped_host' resolved successfully."
else
  echo -e "${RED}❌ Hostname '$stripped_host' could not be resolved.${NC}"
  exit 2
fi
echo

# Run the appropriate traffic generator
for (( i=0; i<$REPEAT; ++i )); do
  loop=$((i+1))
  echo "$loop of $REPEAT) Testing Against URL: $HOST"

  if [ "$MODE" == "rate" ]; then
    ratelimit   
  elif [ "$MODE" == "misc"  ]; then
    cd /home/juice-shop-solver && python main.py "$HOST"
  else
    python /home/web-scraper/websitescrap.py "$HOST"
  fi
done
