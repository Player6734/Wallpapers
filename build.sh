#!/bin/bash


PICTURES_DIR=$(pwd)
echo "Set PICTURES_DIR to $PICTURES_DIR"

PREVIEWS_DIR="$PICTURES_DIR/.previews"
echo "Set PREVIEWS_DIR to $PREVIEWS_DIR"

create_preview() {
    echo "Starting preview creation..."
    local original_file="$1"
    local preview_file="$2"

    mkdir -p "$PREVIEWS_DIR"
    echo "Ensured that the previews directory exists."

    local original_width=$(identify -format "%w" "$original_file")
    local original_height=$(identify -format "%h" "$original_file")

    if [ "$original_height" -ne 0 ]; then
        local new_width=$((desired_height * original_width / original_height))

        convert "$original_file" -strip -quality 75 -resize "${new_width}x${desired_height}" "$preview_file"
        echo "Created preview for $original_file as $preview_file"
    else
        echo "Error: Unable to read image dimensions for $original_file"
    fi
    echo "Preview creation complete."
}

create_subdir_index() {
    local dir_path="$1"
    local subdir_name=$(basename "$dir_path")
    local subdir_html_file="$PICTURES_DIR/${subdir_name}.html"

    write_header "$subdir_html_file" "$subdir_name"

    echo "Adding images to $subdir_html_file..."
    find "$dir_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) | while read file_path; do
        write_img "$file_path" "$subdir_html_file"
        echo "Added image $(basename "$file_path") to $subdir_html_file"
    done

    echo "</body></html>" >> "$subdir_html_file"
    echo "$subdir_html_file created successfully."
}

create_main_index() {
    local pictures_dir="$1"
    local index_file="$2"

    write_header "$index_file" "Main Gallery"
    echo "Started writing to $index_file with a standard HTML header."

    for subdir in "$pictures_dir"/*/; do
        if [ -d "$subdir" ]; then
            local subdir_name=$(basename "$subdir")
            echo "Processing subdirectory: $subdir_name"

            echo "<div class='subdirectory'>" >> "$index_file"
            echo "<h2>$subdir_name</h2>" >> "$index_file"
            echo "<div class='preview-container'>" >> "$index_file"

            local count=0
            while IFS= read -r -d '' file_info && [ "$count" -lt 8 ]; do
                local preview_file="$PREVIEWS_DIR/$(basename "$file_info")"
                create_preview "$file_info" "$preview_file"
                echo "<img src='$preview_file' alt='Preview'>" >> "$index_file"
                ((count++))
                echo "Added preview for $(basename "$file_info") to $index_file"
            done < <(find "$subdir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.avif" \) -print0)

            echo "</div>" >> "$index_file"
            echo "</div>" >> "$index_file"
            echo "Finished processing $subdir_name"
        fi
    done

    echo "</body></html>" >> "$index_file"
    echo "Completed writing to $index_file."
}

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
        echo "Added header with title '$title' to $output_file"
    fi
}

echo "Starting script..."

mkdir -p "$PREVIEWS_DIR"
echo "Verified that the previews directory exists."

INDEX_FILE="$PICTURES_DIR/index.html"
echo "Set INDEX_FILE to $INDEX_FILE"

echo "Creating the main index file..."
create_main_index "$PICTURES_DIR" "$INDEX_FILE"

echo "Script completed successfully."
