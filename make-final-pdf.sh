#!/bin/bash
# Convert md files to pdfs, and append them into one big pdf
# Input argument is the original PDF of unprocessed pages
# Ultimately I'd like a more complex pdf output including original images
# But this is a good start
set -euo pipefail

# All copied from the pre-processing script
PDF_PATH=$(readlink -f "$1")
PDF_DIR=$(dirname "$PDF_PATH")
PDF_NAME=$(basename "${PDF_PATH%.*}") # the filename without extension
TEMP_DIR="${PDF_DIR}/temp_${PDF_NAME}" # working directory

# Quick hack - uncomment if I want to process some files that were generated
# using a manual process, but still map to a regular input pdf
# TEMP_DIR="original_letters/temp_manual_chat_processing"
# PDF_NAME="manual_chat_processing"

for file in "$TEMP_DIR"/ocr_*.md; do
    echo "Converting ${file} to pdf..."
    md-to-pdf "$file"
done
echo "Converted markdown files to pdf"

# Unite all pdf files in the temp directory that match the "ocr_*" pattern
# Output file goes in the parent directory where the original unprocessed PDF is
echo "Uniting pdf files..."
outfile="${PDF_DIR}/ocr_${PDF_NAME}.pdf"
pdfunite "$TEMP_DIR"/ocr_*.pdf $outfile
echo "Success! See your results at $outfile"
