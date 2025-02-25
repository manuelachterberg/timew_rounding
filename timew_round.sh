#!/bin/bash

# Function to round down time to the nearest 15 minutes and set seconds to 00
round_down_time() {
    local input_time=$1
    local rounded_time

    # Get minutes
    minutes=$(date -j -f "%H:%M:%S" "$input_time" +%M)
    
    # Round down to nearest 15 minutes
    rounded_minutes=$(( (minutes / 15) * 15 ))

    # Set the rounded time with seconds set to 00
    rounded_time=$(date -j -f "%H:%M:%S" -v -$((minutes - rounded_minutes))M "$input_time" +%H:%M:00)
    echo "$rounded_time"
}

# Function to round up time to the nearest 15 minutes and set seconds to 00
round_up_time() {
    local input_time=$1
    local rounded_time

    # Get minutes
    minutes=$(date -j -f "%H:%M:%S" "$input_time" +%M)
    
    # Round up to nearest 15 minutes
    rounded_minutes=$(( ((minutes + 14) / 15) * 15 ))

    # Set the rounded time with seconds set to 00
    rounded_time=$(date -j -f "%H:%M:%S" -v +$((rounded_minutes - minutes))M "$input_time" +%H:%M:00)
    echo "$rounded_time"
}

# Fetch time entries using 'timew summary :ids'
entries=$(timew summary :ids)

# Loop through all entries and round their start and end times
while IFS= read -r entry; do
    # Skip empty lines or non-relevant lines
    if [[ -z "$entry" || "$entry" =~ ^-- || "$entry" =~ ^Wk ]]; then
        continue
    fi
    
    # Extract start and end times using regex
    if [[ "$entry" =~ (@[0-9]+).*([0-9]{2}:[0-9]{2}:[0-9]{2})\ ([0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        id="${BASH_REMATCH[1]}"
        start_time="${BASH_REMATCH[2]}"
        end_time="${BASH_REMATCH[3]}"
        
        # Check if start_time and end_time are not empty and in correct format
        if [[ -n "$start_time" && -n "$end_time" && "$start_time" =~ [0-9]{2}:[0-9]{2}:[0-9]{2} && "$end_time" =~ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            # Round the start and end times
            rounded_start=$(round_down_time "$start_time")
            rounded_end=$(round_up_time "$end_time")

            # Update the entry using 'timew modify'
            timew modify start "$id" "$rounded_start"
            timew modify end "$id" "$rounded_end"

            # Print the rounded entry
            echo "Updated entry: ID: $id, Start time: $start_time -> $rounded_start, End time: $end_time -> $rounded_end"
        else
            echo "Skipping entry due to missing or incorrectly formatted start or end time: $entry"
        fi
    else
        echo "Skipping entry due to missing start or end time: $entry"
    fi
done <<< "$entries"