#!/bin/bash

# GitHub authentication
USERNAME="your-github-username"
TOKEN="your-personal-access-token"

# Helper function to validate input
function validate_input {
    if [[ $# -ne 2 ]]; then
        echo "Please enter the organization name followed by the repository name."
        echo "Usage: $0 <org_name> <repo_name>"
        exit 1
    fi
}

# Function to call GitHub API
function github_api_get {
    local url="https://api.github.com/$1"
    curl -s -u "${USERNAME}:${TOKEN}" "$url"
}

# Function to list collaborators and their permissions
function list_collaborators_with_permissions {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators?per_page=100"

    echo "Fetching collaborators for ${REPO_OWNER}/${REPO_NAME}..."
    response=$(github_api_get "$endpoint")

    collaborators=$(echo "$response" | jq -r '.[] | [.login, .permissions.admin, .permissions.push, .permissions.pull] | @tsv')

    if [[ -z "$collaborators" ]]; then
        echo "No collaborators found or invalid repository/org name."
        exit 1
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

# -------------------- MAIN --------------------

# Validate input arguments
validate_input "$@"

# Assign command-line arguments
REPO_OWNER="$1"
REPO_NAME="$2"

# Run the main function
list_collaborators_with_permissions
