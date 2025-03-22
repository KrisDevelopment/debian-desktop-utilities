#!/bin/bash

echo "Unsetting all Git credentials and caches..."

read -p "Are you sure you want to remove all Git credentials and caches? [y/N] " -n 1 -r

# Unset Git credentials stored in the global config
git config --global --unset credential.helper
git config --global --unset user.name
git config --global --unset user.email

# Clear any cached credentials (if using credential-cache or credential-cache daemon)
git credential reject "https://github.com"
git credential reject "https://gitlab.com"
git credential reject "https://git.revoltsoftware.com"
git credential reject "https://bitbucket.org"

# Remove any stored credentials in Git credential storage
rm -f ~/.git-credentials
rm -f ~/.gitconfig
rm -rf ~/.config/git 

# If using GPG signing, unset signing key
git config --global --unset user.signingkey

# If using SSH keys, remove known hosts and SSH agent identities
ssh-add -D
rm -rf ~/.ssh/known_hosts

# Restart SSH agent
eval "$(ssh-agent -k)"

echo "All Git credentials and caches have been removed."
