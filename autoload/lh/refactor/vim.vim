"=============================================================================
" File:         autoload/lh/refactor/vim.vim                      {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      2.0.0
let s:k_version = 200
" Created:      20th Jan 2014
" Last Update:  08th Mar 2018
"------------------------------------------------------------------------
" Description:
"       VimL settings for lh-refactor
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#vim#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#vim#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#refactor#vim#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## VimL Refactorings {{{1
" # Extract Method                               {{{2         -----------
call lh#refactor#fill('EM', 'vim', '_call',      ['call', 'placeholder'])
call lh#refactor#fill('EM', 'vim', '_function',  ['begin', '_body', 'end'])

call lh#refactor#fill('EM', 'vim', 'call',       lh#function#bind("lh#refactor#hfunc(v:1_, '_real_params')"))
call lh#refactor#fill('EM', 'vim', 'begin',      ['k_function', 'fsig', 'NL'])
call lh#refactor#fill('EM', 'vim', 'k_function', "function! ")
call lh#refactor#fill('EM', 'vim', 'fsig',       lh#function#bind('lh#refactor#hfunc(v:1_, "_formal_params")'))
call lh#refactor#fill('EM', 'vim', 'NL',         "\n")
call lh#refactor#fill('EM', 'vim', 'end',        ['NL', 'k_endf', 'placeholder', 'NL'])
call lh#refactor#fill('EM', 'vim', 'k_endf',     "endfunction")
call lh#refactor#fill('EM', 'vim', 'placeholder', lh#refactor#placeholder(''))

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#fill('EV', 'vim', '_use',         ['_varname'])
call lh#refactor#fill('EV', 'vim', '_definition',  ['let', '_varname', 'assign', '_value'])
call lh#refactor#fill('EV', 'vim', 'assign',       ' = ')
call lh#refactor#fill('EV', 'vim', 'let',          'let ')

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#vim#_load() {{{2
" Fake function to have the vim settings loaded
function! lh#refactor#vim#_load() abort
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
