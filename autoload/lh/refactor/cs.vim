"=============================================================================
" $Id$
" File:         autoload/lh/refactor/cs.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      1.2.0
" Created:      20th Jan 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       C# settings for lh-refactor
" 
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 120
function! lh#refactor#cs#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#refactor#cs#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#refactor#cs#debug(expr)
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## C# Refactorings {{{1
" Import C refactorings
call lh#refactor#java#_load()

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#inherit('EV', 'c', 'cpp', 0)

" # Extract Getter                               {{{2         -----------
" Shallow copy of the java definition, nothing to customize
" NB: I do not develop in C#, this may be wrong
" We may prefer to generate a property instead
call lh#refactor#inherit('Eg', 'java', 'cs', 0)

" # Extract Setter                               {{{2         -----------
" Shallow copy of the java definition, nothing to customize
" NB: I do not develop in C#, this may be wrong
" We may prefer to generate a property instead
call lh#refactor#inherit('Es', 'java', 'cs', 0)

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#cs#_load() {{{2
" Fake function to have the C# settings loaded
function! lh#refactor#cs#_load()
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
