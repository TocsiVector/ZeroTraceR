#!/usr/bin/env bash
#
# ZeroTraceR - Advanced Linux Recon Tool
# Author: TocsiVector

set -u
set -o pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly TOOL_NAME="ZeroTraceR"
readonly TOOL_VERSION="3.0.1"
readonly TOOL_AUTHOR="TocsiVector"

OUTPUT_FILE=""
REPORT_FILE=""
USE_COLOR=1
WARNINGS_COUNT=0
RISK_COUNT=0
TOTAL_CHECKS=0
PORT_RISK_TEXT="No elevated port exposure detected"
USER_RISK_TEXT="No elevated privilege risk detected"
SUDO_STATUS="Unknown"
ROOT_RISK_FOUND=0
SUDO_RISK_FOUND=0
PORT_RISK_FOUND=0

readonly COLOR_RED=$'\033[0;31m'
readonly COLOR_GREEN=$'\033[0;32m'
readonly COLOR_YELLOW=$'\033[1;33m'
readonly COLOR_BOLD=$'\033[1m'
readonly COLOR_RESET=$'\033[0m'

# Remove the temporary report file when execution ends.
cleanup() {
    if [[ -n "${REPORT_FILE}" && -f "${REPORT_FILE}" ]]; then
        rm -f -- "${REPORT_FILE}"
    fi
}

trap cleanup EXIT

# Disable colors for non-interactive terminals or when explicitly requested.
disable_color_if_needed() {
    if [[ ! -t 1 ]] || [[ "${TERM:-}" == "dumb" ]]; then
        USE_COLOR=0
    fi
}

# Apply ANSI styling only when color output is enabled.
colorize() {
    local color="$1"
    local message="$2"

    if [[ "${USE_COLOR}" -eq 1 ]]; then
        printf '%s%s%s' "${color}" "${message}" "${COLOR_RESET}"
    else
        printf '%s' "${message}"
    fi
}

# Return a simple timestamp for log messages.
timestamp() {
    date '+%H:%M:%S' 2>/dev/null || printf '00:00:00'
}

# Print a green informational status line.
log_info() {
    colorize "${COLOR_GREEN}" "[$(timestamp)] [+] $1"
    printf '\n'
}

# Print a yellow warning line and increment the warning counter.
log_warn() {
    WARNINGS_COUNT=$((WARNINGS_COUNT + 1))
    colorize "${COLOR_YELLOW}" "[$(timestamp)] [!] $1"
    printf '\n' >&2
}

# Print a red error line for fatal or invalid states.
log_error() {
    colorize "${COLOR_RED}" "[$(timestamp)] [!] $1"
    printf '\n' >&2
}

# Append a single line to the temporary report.
append_line() {
    printf '%s\n' "$1" >> "${REPORT_FILE}"
}

# Append a clean section header to the temporary report.
append_header() {
    local title="$1"
    append_line ""
    append_line "================================================================"
    append_line "[ ${title} ]"
    append_line "================================================================"
}

# Render the complete professional help menu.
show_help() {
    cat <<EOF
-------------------------------------
ZeroTraceR - Advanced Linux Recon Tool
-------------------------------------

USAGE:
  ./${SCRIPT_NAME} [OPTIONS]

OPTIONS:
  -o <file>      Save output report to file
  -h             Show this help menu
  --no-color     Disable ANSI color output

DESCRIPTION:
  ZeroTraceR is a Linux system reconnaissance tool designed for
  post-exploitation enumeration, security validation, and
  system analysis in authorized environments.

FEATURES:
  [*] OS and kernel detection
  [*] User and privilege enumeration
  [*] Process and service discovery
  [*] Open port detection
  [*] Network interface mapping
  [*] Installed package inventory
  [*] Risk indicators for root, sudo, and exposed ports

EXAMPLES:
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} -o report.txt
  ./${SCRIPT_NAME} --no-color

OUTPUT:
  Displays structured reconnaissance data in the terminal and
  optionally saves the full report to the specified file.

