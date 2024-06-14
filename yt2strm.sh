#!/bin/bash

# sudo apt update
# sudo apt install yt-dlp jq

# Define the base directory where the channel folders will be created
BASE_DIR="/path/to/base_directory"

# Define the log file to keep track of processed videos
LOG_FILE="processed_videos.log"

# Define the file containing the list of channel URLs
CHANNELS_FILE="channels.txt"

# Create base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Function to create .strm files for a given channel
process_channel() {
  local channel_url=$1
  local channel_info
  channel_info=$(yt-dlp -J --flat-playlist "$channel_url")
  
  local channel_id
  channel_id=$(echo "$channel_info" | jq -r '.id')
  
  local channel_name
  channel_name=$(echo "$channel_info" | jq -r '.title')

  # Create channel folder
  local channel_folder="$BASE_DIR/${channel_name// /_} [$channel_id]"
  mkdir -p "$channel_folder"

  # Fetch video details
  yt-dlp -j --dateafter now-2y "$channel_url" | jq -r '. | "\(.id) \(.upload_date) \(.title)"' | while read -r video_id upload_date video_title; do
    # Check if the video has already been processed
    if grep -q "$video_id" "$LOG_FILE"; then
      echo "Skipping $video_id, already processed."
      continue
    fi

    # Sanitize video title for filename
    local sanitized_title
    sanitized_title=$(echo "$video_title" | tr -dc '[:alnum:][:space:]-_')

    # Create the .strm file
    local strm_file="$channel_folder/${upload_date}_${sanitized_title}.strm"
    echo "https://www.youtube.com/watch?v=$video_id" > "$strm_file"
    
    # Log the processed video
    echo "$video_id" >> "$LOG_FILE"
  done
}

# Read the channels file and process each channel
while IFS= read -r channel_url; do
  process_channel "$channel_url"
done < "$CHANNELS_FILE"
