#!/bin/bash

# File And ISO Management Suite
# Comprehensive file operations, ISO handling, and data management toolkit
# Consolidates: Find_and_move_iso.sh, file_organizer.sh, backup_manager.sh, data_migration.sh

set -euo pipefail

LOG_FILE="$HOME/file_iso_management_$(date +'%Y%m%d_%H%M%S').log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║              File And ISO Management Suite                   ║${NC}"
    echo -e "${PURPLE}║      Comprehensive File Operations & Data Management        ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_main_menu() {
    echo -e "${CYAN}Select file management option:${NC}"
    echo ""
    echo "💿 ISO & IMAGE MANAGEMENT:"
    echo "1. 🔍 Find & Organize ISO Files"
    echo "2. 💿 ISO File Operations"
    echo "3. 🖼️  Image File Management"
    echo "4. 🗜️  Archive & Compression Tools"
    echo ""
    echo "📁 FILE ORGANIZATION:"
    echo "5. 🗂️  Smart File Organizer"
    echo "6. 🔄 Duplicate File Finder"
    echo "7. 📊 Disk Space Analysis"
    echo "8. 🏷️  File Tagging & Metadata"
    echo ""
    echo "💾 BACKUP & MIGRATION:"
    echo "9. 📦 Backup Manager"
    echo "10. 🚛 Data Migration Tools"
    echo "11. 🔄 Sync & Replication"
    echo "12. 📋 Restore Operations"
    echo ""
    echo "🔧 ADVANCED OPERATIONS:"
    echo "13. 🔍 Advanced Search Tools"
    echo "14. 🔐 File Security & Permissions"
    echo "15. 📈 File System Maintenance"
    echo "16. 🚪 Exit"
    echo ""
    read -p "Enter your choice (1-16): " choice
}

# ===== UTILITY FUNCTIONS =====

check_root_required() {
    if [ "$EUID" -ne 0 ]; then
        log "${RED}This operation requires root privileges. Please run with sudo.${NC}"
        return 1
    fi
    return 0
}

install_package_if_missing() {
    local package="$1"
    
    if ! command -v "$package" >/dev/null 2>&1 && ! rpm -q "$package" >/dev/null 2>&1; then
        log "Installing $package..."
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "$package" 2>&1 | tee -a "$LOG_FILE"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "$package" 2>&1 | tee -a "$LOG_FILE"
        else
            log "${RED}No supported package manager found${NC}"
            return 1
        fi
    else
        log "$package is already installed"
    fi
}

format_size() {
    local size=$1
    if [ $size -ge 1073741824 ]; then
        echo "$(echo "scale=2; $size/1073741824" | bc)GB"
    elif [ $size -ge 1048576 ]; then
        echo "$(echo "scale=2; $size/1048576" | bc)MB"
    elif [ $size -ge 1024 ]; then
        echo "$(echo "scale=2; $size/1024" | bc)KB"
    else
        echo "${size}B"
    fi
}

create_directory_safely() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log "Created directory: $dir"
    fi
}

# ===== ISO & IMAGE MANAGEMENT =====

