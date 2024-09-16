#!/bin/zsh

# This script is used to copy from local folders into my Cloud Folders

# Create variables for paths
cloud_desktop="$HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs/Desktop"
local_desktop="$HOME/Desktop"
cloud_docs="$HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs/Documents"
local_docs="$HOME/Documents"

# List contents of the cloud desktop folder
echo "Contents of Cloud Desktop:"
ls "$cloud_desktop"
sleep 10

# Copy files from local desktop to cloud desktop
echo "Copying files from Local Desktop to Cloud Desktop..."
sleep 10
cp -r "$local_desktop"/* "$cloud_desktop"

# Copy files from local documents to cloud documents
echo "Copying files from Local Documents to Cloud Documents..."
cp -r "$local_docs"/* "$cloud_docs"

echo "Files copied successfully."
