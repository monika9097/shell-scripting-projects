#!/bin/bash

# GitHub authentication
USERNAME="your-github-username"
TOKEN="your-personal-access-token"

# 🔐 Validate input arguments
if [[ $# -ne 2 ]]; then
    echo "Please enter the organization name followed by the repository name."
    echo "Usage: $0 <org_name> <repo_name>"
    exit 1
fi

# Assign command-line arguments
REPO_OWNER="$1"
REPO_NAME="$2"

# Function to call GitHub API
function github_api_get {
    local url="https://api.github.com/$1"
    curl -s -u "${USERNAME}:${TOKEN}" "$url"
}

# Function to list collaborators
function list_collaborators_with_permissions {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators?per_page=100"

    echo "Fetching collaborators for ${REPO_OWNER}/${REPO_NAME}..."
    response=$(github_api_get "$endpoint")

    # Check if API returned an array
    if ! echo "$response" | jq -e 'type == "array"' > /dev/null; then
        echo "GitHub API response is invalid. Check repo/org name or credentials."
        exit 1
    fi

    collaborators=$(echo "$response" | jq -r '.[] | [.login, .permissions.admin, .permissions.push, .permissions.pull] | @tsv')

    if [[ -z "$collaborators" ]]; then
        echo "No collaborators found or insufficient permissions."
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

# Call the main function
list_collaborators_with_permissions
