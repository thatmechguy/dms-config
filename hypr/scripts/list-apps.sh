#!/usr/bin/env bash
# List all installed applications as JSON

OUTPUT_FILE="/tmp/quickshell-apps.json"
TEMP_FILE="/tmp/quickshell-apps-temp.txt"

> "$TEMP_FILE"

find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | while read -r desktop; do
    name=$(grep -m1 "^Name=" "$desktop" 2>/dev/null | cut -d= -f2-)
    icon=$(grep -m1 "^Icon=" "$desktop" 2>/dev/null | cut -d= -f2-)
    exec_cmd=$(grep -m1 "^Exec=" "$desktop" 2>/dev/null | cut -d= -f2- | sed 's/%[fFuUdDnNickvm]//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
    hidden=$(grep -m1 "^NoDisplay=" "$desktop" 2>/dev/null | cut -d= -f2-)
    
    # Skip hidden and empty entries
    if [ "$hidden" = "true" ] || [ -z "$name" ] || [ -z "$exec_cmd" ]; then
        continue
    fi
    
    # Escape quotes
    name=$(echo "$name" | sed 's/"/\\"/g')
    exec_cmd=$(echo "$exec_cmd" | sed 's/"/\\"/g')
    icon=$(echo "$icon" | sed 's/"/\\"/g')
    
    # Get first letter for grouping
    first_letter=$(echo "$name" | head -c1 | tr '[:lower:]' '[:upper:]')
    
    echo "${first_letter}|${name}|${icon}|${exec_cmd}" >> "$TEMP_FILE"
done

# Sort and convert to JSON
sort -t'|' -k1,1 -k2,2 "$TEMP_FILE" | awk -F'|' '
BEGIN { print "["; first=1 }
{
    if (first == 0) printf ",\n"
    first=0
    printf "  {\"letter\": \"%s\", \"name\": \"%s\", \"icon\": \"%s\", \"exec\": \"%s\"}", $1, $2, $3, $4
}
END { print "\n]" }
' > "$OUTPUT_FILE"

rm -f "$TEMP_FILE"
