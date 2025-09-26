#!/bin/bash

# Set default values
DEPTH=2
OUTPUT_DIR="/tmp/crawl_output"
WAIT_TIME=2
MAX_RATE="100k"


# Color definitions
GREEN='\033[0;32m'
NC='\033[0m' # No Color




# Help function
show_help() {
    echo "Usage: $0 [-d depth] [-o output_dir] [-w wait_time] [-r rate_limit] URL"
    echo "Options:"
    echo "  -d    Maximum depth level (default: 2)"
    echo "  -o    Output directory (default: crawl_output)"
    echo "  -w    Wait time between requests in seconds (default: 2)"
    echo "  -r    Rate limit in bytes/second (default: 100k)"
    echo "  -h    Show this help message"
}

# Parse command line arguments
while getopts "d:o:w:r:h" opt; do
    case $opt in
        d) DEPTH="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        w) WAIT_TIME="$OPTARG" ;;
        r) MAX_RATE="$OPTARG" ;;
        h) show_help; exit 0 ;;
        ?) show_help; exit 1 ;;
    esac
done

# Shift arguments to get URL
shift $((OPTIND-1))
URL="$1"

# Validate input
if [ -z "$URL" ]; then
    echo "Error: URL is required"
    show_help
    exit 1
fi


# Progress bar function# Progress bar function# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local width=50
    
    # Check for valid total
    if [[ $total -eq 0 ]]; then
        printf "\rAnalyzing... URLs found: %d" "$current"
        return
    fi
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "\r[${GREEN}"
    printf "%-${filled}s" | tr ' ' '='
    printf "${NC}"
    printf "%-${empty}s" | tr ' ' ' '
    printf "] %3d%% (%d/%d URLs)" "$percentage" "$current" "$total"
}

crawl_with_progress() {
    local url=$1
    local depth=$2
    local output_dir=$3
    
    echo "Analyzing site structure..."
    local total_urls=$(wget --spider --recursive --level="$depth" \
        --no-verbose --output-file=- "$url" 2>/dev/null | \
        grep '^--' | wc -l)
    
    # Validate total_urls
    if [[ $total_urls -eq 0 ]]; then
        echo "Warning: Could not determine total URLs. Running with dynamic counter..."
        total_urls=100  # Set default estimate
    fi
    
 
    
    local temp_file=$(mktemp)
    
    wget --recursive \
        --level="$depth" \
        --wait="$WAIT_TIME" \
        --limit-rate="$MAX_RATE" \
        --page-requisites \
        --html-extension \
        --convert-links \
        --restrict-file-names=windows \
        --domains "$(echo "$url" | awk -F[/:] '{print $4}')" \
        --no-parent \
        --directory-prefix="$output_dir" \
        --output-file="$temp_file" \
        "$url" &
    
    local wget_pid=$!
    local current_urls=0
    
    while kill -0 $wget_pid 2>/dev/null; do
        current_urls=$(grep -c '^--' "$temp_file")
        show_progress "$current_urls" "$total_urls"
        sleep 1
    done
    
    current_urls=$(grep -c '^--' "$temp_file")
    show_progress "$current_urls" "$total_urls"
    echo -e "\nCrawl complete!"
    
    rm -f "$temp_file"
}



# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Starting crawl of $URL"
echo "Depth: $DEPTH"
echo "Output directory: $OUTPUT_DIR"
echo "Wait time: $WAIT_TIME seconds"
echo "Rate limit: $MAX_RATE"

# Start crawling
#
crawl_with_progress "$URL" "$DEPTH" "$OUTPUT_DIR"
echo "Crawl complete. Results saved in $OUTPUT_DIR"
