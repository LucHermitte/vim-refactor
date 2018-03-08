"=============================================================================
" File:         autoload/lh/refactor/perl.vim                       {{{1
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
"       Perl settings for lh-refactor
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#perl#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#perl#verbose(...)
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

function! lh#refactor#perl#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Perl Refactorings {{{1
" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#fill('EV', 'perl', '_use',         ['_varname'])
call lh#refactor#fill('EV', 'perl', '_definition',  ['my', '_varname', 'assign', '_value', 'eol'])
call lh#refactor#fill('EV', 'perl', 'assign',       ' = ')
call lh#refactor#fill('EV', 'perl', 'my',           'my ')
call lh#refactor#fill('EV', 'perl', 'eol',          ';')

call lh#refactor#fill('EV_name', 'perl',            '_naming_policy', ['$'])
call lh#refactor#fill('EV_name', 'perl', '$',       '$')

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#perl#_load() {{{2
" Fake function to have the perl settings loaded
function! lh#refactor#perl#_load() abort
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
