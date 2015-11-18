"=============================================================================
" File:		mkVba/mk-lh-refactor.vim                            {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/License.md>
" Version:	1.2.4
let s:version = '1.2.4'
" Created:	06th Nov 2007
" Last Update:	18th Nov 2015
"------------------------------------------------------------------------
" Description:
"       vimball archive builder for lh-refactor
"
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/mkVba
"       Requires Vim7+
" }}}1
"=============================================================================
let s:project = 'lh-refactor'
cd <sfile>:p:h
try
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '33,$MkVimball! '.s:project.'-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
License.md
README.md
VimFlavor
addon-info.json
autoload/lh/refactor.vim
autoload/lh/refactor/c.vim
autoload/lh/refactor/cpp.vim
autoload/lh/refactor/cs.vim
autoload/lh/refactor/java.vim
autoload/lh/refactor/javascript.vim
autoload/lh/refactor/perl.vim
autoload/lh/refactor/php.vim
autoload/lh/refactor/python.vim
autoload/lh/refactor/sh.vim
autoload/lh/refactor/vim.vim
doc/refactor.txt
ftplugin/cpp/cpp_refactor.vim
mkVba/mk-lh-refactor.vim
plugin/refactor.vim
