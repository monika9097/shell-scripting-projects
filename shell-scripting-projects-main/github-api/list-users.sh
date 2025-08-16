#!/bin/bash

API_URL="https://api.github.com"

# GitHub username and personal access token (set these before running)
USERNAME=$username
TOKEN=$token

# Check if two arguments are provided
function check_args {
    if [[ $# -ne 2 ]]; then
        echo "Please provide the organization name followed by the repository name."
        exit 1
    fi
}

# Function to make a GET request to the GitHub API
function github_api_get {
    local endpoint="$1"
    local url="${API_URL}/${endpoint}"
    curl -s -u "${USERNAME}:${TOKEN}" "$url"
}

# Function to list collaborators with their access level
function list_collaborators_with_access {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators"
    local response=$(github_api_get "$endpoint")

    # Check if response is valid JSON array
    if ! echo "$response" | jq -e 'type == "array"' >/dev/null 2>&1; then
        echo "GitHub API response is invalid. Check repo/org name or credentials."
        exit 1
    fi

    local collaborators=$(echo "$response" | jq -r '.[] | "\(.login) \(.permissions.admin) \(.permissions.push) \(.permissions.pull)"')

    if [[ -z "$collaborators" ]]; then
        echo "No collaborators found for ${REPO_OWNER}/${REPO_NAME}."
        exit 0
    fi

    echo "Collaborators and their access levels for ${REPO_OWNER}/${REPO_NAME}:"
    for collaborator in $collaborators; do
        login=$(echo $collaborator | awk '{print $1}')
        admin=$(echo $collaborator | awk '{print $2}')
        write=$(echo $collaborator | awk '{print $3}')
        read=$(echo $collaborator | awk '{print $4}')

        if [[ "$admin" == "true" ]]; then
            access="admin"
        elif [[ "$write" == "true" ]]; then
            access="write"
        elif [[ "$read" == "true" ]]; then
            access="read"
        else
            access="none"
        fi

        echo "$login: $access"
    done
}

# Main script execution
check_args "$@"

REPO_OWNER=$1
REPO_NAME=$2

list_collaborators_with_access
