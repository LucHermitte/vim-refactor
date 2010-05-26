"=============================================================================
" $Id$
" File:		autoload/lh/refactor.vim                                 {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:	0.1.0
" Created:	31st Oct 2008
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	
" 	Language independent refactoring suite
" 
"------------------------------------------------------------------------
" Installation:
" 	Requires Vim 7.1+, and lh-vim-lib v2.2.0+
" 	Drop this file into {rtp}/autoload/lh
"
" History:	
" 	v0.1.0 new kernel built on top of lh#function
" TODO:		
" 	- support <++> as placeholder marks, and automatically convert them to
" 	the current ones
" 	- jump to the first placeholder
" 	- should I simplify the use to rely on mu-template expansion engine ?
"       - option to return nothing from lh#refactor#placeholder() when
"       |b:usemarks| is false
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" # Helper functions                             {{{2         -----------
" s:ConstKey(varName)                                       {{{3
function! lh#refactor#const_key(varName)
  let res = s:IsCConst(a:varName) ? (exists('c_no_c99') ? '#define ' : 'const ') : '' 
  return res
endfunction
" s:IsCConst(varName)                                       {{{3
" Tells whether the variable name looks like a constant (all upper case / start
" with k_)
function! s:IsCConst(variableName)
  let isConst = a:variableName =~ '^k_\|\u[A-Z0-9_]*'
  return isConst
endfunction

" lh#refactor#hfunc(signature)                              {{{3
" Global helper function that builds the signature of a function by
" adding parenthesis after the text given. If there is already a
" parenthesis in the text, nothing is added.
" Valable with most languages: C, vimL, ...
function! lh#refactor#hfunc(sig)
  if stridx(a:sig, '(') < 0
    return a:sig . '(' . Marker_Txt('Parameters') . ')'
  else
    return a:sig
  endif
endfunction

" lh#refactor#_add_key(dict, varname, value)                {{{3
" internal, but addressable function.
function! lh#refactor#_add_key(dict, varname, value)
  " echo "dict".string(a:dict)
  " echo "varname".a:varname
  let a:dict[a:varname] = a:value
  return ''
endfunction

" lh#refactor#let(dict, varname, value)                     {{{3
function! lh#refactor#let(varname, value)
  let f = lh#function#bind("lh#refactor#_add_key(v:1_, ".string(a:varname).','.(a:value).")")
  return f
endfunction

" lh#refactor#placeholder(text [, extra])                   {{{3
" todo: ooption to return nothing when |b:usemarks| is false
function! lh#refactor#placeholder(text, ...)
  let f = lh#function#bind('Marker_Txt('.string(a:text).')'. ((a:0) ? '.'.string(a:1 ): ''))
  return f
endfunction

" ## Definitions {{{1

" # (re)set {{{2
if !exists('g:refactor_params') || lh#option#get("refactor_params_reset", 0, 'g')
  let g:refactor_params = {
	\ 'EM': {},
	\ 'EV': {}, 'EV_name': {},
	\ 'ET': {}
	\}
endif

" # Fill function {{{2
function! s:ForceToExist(table, key)
  if !has_key(a:table, a:key)
    let a:table[a:key] = {}
  endif
endfunction

function! lh#refactor#fill(refactoring, ft, element, value)
  call s:ForceToExist(g:refactor_params[a:refactoring], a:ft)
  let familly = g:refactor_params[a:refactoring][a:ft]
  call s:ForceToExist(familly, a:element)
  let familly[a:element] = a:value
endfunction

" # Inherit function {{{2
function! lh#refactor#inherit(refactoring, ft_parent, ft_child, deepcopy)
  let refactoring = g:refactor_params[a:refactoring]
  " for [element,def] in items(refactoring)
  let def = refactoring
    if has_key(def, a:ft_parent)
      if a:deepcopy
	let def[a:ft_child] = deepcopy(def[a:ft_parent]) 
      else
	let def[a:ft_child] = def[a:ft_parent] 
      endif
    endif
  " endfor
endfunction


" # Extract Method                               {{{2         -----------
" C & familly                                               {{{3         -----------
call lh#refactor#fill('EM', 'c', '_call', ['call'])
call lh#refactor#fill('EM', 'c', '_function', ['begin', '_body', 'end'])

