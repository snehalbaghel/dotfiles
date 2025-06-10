#!/usr/bin/env bash#

if [[ "$@" == *"--install"* ]]; then
  # Aerospace
  brew install --cask nikitabobko/tap/aerospace
  # Janky borders
  brew tap FelixKratz/formulae
  brew install borders
fi

stow .