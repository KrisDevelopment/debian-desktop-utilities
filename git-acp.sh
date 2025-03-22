#!/bin/bash

# Git "Add Commit Push". Will try to reconcile your working copy with the remote branch.

run_acp() {
    if [ -z "$1" ]; then
        echo "Usage: gitacp <commit message>"
        return 1
    fi

    # if detached head, abort
    if git branch --show-current | grep -q "HEAD detached"; then
        echo "You are in a detached HEAD state. Aborting."
        return 1
    fi

    git add .

    # Check if there are changes to commit
    if ! git diff --quiet || ! git diff --cached --quiet; then
        git commit -m "$1"
    else
        echo "No changes to commit."
        return 0
    fi

    # Push changes and handle errors
    if ! git push; then
        echo "Push failed. Attempting to pull with rebase..."
        if git pull --rebase; then
            git push
        elif git pull --ff; then
            git push
        else 
            echo "Pull failed. Resolve conflicts manually."
            return 1
        fi
    fi
}

run_acp "$@"


# --- Install as bashrc alias ---

install_arg=0
if [ "$1" == "--install" ]; then
    echo "Installing gitacp alias in ~/.bashrc..."
    install_arg=1
fi

installed=0
if grep -q "alias gitacp=" ~/.bashrc; then
    installed=1
else
    echo "Tip: You can install this script as a bashrc alias by running 'git-acp.sh --install'"
fi

# install as bashrc 'gitacp' alias if --install flag is passed, unless already installed
if [ $install_arg -eq 1 ]; then
    if $installed -eq 1; then
        echo "gitacp alias already installed in ~/.bashrc"
    else
        echo "Installing gitacp alias in ~/.bashrc..."
        echo "alias gitacp='source ~/debian-desktop-utilities/git-acp.sh'" >> ~/.bashrc
    fi
fi