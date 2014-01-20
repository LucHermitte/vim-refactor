"=============================================================================
" $Id$
" File:         autoload/lh/refactor/c.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      1.2.0
" Created:      20th Jan 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       C & familly settings for lh-refactor
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
function! lh#refactor#c#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#refactor#c#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#refactor#c#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## C & familly Refactorings {{{1
" # Extract Method                               {{{2         -----------
call lh#refactor#fill('EM', 'c', '_call', ['call'])
call lh#refactor#fill('EM', 'c', '_function', ['begin', '_body', 'end'])

call lh#refactor#fill('EM', 'c', 'placeholder', lh#refactor#placeholder(''))
call lh#refactor#fill('EM', 'c', 'NL',          "\n")
call lh#refactor#fill('EM', 'c', 'rettype',     lh#refactor#placeholder('ReturnType', ' '))
call lh#refactor#fill('EM', 'c', 'fsig',        lh#function#bind('lh#refactor#hfunc(v:1_, "_formal_params")'))
call lh#refactor#fill('EM', 'c', 'open',        "\n{")
call lh#refactor#fill('EM', 'c', 'begin',       ['rettype', 'fsig', 'open', 'NL'])
call lh#refactor#fill('EM', 'c', 'close',       "\n}")
call lh#refactor#fill('EM', 'c', 'end',         ['close', 'placeholder', 'NL'])
" call has to accept an optional parameter: the function parameters...
call lh#refactor#fill('EM', 'c', 'call',        lh#function#bind("lh#refactor#hfunc(v:1_, '_real_params').';'.Marker_Txt()"))

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#fill('EV', 'c', '_use',         ['_varname'])
call lh#refactor#fill('EV', 'c', '_definition',  ['mutable', 'type', '_varname', 'assign', '_value', 'eol'])
call lh#refactor#fill('EV', 'c', 'assign',       ' = ')
call lh#refactor#fill('EV', 'c', 'eol',          ';')
call lh#refactor#fill('EV', 'c', 'type',         lh#refactor#placeholder('type', ' '))
call lh#refactor#fill('EV', 'c', 'mutable',      lh#function#bind(function('lh#refactor#const_key'), 'v:1_._varname'))

" # Extract Type                                 {{{2         -----------
call lh#refactor#fill('ET', 'c', '_use',         ['_typename'])
call lh#refactor#fill('ET', 'c', '_definition',  ['typedef', '_typeexpression', 'space', '_typename', 'eol'])
call lh#refactor#fill('ET', 'c', 'typedef',      'typedef ')
call lh#refactor#fill('ET', 'c', 'space',        ' ')
call lh#refactor#fill('ET', 'c', 'eol',          ';')

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#c#_load() {{{2
" Fake function to have the c settings loaded
function! lh#refactor#c#_load()
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
