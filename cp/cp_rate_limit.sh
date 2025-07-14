#!/bin/bash

# --- Configuration ---

# The URL to send the curl requests to.
# Can be overridden by the first command-line argument.
URL="http://vampi.lab/"

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
  # The -s flag silences the progress meter, and -o /dev/null discards the output.
  # The -w flag is used to print out the HTTP status code and total time.
  curl -s -o /dev/null -w "Status: %{http_code} | Time: %{time_total}s\n" "$URL"
  echo "------------------------"

  # Don't sleep after the last request
  if [ $i -lt $NUMBER_OF_REQUESTS ]; then
    sleep $DELAY
  fi
done

echo "Finished sending all requests."
