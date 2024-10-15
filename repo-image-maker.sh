#!/bin/bash

# GitHub Social Image Generator
# This tool automatically generates beautiful social media images for your GitHub repositories.
# Created by: github.com/mahendraplus - Mahendra Mali

# Function to display help message
function display_help() {
    echo "Usage: $0 -u <github_username>"
    echo ""
    echo "Options:"
    echo "  -u    Specify the GitHub username to fetch repositories."
    echo "  -h    Display this help message."
    exit 1
}

# Parse command-line arguments
while getopts ":u:h" opt; do
  case $opt in
    u)
      USERNAME=$OPTARG
      ;;
    h)
      display_help
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_help
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      display_help
      ;;
  esac
done

# Check if USERNAME is set
if [ -z "$USERNAME" ]; then
    echo "Error: GitHub username is required."
    display_help
fi

# Base directory to save images
DOWNLOAD_DIR="downloads"

# Create the directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Get all repositories for the specified user
repo_response=$(curl -s "https://api.github.com/users/$USERNAME/repos?per_page=100")

# Extract the repository names
repo_names=$(echo "$repo_response" | jq -r '.[].name')

# Loop through each repository
for REPO_NAME in $repo_names; do
    echo "Processing repository: $REPO_NAME"

    # URL to fetch images from the API for the current repository
    API_URL="https://lpf64gdwdb.execute-api.us-east-1.amazonaws.com/?repo=https://github.com/$USERNAME/$REPO_NAME"

    # Fetching image URLs
    response=$(curl -s "$API_URL")
    img_urls=$(echo "$response" | jq -r '.[]')

    # Initialize a counter for naming images
    counter=1

    # Create a temporary file to store image URLs for parallel download
    temp_file=$(mktemp)

    # Prepare image URLs with naming convention
    for img_url in $img_urls; do
        img_name="${REPO_NAME}_${counter}.png"
        echo "$img_url $DOWNLOAD_DIR/$img_name" >> "$temp_file"
        counter=$((counter + 1))
    done

    # Use xargs to download images in parallel without showing curl output
    cat "$temp_file" | xargs -n 2 -P 8 sh -c 'curl -s -o "$1" "$0"'

    # Clean up temporary file
    rm -f "$temp_file"
done

echo "All images have been downloaded to the $DOWNLOAD_DIR directory."
