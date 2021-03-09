"=============================================================================
" File:         autoload/lh/refactor/sh.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      2.0.0
let s:k_version = 200
" Created:      20th Jan 2014
" Last Update:  05th Jan 2021
"------------------------------------------------------------------------
" Description:
"       Shell scripts (sh, bash, ...) settings for lh-refactor
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#sh#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#sh#verbose(...)
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

function! lh#refactor#sh#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Shell scripts (sh, bash, ...) Refactorings {{{1
" # Extract Method                               {{{2         -----------
call lh#refactor#fill('EM', 'sh', '_call',       ['fcall'])
call lh#refactor#fill('EM', 'sh', 'fcall',       lh#function#bind('v:1_._fname ." ".lh#marker#txt("parameters")') )
call lh#refactor#fill('EM', 'sh', '_function',   ['begin', '_body', 'end'])
call lh#refactor#fill('EM', 'sh', 'begin',       [ 'fsig', 'open' ] )
call lh#refactor#fill('EM', 'sh', 'fsig',        lh#function#bind('v:1_._fname . "()"'))
call lh#refactor#fill('EM', 'sh', 'open',        " {\n" )
call lh#refactor#fill('EM', 'sh', 'end',         ['placeholder', 'close', 'placeholder'] )
call lh#refactor#fill('EM', 'sh', 'placeholder', lh#refactor#placeholder(''))
call lh#refactor#fill('EM', 'sh', 'close',       "\n}" )

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#fill('EV', 'sh', '_use',         ['var_start', '_varname', 'var_end'])
call lh#refactor#fill('EV', 'sh', 'var_start',    '${')
call lh#refactor#fill('EV', 'sh', 'var_end',      '}')
call lh#refactor#fill('EV', 'sh', '_definition',  ['_varname', 'assign', '_value'])
call lh#refactor#fill('EV', 'sh', 'assign',       '=')

" call lh#refactor#fill('EV_name', 'sh',            '_naming_policy', ['$'])
" call lh#refactor#fill('EV_name', 'sh', '$',       '$')

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#sh#_load() {{{2
" Fake function to have the Shell Scripts settings loaded
function! lh#refactor#sh#_load() abort
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
