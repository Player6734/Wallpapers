#!/bin/bash

# Define the path to the Pictures directory
PICTURES_DIR=$(pwd)
PREVIEWS_DIR="$PICTURES_DIR/.previews"

write_img_preview() {
    local original_file="$1"
    local output_file="$2"
    local preview_file_name=$(basename "$original_file")
    local preview_file_path="$PREVIEWS_DIR/$preview_file_name"

    # Call the create_preview function to create the preview image if it doesn't exist
    if [ ! -f "$preview_file_path" ]; then
        create_preview "$original_file" "$preview_file_path"
    fi

    # Write the HTML image tag to the output_file
    echo "<a href=\"$original_file\"><img src=\"$preview_file_path\" alt=\"$preview_file_name\" /></a>" >> "$output_file"
}

create_preview() {
    local original_file="$1"
    local preview_file="$2"
    local desired_height=200  # Set your desired height

    # Create a previews directory if it doesn't exist
    mkdir -p "$PREVIEWS_DIR"

    # Calculate the new width based on the desired height and original aspect ratio
    local original_width=$(identify -format "%w" "$original_file")
    local original_height=$(identify -format "%h" "$original_file")

    if [ "$original_height" -ne 0 ]; then
        local new_width=$((desired_height * original_width / original_height))

        # Reduce the quality and resize the image
        convert "$original_file" -strip -quality 75 -resize "${new_width}x${desired_height}" "$preview_file"
    else
        echo "Error: Unable to read image dimensions for $original_file"
    fi
}

# Function to process each directory
process_directory() {
    local dir_path="$1"
    local is_main_index="$2"
    local parent_dir="$(dirname "$dir_path")"
    local subdir_name=$(basename "$dir_path")
    local subdir_index_file="$parent_dir/${subdir_name}_index.html"

    if [[ "$is_main_index" != true ]]; then
        # Write header with directory name for subdir index files
        write_header "$subdir_index_file" "$subdir_name"
    fi

    # Process files in the current directory
    while IFS= read -r -d '' file_info; do
        if [[ "$is_main_index" == true ]]; then
            write_img_preview "$file_info" "$parent_dir/index.html"
        else
            write_img "$file_info" "$subdir_index_file"
        fi
    done < <(find "$dir_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) -print0)

    # Close HTML tags for subdir index files
    if [[ "$is_main_index" != true ]]; then
        echo "</body></html>" >> "$subdir_index_file"
    fi
}






process_directory() {
    local dir_path="$1"
    local main_output_file="$2"
    local subdir_name=$(basename "$dir_path")

    # Create a section with a title for the subdirectory
    echo "<div class='directory-section'>" >> "$main_output_file"
    echo "<h2 class='subdir-title'>$subdir_name</h2>" >> "$main_output_file"
    echo "<div class='subdir-previews'>" >> "$main_output_file"

    # Process files in the current directory
    local count=0
    while IFS= read -r -d '' file_info && [ "$count" -lt 8 ]; do
        write_img_preview "$file_info" "$main_output_file"
        ((count++))
    done < <(find "$dir_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) -print0)

    # Close the previews container div
    echo "</div>" >> "$main_output_file"
    # Close the directory section div
    echo "</div>" >> "$main_output_file"
}






write_img() {
    local file_path="$1"
    local output_file="$2"
    local preview_path="$PREVIEWS_DIR/$(basename "$file_path")"
    local desired_height=200  # Set your desired height here

    # Create a previews directory if it doesn't exist
    mkdir -p "$PREVIEWS_DIR"

    # Check if the preview already exists to avoid reprocessing
    if [ ! -f "$preview_path" ]; then
        # Calculate the width based on the desired height and original aspect ratio
        original_width=$(identify -format "%w" "$file_path")
        original_height=$(identify -format "%h" "$file_path")

        # Debugging output
        echo "Creating preview: $preview_path"
        echo "Original size: $original_width x $original_height"
        echo "New size: $new_width x $desired_height"


        if [ "$original_height" -ne 0 ]; then
            local new_width=$((desired_height * original_width / original_height))
            # Reduce the quality (e.g., 75%) and resize to the calculated width and desired height
            convert "$file_path" -strip -quality 75 -resize "${new_width}x${desired_height}" "$preview_path"
        else
            echo "Error: Unable to read image dimensions for $file_path"
            return  # Skip adding this image to the HTML if there's an error
        fi
    fi

    # Use the relative path for the preview in the HTML
    local relative_preview_path=$(realpath --relative-to="$PICTURES_DIR" "$preview_path")

    # Write the HTML tag with the preview as the source and link to the full image
    echo "Debug: output_file = '$output_file'"
    echo "<a href=\"$file_path\"><img src=\"$relative_preview_path\" alt=\"$(basename "$file_path")\" height=\"$desired_height\"></a>" >> "$output_file"
}





# Function to write the header of the HTML file
write_header() {
    local output_file="$1"
    local dir_name="$2"  # Optional directory name

    cat > "$output_file" <<-EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>${dir_name:-Gallery}</title>
    <link rel="stylesheet" type="text/css" href="styles.css">
</head>
<body>
EOF

    # Add directory name as a header if provided
    if [ -n "$dir_name" ]; then
        echo "<h1>$dir_name</h1>" >> "$output_file"
    fi
}


# Start the main index.html file
INDEX_FILE="$PICTURES_DIR/index.html"
write_header "$INDEX_FILE"

# Loop through each folder in the Pictures directory
for subdir in "$PICTURES_DIR"/*/; do
    if [ -d "$subdir" ]; then
        process_directory "$subdir" "$INDEX_FILE"
    fi
done

# Finalize the main index.html file
echo "</body></html>" >> "$INDEX_FILE"



echo "Script completed."
