#!/usr/bin/env bash
#
# ZeroTraceR - Advanced Linux Recon Tool
#
# Production-grade Linux reconnaissance utility focused on stable execution,
# clear output, and practical operator value for authorized assessment use.

set -u
set -o pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly TOOL_NAME="ZeroTraceR"
readonly TOOL_VERSION="3.0.1"

OUTPUT_FILE=""
REPORT_FILE=""
USE_COLOR=1
WARNINGS_COUNT=0
SECTIONS_OK=0

readonly COLOR_RED=$'\033[0;31m'
readonly COLOR_GREEN=$'\033[0;32m'
readonly COLOR_YELLOW=$'\033[1;33m'
readonly COLOR_BOLD=$'\033[1m'
readonly COLOR_RESET=$'\033[0m'

# Remove the temporary report file on exit.
cleanup() {
    if [[ -n "${REPORT_FILE}" && -f "${REPORT_FILE}" ]]; then
        rm -f -- "${REPORT_FILE}"
    fi
}

trap cleanup EXIT

# Disable ANSI colors when output is not an interactive terminal.
disable_color_if_needed() {
    if [[ ! -t 1 ]] || [[ "${TERM:-}" == "dumb" ]]; then
        USE_COLOR=0
    fi
}

# Apply color formatting when supported by the current terminal.
colorize() {
    local color="$1"
    local message="$2"

    if [[ "${USE_COLOR}" -eq 1 ]]; then
        printf '%s%s%s' "${color}" "${message}" "${COLOR_RESET}"
    else
        printf '%s' "${message}"
    fi
}

# Print informational runtime messages for successful actions.
log_info() {
    colorize "${COLOR_GREEN}" "[INFO] $1"
    printf '\n'
}

# Print warning messages without aborting execution.
log_warn() {
    WARNINGS_COUNT=$((WARNINGS_COUNT + 1))
    colorize "${COLOR_YELLOW}" "[WARN] $1"
    printf '\n' >&2
}

# Print error messages for invalid input or unrecoverable failures.
log_error() {
    colorize "${COLOR_RED}" "[ERROR] $1"
    printf '\n' >&2
}

# Append a single line to the temporary report file.
append_line() {
    printf '%s\n' "$1" >> "${REPORT_FILE}"
}

# Append a blank line to improve report readability.
append_blank_line() {
    printf '\n' >> "${REPORT_FILE}"
}

# Append a clean section header to the report.
append_header() {
    local title="$1"
    append_blank_line
    append_line "================================================================"
    append_line "${title}"
    append_line "================================================================"
}

# Show the full professional help menu for the tool.
show_help() {
    cat <<EOF
-------------------------------------
ZeroTraceR - Advanced Linux Recon Tool
-------------------------------------

USAGE:
  ./${SCRIPT_NAME} [OPTIONS]

OPTIONS:
  -o <file>     Save output report to file
  -h            Show this help menu

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
  [*] Risk indicators for root, sudo, and suspicious ports

EXAMPLES:
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} -o report.txt

OUTPUT:
  Displays structured reconnaissance data in the terminal and
  optionally saves the full report to the specified file.

NOTES:
  - Some data may require root privileges for complete visibility
  - Missing commands are handled gracefully with warnings
  - Designed for authorized security testing and lab environments only
EOF
}

# Parse supported CLI flags and validate arguments.
parse_args() {
    while getopts ":o:h" opt; do
        case "${opt}" in
            o)
                OUTPUT_FILE="${OPTARG}"
                ;;
            h)
                show_help
                exit 0
                ;;
            :)
                log_error "Option -${OPTARG} requires an argument."
                show_help
                exit 1
                ;;
            \?)
                log_error "Invalid option: -${OPTARG}"
                show_help
                exit 1
                ;;
        esac
    done

    shift $((OPTIND - 1))
    if [[ "$#" -gt 0 ]]; then
        log_error "Unexpected argument(s): $*"
        show_help
        exit 1
    fi
}

# Check whether a command exists before trying to use it.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Initialize the temporary report file used for structured output.
initialize_report() {
    REPORT_FILE="$(mktemp "${TMPDIR:-/tmp}/zerotracer.XXXXXX")" || {
        log_error "Unable to create temporary report file."
        exit 1
    }
}

# Validate the target output path before attempting to save a report.
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

# Format key/value pairs consistently throughout the report.
append_kv() {
    local key="$1"
    local value="$2"
    append_line "$(printf '%-24s %s' "${key}:" "${value}")"
}

# Add top-level metadata so the report has traceable execution context.
write_report_prelude() {
    append_line "${TOOL_NAME} Reconnaissance Report"
    append_line "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date)"
    append_line "Script: ${SCRIPT_NAME}"
    append_line "Version: ${TOOL_VERSION}"
}

