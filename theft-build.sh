#!/bin/sh

#not really a header, it's just the begining of the page.
write_header(){
  echo "<!DOCTYPE html>
<html lang=\"en\">

<head>
  <meta charset=\"utf-8\">
  <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">
  <title>Gruvbox wallpapers</title>
</head>

<body>
  <h1>Wallpapers for gruvbox</h1>" > $1
}

write_section_header(){
  echo "<h2 id=s"$1">" >> $3
  echo "$2" | tr a-z A-Z  >> $3
  echo "</h2>" >> $3
}

write_img(){
  echo "  <a target=\"_blank\" href=\"$1\">
<img loading=\"lazy\" src=\"$1\" alt="$1" width=\"200\"></a>" >> $2
}

#not really a footer, it's just the end of the page.
write_footer(){
      echo "<p> Contributions!! <a href=\"https://github.com/AngelJumbo/gruvbox-wallpapers\">here</a>.</p>
</body>
</html>" >> $1

}

#create index file
touch ./index.html

#write the begining of the index file
write_header ./index.html

#color of the section headers
#there are 7 colors and these are defined in the style.css
#with the ids: s1, s2 .... s7
color=1

for subdir in ./wallpapers/*
do
  #for each folder in the wallpapers directory we first write a section header
  write_section_header $color "${subdir##*/}" ./index.html

  echo "<div id=c>" >> ./index.html

  count=1;

# Loop through each folder in the current directory
for subdir in ./*; do
    # Skip if it's not a directory or if it's the wallpapers directory
    if [ ! -d "$subdir" ] || [ "${subdir##*/}" = "wallpapers" ]; then
        continue
    fi

    # Write a section header for each folder
    write_section_header "$color" "${subdir##*/}" ./index.html
    echo "<div id=c>" >> ./index.html

    count=1

    # Find and handle each image file in the directory
    while IFS= read -r -d '' wallpaper; do
        # Write each image to the index file, limit to 8 per section
        if [ "$count" -lt 9 ]; then
            write_img "$wallpaper" ./index.html
            count=$((count+1))
        else
            # Create a new HTML file for the rest of the images
            subhtml="${subdir##*/}.html"
            nimgs=$(find "$subdir" -maxdepth 1 -type f | wc -l)

            # Make a link to the new page and create it
            echo "  <a target=\"_blank\" class=\"showmore\" href=\"${subhtml}\">
            <div class=\"showmore\">show all ${nimgs} ${subdir##*/} wallpapers </div></a>" >> ./index.html

            touch "$subhtml"
            write_header "$subhtml"
            write_section_header "$color" "${subdir##*/}" "$subhtml"
            echo "<div id=c>" >> "$subhtml"

            # Write all the images to the new page
            find "$subdir" -maxdepth 1 -type f | while IFS= read -r wallpaper2; do
                write_img "$wallpaper2" "$subhtml"
            done

            echo "</div>" >> "$subhtml"
            write_footer "$subhtml"

            # Break from the loop after creating the additional page
            break
        fi
    done < <(find "$subdir" -maxdepth 1 -type f -print0)

    echo "</div>" >> ./index.html

    # Update the color for the next section
    color=$((color+1))
    if [ "$color" -eq 8 ]; then
        color=1
    fi
done

write_footer ./index.html


  echo "</div>" >> ./index.html

  color=$((color+1))
  #there are only 7 colors, if there are more than 7 folders in the wallpapers folder
  #then repeat the colors
  if [ "$color" -eq 8 ]; then
    color=1
  fi
done

write_footer ./index.html
