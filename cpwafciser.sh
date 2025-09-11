#!/usr/bin/env bash
set -euo pipefail
# cpwafciser is bash based application to demonstrate Check Point WAF capabilities
# Created to be used against Juice Shop and VAMPI applications 
# Written by Vince Mammoliti - vincem@checkpoint.com
# 25 Sept 08-  Combined of a few applicaiton into single for simplicity
# 

# Color setup
RED='\033[0;31m'
NC='\033[0m'

# Default values
APP="web"   # or "api
MODE="good"      # or "malicious" or "ratelimit"
REPEAT=1
DELAY=1
HOST_WEB="http://juiceshop.lab:80"
HOST_API="http://vampi.lab"
VERBOSE=0
INITDB=0
SQL=0
SQLUPDATE=0

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
$0 - Unified WAF Test & Training Tool

Usage:
  $0 --app web|api [--good|--malicious|--ratelimit] [--repeat N] [--delay N] [--initdb] [--sql] [--sqlupdate] [--help]

Options:
  --app         Target application: web or api
  --good        Send good/benign traffic (default)
  --malicious   Send malicious traffic
  --ratelimit   Run ratelimit test (web only)
  --repeat N    Number of times to repeat (default: 1)
  --delay N     Delay in seconds between requests (default: 1)
  --initdb      Initialize VAMPI DB (vampi only)
  --sql         Run SQL injection test (api only)
  --sqlupdate   Update sqlmap database
  --help        Show this help message

Examples:
  $0 --app web --good --repeat 5
  $0 --app api --malicious --repeat 3
  $0 --app api --initdb
  $0 --app web --ratelimit --repeat 100 --delay 10
EOF
  exit 0
}

# Utility: HTTP status code description 
get_http_status_description() {
  case "$1" in
    200) echo "OK ✅" ;;
    400) echo "Bad Request 👎" ;;
    403) echo "Forbidden 🚫" ;;
    404) echo "Not Found" ;;
    429) echo "Too Many Requests" ;;
    500) echo "Internal Server Error 💥" ;;
    *) echo "Unknown Status Code" ;;
  esac
}

# Juice Shop traffic generators
traffic_good_juiceshop() {
  echo -e "\nGenerating good traffic for Juice Shop\n"
  for ((i=1; i<=REPEAT; i++)); do
    echo "$i of $REPEAT) Testing Against URL: $HOST_WEB"
    python /home/web-scraper/websitescrap.py "$HOST_WEB"
    sleep "$DELAY"
  done
}

traffic_malicious_juiceshop() {
  echo -e "\nGenerating malicious traffic for Juice Shop\n"
  for ((i=1; i<=REPEAT; i++)); do
    echo "$i of $REPEAT) Testing Against URL: $HOST_WEB"
    cd /home/juice-shop-solver && python main.py "$HOST_WEB"
    sleep "$DELAY"
  done
}

ratelimit_traffic() {
  echo "----------------------------------------------------------------"
  echo "Sending $REPEAT requests to $HOST_WEB with ${DELAY}s delay between each request."
  echo "----------------------------------------------------------------"
  
  for ((i=1; i<=REPEAT; i++)); do
    echo "Request #$i at $(date +%T)"
    
    # Execute curl and capture both the HTTP code and total time
    CURL_OUTPUT=$(curl -s -o /dev/null -w "%{http_code}|||%{time_total}" "$HOST_WEB")
    
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
  TOKEN=$(curl -sS -X POST "${HOST_API}/users/v1/login" \
          -H 'accept: application/json' \
          -H 'Content-Type: application/json' \
          -d '{ "password": "pass1", "username": "admin" }' \
          | jq -r '.auth_token')
  return 0
}

# Check if response was blocked by WAF
ifblocked() {
  if echo "$OUTPUT" | grep -q -o -P '.{0,20}Application Security.{0,4}'; then
    echo -e "${RED}Check Point - Application Security Blocked ${NC}"
  fi
}

initdb_vampi() {
  echo -e "Initializing VAMPI DB\n"
  OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' "${HOST_API}/users/v1")
  if echo "$OUTPUT" | grep -q -o 'no such table: users'; then
    OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' "${HOST_API}/createdb")
    if echo "$OUTPUT" | grep -q -o -P '.{0,20}Application Security.{0,4}'; then
      echo -e "${RED}Check Point - Application Security Blocked ${NC}"
      echo -e "Reexecute the command directly to the non protected host URL"
      exit 1
    fi
  else
    echo -e "VAMPI DB is already Initialized"
    exit 1
  fi
}

