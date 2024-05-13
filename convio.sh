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
    echo "  -l LOG    Directory to store the log file"
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
    mkdir -p "$output_dir"
    local start_time end_time execution_time
    local log_file="$log_dir/convio.log"

    start_time=$(date +%s)

    # Function to process individual files
    process_file() {
        local input="$1"
        local output_dir="$2"
        local filename="${input##*/}"
        local extension="${filename##*.}"
        local output_file="$output_dir/$filename"
        local metadata_file="$log_dir/$filename.metadata"

        case "$extension" in
        mp4)
            install_tools "ffmpeg"
            ffmpeg -i "$input" -c:v libx264 -crf 23 "$output_file"
            ;;
        jpg | png | gif)
            install_tools "imagemagick"
            convert "$input" -quality 60 "$output_file"
            ;;
        pdf | doc | docx | xls | xlsx | ppt | pptx)
            install_tools "unoconv"
            unoconv -f pdf -o "$output_dir" "$input"
            ;;
        *)
            echo "Unsupported file format: $input" >&2
            ;;
        esac

        # Capture file metadata
        file_metadata=$(ffprobe -v quiet -print_format json -show_format "$output_file")
    }

    # Function to process directories recursively
    compress_recursive() {
        local source_dir="$1"
        local output_dir="$2"
        echo -e "${GREEN}Processing $source_dir...${NC}"
        for file in "$source_dir"/*; do
            if [ -d "$file" ]; then
                local sub_dir="$output_dir/${file##*/}"
                if [ "${file##*/}" != "compressed_files" ]; then
                    mkdir -p "$sub_dir"
                    compress_recursive "$file" "$sub_dir"
                fi
            else
                process_file "$file" "$output_dir" &
            fi
        done
    }

    # Main compression logic
    if [ "$recursive" == "true" ]; then
        compress_recursive "$source_dir" "$output_dir"
    else
        for file in "$source_dir"/*; do
            process_file "$file" "$output_dir"
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
    l) log_dir="$OPTARG" ;;
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
