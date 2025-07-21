#!/bin/bash

# Organize package files by OS version and architecture
# This script organizes packages in /run/media/sgallego/ by OS and architecture

set -euo pipefail

# Configuration
SCAN_DIR="/run/media/$USER"
# Auto-detect available devices or use specific device
DEVICE_ID="${1:-}"  # First argument can specify device ID
if [ -z "$DEVICE_ID" ]; then
    # Try to auto-detect the first available device
    if [ -d "$SCAN_DIR" ]; then
        DEVICE_ID=$(ls -1 "$SCAN_DIR" 2>/dev/null | head -1)
    fi
fi

BASE_DIR="/run/media/$USER/$DEVICE_ID"
ORGANIZE_DIR="$BASE_DIR/OS"
LOG_FILE="$HOME/organize_packages.log"
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to detect RPM OS version
detect_rpm_os() {
    local rpm_file="$1"
    local filename=$(basename "$rpm_file")
    
    # Check for Fedora Core versions (fc30-fc44)
    if [[ "$filename" =~ \.fc([3-4][0-9])\.([^.]+)\.rpm$ ]]; then
        local fc_version="${BASH_REMATCH[1]}"
        local arch="${BASH_REMATCH[2]}"
        echo "Fedora_${fc_version}/${arch}"
        return 0
    fi
    
    # Check for RHEL/CentOS versions
    if [[ "$filename" =~ \.el([5-9])\.([^.]+)\.rpm$ ]]; then
        local el_version="${BASH_REMATCH[1]}"
        local arch="${BASH_REMATCH[2]}"
        echo "RHEL_${el_version}/${arch}"
        return 0
    fi
    
    # Check for openSUSE
    if [[ "$filename" =~ \.(suse|opensuse)\.([^.]+)\.rpm$ ]]; then
        local arch="${BASH_REMATCH[2]}"
        echo "openSUSE/${arch}"
        return 0
    fi
    
    # Generic RPM with architecture
    if [[ "$filename" =~ \.([^.]+)\.rpm$ ]]; then
        local arch="${BASH_REMATCH[1]}"
        case "$arch" in
            x86_64|i386|i686|noarch|aarch64|armv7hl|ppc64le|s390x)
                echo "Generic_RPM/${arch}"
                ;;
            *)
                echo "Generic_RPM/unknown"
                ;;
        esac
        return 0
    fi
    
    echo "Generic_RPM/unknown"
}

# Function to detect DEB architecture
detect_deb_arch() {
    local deb_file="$1"
    local filename=$(basename "$deb_file")
    
    # Extract architecture from filename
    if [[ "$filename" =~ _([^_]+)\.deb$ ]]; then
        local arch="${BASH_REMATCH[1]}"
        case "$arch" in
            amd64|i386|arm64|armhf|armel|all|source)
                echo "Debian/${arch}"
                ;;
            *)
                echo "Debian/unknown"
                ;;
        esac
    else
        echo "Debian/unknown"
    fi
}

# Function to organize files
organize_files() {
    local source_dir="$1"
    local file_count=0
    local organized_count=0
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory $source_dir does not exist${NC}"
        return 1
    fi
    
    log "${BLUE}Scanning $source_dir for package files...${NC}"
    
    # Find all package files
    while IFS= read -r -d '' file; do
        ((file_count++))
        
        # Progress reporting every 1000 files
        if (( file_count % 1000 == 0 )); then
            log "${BLUE}Progress: Found $file_count package files so far...${NC}"
        fi
        
        local filename=$(basename "$file")
        local relative_path=$(dirname "${file#$source_dir/}")
        
        # Skip files already in the TARGET organized directory (not parent organized directories)
        if [[ "$file" =~ /OS/ ]]; then
            continue
        fi
        
        local target_dir=""
        
        # Determine target directory based on file type
        case "$filename" in
            *.rpm)
                local rpm_path=$(detect_rpm_os "$file")
                target_dir="$ORGANIZE_DIR/RPM/$rpm_path"
                ;;
            *.deb)
                local deb_path=$(detect_deb_arch "$file")
                target_dir="$ORGANIZE_DIR/DEB/$deb_path"
                ;;
            *.msi|*.exe)
                target_dir="$ORGANIZE_DIR/MSI/Windows"
                ;;
            *.flatpak)
                target_dir="$ORGANIZE_DIR/Flatpak"
                ;;
            *.snap)
                target_dir="$ORGANIZE_DIR/Snap"
                ;;
            *.AppImage)
                target_dir="$ORGANIZE_DIR/AppImage"
                ;;
            comps.xml)
                target_dir="$ORGANIZE_DIR/RPM/comps_files"
                ;;
            *)
                continue
                ;;
        esac
        
        if [ -n "$target_dir" ]; then
            if [ "$DRY_RUN" = true ]; then
                log "${YELLOW}[DRY RUN] Would move: $file -> $target_dir/${NC}"
            else
                # Create target directory
                if ! mkdir -p "$target_dir" 2>/dev/null; then
                    log "${RED}Failed to create directory: $target_dir${NC}"
                    continue
                fi
                
                # Move file
                if mv "$file" "$target_dir/" 2>/dev/null; then
                    log "${GREEN}Moved: $filename -> $target_dir/${NC}"
                    ((organized_count++))
                else
                    log "${RED}Failed to move: $file${NC}"
                fi
            fi
        fi
    done < <(find "$source_dir" -type f \( -name "*.rpm" -o -name "*.deb" -o -name "*.msi" -o -name "*.exe" -o -name "*.flatpak" -o -name "*.snap" -o -name "*.AppImage" -o -name "comps.xml" \) -print0)
    
    log "${BLUE}Scan complete. Found $file_count package files, organized $organized_count files.${NC}"
}