NOTES:
  - Some data may require root privileges for complete visibility
  - Missing commands are handled gracefully with warnings
  - Designed for authorized security testing and lab environments only
EOF
}

# Parse CLI arguments including long-form color control.
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -o)
                if [[ $# -lt 2 ]]; then
                    log_error "Option -o requires a filename."
                    show_help
                    exit 1
                fi
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -o*)
                log_error "Use -o <file> with a space before the filename."
                show_help
                exit 1
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --no-color)
                USE_COLOR=0
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                log_error "Invalid option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ "$#" -gt 0 ]]; then
        log_error "Unexpected argument(s): $*"
        show_help
        exit 1
    fi
}

# Check whether a command exists before using it.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create the temporary report file used during collection.
initialize_report() {
    REPORT_FILE="$(mktemp "${TMPDIR:-/tmp}/zerotracer.XXXXXX")" || {
        log_error "Unable to create temporary report file."
        exit 1
    }
}

# Validate that the requested report directory exists.
validate_output_target() {
    if [[ -z "${OUTPUT_FILE}" ]]; then
        return 0
    fi

    local output_dir
    output_dir="$(dirname "${OUTPUT_FILE}")"

    if [[ ! -d "${output_dir}" ]]; then
        log_error "Output directory does not exist: ${output_dir}"
        exit 1
    fi
}

# Format aligned key/value pairs inside the report.
append_kv() {
    local key="$1"
    local value="$2"
    append_line "$(printf '%-16s : %s' "${key}" "${value}")"
}

# Increase the risk counter when a risk condition is found.
add_risk() {
    RISK_COUNT=$((RISK_COUNT + 1))
}

# Clear the terminal for a cleaner full-screen operator experience.
clear_screen() {
    if [[ -t 1 ]]; then
        command_exists clear && clear
    fi
}

# Print the cyber-style banner and tool metadata.
print_banner() {
    printf '\n'
    colorize "${COLOR_GREEN}" "  ______                  ______                  ______"
    printf '\n'
    colorize "${COLOR_GREEN}" " /__  /___  _________    /_  __/________ ________/ ____/"
    printf '\n'
    colorize "${COLOR_GREEN}" "   / / __ \\/ ___/ __ \\    / / / ___/ __ \`/ ___/ _ \\/ /"
    printf '\n'
    colorize "${COLOR_GREEN}" "  / / /_/ / /  / /_/ /   / / / /  / /_/ / /__/  __/ /___"
    printf '\n'
    colorize "${COLOR_GREEN}" " /_/\\____/_/   \\____/   /_/ /_/   \\__,_/\\___/\\___/\\____/"
    printf '\n\n'
    colorize "${COLOR_BOLD}" " ${TOOL_NAME} v${TOOL_VERSION}"
    printf '\n'
    colorize "${COLOR_GREEN}" " Author : ${TOOL_AUTHOR}"
    printf '\n'
    colorize "${COLOR_GREEN}" " Theme  : Neon Green Offensive Recon Interface"
    printf '\n'
    printf '%s\n\n' "================================================================"
}

# Pause briefly so status messages feel deliberate without being noisy.
scan_delay() {
    if [[ -t 1 ]]; then
        sleep 0.08
    fi
}

# Write base metadata into the report before section collection begins.
write_report_prelude() {
    append_line "${TOOL_NAME} Reconnaissance Report"
    append_line "Version : ${TOOL_VERSION}"
    append_line "Author  : ${TOOL_AUTHOR}"
    append_line "Date    : $(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date)"
}

# Detect likely sudo-capable access for the current user.
detect_sudo_status() {
    local groups_value="$1"

    if [[ "${EUID:-99999}" -eq 0 ]]; then
        printf 'root'
        return 0
    fi

    case " ${groups_value} " in
        *" sudo "*|*" wheel "*|*" admin "*)
            printf 'group-based sudo access likely'
            return 0
            ;;
    esac

    if command_exists sudo && sudo -n -l >/dev/null 2>&1; then
        printf 'sudo access confirmed'
        return 0
    fi

    printf 'no direct sudo evidence'
}

