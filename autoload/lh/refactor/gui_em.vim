"=============================================================================
" File:         autoload/lh/refactor/gui_em.vim                   {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      1.2.6
let s:k_version = 126
" Created:      01st Jun 2010
" Last Update:  08th Mar 2018
"------------------------------------------------------------------------
" Description:
"       «description»
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh/refactor
"       Requires Vim7+
"       «install details»
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#refactor#gui_em#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#refactor#gui_em#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#refactor#gui_em#debug(expr)
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
function! s:CompleteUpToCol(text, col)
  let text = a:text . repeat(' ', a:col-lh#encoding#strlen(a:text))
  return text
endfunction

function! s:Gui(self)
  let lines = []
  let list = a:self.list
  for p in list
    let line = '  - ['. (p.dir).'] '
    let line = s:CompleteUpToCol(line, 11)
    let line .= (p.formal)
    let line = s:CompleteUpToCol(line, 30)
    let line .= (has_key(p, 'type') ? ': '.(p.type) : '' )
    let line = s:CompleteUpToCol(line, 48) . '| '
    let line .= (p.name)

    let lines += [line]
  endfor
  return join(lines, "\n")
endfunction

function! lh#refactor#gui_em#open(data)
  let parameters = { 'list': [] }
  function! a:data.parameters.gui() dict
    return s:Gui(self)
  endfunction

  " VFT solution
  tabnew
  call MuTemplate( '_refactor/em-gui', a:data)

  let form = vft#InitCurBuf()
  let returns = [ 'void' ]
  call form.setItems('return', returns)
  call form.setValues({
        \ 'return': returns[0]
        \ })
  let s:data = a:data

  function! VftTest_ChangeCallback(id, value)
    echomsg 'Control ' . a:id . ' got new value ' . a:value
    return
    if a:id == 'colorscheme'
      execute 'colorscheme ' . a:value
    elseif a:id == 'foldmethod'
      execute 'set ' . a:id . '=' . a:value
    else
      execute 'set ' . a:id . (a:value ? '' : '!')
    endif
  endfunction

  call form.setChangeCallback(function('VftTest_ChangeCallback'))

  function! VftTest_ButtonCallback(id)
    if a:id == 'RENAME'
    elseif a:id == 'OK'
      tabclose
      call lh#refactor#_do_EM_callback(s:data)
      " Run refactor EM
    elseif a:id == 'ABORT'
      tabclose
      call lh#common#warning_msg("refactor: Extract Method aborted")
    else
      call confirm('Invalid concluion: '.a:id, '&Ok', 1)
    endif
  endfunction

  call form.setButtonCallback(function('VftTest_ButtonCallback'))

  " VFT => return async==1, python would return async==0
  return 1
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