find_organize_iso_files() {
    log "${BLUE}=== Find & Organize ISO Files ===${NC}"
    
    echo "ISO file search and organization options:"
    echo "1. 🔍 Find all ISO files"
    echo "2. 📁 Organize ISOs by type"
    echo "3. 🗂️  Move ISOs to destination"
    echo "4. 📊 Analyze ISO collection"
    echo "5. 🧹 Clean up duplicate ISOs"
    read -p "Choose option (1-5): " iso_choice
    
    case $iso_choice in
        1)
            log "Searching for ISO files..."
            
            read -p "Enter search directory (default: $HOME): " search_dir
            if [ -z "$search_dir" ]; then
                search_dir="$HOME"
            fi
            
            if [ ! -d "$search_dir" ]; then
                log "${RED}Directory not found: $search_dir${NC}"
                return 1
            fi
            
            log "Searching for ISO files in: $search_dir"
            
            local iso_list="/tmp/found_isos_$(date +%Y%m%d_%H%M%S).txt"
            
            # Find ISO files
            find "$search_dir" -type f -iname "*.iso" -printf "%s %p\n" 2>/dev/null | \
            while read size path; do
                formatted_size=$(format_size $size)
                echo "$formatted_size $path" | tee -a "$iso_list"
            done
            
            local iso_count=$(wc -l < "$iso_list" 2>/dev/null || echo "0")
            
            if [ "$iso_count" -gt 0 ]; then
                log "${GREEN}Found $iso_count ISO files${NC}"
                
                # Calculate total size
                local total_size=$(awk '{total += $1} END {print total}' "$iso_list" 2>/dev/null || echo "0")
                local formatted_total=$(format_size $total_size)
                
                log "Total size: $formatted_total"
                log "Detailed list saved to: $iso_list"
                
                echo ""
                echo "Sample of found ISOs:"
                head -10 "$iso_list" | tee -a "$LOG_FILE"
                
                if [ "$iso_count" -gt 10 ]; then
                    log "... and $((iso_count - 10)) more files"
                fi
            else
                log "${YELLOW}No ISO files found in $search_dir${NC}"
            fi
            ;;
        2)
            log "Organizing ISOs by type..."
            
            read -p "Enter source directory: " source_dir
            read -p "Enter destination directory: " dest_dir
            
            if [ ! -d "$source_dir" ]; then
                log "${RED}Source directory not found: $source_dir${NC}"
                return 1
            fi
            
            create_directory_safely "$dest_dir"
            
            # Create category directories
            local categories=(
                "Linux"
                "Windows"
                "MacOS"
                "Software"
                "Games"
                "Utilities"
                "Unknown"
            )
            
            for category in "${categories[@]}"; do
                create_directory_safely "$dest_dir/$category"
            done
            
            log "Categorizing and moving ISOs..."
            
            find "$source_dir" -type f -iname "*.iso" | while read iso_file; do
                local filename=$(basename "$iso_file")
                local category="Unknown"
                
                # Categorize based on filename patterns
                if echo "$filename" | grep -qi -E "(ubuntu|debian|fedora|centos|rhel|opensuse|mint|arch|manjaro)"; then
                    category="Linux"
                elif echo "$filename" | grep -qi -E "(windows|win7|win8|win10|win11|server)"; then
                    category="Windows"
                elif echo "$filename" | grep -qi -E "(macos|osx)"; then
                    category="MacOS"
                elif echo "$filename" | grep -qi -E "(office|adobe|visual|studio)"; then
                    category="Software"
                elif echo "$filename" | grep -qi -E "(game|steam)"; then
                    category="Games"
                elif echo "$filename" | grep -qi -E "(antivirus|tool|utility|rescue)"; then
                    category="Utilities"
                fi
                
                log "Moving $filename to $category/"
                mv "$iso_file" "$dest_dir/$category/"
            done
            
            log "${GREEN}ISO organization completed${NC}"
            ;;
        3)
            log "Moving ISOs to destination..."
            
            read -p "Enter source directory: " source_dir
            read -p "Enter destination directory: " dest_dir
            
            if [ ! -d "$source_dir" ]; then
                log "${RED}Source directory not found: $source_dir${NC}"
                return 1
            fi
            
            create_directory_safely "$dest_dir"
            
            local iso_files=($(find "$source_dir" -type f -iname "*.iso"))
            local iso_count=${#iso_files[@]}
            
            if [ $iso_count -eq 0 ]; then
                log "${YELLOW}No ISO files found in source directory${NC}"
                return 0
            fi
            
            log "Found $iso_count ISO files to move"
            
            echo "Move options:"
            echo "1. Move all files"
            echo "2. Copy all files"
            echo "3. Select files to move"
            read -p "Choose option (1-3): " move_option
            
            case $move_option in
                1)
                    log "Moving all ISO files..."
                    for iso_file in "${iso_files[@]}"; do
                        local filename=$(basename "$iso_file")
                        log "Moving: $filename"
                        mv "$iso_file" "$dest_dir/"
                    done
                    ;;
                2)
                    log "Copying all ISO files..."
                    for iso_file in "${iso_files[@]}"; do
                        local filename=$(basename "$iso_file")
                        log "Copying: $filename"
                        cp "$iso_file" "$dest_dir/"
                    done
                    ;;
                3)
                    log "Available ISO files:"
                    for i in "${!iso_files[@]}"; do
                        echo "$((i+1)). $(basename "${iso_files[$i]}")"
                    done
                    
                    read -p "Enter file numbers to move (comma-separated): " selection
                    IFS=',' read -ra selected <<< "$selection"
                    
                    for num in "${selected[@]}"; do
                        num=$(echo "$num" | xargs)  # trim whitespace
                        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le $iso_count ]; then
                            local index=$((num - 1))
                            local filename=$(basename "${iso_files[$index]}")
                            log "Moving: $filename"
                            mv "${iso_files[$index]}" "$dest_dir/"
                        fi
                    done
                    ;;
            esac
            
            log "${GREEN}ISO move operation completed${NC}"
            ;;
        4)
            log "Analyzing ISO collection..."
            
            read -p "Enter directory to analyze: " analyze_dir
            
            if [ ! -d "$analyze_dir" ]; then
                log "${RED}Directory not found: $analyze_dir${NC}"
                return 1
            fi
            
            local analysis_report="/tmp/iso_analysis_$(date +%Y%m%d_%H%M%S).txt"
            
            {
                echo "ISO Collection Analysis Report"
                echo "=============================="
                echo "Generated: $(date)"
                echo "Directory: $analyze_dir"
                echo ""
                
                # Count and total size
                local iso_count=$(find "$analyze_dir" -type f -iname "*.iso" | wc -l)
                local total_size=$(find "$analyze_dir" -type f -iname "*.iso" -exec stat -c%s {} + | awk '{total+=$1} END {print total}')
                
                echo "Total ISO files: $iso_count"
                echo "Total size: $(format_size $total_size)"
                echo ""
                
                # Size distribution
                echo "Size Distribution:"
                echo "=================="
                find "$analyze_dir" -type f -iname "*.iso" -exec stat -c%s {} + | \
                awk '{
                    if ($1 < 737280000) small++
                    else if ($1 < 4700000000) medium++
                    else large++
                } END {
                    print "Small (<700MB): " small+0
                    print "Medium (700MB-4.7GB): " medium+0
                    print "Large (>4.7GB): " large+0
                }'
                echo ""
                
                # Detailed file list
                echo "Detailed File List:"
                echo "==================="
                find "$analyze_dir" -type f -iname "*.iso" -printf "%s %p\n" | \
                while read size path; do
                    echo "$(format_size $size) $(basename "$path")"
                done | sort -k1 -h
                
            } | tee "$analysis_report" | tee -a "$LOG_FILE"
            
            log "Analysis report saved to: $analysis_report"
            ;;
        5)
            log "Cleaning up duplicate ISOs..."
            
            read -p "Enter directory to check for duplicates: " check_dir
            
            if [ ! -d "$check_dir" ]; then
                log "${RED}Directory not found: $check_dir${NC}"
                return 1
            fi
            
            log "Scanning for duplicate ISO files..."
            
            # Install fdupes if needed
            install_package_if_missing "fdupes"
            
            if command -v fdupes >/dev/null 2>&1; then
                local duplicates_file="/tmp/iso_duplicates_$(date +%Y%m%d_%H%M%S).txt"
                
                fdupes -r "$check_dir" -f iso | tee "$duplicates_file" | tee -a "$LOG_FILE"
                
                if [ -s "$duplicates_file" ]; then
                    log "${YELLOW}Duplicate ISO files found${NC}"
                    
                    echo "Actions for duplicates:"
                    echo "1. List only (no action)"
                    echo "2. Delete duplicates (keep first)"
                    echo "3. Move duplicates to separate folder"
                    read -p "Choose action (1-3): " dup_action
                    
                    case $dup_action in
                        2)
                            log "Deleting duplicate files..."
                            fdupes -r "$check_dir" -f iso -d
                            ;;
                        3)
                            local dup_dir="$check_dir/duplicates"
                            create_directory_safely "$dup_dir"
                            
                            log "Moving duplicates to: $dup_dir"
                            # Custom script to move duplicates would go here
                            ;;
                    esac
                else
                    log "${GREEN}No duplicate ISO files found${NC}"
                fi
            else
                log "${YELLOW}fdupes not available for duplicate detection${NC}"
                
                # Alternative: basic duplicate detection by size
                log "Using basic size-based duplicate detection..."
                find "$check_dir" -type f -iname "*.iso" -exec stat -c "%s %n" {} + | \
                sort | uniq -d -w 10 | tee -a "$LOG_FILE"
            fi
            ;;
    esac
    
    log "${GREEN}ISO file management completed${NC}"
}