# Function to clean up empty directories
cleanup_empty_dirs() {
    local scan_dir="$1"
    
    log "${BLUE}Cleaning up empty directories in $scan_dir...${NC}"
    
    # Find and remove empty directories (excluding organized structure)
    # Run multiple passes to handle nested empty directories
    local removed_count=0
    local pass=1
    
    while true; do
        log "${BLUE}Empty directory cleanup pass $pass...${NC}"
        local dirs_removed_this_pass=0
        
        # Find empty directories, excluding the organized package structure
        while IFS= read -r -d '' dir; do
            # Skip if it's part of our organized structure
            local dir_basename=$(basename "$dir")
            local parent_dir=$(dirname "$dir")
            local parent_basename=$(basename "$parent_dir")
            
            # Skip organized directories but allow cleanup within them
            if [[ "$parent_basename" == "RPM" || "$parent_basename" == "DEB" || "$parent_basename" == "MSI" || 
                  "$parent_basename" == "Flatpak" || "$parent_basename" == "Snap" || "$parent_basename" == "AppImage" ]]; then
                continue
            fi
            
            # Skip the main organized directories themselves and OS directory
            if [[ "$dir_basename" == "RPM" || "$dir_basename" == "DEB" || "$dir_basename" == "MSI" || 
                  "$dir_basename" == "Flatpak" || "$dir_basename" == "Snap" || "$dir_basename" == "AppImage" || 
                  "$dir_basename" == "OS" ]]; then
                continue
            fi
            
            # Skip if it's inside the OS directory
            if [[ "$dir" =~ /OS/ ]]; then
                continue
            fi
            
            if [ "$DRY_RUN" = true ]; then
                log "${YELLOW}[DRY RUN] Would remove empty directory: $dir${NC}"
                ((dirs_removed_this_pass++))
            else
                if rmdir "$dir" 2>/dev/null; then
                    log "${GREEN}Removed empty directory: $dir${NC}"
                    ((dirs_removed_this_pass++))
                    ((removed_count++))
                fi
            fi
        done < <(find "$scan_dir" -type d -empty -print0 2>/dev/null)
        
        # If no directories were removed this pass, we're done
        if [ "$dirs_removed_this_pass" -eq 0 ]; then
            break
        fi
        
        ((pass++))
        
        # Safety limit to prevent infinite loops
        if [ "$pass" -gt 10 ]; then
            log "${YELLOW}Reached maximum cleanup passes (10), stopping.${NC}"
            break
        fi
    done
    
    if [ "$DRY_RUN" = false ]; then
        log "${GREEN}Cleanup complete. Removed $removed_count empty directories.${NC}"
    fi
}