call lh#refactor#fill('EM', 'c', 'placeholder', lh#refactor#placeholder(''))
call lh#refactor#fill('EM', 'c', 'NL',          "\n")
call lh#refactor#fill('EM', 'c', 'rettype',     lh#refactor#placeholder('ReturnType', ' '))
call lh#refactor#fill('EM', 'c', 'fsig',        lh#function#bind('lh#refactor#hfunc(v:1_._fname)'))
call lh#refactor#fill('EM', 'c', 'open',        "\n{")
call lh#refactor#fill('EM', 'c', 'begin',       ['rettype', 'fsig', 'open', 'NL'])
call lh#refactor#fill('EM', 'c', 'close',       "\n}")
call lh#refactor#fill('EM', 'c', 'end',         ['close', 'placeholder', 'NL'])
call lh#refactor#fill('EM', 'c', 'call',        lh#function#bind("lh#refactor#hfunc(v:1_._fname).';'.Marker_Txt()", '_fname'))

call lh#refactor#inherit('EM', 'c', 'cpp', 0)
call lh#refactor#inherit('EM', 'c', 'java', 0)


" VimL                                                      {{{3         -----------
call lh#refactor#fill('EM', 'vim', '_call',      ['call'])
call lh#refactor#fill('EM', 'vim', '_function',  ['begin', '_body', 'end'])

call lh#refactor#fill('EM', 'vim', 'call',       lh#function#bind("'call '.lh#refactor#hfunc(v:1_._fname).Marker_Txt()", '_fname'))
call lh#refactor#fill('EM', 'vim', 'begin',      ['k_function', 'fsig', 'NL'])
call lh#refactor#fill('EM', 'vim', 'k_function', "function! ")
call lh#refactor#fill('EM', 'vim', 'fsig',       lh#function#bind('lh#refactor#hfunc(v:1_._fname)'))
call lh#refactor#fill('EM', 'vim', 'NL',         "\n")
call lh#refactor#fill('EM', 'vim', 'end',        ['k_endf', 'placeholder', 'NL'])
call lh#refactor#fill('EM', 'vim', 'k_endf',     "endfunction")
call lh#refactor#fill('EM', 'vim', 'placeholder', lh#refactor#placeholder(''))


" Shell scripts (sh, bash, ...)                             {{{3         -----------
call lh#refactor#fill('EM', 'sh', '_call',       ['fcall'])
call lh#refactor#fill('EM', 'sh', 'fcall',       lh#function#bind('v:1_._fname ." ".Marker_Txt("parameters")') )
call lh#refactor#fill('EM', 'sh', '_function',   ['begin', '_body', 'end'])
call lh#refactor#fill('EM', 'sh', 'begin',       [ 'fsig', 'open' ] )
call lh#refactor#fill('EM', 'sh', 'fsig',        lh#function#bind('v:1_._fname . "()"'))
call lh#refactor#fill('EM', 'sh', 'open',        " {\n" )
call lh#refactor#fill('EM', 'sh', 'end',         ['placeholder', 'close', 'placeholder'] )
call lh#refactor#fill('EM', 'sh', 'placeholder', lh#refactor#placeholder(''))
call lh#refactor#fill('EM', 'sh', 'close',       "\n}" )


" Pascal                                                    {{{3         -----------
call lh#refactor#fill('EM', 'pascal', '_call',      ['ask_kind', 'call'])
call lh#refactor#fill('EM', 'pascal', 'ask_kind',   lh#refactor#let('kind_', "WHICH('CONFIRM', 'nature of the routine? ', 'function\nprocedure', 1)"))
call lh#refactor#fill('EM', 'pascal', '_function',  ['begin', '_body', 'return', 'end'])

call lh#refactor#fill('EM', 'pascal', 'call',       lh#function#bind("(v:1_.kind_ == 'function' ? Marker_Txt('variable').' := ' : '') . lh#refactor#hfunc(v:1_._fname).';'.Marker_Txt()", '_fname'))
call lh#refactor#fill('EM', 'pascal', 'begin',      ['kind_', 'SPACE', 'fsig', 'NL', 'vars', 'NL', 'k_begin', 'NL'])
call lh#refactor#fill('EM', 'pascal', 'vars',       lh#refactor#placeholder('var', ';'))
call lh#refactor#fill('EM', 'pascal', 'fsig',       lh#function#bind('lh#refactor#hfunc(v:1_._fname)'))
call lh#refactor#fill('EM', 'pascal', 'SPACE',      " ")
call lh#refactor#fill('EM', 'pascal', 'NL',         "\n")
call lh#refactor#fill('EM', 'pascal', 'return',     lh#function#bind("v:1_.kind_ == 'function' ? (v:1_._fname) . ' := '.Marker_Txt('value').';\n' : ''"))
call lh#refactor#fill('EM', 'pascal', 'end',        ['k_end', 'placeholder', 'NL'])
call lh#refactor#fill('EM', 'pascal', 'k_begin',    "begin")
call lh#refactor#fill('EM', 'pascal', 'k_end',      "end")
call lh#refactor#fill('EM', 'pascal', 'placeholder', lh#refactor#placeholder(''))