# Collect operating system details and host identity information.
collect_os_details() {
    append_header "OS DETAILS"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local hostname_value os_value kernel_value uptime_value
    hostname_value="Unavailable"
    os_value="Unavailable"
    kernel_value="Unavailable"
    uptime_value="Unavailable"

    command_exists hostname && hostname_value="$(hostname 2>/dev/null || printf 'Unavailable')"

    if [[ -r /etc/os-release ]]; then
        os_value="$(awk -F= '/^PRETTY_NAME=/{gsub(/"/, "", $2); print $2}' /etc/os-release 2>/dev/null)"
    elif command_exists lsb_release; then
        os_value="$(lsb_release -ds 2>/dev/null || printf 'Unavailable')"
    elif command_exists uname; then
        os_value="$(uname -s 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "Unable to determine operating system details."
    fi

    if command_exists uname; then
        kernel_value="$(uname -r 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "uname command not available."
    fi

    if command_exists uptime; then
        uptime_value="$(uptime -p 2>/dev/null || uptime 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "uptime command not available."
    fi

    append_kv "Hostname" "${hostname_value}"
    append_kv "OS" "${os_value:-Unavailable}"
    append_kv "Kernel" "${kernel_value}"
    append_kv "Uptime" "${uptime_value}"
    return 0
}

# Collect current user context and privilege information.
collect_current_user() {
    append_header "CURRENT USER"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local username_value id_value groups_value privilege_value risk_value
    username_value="${USER:-Unavailable}"
    id_value="Unavailable"
    groups_value="Unavailable"
    privilege_value="standard user"
    risk_value="LOW"

    if command_exists id; then
        username_value="$(id -un 2>/dev/null || printf '%s' "${username_value}")"
        id_value="$(id 2>/dev/null || printf 'Unavailable')"
        groups_value="$(id -nG 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "id command not available; user context may be incomplete."
    fi

    if [[ "${EUID:-99999}" -eq 0 ]]; then
        privilege_value="root"
        risk_value="[!] ROOT USER DETECTED"
        USER_RISK_TEXT="Root execution context detected"
        if [[ "${ROOT_RISK_FOUND}" -eq 0 ]]; then
            add_risk
            ROOT_RISK_FOUND=1
        fi
    fi

    SUDO_STATUS="$(detect_sudo_status "${groups_value}")"
    if [[ "${SUDO_STATUS}" == "sudo access confirmed" || "${SUDO_STATUS}" == "group-based sudo access likely" ]]; then
        risk_value="[!] SUDO-CAPABLE ACCOUNT"
        USER_RISK_TEXT="Privileged account with sudo-equivalent access detected"
        if [[ "${SUDO_RISK_FOUND}" -eq 0 ]]; then
            add_risk
            SUDO_RISK_FOUND=1
        fi
    fi

    append_kv "User" "${username_value}"
    append_kv "Identity" "${id_value}"
    append_kv "Groups" "${groups_value}"
    append_kv "Privileges" "${privilege_value}"
    append_kv "Sudo Status" "${SUDO_STATUS}"
    append_kv "Risk" "${risk_value}"
    return 0
}

# Enumerate all local users using the best available source.
collect_all_users() {
    append_header "ALL USERS"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if command_exists getent; then
        append_line "Source           : getent passwd"
        if getent passwd | awk -F: '{printf "%-16s : uid=%s gid=%s shell=%s\n", $1, $3, $4, $7}' >> "${REPORT_FILE}" 2>/dev/null; then
            return 0
        fi
        log_warn "getent user enumeration failed."
    fi

    if [[ -r /etc/passwd ]]; then
        append_line "Source           : /etc/passwd"
        if awk -F: '{printf "%-16s : uid=%s gid=%s shell=%s\n", $1, $3, $4, $7}' /etc/passwd >> "${REPORT_FILE}" 2>/dev/null; then
            return 0
        fi
        log_warn "Unable to read /etc/passwd."
    fi

    append_line "[!] No supported method available to enumerate users."
    return 1
}

