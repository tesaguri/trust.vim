# trust.nvim

A poor imitation of Workspace Trust™️ for NeoVim/Vim8.

## Overview

`trust.nvim` provides utilities for managing "trusted" paths like in Visual Studio Code's Workspace
Trust feature. It also comes with an integration with NeoVim's builtin `vim.lsp` framework,
preventing language servers from running on untrusted workspaces.

## Prerequisites

- NeoVim or Vim (compiled with the `+lua` option), and
- Unix-like environment (current implementation assumes it in path manipulation)

Both are tested with the latest versions.

Note that the `trust.lsp` module (and `trust#lsp`) depends on NeoVim's `vim.lsp` Lua module, which
is only available on NeoVim. On Vim, what the plugin provides is a mere trust database and its
management utilities, on which you write integrations with other features.

## Installation

Using the builtin Vim packages (`:help packages`), for NeoVim:

```sh
git clone https://github.com/tesaguri/trust.vim.git "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/plugins/start/trust.vim"
```

or for Vim:

```sh
git clone https://github.com/tesaguri/trust.vim.git "$HOME/.vim/pack/plugins/start/trust.vim"
```

Usually however, you may want to manage the plugin with your favorite plugin manager, though I'm not
going to enumerate installation instructions for every manager, most of which should be something
like `AddOrPlugOrWhatever 'tesaguri/trust.vim'` in your vimrc.

## Setup

Add a configuration like the following in your `init.lua`:

```lua
local trust = require("trust")
local expand = vim.fn.expand

-- List of (dis)trusted directories.
-- This example trusts directories under `~/workspace` except for those under `forks` directory:
trust.allow(expand("~/workspace"))
trust.deny(expand("~/workspace/forks"))
trust.allow(expand("~/workspace/forks/some-thirdparty-repo-you-trust")
-- ...

-- Settings for NeoVim's builtin `vim.lsp` framework follows:
local trust_lsp = require("trust.lsp")

-- List of servers that are safe to run in arbitrary directory:
trust_lsp.safe_servers = { "dhall_lsp_server" }

-- Call the following function to make `vim.lsp.start_client` respect the above settings:
trust_lsp.hook_start_client()
```

Or in `init.vim`:

```vim
call trust#allow(expand("~/workspace"))
call trust#deny(expand("~/workspace/forks"))
" ...

call trust#lsp#set_safe_servers(["dhall_lsp_server"])

call trust#lsp#hook_start_client()
```

Don't want to write new repository in the vimrc each and every time? You can also store and load
the trust database from a directory. First, create the database files with Ex commands:

```vim
:" Mark the current directory as trusted, temporarily until the editor exits:
:TrustAllow .
:" Temporarily mark a directory as distrusted:
:TrustDeny ./thirdparty
:" Save the temporary trust database to files.
:" If the argument is omitted, defaults to `stdpath("data")."/trust"` (NeoVim-only):
:TrustSave ~/.local/share/trust.vim
```

and replace the list of trusted directories in the `init.lua` with the following:

```lua
require("trust").load()
```

Or in `init.vim`:

```vim
call trust#load()
```

If you want to write some trusted directories in the vimrc while keeping others from it, be sure to
write the list of directories _after_ calling the `load()` function. Otherwise, the function will
overwrite the on-memory trust database with the contents of the files. For example:

```lua
local trust = require("trust")
trust.load()
trust.allow(vim.fn.expand("~/workspace"))
trust.deny(vim.fn.expand("~/workspace/forks"))
```

## License

Copyright (c) 2022 Daiki "tesaguri" Mizukami

This project is licensed under either of:

- The Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://www.apache.org/licenses/LICENSE-2.0>), or
- The MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)

at your option.
