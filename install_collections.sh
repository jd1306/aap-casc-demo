#!/bin/bash
#
# Install Ansible collections per AAP version into separate directories.
# Used when running import.sh/export.sh with --playbook (ansible-playbook
# instead of ansible-navigator/EE). Each AAP version can pin different
# collection versions; this script installs them into collections/<version>/
# so ANSIBLE_COLLECTIONS_PATHS can point at the right one per run.
#
# Requirements file per version: collections/<version>/requirements.yml
# Example: collections/2.4/requirements.yml, collections/2.6/requirements.yml
#

set -euo pipefail

parent_dir=$(dirname "$(readlink -f "$0")")
script_vars_dir="$parent_dir/script_vars"
collections_base="$parent_dir/collections"

usage() {
    echo "Usage: $0 [version ...]"
    echo "  Install collections for each AAP version into collections/<version>/"
    echo "  With no arguments, installs for all versions in script_vars (e.g. 2.4 2.5 2.6)."
    echo "  With version(s), installs only for those (e.g. $0 2.6)."
    echo ""
    echo "  Each version needs: collections/<version>/requirements.yml"
    exit 1
}

# Resolve list of versions to install
if [[ $# -eq 0 ]]; then
    versions=()
    for vdir in "$script_vars_dir"/*/; do
        [[ -e "$vdir" ]] || continue
        ver=$(basename "$vdir")
        versions+=("$ver")
    done
    if [[ ${#versions[@]} -eq 0 ]]; then
        echo "No version directories found under $script_vars_dir"
        exit 1
    fi
else
    versions=("$@")
fi

for ver in "${versions[@]}"; do
    req_file="$collections_base/$ver/requirements.yml"
    install_dir="$collections_base/$ver"

    if [[ ! -f "$req_file" ]]; then
        echo "Skipping $ver: no $req_file"
        continue
    fi
    if [[ ! -s "$req_file" ]]; then
        echo "Skipping $ver: $req_file is empty"
        continue
    fi

    echo "Installing collections for AAP $ver into $install_dir"
    mkdir -p "$install_dir"
    # Restrict galaxy to this path only so it doesn't treat collections in
    # ~/.ansible/collections or /usr/share/ansible/collections as "already
    # installed" and skip them. Each versioned dir must be self-contained.
    ANSIBLE_COLLECTIONS_PATHS="$install_dir" ansible-galaxy collection install -r "$req_file" -p "$install_dir"
done

echo "Done."
