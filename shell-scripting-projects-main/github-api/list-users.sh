#!/bin/bash

# -----------------------
# GitHub Collaborators Access Checker
# -----------------------

# Validate environment variables
if [[ -z "${GITHUB_USERNAME}" || -z "${GITHUB_TOKEN}" ]]; then
    echo "❌ Environment variables GITHUB_USERNAME and/or GITHUB_TOKEN are not set."
    echo "Please export them before running this script:"
    echo "  export GITHUB_USERNAME='your-username'"
    echo "  export GITHUB_TOKEN='your-token'"
    exit 1
fi

# Validate input arguments
if [[ $# -ne 2 ]]; then
    echo "Please enter the organization name followed by the repository name."
    echo "Usage: $0 <org_name> <repo_name>"
    exit 1
fi

# Assign arguments
REPO_OWNER="$1"
REPO_NAME="$2"

# GitHub API GET function
function github_api_get {
    local url="https://api.github.com/$1"
    curl -s -u "${GITHUB_USERNAME}:${GITHUB_TOKEN}" "$url"
}

# Main function to list collaborators and access levels
function list_collaborators_with_permissions {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators?per_page=100"

    echo "Fetching collaborators for ${REPO_OWNER}/${REPO_NAME}..."
    response=$(github_api_get "$endpoint")

    # Check if response is an array
    if ! echo "$response" | jq -e 'type == "array"' > /dev/null; then
        echo "❌ GitHub API response is invalid. Check repo/org name or credentials."
        echo "Raw response: $response"
        exit 1
    fi

    collaborators=$(echo "$response" | jq -r '.[] | [.login, .permissions.admin, .permissions.push, .permissions.pull] | @tsv')

    if [[ -z "$collaborators" ]]; then
        echo "ℹ️ No collaborators found or insufficient permissions."
        exit 0
    fi

    echo
    echo "Collaborators and their access:"
    printf "%-20s %-10s\n" "Username" "Access"
    echo "---------------------------------------"

    while IFS=$'\t' read -r login admin write read; do
        if [[ "$admin" == "true" ]]; then
            access="admin"
        elif [[ "$write" == "true" ]]; then
            access="write"
        elif [[ "$read" == "true" ]]; then
            access="read"
        else
            access="unknown"
        fi
        printf "%-20s %-10s\n" "$login" "$access"
    done <<< "$collaborators"
}

# Run the function
list_collaborators_with_permissions
