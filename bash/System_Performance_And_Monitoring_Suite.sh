#!/bin/bash

# System Performance And Monitoring Suite
# Comprehensive system performance analysis, optimization, and monitoring toolkit
# Consolidates: Optimize_System_Performance.sh, system_monitor.sh, performance_tuning.sh

set -euo pipefail

LOG_FILE="$HOME/system_performance_$(date +'%Y%m%d_%H%M%S').log"

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
    echo
    echo
    echo
    echo
    echo ""
}

show_main_menu() {
    echo
    echo ""
    echo " SYSTEM MONITORING:"
    echo "1.  Real-time System Monitor"
    echo "2.  Performance Dashboard"
    echo "3.  Resource Usage Analysis"
    echo "4.   Temperature & Hardware Monitor"
    echo ""
    echo " PERFORMANCE OPTIMIZATION:"
    echo "5.  Quick System Optimization"
    echo "6.  Advanced Performance Tuning"
    echo "7.  Memory Optimization"
    echo "8.  Storage Performance Tuning"
    echo ""
    echo " ANALYSIS & BENCHMARKING:"
    echo "9.  System Benchmark Suite"
    echo "10.  Performance Bottleneck Analysis"
    echo "11.  Generate Performance Report"
    echo "12.  Process Analysis & Management"
    echo ""
    echo "  SYSTEM CONFIGURATION:"
    echo "13.   Kernel Parameter Tuning"
    echo "14.  Service Optimization"
    echo "15.   Filesystem Optimization"
    echo "16.  Exit"
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

get_system_info() {
    log "${CYAN}=== System Information ===${NC}"
    
    # Basic system info
    echo "Hostname: $(hostname)" | tee -a "$LOG_FILE"
    echo "Kernel: $(uname -r)" | tee -a "$LOG_FILE"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)" | tee -a "$LOG_FILE"
    echo "Uptime: $(uptime -p)" | tee -a "$LOG_FILE"
    
    # Hardware info
    echo "" | tee -a "$LOG_FILE"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)" | tee -a "$LOG_FILE"
    echo "CPU Cores: $(nproc)" | tee -a "$LOG_FILE"
    echo "Memory: $(free -h | grep Mem | awk '{print $2}')" | tee -a "$LOG_FILE"
    echo "Storage: $(df -h / | tail -1 | awk '{print $2}')" | tee -a "$LOG_FILE"
}

format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [ $bytes -gt 1024 ] && [ $unit -lt 4 ]; do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done
    
    echo "$bytes${units[$unit]}"
}

# ===== SYSTEM MONITORING =====

real_time_system_monitor() {
    log "${BLUE}=== Real-time System Monitor ===${NC}"
    
    # Install required tools
    install_package_if_missing "htop"
    install_package_if_missing "iotop"
    install_package_if_missing "nethogs"
    
    echo "Real-time monitoring options:"
    echo "1.  CPU & Memory Monitor (htop)"
    echo "2.  Disk I/O Monitor (iotop)"
    echo "3.  Network Monitor (nethogs)"
    echo "4.  All-in-one Dashboard"
    echo "5.  Continuous Monitoring (5 min)"
    read -p "Choose monitoring type (1-5): " monitor_choice
    
    case $monitor_choice in
        1)
            log "Starting CPU & Memory monitor..."
            if command -v htop >/dev/null 2>&1; then
                htop
            else
                top
            fi
            ;;
        2)
            log "Starting Disk I/O monitor..."
            if command -v iotop >/dev/null 2>&1; then
                sudo iotop
            else
                iostat -x 1 2>/dev/null || log "${YELLOW}iostat not available${NC}"
            fi
            ;;
        3)
            log "Starting Network monitor..."
            if command -v nethogs >/dev/null 2>&1; then
                sudo nethogs
            else
                log "${YELLOW}nethogs not available${NC}"
                netstat -i 2>/dev/null || ss -i 2>/dev/null || log "No network monitoring tools available"
            fi
            ;;
        4)
            log "Starting comprehensive monitoring dashboard..."
            
            # Create temporary monitoring script
            local monitor_script="/tmp/system_monitor.sh"
            cat > "$monitor_script" << 'EOF'
#!/bin/bash