# Collect process listings from ps with fallback output format.
collect_processes() {
    append_header "RUNNING PROCESSES"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if ! command_exists ps; then
        append_line "[!] ps command not available."
        log_warn "ps command not available."
        return 1
    fi

    append_line "Source           : ps"
    if ps auxww >> "${REPORT_FILE}" 2>&1; then
        return 0
    fi

    append_line "[!] Primary process listing failed; attempting fallback."
    if ps -ef >> "${REPORT_FILE}" 2>&1; then
        return 0
    fi

    append_line "[!] Unable to capture running processes."
    log_warn "Process enumeration failed."
    return 1
}

# Collect listening ports and flag sensitive or high-value services.
collect_open_ports() {
    append_header "OPEN PORTS"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local port_output=""
    local source_cmd=""
    local risky_ports=""
    local port

    if command_exists ss; then
        source_cmd="ss -tulpn"
        port_output="$(ss -tulpn 2>&1)" || true
    elif command_exists netstat; then
        source_cmd="netstat -tulpn"
        port_output="$(netstat -tulpn 2>&1)" || true
    elif command_exists lsof; then
        source_cmd="lsof -nP -i"
        port_output="$(lsof -nP -i 2>&1)" || true
    else
        append_line "[!] No supported command available to enumerate open ports."
        log_warn "No supported port enumeration tool found."
        return 1
    fi

    append_kv "Source" "${source_cmd}"
    if [[ -z "${port_output}" ]]; then
        append_line "[!] Open port enumeration returned no data."
        log_warn "Open port enumeration returned no data."
        return 1
    fi

    append_line "${port_output}"
    append_line ""

    for port in 22 80 111 139 443 445 1433 1521 3306 3389 4444 5432 5900 6379 8080 9200 27017; do
        if printf '%s\n' "${port_output}" | grep -Eq "(^|[^0-9])${port}([^0-9]|$)"; then
            risky_ports="${risky_ports} ${port}"
        fi
    done

    if [[ -n "${risky_ports}" ]]; then
        PORT_RISK_TEXT="Sensitive or exposed ports detected:${risky_ports}"
        append_kv "Risk" "[!] ${PORT_RISK_TEXT}"
        if [[ "${PORT_RISK_FOUND}" -eq 0 ]]; then
            add_risk
            PORT_RISK_FOUND=1
        fi
    else
        append_kv "Risk" "No built-in risky port matches detected"
    fi

    if printf '%s\n' "${port_output}" | grep -qi "permission denied"; then
        log_warn "Open port visibility may be incomplete due to permissions."
    fi

    return 0
}

# Collect network interface information from ip or ifconfig.
collect_network_interfaces() {
    append_header "NETWORK INTERFACES"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if command_exists ip; then
        append_kv "Source" "ip address show"
        if ip address show >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "ip command failed while collecting network interfaces."
    fi

    if command_exists ifconfig; then
        append_kv "Source" "ifconfig -a"
        if ifconfig -a >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "ifconfig command failed while collecting network interfaces."
    fi

    append_line "[!] No supported command available to enumerate network interfaces."
    return 1
}

# Inventory installed packages using common Linux package managers.
collect_installed_packages() {
    append_header "INSTALLED PACKAGES"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if command_exists dpkg-query; then
        append_kv "Source" "dpkg-query -W"
        if dpkg-query -W -f='${binary:Package}\t${Version}\n' >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "dpkg-query package inventory failed."
    fi

    if command_exists rpm; then
        append_kv "Source" "rpm -qa"
        if rpm -qa >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "rpm package inventory failed."
    fi

    if command_exists pacman; then
        append_kv "Source" "pacman -Q"
        if pacman -Q >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "pacman package inventory failed."
    fi

    if command_exists apk; then
        append_kv "Source" "apk info -vv"
        if apk info -vv >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "apk package inventory failed."
    fi

    append_line "[!] No supported package manager detected."
    return 1
}

