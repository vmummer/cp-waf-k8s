#!/usr/bin/env bash
set -euo pipefail
# cpwafciser is bash based application to demonstrate Check Point WAF capabilities
# Created to be used against Juice Shop and VAMPI applications 
# Written by Vince Mammoliti - vincem@checkpoint.com
# 25 Sept 08-  Combined of a few applicaiton into single for simplicity
# 25 Sept 23 - Removed HOST_API definition in vampi malicious
# 25 Oct  16 - Stripped the URL hostname anything after the first / for host check
# 25 Oct  21 - Added for Check Point WAF in ifblocked check

# Script metadata
VERSION="1.0.6"
SCRIPT_NAME=$(basename "$0")
CURL_TIMEOUT=30


CURL_CONNECTTIMEOUT=10

# Color setup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
APP="web"   # or "api
MODE="good"      # or "malicious" or "ratelimit"
REPEAT=1
DELAY=1
#DEFAULT_HOST_WEB="http://juiceshop.lab:80"
#DEFAULT_HOST_API="http://vampi.lab"
VERBOSE=0
INITDB=0
SQL=0
SQLUPDATE=0
LINE=10
CHAR=$((80 * LINE))

# Check for environment variables or use defaults
HOST_WEB="${DEFAULT_URL_CPTRAFFIC:-http://juiceshop.lab:80}"
HOST_API="${DEFAULT_URL_CPAPI:-http://vampi.lab:80}"





# Verbose output handling
declare vResponse='silentResponse'   # Default to silent mode

# Silent response function (does nothing)
silentResponse() {
  :  # No-op
}

# Enable/disable verbose output
set_verbose() {
  if (( VERBOSE )); then
    vResponse='echo'
  else
    vResponse='silentResponse'
  fi
}

usage() {
    cat << EOF
WAFciser - Check Point WAF Demonstration Tool - Version $VERSION - by Vince Mammoliti -
Usage: $0 (-a|--app) web|api [OPTIONS...]

Options:
  -a, --app web|api    Target application type (required) (default: web)
  -g, --good           Send good/benign traffic (default)
  -m, --malicious      Send malicious traffic
  -r, --ratelimit      Run ratelimit test (web only)
  -n, --repeat N       Number of times to repeat (default: $REPEAT)
  -d, --delay N        Delay in seconds between requests (default: $DELAY)
  -i, --initdb         Initialize API DB (api only)
  -s, --sql            Run SQL injection test (api only)
  -u, --sqlupdate      Update sqlmap database
  -v, --verbose        Show detailed output
  -h, --help           Show this help message

Examples:
  $0 --app web --good --repeat 5
  $0 --app api --malicious --repeat 3
  $0 --app api --initdb
  $0 --app web --ratelimit --repeat 100 --delay 10

Environment Variables:
  DEFAULT_URL_CPTRAFFIC  Override default WEB URL
  DEFAULT_URL_CPAPI      Override default API URL
EOF
    exit 0
}


# Curl with timeouts.
curl_to() {
   curl --connect-timeout "$CURL_TIMEOUT" \
         --max-time "$CURL_CONNECTTIMEOUT" \
         -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.5993.90 Safari/537.36" \
         -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
         -H "Accept-Language: en-US,en;q=0.9" \
         -H "Connection: keep-alive" \
         "$@"
    return 0
}

 


# Utility: HTTP status code description 
get_http_status_description() {
  case "$1" in
    200) echo "OK ✅" ;;
    301) echo "Moved Permanently" ;;
    307) echo "Temporary Redirect" ;;
    400) echo "Bad Request 👎" ;;
    403) echo "Forbidden 🚫" ;;
    404) echo "Not Found" ;;
    429) echo "Too Many Requests" ;;
    500) echo "Internal Server Error 💥" ;;
    502) echo "Bad Gateway" ;;
    504) echo "Gateway Timeout" ;;
    *) echo "Unknown Status Code" ;;
  esac
}

# Web site traffic generators
traffic_good_juiceshop() {

  hostcheck
  echo -e "\nGenerating good traffic on a website\n"
  for ((i=1; i<=REPEAT; i++)); do
    echo "$i of $REPEAT) Testing Against URL: $HOST"
    python /home/web-scraper/websitescrap.py "$HOST"
    sleep "$DELAY"
  done
}

