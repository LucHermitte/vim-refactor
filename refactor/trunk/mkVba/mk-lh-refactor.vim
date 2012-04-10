"=============================================================================
" $Id$
" File:		mkVba/mk-lh-refactor.vim                            {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:	1.0.0
let s:version = '1.0.0'
" Created:	06th Nov 2007
" Last Update:	$Date$
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
autoload/lh/refactor.vim
doc/refactor.txt
ftplugin/cpp/cpp_refactor.vim
lh-refactor-addon-info.txt
mkVba/mk-lh-refactor.vim
plugin/refactor.vim
refactor.README
