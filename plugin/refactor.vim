"=============================================================================
" File:         refactor.vim                                           {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      v2.0.0
" Created:      11th Mar 2005
" Last Update:  08th Mar 2018
"------------------------------------------------------------------------
" Description:  Some refactoring oriented mappings and commands
"
"
" Refactoring Lines In A New Function:
" 1- Select the lines (in visual-mode) you wish to use as a start for a new
"    function
" 2- Type ``:ExtractFunction''. The lines disapear and are replaced by a
"    function call. Markers (/placeholders) may be automatically inserted in
"    the function call.
" 3- Do not forget to execute ``:PutExtractedFunction'' to insert the body of
"    the new function back into the code
"
" Note: only one extracted function will be remembered at a time.
"
"------------------------------------------------------------------------
" Installation:
"       Drop this file into one of your {rtp}/plugin/ directory.
"
"       Adding new langages ....
"
"       Requires: vim7, lh-vim-lib, lh-dev, lh-tags
"
" History:
"       v2.0.0: 08th Mar 2018
"               * Change vmap to xmap
"       v1.2.6: 15th Mar 2017
"               * Deprecate `CONFIRM()` & co
"       v1.2.0: 20th Jan 2014
"               * Can be extended thanks to external files
"               * Bugs fixed regarding snippets for *extracting variables*.
"       v1.1.1: 18th Dec 2013
"               * Extract commands fixed to correctly process the visual
"                 selection
"       v1.1.0: * FixRealloc
"       v1.0.0: GPLv3
"       v0.2.2: Feb - 23rd Aug 2011
"               * <c-x>g and <c-x>s to prepare getters and setters
"       v0.0.4: 31st Oct 2007 - 08th Sep 2009
"               * Default variable names
"               * Relies on lh#functors
"               * Extract variable can change several occurences of the
"               expression to the new value. Todo: take the scope into account,
"               support, OO attributes, global variables, local variables, ...
"               (filetype specific).
"
"       v0.0.3: 30th Aug 2007 - 31st Oct 2007
"               * :ExtractFunction can abort if options are missing
"               * fix is_like_EM_
"               * Extract variable defined (see tip tip1171)
"               * Extract type defined
"               * Mappings v_CTRL-X_f, v_CTRL-X_v, v_CTRL-X-t, n_CTR-X_p, n_CTRL-X_P
"               * Mappings will abort on empty names
"
"       v0.0.2: 24th Mar 2005
"               * :PutExtractedFunction accepts <bang>
"
"       v0.0.1: 11th Mar 2005
"               * Initial version: :ExtractFunction, :PutExtractedFunction (see
"               tip 589)
"
" TODO:
" * documentation
" * callback for C++, be smart
" * simplify the the use of is_like stuff
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion                  {{{1
if exists("g:loaded_refactor") && !exists('g:force_reload_refactor')
  finish
endif
let g:loaded_refactor = 200
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands and mappings                     {{{1

" Command: :FixRealloc
" Analyses the current call to realloc, and fixes
"    p = (T*) realloc(p, size);
" into
"    T* new_p = (T*) realloc(p, size);
"    if (! new_p) {
"        free(p)
"        size = 0;
"        p = 0;
"        error_message();
"        return false;
"    }
"    p = new_p;
command! -range -nargs=0 FixRealloc
      \ <line1>,<line2>call lh#refactor#fix_realloc()

" Command: :ExtractFunction [<function_name> <signature>]
" Extracts the body of a newly factored function;
" As an optional argument, we can give the name of the new function
command! -range -nargs=* ExtractFunction
      \ <line1>,<line2>call lh#refactor#extract_function(0, <f-args>)

" Command: :ExtractVariable <variable_name>
" Extracts an expression to a newly factored variable;
command! -range -nargs=1 ExtractVariable
      \ <line1>,<line2>call lh#refactor#extract_variable(0, <f-args>)


" Command: :ExtractType <type_name>
" Extracts an expression to a newly factored type;
command! -range -nargs=1 ExtractType
      \ <line1>,<line2>call lh#refactor#extract_type(0, <f-args>)

" Command: :PutExtracted
" Put the body of the extracted thing somewhere else
command! -nargs=0 -bang  PutExtracted
      \ :call lh#refactor#put_extracted_last('')

xnoremap <silent> <c-x>f :call lh#refactor#extract_function(1,lh#ui#input("Name for the function to extract: "))<cr>

xnoremap <silent> <Plug>RefactorExtractVariable
      \ :call lh#refactor#extract_variable(1,lh#ui#input("Name for the variable to extract: ", lh#refactor#default_varname()))<cr>
if !hasmapto('<Plug>RefactorExtractVariable', 'v')
  xmap <unique> <c-x>v <Plug>RefactorExtractVariable
endif
xnoremap <silent> <Plug>RefactorExtractType
      \ :call lh#refactor#extract_type(1,lh#ui#input("Name for the type to extract: "))<cr>
if !hasmapto('<Plug>RefactorExtractType', 'v')
  xmap <unique> <c-x>t <Plug>RefactorExtractType
endif
nnoremap <Plug>RefactorPutLastUp <c-\><c-N>:call lh#refactor#put_extracted_last('!')<cr>
if !hasmapto('<Plug>RefactorPutLastUp', 'n')
  nmap <unique> <c-x>P <Plug>RefactorPutLastUp
endif
nnoremap <Plug>RefactorPutLastDown <c-\><c-N>:call lh#refactor#put_extracted_last('')<cr>
if !hasmapto('<Plug>RefactorPutLastDown', 'n')
  nmap <unique> <c-x>p <Plug>RefactorPutLastDown
endif

nnoremap <Plug>RefactorExtractGetter <c-\><c-n>:call lh#refactor#extract_getter()<cr>
if !hasmapto('<Plug>RefactorExtractGetter', 'n')
  nmap <unique> <c-x>g <Plug>RefactorExtractGetter
endif
nnoremap <Plug>RefactorExtractSetter <c-\><c-n>:call lh#refactor#extract_setter()<cr>
if !hasmapto('<Plug>RefactorExtractSetter', 'n')
  nmap <unique> <c-x>s <Plug>RefactorExtractSetter
endif

" Commands and mappings }}}1
"------------------------------------------------------------------------
finish
" It looks like what follow has been deprecated a long time ago...
" TODO: remove these functions

" Definitions for the various langages      {{{1        -----------------
" Helpers                                        {{{2         -----------
" RefactorH_func(signature)                                {{{3
" Global helper function that builds the signature of a function by
" adding parenthesis after the text given. If there is already a
" parenthesis in the text, nothing is added.
" Valable with most languages: C, vimL, ...
function! RefactorH_func(sig) abort
  if stridx(a:sig, '(') < 0
    return a:sig . '(' . lh#marker#txt('Parameters') . ')'
  else
    return a:sig
  endif
endfunction

" Callbacks for the various languages            {{{2         -----------
" C, C++, Java                                             {{{3
function! Refactor_EM_c(part, ...) abort
  if     a:part == 'begin'
    return lh#marker#txt('ReturnType').' '.RefactorH_func(a:1) . "\n{"
  elseif a:part == 'end'
    return "\n}".lh#marker#txt()."\n"
  elseif a:part == 'call'
    return RefactorH_func(a:1).lh#marker#txt().';'.lh#marker#txt()
  endif
endfunction

let g:refactor_EM_cpp_is_like  = "c"
let g:refactor_EM_java_is_like = "c"

" VimL                                                     {{{3
function! Refactor_EM_vim(part, ...) abort
  if     a:part == 'begin'
    return 'function! s:'.RefactorH_func(a:1)
  elseif a:part == 'end'
    return "\nendfunction\n"
  elseif a:part == 'call'
    return 's:'.RefactorH_func(a:1)
  endif
endfunction

" Pascal                                                   {{{3

function! s:FuncName(sig) abort
  let idx = stridx(a:sig, '(')
  if  idx < 0
    return a:sig
  else
    return strpart(a:sig, 0, idx)
  endif
endfunction

function! Refactor_EM_pascal(part,...) abort
  if     a:part == 'begin'
    " first call -> ask a few questions
    let c = confirm('What is extracted', "a &procedure\na &function", 1)
    if     c==0 " abort => suppose procedure
      let s:type = 'p'
    elseif c==1
      let s:type = 'p'
    else " c==2
      let s:type = 'f'
    endif
    if s:type == 'p'
      return 'procedure '.RefactorH_func(a:1). "\nbegin"
    else " function
      return 'function '.RefactorH_func(a:1). ": ".
            \ lh#marker#txt('ReturnType'). "\nbegin"
    endif
  elseif a:part == 'end'
    return ((s:type=='f') ? s:FuncName(a:1).' := '.lh#marker#txt('Value')."\n": '')
          \ . 'end'
  elseif a:part == 'call'
    if s:type == 'p'
      return RefactorH_func(a:1)
    else " function
      return lh#marker#txt('Result').' := '.RefactorH_func(a:1)
    endif
  endif
endfunction

" Definitions for the various langages      }}}1        -----------------
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
