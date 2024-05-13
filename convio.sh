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
    echo " -f       Use fork for parallel processing"
    echo "  -o FORMAT Output format for conversions (e.g., mp4, jpg, pdf)"
    echo "  -r        Recursive conversion (for folders)"
    echo " -s use subshell to run conversion"
}

# Function to install conversion tools
install_tools() {
    local tools=("$@")
    for tool in "${tools[@]}"; do
        if [ "$tool" == "imagemagick" ]; then
            if ! command -v convert &>/dev/null; then
                echo -e "${GREEN}Installing $tool...${NC}"
                sudo apt-get install -y "$tool"
            fi
        else
            if ! command -v "$tool" &>/dev/null; then
                echo -e "${GREEN}Installing $tool...${NC}"
                sudo apt-get install -y "$tool"
            fi
        fi
    done
}

if [ "$use_fork" == "true" ] || [ "$use_subshell" == "true" ]; then
    install_tools "ffmpeg" "imagemagick" "unoconv" "xz"
fi
# Function to compress files (video, images, and others)
compress_files() {
    local source_dir="$1"
    local output_format="$2"
    local recursive="$3"
    local output_dir="$source_dir/compressed_files"
    mkdir -p "$output_dir"
    local start_time end_time execution_time
    local max_processes=10
    local running_processes=0

    start_time=$(date +%s)
    calculate_process() {
        ((running_processes++))
        if [ $running_processes -ge $max_processes ]; then
            wait
            running_processes=0
        fi
    }
    # Function to process individual files
    process_file() {
        local input="$1"
        local output_dir="$2"
        local filename="${input##*/}"
        local extension="${filename##*.}"
        local output_file="$output_dir/$filename"

        if [ -d "$input" ]; then
            return # Skip directories
        fi
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
        mp3 | wav | flac)
            install_tools "ffmpeg"
            ffmpeg -i "$input" -ar 16000 -b:a 32000 -ac 1 "$output_file"
            ;;
        *)
            echo "Unsupported file format: $input" >&2
            ;;
        esac
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
                if [ "$use_fork" == "true" ]; then
                    process_file "$file" "$output_dir" &
                    calculate_process

                elif [ "$use_subshell" == "true" ]; then
                    (
                        process_file "$file" "$output_dir"
                    )
                else
                    process_file "$file" "$output_dir"
                fi

            fi
        done
    }

    # Main compression logic
    if [ "$recursive" == "true" ]; then
        compress_recursive "$source_dir" "$output_dir"
    else
        for file in "$source_dir"/*; do
            if [ "$use_fork" == "true" ]; then
                process_file "$file" "$output_dir" &
                calculate_process
            elif [ "$use_subshell" == "true" ]; then
                (
                    process_file "$file" "$output_dir"
                )
            else
                process_file "$file" "$output_dir"

            fi
        done
    fi
    if [ "$use_fork" == "true" ]; then
        wait
    fi
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    echo -e "${GREEN}Compression completed in $execution_time seconds${NC}"
}
# Process command-line arguments
use_fork="false"
use_subshell="false"
while getopts ":hc:o:r:fs" opt; do
    case $opt in
    h)
        show_help
        exit 0
        ;;
    c) convert_type="$OPTARG" ;;
    o) output_format="$OPTARG" ;;
    r) recursive="true" ;;
    f) use_fork="true" ;;
    s) use_subshell="true" ;;

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
