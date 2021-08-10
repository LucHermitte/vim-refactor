# vim-refactor v2.0.0 [![Last release](https://img.shields.io/github/tag/LucHermitte/vim-refactor.svg)](https://github.com/LucHermitte/vim-refactor/releases) [![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)
## Features

lh-refactor is a generic refactoring plugin.

So far it supports the following refactorings (v0.2.2):
  * Extract Function,
  * Extract Variable,
  * Extract Type,
  * Extract Getter & Extract Setter, _(it's more a generate than an extract actually)_
and the following languages: C, C++, Java, Pascal, VimL.

The list of languages supported can be extended (however some refactoring work in the plugin is required to simplify that part)

The complete documentation can be browsed [in the repository](doc/refactor.txt)

## Mappings
### Visual-mode Mappings (not available in Select-mode)
  * `<C-X>f` to eXtract a Function
  * `<C-X>v` to eXtract a Variable
  * `<C-X>t` to eXtract a Type
### Normal-mode Mappings
  * `<C-X>g` to eXtract a Getter, and `<C-X>s` to eXtract a Setter
  * `<C-X>p` and `<C-X>P` to Put back the definition that as been extracted

#### Note

The extraction refactorings don't put back anything. The position in the code
where the extracted things are to be placed are left to end-user appreciation.
This has to be done with `<C-X>p` and `<C-X>P`.

## Installation
  * Requirements: Vim 7.+, [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib), [lh-brackets](http://github.com/LucHermitte/lh-brackets), [lh-dev](http://github.com/LucHermitte/lh-dev) (and thus [lh-tags](http://github.com/LucHermitte/lh-tags)), and [lh-style](http://github.com/LucHermitte/lh-style)
  * With [vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), install lh-refactor. This is the preferred method because of the various dependencies.

    ```vim
    ActivateAddons lh-refactor
    ```

  * or you can clone the git repositories (expecting I haven't forgotten anything):

    ```
    git clone git@github.com:LucHermitte/lh-vim-lib.git
    git clone git@github.com:LucHermitte/lh-tags.git
    git clone git@github.com:LucHermitte/lh-dev.git
    git clone git@github.com:LucHermitte/lh-style.git
    git clone git@github.com:LucHermitte/lh-brackets.git
    git clone git@github.com:LucHermitte/vim-refactor.git

    # For experimental function extraction
    git clone git@github.com:LucHermitte/mu-template.git
    git clone git@github.com:tomtom/stakeholders_vim.git
    ```

  * or with Vundle/NeoBundle (expecting I haven't forgotten anything):

    ```vim
    Bundle 'LucHermitte/lh-vim-lib'
    Bundle 'LucHermitte/lh-tags'
    Bundle 'LucHermitte/lh-dev'
    Bundle 'LucHermitte/lh-style'
    Bundle 'LucHermitte/lh-brackets'
    Bundle 'LucHermitte/vim-refactor'

    " For experimental function extraction
    Bundle 'LucHermitte/mu-template'
    Bundle 'tomtom/stakeholders_vim'
    ```

## See also
  * Klaus Horsten's tip: [Vim as refactoring tool (with examples in C#)](http://vim.wikia.com/wiki/Vim_as_a_refactoring_tool_and_some_examples_in_C_sharp)
  * [lh-cpp](http://github.com/LucHermitte/lh-cpp) defines a few other refactoring-like functionalities:
    * Generate accessor and mutator (`:ADDATTRIBUTE`),
    * Generate default body given a function signature (`:GOTOIMPL`)
  * [Refactoring.com](http://www.refactoring.com/catalog/index.html)

