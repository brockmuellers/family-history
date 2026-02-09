#!/bin/bash
# Convert md files to pdfs, and append them into one big pdf
# Input argument is the original PDF of unprocessed pages
# Ultimately I'd like a more complex pdf output including original images
# NOTE AND TODO: if multiple models were used, this will grab results from all of them, which is a mess
# But this is a good start
set -euo pipefail
shopt -s nullglob

# CONTROL FLOW hacky hacky these should be args or diff; default all to false for normal flow
SKIP_MD_TO_PDF=true
INTERLEAVE=true
SIDE_BY_SIDE_INTERLEAVE=true


# Path generation all copied from the pre-processing script
PDF_PATH=$(readlink -f "$1")
PDF_DIR=$(dirname "$PDF_PATH")
PDF_NAME=$(basename "${PDF_PATH%.*}") # the filename without extension
TEMP_DIR="${PDF_DIR}/temp_${PDF_NAME}" # working directory

PDF_FONT_SIZE="16px"
PDF_MARGINS="10mm"

# Quick hack - uncomment if I want to process some files that were generated
# using a manual process, but still map to a regular input pdf
# TEMP_DIR="original_letters/temp_manual_chat_processing"
# PDF_NAME="manual_chat_processing"

# Can skip this; e.g. if some were done manually due to formatting problems
if ! [[ $SKIP_MD_TO_PDF == "true" ]]; then
    for file in "$TEMP_DIR"/ocr_*.md; do
        # Made a separate conversion script so I can do one-offs if any need a different font size etc
        bash ./convert-md-to-pdf.sh $file $PDF_FONT_SIZE $PDF_MARGINS
    done
    echo "Converted markdown files to pdf"
else
    echo "Skipping markdown to pdf conversion"
fi

# Unite all pdf files in the temp directory that match the "ocr_*" pattern WHICH COULD BE A PROBLEM
# Output file goes in the parent directory where the original unprocessed PDF is
echo "Uniting pdf files..."
outfile="${PDF_DIR}/ocr_${PDF_NAME}.pdf"
pdfunite "$TEMP_DIR"/ocr_*.pdf $outfile
num_pages=$(pdfinfo $outfile | awk '/^Pages:/ {print $2}')
echo -e "Success! United $num_pages pages.\nSee your results at $outfile"

# Optionally, interleave pages with the original - exit now if we're not doing that
# note to self - weird boolean stuff going on here, why?
if ! [[ $INTERLEAVE == "true" || $SIDE_BY_SIDE_INTERLEAVE == "true" ]]; then
    echo "should exit"
    exit 0
fi

# If PDFs have the same number of pages, it's a loose guarantee that interleaving will be correct
# Hack - if the original PDF needs its pages reordered, put the reordered file path here
#PDF_PATH="path/reordered_letters.pdf"
echo $PDF_PATH
num_pages_original=$(pdfinfo $PDF_PATH | awk '/^Pages:/ {print $2}')
if [[ $num_pages != $num_pages_original ]]; then
    echo "Can't interleave pdfs with different number of pages: $num_pages and $num_pages_original. Exiting."
    exit 1
fi

# We need to do the basic interleave (original p1, ocr p1, original p2, ocr p2, ...)
# either way, since it's an input to the side-by-side function
merged_outfile="${PDF_DIR}/ocr_merged_${PDF_NAME}.pdf"
pdftk A=$PDF_PATH B=$outfile shuffle B A output $merged_outfile # change order by swapping A/B
echo "Successfully interleaved OCR with original"

if ! [[ $SIDE_BY_SIDE_INTERLEAVE == "true" ]]; then
    exit 0
fi

# Make a side-by-side version of the interleaved PDF
# suppressing stdout because it's verbose
pdfjam --nup 2x1 --landscape $merged_outfile --outfile "${PDF_DIR}/ocr_side_by_side_${PDF_NAME}.pdf" &> /dev/null
echo "Successfully generated side-by-side PDF"
