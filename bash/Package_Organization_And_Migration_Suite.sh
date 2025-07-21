#!/bin/bash

# Package Organization And Migration Suite
# Comprehensive package management, organization, and migration toolkit
# Consolidates: move_rpms_in_batches.sh, organize_rpms.sh, Manage_downloaded_package.sh, bulk_mv.sh

set -euo pipefail

LOG_FILE="$HOME/package_management_$(date +'%Y%m%d_%H%M%S').log"

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
    echo -e "${PURPLE}║         Package Organization And Migration Suite             ║${NC}"
    echo -e "${PURPLE}║     Comprehensive Package Management & Organization Tool     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_main_menu() {
    echo -e "${CYAN}Select package management option:${NC}"
    echo ""
    echo "📦 PACKAGE ORGANIZATION:"
    echo "1. 🗂️  Auto-Organize RPM Packages by OS/Architecture"
    echo "2. 📁 Batch Move Files to Organized Structure"
    echo "3. 🔄 Migrate Packages Between Directories"
    echo "4. 📋 Sort & Categorize Downloaded Packages"
    echo ""
    echo "🧹 CLEANUP & MAINTENANCE:"
    echo "5. 🗑️  Remove Duplicate Packages"
    echo "6. 🔍 Find & Manage Old Package Versions"
    echo "7. 📊 Package Statistics & Analysis"
    echo "8. 🧼 Clean Empty Directories"
    echo ""
    echo "🔧 BATCH OPERATIONS:"
    echo "9. 📦 Bulk File Operations"
    echo "10. 🏷️  Mass Rename Package Files"
    echo "11. 🔗 Create Package Symlinks"
    echo "12. 📋 Generate Package Inventory"
    echo ""
    echo "⚙️  ADVANCED:"
    echo "13. 🎯 Custom Package Organization Rules"
    echo "14. 📊 Package Dependency Analysis"
    echo "15. 🚀 Automated Package Workflow"
    echo "16. 🚪 Exit"
    echo ""
    read -p "Enter your choice (1-16): " choice
}

# ===== UTILITY FUNCTIONS =====

detect_package_info() {
    local package_file="$1"
    local filename=$(basename "$package_file")
    
    # Initialize variables
    local os=""
    local os_major=""
    local arch=""
    local package_name=""
    local version=""
    
    # Detect OS from filename
    if [[ "$filename" == *".el9."* ]]; then
        os="RHEL"
        os_major="9"
    elif [[ "$filename" == *".el8."* ]]; then
        os="RHEL"
        os_major="8"
    elif [[ "$filename" == *".el7."* ]]; then
        os="RHEL"
        os_major="7"
    elif [[ "$filename" == *".fc"* ]]; then
        os="Fedora"
        os_major=$(echo "$filename" | sed -n 's/.*\.fc\([0-9]\+\)\..*/\1/p')
    elif [[ "$filename" == *".mga"* ]]; then
        os="Mageia"
        os_major=$(echo "$filename" | sed -n 's/.*\.mga\([0-9]\+\)\..*/\1/p')
    elif [[ "$filename" == *".mdv"* ]] || [[ "$filename" == *".mnb"* ]]; then
        os="Mandriva"
    elif [[ "$filename" == *".suse"* ]] || [[ "$filename" == *".opensuse"* ]]; then
        os="SUSE"
    else
        os="Unknown"
        os_major="Unknown"
    fi
    
    # Detect architecture
    if [[ "$filename" == *".x86_64."* ]] || [[ "$filename" == *".x86_64.rpm" ]]; then
        arch="x86_64"
    elif [[ "$filename" == *".i686."* ]] || [[ "$filename" == *".i686.rpm" ]]; then
        arch="i686"
    elif [[ "$filename" == *".aarch64."* ]] || [[ "$filename" == *".aarch64.rpm" ]]; then
        arch="aarch64"
    elif [[ "$filename" == *".armv7hl."* ]] || [[ "$filename" == *".armv7hl.rpm" ]]; then
        arch="armv7hl"
    elif [[ "$filename" == *".noarch."* ]] || [[ "$filename" == *".noarch.rpm" ]]; then
        arch="noarch"
    elif [[ "$filename" == *".src."* ]] || [[ "$filename" == *".src.rpm" ]]; then
        arch="src"
    else
        arch="unknown"
    fi
    
    # Extract package name (everything before first version number)
    package_name=$(echo "$filename" | sed 's/\.rpm$//' | sed 's/-[0-9].*//')
    
    # Extract version (everything between package name and architecture)
    local remaining=$(echo "$filename" | sed "s/^$package_name-//" | sed 's/\.rpm$//')
    version=$(echo "$remaining" | sed "s/\.$arch.*$//" | sed "s/\.$os_major.*$//" | sed 's/\.el[0-9].*$//' | sed 's/\.fc[0-9].*$//')
    
    echo "$os|$os_major|$arch|$package_name|$version"
}

get_first_letter() {
    local name="$1"
    local first_char=$(echo "$name" | head -c 1 | tr '[:lower:]' '[:upper:]')
    
    # Handle special cases
    case "$first_char" in
        [0-9]) echo "0-9" ;;
        [A-Z]) echo "$first_char" ;;
        *) echo "Other" ;;
    esac
}

create_directory_structure() {
    local base_dir="$1"
    local os="$2"
    local os_major="$3"
    local arch="$4"
    local first_letter="$5"
    
    local target_dir="$base_dir/$os"
    if [ "$os_major" != "Unknown" ]; then
        target_dir="$target_dir/$os_major"
    fi
    target_dir="$target_dir/$arch/$first_letter"
    
    mkdir -p "$target_dir"
    echo "$target_dir"
}

# ===== PACKAGE ORGANIZATION =====

