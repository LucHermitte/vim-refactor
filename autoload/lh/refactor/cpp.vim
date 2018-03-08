"=============================================================================
" File:         autoload/lh/refactor/cpp.vim                       {{{1
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
"       C++ settings for lh-refactor
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#cpp#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#cpp#verbose(...)
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

function! lh#refactor#cpp#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## C++ Refactorings {{{1
" Import C refactorings
call lh#refactor#c#_load()

" # Extract Method                               {{{2         -----------
" In C++ case, the definition of the function may require to prepend the name
" with the class name.
" @todo: check with namespace
call lh#refactor#inherit('EM', 'c', 'cpp', 0)
call lh#refactor#fill('EM', 'cpp', 'fsig',      lh#function#bind('lh#refactor#hfunc_def_full(v:1_, "_formal_params")'))
call lh#refactor#inherit('EM', 'c', 'java', 0)

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#inherit('EV', 'c', 'cpp', 0)

" # Extract Type                                 {{{2         -----------
call lh#refactor#inherit('ET', 'c', 'cpp', 1)

" # Extract Getter                               {{{2         -----------
" Deep copy of the generic definition, in order to customize the result for C++
call lh#refactor#inherit('Eg', '_oo_c_', 'cpp', 1)
call lh#refactor#fill('Eg', 'cpp',    'rettype',      lh#function#bind('lh#dev#cpp#types#ConstCorrectType(v:1_._type)'))
call lh#refactor#fill('Eg', 'cpp',    'postfix_',     " const".(lh#dev#cpp#use_cpp11()? " noexcept" : ""))

" # Extract Setter                               {{{2         -----------
" Shallow copy of the generic definition, nothing to customize
call lh#refactor#inherit('Es', '_oo_c_', 'cpp', 0)

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#cpp#_load() {{{2
" Fake function to have the cpp settings loaded
function! lh#refactor#cpp#_load()
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