while true; do
    clear
    echo "=== SYSTEM PERFORMANCE DASHBOARD ==="
    echo "Updated: $(date)"
    echo ""
    
    # CPU Usage
    echo "CPU Usage:"
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage "%"}'
    echo ""
    
    # Memory Usage
    echo "Memory Usage:"
    free -h | grep -E "Mem|Swap"
    echo ""
    
    # Load Average
    echo "Load Average:"
    uptime | cut -d',' -f3-
    echo ""
    
    # Top Processes by CPU
    echo "Top 5 CPU Processes:"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6
    echo ""
    
    # Top Processes by Memory
    echo "Top 5 Memory Processes:"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -6
    echo ""
    
    # Disk Usage
    echo "Disk Usage:"
    df -h | grep -vE "^Filesystem|tmpfs|cdrom"
    echo ""
    
    # Network Statistics
    echo "Network Statistics:"
    cat /proc/net/dev | grep -E "eth|wlan|enp" | head -3
    echo ""
    
    echo "Press Ctrl+C to exit"
    sleep 5
done
EOF
            
            chmod +x "$monitor_script"
            bash "$monitor_script"
            rm -f "$monitor_script"
            ;;
        5)
            log "Starting 5-minute continuous monitoring..."
            
            local start_time=$(date +%s)
            local end_time=$((start_time + 300))  # 5 minutes
            
            echo "Monitoring system for 5 minutes..."
            echo "Data will be logged to: $LOG_FILE"
            
            while [ $(date +%s) -lt $end_time ]; do
                {
                    echo "=== $(date) ==="
                    echo "CPU: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage "%"}')"
                    echo "Memory: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
                    echo "Load: $(uptime | cut -d',' -f3-)"
                    echo "Disk I/O: $(iostat -d 1 1 2>/dev/null | tail -1 || echo 'N/A')"
                    echo ""
                } >> "$LOG_FILE"
                
                sleep 30
            done
            
            log "Monitoring completed"
            ;;
    esac
    
    log "${GREEN}System monitoring completed${NC}"
}

performance_dashboard() {
    log "${BLUE}=== Performance Dashboard ===${NC}"
    
    get_system_info
    
    log "${CYAN}=== Current Performance Metrics ===${NC}"
    
    # CPU Information
    echo "CPU Information:" | tee -a "$LOG_FILE"
    echo "  Model: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)" | tee -a "$LOG_FILE"
    echo "  Cores: $(nproc)" | tee -a "$LOG_FILE"
    echo "  Current Usage: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {printf "%.1f%%", usage}')" | tee -a "$LOG_FILE"
    echo "  Load Average: $(uptime | cut -d',' -f3-)" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Memory Information
    echo "Memory Information:" | tee -a "$LOG_FILE"
    free -h | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Storage Information
    echo "Storage Information:" | tee -a "$LOG_FILE"
    df -h | grep -vE "^Filesystem|tmpfs|cdrom" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Network Information
    echo "Network Interfaces:" | tee -a "$LOG_FILE"
    ip addr show | grep -E "^[0-9]+:|inet " | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Process Information
    echo "Top 10 Processes by CPU:" | tee -a "$LOG_FILE"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -11 | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    echo "Top 10 Processes by Memory:" | tee -a "$LOG_FILE"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -11 | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # System Services
    echo "Key System Services:" | tee -a "$LOG_FILE"
    systemctl is-active NetworkManager firewalld sshd 2>/dev/null | paste <(echo -e "NetworkManager\nfirewalld\nsshd") - | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Hardware Temperature (if available)
    if command -v sensors >/dev/null 2>&1; then
        echo "Hardware Temperatures:" | tee -a "$LOG_FILE"
        sensors 2>/dev/null | grep -E "temp|Core" | tee -a "$LOG_FILE" || log "Temperature sensors not available"
        echo "" | tee -a "$LOG_FILE"
    fi
    
    log "${GREEN}Performance dashboard completed${NC}"
}