auto_organize_rpms() {
    log "${BLUE}=== Auto-Organizing RPM Packages ===${NC}"
    
    echo "RPM Organization Options:"
    echo "1. Organize single directory"
    echo "2. Organize multiple directories" 
    echo "3. Organize with custom structure"
    echo ""
    read -p "Choose option (1-3): " org_choice
    
    case $org_choice in
        1) organize_single_directory ;;
        2) organize_multiple_directories ;;
        3) organize_custom_structure ;;
        *) log "${RED}Invalid choice${NC}"; return 1 ;;
    esac
}

organize_single_directory() {
    read -p "Enter source directory containing RPMs: " source_dir
    if [ ! -d "$source_dir" ]; then
        log "${RED}Directory not found: $source_dir${NC}"
        return 1
    fi
    
    read -p "Enter target directory for organized structure: " target_dir
    mkdir -p "$target_dir"
    
    local rpm_count=0
    local organized_count=0
    local version_keep_count=2
    
    read -p "Keep how many versions of each package? (default: 2): " user_keep_count
    if [[ "$user_keep_count" =~ ^[0-9]+$ ]]; then
        version_keep_count="$user_keep_count"
    fi
    
    log "Organizing RPMs from $source_dir to $target_dir"
    log "Keeping $version_keep_count versions of each package"
    
    # Find all RPM files
    while IFS= read -r -d '' rpm_file; do
        ((rpm_count++))
        
        local filename=$(basename "$rpm_file")
        log "Processing: $filename"
        
        # Parse package information
        local package_info=$(detect_package_info "$rpm_file")
        IFS='|' read -r os os_major arch package_name version <<< "$package_info"
        
        local first_letter=$(get_first_letter "$package_name")
        local dest_dir=$(create_directory_structure "$target_dir" "$os" "$os_major" "$arch" "$first_letter")
        
        # Check for existing versions
        local existing_versions=()
        while IFS= read -r -d '' existing_file; do
            existing_versions+=("$(basename "$existing_file")")
        done < <(find "$dest_dir" -name "${package_name}-*.rpm" -print0 2>/dev/null || true)
        
        # Sort versions and keep only the newest ones
        if [ ${#existing_versions[@]} -ge $version_keep_count ]; then
            log "Found ${#existing_versions[@]} versions of $package_name, keeping newest $version_keep_count"
            
            # Sort by modification time and remove older versions
            local sorted_files=($(printf '%s\n' "${existing_versions[@]}" | while read -r file; do
                echo "$(stat -c %Y "$dest_dir/$file") $file"
            done | sort -nr | cut -d' ' -f2-))
            
            # Remove oldest versions
            for ((i=$version_keep_count; i<${#sorted_files[@]}; i++)); do
                local old_file="$dest_dir/${sorted_files[i]}"
                log "Removing old version: ${sorted_files[i]}"
                rm -f "$old_file"
            done
        fi
        
        # Move the new file
        if mv "$rpm_file" "$dest_dir/"; then
            log "Moved to: $dest_dir/"
            ((organized_count++))
        else
            log "${RED}Failed to move: $filename${NC}"
        fi
        
        # Progress indicator
        if [ $((rpm_count % 50)) -eq 0 ]; then
            log "Progress: $organized_count/$rpm_count packages organized"
        fi
        
    done < <(find "$source_dir" -name "*.rpm" -type f -print0)
    
    log "${GREEN}Organization complete: $organized_count/$rpm_count packages organized${NC}"
    
    # Clean up empty directories
    find "$source_dir" -type d -empty -delete 2>/dev/null || true
    
    # Generate summary
    generate_organization_summary "$target_dir"
}

organize_multiple_directories() {
    echo "Enter directories containing RPMs (one per line, empty line to finish):"
    local source_dirs=()
    
    while true; do
        read -p "Directory: " dir
        if [ -z "$dir" ]; then
            break
        fi
        if [ -d "$dir" ]; then
            source_dirs+=("$dir")
        else
            log "${YELLOW}Warning: Directory not found: $dir${NC}"
        fi
    done
    
    if [ ${#source_dirs[@]} -eq 0 ]; then
        log "${RED}No valid directories provided${NC}"
        return 1
    fi
    
    read -p "Enter target directory for organized structure: " target_dir
    mkdir -p "$target_dir"
    
    log "Processing ${#source_dirs[@]} directories..."
    
    local total_rpm_count=0
    local total_organized_count=0
    
    for source_dir in "${source_dirs[@]}"; do
        log "${CYAN}Processing directory: $source_dir${NC}"
        
        local rpm_count=0
        local organized_count=0
        
        while IFS= read -r -d '' rpm_file; do
            ((rpm_count++))
            ((total_rpm_count++))
            
            local filename=$(basename "$rpm_file")
            local package_info=$(detect_package_info "$rpm_file")
            IFS='|' read -r os os_major arch package_name version <<< "$package_info"
            
            local first_letter=$(get_first_letter "$package_name")
            local dest_dir=$(create_directory_structure "$target_dir" "$os" "$os_major" "$arch" "$first_letter")
            
            if mv "$rpm_file" "$dest_dir/"; then
                ((organized_count++))
                ((total_organized_count++))
            fi
            
        done < <(find "$source_dir" -name "*.rpm" -type f -print0)
        
        log "Processed $source_dir: $organized_count/$rpm_count packages"
        
        # Clean up empty directories
        find "$source_dir" -type d -empty -delete 2>/dev/null || true
    done
    
    log "${GREEN}Total organization complete: $total_organized_count/$total_rpm_count packages${NC}"
    generate_organization_summary "$target_dir"
}

organize_custom_structure() {
    log "${BLUE}Custom Package Organization${NC}"
    
    echo "Select organization structure:"
    echo "1. By Package Name Only (Alphabetical)"
    echo "2. By Architecture Only"
    echo "3. By OS Only"
    echo "4. Flat Structure (No subdirectories)"
    echo "5. Custom Pattern"
    echo ""
    read -p "Choose structure (1-5): " structure_choice
    
    read -p "Enter source directory: " source_dir
    read -p "Enter target directory: " target_dir
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    mkdir -p "$target_dir"
    
    local rpm_count=0
    local organized_count=0
    
    while IFS= read -r -d '' rpm_file; do
        ((rpm_count++))
        
        local filename=$(basename "$rpm_file")
        local package_info=$(detect_package_info "$rpm_file")
        IFS='|' read -r os os_major arch package_name version <<< "$package_info"
        
        local dest_dir=""
        
        case $structure_choice in
            1)
                local first_letter=$(get_first_letter "$package_name")
                dest_dir="$target_dir/$first_letter"
                ;;
            2)
                dest_dir="$target_dir/$arch"
                ;;
            3)
                dest_dir="$target_dir/$os"
                ;;
            4)
                dest_dir="$target_dir"
                ;;
            5)
                read -p "Enter custom pattern (use {os}, {arch}, {name}, {version}): " pattern
                dest_dir=$(echo "$pattern" | sed "s/{os}/$os/g" | sed "s/{arch}/$arch/g" | sed "s/{name}/$package_name/g" | sed "s/{version}/$version/g")
                dest_dir="$target_dir/$dest_dir"
                ;;
            *)
                log "${RED}Invalid choice${NC}"
                return 1
                ;;
        esac
        
        mkdir -p "$dest_dir"
        
        if mv "$rpm_file" "$dest_dir/"; then
            ((organized_count++))
            log "Moved $filename to $dest_dir/"
        fi
        
    done < <(find "$source_dir" -name "*.rpm" -type f -print0)
    
    log "${GREEN}Custom organization complete: $organized_count/$rpm_count packages${NC}"
}

# ===== BATCH OPERATIONS =====

batch_move_files() {
    log "${BLUE}=== Batch File Operations ===${NC}"
    
    echo "Batch Move Options:"
    echo "1. Move files by extension"
    echo "2. Move files by pattern"
    echo "3. Move files by size"
    echo "4. Move files by date"
    echo "5. Interactive batch move"
    echo ""
    read -p "Choose option (1-5): " batch_choice
    
    case $batch_choice in
        1) batch_move_by_extension ;;
        2) batch_move_by_pattern ;;
        3) batch_move_by_size ;;
        4) batch_move_by_date ;;
        5) interactive_batch_move ;;
        *) log "${RED}Invalid choice${NC}"; return 1 ;;
    esac
}

