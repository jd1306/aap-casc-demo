#!/bin/bash

set -euo pipefail

# Get the directory of the script
parent_dir=$(dirname "$(readlink -f "$0")")

# --- Function to display usage ---
# Moved to the top and made generic for better script structure.
usage() {
    echo "Usage: $0 <org> <env>"
    exit 1
}

orgs_vars_dir="$parent_dir/orgs_vars"

# --- Initial Argument Validation ---
# Ensure the two mandatory arguments are provided.
if [[ $# -lt 2 ]]; then
    echo "Error: Missing organization or environment argument."
    echo ""
    if [[ $# -eq 0 ]]; then
        # No arguments provided, show usage
        usage
    elif [[ $# -eq 1 ]]; then
        # Only org provided, list available environments for that org
        org=$1
        org_base_dir="$orgs_vars_dir/$org"
        if [[ -d "$org_base_dir" ]]; then
            available_envs=$(find "$org_base_dir" -mindepth 1 -maxdepth 1 -type d -not -name "common" -printf "%f|" | sed 's/|$//')
            echo "Available environments in '$org': {$available_envs}"
        else
            if [[ -d "$orgs_vars_dir" ]]; then
                available_orgs=$(find "$orgs_vars_dir" -mindepth 1 -maxdepth 1 -type d -printf "%f|" | sed 's/|$//')
                echo "Available organizations: {$available_orgs}"
            fi
        fi
    fi
    usage
fi

org=$1
env=$2
org_base_dir="$orgs_vars_dir/$org"

# --- Validate Organization ---
if [[ ! -d "$org_base_dir" ]]; then
    echo "Error: Organization '$org' not found or is invalid."
    echo ""
    if [[ -d "$orgs_vars_dir" ]]; then
        available_orgs=$(find "$orgs_vars_dir" -mindepth 1 -maxdepth 1 -type d -printf "%f|" | sed 's/|$//')
        echo "Available organizations: {$available_orgs}"
    fi
    exit 1
fi

# --- Validate Environment ---
# Check if the environment exists and is not the 'common' directory.
if [[ ! -d "$org_base_dir/$env" ]]; then
    echo "Error: Environment '$env' not found or is invalid in organization '$org'."
    echo ""
    # List available environments for the given organization.
    available_envs=$(find "$org_base_dir" -mindepth 1 -maxdepth 1 -type d -not -name "common" -printf "%f|" | sed 's/|$//')
    echo "Available environments in '$org': {$available_envs}"
    exit 1
fi

# Change to the playbooks directory.
cd "$parent_dir" || { echo "Failed to change directory to $parent_dir"; exit 1; }

# --- Define the file to edit and execute the command ---
file_to_edit="${org_base_dir}/${env}/vault.yml"

echo "Opening vault file: $file_to_edit"
ansible-vault edit "$file_to_edit"