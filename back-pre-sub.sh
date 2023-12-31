#!/bin/bash

# Set the Pictures directory and the Previews directory.
PICTURES_DIR=$(pwd)
PREVIEWS_DIR="$PICTURES_DIR/.previews"
SUBDIR_HTML_DIR="subdir-html"  # Name of the new directory to store HTML files
mkdir -p "$SUBDIR_HTML_DIR"

cat << EOF > styles.css
body {
  background-color: #282828;
  color: #ebdbb2;
  padding: 0 4%;
  text-align: center;
}

h1, h3 {
  background-color: #ebdbb2;
  color: #282828;
  text-align: center;
}

img {
  transition: transform 0.3s ease; /* Smooth transition for hover effect */
}

img:hover {
  transform: scale(1.2); /* Enlarge image on hover */
}

a img {
  border: 0; /* Remove border around images inside links */
}

EOF


# Function to create preview images
create_preview() {
    local original_file="$1"
    local preview_file="$2"
    local desired_height=200  # Set your desired height for the preview image
    if [ -z "$original_file" ]; then
        echo "No file name provided for preview creation" >> debug.log
        return
    fi

    echo "Checking preview for: $original_file" >> debug.log

    # Check if the preview already exists
    if [ -f "$preview_file" ]; then
        echo "Preview already exists: $preview_file" >> debug.log
        return  # Skip creating the preview
    fi

    echo "Creating preview for $original_file" >> debug.log

    mkdir -p ".previews"  # Ensure the .previews directory exists
    echo "Directory checked/created for .previews" >> debug.log

    local original_width=$(identify -format "%w" "$original_file")
    local original_height=$(identify -format "%h" "$original_file")
    echo "Dimensions for $original_file: Width=$original_width, Height=$original_height" >> debug.log

    if [ "$original_height" -ne 0 ]; then
        local new_width=$((desired_height * original_width / original_height))
        echo "Processing file: $img_file" >> debug.log
        convert "$original_file" -strip -quality 75 -resize "${new_width}x${desired_height}" "$preview_file" 2>> debug.log
        if [ $? -eq 0 ]; then
            echo "Preview successfully created: $preview_file" >> debug.log
        else
            echo "Error during conversion for $original_file" >> debug.log
        fi
    else
        echo "Error: Unable to read image dimensions for $original_file" >> debug.log
    fi
}



# Function to create an HTML file for a subdirectory showing all images
create_subdir_index() {
    local dir_path="$1"
    local relative_path="${dir_path#$PICTURES_DIR/}"  # Remove PICTURES_DIR part from the path
    local html_file_name="${relative_path//\//_}.html"  # Replace '/' with '_' in file name
    local html_file_path="${SUBDIR_HTML_DIR}/${html_file_name}"

    # Write the header for the HTML file
    write_header "$html_file_path" "$(basename "$dir_path")"

    # Process images in the directory
    write_img "$dir_path" "$html_file_path"

    # Recursively process subdirectories
    for subdir in "$dir_path"/*/; do
        if [ -d "$subdir" ]; then
            create_subdir_index "$subdir"
        fi
    done

    # Finalize the HTML file
    echo "</body></html>" >> "$html_file_path"
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
    <link rel="stylesheet" type="text/css" href="../styles.css">
</head>
<body>
EOF

    if [ -n "$title" ]; then
        echo "<h1>$title</h1>" >> "$output_file"
    fi
}

# Function to write an image tag to the HTML file
write_img() {
    local dir_path="$1"
    local output_file="$2"

    # Loop through image files in the directory
    for img_file in "$dir_path"/*.{jpg,jpeg,png,avif,webp}; do
        if [ -f "$img_file" ]; then
            local file_name=$(basename "$img_file")
            local preview_path="../.previews/$file_name"  # Path to the preview image
            local relative_img_path="../$(basename "$dir_path")/$file_name"  # Relative path to the original image

            # Write the image tag wrapped in an anchor tag to the HTML file
            echo "<a href=\"$relative_img_path\" target=\"_blank\"><img src=\"$preview_path\" alt=\"$file_name\" style='height:200px;'></a>" >> "$output_file"
        fi
    done
}






# Create the main index file with a header

# Loop through each folder in the Pictures directory to create subdir HTMLs
for subdir in "${PICTURES_DIR}"/*/; do
    if [ -d "$subdir" ]; then
        create_subdir_index "$subdir"
    fi
done

# Function to create index.html
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

    list_subdirs "$PICTURES_DIR" ""

    cat << EOF >> index.html
</body>
</html>
EOF
}

list_subdirs() {
    local current_dir="$1"
    local prefix="$2"

    for folder in "$current_dir"*/ ; do
        if [ -d "$folder" ]; then
            local folder_name=${folder%/}
            folder_name=${folder_name##*/}

            # Skip the subdir-html folder
            if [ "$folder_name" = "subdir-html" ]; then
                continue
            fi

            local relative_html_path="${SUBDIR_HTML_DIR}/${prefix}${folder_name}.html"
            relative_html_path="${relative_html_path//\//_}"  # Replace '/' with '_' only once

            echo "<div class='folder-entry'><h3><a href='$relative_html_path'>$prefix$folder_name</a></h3></div>" >> index.html

            # Recursively list subdirectories
            list_subdirs "$folder" "$prefix$folder_name/"
        fi
    done
}



for folder in "${PICTURES_DIR}"/*/; do
    if [ -d "$folder" ]; then
        for img_file in "${folder}"*.{jpg,jpeg,png,avif,webp}; do
            if [ -f "$img_file" ]; then
                file_name=$(basename "$img_file")
                create_preview "$img_file" ".previews/$file_name"
            fi
        done
    fi
done


create_index_html

echo "Script completed."
exit 10