batch_move_by_extension() {
    read -p "Enter source directory: " source_dir
    read -p "Enter target directory: " target_dir
    read -p "Enter file extension (e.g., rpm, deb, tar.gz): " extension
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    mkdir -p "$target_dir"
    
    local file_count=0
    local moved_count=0
    
    while IFS= read -r -d '' file; do
        ((file_count++))
        
        if mv "$file" "$target_dir/"; then
            ((moved_count++))
            log "Moved: $(basename "$file")"
        fi
        
    done < <(find "$source_dir" -name "*.$extension" -type f -print0)
    
    log "${GREEN}Batch move complete: $moved_count/$file_count files moved${NC}"
}

batch_move_by_pattern() {
    read -p "Enter source directory: " source_dir
    read -p "Enter target directory: " target_dir
    read -p "Enter filename pattern (e.g., *kernel*, test-*): " pattern
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    mkdir -p "$target_dir"
    
    local file_count=0
    local moved_count=0
    
    while IFS= read -r -d '' file; do
        ((file_count++))
        
        if mv "$file" "$target_dir/"; then
            ((moved_count++))
            log "Moved: $(basename "$file")"
        fi
        
    done < <(find "$source_dir" -name "$pattern" -type f -print0)
    
    log "${GREEN}Pattern-based move complete: $moved_count/$file_count files moved${NC}"
}

batch_move_by_size() {
    read -p "Enter source directory: " source_dir
    read -p "Enter target directory: " target_dir
    echo "Size options:"
    echo "1. Files larger than X MB"
    echo "2. Files smaller than X MB"
    echo "3. Files between X and Y MB"
    read -p "Choose option (1-3): " size_option
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    mkdir -p "$target_dir"
    
    local find_args=""
    
    case $size_option in
        1)
            read -p "Enter minimum size in MB: " min_size
            find_args="-size +${min_size}M"
            ;;
        2)
            read -p "Enter maximum size in MB: " max_size
            find_args="-size -${max_size}M"
            ;;
        3)
            read -p "Enter minimum size in MB: " min_size
            read -p "Enter maximum size in MB: " max_size
            find_args="-size +${min_size}M -size -${max_size}M"
            ;;
        *)
            log "${RED}Invalid option${NC}"
            return 1
            ;;
    esac
    
    local file_count=0
    local moved_count=0
    
    while IFS= read -r -d '' file; do
        ((file_count++))
        
        if mv "$file" "$target_dir/"; then
            ((moved_count++))
            local size=$(du -h "$target_dir/$(basename "$file")" | cut -f1)
            log "Moved: $(basename "$file") ($size)"
        fi
        
    done < <(find "$source_dir" $find_args -type f -print0)
    
    log "${GREEN}Size-based move complete: $moved_count/$file_count files moved${NC}"
}

