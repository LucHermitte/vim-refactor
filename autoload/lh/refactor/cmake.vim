"=============================================================================
" File:         autoload/lh/refactor/cmake.vim                    {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      1.2.6
let s:k_version = 126
" Created:      06th Mar 2014
" Last Update:  08th Mar 2018
"------------------------------------------------------------------------
" Description:
"       CMake settings for lh-refactor
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#cmake#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#cmake#verbose(...)
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

function! lh#refactor#cmake#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## CMake Refactorings {{{1

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#fill('EV', 'cmake', '_use',         lh#refactor#snippet('${${_varname}}'))
call lh#refactor#fill('EV', 'cmake', '_definition',  lh#refactor#snippet('SET(${_varname} ${_value})'))

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#cmake#_load() {{{2
" Fake function to have the vim settings loaded
function! lh#refactor#cmake#_load()
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
