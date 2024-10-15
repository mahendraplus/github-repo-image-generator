#!/bin/bash

# GitHub Social Image Generator
# This tool automatically generates beautiful social media images for your GitHub repositories.
# Created by: github.com/mahendraplus - Mahendra Mali

# Define text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display the title and description
display_info() {
    echo -e "${YELLOW}============================${NC}"
    echo -e "${GREEN}  GitHub Social Image Generator  ${NC}"
    echo -e "${YELLOW}============================${NC}"
    echo -e "This tool automatically generates beautiful social media images for your GitHub repositories."
    echo -e "Created by: ${CYAN}github.com/mahendraplus - Mahendra Mali${NC}"
    echo -e "${YELLOW}============================${NC}"
}

# Parse command-line arguments
while getopts ":u:r:" opt; do
    case $opt in
        u) USERNAME="$OPTARG" ;;
        r) REPO_NAME="$OPTARG" ;;
        \?) echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2; exit 1 ;;
    esac
done

# Display tool information
display_info

# Check if username is provided
if [ -z "$USERNAME" ]; then
    read -p "Please enter your GitHub username: " USERNAME
fi

# If a repository name is not provided, prompt for one
if [ -z "$REPO_NAME" ]; then
    read -p "Please enter a repository name (or leave blank for all): " REPO_NAME
fi

# Base directory to save images
DOWNLOAD_DIR="downloads"

# Create the directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Function to download images for a specific repository
download_images() {
    local repo_name="$1"
    echo -e "${BLUE}Processing repository: $repo_name${NC}"

    # URL to fetch images from the API for the current repository
    API_URL="https://lpf64gdwdb.execute-api.us-east-1.amazonaws.com/?repo=https://github.com/$USERNAME/$repo_name"

    # Fetching image URLs
    response=$(curl -s "$API_URL")
    img_urls=$(echo "$response" | jq -r '.[]')

    # Initialize a counter for naming images
    counter=1

    # Create a temporary file to store image URLs for parallel download
    temp_file=$(mktemp)

    # Prepare image URLs with naming convention
    for img_url in $img_urls; do
        img_name="${repo_name}_${counter}.png"
        echo "$img_url $DOWNLOAD_DIR/$img_name" >> "$temp_file"
        counter=$((counter + 1))
    done

    # Use xargs to download images in parallel without showing curl output
    cat "$temp_file" | xargs -n 2 -P 8 sh -c 'curl -s -o "$1" "$0"'

    # Clean up temporary file
    rm -f "$temp_file"
}

# If a specific repository is provided, download images for that repository
if [ -n "$REPO_NAME" ]; then
    download_images "$REPO_NAME"
else
    # Get all repositories for the specified user
    repo_response=$(curl -s "https://api.github.com/users/$USERNAME/repos?per_page=100")
    # Extract the repository names
    repo_names=$(echo "$repo_response" | jq -r '.[].name')

    # Loop through each repository
    for repo_name in $repo_names; do
        download_images "$repo_name"
    done
fi

echo -e "${GREEN}All images have been downloaded to the $DOWNLOAD_DIR directory.${NC}"
