#!/bin/bash

OBSIDIAN_DIR= # add here your obsidian directory's absolute path.

# TODO: put conditional logic on the debug variable to print more info.
DEBUG=false
CHECK_DOMAIN=true


add_frontmatter() {
    local file="$1"
    local temp_file=$(mktemp)
        {
            echo "---"
            echo "created_at:"
            echo "updated_at:"
            echo "revisions:"
            echo "---"
            echo ""
            cat "$file"
        } > "$temp_file"
        mv "$temp_file" "$file"
        return 0
}


# Function to update frontmatter fields by removing and re-adding them
update_frontmatter_fields() {
    local file="$1"
    local temp_file=$(mktemp)
    local today=$(date +%Y-%m-%d)
    
    # Calculate the new values
    local first_commit=$(git log --follow --format="%as" -- "$file" | tail -n 1)
    if [[ -z "$first_commit" ]]; then
        first_commit="$today"
        echo "No git history found, using today's date for created_at"
    fi
    
    local revisions=$(($(git log --follow --oneline -- "$file" | wc -l) + 1))
    
    # Remove the first --- delimiter and our target fields
    sed -E -e '1{/^---$/d}' -e '/^(created_at|updated_at|revisions|revisits):/d' "$file" > "$temp_file"
    
    # Prepend our fields with the opening delimiter
    {
        echo "---"
        echo "created_at: $first_commit"
        echo "updated_at: $today"
        echo "revisions: $revisions"
        cat "$temp_file"
    } > "$file"
    
    rm -f "$temp_file"
    return 0
}

check_domain () {
    local file="$1"
    local domain=$(grep -E "^domain:.+$" "$file")
    if [[ $CHECK_DOMAIN == true && -z "$domain" ]]; then
        echo "No domain found in file: $file"
        return 1
    fi
    return 0
}

# Function to process all markdown files
process_markdown_files() {
    if [[ -z "$OBSIDIAN_DIR" ]]; then
        echo "Error: obsidian_dir is not set. Please configure your Obsidian directory path."
        exit 1
    fi
    
    if [[ ! -d "$OBSIDIAN_DIR" ]]; then
        echo "Error: Directory $obsidian_dir does not exist."
        exit 1
    fi

    local result=0
    
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
        update_frontmatter_fields "$file"
        check_domain "$file"
        if [[ $? -ne 0 ]]; then
            result=1
        fi
    done

    echo "----------------------------------------"
    echo "Timestamp check completed! $result"
    return $result
}

if [ "$1" = "--test" ]; then
    OBSIDIAN_DIR="./sandbox"
    DEBUG=true
    echo "Running in test mode..."
    echo "OBSIDIAN_DIR: $OBSIDIAN_DIR"
fi 

process_markdown_files

exit $?
