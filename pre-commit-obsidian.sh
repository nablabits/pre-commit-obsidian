#!/bin/bash

CHECK_DOMAIN=true
STATUSES=("capture" "distill" "express")

# To establish when the file was created and the number of revisions, we
# use git log with the --follow flag to traverse renames of the files. This has
# some trade off as, if one note is created off a template and not changed
# substantially, it will be considered a revision. To mitigate what counts as
# a rename we use this value for the flag --find-renames. In my experience,
# 60 started to work well, but I'd like to make it more restrictive and trade
# revisions for accuracy.
# See:
# https://git-scm.com/docs/git-log#Documentation/git-log.txt---find-renames
RENAME_SENSITIVITY="80"

DEBUG=false

# Debug helper function - outputs to stderr with [DEBUG] prefix
debug_print() {
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Helper function to run git log with common flags
git_log_with_rename_tracking() {
    local file="$1"
    shift
    
    # Check if no_follow is set to true in the file's frontmatter
    local git_follow=$(grep -E "^no_follow:\strue$" "$file")
    
    if [[ -n "$git_follow" ]]; then
        debug_print "no_follow enabled for $file, skipping --follow and --find-renames"
        git log "$@" -- "$file"
    else
        git log --follow --find-renames="$RENAME_SENSITIVITY" "$@" -- "$file"
    fi
}


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

update_frontmatter_fields() {
    local file="$1"
    local temp_file=$(mktemp)
    local today=$(date +%Y-%m-%d)
    
    # Calculate the new values
    local first_commit=$(git_log_with_rename_tracking "$file" --format="%as" | tail -n 1)
    debug_print "First commit: $first_commit"
    if [[ -z "$first_commit" ]]; then
        first_commit="$today"
        echo "[WARNING] No git history found, using today's date for created_at"
    fi
    
    local revisions=$(($(git_log_with_rename_tracking "$file" --oneline | wc -l) + 1))
    debug_print "Revisions: $revisions"
    
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
    debug_print "Domain: $domain"
    if [[ $CHECK_DOMAIN == true && -z "$domain" ]]; then
        echo "[ERROR] No domain found in file: $file"
        return 1
    fi
    return 0
}

check_status () {
    local file="$1"
    
    # If STATUSES array is empty, return 0. In principle I will mostly have a
    # statuses, but I imagine people not using them, so having the array empty
    # is a proxy for "don't check status".
    if [[ ${#STATUSES[@]} -eq 0 ]]; then
        debug_print "Statuses not defined"
        return 0
    fi
    
    # If grep on status (both field and value) is empty, return 1
    local full_status=$(grep -E "^status:.+$" "$file")
    debug_print "Status: $full_status"
    if [[ -z "$full_status" ]]; then
        echo "[ERROR] No status found in file: $file"
        return 1
    fi

    # TODO: at some point I might want to do a check on whether the status in
    # the file matches the STATUSES array, but not for now.
    
    return 0
}

# Function to process all markdown files
process_markdown_files() {
    debug_print "Processing markdown files..."
    local result=0
    while IFS= read -r file; do      
        debug_print "Processing file: $file"
        # if we don't have frontmatter we add one.
        if ! grep -q "^---$" "$file"; then
            debug_print "Adding frontmatter to file: $file"
            add_frontmatter "$file"
        fi
        update_frontmatter_fields "$file"
        check_domain "$file"
        if [[ $? -ne 0 ]]; then
            result=1
        fi
        check_status "$file"
        if [[ $? -ne 0 ]]; then
            result=1
        fi
    done < <(git diff --cached --name-only --diff-filter=ACM | grep '\.md$')

    echo "Pre-commit check completed!"

    # Check if there are unstaged changes to prevent the commit.
    if ! git diff --quiet; then
        echo "[ERROR] Unstaged changes detected"
        return 1
    fi

    return $result
}

if [ "$1" = "--test" ]; then
    DEBUG=true
    debug_print "Running in test mode..."
fi 

process_markdown_files

exit $?
