#!/bin/bash

# Check if target path is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <target_path>"
    exit 1
fi

TARGET_PATH="$1"

# Convert size string to bytes
convert_size_to_bytes() {
    local size="$1"
    local number=$(echo "$size" | sed -E 's/[^0-9.]//g')
    local unit=$(echo "$size" | sed -E 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')

    case "$unit" in
        B) echo $(printf "%.0f" "$number") ;;
        KB) echo $(printf "%.0f" "$(echo "$number * 1024" | bc)") ;;
        MB) echo $(printf "%.0f" "$(echo "$number * 1024 * 1024" | bc)") ;;
        GB) echo $(printf "%.0f" "$(echo "$number * 1024 * 1024 * 1024" | bc)") ;;
        TB) echo $(printf "%.0f" "$(echo "$number * 1024 * 1024 * 1024 * 1024" | bc)") ;;
        *)
            echo "Invalid size unit. Please use B, KB, MB, GB, or TB" >&2
            exit 1
            ;;
    esac
}

# Format bytes to human-readable size
format_size() {
    local bytes="$1"

    # Convert scientific notation to normal number
    bytes=$(printf "%.0f" "$bytes" 2>/dev/null || echo "$bytes")

    if (( $(echo "$bytes >= 1099511627776" | bc -l) )); then # 1TB
        printf "%.2f TB" $(echo "scale=2; $bytes / 1024 / 1024 / 1024 / 1024" | bc -l)
    elif (( $(echo "$bytes >= 1073741824" | bc -l) )); then # 1GB
        printf "%.2f GB" $(echo "scale=2; $bytes / 1024 / 1024 / 1024" | bc -l)
    elif (( $(echo "$bytes >= 1048576" | bc -l) )); then # 1MB
        printf "%.2f MB" $(echo "scale=2; $bytes / 1024 / 1024" | bc -l)
    elif (( $(echo "$bytes >= 1024" | bc -l) )); then # 1KB
        printf "%.2f KB" $(echo "scale=2; $bytes / 1024" | bc -l)
    else
        echo "$bytes B"
    fi
}

# Check if path exists
if [ ! -d "$TARGET_PATH" ]; then
    echo "The specified path does not exist or is not a folder: $TARGET_PATH" >&2
    exit 1
fi

# Interactive threshold input
echo -e "\nPlease enter the size threshold for large folders"
echo "Supported formats: B, KB, MB, GB, TB (example: 1GB, 500MB, 2TB)"
echo "Press Enter to use the default value 1GB"
read -p "Threshold size: " threshold_input

# Set default value
if [ -z "$threshold_input" ]; then
    threshold_input="1GB"
    echo "Using default threshold: 1GB"
fi

# Convert threshold
threshold_bytes=$(convert_size_to_bytes "$threshold_input")
if [ $? -ne 0 ]; then
    echo "Invalid threshold format: $threshold_input"
    echo -e "\nSupported format examples:"
    echo "1GB  - 1 gigabyte"
    echo "500MB - 500 megabytes"
    echo "2TB   - 2 terabytes"
    exit 1
fi

echo -e "\nStarting directory scan: $TARGET_PATH"
echo "Scan time: $(date +'%Y-%m-%d %H:%M:%S')"
echo "Size threshold: $(format_size "$threshold_bytes")"
echo

# Get folder size
get_folder_size() {
    local path="$1"
    local size=$(find "$path" -type f -print0 2>/dev/null | xargs -0 stat -c "%s" 2>/dev/null | awk '{total += $1} END {print total}')
    echo "${size:-0}"  # Return 0 if size is empty
}

# Check if path is a symbolic link
is_symbolic_link() {
    [ -L "$1" ]
}

# Get symbolic link target
get_symbolic_link_target() {
    readlink -f "$1"
}

# Find all directories and their sizes
scan_directories() {
    local base_path="$1"
    local threshold="$2"

    # Count directories for progress reporting
    echo "Counting directories..."
    local total_folders=$(find "$base_path" -type d 2>/dev/null | wc -l)
    echo "Found $total_folders directories to scan"

    # Find all directories
    echo -e "\nScanning directories for size...\n"

    # Create temporary file for results
    temp_file=$(mktemp)

    find "$base_path" -type d -print0 2>/dev/null | while IFS= read -r -d $'\0' folder; do
        # Calculate depth
        depth=$(echo "$folder" | sed "s|$base_path||" | tr -cd '/' | wc -c)

        # Get size
        size=$(get_folder_size "$folder")

        # Check if it's a symbolic link
        if is_symbolic_link "$folder"; then
            link_target=$(get_symbolic_link_target "$folder")
            is_link=1
        else
            link_target=""
            is_link=0
        fi

        # If size exceeds threshold, record it
        if (( $(echo "$size > $threshold" | bc -l) )); then
            size_display=$(format_size "$size")

            # Print immediately
            link_info=""
            if [ "$is_link" -eq 1 ]; then
                link_info=" [Symbolic link → $link_target]"
            fi
            echo "Found large folder: $folder → $size_display (depth: $depth)$link_info"

            # Record for summary
            echo "$folder|$size_display|$depth|$is_link|$link_target" >> "$temp_file"
        fi

        echo -ne "Processing...\r"
    done

    echo -e "\nScan completed."
    echo -e "\nScan statistics:"
    echo "Total folders scanned: $total_folders"

    # Calculate max depth
    max_depth=$(cat "$temp_file" 2>/dev/null | cut -d'|' -f3 | sort -nr | head -n1)
    if [ -z "$max_depth" ]; then max_depth=0; fi
    echo "Maximum depth: $max_depth"

    # Print summary of large folders
    echo -e "\nLarge folders summary:"
    echo "------------------------------------------------------------------------------------------------------"
    printf "%-60s %-10s %-6s %-30s\n" "Path" "Size" "Depth" "Type"
    echo "------------------------------------------------------------------------------------------------------"

    if [ -s "$temp_file" ]; then
        # Sort by depth descending
        sort -t'|' -k3 -nr "$temp_file" | while IFS='|' read -r path size depth is_link link_target; do
            folder_type="Regular folder"
            if [ "$is_link" -eq 1 ]; then
                folder_type="Symbolic link → $link_target"
            fi
            printf "%-60s %-10s %-6s %-30s\n" "$path" "$size" "$depth" "$folder_type"
        done
    else
        echo "No folders found exceeding the threshold."
    fi

    # Clean up
    rm -f "$temp_file"
}

# Start scanning
scan_directories "$TARGET_PATH" "$threshold_bytes"