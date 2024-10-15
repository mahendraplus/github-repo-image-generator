#!/bin/bash

# Define color codes for output
GREEN='\033[0;32m'   # Green
BLUE='\033[0;34m'    # Blue
YELLOW='\033[0;33m'  # Yellow
RED='\033[0;31m'     # Red
NC='\033[0m'         # No Color

# Display tool description
echo -e "${GREEN}This tool automatically generates beautiful social media images for your GitHub repositories.${NC}"
echo -e "${BLUE}Created by: github.com/mahendraplus - Mahendra Mali${NC}"

# Function to display help message
show_help() {
    echo -e "${RED}Usage: $0 -u <github_username>${NC}"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  -u    Specify your GitHub username to fetch repositories."
    echo -e "  -h    Show this help message."
    exit 1
}

# Parse command-line arguments
while getopts "u:h" option; do
    case ${option} in
        u)
            USERNAME="$OPTARG"
            ;;
        h)
            show_help
            ;;
        *)
            show_help
            ;;
    esac
done

# Check if the username is provided
if [ -z "$USERNAME" ]; then
    echo -e "${RED}Error: You must provide a GitHub username.${NC}"
    show_help
fi

# Directory to save images
DOWNLOAD_DIR="downloads"

# Create the download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Fetch the repositories for the specified user
repo_response=$(curl -s "https://api.github.com/users/$USERNAME/repos?per_page=100")

# Extract the repository names
repo_names=$(echo "$repo_response" | jq -r '.[].name')

# Check if any repositories were found
if [ -z "$repo_names" ]; then
    echo -e "${RED}No repositories found for user $USERNAME.${NC}"
    exit 1
fi

# Download images for each repository
for REPO_NAME in $repo_names; do
    echo -e "${GREEN}Processing repository: $REPO_NAME${NC}"

    # API URL to fetch image URLs
    API_URL="https://lpf64gdwdb.execute-api.us-east-1.amazonaws.com/?repo=https://github.com/$USERNAME/$REPO_NAME"

    # Fetch image URLs
    response=$(curl -s "$API_URL")
    img_urls=$(echo "$response" | jq -r '.[]')

    # Initialize counter for naming images
    counter=1

    # Download each image
    for img_url in $img_urls; do
        img_name="${REPO_NAME}_${counter}.png"
        curl -o "$DOWNLOAD_DIR/$img_name" "$img_url"
        
        if [ $? -eq 0 ]; then
            echo -e "${BLUE}Downloaded: $img_name${NC}"
        else
            echo -e "${RED}Failed to download: $img_url${NC}"
        fi

        # Increment counter
        counter=$((counter + 1))
    done
done

echo -e "${YELLOW}All images have been saved in the $DOWNLOAD_DIR directory.${NC}"