# Function to migrate large collections efficiently
migrate_large_collections() {
    log "${BLUE}=== Large Collection Migration Mode ===${NC}"
    log "${YELLOW}This mode is optimized for collections with 100k+ files${NC}"
    
    # Count total files to process
    local total_files=0
    for dir in "$SCAN_DIR"/*; do
        if [ -d "$dir" ] && [[ ! "$dir" =~ /OS$ ]] && [[ "$dir" != "$BASE_DIR" ]]; then
            local dir_files=$(find "$dir" -type f \( -name "*.rpm" -o -name "*.deb" -o -name "*.msi" -o -name "*.exe" -o -name "*.flatpak" -o -name "*.snap" -o -name "*.AppImage" \) 2>/dev/null | wc -l)
            if [ "$dir_files" -gt 0 ]; then
                log "${BLUE}Found $dir_files package files in $(basename "$dir")${NC}"
                ((total_files += dir_files))
            fi
        fi
    done
    
    log "${YELLOW}Total files to migrate: $total_files${NC}"
    
    if [ "$total_files" -eq 0 ]; then
        log "${GREEN}No files to migrate!${NC}"
        return 0
    fi
    
    read -p "Continue with migration? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "${YELLOW}Migration cancelled by user${NC}"
        return 0
    fi
    
    # Migrate organized directories first
    log "${BLUE}=== Phase 1: Migrating organized directories ===${NC}"
    for pkg_dir in RPM DEB MSI AppImage; do
        local source_dir="$SCAN_DIR/$pkg_dir"
        if [ -d "$source_dir" ]; then
            local file_count=$(find "$source_dir" -type f 2>/dev/null | wc -l)
            if [ "$file_count" -gt 0 ]; then
                log "${BLUE}Migrating $file_count files from $pkg_dir directory${NC}"
                
                # Create target and copy structure
                mkdir -p "$ORGANIZE_DIR/$pkg_dir"
                if cp -r "$source_dir"/* "$ORGANIZE_DIR/$pkg_dir/" 2>/dev/null; then
                    # Verify copy before removing source
                    local target_count=$(find "$ORGANIZE_DIR/$pkg_dir" -type f 2>/dev/null | wc -l)
                    if [ "$target_count" -ge "$file_count" ]; then
                        rm -rf "$source_dir"
                        log "${GREEN}Successfully migrated $file_count files from $pkg_dir${NC}"
                    else
                        log "${RED}Copy verification failed for $pkg_dir${NC}"
                    fi
                else
                    log "${RED}Failed to migrate $pkg_dir directory${NC}"
                fi
            fi
        fi
    done
    
    # Migrate from individual devices
    log "${BLUE}=== Phase 2: Migrating from devices ===${NC}"
    for device_path in "$SCAN_DIR"/*; do
        if [ -d "$device_path" ] && [[ ! "$(basename "$device_path")" =~ ^(RPM|DEB|MSI|AppImage)$ ]] && [[ "$device_path" != "$BASE_DIR" ]]; then
            local device_name=$(basename "$device_path")
            log "${BLUE}Processing device: $device_name${NC}"
            
            # Process different file types in batches
            local organized_count=0
            
            # RPM files
            while IFS= read -r -d '' rpm_file; do
                local filename=$(basename "$rpm_file")
                local rpm_path=$(detect_rpm_os "$rpm_file")
                local target_dir="$ORGANIZE_DIR/RPM/$rpm_path"
                
                mkdir -p "$target_dir"
                if mv "$rpm_file" "$target_dir/" 2>/dev/null; then
                    ((organized_count++))
                    if (( organized_count % 100 == 0 )); then
                        log "${GREEN}Migrated $organized_count files from $device_name${NC}"
                    fi
                fi
            done < <(find "$device_path" -name "*.rpm" -type f -not -path "*/OS/*" -print0 2>/dev/null)
            
            # EXE/MSI files
            while IFS= read -r -d '' exe_file; do
                local target_dir="$ORGANIZE_DIR/MSI/Windows"
                mkdir -p "$target_dir"
                if mv "$exe_file" "$target_dir/" 2>/dev/null; then
                    ((organized_count++))
                fi
            done < <(find "$device_path" \( -name "*.exe" -o -name "*.msi" \) -type f -not -path "*/OS/*" -print0 2>/dev/null)
            
            # Other package types
            for ext in deb flatpak snap AppImage; do
                while IFS= read -r -d '' pkg_file; do
                    local target_dir="$ORGANIZE_DIR/${ext^}"
                    if [ "$ext" = "deb" ]; then
                        local deb_path=$(detect_deb_arch "$pkg_file")
                        target_dir="$ORGANIZE_DIR/DEB/$deb_path"
                    fi
                    
                    mkdir -p "$target_dir"
                    if mv "$pkg_file" "$target_dir/" 2>/dev/null; then
                        ((organized_count++))
                    fi
                done < <(find "$device_path" -name "*.$ext" -type f -not -path "*/OS/*" -print0 2>/dev/null)
            done
            
            if [ "$organized_count" -gt 0 ]; then
                log "${GREEN}Completed migration of $organized_count files from $device_name${NC}"
            fi
        fi
    done
    
    log "${GREEN}Large collection migration completed!${NC}"
}

# Function to display summary
display_summary() {
    local scan_dir="$1"
    
    log "${BLUE}Organization Summary:${NC}"
    log "${BLUE}Scanned: $scan_dir${NC}"
    log "${BLUE}Organized into: $ORGANIZE_DIR${NC}"
    echo
    
    for package_type in RPM DEB MSI Flatpak Snap AppImage; do
        local type_dir="$ORGANIZE_DIR/$package_type"
        if [ -d "$type_dir" ]; then
            local count=$(find "$type_dir" -type f | wc -l)
            log "${GREEN}$package_type: $count files${NC}"
            
            # Show subdirectory breakdown for RPM and DEB
            if [ "$package_type" = "RPM" ] || [ "$package_type" = "DEB" ]; then
                find "$type_dir" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | while read -r subdir; do
                    local subcount=$(find "$subdir" -type f | wc -l)
                    local subname=$(basename "$subdir")
                    log "  ${subname}: $subcount files"
                done
            fi
        fi
    done
}

# Main function
main() {
    echo -e "${BLUE}Package Organization Script${NC}"
    echo -e "${BLUE}===========================${NC}"
    
    # Check if scan directory exists
    if [ ! -d "$SCAN_DIR" ]; then
        log "${RED}Scan directory $SCAN_DIR does not exist!${NC}"
        echo -e "${RED}Make sure you have mounted media devices.${NC}"
        exit 1
    fi
    
    # Show available devices
    echo -e "${BLUE}Available devices in $SCAN_DIR:${NC}"
    if ls -1 "$SCAN_DIR" 2>/dev/null | grep -q .; then
        ls -1 "$SCAN_DIR" 2>/dev/null | while read -r device; do
            echo -e "  ${YELLOW}$device${NC}"
        done
    else
        echo -e "  ${RED}No devices found${NC}"
        exit 1
    fi
    echo
    
    # Check if target device exists
    if [ ! -d "$BASE_DIR" ]; then
        log "${RED}Target device $BASE_DIR does not exist!${NC}"
        echo -e "${YELLOW}Available devices:${NC}"
        ls -1 "$SCAN_DIR" 2>/dev/null
        echo -e "${YELLOW}Usage: $0 [device_id]${NC}"
        echo -e "${YELLOW}Example: $0 048E307611AC6D7E${NC}"
        exit 1
    fi
    
    # Create OS directory if it doesn't exist
    if [ ! -d "$ORGANIZE_DIR" ]; then
        log "${BLUE}Creating OS directory: $ORGANIZE_DIR${NC}"
        mkdir -p "$ORGANIZE_DIR"
    fi
    
    # Initialize log
    echo "Package organization started at $(date)" > "$LOG_FILE"
    echo "User: $USER" >> "$LOG_FILE"
    echo "Scan Directory: $SCAN_DIR" >> "$LOG_FILE"
    echo "Target Device: $BASE_DIR" >> "$LOG_FILE"
    echo "Organization Directory: $ORGANIZE_DIR" >> "$LOG_FILE"
    
    # Show options
    echo
    echo -e "${YELLOW}User: $USER${NC}"
    echo -e "${YELLOW}Scan Directory: $SCAN_DIR${NC}"
    echo -e "${YELLOW}Target Device: $BASE_DIR${NC}"
    echo -e "${YELLOW}Organization Directory: $ORGANIZE_DIR${NC}"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "1. Organize all package files (default)"
    echo "2. Dry run (show what would be organized)"
    echo "3. Clean up empty directories only"
    echo "4. Show current organization summary"
    echo "5. Migrate large collections (for 100k+ files)"
    echo
    
    read -p "Select option (1-5) [1]: " choice
    choice=${choice:-1}
    
    case $choice in
        1)
            log "${GREEN}Starting package organization...${NC}"
            organize_files "$SCAN_DIR"
            cleanup_empty_dirs "$SCAN_DIR"
            display_summary "$SCAN_DIR"
            ;;
        2)
            DRY_RUN=true
            log "${YELLOW}Dry run mode - no files will be moved${NC}"
            organize_files "$SCAN_DIR"
            ;;
        3)
            log "${GREEN}Cleaning up empty directories...${NC}"
            cleanup_empty_dirs "$SCAN_DIR"
            ;;
        4)
            display_summary "$SCAN_DIR"
            ;;
        5)
            log "${GREEN}Starting large collection migration...${NC}"
            migrate_large_collections
            display_summary "$SCAN_DIR"
            ;;
        *)
            log "${RED}Invalid option selected${NC}"
            exit 1
            ;;
    esac
    
    log "${GREEN}Operation completed. Log saved to: $LOG_FILE${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
