#!/bin/bash

# here it sets the directory variables based on $pwd
# here it creates the styles.css file

# Function to create preview images

# Here there is a create_preview function that converts all images to a smaller format in the PREVIEWS_DIR variable previously set



# Function to create an HTML file for a subdirectory showing all images
create_subdir_index() {
    local dir_path="$1"
    local relative_path="${dir_path#$PICTURES_DIR/}"  # Remove PICTURES_DIR part from the path
    local html_file_name="${relative_path//\//-}.html"  # Replace '/' with '-' in file name
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
    local file_path="$1"
    local output_file="$2"
    local file_name=$(basename "$file_path")
    local preview_path="../${PREVIEW_DIR}/$file_name"  # Path to the preview image

    # Write the image tag wrapped in an anchor tag to the HTML file
    # Link to the original image and use the preview image as the source
    echo "<a href=\"../${file_path}\" target=\"_blank\"><img src=\"$preview_path\" alt=\"$file_name\" style='height:200px;'></a>" >> "$output_file"
}

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

        # Skip the subdir-html folder
        if [ "$folder_name" = "subdir-html" ]; then
            continue
        fi

        echo "<div class='folder-entry'>" >> index.html
        echo "<h3><a href='${SUBDIR_HTML_DIR}/${folder_name}.html'>$folder_name</a></h3>" >> index.html

        # Initialize a counter for the images
        local img_count=0

        # Loop through image files in the folder, sorted by name
        for img_file in "${folder}"*.{jpg,jpeg,png,avif,webp}; do
            # Only proceed if it's a file and we have less than 4 images
            if [ -f "$img_file" ] && [ $img_count -lt 4 ]; then
                # Increment the counter
                ((img_count++))

                # Extract just the file name
                file_name=$(basename "$img_file")

                # Add the image and link to the original image in the index.html
                echo "<a href='${folder}${file_name}' target='_blank'><img src='.preview/${file_name}' alt='$folder_name Image' style='height: 200px;'></a>" >> index.html
            fi
        done

        echo "</div>" >> index.html
    done

    cat << EOF >> index.html
</body>
</html>
EOF
}


# Loop through each folder in the Pictures directory to create subdir HTMLs
for subdir in "${PICTURES_DIR}"/*/; do
    if [ -d "$subdir" ]; then
        create_subdir_index "$subdir"
    fi
done


for folder in */ ; do
    for img_file in "${folder}"*; do
        # Extract file extension and check if it's a valid image format
        file_extension="${img_file##*.}"
        case "$file_extension" in
            jpg|jpeg|png|avif|webp)
                # It's a valid image file, process it
                file_name=$(basename "$img_file")
                create_preview "$img_file" ".preview/$file_name"
                ;;
            *)
                # Not a valid image file, skip it
                echo "Skipping non-image file: $img_file" >> debug.log
                ;;
        esac
    done
done

create_index_html

echo "Script completed."