# Determine whether the current user appears to have sudo-equivalent access.
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

    if command_exists sudo; then
        if sudo -n -l >/dev/null 2>&1; then
            printf 'sudo access confirmed'
            return 0
        fi
    fi

    printf 'no direct sudo evidence'
}

# Capture high-level operating system and host identity details.
collect_os_details() {
    append_header "OS DETAILS"

    local hostname_value os_value kernel_value uptime_value
    hostname_value="Unavailable"
    os_value="Unavailable"
    kernel_value="Unavailable"
    uptime_value="Unavailable"

    if command_exists hostname; then
        hostname_value="$(hostname 2>/dev/null || printf 'Unavailable')"
    fi

    if [[ -r /etc/os-release ]]; then
        os_value="$(awk -F= '/^PRETTY_NAME=/{gsub(/"/, "", $2); print $2}' /etc/os-release 2>/dev/null)"
    elif command_exists lsb_release; then
        os_value="$(lsb_release -ds 2>/dev/null || printf 'Unavailable')"
    elif command_exists uname; then
        os_value="$(uname -s 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "Unable to determine OS details."
    fi

    if command_exists uname; then
        kernel_value="$(uname -r 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "uname command not available for kernel detection."
    fi

    if command_exists uptime; then
        uptime_value="$(uptime -p 2>/dev/null || uptime 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "uptime command not available."
    fi

    append_kv "Hostname" "${hostname_value}"
    append_kv "Operating System" "${os_value:-Unavailable}"
    append_kv "Kernel Version" "${kernel_value}"
    append_kv "Uptime" "${uptime_value}"
    return 0
}

# Collect current user identity, groups, and privilege risk indicators.
collect_current_user() {
    append_header "CURRENT USER"

    local username_value id_value groups_value privilege_value sudo_value risk_value
    username_value="${USER:-Unavailable}"
    id_value="Unavailable"
    groups_value="Unavailable"

    if command_exists id; then
        username_value="$(id -un 2>/dev/null || printf '%s' "${username_value}")"
        id_value="$(id 2>/dev/null || printf 'Unavailable')"
        groups_value="$(id -nG 2>/dev/null || printf 'Unavailable')"
    else
        log_warn "id command not available; user context may be incomplete."
    fi

    if [[ "${EUID:-99999}" -eq 0 ]]; then
        privilege_value="root"
        risk_value="HIGH - running as root"
    else
        privilege_value="standard user"
        risk_value="LOW"
    fi

    sudo_value="$(detect_sudo_status "${groups_value}")"
    if [[ "${sudo_value}" == "sudo access confirmed" || "${sudo_value}" == "group-based sudo access likely" ]]; then
        risk_value="ELEVATED - sudo-capable account detected"
    fi

    append_kv "Username" "${username_value}"
    append_kv "Identity" "${id_value}"
    append_kv "Groups" "${groups_value}"
    append_kv "Privileges" "${privilege_value}"
    append_kv "Sudo Status" "${sudo_value}"
    append_kv "Risk Indicator" "${risk_value}"
    return 0
}

# Enumerate local users from getent when available, otherwise from /etc/passwd.
collect_all_users() {
    append_header "ALL USERS"

    if command_exists getent; then
        append_line "Source: getent passwd"
        if getent passwd | awk -F: '{printf "%-24s uid=%s gid=%s shell=%s\n", $1, $3, $4, $7}' >> "${REPORT_FILE}" 2>/dev/null; then
            return 0
        fi
        log_warn "getent user enumeration failed."
    fi

    if [[ -r /etc/passwd ]]; then
        append_line "Source: /etc/passwd"
        if awk -F: '{printf "%-24s uid=%s gid=%s shell=%s\n", $1, $3, $4, $7}' /etc/passwd >> "${REPORT_FILE}" 2>/dev/null; then
            return 0
        fi
        log_warn "Unable to read /etc/passwd for user enumeration."
    fi

    append_line "[WARN] No supported method available to enumerate users."
    return 1
}

# Collect the current process list using standard ps output with fallback.
collect_processes() {
    append_header "RUNNING PROCESSES"

    if ! command_exists ps; then
        append_line "[WARN] ps command not available."
        log_warn "ps command not available."
        return 1
    fi

    append_line "Source: ps"
    if ps auxww >> "${REPORT_FILE}" 2>&1; then
        return 0
    fi

    append_line "[WARN] Primary process listing failed; attempting fallback."
    if ps -ef >> "${REPORT_FILE}" 2>&1; then
        return 0
    fi

    append_line "[WARN] Unable to capture running processes."
    log_warn "Process enumeration failed."
    return 1
}