checkdb() {
  echo -e "Checking VAMPI DB has been initialized\n"
  OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' "${HOST_API}/users/v1")
  if echo "$OUTPUT" | grep -q -o 'no such table: users'; then
    echo -e "${RED}VAMPI DB has NOT been Initialized - Please Initialize to Continue. Use --initdb option to initialize the VAMPI DB.${NC}"
    exit 1
  fi
}

traffic_good_vampi() {
  checkdb
  echo -e "\nWAF API - Training Traffic - Simulator\n"
  for ((i = 0; i < REPEAT; ++i)); do
    loop=$((i + 1))
    echo "Loop: $loop"
    echo "1) GET /"
    OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' "${HOST_API}/")

    echo "2) GET /books/v1"
    OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' "${HOST_API}/books/v1")

    echo "3) GET /users/v1"
    OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' "${HOST_API}/users/v1")

    echo "4) POST /user/v1/login"
    TOKEN=$(curl -sS -X POST "${HOST_API}/users/v1/login" \
            -H 'accept: application/json' \
            -H 'Content-Type: application/json' \
            -d '{ "password": "pass1", "username": "name1" }' \
            | jq -r '.auth_token')

    echo "5) GET /users/v1/admin"
    OUTPUT=$(curl -sS -H 'accept: application/json' -X 'GET' "${HOST_API}/users/v1/admin")

    echo "6) POST /books/v1 - new book added"
    OUTPUT=$(curl -sS -X 'POST' "${HOST_API}/books/v1" \
            -H 'accept: application/json' \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
              "book_title": "cp-GCWAF-102",
              "secret": "cp-secret"
            }')

    echo "7) GET /books/v1/cp-GCWAF-102 - book details"
    OUTPUT=$(curl -sS -X GET "${HOST_API}/books/v1/cp-GCWAF-102" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $TOKEN")

    sleep "$DELAY"
  done
}

traffic_malicious_vampi() {
  checkdb
  echo -e "\nSending Malicious API Traffic to VAMPI\n"
  for ((i = 0; i < REPEAT; ++i)); do
    loop=$((i + 1))
    echo "Loop: $loop"
    gettoken

    echo "1) Send a bad book lookup - sending /books/v1/cp-GCWAF-102x"
    OUTPUT=$(curl -sS -X GET "${HOST_API}/books/v1/cp-GCWAF-102x" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $TOKEN")
    ifblocked

    echo "2) Send an attempt to exploit account - send /users/v1/user1'"
    OUTPUT=$(curl -sS -X GET "${HOST_API}/users/v1/user1'" \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $TOKEN")
    ifblocked

    echo "3) Send an attempt to exploit developer testing tool - send /users/v1/_debug"
    OUTPUT=$(curl -sS -X GET "${HOST_API}/users/v1/_debug" \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $TOKEN")
    ifblocked

    sleep "$DELAY"
  done
}

sql_vampi() {
  if ! [ -x "$(command -v sqlmap)" ]; then
    echo "sqlmap is not installed - please install 'apt-get install sqlmap'" >&2
    exit 1
  fi
  echo "Running SQL injection test on ${HOST_API}"
  gettoken
  sqlmap -u "${HOST_API}/users/v1/*name1*" \
         --method=GET \
         --headers="Accept: application/json\nAuthorization: Bearer $TOKEN" \
         --dbms=sqlite --dump --batch
}

sqlupdate_vampi() {
  if ! [ -x "$(command -v sqlmap)" ]; then
    echo "sqlmap is not installed - please install 'apt-get install sqlmap'" >&2
    exit 1
  fi
  echo "Updating sqlmap..."
  sqlmap --update
}

# Argument parsing (basic, for demonstration)
while [[ $# -gt 0 ]]; do
  case $1 in
    --app)
      APP="$2"; shift 2;;
    --good)
      MODE="good"; shift;;
    --malicious)
      MODE="malicious"; shift;;
    --ratelimit)
      MODE="ratelimit"; shift;;
    --repeat)
      REPEAT="$2"; shift 2;;
    --delay)
      DELAY="$2"; shift 2;;
    --initdb)
      INITDB=1; shift;;
    --sql)
      SQL=1; shift;;
    --sqlupdate)
      SQLUPDATE=1; shift;;
    --verbose)
      VERBOSE=1; shift;;
    --help)
      usage;;
    *)
      echo "Unknown option: $1"; usage;;
  esac
done

# Set verbose mode based on flag
set_verbose

# Main dispatch
if [[ "$APP" == "web" ]]; then
  case "$MODE" in
    good) traffic_good_juiceshop ;;
    malicious) traffic_malicious_juiceshop ;;
    ratelimit) ratelimit_traffic ;;
    *) echo "Unknown mode for Juice Shop: $MODE"; exit 1;;
  esac
elif [[ "$APP" == "api" ]]; then
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