traffic_malicious_juiceshop() {
  hostcheck
  echo -e "\nGenerating malicious traffic for Juice Shop Host\n"
  for ((i=1; i<=REPEAT; i++)); do
    echo "$i of $REPEAT) Testing Against URL: $HOST"
    cd /home/juice-shop-solver && python main.py "$HOST"
    sleep "$DELAY"
  done
}

ratelimit_traffic() {
  echo "----------------------------------------------------------------"
  echo "Sending $REPEAT requests to $HOST with ${DELAY}s delay between each request."
  echo "----------------------------------------------------------------"
  
  for ((i=1; i<=REPEAT; i++)); do
    echo "Request #$i at $(date +%T)"
    
    # Execute curl and capture both the HTTP code and total time
    CURL_OUTPUT=$(curl_to -s -o /dev/null -w "%{http_code}|||%{time_total}" "$HOST")
    
    # Extract the http_code and time_total
    HTTP_CODE=$(echo "$CURL_OUTPUT" | cut -d'|' -f1)
    TIME_TOTAL=$(echo "$CURL_OUTPUT" | cut -d'|' -f4)
    
    # Get the description for the HTTP status code
    STATUS_DESCRIPTION=$(get_http_status_description "$HTTP_CODE")
    
    # Print formatted output
    printf "Status: %s (%s) | Time: %ss\n" "$HTTP_CODE" "$STATUS_DESCRIPTION" "$TIME_TOTAL"
    echo "------------------------"
    
    if ((i < REPEAT)); then
      sleep "$DELAY"
    fi
  done
  
  echo "Finished sending all requests."
}

# VAMPI traffic and API training
# Helper function to get token
gettoken() {
  OUTPUT=$(curl_to -sS -X POST "${HOST}/users/v1/login" \
          -H 'accept: application/json' \
          -H 'Content-Type: application/json' \
          -d '{ "password": "pass1", "username": "admin" }' \
  )
#          | jq -r '.auth_token')
 $vResponse -e ${OUTPUT:0:$CHAR} "\n"

# Parse the response with jq and store token
    if ! TOKEN=$(echo "$OUTPUT" | jq -r '.auth_token'); then
        echo -e "${RED}Failed to parse auth_token from response${NC}" >&2
        return 1
    fi
    
    # Verify token isn't null or empty
    if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
        echo -e "${RED}No valid auth_token in response${NC}" >&2
        return 1
    fi


  return 0
}

# Check if response was blocked by WAF
ifblocked() {
  if echo "$OUTPUT" | grep -q -o  "Application Security"; then
    echo -e "${RED}Check Point WAF - Application Security Blocked ${NC}"
  fi
}

initdb_vampi() {
 
  hostcheck
  echo -e "Initializing VAMPI DB\n"
  OUTPUT=$(curl_to -sS -H 'accept: application/json' -X 'GET' "${HOST}/users/v1")
  if echo "$OUTPUT" | grep -q -o 'no such table: users'; then
    OUTPUT=$(curl_to -sS -H 'accept: application/json' -X 'GET' "${HOST}/createdb")
    if echo "$OUTPUT" | grep -q -o -P '.{0,20}Application Security.{0,4}'; then
      echo -e "${RED}Check Point - Application Security Blocked ${NC}"
      echo -e "Reexecute the command directly to the non protected host URL"
      exit 1
    fi
    exit 1
  else
    echo -e "VAMPI DB is already Initialized"
    exit 1
  fi
}

checkdb() {
  echo -e "Checking VAMPI DB has been initialized on ${HOST}\n"
  OUTPUT=$(curl_to -sS -H 'accept: application/json' -X 'GET' "${HOST}/users/v1")
  if echo "$OUTPUT" | grep -q -o 'no such table: users'; then
    echo -e "${RED}VAMPI DB has NOT been Initialized - Please Initialize to Continue. Use --initdb option to initialize the VAMPI DB.${NC}"
    exit 1
  fi
}