# Scan listening ports and add simple risk indicators for notable services.
collect_open_ports() {
    append_header "OPEN PORTS"

    local port_output=""
    local source_cmd=""
    local suspicious_hits=""

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
        append_line "[WARN] No supported command available to enumerate open ports."
        log_warn "Port enumeration tool not found."
        return 1
    fi

    append_line "Source: ${source_cmd}"
    if [[ -z "${port_output}" ]]; then
        append_line "[WARN] Open port enumeration returned no data."
        log_warn "Open port enumeration returned no data."
        return 1
    fi

    append_line "${port_output}"

    for port in 21 23 69 111 445 1433 1521 3306 3389 4444 5555 5900 6379 8080 9200 27017 31337; do
        if printf '%s\n' "${port_output}" | grep -Eq "(^|[^0-9])${port}([^0-9]|$)"; then
            suspicious_hits="${suspicious_hits} ${port}"
        fi
    done

    append_blank_line
    if [[ -n "${suspicious_hits}" ]]; then
        append_kv "Risk Indicator" "Suspicious or high-value ports detected:${suspicious_hits}"
    else
        append_kv "Risk Indicator" "No suspicious port matches detected from built-in list"
    fi

    if printf '%s\n' "${port_output}" | grep -qi "permission denied"; then
        log_warn "Port enumeration may be incomplete due to permission restrictions."
    fi

    return 0
}

# Enumerate network interfaces using modern tooling with a legacy fallback.
collect_network_interfaces() {
    append_header "NETWORK INTERFACES"

    if command_exists ip; then
        append_line "Source: ip address show"
        if ip address show >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "ip command failed while collecting network interfaces."
    fi

    if command_exists ifconfig; then
        append_line "Source: ifconfig -a"
        if ifconfig -a >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "ifconfig command failed while collecting network interfaces."
    fi

    append_line "[WARN] No supported command available to enumerate network interfaces."
    return 1
}

# Inventory installed packages based on the active package manager.
collect_installed_packages() {
    append_header "INSTALLED PACKAGES"

    if command_exists dpkg-query; then
        append_line "Source: dpkg-query -W"
        if dpkg-query -W -f='${binary:Package}\t${Version}\n' >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "dpkg-query package inventory failed."
    fi

    if command_exists rpm; then
        append_line "Source: rpm -qa"
        if rpm -qa >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "rpm package inventory failed."
    fi

    if command_exists pacman; then
        append_line "Source: pacman -Q"
        if pacman -Q >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "pacman package inventory failed."
    fi

    if command_exists apk; then
        append_line "Source: apk info -vv"
        if apk info -vv >> "${REPORT_FILE}" 2>&1; then
            return 0
        fi
        log_warn "apk package inventory failed."
    fi

    append_line "[WARN] No supported package manager detected."
    return 1
}

# Run one section collector sequentially and report status cleanly.
run_section() {
    local title="$1"
    local function_name="$2"

    if "${function_name}"; then
        SECTIONS_OK=$((SECTIONS_OK + 1))
        log_info "${title} collected."
    else
        log_warn "${title} collected with warnings."
    fi
}

# Add a concise summary section so the report is easy to assess quickly.
write_summary() {
    append_header "SUMMARY"
    append_kv "Tool" "${TOOL_NAME}"
    append_kv "Version" "${TOOL_VERSION}"
    append_kv "Successful Sections" "${SECTIONS_OK}"
    append_kv "Warnings" "${WARNINGS_COUNT}"
    append_kv "Saved Report" "${OUTPUT_FILE:-No}"
}

# Print the report to the terminal in a clean, structured format.
emit_report() {
    printf '\n'
    colorize "${COLOR_BOLD}" "-------------------------------------"
    printf '\n'
    colorize "${COLOR_BOLD}" "${TOOL_NAME} Reconnaissance Report"
    printf '\n'
    colorize "${COLOR_BOLD}" "-------------------------------------"
    printf '\n\n'
    cat "${REPORT_FILE}"
    printf '\n'
}

# Save the assembled report to disk when the operator requested it.
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

# Orchestrate argument parsing, data collection, reporting, and save flow.
main() {
    disable_color_if_needed
    parse_args "$@"
    validate_output_target
    initialize_report

    log_info "Launching ${TOOL_NAME}..."

    write_report_prelude
    run_section "OS Details" collect_os_details
    run_section "Current User" collect_current_user
    run_section "All Users" collect_all_users
    run_section "Running Processes" collect_processes
    run_section "Open Ports" collect_open_ports
    run_section "Network Interfaces" collect_network_interfaces
    run_section "Installed Packages" collect_installed_packages
    write_summary

    emit_report
    save_report_if_requested

    if [[ "${WARNINGS_COUNT}" -gt 0 ]]; then
        log_warn "${TOOL_NAME} completed with warnings."
    else
        log_info "${TOOL_NAME} completed successfully."
    fi
}

main "$@"
