#!/bin/bash

# --- Configuration ---

# The URL to send the curl requests to.
# Can be overridden by the first command-line argument.
URL="http://localhost:8080/api/v1/test"

# The total number of requests to send.
# Can be overridden by the second command-line argument.
NUMBER_OF_REQUESTS=10

# The delay in seconds between each request.
# Can be overridden by the third command-line argument.
DELAY=1

# --- Script ---

# Function to display usage information
usage() {
  echo "Usage: $0 [URL] [NUMBER_OF_REQUESTS] [DELAY]"
  echo "  URL: The URL to send the curl requests to (default: $URL)"
  echo "  NUMBER_OF_REQUESTS: The total number of requests to send (default: $NUMBER_OF_REQUESTS)"
  echo "  DELAY: The delay in seconds between each request (default: $DELAY)"
  exit 1
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


# Override default values with command-line arguments if provided
if [ "$1" ]; then
  URL="$1"
fi

if [ "$2" ]; then
  # Check if the second argument is a positive integer
  if ! [[ "$2" =~ ^[0-9]+$ ]] || [ "$2" -le 0 ]; then
    echo "Error: NUMBER_OF_REQUESTS must be a positive integer."
    usage
  fi
  NUMBER_OF_REQUESTS="$2"
fi

if [ "$3" ]; then
  # Check if the third argument is a non-negative number
  if ! [[ "$3" =~ ^[0-9]*\.?[0-9]+$ ]]; then
    echo "Error: DELAY must be a non-negative number."
    usage
  fi
  DELAY="$3"
fi

echo "Sending $NUMBER_OF_REQUESTS requests to $URL with a ${DELAY}s delay between each request."
echo "----------------------------------------------------------------"

for (( i=1; i<=NUMBER_OF_REQUESTS; i++ ))
do
  echo "Request #$i at $(date +%T)"

  # Execute curl and capture both the HTTP code and total time into a variable
  # Use a separator that's unlikely to appear in the output, like '|||'
  CURL_OUTPUT=$(curl -s -o /dev/null -w "%{http_code}|||%{time_total}" "$URL")

  # Extract the http_code and time_total from the output
  HTTP_CODE=$(echo "$CURL_OUTPUT" | cut -d'|' -f1)
  TIME_TOTAL=$(echo "$CURL_OUTPUT" | cut -d'|' -f3) # Using cut -f3 because there are three '|' chars

  # Get the description for the HTTP status code
  STATUS_DESCRIPTION=$(get_http_status_description "$HTTP_CODE")

  # Print the formatted output
  printf "Status: %s (%s) | Time: %ss\n" "$HTTP_CODE" "$STATUS_DESCRIPTION" "$TIME_TOTAL"
  echo "------------------------"

  # Don't sleep after the last request
  if [ $i -lt $NUMBER_OF_REQUESTS ]; then
    sleep $DELAY
  fi
done

echo "Finished sending all requests."