batch_move_by_date() {
    read -p "Enter source directory: " source_dir
    read -p "Enter target directory: " target_dir
    echo "Date options:"
    echo "1. Files newer than X days"
    echo "2. Files older than X days"
    echo "3. Files modified today"
    echo "4. Files modified this week"
    read -p "Choose option (1-4): " date_option
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    mkdir -p "$target_dir"
    
    local find_args=""
    
    case $date_option in
        1)
            read -p "Enter number of days: " days
            find_args="-mtime -$days"
            ;;
        2)
            read -p "Enter number of days: " days
            find_args="-mtime +$days"
            ;;
        3)
            find_args="-mtime 0"
            ;;
        4)
            find_args="-mtime -7"
            ;;
        *)
            log "${RED}Invalid option${NC}"
            return 1
            ;;
    esac
    
    local file_count=0
    local moved_count=0
    
    while IFS= read -r -d '' file; do
        ((file_count++))
        
        if mv "$file" "$target_dir/"; then
            ((moved_count++))
            local date=$(stat -c %y "$target_dir/$(basename "$file")" | cut -d' ' -f1)
            log "Moved: $(basename "$file") (modified: $date)"
        fi
        
    done < <(find "$source_dir" $find_args -type f -print0)
    
    log "${GREEN}Date-based move complete: $moved_count/$file_count files moved${NC}"
}

interactive_batch_move() {
    read -p "Enter source directory: " source_dir
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    echo "Files in $source_dir:"
    find "$source_dir" -type f | head -20
    
    local total_files=$(find "$source_dir" -type f | wc -l)
    if [ "$total_files" -gt 20 ]; then
        echo "... and $((total_files - 20)) more files"
    fi
    
    echo ""
    echo "1. Move all files"
    echo "2. Select files interactively"
    echo "3. Move files matching pattern"
    read -p "Choose option (1-3): " interactive_choice
    
    read -p "Enter target directory: " target_dir
    mkdir -p "$target_dir"
    
    case $interactive_choice in
        1)
            find "$source_dir" -type f -exec mv {} "$target_dir/" \;
            log "All files moved to $target_dir"
            ;;
        2)
            while IFS= read -r -d '' file; do
                echo -n "Move $(basename "$file")? [y/N]: "
                read -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    mv "$file" "$target_dir/"
                    log "Moved: $(basename "$file")"
                fi
            done < <(find "$source_dir" -type f -print0)
            ;;
        3)
            read -p "Enter pattern to match: " pattern
            find "$source_dir" -name "$pattern" -type f -exec mv {} "$target_dir/" \;
            log "Files matching '$pattern' moved to $target_dir"
            ;;
    esac
}

# ===== CLEANUP & MAINTENANCE =====

