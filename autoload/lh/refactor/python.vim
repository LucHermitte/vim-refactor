"=============================================================================
" File:         autoload/lh/refactor/python.vim                   {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      2.0.0
let s:k_version = 200
" Created:      19th Dec 2014
" Last Update:  02nd Sep 2025
"------------------------------------------------------------------------
" Description:
"       Python settings for lh-refactor
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#python#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#python#verbose(...)
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

function! lh#refactor#python#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Python Refactorings {{{1
" # Extract Method                               {{{2         -----------
call lh#refactor#fill('EM', 'python', '_call',       ['fcall'])
call lh#refactor#fill('EM', 'python', 'fcall',       lh#function#bind('v:1_._fname ." ".lh#marker#txt("parameters")') )
call lh#refactor#fill('EM', 'python', '_function',   ['begin', '_body', 'end'])
call lh#refactor#fill('EM', 'python', 'begin',       [ 'def', 'fsig', 'open' ] )
call lh#refactor#fill('EM', 'python', 'fsig',        lh#function#bind('v:1_._fname . "()"'))
call lh#refactor#fill('EM', 'python', 'def',         "def " )
call lh#refactor#fill('EM', 'python', 'open',        ":\n" )
call lh#refactor#fill('EM', 'python', 'end',         ['placeholder'] )
call lh#refactor#fill('EM', 'python', 'placeholder', lh#refactor#placeholder(''))

" # Refactoring expression in a new variable     {{{2         -----------
call lh#refactor#fill('EV', 'python', '_use',         ['_varname'])
call lh#refactor#fill('EV', 'python', '_definition',  ['_varname', 'assign', '_value'])
call lh#refactor#fill('EV', 'python', 'assign',       ' = ')

" call lh#refactor#fill('EV_name', 'sh',            '_naming_policy', ['$'])
" call lh#refactor#fill('EV_name', 'sh', '$',       '$')

" # Extract Getter                               {{{2         -----------
" Deep copy of the generic definition, in order to customize the result for getters
call lh#refactor#fill('Eg', 'python', '_definition', ['test_property', 'decl', 'body', 'end'])
call lh#refactor#fill('Eg', 'python', 'test_property',
      \                     { p -> {'_is_ppt': 1 == lh#ui#confirm("Shall it be a property?", "&Yes\n&No")} })
call lh#refactor#fill('Eg', 'python', 'decl',        ['property', 'def', 'opt_type', 'colon'])
call lh#refactor#fill('Eg', 'python', 'property',    {p -> p._is_ppt ? "@property\n" : ''})
call lh#refactor#fill('Eg', 'python', 'def',         {p -> printf("def %s(self)", p._is_ppt ? lh#naming#variable(p._name) : p._fname)})
call lh#refactor#fill('Eg', 'python', 'opt_type',
      \                     { p -> !empty(p._type) ? ' -> '.. p._type : lh#refactor#placeholder('-> type')} )
call lh#refactor#fill('Eg', 'python', 'colon',       ":\n" )
call lh#refactor#fill('Eg', 'python', 'body',        lh#refactor#snippet("return self.${_name}") )
call lh#refactor#fill('Eg', 'python', 'end',         { _ -> "\n"..lh#marker#txt('')})

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#refactor#python#_load() {{{2
" Fake function to have the Shell Scripts settings loaded
function! lh#refactor#python#_load() abort
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
