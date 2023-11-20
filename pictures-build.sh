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

    mkdir -p ".preview"  # Ensure the .preview directory exists
    echo "Directory checked/created for .preview" >> debug.log

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
    local subdir_name=$(basename "$dir_path")
    local subdir_html_file="${SUBDIR_HTML_DIR}/${subdir_name}.html"

    # Write the header of the subdir index file
    write_header "$subdir_html_file" "$subdir_name"

    # Loop through each image file in the subdirectory and add it to the HTML
    find "$dir_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) | while read file_path; do
        write_img "$file_path" "$subdir_html_file" "$subdir_name"
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
    local subdir_name="$3"
    local file_name=$(basename "$file_path")
    local preview_path="../.preview/$file_name"  # Adjust the path to your preview directory structure

    # Write the image tag wrapped in an anchor tag to the HTML file
    echo "<a href=\"../${subdir_name}/${file_name}\" target=\"_blank\"><img src=\"$preview_path\" alt=\"$file_name\" style='height:200px;'></a>" >> "$output_file"
}


# Create the main index file with a header

# Loop through each folder in the Pictures directory to create subdir HTMLs
for subdir in "${PICTURES_DIR}"/*/; do
    if [ -d "$subdir" ]; then
        create_subdir_index "$subdir"
    fi
done

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
        # Assuming index.html is in the same directory as styles.css and .preview
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
                # The preview image path is relative to index.html's location
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

# Call the function to create index.html
create_index_html




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