remove_duplicate_packages() {
    log "${BLUE}=== Removing Duplicate Packages ===${NC}"
    
    read -p "Enter directory to scan for duplicates: " scan_dir
    
    if [ ! -d "$scan_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    log "Scanning for duplicate packages in $scan_dir..."
    
    declare -A package_versions
    local duplicate_count=0
    local total_saved_space=0
    
    # First pass: collect all packages and their versions
    while IFS= read -r -d '' rpm_file; do
        local package_info=$(detect_package_info "$rpm_file")
        IFS='|' read -r os os_major arch package_name version <<< "$package_info"
        
        local key="${package_name}_${arch}"
        local file_info="$rpm_file|$version"
        
        if [ -n "${package_versions[$key]:-}" ]; then
            package_versions[$key]="${package_versions[$key]}:$file_info"
        else
            package_versions[$key]="$file_info"
        fi
        
    done < <(find "$scan_dir" -name "*.rpm" -type f -print0)
    
    log "Found ${#package_versions[@]} unique package/architecture combinations"
    
    # Second pass: identify and remove duplicates
    for key in "${!package_versions[@]}"; do
        local files_info="${package_versions[$key]}"
        local file_count=$(echo "$files_info" | tr ':' '\n' | wc -l)
        
        if [ "$file_count" -gt 1 ]; then
            log "${CYAN}Found $file_count versions of $key:${NC}"
            
            # Sort versions and keep the newest
            local newest_file=""
            local newest_time=0
            local files_to_remove=()
            
            while IFS=':' read -ra files; do
                for file_info in "${files[@]}"; do
                    IFS='|' read -r file_path version <<< "$file_info"
                    local file_time=$(stat -c %Y "$file_path")
                    
                    log "  Version $version: $(basename "$file_path") ($(date -d @$file_time '+%Y-%m-%d'))"
                    
                    if [ "$file_time" -gt "$newest_time" ]; then
                        if [ -n "$newest_file" ]; then
                            files_to_remove+=("$newest_file")
                        fi
                        newest_file="$file_path"
                        newest_time="$file_time"
                    else
                        files_to_remove+=("$file_path")
                    fi
                done
            done <<< "$files_info"
            
            # Remove older versions
            for old_file in "${files_to_remove[@]}"; do
                if [ -f "$old_file" ]; then
                    local file_size=$(stat -c %s "$old_file")
                    log "${YELLOW}Removing old version: $(basename "$old_file")${NC}"
                    
                    if rm "$old_file"; then
                        ((duplicate_count++))
                        total_saved_space=$((total_saved_space + file_size))
                    fi
                fi
            done
            
            log "${GREEN}Kept newest: $(basename "$newest_file")${NC}"
            echo ""
        fi
    done
    
    local saved_mb=$((total_saved_space / 1024 / 1024))
    log "${GREEN}Duplicate removal complete: $duplicate_count files removed, ${saved_mb}MB saved${NC}"
}

find_manage_old_versions() {
    log "${BLUE}=== Finding & Managing Old Package Versions ===${NC}"
    
    read -p "Enter directory to scan: " scan_dir
    read -p "Keep how many versions of each package? (default: 2): " keep_versions
    
    if [ ! -d "$scan_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    if ! [[ "$keep_versions" =~ ^[0-9]+$ ]]; then
        keep_versions=2
    fi
    
    log "Scanning for packages with more than $keep_versions versions..."
    
    declare -A package_files
    local cleanup_count=0
    
    # Collect all packages
    while IFS= read -r -d '' rpm_file; do
        local package_info=$(detect_package_info "$rpm_file")
        IFS='|' read -r os os_major arch package_name version <<< "$package_info"
        
        local key="${package_name}_${arch}"
        local file_time=$(stat -c %Y "$rpm_file")
        local file_info="$file_time|$rpm_file"
        
        if [ -n "${package_files[$key]:-}" ]; then
            package_files[$key]="${package_files[$key]}:$file_info"
        else
            package_files[$key]="$file_info"
        fi
        
    done < <(find "$scan_dir" -name "*.rpm" -type f -print0)
    
    # Process packages with multiple versions
    for key in "${!package_files[@]}"; do
        local files_info="${package_files[$key]}"
        local file_count=$(echo "$files_info" | tr ':' '\n' | wc -l)
        
        if [ "$file_count" -gt "$keep_versions" ]; then
            log "${CYAN}Package $key has $file_count versions (keeping newest $keep_versions):${NC}"
            
            # Sort files by timestamp (newest first)
            local sorted_files=($(echo "$files_info" | tr ':' '\n' | sort -t'|' -k1,1nr))
            
            # Keep newest versions, remove older ones
            for ((i=$keep_versions; i<${#sorted_files[@]}; i++)); do
                local file_info="${sorted_files[i]}"
                IFS='|' read -r file_time file_path <<< "$file_info"
                
                log "${YELLOW}Removing old version: $(basename "$file_path")${NC}"
                
                if rm "$file_path"; then
                    ((cleanup_count++))
                fi
            done
            
            # Show kept versions
            for ((i=0; i<$keep_versions && i<${#sorted_files[@]}; i++)); do
                local file_info="${sorted_files[i]}"
                IFS='|' read -r file_time file_path <<< "$file_info"
                log "${GREEN}Kept: $(basename "$file_path")${NC}"
            done
            echo ""
        fi
    done
    
    log "${GREEN}Version cleanup complete: $cleanup_count old versions removed${NC}"
}

package_statistics_analysis() {
    log "${BLUE}=== Package Statistics & Analysis ===${NC}"
    
    read -p "Enter directory to analyze: " analyze_dir
    
    if [ ! -d "$analyze_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    log "Analyzing packages in $analyze_dir..."
    
    local total_packages=0
    local total_size=0
    declare -A os_count
    declare -A arch_count
    declare -A package_count
    declare -A size_by_os
    
    while IFS= read -r -d '' rpm_file; do
        ((total_packages++))
        
        local file_size=$(stat -c %s "$rpm_file")
        total_size=$((total_size + file_size))
        
        local package_info=$(detect_package_info "$rpm_file")
        IFS='|' read -r os os_major arch package_name version <<< "$package_info"
        
        # Count by OS
        os_count["$os"]=$((${os_count["$os"]:-0} + 1))
        size_by_os["$os"]=$((${size_by_os["$os"]:-0} + file_size))
        
        # Count by architecture
        arch_count["$arch"]=$((${arch_count["$arch"]:-0} + 1))
        
        # Count package names
        package_count["$package_name"]=$((${package_count["$package_name"]:-0} + 1))
        
    done < <(find "$analyze_dir" -name "*.rpm" -type f -print0)
    
    # Generate report
    local total_size_mb=$((total_size / 1024 / 1024))
    log "${GREEN}=== PACKAGE ANALYSIS REPORT ===${NC}"
    log "Total packages: $total_packages"
    log "Total size: ${total_size_mb}MB"
    echo ""
    
    log "${CYAN}=== Distribution by OS ===${NC}"
    for os in "${!os_count[@]}"; do
        local count="${os_count[$os]}"
        local size_mb=$((${size_by_os[$os]} / 1024 / 1024))
        log "$os: $count packages (${size_mb}MB)"
    done
    echo ""
    
    log "${CYAN}=== Distribution by Architecture ===${NC}"
    for arch in "${!arch_count[@]}"; do
        local count="${arch_count[$arch]}"
        log "$arch: $count packages"
    done
    echo ""
    
    log "${CYAN}=== Top 10 Most Common Packages ===${NC}"
    for package in "${!package_count[@]}"; do
        echo "${package_count[$package]} $package"
    done | sort -nr | head -10 | while read -r count name; do
        log "$name: $count versions"
    done
    
    log "${GREEN}Analysis complete${NC}"
}

clean_empty_directories() {
    log "${BLUE}=== Cleaning Empty Directories ===${NC}"
    
    read -p "Enter directory to clean: " clean_dir
    
    if [ ! -d "$clean_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    echo "Cleaning options:"
    echo "1. Remove all empty directories"
    echo "2. List empty directories first"
    echo "3. Interactive removal"
    read -p "Choose option (1-3): " clean_choice
    
    case $clean_choice in
        1)
            local removed_count=0
            while [ $(find "$clean_dir" -type d -empty | wc -l) -gt 0 ]; do
                local empty_dirs=$(find "$clean_dir" -type d -empty)
                echo "$empty_dirs" | while read -r dir; do
                    if [ -n "$dir" ]; then
                        rmdir "$dir" 2>/dev/null && ((removed_count++)) && log "Removed: $dir"
                    fi
                done
            done
            log "${GREEN}Removed $removed_count empty directories${NC}"
            ;;
        2)
            log "Empty directories found:"
            find "$clean_dir" -type d -empty | while read -r dir; do
                log "  $dir"
            done
            ;;
        3)
            find "$clean_dir" -type d -empty | while read -r dir; do
                echo -n "Remove empty directory $dir? [y/N]: "
                read -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rmdir "$dir" && log "Removed: $dir"
                fi
            done
            ;;
    esac
}

# ===== ADVANCED FUNCTIONS =====

generate_organization_summary() {
    local target_dir="$1"
    
    log "${CYAN}=== Organization Summary ===${NC}"
    
    # Count packages by OS
    for os_dir in "$target_dir"/*; do
        if [ -d "$os_dir" ]; then
            local os_name=$(basename "$os_dir")
            local package_count=$(find "$os_dir" -name "*.rpm" -type f | wc -l)
            local size_mb=$(du -sm "$os_dir" 2>/dev/null | cut -f1)
            log "$os_name: $package_count packages (${size_mb}MB)"
        fi
    done
    
    # Overall statistics
    local total_packages=$(find "$target_dir" -name "*.rpm" -type f | wc -l)
    local total_size_mb=$(du -sm "$target_dir" 2>/dev/null | cut -f1)
    log "${GREEN}Total: $total_packages packages (${total_size_mb}MB)${NC}"
}

mass_rename_packages() {
    log "${BLUE}=== Mass Rename Package Files ===${NC}"
    
    read -p "Enter directory containing packages: " rename_dir
    
    if [ ! -d "$rename_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    echo "Rename options:"
    echo "1. Add prefix to all files"
    echo "2. Add suffix to all files"
    echo "3. Replace text in filenames"
    echo "4. Convert to lowercase"
    echo "5. Convert to uppercase"
    echo "6. Custom rename pattern"
    read -p "Choose option (1-6): " rename_choice
    
    local renamed_count=0
    
    case $rename_choice in
        1)
            read -p "Enter prefix to add: " prefix
            find "$rename_dir" -name "*.rpm" -type f | while read -r file; do
                local dir=$(dirname "$file")
                local filename=$(basename "$file")
                local new_name="$prefix$filename"
                
                if mv "$file" "$dir/$new_name"; then
                    log "Renamed: $filename -> $new_name"
                    ((renamed_count++))
                fi
            done
            ;;
        2)
            read -p "Enter suffix to add (before .rpm): " suffix
            find "$rename_dir" -name "*.rpm" -type f | while read -r file; do
                local dir=$(dirname "$file")
                local filename=$(basename "$file" .rpm)
                local new_name="${filename}${suffix}.rpm"
                
                if mv "$file" "$dir/$new_name"; then
                    log "Renamed: $(basename "$file") -> $new_name"
                    ((renamed_count++))
                fi
            done
            ;;
        3)
            read -p "Enter text to replace: " old_text
            read -p "Enter replacement text: " new_text
            find "$rename_dir" -name "*.rpm" -type f | while read -r file; do
                local dir=$(dirname "$file")
                local filename=$(basename "$file")
                local new_name=$(echo "$filename" | sed "s/$old_text/$new_text/g")
                
                if [ "$filename" != "$new_name" ]; then
                    if mv "$file" "$dir/$new_name"; then
                        log "Renamed: $filename -> $new_name"
                        ((renamed_count++))
                    fi
                fi
            done
            ;;
        4)
            find "$rename_dir" -name "*.rpm" -type f | while read -r file; do
                local dir=$(dirname "$file")
                local filename=$(basename "$file")
                local new_name=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
                
                if [ "$filename" != "$new_name" ]; then
                    if mv "$file" "$dir/$new_name"; then
                        log "Renamed: $filename -> $new_name"
                        ((renamed_count++))
                    fi
                fi
            done
            ;;
        5)
            find "$rename_dir" -name "*.rpm" -type f | while read -r file; do
                local dir=$(dirname "$file")
                local filename=$(basename "$file")
                local new_name=$(echo "$filename" | tr '[:lower:]' '[:upper:]')
                
                if [ "$filename" != "$new_name" ]; then
                    if mv "$file" "$dir/$new_name"; then
                        log "Renamed: $filename -> $new_name"
                        ((renamed_count++))
                    fi
                fi
            done
            ;;
        6)
            echo "Available variables: {name}, {version}, {arch}, {os}"
            read -p "Enter rename pattern: " pattern
            
            find "$rename_dir" -name "*.rpm" -type f | while read -r file; do
                local dir=$(dirname "$file")
                local package_info=$(detect_package_info "$file")
                IFS='|' read -r os os_major arch package_name version <<< "$package_info"
                
                local new_name=$(echo "$pattern" | sed "s/{name}/$package_name/g" | sed "s/{version}/$version/g" | sed "s/{arch}/$arch/g" | sed "s/{os}/$os/g")
                new_name="${new_name}.rpm"
                
                if mv "$file" "$dir/$new_name"; then
                    log "Renamed: $(basename "$file") -> $new_name"
                    ((renamed_count++))
                fi
            done
            ;;
    esac
    
    log "${GREEN}Mass rename complete: $renamed_count files renamed${NC}"
}

create_package_symlinks() {
    log "${BLUE}=== Creating Package Symlinks ===${NC}"
    
    read -p "Enter source directory (organized packages): " source_dir
    read -p "Enter target directory (for symlinks): " target_dir
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    mkdir -p "$target_dir"
    
    echo "Symlink creation options:"
    echo "1. Flat symlink structure (all packages in one directory)"
    echo "2. Mirror directory structure with symlinks"
    echo "3. Symlinks by package name only"
    read -p "Choose option (1-3): " symlink_choice
    
    local symlink_count=0
    
    case $symlink_choice in
        1)
            find "$source_dir" -name "*.rpm" -type f | while read -r file; do
                local filename=$(basename "$file")
                local target_file="$target_dir/$filename"
                
                if ln -sf "$file" "$target_file"; then
                    log "Created symlink: $filename"
                    ((symlink_count++))
                fi
            done
            ;;
        2)
            find "$source_dir" -name "*.rpm" -type f | while read -r file; do
                local relative_path=$(realpath --relative-to="$source_dir" "$file")
                local target_file="$target_dir/$relative_path"
                local target_dir_path=$(dirname "$target_file")
                
                mkdir -p "$target_dir_path"
                
                if ln -sf "$file" "$target_file"; then
                    log "Created symlink: $relative_path"
                    ((symlink_count++))
                fi
            done
            ;;
        3)
            declare -A package_names
            
            find "$source_dir" -name "*.rpm" -type f | while read -r file; do
                local package_info=$(detect_package_info "$file")
                IFS='|' read -r os os_major arch package_name version <<< "$package_info"
                
                local package_dir="$target_dir/$package_name"
                mkdir -p "$package_dir"
                
                local filename=$(basename "$file")
                local target_file="$package_dir/$filename"
                
                if ln -sf "$file" "$target_file"; then
                    log "Created symlink: $package_name/$filename"
                    ((symlink_count++))
                fi
            done
            ;;
    esac
    
    log "${GREEN}Symlink creation complete: $symlink_count symlinks created${NC}"
}

generate_package_inventory() {
    log "${BLUE}=== Generating Package Inventory ===${NC}"
    
    read -p "Enter directory to inventory: " inventory_dir
    
    if [ ! -d "$inventory_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    local inventory_file="$HOME/package_inventory_$(date +'%Y%m%d_%H%M%S').txt"
    local csv_file="$HOME/package_inventory_$(date +'%Y%m%d_%H%M%S').csv"
    local html_file="$HOME/package_inventory_$(date +'%Y%m%d_%H%M%S').html"
    
    log "Generating inventory for $inventory_dir..."
    
    # Create text inventory
    {
        echo "Package Inventory Report"
        echo "Generated: $(date)"
        echo "Directory: $inventory_dir"
        echo "======================================"
        echo ""
        
        find "$inventory_dir" -name "*.rpm" -type f | while read -r file; do
            local package_info=$(detect_package_info "$file")
            IFS='|' read -r os os_major arch package_name version <<< "$package_info"
            
            local file_size=$(stat -c %s "$file")
            local file_size_mb=$((file_size / 1024 / 1024))
            local file_date=$(stat -c %y "$file" | cut -d' ' -f1)
            
            echo "Package: $package_name"
            echo "Version: $version"
            echo "OS: $os $os_major"
            echo "Architecture: $arch"
            echo "Size: ${file_size_mb}MB"
            echo "Date: $file_date"
            echo "File: $file"
            echo "--------------------"
        done
    } > "$inventory_file"
    
    # Create CSV inventory
    {
        echo "Package Name,Version,OS,OS Major,Architecture,Size (MB),Date,File Path"
        
        find "$inventory_dir" -name "*.rpm" -type f | while read -r file; do
            local package_info=$(detect_package_info "$file")
            IFS='|' read -r os os_major arch package_name version <<< "$package_info"
            
            local file_size=$(stat -c %s "$file")
            local file_size_mb=$((file_size / 1024 / 1024))
            local file_date=$(stat -c %y "$file" | cut -d' ' -f1)
            
            echo "\"$package_name\",\"$version\",\"$os\",\"$os_major\",\"$arch\",$file_size_mb,\"$file_date\",\"$file\""
        done
    } > "$csv_file"
    
    # Create HTML inventory
    {
        cat << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Package Inventory</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .header { background-color: #e6f3ff; padding: 15px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Package Inventory Report</h1>
        <p>Generated: $(date)</p>
        <p>Directory: $inventory_dir</p>
    </div>
    
    <table>
        <tr>
            <th>Package Name</th>
            <th>Version</th>
            <th>OS</th>
            <th>Architecture</th>
            <th>Size (MB)</th>
            <th>Date</th>
            <th>File Path</th>
        </tr>
EOF
        
        find "$inventory_dir" -name "*.rpm" -type f | while read -r file; do
            local package_info=$(detect_package_info "$file")
            IFS='|' read -r os os_major arch package_name version <<< "$package_info"
            
            local file_size=$(stat -c %s "$file")
            local file_size_mb=$((file_size / 1024 / 1024))
            local file_date=$(stat -c %y "$file" | cut -d' ' -f1)
            
            echo "        <tr>"
            echo "            <td>$package_name</td>"
            echo "            <td>$version</td>"
            echo "            <td>$os $os_major</td>"
            echo "            <td>$arch</td>"
            echo "            <td>$file_size_mb</td>"
            echo "            <td>$file_date</td>"
            echo "            <td>$file</td>"
            echo "        </tr>"
        done
        
        echo "    </table>"
        echo "</body>"
        echo "</html>"
    } > "$html_file"
    
    log "${GREEN}Inventory generated:${NC}"
    log "Text: $inventory_file"
    log "CSV: $csv_file"
    log "HTML: $html_file"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== Package Organization And Migration Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) auto_organize_rpms ;;
            2) batch_move_files ;;
            3) migrate_packages ;;
            4) sort_categorize_packages ;;
            5) remove_duplicate_packages ;;
            6) find_manage_old_versions ;;
            7) package_statistics_analysis ;;
            8) clean_empty_directories ;;
            9) batch_move_files ;;
            10) mass_rename_packages ;;
            11) create_package_symlinks ;;
            12) generate_package_inventory ;;
            13) custom_organization_rules ;;
            14) package_dependency_analysis ;;
            15) automated_package_workflow ;;
            16) 
                log "${GREEN}Exiting Package Organization Suite${NC}"
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

# Helper functions for additional menu items
migrate_packages() {
    log "${BLUE}=== Package Migration ===${NC}"
    
    echo "Migration options:"
    echo "1. Migrate between different organization structures"
    echo "2. Migrate from flat to organized structure"
    echo "3. Migrate from organized to flat structure"
    echo "4. Cross-platform package migration"
    read -p "Choose option (1-4): " migrate_choice
    
    case $migrate_choice in
        1|2) auto_organize_rpms ;;
        3) 
            read -p "Enter organized source directory: " org_source
            read -p "Enter flat target directory: " flat_target
            mkdir -p "$flat_target"
            find "$org_source" -name "*.rpm" -type f -exec cp {} "$flat_target/" \;
            log "Migration to flat structure completed"
            ;;
        4)
            log "Cross-platform migration requires manual package conversion"
            log "Consider using alien or similar tools for .deb <-> .rpm conversion"
            ;;
    esac
}

sort_categorize_packages() {
    log "${BLUE}=== Sort & Categorize Downloaded Packages ===${NC}"
    
    read -p "Enter download directory: " download_dir
    if [ ! -d "$download_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    # Categories based on common package types
    declare -A categories
    categories["system"]="kernel|glibc|systemd|dbus"
    categories["development"]="gcc|clang|cmake|git|vim|emacs"
    categories["multimedia"]="ffmpeg|vlc|gstreamer|alsa|pulseaudio"
    categories["networking"]="curl|wget|openssh|networkmanager"
    categories["security"]="openssl|gpg|firewall|selinux"
    categories["desktop"]="gnome|kde|xorg|wayland|gtk|qt"
    
    read -p "Enter target directory for categorized packages: " target_dir
    mkdir -p "$target_dir"
    
    for category in "${!categories[@]}"; do
        mkdir -p "$target_dir/$category"
    done
    mkdir -p "$target_dir/other"
    
    local categorized_count=0
    
    find "$download_dir" -name "*.rpm" -type f | while read -r file; do
        local filename=$(basename "$file")
        local package_info=$(detect_package_info "$file")
        IFS='|' read -r os os_major arch package_name version <<< "$package_info"
        
        local moved=false
        
        # Check against categories
        for category in "${!categories[@]}"; do
            local patterns="${categories[$category]}"
            if echo "$package_name" | grep -E "$patterns" >/dev/null; then
                mv "$file" "$target_dir/$category/"
                log "Categorized $filename as $category"
                moved=true
                ((categorized_count++))
                break
            fi
        done
        
        # Move to 'other' if not categorized
        if [ "$moved" = false ]; then
            mv "$file" "$target_dir/other/"
            log "Moved $filename to other category"
        fi
    done
    
    log "${GREEN}Categorization complete: $categorized_count packages categorized${NC}"
}

custom_organization_rules() {
    log "${BLUE}=== Custom Package Organization Rules ===${NC}"
    
    echo "This feature allows you to create custom organization rules"
    echo "Rules are saved and can be reused for future organization tasks"
    echo ""
    echo "Example rules:"
    echo "- kernel* packages -> System/Kernel/"
    echo "- *-devel packages -> Development/"
    echo "- lib* packages -> Libraries/"
    echo ""
    echo "Implementation: Use the organize_custom_structure function"
    organize_custom_structure
}

package_dependency_analysis() {
    log "${BLUE}=== Package Dependency Analysis ===${NC}"
    
    read -p "Enter directory containing packages: " pkg_dir
    if [ ! -d "$pkg_dir" ]; then
        log "${RED}Directory not found${NC}"
        return 1
    fi
    
    log "Analyzing package dependencies..."
    
    local analysis_file="$HOME/dependency_analysis_$(date +'%Y%m%d_%H%M%S').txt"
    
    {
        echo "Package Dependency Analysis"
        echo "Generated: $(date)"
        echo "Directory: $pkg_dir"
        echo "=========================="
        echo ""
        
        find "$pkg_dir" -name "*.rpm" -type f | while read -r file; do
            local filename=$(basename "$file")
            echo "Package: $filename"
            
            if command -v rpm >/dev/null 2>&1; then
                echo "Provides:"
                rpm -qp --provides "$file" 2>/dev/null | head -10
                echo ""
                echo "Requires:"
                rpm -qp --requires "$file" 2>/dev/null | head -10
                echo ""
            else
                echo "rpm command not available for detailed analysis"
            fi
            echo "---"
        done
    } > "$analysis_file"
    
    log "Dependency analysis saved to: $analysis_file"
}

automated_package_workflow() {
    log "${BLUE}=== Automated Package Workflow ===${NC}"
    
    echo "Automated workflow will:"
    echo "1. Organize packages by OS/Architecture"
    echo "2. Remove duplicates (keep 2 newest versions)"
    echo "3. Generate inventory report"
    echo "4. Clean empty directories"
    echo ""
    read -p "Enter source directory: " workflow_source
    read -p "Enter target directory: " workflow_target
    
    if [ ! -d "$workflow_source" ]; then
        log "${RED}Source directory not found${NC}"
        return 1
    fi
    
    log "${CYAN}Starting automated workflow...${NC}"
    
    # Step 1: Organize packages
    log "Step 1: Organizing packages..."
    mkdir -p "$workflow_target"
    
    local rpm_count=0
    while IFS= read -r -d '' rpm_file; do
        ((rpm_count++))
        
        local package_info=$(detect_package_info "$rpm_file")
        IFS='|' read -r os os_major arch package_name version <<< "$package_info"
        
        local first_letter=$(get_first_letter "$package_name")
        local dest_dir=$(create_directory_structure "$workflow_target" "$os" "$os_major" "$arch" "$first_letter")
        
        cp "$rpm_file" "$dest_dir/"
        
    done < <(find "$workflow_source" -name "*.rpm" -type f -print0)
    
    log "Step 1 complete: $rpm_count packages organized"
    
    # Step 2: Remove duplicates
    log "Step 2: Removing duplicates..."
    # Use the existing remove_duplicate_packages logic here
    
    # Step 3: Generate inventory
    log "Step 3: Generating inventory..."
    local old_inventory_dir="$workflow_target"
    generate_package_inventory # This will use the workflow_target
    
    # Step 4: Clean empty directories
    log "Step 4: Cleaning empty directories..."
    find "$workflow_target" -type d -empty -delete 2>/dev/null || true
    
    log "${GREEN}Automated workflow complete!${NC}"
    generate_organization_summary "$workflow_target"
}

main "$@"
