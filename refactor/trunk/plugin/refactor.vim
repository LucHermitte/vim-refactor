"=============================================================================
" File:		refactor.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	v0.0.3
" Created:	11th Mar 2005
" Last Update:	28th Nov 2007
"------------------------------------------------------------------------
" Description:	Some refactoring oriented mappings and commands
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
" 	Drop this file into one of your {rtp}/plugin/ directory.
"
" 	Adding new langages ....
"
" 	Requires: bracketing.base.vim, Vim7
"
" History:
" 	v0.0.3:	30th Aug 2007 - 31st Oct 2007 
" 		* :ExtractFunction can abort if options are missing
" 		* fix is_like_EM_
" 		* Extract variable defined (see tip tip1171)
" 		* Extract type defined
" 		* Mappings v_CTRL-X_f, v_CTRL-X_v, v_CTRL-X-t, n_CTR-X_p, n_CTRL-X_P
" 		* Mappings will abort on empty names
"
" 	v0.0.2:	24th Mar 2005
" 		* :PutExtractedFunction accepts <bang>
"
" 	v0.0.1:	11th Mar 2005
" 		* Initial version: :ExtractFunction, :PutExtractedFunction (see
" 		tip 589)
"
" TODO:
" * documentation
" * callback for C++, be smart
" * simplify the the use of is_like stuff
" * autoload
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion                  {{{1
if exists("g:loaded_refactor") && !exists('g:force_reload_refactor')
  finish
endif
let g:loaded_refactor = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands and mappings                     {{{1

" Command: :ExtractFunction [<function_name> <signature>]
" Extracts the body of a newly factored function;
" As an optional argument, we can give the name of the new function
command! -range -nargs=* ExtractFunction
      \ :call s:ExtractFunction(0, <f-args>)

" Command: :PutExtractedFunction
" Put the body of the extracted function somewhere else
command! -nargs=0 -bang  PutExtractedFunction
      \ :call s:PutExtractedStuff("<bang>", s:fn)

" Command: :ExtractVariable <variable_name>
" Extracts an expression to a newly factored variable;
command! -range -nargs=1 ExtractVariable
      \ :call s:ExtractVariable(0, <f-args>)

" Command: :PutExtractedVariable
" Put the body of the extracted variable somewhere else
command! -nargs=0 -bang  PutExtractedVariable
      \ :call s:PutExtractedStuff("<bang>", s:variable)

" Command: :ExtractType <type_name>
" Extracts an expression to a newly factored type;
command! -range -nargs=1 ExtractType
      \ :call s:ExtractType(0, <f-args>)

" Command: :PutExtractedType
" Put the body of the extracted type somewhere else
command! -nargs=0 -bang  PutExtractedType
      \ :call s:PutExtractedStuff("<bang>", s:type)


vnoremap <silent> <c-x>f :call <sid>ExtractFunction(1,INPUT("Name for the function to extract: "))<cr>
vnoremap <silent> <c-x>v :call <sid>ExtractVariable(1,INPUT("Name for the variable to extract: "))<cr>
vnoremap <silent> <c-x>t :call <sid>ExtractType(1,INPUT("Name for the type to extract"))<cr>
nnoremap <silent> <c-x>P <c-\><c-N>:call <sid>PutExtractedLast('!')<cr>
nnoremap <silent> <c-x>p <c-\><c-N>:call <sid>PutExtractedLast('')<cr>

" Commands and mappings }}}1
"------------------------------------------------------------------------
" Definitions for the various langages      {{{1        -----------------
" Helpers                                        {{{2         -----------
" RefactorH_func(signature)                                {{{3
" Global helper function that builds the signature of a function by
" adding parenthesis after the text given. If there is already a
" parenthesis in the text, nothing is added.
" Valable with most languages: C, vimL, ...
function! RefactorH_func(sig)
  if stridx(a:sig, '(') < 0
    return a:sig . '(' . Marker_Txt('Parameters') . ')'
  else
    return a:sig
  endif
endfunction

" s:IsCConst(varName)                                      {{{3
" Tells whether the variable name looks like a constant (all upper case / start
" with k_)
function! s:IsCConst(variableName)
  let isConst = a:variableName =~ '^k_\|\u[A-Z0-9_]*'
  return isConst
endfunction

" Callbacks for the various languages            {{{2         -----------
" C, C++, Java                                             {{{3
function! Refactor_EM_c(part, ...)
  if     a:part == 'begin'
    return Marker_Txt('ReturnType').' '.RefactorH_func(a:1) . "\n{"
  elseif a:part == 'end'
    return "\n}".Marker_Txt()."\n"
  elseif a:part == 'call'
    return RefactorH_func(a:1).Marker_Txt().';'.Marker_Txt()
  endif
endfunction

let g:refactor_EM_cpp_is_like  = "c"
let g:refactor_EM_java_is_like = "c"

function! Refactor_EV_c(part, ...)
  if     a:part == 'assign'
    return ' = '
  elseif a:part == 'type'
    return Marker_Txt('type').' '
  elseif a:part == 'mutable'
    return s:IsCConst(a:1)
	  \ ? (exists('c_no_c99') ? '#define ' : 'const ')
	  \ : ''
  elseif a:part == 'eol'
    return ';'
  endif
endfunction

function! Refactor_EV_cpp(part, ...)
  if     a:part == 'assign'
    return ' = '
  elseif a:part == 'type'
    return Marker_Txt('auto').' '
  elseif a:part == 'mutable'
    return s:IsCConst(a:1)
	  \ ? 'const '
	  \ : Marker_Txt('const ')
  elseif a:part == 'eol'
    return ';'
  endif
endfunction

let g:refactor_ET_cpp_is_like  = "c"
function! Refactor_ET_c(typeName, typeDefinition)
  return 'typedef ' . a:typeDefinition . ' ' . a:typeName . ';'
endfunction

" VimL                                                     {{{3
function! Refactor_EM_vim(part, ...)
  if     a:part == 'begin'
    return 'function! s:'.RefactorH_func(a:1)
  elseif a:part == 'end'
    return "\nendfunction\n"
  elseif a:part == 'call'
    return 's:'.RefactorH_func(a:1)
  endif
endfunction

function! Refactor_EV_vim(part, ...)
  if     a:part == 'assign'
    return ' = '
  elseif a:part == 'type'
    return 'let '
  elseif a:part == 'mutable'
    return ''
  elseif a:part == 'eol'
    return ''
  endif
endfunction

" Pascal                                                   {{{3

function! s:FuncName(sig)
  let idx = stridx(a:sig, '(')
  if  idx < 0
    return a:sig
  else
    return strpart(a:sig, 0, idx)
  endif
endfunction

function! Refactor_EM_pascal(part,...)
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
	    \ Marker_Txt('ReturnType'). "\nbegin"
    endif
  elseif a:part == 'end'
    return ((s:type=='f') ? s:FuncName(a:1).' := '.Marker_Txt('Value')."\n": '')
	  \ . 'end'
  elseif a:part == 'call'
    if s:type == 'p'
      return RefactorH_func(a:1)
    else " function
      return Marker_Txt('Result').' := '.RefactorH_func(a:1)
    endif
  endif
endfunction

" Definitions for the various langages      }}}1        -----------------
"------------------------------------------------------------------------
" Functions                                 {{{1        -----------------
"
" Options                                        {{{2         -----------
"
" s:Option(ft, name)                                       {{{3
function! s:Option(ft, refactorKind, name, param)
  let opt = 'Refactor_'.a:refactorKind.'_'.a:ft
  if exists('*'.opt)
    return {opt}(a:name, a:param)
  else
    let as = 'g:refactor_'.a:refactorKind.'_'.a:ft.'_is_like'
    if exists(as)
      return s:Option({as}, a:refactorKind, a:name, a:param)
    else
      throw "refactor.vim: Please define ``".opt."()''"
    endif
  endif
endfunction


" Refactoring lines in a new function            {{{2         -----------
" s:ExtractFunction( [name ... signature] ) range          {{{3
" Main function called by :ExtractFunction
" @pre: the selection must be line-wise
function! s:ExtractFunction(mayabort, ...) range abort
  if a:0 == 1 && (strlen(a:1)==0) && a:mayabort
    throw "ExtractFunction: Please specify a name for the new function"
  endif
  " New text to insert
  " -- In case not every thing is configured, it will abort the extraction
  let sig   = (a:0 == 0) ? Marker_Txt('FunctionName') : a:1
  let call  = s:Option(&ft, 'EM', 'call',  sig)
  let begin = s:Option(&ft, 'EM', 'begin', sig) . "\n"
  let end   = s:Option(&ft, 'EM', 'end',   '')

  try
    let a_save = @a

    " Extract what will become the body of the function
    '<,'>delete a

    " Put the call to the function in place of the code extracted
    silent! put!=call
    " Reindent
    silent! normal! ==

    " Prepare the function body
    " TODO: use g:c_nl_before_curlyB / g:c_nl_before_curlyB_for_function
    let s:fn = begin
    let s:fn .= @a
    if exists('b:usemarks') && b:usemarks
      let s:fn .= "\n" . Marker_Txt()
    endif
    let s:fn .= end

    let s:last_refactor='fn'

  finally
    " Restaure the register @a
    let @a = a_save
  endtry
endfunction

" Refactoring expression in a new variable       {{{2         -----------
" s:ExtractVariable( [name] ) range                        {{{3
" Main function called by :ExtractFunction
" @pre: the selection is not expected to be line-wise
function! s:ExtractVariable(mayabort, variableName) range abort
  if a:0 == 1 && (strlen(a:1)==0) && a:mayabort
    throw "ExtractVariable: Please specify a name for the new variable"
  endif
  let assign  = s:Option(&ft, 'EV', 'assign',   a:variableName)
  let type    = s:Option(&ft, 'EV', 'type',     a:variableName)
  let mutable = s:Option(&ft, 'EV', 'mutable',  a:variableName)
  let eol     = s:Option(&ft, 'EV', 'eol',  	a:variableName)

  try
    let a_save = @a

    " Extract the selected expression into register @a
    exe "normal! gv\"ac".a:variableName
    let s:variable = mutable . type . a:variableName . assign . @a . eol
    let s:last_refactor='variable'
  finally
    " Restaure the register @a
    let @a = a_save
  endtry
endfunction


" Extract a type                                 {{{2         -----------
" s:ExtractType( [name] ) range                        {{{3
" Main function called by :ExtractFunction
" @pre: the selection is not expected to be line-wise
function! s:ExtractType(mayabort, typeName) range abort
  if a:0 == 1 && (strlen(a:1)==0) && a:mayabort
    throw "ExtractVariable: Please specify a name for the new type"
  endif

  try
    let a_save = @a

    " Extract the selected text into register @a
    exe "normal! gv\"ac".a:typeName
    let s:type = s:Option(&ft, 'ET', a:typeName, @a)
    let s:last_refactor='type'
  finally
    " Restaure the register @a
    let @a = a_save
  endtry
endfunction


" General functions                              {{{2         -----------
" s:PutExtractedStuff([bang])                              {{{3
function! s:PutExtractedStuff(bang, what)
  " Put the function
  if "!" == a:bang
    silent! put!=a:what
  else
    silent! put=a:what
  endif
  " Reindent the code inserted
  silent! '[,']normal! ==
endfunction


" s:PutExtractedLast()                                     {{{3
function! s:PutExtractedLast(bang)
  call s:PutExtractedStuff(a:bang, s:{s:last_refactor})
endfunction



" Functions                                 }}}1        -----------------
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
