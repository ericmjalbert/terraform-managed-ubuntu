terraform {
  required_version = ">= 1.6.0"

  required_providers {
    apt = {
      source  = "ericmjalbert/apt"
      version = "~> 0.1"
    }
    # snap = {
    #   source  = "ericmjalbert/snap"
    #   version = "~> 0.1"
    # }
    # nvim = {
    #   source  = "ericmjalbert/nvim"
    #   version = "~> 0.1"
    # }
    # tmux = {
    #   source  = "ericmjalbert/tmux"
    #   version = "~> 0.1"
    # }
    # claude = {
    #   source  = "ericmjalbert/claude"
    #   version = "~> 0.1"
    # }
    dotfiles = {
      source  = "ericmjalbert/dotfiles"
      version = "~> 0.1"
    }
    # golang = {
    #   source  = "ericmjalbert/golang"
    #   version = "~> 0.1"
    # }
    # pipx = {
    #   source  = "ericmjalbert/pipx"
    #   version = "~> 0.1"
    # }
    # github-release = {
    #   source  = "ericmjalbert/github-release"
    #   version = "~> 0.1"
    # }
  }
}

provider "apt" {}

provider "dotfiles" {}
