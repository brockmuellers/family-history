#!/bin/bash
# Convert md files to pdf
set -euo pipefail
shopt -s nullglob

# $1 is the first argument (required)
MARKDOWN_FILE=$1
PDF_FONT_SIZE=$2 # e.g. 16px
PDF_MARGINS=$3 # 10mm is a good bet

#echo "Converting ${MARKDOWN_FILE} to pdf..."
# suppressing stdout
md-to-pdf "$MARKDOWN_FILE" --css "@page { margin: $PDF_MARGINS; } body { font-size: $PDF_FONT_SIZE; }" > /dev/null

# for the sake of catching errors early, print the number of pages that were generated
new_filename="${MARKDOWN_FILE%.*}.pdf"
pages=$(pdfinfo $new_filename | awk '/^Pages:/ {print $2}')
echo "Generated $pages page file: $new_filename"