resource_usage_analysis() {
    log "${BLUE}=== Resource Usage Analysis ===${NC}"
    
    echo "Resource analysis options:"
    echo "1.  CPU Usage Analysis"
    echo "2.  Memory Usage Analysis"
    echo "3.  Disk Usage Analysis"
    echo "4.  Network Usage Analysis"
    echo "5.  Complete Resource Analysis"
    read -p "Choose analysis type (1-5): " analysis_choice
    
    case $analysis_choice in
        1)
            log "Analyzing CPU usage..."
            
            echo "CPU Analysis Results:" | tee -a "$LOG_FILE"
            echo "===================" | tee -a "$LOG_FILE"
            
            # CPU model and specs
            lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket" | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Current CPU usage
            echo "Current CPU Usage:" | tee -a "$LOG_FILE"
            top -bn1 | grep "Cpu(s)" | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Top CPU consumers
            echo "Top CPU Consuming Processes:" | tee -a "$LOG_FILE"
            ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -10 | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # CPU frequency
            if [ -f /proc/cpuinfo ]; then
                echo "CPU Frequencies:" | tee -a "$LOG_FILE"
                grep "cpu MHz" /proc/cpuinfo | head -4 | tee -a "$LOG_FILE"
            fi
            ;;
        2)
            log "Analyzing memory usage..."
            
            echo "Memory Analysis Results:" | tee -a "$LOG_FILE"
            echo "======================" | tee -a "$LOG_FILE"
            
            # Memory overview
            free -h | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Detailed memory info
            echo "Detailed Memory Information:" | tee -a "$LOG_FILE"
            cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree" | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Top memory consumers
            echo "Top Memory Consuming Processes:" | tee -a "$LOG_FILE"
            ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -10 | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Memory usage percentage
            local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
            local swap_usage=$(free | grep Swap | awk '{if($2>0) printf "%.1f", $3/$2 * 100.0; else print "0"}')
            
            echo "Memory Usage: ${mem_usage}%" | tee -a "$LOG_FILE"
            echo "Swap Usage: ${swap_usage}%" | tee -a "$LOG_FILE"
            
            if (( $(echo "$mem_usage > 80" | bc -l) )); then
                log "${YELLOW}WARNING: High memory usage detected${NC}"
            fi
            ;;
        3)
            log "Analyzing disk usage..."
            
            echo "Disk Analysis Results:" | tee -a "$LOG_FILE"
            echo "====================" | tee -a "$LOG_FILE"
            
            # Disk space usage
            df -h | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Inode usage
            echo "Inode Usage:" | tee -a "$LOG_FILE"
            df -i | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Largest directories
            echo "Largest Directories in /:" | tee -a "$LOG_FILE"
            sudo du -sh /* 2>/dev/null | sort -rh | head -10 | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Disk I/O statistics
            if command -v iostat >/dev/null 2>&1; then
                echo "Disk I/O Statistics:" | tee -a "$LOG_FILE"
                iostat -x 1 1 2>/dev/null | tee -a "$LOG_FILE"
            fi
            ;;
        4)
            log "Analyzing network usage..."
            
            echo "Network Analysis Results:" | tee -a "$LOG_FILE"
            echo "========================" | tee -a "$LOG_FILE"
            
            # Network interfaces
            echo "Network Interfaces:" | tee -a "$LOG_FILE"
            ip addr show | grep -E "^[0-9]+:|inet " | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Network statistics
            echo "Network Statistics:" | tee -a "$LOG_FILE"
            cat /proc/net/dev | head -3 | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Active connections
            echo "Active Network Connections:" | tee -a "$LOG_FILE"
            ss -tuln | head -10 | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            
            # Network processes
            if command -v netstat >/dev/null 2>&1; then
                echo "Processes with Network Activity:" | tee -a "$LOG_FILE"
                netstat -tuln -p 2>/dev/null | grep LISTEN | head -10 | tee -a "$LOG_FILE"
            fi
            ;;
        5)
            log "Performing complete resource analysis..."
            
            # Run all analyses
            resource_usage_analysis() {
                for i in {1..4}; do
                    echo "choice=$i"
                    case $i in
                        1) log "=== CPU Analysis ===" ;;
                        2) log "=== Memory Analysis ===" ;;
                        3) log "=== Disk Analysis ===" ;;
                        4) log "=== Network Analysis ===" ;;
                    esac
                done
            }
            ;;
    esac
    
    log "${GREEN}Resource usage analysis completed${NC}"
}

# ===== PERFORMANCE OPTIMIZATION =====

quick_system_optimization() {
    log "${BLUE}=== Quick System Optimization ===${NC}"
    
    if ! check_root_required; then
        return 1
    fi
    
    log "Performing quick system optimization..."
    
    # Clean package cache
    log "Cleaning package cache..."
    if command -v dnf >/dev/null 2>&1; then
        dnf clean all 2>&1 | tee -a "$LOG_FILE"
    elif command -v yum >/dev/null 2>&1; then
        yum clean all 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Clean temporary files
    log "Cleaning temporary files..."
    find /tmp -type f -atime +7 -delete 2>/dev/null || true
    find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
    
    # Clean log files
    log "Cleaning old log files..."
    journalctl --vacuum-time=7d 2>&1 | tee -a "$LOG_FILE"
    
    # Update locate database
    log "Updating locate database..."
    updatedb 2>/dev/null || log "${YELLOW}updatedb not available${NC}"
    
    # Optimize systemd services
    log "Optimizing systemd services..."
    systemctl daemon-reload
    
    # Enable automatic trim for SSDs
    if [ -b /dev/nvme0n1 ] || [ -b /dev/sda ]; then
        log "Enabling automatic SSD trim..."
        systemctl enable fstrim.timer 2>/dev/null || true
    fi
    
    # Adjust swappiness for better performance
    log "Optimizing swappiness..."
    echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
    sysctl vm.swappiness=10
    
    # Optimize dirty page writeback
    log "Optimizing dirty page writeback..."
    echo 'vm.dirty_ratio=15' >> /etc/sysctl.d/99-performance.conf
    echo 'vm.dirty_background_ratio=5' >> /etc/sysctl.d/99-performance.conf
    sysctl -p /etc/sysctl.d/99-performance.conf
    
    log "${GREEN}Quick optimization completed${NC}"
    log "Reboot recommended for all changes to take effect"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== System Performance And Monitoring Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) real_time_system_monitor ;;
            2) performance_dashboard ;;
            3) resource_usage_analysis ;;
            4) temperature_hardware_monitor ;;
            5) quick_system_optimization ;;
            6) advanced_performance_tuning ;;
            7) memory_optimization ;;
            8) storage_performance_tuning ;;
            9) system_benchmark_suite ;;
            10) bottleneck_analysis ;;
            11) generate_performance_report ;;
            12) process_analysis_management ;;
            13) kernel_parameter_tuning ;;
            14) service_optimization ;;
            15) filesystem_optimization ;;
            16) 
                log "${GREEN}Exiting System Performance Suite${NC}"
                echo
                exit 0
                ;;
            *)
                echo
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Placeholder functions for remaining menu items (to be implemented)
temperature_hardware_monitor() {
    log "${BLUE}=== Temperature & Hardware Monitor ===${NC}"
    log "This feature will monitor hardware temperatures and sensors"
    log "Implementation: lm-sensors, thermal monitoring, fan control"
}

advanced_performance_tuning() {
    log "${BLUE}=== Advanced Performance Tuning ===${NC}"
    log "This feature will perform advanced system tuning"
    log "Implementation: Kernel parameters, scheduler tuning, memory management"
}

memory_optimization() {
    log "${BLUE}=== Memory Optimization ===${NC}"
    log "This feature will optimize memory usage"
    log "Implementation: Swap optimization, memory compression, cache tuning"
}

storage_performance_tuning() {
    log "${BLUE}=== Storage Performance Tuning ===${NC}"
    log "This feature will optimize storage performance"
    log "Implementation: I/O scheduler, filesystem optimization, SSD tuning"
}

system_benchmark_suite() {
    log "${BLUE}=== System Benchmark Suite ===${NC}"
    log "This feature will run comprehensive system benchmarks"
    log "Implementation: CPU, memory, disk, network benchmarks"
}

bottleneck_analysis() {
    log "${BLUE}=== Performance Bottleneck Analysis ===${NC}"
    log "This feature will analyze performance bottlenecks"
    log "Implementation: Resource monitoring, analysis algorithms, recommendations"
}

generate_performance_report() {
    log "${BLUE}=== Generate Performance Report ===${NC}"
    log "This feature will generate comprehensive performance report"
    log "Implementation: System analysis, graphs, recommendations, HTML report"
}

process_analysis_management() {
    log "${BLUE}=== Process Analysis & Management ===${NC}"
    log "This feature will analyze and manage system processes"
    log "Implementation: Process monitoring, resource usage, optimization suggestions"
}

kernel_parameter_tuning() {
    log "${BLUE}=== Kernel Parameter Tuning ===${NC}"
    log "This feature will tune kernel parameters for performance"
    log "Implementation: sysctl optimization, kernel module tuning"
}

service_optimization() {
    log "${BLUE}=== Service Optimization ===${NC}"
    log "This feature will optimize system services"
    log "Implementation: Service analysis, disable unnecessary services, startup optimization"
}

filesystem_optimization() {
    log "${BLUE}=== Filesystem Optimization ===${NC}"
    log "This feature will optimize filesystem performance"
    log "Implementation: Mount options, filesystem tuning, defragmentation"
}

main "$@"
