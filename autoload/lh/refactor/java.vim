"=============================================================================
" File:         autoload/lh/refactor/java.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      1.2.6
let s:k_version = 126
" Created:      20th Jan 2014
" Last Update:  08th Mar 2018
"------------------------------------------------------------------------
" Description:
"       Java settings for lh-refactor
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#java#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#java#verbose(...)
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

function! lh#refactor#java#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Java Refactorings {{{1
" Import C refactorings
call lh#refactor#c#_load()

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#inherit('EV', 'c', 'java', 0)

" # Extract Getter                               {{{2         -----------
" Deep copy of the generic definition, in order to customize the result for Java
" NB: I seldom develop in Java, this may be wrong
call lh#refactor#inherit('Eg', '_oo_c_', 'java', 1)
call lh#refactor#fill('Eg', 'java',   'prefix_',       lh#refactor#placeholder('public '))

" # Extract Setter                               {{{2         -----------
" Deep copy of the generic definition, in order to customize the result for Java
" NB: I seldom develop in Java, this may be wrong
call lh#refactor#inherit('Es', '_oo_c_', 'java', 1)
call lh#refactor#fill('Es', 'java',   'prefix_',       lh#refactor#placeholder('public '))

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#java#_load() {{{2
" Fake function to have the java settings loaded
function! lh#refactor#java#_load() abort
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
