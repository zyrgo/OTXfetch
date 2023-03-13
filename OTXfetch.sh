#!/bin/bash

function print_logo {
  echo -e "\033[1;31m
  ____ _________   __ __     _       _
 / __ \__   __\ \ / // _|   | |     | |
| |  | | | |   \ V /| |_ ___| |_ ___| |__
| |  | | | |    > < |  _/ _ \ __/ __| '_ '\'
| |__| | | |   / . \| ||  __/ || (__| | | |
 \____/  |_|  /_/ \_\_| \___|\__\___|_| |_|
                                                           @zyrgo
\033[0m"
}

print_logo

function print_help {
  echo "OTXfetch - Fetch URLs from Alienvault OTX API"
  echo ""
  echo "Usage: ./OTXfetch.sh <domain>"
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message and exit"
}

if [[ $1 == "-h" || $1 == "--help" ]]; then
  print_help
  exit 0
elif [ -z "$1" ]; then
  echo "Error: no domain provided"
  echo ""
  print_help
  exit 1
fi

# Make the initial request to the API
response=$(curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$1/url_list?limit=500&page=1")

# Get the full_size from the response using jq
full_size=$(echo "$response" | jq -r '.full_size')

RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "Total number of urls is ${RED}$full_size${NC}\n"

if [[ $full_size -gt 500 ]]; then
  pages=$((($full_size - 1) / 500 + 1))
  urls=()

  for (( page=2; page<=$pages; page++ )); do

    new_response=$(curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$1/url_list?limit=500&page=$page")

    new_urls=($(echo "$new_response" | jq -r '.url_list[].url'))
    urls+=("${new_urls[@]}")

    progress=$((page * 100 / pages))

    num_hashes=$(echo "scale=0; $progress / 2" | bc)

    printf "\r\033[1;31m[%-${num_hashes}s] %d%%\033[0m" "$(printf '#%.0s' $(seq 1 $((num_hashes))))" $progress
  done

  printf '%s\n' "${urls[@]}" > $1-urls.txt
else

  echo "$response" | jq -r '.url_list[].url' > $1-urls.txt
fi

echo -e "\n\nURLs saved to $1-urls.txt"