" # Refactoring expression in a new variable     {{{2         -----------
" C & familly                                               {{{3         -----------
call lh#refactor#fill('EV', 'c', '_use',         ['_varname'])
call lh#refactor#fill('EV', 'c', '_definition',  ['mutable', 'type', '_varname', 'assign', '_value', 'eol'])
call lh#refactor#fill('EV', 'c', 'assign',       ' = ')
call lh#refactor#fill('EV', 'c', 'eol',          ';')
call lh#refactor#fill('EV', 'c', 'type',         lh#refactor#placeholder('type', ' '))
call lh#refactor#fill('EV', 'c', 'mutable',      lh#function#bind(function('lh#refactor#const_key'), 'v:1_._varname'))

call lh#refactor#inherit('EV', 'c', 'cpp', 1)
" overide type for C++
call lh#refactor#fill('EV', 'cpp', 'type',         lh#refactor#placeholder('auto', ' ')) " C++0x


" VimL                                                      {{{3         -----------
call lh#refactor#fill('EV', 'vim', '_use',         ['_varname'])
call lh#refactor#fill('EV', 'vim', '_definition',  ['let', '_varname', 'assign', '_value'])
call lh#refactor#fill('EV', 'vim', 'assign',       ' = ')
call lh#refactor#fill('EV', 'vim', 'let',          'let ')

" Perl                                                      {{{3         -----------
call lh#refactor#fill('EV', 'perl', '_use',         ['_varname'])
call lh#refactor#fill('EV', 'perl', '_definition',  ['my', '_varname', 'assign', '_value', 'eol'])
call lh#refactor#fill('EV', 'perl', 'assign',       ' = ')
call lh#refactor#fill('EV', 'perl', 'my',           'my ')
call lh#refactor#fill('EV', 'perl', 'eol',          ';')

call lh#refactor#fill('EV_name', 'perl',            '_naming_policy', ['$'])
call lh#refactor#fill('EV_name', 'perl', '$',       '$')


" # Extract Type                                 {{{2         -----------
" C & familly                                               {{{3         -----------
call lh#refactor#fill('ET', 'c', '_use',         ['_typename'])
call lh#refactor#fill('ET', 'c', '_definition',  ['typedef', '_typeexpression', 'space', '_typename', 'eol'])
call lh#refactor#fill('ET', 'c', 'typedef',      'typedef ')
call lh#refactor#fill('ET', 'c', 'space',        ' ')
call lh#refactor#fill('ET', 'c', 'eol',          ';')

call lh#refactor#inherit('ET', 'c', 'cpp', 1)


" ## Functions {{{1
" # Debug                                        {{{2         -----------
function! lh#refactor#verbose(level)
  let s:verbose = a:level
endfunction

function! s:Verbose(expr)
  if exists('s:verbose') && s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#refactor#echo(expr)
  echo eval(a:expr)
endfunction

" # Options                                      {{{2         -----------
"
" s:Option(ft, refactoring, name, param)                    {{{3
function! s:Option(ft, refactorKind, name, param)
  " let opt = g:refactor_params[a:refactorKind][a:name][a:ft]
  let kind = g:refactor_params[a:refactorKind]
  let familly = kind[a:ft]
  let opt = familly[a:name]
  if type(opt)==type({}) && has_key(opt, 'execute')
    let res = lh#function#execute(opt, a:param)
  else
    let res = opt
  endif
  return res
  " throw "refactor.vim: Please define ``".opt."()''"
endfunction

" s:Concat(ft, refactoring, elements, variables)            {{{3
function! s:Concat(ft, refactoring, lElements, variables)
  let result = ''
  for element in a:lElements
    if has_key(a:variables, element)
      let s = a:variables[element]
    else
      let r = s:Option(a:ft, a:refactoring, element, a:variables)
      if type(r) == type([])
	let s = s:Concat(a:ft, a:refactoring, r, a:variables)
      else
	let s = r
      endif
      unlet r
    endif
    let result .= s
  endfor
  return result
endfunction

