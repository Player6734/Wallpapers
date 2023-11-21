#!/bin/bash

PICTURES_DIR=$(pwd)
PREVIEWS_DIR="$PICTURES_DIR/.previews"
SUBDIR_HTML_DIR="subdir-html"  # Name of the new directory to store HTML files
mkdir -p "$SUBDIR_HTML_DIR"
mkdir -p "$PREVIEWS_DIR"
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

    # Remove any double slashes in file paths
    original_file="${original_file//\/\///}"
    preview_file="${preview_file//\/\///}"

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

    mkdir -p "$(dirname "$preview_file")"  # Ensure the directory for the preview exists

    local original_width=$(identify -format "%w" "$original_file")
    local original_height=$(identify -format "%h" "$original_file")
    echo "Dimensions for $original_file: Width=$original_width, Height=$original_height" >> debug.log

    if [ "$original_height" -ne 0 ]; then
        local new_width=$((desired_height * original_width / original_height))
        echo $(pwd) >> debug.log
        echo $PREVIEWS_DIR$file_name >> debug.log
        echo "Running convert command: convert $original_file -strip -quality 75 -resize ${new_width}x${desired_height} $preview_file" >> debug.log
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



# Function to create an HTML file for a subdirectory and process images
process_directory() {
    local dir_path="$1"
    local relative_path="${dir_path#$PICTURES_DIR/}"  # Remove PICTURES_DIR part from the path

    # Skip processing the .previews and subdir-html directories
    if [[ "$dir_path" == *"/.previews"* || "$dir_path" == *"/subdir-html"* ]]; then
        return
    fi

    # Remove trailing slash from relative_path if present
    relative_path="${relative_path%/}"

    local html_file_path="${SUBDIR_HTML_DIR}/${relative_path}/index.html"  # Use index.html in corresponding subdirectory

    # Ensure the directory exists
    mkdir -p "$(dirname "$html_file_path")"

    # Write the header for the HTML file
    write_header "$html_file_path" "$(basename "$dir_path")"

    # Process images in the directory for HTML
    for img_file in "$dir_path"/*.{jpg,jpeg,png,avif,webp}; do
        if [ -f "$img_file" ]; then
            write_img "$img_file" "$html_file_path"
        fi
    done

    # Recursively process subdirectories
    for subdir in "$dir_path"/*/; do
        if [ -d "$subdir" ]; then
            process_directory "$subdir"
        fi
    done

    # Finalize the HTML file
    echo "</body></html>" >> "$html_file_path"
}











# Function to write the header of the HTML file
write_header() {
    local output_file="$1"
    local title="$2"
    local subdir_depth=$(awk -F"/" '{print NF-1}' <<< "${output_file#${SUBDIR_HTML_DIR}/}")
    local relative_path_prefix=$(printf '../%.0s' $(seq 1 $subdir_depth))

    cat > "$output_file" <<-EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>${title:-Gallery}</title>
    <link rel="stylesheet" type="text/css" href="${relative_path_prefix}styles.css">
</head>
<body>
EOF

    if [ -n "$title" ]; then
        echo "<h1>$title</h1>" >> "$output_file"
    fi
}


# Function to write an image tag to the HTML file
write_img() {
    local original_file="$1"
    local output_file="$2"
    local file_name=$(basename "$original_file")

    # Calculate the depth of the output file relative to the top directory
    local depth=$(awk -F"/" '{print NF-1}' <<< "${output_file#${SUBDIR_HTML_DIR}/}")
    local preview_path=$(printf '../%.0s' $(seq 1 $depth))".previews/$file_name"

    # Write the image tag wrapped in an anchor tag to the HTML file
    echo "<a href=\"$original_file\" target=\"_blank\"><img src=\"$preview_path\" alt=\"$file_name\" style='height:200px;'></a>" >> "$output_file"
}





# Function to create index.html with nested directory structure
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

    list_directories_recursively "$PICTURES_DIR" ""

    echo "</body></html>" >> index.html
}

# Function to list directories recursively
list_directories_recursively() {
    local dir_path="$1"
    local indentation="$2"
    local folder_name

    for folder in "$dir_path"/*/; do
        if [ -d "$folder" ]; then
            folder_name=$(basename "$folder")

            # Skip the subdir-html folder and .previews directory
            if [[ "$folder_name" != "subdir-html" && "$folder_name" != ".previews" ]]; then
                # Write the folder name with a link to its HTML file
                echo "$indentation<div class='folder-entry'>" >> index.html
                local html_file_name="${folder_name//\//-}.html"
                echo "$indentation<h3><a href='${SUBDIR_HTML_DIR}/${html_file_name}'>$folder_name</a></h3>" >> index.html

                # Recursively list subdirectories, skipping subdir-html
                list_directories_recursively "$folder" "$indentation&nbsp;&nbsp;&nbsp;&nbsp;"
                echo "$indentation</div>" >> index.html
            fi
        fi
    done
}




# Process each subdirectory
for subdir in "$PICTURES_DIR"/*/; do
    if [ -d "$subdir" ]; then
        process_directory "$subdir"
    fi
done

# Create previews for each image file
find "$PICTURES_DIR" -path "$PICTURES_DIR/.previews" -prune -o -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.avif" -o -name "*.webp" \) -print | while read img_file; do
    file_name=$(basename "$img_file")
    create_preview "$img_file" "$PREVIEWS_DIR/$file_name"
done

create_index_html
# A html file is generated for the folder containing all of the other html files, let's remove it.
rm $SUBDIR_HTML_DIR/$SUBDIR_HTML_DIR.html
echo "Script completed."