# Build a dedicated risk section for fast operator triage.
collect_risk_indicators() {
    append_header "RISK INDICATORS"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    append_kv "User Risk" "${USER_RISK_TEXT}"
    append_kv "Sudo Risk" "${SUDO_STATUS}"
    append_kv "Port Risk" "${PORT_RISK_TEXT}"
    append_kv "Risk Count" "${RISK_COUNT}"
    return 0
}

# Run a section collector with readable progress output.
run_section() {
    local title="$1"
    local function_name="$2"

    log_info "Collecting ${title}..."
    scan_delay

    if "${function_name}"; then
        log_info "${title} complete."
    else
        log_warn "${title} completed with warnings."
    fi
}

# Append a final summary block to the report.
write_summary() {
    append_header "SCAN COMPLETED"
    append_kv "Tool" "${TOOL_NAME}"
    append_kv "Version" "${TOOL_VERSION}"
    append_kv "Author" "${TOOL_AUTHOR}"
    append_kv "Total Checks" "${TOTAL_CHECKS}"
    append_kv "Warnings" "${WARNINGS_COUNT}"
    append_kv "Risk Count" "${RISK_COUNT}"
    append_kv "Saved Report" "${OUTPUT_FILE:-No}"
}

# Render the saved report to the terminal with styled section lines.
emit_report() {
    local line=""

    printf '\n'
    while IFS= read -r line; do
        case "${line}" in
            "================================================================")
                colorize "${COLOR_GREEN}" "${line}"
                printf '\n'
                ;;
            "[ RISK INDICATORS ]"|"[ SCAN COMPLETED ]")
                colorize "${COLOR_RED}" "${line}"
                printf '\n'
                ;;
            \[*\])
                colorize "${COLOR_GREEN}" "${line}"
                printf '\n'
                ;;
            *"[!]"*|*"ROOT USER DETECTED"*|*"SUDO-CAPABLE ACCOUNT"*|*"Sensitive or exposed ports detected"*)
                colorize "${COLOR_RED}" "${line}"
                printf '\n'
                ;;
            *)
                printf '%s\n' "${line}"
                ;;
        esac
    done < "${REPORT_FILE}"
    printf '\n'
}

# Save the report to disk if the operator requested file output.
save_report_if_requested() {
    if [[ -z "${OUTPUT_FILE}" ]]; then
        return 0
    fi

    if cat "${REPORT_FILE}" > "${OUTPUT_FILE}" 2>/dev/null; then
        log_info "Report saved to ${OUTPUT_FILE}"
        return 0
    fi

    log_error "Failed to save report to ${OUTPUT_FILE}"
    return 1
}

# Coordinate setup, data collection, and final report display.
main() {
    parse_args "$@"
    disable_color_if_needed
    validate_output_target
    initialize_report
    clear_screen
    print_banner

    write_report_prelude
    run_section "OS Details" collect_os_details
    run_section "Current User" collect_current_user
    run_section "All Users" collect_all_users
    run_section "Running Processes" collect_processes
    run_section "Open Ports" collect_open_ports
    run_section "Network Interfaces" collect_network_interfaces
    run_section "Installed Packages" collect_installed_packages
    run_section "Risk Indicators" collect_risk_indicators
    write_summary

    emit_report
    save_report_if_requested

    if [[ "${RISK_COUNT}" -gt 0 ]]; then
        colorize "${COLOR_RED}" "[!] Scan Completed: ${RISK_COUNT} risk indicator(s) detected."
        printf '\n'
    elif [[ "${WARNINGS_COUNT}" -gt 0 ]]; then
        colorize "${COLOR_YELLOW}" "[!] Scan Completed: warnings detected, review output."
        printf '\n'
    else
        colorize "${COLOR_GREEN}" "[+] Scan Completed: no elevated risks detected."
        printf '\n'
    fi
}

main "$@"
