#!/bin/bash

# Verbose Script to Generate a Main Index HTML with Previews for Each Subdirectory

# Define the absolute path to the Pictures directory where the script is run
PICTURES_DIR=$(pwd)
echo "Set PICTURES_DIR to $PICTURES_DIR"

# Define the path to the directory where previews will be stored
PREVIEWS_DIR="$PICTURES_DIR/.previews"
echo "Set PREVIEWS_DIR to $PREVIEWS_DIR"

# Function to create a scaled-down preview image from an original image
create_preview() {
    echo "Starting preview creation..."
    local original_file="$1"
    local preview_file="$2"
    local desired_height=200  # Desired height for preview images

    # Check if the previews directory exists, if not, create it
    mkdir -p "$PREVIEWS_DIR"
    echo "Ensured that the previews directory exists."

    # Calculate the new width to maintain the aspect ratio
    local original_width=$(identify -format "%w" "$original_file")
    local original_height=$(identify -format "%h" "$original_file")

    # If original height is non-zero, proceed to calculate new width and create the preview
    if [ "$original_height" -ne 0 ]; then
        local new_width=$((desired_height * original_width / original_height))

        # Resize the image and reduce quality to create a preview
        convert "$original_file" -strip -quality 75 -resize "${new_width}x${desired_height}" "$preview_file"
        echo "Created preview for $original_file as $preview_file"
    else
        # If the image size couldn't be determined, output an error message
        echo "Error: Unable to read image dimensions for $original_file"
    fi
    echo "Preview creation complete."
}

create_subdir_index() {
    local dir_path="$1"
    local subdir_name=$(basename "$dir_path")
    local subdir_html_file="$PICTURES_DIR/${subdir_name}.html"

    # Start writing the subdir index file with a standard HTML header
    write_header "$subdir_html_file" "$subdir_name"

    # Loop through each image file in the subdirectory and add it to the HTML
    echo "Adding images to $subdir_html_file..."
    find "$dir_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) | while read file_path; do
        write_img "$file_path" "$subdir_html_file"
        echo "Added image $(basename "$file_path") to $subdir_html_file"
    done

    # Close the HTML tags for the subdir index file
    echo "</body></html>" >> "$subdir_html_file"
    echo "$subdir_html_file created successfully."
}

# Function to create the main index.html file
create_main_index() {
    local pictures_dir="$1"
    local index_file="$2"

    # Begin writing the main index file with a standard HTML header
    write_header "$index_file" "Main Gallery"
    echo "Started writing to $index_file with a standard HTML header."

    # Loop through each directory within the Pictures directory
    for subdir in "$pictures_dir"/*/; do
        if [ -d "$subdir" ]; then
            local subdir_name=$(basename "$subdir")
            echo "Processing subdirectory: $subdir_name"

            # Create a header for the subdirectory in the index file
            echo "<div class='subdirectory'>" >> "$index_file"
            echo "<h2>$subdir_name</h2>" >> "$index_file"
            echo "<div class='preview-container'>" >> "$index_file"

            # Fetch up to 8 images from the subdirectory to create previews
            local count=0
            while IFS= read -r -d '' file_info && [ "$count" -lt 8 ]; do
                local preview_file="$PREVIEWS_DIR/$(basename "$file_info")"
                create_preview "$file_info" "$preview_file"
                echo "<img src='$preview_file' alt='Preview'>" >> "$index_file"
                ((count++))
                echo "Added preview for $(basename "$file_info") to $index_file"
            done < <(find "$subdir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) -print0)

            # Close the HTML tags for the preview container and the subdirectory section
            echo "</div>" >> "$index_file"
            echo "</div>" >> "$index_file"
            echo "Finished processing $subdir_name"
        fi
    done

    # Finalize the main index file by closing the HTML tags
    echo "</body></html>" >> "$index_file"
    echo "Completed writing to $index_file."
}

# Function to write the header of the HTML file
write_header() {
    local output_file="$1"
    local title="$2"  # Title is optional, defaults to 'Gallery'

    # Write the doctype and head section with title and link to stylesheet
    cat > "$output_file" <<-EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>${title:-Gallery}</title>
    <link rel="stylesheet" type="text/css" href="styles.css">
</head>
<body>
EOF

    # If a title is provided, add it as a header in the body
    if [ -n "$title" ]; then
        echo "<h1>$title</h1>" >> "$output_file"
        echo "Added header with title '$title' to $output_file"
    fi
}

# Main execution starts here
echo "Starting script..."

# Ensure the previews directory exists before starting the process
mkdir -p "$PREVIEWS_DIR"
echo "Verified that the previews directory exists."

# Define the main index file path
INDEX_FILE="$PICTURES_DIR/index.html"
echo "Set INDEX_FILE to $INDEX_FILE"

# Call the function to create the main index file
echo "Creating the main index file..."
create_main_index "$PICTURES_DIR" "$INDEX_FILE"

# Indicate script completion
echo "Script completed successfully."
