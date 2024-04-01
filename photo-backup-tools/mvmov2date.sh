#!/usr/bin/env bash
#
# Get output directory for target directories
read -p "Enter the output directory for video files: " output_dir

# Create directory for files with no date
mkdir -p "${output_dir}/no-date"

# Loop through all MOV files
for file in *.mov *.MOV *.mp4 *.MP4; do
    # Use exiftool to extract create date information
    create_date=$(exiftool -CreateDate -s -s -s "$file")

    # Extract year and month from create date
    if [ -n "$create_date" ]; then
        year=$(echo "$create_date" | cut -d':' -f1)
        month=$(echo "$create_date" | cut -d':' -f2)

        # Create directory if not exists
        mkdir -p "${output_dir}/${year}-${month}"
	
	echo "-- Moving $file ($(du -h $file)) --> ${year}-${month}" 

        # Move file to appropriate directory
        mv "$file" "${output_dir}/${year}-${month}/"
    else
        # Move file to directory for files with no date
        mv "$file" "${output_dir}/no-date/"
    fi
done

