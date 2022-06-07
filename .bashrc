#!/usr/bin/env bash
# -*- coding: utf-8 -*-

## ---------------------------------------------------------------------------------- ##
## .bashrc                                              Nicholas Berlette, 2022-06-03 ##
## ---------------------------------------------------------------------------------- ##
##         https://github.com/nberlette/codespace-dotfiles/blob/main/.bashrc          ##
## ---------------------------------------------------------------------------------- ##
##                    MIT © Nicholas Berlette <nick@berlette.com>                     ##
## ---------------------------------------------------------------------------------- ##

export DOTFILES_PREFIX="$HOME/dotfiles"
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# source the .path file to make sure all programs and functions are accessible
# this also sources our core.sh file. and if it cant be found, it fails. HARD.
if [ -r ~/.path ]; then
  # shellcheck source=/dev/null
  { source ~/.path 2>/dev/null || source "${DOTFILES_PREFIX:-"$HOME/dotfiles"}/.path" 2>/dev/null; } || exit $?;
fi
  
# make sure our gitconfig is up to date
# user.name, user.email, user.signingkey
if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
  if [ -n "$GIT_COMMITTER_NAME" ] || [ -n "$GIT_AUTHOR_NAME" ]; then
    git config --global user.name "${GIT_COMMITTER_NAME:-"$GIT_AUTHOR_NAME"}"
  fi
  if [ -n "$GIT_COMMITTER_EMAIL" ] || [ -n "$GIT_AUTHOR_EMAIL" ]; then
    git config --global user.email "${GIT_COMMITTER_EMAIL:-"$GIT_AUTHOR_EMAIL"}"
  fi
  if [ -z "$(git config --global user.signingkey)" ]; then
    git config --global user.signingkey "${GPG_KEY_ID:-"${GIT_COMMITTER_EMAIL:-"$GIT_AUTHOR_EMAIL"}"}"
  fi
fi

# install homebrew 
if ! which brew &> /dev/null; then 
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# install pnpm
if ! which pnpm &> /dev/null; then
  curl -fsSL https://get.pnpm.io/install.sh | sh - 2>&1
  # double check that pnpm is installed, then install/setup node v16.15.0
  which pnpm &>/dev/null && pnpm env use --global "16.15.0" 2>/dev/null
fi

# 
if which brew &>/dev/null; then
  eval "$(brew shellenv)"
  
  # [see .Brewfile] install starship prompt and other goodies
  if ! which starship &>/dev/null && [ -r "$HOME/.Brewfile" ]; then
    brew bundle install --global 2>/dev/null
  fi
fi

# include all files in .bashrc.d folder
src ~/.bashrc.d/*

# import all vars from .env + .extra into current environment
srx ~/.{env,extra} "${PWD-}"/.{env,env.d}

# include our core bash environment
src ~/.{exports,functions,bash_aliases}

# bash completion
src "$HOMEBREW_PREFIX/etc/bash_completion.d" 2>/dev/null

# lesspipe
which lesspipe &>/dev/null && eval "$(SHELL="$(which bash)" lesspipe)"

# dircolors: attractive color coded output for ls, grep, etc.
if which dircolors &>/dev/null; then
  [ -r ~/.dircolors ] && eval "$(dircolors -b ~/.dircolors 2>/dev/null)" || eval "$(dircolors -b)"
fi

# export PATH="${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/bin:"}$PATH"
# clean up $PATH
if hash dedupe_path &>/dev/null; then 
  export PATH="$(dedupe_path)"; 
fi

eval "$(starship init bash)"