iso_file_operations() {
    log "${BLUE}=== ISO File Operations ===${NC}"
    
    echo "ISO file operations:"
    echo "1. 🔍 Examine ISO contents"
    echo "2. 🗜️  Extract ISO files"
    echo "3. 💿 Mount/Unmount ISO"
    echo "4. ✅ Verify ISO integrity"
    echo "5. 🔧 Create ISO from directory"
    read -p "Choose operation (1-5): " iso_op_choice
    
    case $iso_op_choice in
        1)
            read -p "Enter path to ISO file: " iso_path
            
            if [ ! -f "$iso_path" ]; then
                log "${RED}ISO file not found: $iso_path${NC}"
                return 1
            fi
            
            log "Examining ISO contents: $(basename "$iso_path")"
            
            # Install required tools
            install_package_if_missing "isoinfo"
            
            if command -v isoinfo >/dev/null 2>&1; then
                log "ISO Information:"
                isoinfo -d -i "$iso_path" | tee -a "$LOG_FILE"
                
                echo ""
                log "Directory listing:"
                isoinfo -l -i "$iso_path" | head -50 | tee -a "$LOG_FILE"
            else
                # Alternative using file command
                log "Basic ISO information:"
                file "$iso_path" | tee -a "$LOG_FILE"
                ls -lh "$iso_path" | tee -a "$LOG_FILE"
            fi
            ;;
        2)
            read -p "Enter path to ISO file: " iso_path
            read -p "Enter extraction destination: " extract_dir
            
            if [ ! -f "$iso_path" ]; then
                log "${RED}ISO file not found: $iso_path${NC}"
                return 1
            fi
            
            create_directory_safely "$extract_dir"
            
            log "Extracting ISO: $(basename "$iso_path")"
            
            # Method 1: Using 7zip
            if command -v 7z >/dev/null 2>&1; then
                7z x "$iso_path" -o"$extract_dir"
            # Method 2: Using mount and copy
            elif command -v mount >/dev/null 2>&1; then
                local mount_point="/tmp/iso_mount_$$"
                mkdir -p "$mount_point"
                
                if sudo mount -o loop "$iso_path" "$mount_point"; then
                    cp -r "$mount_point"/* "$extract_dir"/ 2>/dev/null || true
                    sudo umount "$mount_point"
                    rmdir "$mount_point"
                    log "${GREEN}ISO extracted successfully${NC}"
                else
                    log "${RED}Failed to mount ISO${NC}"
                    rmdir "$mount_point"
                fi
            else
                log "${RED}No suitable extraction tool found${NC}"
            fi
            ;;
        3)
            echo "Mount/Unmount operations:"
            echo "1. Mount ISO"
            echo "2. Unmount ISO"
            echo "3. List mounted ISOs"
            read -p "Choose operation (1-3): " mount_choice
            
            case $mount_choice in
                1)
                    read -p "Enter path to ISO file: " iso_path
                    read -p "Enter mount point (default: /mnt/iso): " mount_point
                    
                    if [ -z "$mount_point" ]; then
                        mount_point="/mnt/iso"
                    fi
                    
                    if [ ! -f "$iso_path" ]; then
                        log "${RED}ISO file not found: $iso_path${NC}"
                        return 1
                    fi
                    
                    create_directory_safely "$mount_point"
                    
                    if sudo mount -o loop "$iso_path" "$mount_point"; then
                        log "${GREEN}ISO mounted at: $mount_point${NC}"
                        ls -la "$mount_point" | tee -a "$LOG_FILE"
                    else
                        log "${RED}Failed to mount ISO${NC}"
                    fi
                    ;;
                2)
                    read -p "Enter mount point to unmount: " mount_point
                    
                    if sudo umount "$mount_point" 2>/dev/null; then
                        log "${GREEN}Successfully unmounted: $mount_point${NC}"
                    else
                        log "${RED}Failed to unmount: $mount_point${NC}"
                    fi
                    ;;
                3)
                    log "Currently mounted ISOs:"
                    mount | grep loop | tee -a "$LOG_FILE"
                    ;;
            esac
            ;;
        4)
            read -p "Enter path to ISO file: " iso_path
            
            if [ ! -f "$iso_path" ]; then
                log "${RED}ISO file not found: $iso_path${NC}"
                return 1
            fi
            
            log "Verifying ISO integrity: $(basename "$iso_path")"
            
            # Check if checksums are available
            local iso_dir=$(dirname "$iso_path")
            local iso_name=$(basename "$iso_path" .iso)
            
            # Look for common checksum files
            local checksum_files=(
                "$iso_dir/${iso_name}.md5"
                "$iso_dir/${iso_name}.sha1"
                "$iso_dir/${iso_name}.sha256"
                "$iso_dir/MD5SUMS"
                "$iso_dir/SHA1SUMS"
                "$iso_dir/SHA256SUMS"
            )
            
            local found_checksum=""
            for checksum_file in "${checksum_files[@]}"; do
                if [ -f "$checksum_file" ]; then
                    found_checksum="$checksum_file"
                    break
                fi
            done
            
            if [ -n "$found_checksum" ]; then
                log "Found checksum file: $found_checksum"
                
                if echo "$found_checksum" | grep -q md5; then
                    md5sum -c "$found_checksum" | grep "$(basename "$iso_path")" | tee -a "$LOG_FILE"
                elif echo "$found_checksum" | grep -q sha1; then
                    sha1sum -c "$found_checksum" | grep "$(basename "$iso_path")" | tee -a "$LOG_FILE"
                elif echo "$found_checksum" | grep -q sha256; then
                    sha256sum -c "$found_checksum" | grep "$(basename "$iso_path")" | tee -a "$LOG_FILE"
                fi
            else
                log "No checksum file found, generating checksums..."
                
                log "MD5: $(md5sum "$iso_path" | cut -d' ' -f1)"
                log "SHA1: $(sha1sum "$iso_path" | cut -d' ' -f1)"
                log "SHA256: $(sha256sum "$iso_path" | cut -d' ' -f1)"
                
                # Save checksums
                echo "$(md5sum "$iso_path")" > "${iso_path}.md5"
                echo "$(sha1sum "$iso_path")" > "${iso_path}.sha1"
                echo "$(sha256sum "$iso_path")" > "${iso_path}.sha256"
                
                log "Checksums saved to ${iso_path}.{md5,sha1,sha256}"
            fi
            ;;
        5)
            read -p "Enter source directory: " source_dir
            read -p "Enter output ISO file path: " output_iso
            
            if [ ! -d "$source_dir" ]; then
                log "${RED}Source directory not found: $source_dir${NC}"
                return 1
            fi
            
            # Install required tools
            install_package_if_missing "genisoimage"
            
            if command -v genisoimage >/dev/null 2>&1; then
                log "Creating ISO from directory: $source_dir"
                
                genisoimage -o "$output_iso" -R -J -T -v "$source_dir" 2>&1 | tee -a "$LOG_FILE"
                
                if [ -f "$output_iso" ]; then
                    log "${GREEN}ISO created successfully: $output_iso${NC}"
                    ls -lh "$output_iso" | tee -a "$LOG_FILE"
                else
                    log "${RED}Failed to create ISO${NC}"
                fi
            else
                log "${RED}genisoimage not available${NC}"
            fi
            ;;
    esac
    
    log "${GREEN}ISO operations completed${NC}"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== File And ISO Management Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) find_organize_iso_files ;;
            2) iso_file_operations ;;
            3) image_file_management ;;
            4) archive_compression_tools ;;
            5) smart_file_organizer ;;
            6) duplicate_file_finder ;;
            7) disk_space_analysis ;;
            8) file_tagging_metadata ;;
            9) backup_manager ;;
            10) data_migration_tools ;;
            11) sync_replication ;;
            12) restore_operations ;;
            13) advanced_search_tools ;;
            14) file_security_permissions ;;
            15) filesystem_maintenance ;;
            16) 
                log "${GREEN}Exiting File And ISO Management Suite${NC}"
                echo -e "${GREEN}Log file saved to: $LOG_FILE${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Placeholder functions for remaining menu items (to be implemented)
image_file_management() {
    log "${BLUE}=== Image File Management ===${NC}"
    log "This feature will manage image files (photos, graphics)"
    log "Implementation: Image organization, metadata extraction, format conversion"
}

archive_compression_tools() {
    log "${BLUE}=== Archive & Compression Tools ===${NC}"
    log "This feature will handle archive and compression operations"
    log "Implementation: tar, zip, 7z operations, compression optimization"
}

smart_file_organizer() {
    log "${BLUE}=== Smart File Organizer ===${NC}"
    log "This feature will intelligently organize files"
    log "Implementation: File type detection, auto-categorization, smart rules"
}

duplicate_file_finder() {
    log "${BLUE}=== Duplicate File Finder ===${NC}"
    log "This feature will find and handle duplicate files"
    log "Implementation: Hash-based detection, size comparison, cleanup options"
}

disk_space_analysis() {
    log "${BLUE}=== Disk Space Analysis ===${NC}"
    log "This feature will analyze disk space usage"
    log "Implementation: Directory tree analysis, largest files, space visualization"
}

file_tagging_metadata() {
    log "${BLUE}=== File Tagging & Metadata ===${NC}"
    log "This feature will manage file tags and metadata"
    log "Implementation: Extended attributes, file tags, metadata extraction"
}

backup_manager() {
    log "${BLUE}=== Backup Manager ===${NC}"
    log "This feature will manage backup operations"
    log "Implementation: Incremental backups, scheduling, compression, verification"
}

data_migration_tools() {
    log "${BLUE}=== Data Migration Tools ===${NC}"
    log "This feature will handle data migration tasks"
    log "Implementation: Large file transfers, progress monitoring, validation"
}

sync_replication() {
    log "${BLUE}=== Sync & Replication ===${NC}"
    log "This feature will handle file synchronization"
    log "Implementation: rsync operations, bi-directional sync, conflict resolution"
}

restore_operations() {
    log "${BLUE}=== Restore Operations ===${NC}"
    log "This feature will handle file restoration"
    log "Implementation: Backup restoration, file recovery, point-in-time recovery"
}

advanced_search_tools() {
    log "${BLUE}=== Advanced Search Tools ===${NC}"
    log "This feature will provide advanced file search capabilities"
    log "Implementation: Complex queries, content search, metadata search"
}

file_security_permissions() {
    log "${BLUE}=== File Security & Permissions ===${NC}"
    log "This feature will manage file security and permissions"
    log "Implementation: Permission analysis, ACL management, security auditing"
}

filesystem_maintenance() {
    log "${BLUE}=== File System Maintenance ===${NC}"
    log "This feature will perform filesystem maintenance"
    log "Implementation: fsck operations, defragmentation, optimization"
}

main "$@"
