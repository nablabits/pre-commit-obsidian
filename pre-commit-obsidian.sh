#!/bin/bash

obsidian_dir= # add here your obsidian directory's absolute path.
# TODO: continue here, put conditional logic on the debug variable to print more info.
debug=false

# Function to check and update timestamps in frontmatter
check_timestamps() {
    local file="$1"
    local today=$(date +%Y-%m-%d)
    local temp_file=$(mktemp)
    local in_frontmatter=false
    local frontmatter_end=false
    local has_created_at=false
    local has_updated_at=false
    local created_at_empty=false
    local updated_at_empty=false
    local line_num=0

    # TODO: this can be probably simplified to always update using grep on the
    # frontmatter. smth of the sort: `^created_at:.*$` and `^updated_at:.*$`
    # and then setting the right dates.

    # created_at will pick either today if the file is new or the date of the 
    # first commit.
    
    # updated_at, will pick today in every case.
    
    echo "Checking timestamps in: $file"
    
    # First pass: analyze the frontmatter
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [[ $line_num -eq 1 && "$line" == "---" ]]; then
            in_frontmatter=true
        elif [[ "$line" == "---" && $in_frontmatter == true && $line_num -gt 1 ]]; then
            frontmatter_end=true
            break
        elif [[ $in_frontmatter == true ]]; then
            if [[ "$line" =~ ^created_at:[[:space:]]*$ ]]; then
                has_created_at=true
                created_at_empty=true
            elif [[ "$line" =~ ^created_at:[[:space:]]+.+ ]]; then
                has_created_at=true
            elif [[ "$line" =~ ^updated_at:[[:space:]]*$ ]]; then
                has_updated_at=true
                updated_at_empty=true
            elif [[ "$line" =~ ^updated_at:[[:space:]]+.+ ]]; then
                has_updated_at=true
            fi
        fi
    done < "$file"
    
    # If no frontmatter found, skip this file
    if [[ $in_frontmatter == false ]]; then
        echo "  No frontmatter found, skipping..."
        return 0
    fi
    
    # Second pass: update the file if needed
    local needs_update=false
    if [[ $created_at_empty == true || $updated_at_empty == true || $has_created_at == false || $has_updated_at == false ]]; then
        needs_update=true
    fi
    
    if [[ $needs_update == true ]]; then
        echo "  Updating timestamps..."
        line_num=0
        in_frontmatter=false
        
        while IFS= read -r line; do
            line_num=$((line_num + 1))
            
            if [[ $line_num -eq 1 && "$line" == "---" ]]; then
                echo "$line" >> "$temp_file"
                in_frontmatter=true
            elif [[ "$line" == "---" && $in_frontmatter == true && $line_num -gt 1 ]]; then
                # Add missing timestamps before closing frontmatter
                if [[ $has_created_at == false ]]; then
                    echo "created_at: $today" >> "$temp_file"
                fi
                if [[ $has_updated_at == false ]]; then
                    echo "updated_at: $today" >> "$temp_file"
                fi
                echo "$line" >> "$temp_file"
                in_frontmatter=false
            elif [[ $in_frontmatter == true ]]; then
                if [[ "$line" =~ ^created_at:[[:space:]]*$ ]]; then
                    echo "created_at: $today" >> "$temp_file"
                elif [[ "$line" =~ ^updated_at:[[:space:]]*$ ]]; then
                    echo "updated_at: $today" >> "$temp_file"
                else
                    echo "$line" >> "$temp_file"
                fi
            else
                echo "$line" >> "$temp_file"
            fi
        done < "$file"
        
        # Replace original file with updated content
        mv "$temp_file" "$file"
        echo "  ✓ Timestamps updated"
    else
        echo "  ✓ Timestamps already present"
        rm -f "$temp_file"
    fi
}

# Function to process all markdown files
process_markdown_files() {
    if [[ -z "$obsidian_dir" ]]; then
        echo "Error: obsidian_dir is not set. Please configure your Obsidian directory path."
        exit 1
    fi
    
    if [[ ! -d "$obsidian_dir" ]]; then
        echo "Error: Directory $obsidian_dir does not exist."
        exit 1
    fi
    
    echo "Processing markdown files in: $obsidian_dir"
    echo "----------------------------------------"
    
    # Get staged .md files only (for pre-commit)
    md_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.md$')
    for file in $md_files; do      
        echo "Processing file: $file"
        # TODO: maybe first of all we want to check whether the file has
        # frontmatter at all and add one if it doesn't. I don't think this will
        # be a likely scenario as I tend to add templates to all my notes which
        # carry the frontmatter.
        check_timestamps "$file"
    done
    
    echo "----------------------------------------"
    echo "Timestamp check completed!"
}

if [ "$1" = "--test" ]; then
    obsidian_dir="./sandbox"
    debug=true
    echo "Running in test mode..."
    echo "obsidian_dir: $obsidian_dir"
fi 

process_markdown_files

exit 0