" # Extract METHOD                               {{{2         -----------
" lh#refactor#extract_function( [name] ) range              {{{3
" Main function called by :ExtractFunction
" @pre: the selection must be line-wise
" @todo: determine external variables, and returned data
function! lh#refactor#extract_function(mayabort, functionName) range abort
  if (strlen(a:functionName)==0) && a:mayabort
    throw "ExtractFunction: Please specify a name for the new function"
  endif
  let lCall     = s:Option(&ft, 'EM', '_call', '')
  let lFunction = s:Option(&ft, 'EM', '_function', '')

  let params    = {'_fname': a:functionName}
  let sCall     = s:Concat(&ft, 'EM', lCall, params)

  try
    let a_save = @a

    " Extract what will become the body of the function into register @a
    '<,'>yank a

    " Prepare the function body
    let params['_body'] = @a " reuse the same variable as _call may have added some data to params
    let sFunction = s:Concat(&ft, 'EM', lFunction, params)
    " Preparation OK => commit the modification
    '<,'>delete a

    " Put the call to the function in place of the code extracted
    silent! put!=sCall
    " Reindent
    silent! normal! ==

    let s:function = sFunction
    let s:last_refactor='function'
  finally
    " Restaure the register @a
    let @a = a_save
  endtry
endfunction


" # Refactoring expression in a new VARIABLE     {{{2         -----------
" lh#refactor#extract_variable( [name] ) range              {{{3
" Main function called by :ExtractVariable
" @pre: the selection is not expected to be line-wise

function! lh#refactor#extract_variable(mayabort, variableName) range abort
  if (strlen(a:variableName)==0) && a:mayabort
    throw "ExtractVariable: Please specify a name for the new variable"
  endif
  let lUse        = s:Option(&ft, 'EV', '_use', '')
  let lDefinition = s:Option(&ft, 'EV', '_definition', '')

  let params      = {'_varname': a:variableName}
  let sUse        = s:Concat(&ft, 'EV', lUse       , params)

  try
    let a_save = @a

    " Extract the selected expression into register @a
    exe "normal! gv\"ac".sUse
    let params['_value'] = @a " reuse the same variable as _use may have added some data to params
    let sDefinition = s:Concat(&ft, 'EV', lDefinition, params)
    let s:variable = sDefinition
    let s:last_refactor='variable'

    let continue = CONFIRM("Replace other occurrences of `".@a."' ?", "&Yes\n&No", 1)
    if continue == 1
      let p = getpos('.')
      try 
        :exe ':%s/\V'.escape(@a,'/\').'/'.sUse.'/cg'
      finally
        call setpos('.',p)
      endtry
    endif
  finally
    " Restaure the register @a
    let @a = a_save
  endtry


endfunction

" lh#refactor#default_varname()                             {{{3
" Helper function called by :ExtractVariable
" @pre: the selection is not expected to be line-wise
function! lh#refactor#default_varname()
  let expression = lh#visual#selection()
  " try to determine type or any other meaningful thing (may not be possible...)
  try 
    let lVarNameData = s:Option(&ft, 'EV_name', '_naming_policy', '') 
  catch /.*/
    " no key => default a default empty name
    return ""
  endtry
  let sName = s:Concat(&ft, 'EV_name', lVarNameData, {'_value':expression})
  return sName
endfunction

" # Extract a TYPE                               {{{2         -----------
" lh#refactor#extract_type( [name] ) range                 {{{3
" Main function called by :ExtractType
" @pre: the selection is not expected to be line-wise

function! lh#refactor#extract_type(mayabort, typeName) range abort
  if (strlen(a:typeName)==0) && a:mayabort
    throw "ExtractType: Please specify a name for the new type"
  endif
  let lUse        = s:Option(&ft, 'ET', '_use', '')
  let lDefinition = s:Option(&ft, 'ET', '_definition', '')

  let params      = {'_typename': a:typeName}
  let sUse        = s:Concat(&ft, 'EV', lUse       , params)

  try
    let a_save = @a

    " Extract the selected expression into register @a
    exe "normal! gv\"ac".sUse
    let params['_typeexpression'] = @a
    let sDefinition = s:Concat(&ft, 'ET', lDefinition, params)
    let s:type = sDefinition
    let s:last_refactor='type'
  finally
    " Restaure the register @a
    let @a = a_save
  endtry
endfunction

" General functions                              {{{2         -----------
" lh#refactor#put_extracted_stuff(bang,what)                {{{3
function! lh#refactor#put_extracted_stuff(bang, what)
  " Put the function
  if "!" == a:bang
    silent! put!=a:what
  else
    silent! put=a:what
  endif
  " Reindent the code inserted
  silent! '[,']normal! ==
endfunction


" s:PutExtractedLast()                                      {{{3
function! lh#refactor#put_extracted_last(bang)
  call lh#refactor#put_extracted_stuff(a:bang, s:{s:last_refactor})
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
