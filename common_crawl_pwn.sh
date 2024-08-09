#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 (-d <domain_file> | -t <target_domain>) -o <output_file> [-w]"
    echo "  -d: Domain file (mutually exclusive with -t)"
    echo "  -t: Target domain (mutually exclusive with -d)"
    echo "  -o: Output file"
    echo "  -w: Include wildcard results (optional)"
    exit 1
}

# Parse command line arguments
WILDCARD=false
while getopts "d:t:o:w" opt; do
    case $opt in
        d) DOMAIN_FILE="$OPTARG" ;;
        t) TARGET_DOMAIN="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        w) WILDCARD=true ;;
        *) usage ;;
    esac
done

if [ -z "$OUTPUT_FILE" ] || { [ -z "$DOMAIN_FILE" ] && [ -z "$TARGET_DOMAIN" ]; } || { [ -n "$DOMAIN_FILE" ] && [ -n "$TARGET_DOMAIN" ]; }; then
    usage
fi

METADATA_FILE="cc_metadata.txt"
INDEX_FILE="indexes.txt"

# Clear metadata file if it exists
> "$METADATA_FILE"

# Fetch list of available indexes
INDEXES_URL="https://index.commoncrawl.org/collinfo.json"
curl -s "$INDEXES_URL" | jq -r '.[] | .id' > "$INDEX_FILE"

# Function to select indexes for each year
select_indexes() {
    local year=$1
    grep "CC-MAIN-$year" "$INDEX_FILE" | sort -n -t '-' -k 3 | awk 'NR==1 || NR==int(NR/2) || NR==NF'
}

# Function to process a single domain
process_domain() {
    local domain=$1
    if [ "$WILDCARD" = true ]; then
        search_domain="*.$domain/*"
    else
        search_domain="$domain/*"
    fi

    for year in $(seq 2013 $(date +"%Y")); do
        selected_indexes=$(select_indexes "$year")
        for index in $selected_indexes; do
            echo "Searching for domain: $domain in index: $index"
            INDEX_URL="https://index.commoncrawl.org/$index-index?url=$search_domain&output=json"
            echo "Querying URL: $INDEX_URL"
            response=$(curl -s "$INDEX_URL")
            metadata_count=0
            while IFS= read -r line; do
                json_part=$(echo "$line" | sed 's/^[^{]*//')  # Remove non-JSON part of the line
                if echo "$json_part" | jq empty 2>/dev/null; then
                    echo "$json_part" | jq -r '[.url, .status, .filename, .offset, .length] | @csv' >> "$METADATA_FILE"
                    ((metadata_count++))
                else
                    echo "Warning: Invalid JSON response for domain $domain in index $index"
                fi
            done <<< "$response"
            echo "Saved $metadata_count metadata entries for $domain in index $index"
            ((total_metadata+=metadata_count))
        done
    done
}

# Extract metadata from Common Crawl Indexes
total_metadata=0
if [ -n "$TARGET_DOMAIN" ]; then
    process_domain "$TARGET_DOMAIN"
else
    while IFS= read -r domain; do
        process_domain "$domain"
    done < "$DOMAIN_FILE"
fi

echo "Metadata extraction complete. Total $total_metadata entries saved in $METADATA_FILE."

# Check if metadata file is empty
if [ ! -s "$METADATA_FILE" ]; then
    echo "No metadata was extracted. Exiting."
    exit 1
fi

# Generate complete URLs and save to output file
> "$OUTPUT_FILE"
while IFS=',' read -r url status filename offset length || [[ -n "$url" ]]; do
    # Skip empty lines
    [ -z "$url" ] && continue
    
    # Remove quotes from all fields
    url=$(echo $url | tr -d '"')
    filename=$(echo $filename | tr -d '"')
    offset=$(echo $offset | tr -d '"')
    length=$(echo $length | tr -d '"')
    
    FILE_URL="https://data.commoncrawl.org/$filename"
    COMPLETE_URL="${FILE_URL}#offset=${offset}&length=${length}"
    
    echo "Original: $url" >> "$OUTPUT_FILE"
    echo "$COMPLETE_URL" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"  # Add a blank line for readability
    
done < "$METADATA_FILE"

echo "URL generation complete. URLs saved in $OUTPUT_FILE."
