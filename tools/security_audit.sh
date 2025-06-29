#!/usr/bin/env bash

# Security audit script for YouTube Playlist Manager
# This script checks for common security vulnerabilities

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_ISSUES=0
CRITICAL_ISSUES=0
WARNING_ISSUES=0
INFO_ISSUES=0

# Logging function
log_issue() {
    local severity="$1"
    local message="$2"
    local file="$3"
    local line="$4"
    
    case "$severity" in
        "CRITICAL")
            echo -e "${RED}[CRITICAL]${NC} $message"
            echo "  File: $file:$line"
            ((CRITICAL_ISSUES++))
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            echo "  File: $file:$line"
            ((WARNING_ISSUES++))
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            echo "  File: $file:$line"
            ((INFO_ISSUES++))
            ;;
    esac
    ((TOTAL_ISSUES++))
    echo
}

echo -e "${BLUE}=== YouTube Playlist Manager Security Audit ===${NC}\n"

# Check 1: SQL Injection vulnerabilities
echo "🔍 Checking for SQL injection vulnerabilities..."

# Look for unescaped variables in SQL queries that contain user input
while IFS=: read -r file line content; do
    if [[ "$content" =~ sqlite3.*\$[A-Za-z_][A-Za-z0-9_]* ]]; then
        # Check if sqlite_escape is used
        if [[ ! "$content" =~ sqlite_escape ]]; then
            # Additional check: look for common user input variables
            if [[ "$content" =~ \$playlist_id|\$track_id|\$artist|\$album|\$title|\$vid|\$pid ]]; then
                log_issue "CRITICAL" "Potential SQL injection: unescaped user input variable in SQL query" "$file" "$line"
            fi
        fi
    fi
done < <(grep -n "sqlite3.*\$" *.sh lib/*.sh tools/*.sh 2>/dev/null || true)

# Check 2: Command injection vulnerabilities
echo "🔍 Checking for command injection vulnerabilities..."

# Look for eval usage
while IFS=: read -r file line content; do
    log_issue "CRITICAL" "Command injection risk: eval usage detected" "$file" "$line"
done < <(grep -n "eval" *.sh lib/*.sh tools/*.sh 2>/dev/null || true)

# Look for unquoted variables in commands
while IFS=: read -r file line content; do
    if [[ "$content" =~ [a-zA-Z_][a-zA-Z0-9_]*=.*\$[A-Za-z_][A-Za-z0-9_]*[^\"\'] ]]; then
        log_issue "WARNING" "Unquoted variable in assignment: potential command injection" "$file" "$line"
    fi
done < <(grep -n "=.*\$" *.sh lib/*.sh tools/*.sh 2>/dev/null || true)

# Check 3: Path traversal vulnerabilities
echo "🔍 Checking for path traversal vulnerabilities..."

# Look for unvalidated file paths
while IFS=: read -r file line content; do
    if [[ "$content" =~ \.\./ ]] && [[ ! "$content" =~ validate_filename ]]; then
        log_issue "WARNING" "Potential path traversal: unvalidated path with .." "$file" "$line"
    fi
done < <(grep -n "\.\./" *.sh lib/*.sh tools/*.sh 2>/dev/null || true)

# Check 4: Input validation
echo "🔍 Checking for input validation..."

# Look for read commands without validation
while IFS=: read -r file line content; do
    if [[ "$content" =~ ^[[:space:]]*read ]]; then
        # Check if validation is used after read
        if ! grep -A 10 -B 2 "read.*$" "$file" | grep -q "validate_"; then
            log_issue "INFO" "User input read without explicit validation" "$file" "$line"
        fi
    fi
done < <(grep -n "read" *.sh lib/*.sh tools/*.sh 2>/dev/null || true)

# Check 5: File permissions
echo "🔍 Checking file permissions..."

# Check if scripts are executable
for script in *.sh lib/*.sh tools/*.sh; do
    if [[ -f "$script" ]] && [[ ! -x "$script" ]]; then
        log_issue "WARNING" "Script is not executable: $script" "$script" "1"
    fi
done

# Check 6: Hardcoded paths
echo "🔍 Checking for hardcoded paths..."

# Look for hardcoded Termux paths
while IFS=: read -r file line content; do
    if [[ "$content" =~ /data/data/com\.termux ]]; then
        log_issue "INFO" "Hardcoded Termux path found" "$file" "$line"
    fi
done < <(grep -n "/data/data/com.termux" *.sh lib/*.sh tools/*.sh 2>/dev/null || true)

# Check 7: Error handling
echo "🔍 Checking error handling..."

# Look for commands without error checking
while IFS=: read -r file line content; do
    if [[ "$content" =~ sqlite3.*\$ ]] && [[ ! "$content" =~ \|\| ]]; then
        log_issue "INFO" "SQL command without error handling" "$file" "$line"
    fi
done < <(grep -n "sqlite3.*\$" *.sh lib/*.sh tools/*.sh 2>/dev/null || true)

# Check 8: Logging
echo "🔍 Checking security logging..."

# Check if security events are logged
if ! grep -r "log_security_event" *.sh lib/*.sh tools/*.sh 2>/dev/null | grep -q .; then
    log_issue "INFO" "No security event logging found" "N/A" "N/A"
fi

# Check 9: Configuration security
echo "🔍 Checking configuration security..."

# Check if sensitive data is in config
if grep -q "password\|secret\|key" lib/config.sh 2>/dev/null; then
    log_issue "WARNING" "Potential sensitive data in configuration" "lib/config.sh" "N/A"
fi

# Check 10: Dependencies
echo "🔍 Checking dependency security..."

# Check if yt-dlp is up to date
if command -v yt-dlp >/dev/null 2>&1; then
    yt_dlp_version=$(yt-dlp --version 2>/dev/null || echo "unknown")
    log_issue "INFO" "yt-dlp version: $yt_dlp_version" "N/A" "N/A"
else
    log_issue "WARNING" "yt-dlp not found in PATH" "N/A" "N/A"
fi

# Summary
echo -e "${BLUE}=== Security Audit Summary ===${NC}\n"
echo -e "Total issues found: ${TOTAL_ISSUES}"
echo -e "${RED}Critical issues: ${CRITICAL_ISSUES}${NC}"
echo -e "${YELLOW}Warnings: ${WARNING_ISSUES}${NC}"
echo -e "${BLUE}Info: ${INFO_ISSUES}${NC}"

if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    echo -e "\n${RED}❌ Critical security issues found! Please address these immediately.${NC}"
    exit 1
elif [[ $WARNING_ISSUES -gt 0 ]]; then
    echo -e "\n${YELLOW}⚠️  Warnings found. Consider addressing these issues.${NC}"
    exit 0
else
    echo -e "\n${GREEN}✅ No critical security issues found.${NC}"
    exit 0
fi 