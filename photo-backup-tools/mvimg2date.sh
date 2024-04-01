#!/usr/bin/env bash

# Set base directory for target directories
#img_dir="/mnt/samsungt5/Fotos/fotos-uitzoeken-2020-date"
read -p "Enter the output directory for images files: " output_dir

# Create directory for files with no date
mkdir -p "${img_dir}/no-date"

# Loop through all JPEG files
for file in *.jpg *.JPG *.PNG *.png; do
    # Use file command to extract datetime information
    datetime=$(file "$file" | grep -oP 'datetime=\K[^,]*')

    # Extract year and month from datetime
    if [ -n "$datetime" ]; then
        year=$(echo "$datetime" | cut -d':' -f1)
        month=$(echo "$datetime" | cut -d':' -f2)

        # Create directory if not exists
        mkdir -p "${img_dir}/${year}-${month}"

        # Move file to appropriate directory
        mv "$file" "${img_dir}/${year}-${month}/"
    else
        # Move file to directory for files with no date
        mv "$file" "${img_dir}/no-date/"
    fi
done

