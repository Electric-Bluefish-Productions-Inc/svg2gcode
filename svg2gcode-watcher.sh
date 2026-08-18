#!/bin/sh

# SVG to G-code Converter Watcher
# Monitors a directory for SVG files and automatically converts them to G-code
#
# Usage: ./svg2gcode-watcher.sh [watch_dir] [poll_interval]
#
# Environment variables:
#   FEEDRATE: Machine feed rate (mm/min) - default 1000
#   TOLERANCE: Curve interpolation tolerance (mm) - default 0.5
#   DPI: Dots per Inch for scaling - default 96
#   LOG_LEVEL: Logging verbosity - default INFO

# Configuration from environment or defaults
WATCH_DIR="${1:-.}"
POLL_INTERVAL="${2:-2}"
FEEDRATE="${FEEDRATE:-1000}"
TOLERANCE="${TOLERANCE:-0.5}"
DPI="${DPI:-96}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Ensure watch directory exists
mkdir -p "$WATCH_DIR"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] SVG to G-code Watcher started"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Watch directory: $WATCH_DIR"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Poll interval: ${POLL_INTERVAL}s"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Settings: feedrate=${FEEDRATE}, tolerance=${TOLERANCE}, dpi=${DPI}"

# Track processed files (simple space-separated list for sh compatibility)
processed_files=""

while true; do
    # Find all SVG files in watch directory
    find "$WATCH_DIR" -maxdepth 1 \( -name "*.svg" -o -name "*.SVG" \) | while read -r svg_file; do
        # Skip if file doesn't exist
        [ -f "$svg_file" ] || continue

        # Skip if already processed (check if in processed_files list)
        case " $processed_files " in
            *" $svg_file "*)
                continue
                ;;
        esac

        # Skip if file is locked (still being written)
        if ! lsof "$svg_file" 2>/dev/null | grep -q . 2>/dev/null; then
            # File exists and is not open - mark as processed
            processed_files="$processed_files $svg_file"

            filename=$(basename "$svg_file")
            gcode_file="${svg_file%.*}.gcode"
            gcode_filename=$(basename "$gcode_file")

            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Converting: $filename"

            # Call svg2gcode-cli with configured parameters
            if svg2gcode-cli "$svg_file" \
                --feedrate "$FEEDRATE" \
                --tolerance "$TOLERANCE" \
                --dpi "$DPI" \
                -o "$gcode_file" 2>&1; then

                echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✓ Generated: $gcode_filename"
            else
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✗ Failed to convert: $filename" >&2
            fi
        fi
    done

    # Sleep before next poll
    sleep "$POLL_INTERVAL"
done