hostcheck() {
  echo -e "WAFciser v$VERSION is a unified WAF Test & Training Tool - by Vince Mammoliti - vincem@checkpoint.com & Co-conspirator Marlon Chung \n - Check Point Software 2025 (-h) for usage \n
"
  local stripped_host="${HOST#http://}"
  stripped_host="${stripped_host#https://}"
  stripped_host="${stripped_host%%:*}"

  # Extract just the hostname (before any slash)
  stripped_host="${stripped_host%%/*}"

  if timeout 5 getent hosts "$stripped_host" > /dev/null; then
    echo "✅ Hostname '$stripped_host' resolved successfully."
  else
    echo -e "${RED}❌ Hostname '$stripped_host' could not be resolved.${NC}"
    exit 2
  fi
}

traffic_good_vampi() {
 
  hostcheck
  checkdb
  echo -e "\nWAF API - Training Traffic - Simulator\n"
  for ((i = 0; i < REPEAT; ++i)); do
    loop=$((i + 1))
    echo "Loop: $loop"
    echo "1) GET /"
    OUTPUT=$(curl_to -sS -H 'accept: application/json' -X 'GET' "${HOST}")
    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"


    echo "2) GET /books/v1"
    OUTPUT=$(curl_to -sS -H 'accept: application/json' -X 'GET' "${HOST}/books/v1")
    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"


    echo "3) GET /users/v1"
    OUTPUT=$(curl_to -sS -H 'accept: application/json' -X 'GET' "${HOST}/users/v1")
    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"


    echo "4) POST /user/v1/login"
    TOKEN=$(curl_to -sS -X POST "${HOST}/users/v1/login" \
            -H 'accept: application/json' \
            -H 'Content-Type: application/json' \
            -d '{ "password": "pass1", "username": "name1" }' \
            | jq -r '.auth_token')

    OUTPUT=${TOKEN}        
    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"


    echo "5) GET /users/v1/admin"
    OUTPUT=$(curl_to -sS -H 'accept: application/json' -X 'GET' "${HOST}/users/v1/admin")

    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"


    echo "6) POST /books/v1 - new book added"
    OUTPUT=$(curl_to -sS -X 'POST' "${HOST}/books/v1" \
            -H 'accept: application/json' \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
              "book_title": "cp-GCWAF-102",
              "secret": "cp-secret"
            }')

    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"


    echo "7) GET /books/v1/cp-GCWAF-102 - book details"
    OUTPUT=$(curl_to -sS -X GET "${HOST}/books/v1/cp-GCWAF-102" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $TOKEN")

    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"


    sleep "$DELAY"
  done
}

traffic_malicious_vampi() {
 
  hostcheck
  checkdb
  echo -e "\nSending Malicious API Traffic to VAMPI\n"
  for ((i = 0; i < REPEAT; ++i)); do
    loop=$((i + 1))
    echo "Loop: $loop"
    gettoken
 # Create a Bad Book Lookup
    echo "1) Send a bad book lookup - sending /books/v1/cp-GCWAF-102x"
    OUTPUT=$(curl_to -sS -X GET "${HOST}/books/v1/cp-GCWAF-102x" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $TOKEN")
    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"

    echo "2) Send an attempt to exploit account - send /users/v1/user1'"
    OUTPUT=$(curl_to -sS -X GET "${HOST}/users/v1/user1'" \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $TOKEN")
    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"
   
    echo "3) Send an attempt to exploit developer testing tool - send /users/v1/_debug"
    OUTPUT=$(curl_to -sS -X GET "${HOST}/users/v1/_debug" \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $TOKEN")
    ifblocked
    $vResponse -e ${OUTPUT:0:$CHAR} "\n"
    
    
    echo "4) DELETE /users/v1/cgwaf2 "
    OUTPUT=$(curl_to -sS -X DELETE   ${HOST}/users/v1/cgwaf2  -H 'Content-Type: application/json' \
         -H "Authorization: Bearer $TOKEN"
           )
    ifblocked
    $vResponse $OUTPUT
    
    echo "5) /ui "
    OUTPUT=$(curl_to -sS ${HOST}/ui)
    ifblocked
    $vResponse $OUTPUT
    
    sleep "$DELAY"
    done  
}

sql_vampi() {
  hostcheck
  if ! [ -x "$(command -v sqlmap)" ]; then
    echo "sqlmap is not installed - please install 'apt-get install sqlmap'" >&2
    exit 1
  fi
  echo "Running SQL injection test on ${HOST}"
  gettoken
  sqlmap -u "${HOST}/users/v1/*name1*" \
         --method=GET \
         --headers="Accept: application/json\nAuthorization: Bearer $TOKEN" \
         --dbms=sqlite --dump --batch

exit 1  
}

sqlupdate_vampi() {
  if ! [ -x "$(command -v sqlmap)" ]; then
    echo "sqlmap is not installed - please install 'apt-get install sqlmap'" >&2
    exit 1
  fi
  echo "Updating sqlmap..."
  sqlmap --update
  exit 1
}

# Standardize error exits
die() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}


# Check if no arguments provided
if [[ $# -eq 0 ]]; then
#    usage
echo " Using Default Settings - Web Application - Good Traffic" 
fi


# Argument parsing
while [[ $# -gt 0 ]]; do
  key="$1"
    case $key in
        -a|--app)
            if [[ -n "${2:-}" ]]; then
                APP="$2"
                shift 2
            else
                echo "Error: -a|--app requires a value (web or api)" >&2
                exit 1
            fi
            ;;
        -g|--good)
            MODE="good"
            shift
            ;;
        -m|--malicious)
            MODE="malicious"
            shift
            ;;
        -r|--ratelimit)
            MODE="ratelimit"
            APP="web"
            shift
            ;;
        -n|--repeat)
            if [[ -n "${2:-}" ]]; then
                REPEAT="$2"
                shift 2
            else
                echo "Error: -n|--repeat requires a number" >&2
                exit 1
            fi
            ;;
        -d|--delay)
            if [[ -n "${2:-}" ]]; then
                DELAY="$2"
                shift 2
            else
                echo "Error: -d|--delay requires a number" >&2
                exit 1
            fi
            ;;
        -i|--initdb)
            INITDB=1
            APP="api"
            shift
            ;;
        -s|--sql)
            SQL=1
            APP="api"
            shift
            ;;
        -u|--sqlupdate)
            SQLUPDATE=1
            APP="api"
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            ;;
    *)
  #    echo "Unknown option: ${1:-}" >&2
