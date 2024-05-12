Sure, here's a README file for the `convio` tool on GitHub:

```markdown
# Convio

Convio is a powerful batch file conversion tool that allows you to convert various types of files, including images, videos, audio, documents, and compressed files. It supports recursive conversions for folders and provides options for asynchronous compression using fork or threads for improved performance.

## Features

- Convert multiple file types:
  - Images (JPG, PNG, GIF)
  - Videos (MP4)
  - Audio (MP3, WAV, FLAC)
  - Documents (PDF, DOC, DOCX, PPT, PPTX)
  - Compression (XZ)
- Recursive conversion for folders
- Asynchronous compression using fork or threads for faster processing
- Easy command-line interface

## Installation

1. Clone the repository:

   ```bash
   git clone 
   ```

2. Navigate to the project directory:

   ```bash
   cd convio
   ```

3. Make the script executable:

   ```bash
   chmod +x convio.sh
   ```

## Usage

```
convio - Batch file conversion tool
Usage: convio [OPTIONS] SOURCE_DIR
Options:
  -h        Show help
  -c TYPE   Conversion type (image, video, audio, document, compress)
  -o FORMAT Output format for conversions (e.g., mp4, jpg, pdf)
  -r        Recursive conversion (for folders)
  -f        Use fork for asynchronous compression
  -t        Use threads for asynchronous compression
```

Example:

```bash
./convio.sh -c compress -o xz -r /path/to/source/directory
```

This command will compress all files in the `/path/to/source/directory` and its subdirectories recursively, using the XZ compression format. The compressed files will be saved in a new `compressed_files` directory within the source directory.

## Dependencies

Convio relies on the following tools for file conversions:

- `ffmpeg` (for video conversions)
- `imagemagick` (for image conversions)
- `xz` (for compression)

These tools will be automatically installed if not present on your system.
