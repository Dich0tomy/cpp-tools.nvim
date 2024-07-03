# Table of Contents

<!-- vim-markdown-toc GFM -->

* [Functional spec of cpp-tools.nvim](#functional-spec-of-cpp-toolsnvim)
* [What is cpp-tools.nvim](#what-is-cpp-toolsnvim)
  * [Main objectives](#main-objectives)
  * [Installation](#installation)
    * [Using Nix](#using-nix)
    * [Using rocks.nvim](#using-rocksnvim)
    * [Using lazy.nvim](#using-lazynvim)
  * [Usage](#usage)
  * [General info](#general-info)
* [Definitions](#definitions)
* [Goals for *some* future release](#goals-for-some-future-release)
* [Goals for this release](#goals-for-this-release)
* [Goals for the **next** release](#goals-for-the-next-release)
* [Non-goals for **any** release](#non-goals-for-any-release)
* [Not sure if I'll ever implement these](#not-sure-if-ill-ever-implement-these)
* [Known issues and questions](#known-issues-and-questions)

<!-- vim-markdown-toc -->

# Functional spec of cpp-tools.nvim

> [!NOTE]
> This is a **pre implementation** draft, which means it's *just* an idea and no code yet.
> It may change if I see some technical limitations.

# What is cpp-tools.nvim

cpp-tools.nvim is a neovim plugin that aims to improve the experience of C++ development under neovim.

By default, OOTB it provides a sensible, carefully crafted, default C++ configuration.  
It also contains a plethora of modules for making the C++ experience smooth, including modules for generating code,
exploring documentation, etc.

## Main objectives

- [x] Provide a sensible default implementation OOTB
- [x] Provide several modules which address pain points when working with C++ in neovim
- [x] Provide several modules with niceities, like inserting comment preambles, header guards, etc.
- [x] TBD.

## Installation

<!-- TODO: This -->

### Using Nix

### Using rocks.nvim

### Using lazy.nvim

## Usage

> [!IMPORTANT]
> Disable all LSP, Dap and <!-- TODO: This --> configuration you do manually.

The simplest usage is just installing the plugin, it will automatically enable a number of modules, which
active the LSP, dap and ....

## General info

# Definitions

...

# Goals for *some* future release

# Goals for this release

# Goals for the **next** release

# Non-goals for **any** release

# Not sure if I'll ever implement these

# Known issues and questions