#      usage
      # Positional argument for URL
      if [ $# -gt 0 ] && [ -n "${1:-}" ]; then
        if [[ "${1:-}" != http* ]]; then
        echo -e "${RED}ERROR: URL must start with http:// or https://${NC}"
        exit 2 
        fi
      HOST=${1} 
      fi
      shift

      ;;
  esac
done

# Set verbose mode based on flag
set_verbose

# Main dispatch


if [[ "$APP" == "web" ]]; then
#Check to see if DEFAULT_URL_CPTRAFFIC URL has been passed.
#
##if [ -z "${DEFAULT_URL_CPTRAFFIC:-}" ]; then
   if [ -z "${HOST:-}" ]; then
   	HOST=${HOST_WEB}
    fi
#else
#	HOST=${DEFAULT_URL_CPTRAFFIC}
#fi




  case "$MODE" in
    good) traffic_good_juiceshop ;;
    malicious) traffic_malicious_juiceshop ;;
    ratelimit) ratelimit_traffic ;;
    *) echo "Unknown mode for Juice Shop: $MODE"; exit 1;;
  esac
elif [[ "$APP" == "api" ]]; then

#Check to see if DEFAULT_URL_CPAPI URL has been passed.
#
#if [ -z "${DEFAULT_URL_CPAPI:-}" ]; then
   if [ -z "${HOST:-}" ]; then
   	HOST=${HOST_API}
    fi
#else
#HOST=${DEFAULT_URL_CPAPI}
#fi
  if (( INITDB )); then initdb_vampi; fi
  if (( SQL )); then sql_vampi; fi
  if (( SQLUPDATE )); then sqlupdate_vampi; fi
  case "$MODE" in
    good) traffic_good_vampi ;;
    malicious) traffic_malicious_vampi ;;
    *) echo "Unknown mode for VAMPI: $MODE"; exit 1;;
  esac
else
  echo "Unknown app: $APP"; usage
fi
