#!/bin/bash

# Define the path to the Pictures directory
PICTURES_DIR=$(pwd)
PREVIEWS_DIR="$PICTURES_DIR/.previews"

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
    local output_file="$2"
    local subdir_name=$(basename "$dir_path")

    # Create a checkbox and a label for the directory
    echo "<input type='checkbox' id='$subdir_name' style='display:none;'>" >> "$output_file"
    echo "<label for='$subdir_name' style='font-size: 18px; color: #EBDBB2; cursor: pointer;'>$subdir_name</label>" >> "$output_file"
    echo "<div style='display:none;' id='content_$subdir_name'>" >> "$output_file"

    # Process files in the current directory
    while IFS= read -r -d '' file_info; do
        write_img "$file_info" "$output_file"
    done < <(find "$dir_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) -print0)

    echo "</div>" >> "$output_file"
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
    <link rel="stylesheet" type="text/css" href="../styles.css">
</head>
<body>
EOF

    if [ -n "$dir_name" ]; then
        echo "<h1>$dir_name</h1>" >> "$output_file"
    fi
}



# Create index file
INDEX_FILE="$PICTURES_DIR/index.html"
touch "$INDEX_FILE"
write_header "$INDEX_FILE"

# Loop through each folder in the Pictures directory
# Main script loop
for subdir in "$PICTURES_DIR"/*/; do
    if [ -d "$subdir" ]; then
        process_directory "$subdir" "$PICTURES_DIR/index.html"
    fi
done


echo "</body></html>" >> "$INDEX_FILE"


echo "Script completed."
