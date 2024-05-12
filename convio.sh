#!/bin/bash

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Function to display help
show_help() {
    echo "convio - Batch file conversion tool"
    echo "Usage: convio [OPTIONS] SOURCE_DIR"
    echo "Options:"
    echo "  -h        Show help"
    echo "  -c TYPE   Conversion type (image, video, audio, document, compress)"
    echo "  -o FORMAT Output format for conversions (e.g., mp4, jpg, pdf)"
    echo "  -r        Recursive conversion (for folders)"
}

# Function to install conversion tools
install_tools() {
    local tools=("$@")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${GREEN}Installing $tool...${NC}"
            sudo apt-get install -y "$tool"
        fi
    done
}

# Function to compress files (video, images, and others)
compress_files() {
    local source_dir="$1"
    local output_format="$2"
    local recursive="$3"
    local output_dir="$source_dir/compressed_files"
    install_tools "ffmpeg" "imagemagick" "xz"
    mkdir -p "$output_dir"
    start_time=$(date +%s)

    # Recursive function to compress files
    compress_recursive() {
        local dir="$1"
        local output_subdir="$2"
        for entry in "$dir"/*; do
            if [ -d "$entry" ]; then
                local subdir="$output_subdir/${entry##*/}"
                mkdir -p "$subdir"
                compress_recursive "$entry" "$subdir"
            elif [ -f "$entry" ]; then
                local filename="${entry##*/}"
                local extension="${filename##*.}"
                case "$extension" in
                mp4)
                    ffmpeg -i "$entry" -c:v libx264 -crf 23 "$output_subdir/$filename"
                    ;;
                jpg | png | gif)
                    convert "$entry" "$output_subdir/$filename.$output_format"
                    ;;
                *)
                    xz -k -z "$entry" -c >"$output_subdir/$filename.xz"
                    ;;
                esac
            fi
        done
    }

    if [ "$recursive" == "true" ]; then
        compress_recursive "$source_dir" "$output_dir"
    else
        for file in "$source_dir"/*; do
            compress_recursive "$file" "$output_dir"
        done
    fi

    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    echo -e "${GREEN}Compression completed in $execution_time seconds${NC}"
}

# Process command-line arguments
while getopts ":hc:o:r" opt; do
    case $opt in
    h)
        show_help
        exit 0
        ;;
    c) convert_type="$OPTARG" ;;
    o) output_format="$OPTARG" ;;
    r) recursive="true" ;;
    \?)
        echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
        show_help
        exit 1
        ;;
    :)
        echo -e "${RED}Option -$OPTARG requires an argument${NC}" >&2
        show_help
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

# Check if source directory is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Source directory is missing${NC}" >&2
    show_help
    exit 1
fi
source_dir="$1"

# Execute the compression
case "$convert_type" in
compress)
    compress_files "$source_dir" "$output_format" "$recursive"
    ;;
*)
    echo -e "${RED}Error: Invalid conversion type${NC}" >&2
    show_help
    exit 1
    ;;
esac
