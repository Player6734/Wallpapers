#!/bin/bash

# Set the Pictures directory and the Previews directory.
PICTURES_DIR=$(pwd)
PREVIEWS_DIR="$PICTURES_DIR/.previews"

# Function to create a scaled-down preview image from an original image
create_preview() {
    local original_file="$1"
    local preview_file="$2"
    local desired_height=200  # Set your desired height for the preview image

    mkdir -p "$PREVIEWS_DIR"

    local original_width=$(identify -format "%w" "$original_file")
    local original_height=$(identify -format "%h" "$original_file")

    if [ "$original_height" -ne 0 ]; then
        local new_width=$((desired_height * original_width / original_height))
        convert "$original_file" -strip -quality 75 -resize "${new_width}x${desired_height}" "$preview_file"
    else
        echo "Error: Unable to read image dimensions for $original_file"
    fi
}

# Function to create an HTML file for a subdirectory showing all images
create_subdir_index() {
    local dir_path="$1"
    local subdir_name=$(basename "$dir_path")
    local subdir_html_file="$PICTURES_DIR/${subdir_name}.html"

    # Write the header of the subdir index file
    write_header "$subdir_html_file" "$subdir_name"

    # Loop through each image file in the subdirectory and add it to the HTML
    find "$dir_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) | while read file_path; do
        write_img "$file_path" "$subdir_html_file"
    done

    # Finalize the HTML file
    echo "</body></html>" >> "$subdir_html_file"
}

# Function to write the header of the HTML file
write_header() {
    local output_file="$1"
    local title="$2"

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

    if [ -n "$title" ]; then
        echo "<h1>$title</h1>" >> "$output_file"
    fi
}

# Function to write an image tag to the HTML file
write_img() {
    local file_path="$1"
    local output_file="$2"

    # Write the image tag to the HTML file
    echo "<img src=\"$file_path\" alt=\"$(basename "$file_path")\" style='height:200px;'>" >> "$output_file"
}

# Create the main index file with a header
INDEX_FILE="$PICTURES_DIR/index.html"
write_header "$INDEX_FILE" "Main Gallery"

# Loop through each folder in the Pictures directory to create subdir HTMLs
for subdir in "$PICTURES_DIR"/*/; do
    if [ -d "$subdir" ]; then
        create_subdir_index "$subdir"
    fi
done

# Generate main index previews after subdir HTMLs to ensure the preview images exist
create_main_index "$PICTURES_DIR" "$INDEX_FILE"

# Finalize the main index HTML file
echo "</body></html>" >> "$INDEX_FILE"

# Function to create index.html
create_index_html() {
    cat << EOF > index.html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" type="text/css" href="styles.css">
    <title>Index of Folders</title>
</head>
<body>
    <h1>Index of Folders</h1>
EOF

    for folder in */ ; do
        folder_name=${folder%/}
        echo "<div class='folder-entry'>" >> index.html
        echo "<h2><a href='${folder_name}.html'>$folder_name</a></h2>" >> index.html

        # Add up to four images from the folder
        img_count=0
        for img_format in jpg jpeg png avif webp; do
            for img in "${folder}"*.$img_format; do
                if [ $img_count -ge 4 ]; then
                    break 2  # Exit both loops when 4 images have been added
                fi
                if [ -f "$img" ]; then  # Check if the file actually exists
                    echo "<img src='$img' alt='$folder_name Image'>" >> index.html
                    ((img_count++))
                fi
            done
        done

        echo "</div>" >> index.html
    done

    cat << EOF >> index.html
</body>
</html>
EOF
}


echo "Script completed."
