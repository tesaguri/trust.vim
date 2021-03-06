# trust.vim

[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)][vital]

A poor imitation of Workspace Trust™️ for Neovim/Vim.

## Overview

`trust.vim` is a Neovim/Vim plugin that provides utilities for managing "trusted" paths like in
Visual Studio Code's Workspace Trust feature. It also comes with an integration with Neovim's
builtin `vim.lsp` framework, preventing language servers from running on untrusted workspaces.

## Prerequisites

- Neovim (recommended), or
- Vim

Both are tested with the latest versions.

Note that the `trust.lsp` module (and `trust#lsp`) depends on Neovim's `vim.lsp` Lua module, which
is only available on Neovim. On Vim, what the plugin provides is a mere trust database and its
management utilities, on which you write integrations with other features.

## Installation

Using the builtin Vim packages (`:help packages`), for Neovim:

```sh
git clone https://github.com/tesaguri/trust.vim.git "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/plugins/start/trust.vim"
```

or for Vim:

```sh
git clone https://github.com/tesaguri/trust.vim.git "$HOME/.vim/pack/plugins/start/trust.vim"
```

Usually however, you may want to manage the plugin with your favorite plugin manager. Here is an
example for [`dein`][dein] (my favorite one). In your `init.lua`:

```lua
vim.fn['dein#add']("tesaguri/trust.vim", { rev = "v0.1" })
```

Or in `init.vim` (`vimrc`):

```vim
call dein#add('tesaguri/trust.vim', #{rev: 'v0.1'})
```

Setups for other package managers should also look like this.

Pinning to a versioned branch like `v0.1` is recommended because `HEAD` may have changes that break
your vimrc at any time.

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

-- Settings for Neovim's builtin `vim.lsp` framework follows:
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
:" If the argument is omitted, defaults to `stdpath("data")."/trust"` (Neovim-only):
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
local expand = vim.fn.expand
trust.load()

trust.allow(expand("~/workspace"))
trust.deny(expand("~/workspace/forks"))
```

## License

See [`COPYING.md`](COPYING.md) file for copyright notices and license information.

[vital]: <https://github.com/vim-jp/vital.vim>
[dein]: <https://github.com/Shougo/dein.vim>
