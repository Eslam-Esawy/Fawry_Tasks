#!/bin/bash

# Variables
search_string=""
filename=""
show_line_numbers=false
invert_match=false

# Function to print usage/help
print_usage() {
    echo "Usage: $0 [options] <search_string> <filename>"
    echo "Options:"
    echo "  -n    Show line numbers"
    echo "  -v    Invert match (show non-matching lines)"
    echo "  --help   Show this help message"
}

# Function to handle errors
error_exit() {
    echo "Error: $1"
    print_usage
    exit 1
}

# Function to parse options using getopts
parse_arguments() {
    # Check for --help as special case first
    # This is so important because getopts does not handle long options like --help
    if [[ "$1" == "--help" ]]; then
        print_usage
        exit 0
    fi

    # Handle options with getopts
    # This is stronger than manual parsing because it supports combined options like -vn and -nv
    OPTIND=1
    while getopts "nv" opt; do
        case "$opt" in
            n) show_line_numbers=true ;;
            v) invert_match=true ;;
            *) error_exit "Invalid option: $opt" ;;
        esac
    done
    
    # Shift past the options so $1 now points to the first argument that is not an option
    shift $((OPTIND - 1))
    
    # Check for the case where -v is used but missing search string
    if [[ "$invert_match" == true && $# -eq 1 ]]; then
        # If we have only one argument after options, it might be a filename
        # Check if it's an existing file - if yes, then the search string is missing
        if [[ -f "$1" ]]; then
            error_exit "Missing search string."
        fi
    fi
    
    # Check if search string is provided
    if [[ -z "$1" ]]; then
        error_exit "Missing search string."
    fi
    search_string="$1"
    shift
    
    # Check if filename is provided
    if [[ -z "$1" ]]; then
        error_exit "Missing filename."
    fi
    filename="$1"
    
    # Check if file exists
    if [[ ! -f "$filename" ]]; then
        error_exit "File not found: $filename"
    fi
}

# Function to perform the search
perform_search() {
    local line_number=0
    local found_match=false
    
    while read -r line; do
        ((line_number++))
        if [[ "$invert_match" == false ]]; then
	    #To search for a string in the line (case-insensitive)	
            if echo "$line" | grep -i -q "$search_string"; then
                found_match=true
                if [[ "$show_line_numbers" == true ]]; then
                    echo "${line_number}:$line"
                else
                    echo "$line"
                fi
            fi
        else
	    #For the inverted search	
            if ! echo "$line" | grep -i -q "$search_string"; then
                found_match=true
                if [[ "$show_line_numbers" == true ]]; then
                    echo "${line_number}:$line"
                else
                    echo "$line"
                fi
            fi
        fi
    done < "$filename"
    
    if [[ "$found_match" == false ]]; then
        echo "No matches found for '$search_string' in the file '$filename'."
        exit 0
    fi
}

# Main Execution
parse_arguments "$@"
perform_search
