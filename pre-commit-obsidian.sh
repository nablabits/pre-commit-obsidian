#!/bin/bash

obsidian_dir= # add here your obsidian directory's absolute path.

# TODO: put conditional logic on the debug variable to print more info.
debug=false

today=$(date +%Y-%m-%d)

add_frontmatter() {
    local file="$1"
    local temp_file=$(mktemp)
        {
            echo "---"
            echo "created_at:"
            echo "updated_at:"
            echo "---"
            echo ""
            cat "$file"
        } > "$temp_file"
        mv "$temp_file" "$file"
        echo "Added frontmatter with timestamps"
        return 0
}


# Function to check and update timestamps in frontmatter
check_timestamps() {
    local file="$1"
    # if created at or updated_at do not exist, we raise a warning but allow
    # to continue. I will hardly find myself without these folks missing, so
    # it does not make sense to me for the time being to automate this edge
    # case.
    local has_created_at=$(grep -q "^created_at:" "$file")
    local has_updated_at=$(grep -q "^updated_at:" "$file")
    if ! $has_created_at || ! $has_updated_at; then
        echo "Warning: created_at or updated_at not found in file: $file"
    fi

    # replace created_at with the date of the first commit, or today's date if 
    # no history
    local first_commit=$(git log --follow --format="%as" -- "$file" | tail -n 1)
    if [[ -z "$first_commit" ]]; then
        first_commit="$today"
        echo "No git history found, using today's date for created_at"
    fi
    sed -Ei "s/^created_at:.+?$/created_at: $first_commit/" "$file"

    # replace updated_at with the current date.
    sed -Ei "s/^updated_at:.+?$/updated_at: $today/" "$file"
    
    return 0
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
        # if we don't have frontmatter we add one.
        if ! grep -q "^---$" "$file"; then
            echo "No frontmatter found in file: $file"
            add_frontmatter "$file"
        fi
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
