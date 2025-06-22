#!/usr/bin/env bash
# -*- coding: utf-8 -*-

## ------------------------------------------------------------------------- ##
## .bashrc                                                        2025-06-21 ##
## ------------------------------------------------------------------------- ##
##  Copyright (c) 2021-2025 Nicholas Berlette. All rights reserved.          ##
##  Distributed under the MIT License: https://nick.mit-license.org/2021     ##
## ------------------------------------------------------------------------- ##

### Environment variables ###
export DOTFILES_PREFIX="$HOME/dotfiles"
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

### Source custom PATH and core scripts ###
if [ -r ~/.path ]; then
  { source ~/.path 2>/dev/null \
    || source "${DOTFILES_PREFIX:-"$HOME/dotfiles"}/.path" 2>/dev/null; } \
    || exit $?
fi

### Ensure Git global user config ###
if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
  [ -n "$GIT_COMMITTER_NAME" ] && git config --global user.name "$GIT_COMMITTER_NAME"
  [ -n "$GIT_COMMITTER_EMAIL" ] && git config --global user.email "$GIT_COMMITTER_EMAIL"
  if [ -z "$(git config --global user.signingkey)" ]; then
    git config --global user.signingkey \
      "${GPG_KEY_ID:-"${GIT_COMMITTER_EMAIL:-"$GIT_AUTHOR_EMAIL"}"}"
  fi
fi

### Helper for curl-based installs ###
_install() {
  local cmd=$1 url=$2 installer=${3:-sh}
  shift 3; local args=( "$@" )
  if ! command -v "$cmd" &>/dev/null; then
    curl -fsSL "$url" | $installer "${args[@]}"
  fi
}

### Install Homebrew and bundle ###
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if command -v brew &>/dev/null; then
  eval "$(brew shellenv)"
  [ -r "$HOME/.Brewfile" ] && brew bundle install --global 2>/dev/null
fi

### Install pnpm ###
_install pnpm https://get.pnpm.io/install.sh sh -
[ -x "$(command -v pnpm)" ] && pnpm env use --global latest 2>/dev/null

### Install Deno ###
_install deno https://deno.land/install.sh sh -y

### Install Bun ###
_install bun https://bun.sh/install sh -

### Install GitHub CLI ###
if ! command -v gh &>/dev/null; then
  brew install gh &>/dev/null
fi

### Install Rust (cargo via rustup) ###
_install cargo https://sh.rustup.rs sh -y
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

### Helper for installing shell completions ###
_install_completion() {
  local cmd=$1 cmp="/etc/bash_completion.d/${cmd}.bash"
  if command -v "$cmd" &>/dev/null && [ ! -s "$cmp" ]; then
    sudo touch "$cmp"
    sudo chown "${USER}:${USER}" "$cmp"
    "$cmd" completions bash > "$cmp"
  fi
}

### Install completions ###
_install_completion deno
_install_completion bun
_install_completion gh
_install_completion cargo

### Load additional bash fragments ###
src ~/.bashrc.d/*

### Import environment files ###
srx ~/.{env,extra} "${PWD-}"/.{env,env.d}

### Source core bash functions and aliases ###
src ~/.{exports,functions,bash_aliases}

### Homebrew bash completions ###
src "$HOMEBREW_PREFIX/etc/bash_completion.d" 2>/dev/null

### lesspipe support ###
command -v lesspipe &>/dev/null && eval "$(SHELL="$(which bash)" lesspipe)"

### dircolors for ls/grep ###
if command -v dircolors &>/dev/null; then
  [ -r ~/.dircolors ] \
    && eval "$(dircolors -b ~/.dircolors 2>/dev/null)" \
    || eval "$(dircolors -b)"
fi

### Deduplicate PATH ###
if hash dedupe_path &>/dev/null; then
  export PATH="$(dedupe_path)"
fi

### Starship prompt ###
command -v starship &>/dev/null && eval "$(starship init bash)"
