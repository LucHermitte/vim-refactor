"=============================================================================
" File:         autoload/lh/refactor.vim                                 {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-refactor>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-refactor/tree/master/License.md>
" Version:      2.0.0
let s:k_version = 200
" Created:      31st Oct 2008
" Last Update:  05th Mar 2019
"------------------------------------------------------------------------
" Description:
"       Language independent refactoring suite
"
"------------------------------------------------------------------------
" Installation:
"       Requires Vim 7.1+, lh-vim-lib v2.2.1+, and lh-dev v0.0.3 (for setter/getter)
"       Takes advantage of lh-tags v0.2.2 (and ctags) and lh-dev v0.0.1 when
"       installed to implement a smart Extract Method refactoring.
"       Drop this file into {rtp}/autoload/lh
"
" History:
"       v0.1.0 New kernel built on top of lh#function
"       v0.2.0 Smart Extract Method refactoring
"       v0.2.1 Extract shell variables
"       v0.2.2 Getter/Setter
"       v0.2.3 Bug fixes in Getter/Setter
"              New helper functions lh#refactor#snippet() and
"              lh#refactor#opt_snippet()
"       v1.0.0 GPLv3
"       v1.1.0 FixRealloc
"       v1.2.0 Can be extended thanks to external files
"              Bugs fixed regarding snippets for *extracting variables*.
"       v1.2.6 Deprecate `CONFIRM()` & co
"       v2.0.0 Migrate dependencies from lh-dev to lh-vim-lib/lh-style
"              Use current indent by default when indenting (typically extract
"              variable in Python)
"
" TODO:
"       - support <++> as placeholder marks, and automatically convert them to
"       the current ones
"       - jump to the first placeholder
"       - should I simplify the use to rely on mu-template expansion engine ?
"       - option to return nothing from lh#refactor#placeholder() when
"       |[bg]:usemarks| is false
"       - implement choices.
"         for instance, "T(args)" shall be understood as a constructor call in
"         C++ and thus result into "T {var}(args)".
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" # Helper functions                             {{{2         -----------
" s:ConstKey(varName)                                       {{{3
function! lh#refactor#const_key(varName) abort
  let res = s:IsCConst(a:varName) ? (exists('c_no_c99') ? '#define ' : 'const ') : ''
  return res
endfunction
" s:IsCConst(varName)                                       {{{3
" Tells whether the variable name looks like a constant (all upper case / start
" with k_)
function! s:IsCConst(variableName) abort
  let isConst = a:variableName =~ '^k_\|\u[A-Z0-9_]*'
  return isConst
endfunction

" lh#refactor#hfunc(dict,params)                            {{{3
" Global helper function that builds the signature of a function by
" adding parenthesis after the text given. If there is already a
" parenthesis in the text, nothing is added.
" Valable with most languages: C, vimL, ...
" @param a:dict._fname -> function name
" @param a:key         -> parameter in a:dict.{a:key}
function! lh#refactor#hfunc(dict, params) abort
  " echomsg "lh#refactor#hfunc(".string(a:dict).' ## '.string(a:params).')'
  let result = a:dict._fname
  if has_key(a:dict, a:params)
    let result .= '('. (a:dict[a:params]) . ')'
  endif
  return result
endfunction

function! lh#refactor#hfunc_def_full(dict, params) abort
  let result = a:dict._fname_full
  if has_key(a:dict, a:params)
    let result .= '('. (a:dict[a:params]) . ')'
  endif
  return result
endfunction

" lh#refactor#_add_key(dict, varname, value)                {{{3
" internal, but addressable function.
function! lh#refactor#_add_key(dict, varname, value) abort
  " echo "dict".string(a:dict)
  " echo "varname".a:varname
  let a:dict[a:varname] = a:value
  return ''
endfunction

" lh#refactor#let(varname, value)                           {{{3
function! lh#refactor#let(varname, value) abort
  let f = lh#function#bind("lh#refactor#_add_key(v:1_, ".string(a:varname).','.(a:value).")")
  return f
endfunction

" lh#refactor#placeholder(text [, extra])                   {{{3
" todo: option to return nothing when |b:usemarks| is false
function! lh#refactor#placeholder(text, ...) abort
  let f = lh#function#bind('lh#marker#txt('.string(a:text).')'. ((a:0) ? '.'.string(a:1 ): ''))
  return f
endfunction

" lh#refactor#snippet(text)                                 {{{3
" todo: option to return nothing when |b:usemarks| is false
function! lh#refactor#snippet(text) abort
  let text = '"' . substitute(a:text, '${\(\k\{-}\)}', '".v:1_.\1."', 'g') . '"'
  " let text = string(text)
  let f = lh#function#bind(text)
  return f
endfunction

function! lh#refactor#opt_snippet(option) abort
  let snippet = lh#ft#option#get(a:option, &ft, '')
  let f = lh#function#bind("lh#refactor#snippet(lh#ft#option#get(".string(a:option).", &ft, ''))")
  return f
endfunction

" EM: automagic parameters {{{3

function! s:CheckUsed(variables, lines) abort
  let used = []
  let is_continuing_comment = 0
  for l in a:lines
    " purge comments -- doesn't support #if 0
    let [l2, is_continuing_comment] = lh#dev#purge_comments(l, is_continuing_comment)
    " for each variable check its presence in the line
    let i = 0
    while i < len(a:variables)
      let v = a:variables[i]
      if match(l2, '\<'. (v.name) . '\>') != -1
        call add(used, v)
        call remove(a:variables, i)
        if empty(a:variables) | return used | endif
        break
      endif
      let i+= 1
    endwhile
  endfor
  return used
endfunction

function! s:SearchParameters(extract_begin, extract_end, extr_fn_name, lCall, lFunction) abort
  try
    call lh#dev#start_tag_session()

    let extr_fn_name = a:extr_fn_name

    " 1- Obtain function boundaries
    let fn = lh#dev#find_function_boundaries(a:extract_begin)

    " 2- Find the variables declared in the function
    let params = [fn.lines] + a:000
    " let lVariables = call (function('lh#dev#get_variables'),params)
    let lVariables = lh#dev#get_variables(fn.lines, a:extract_begin, a:extract_end)

    " 2.1- sort the variables extracted, the variables declared before and used
    " by the extracted code
    let extracted_lines = getline(a:extract_begin, a:extract_end)

    let original_parameters = lh#dev#function#get_(fn.fn, 'parameters')
    for p in original_parameters
      let p.line = -1 " and not as this is a parameter of the original function fn.lines[0]
    endfor
    let before_variables    = lVariables[0] + original_parameters
    let extracted_variables = lVariables[1]
    let after_variables     = lVariables[2]

    let required_variables = s:CheckUsed(before_variables, extracted_lines)

    let after_lines = getline(a:extract_end+1, fn.lines[1])
    let exported_variables = s:CheckUsed(copy(extracted_variables), after_lines)
    " at this point, before_variables == unused_variables

    " 2.2- if the function is actually a member/function class, check whether
    " its member are required by the extracted part
    let class
          \ = has_key(fn.fn, 'class')  ? fn.fn.class
          \ : has_key(fn.fn, 'struct') ? fn.fn.struct
          \ : ''
    if !empty(class)
      call s:Verbose("CLASS=".class)
      let members = lh#dev#class#members(class)
      " strip class name from members
      let class_prefix = class . lh#dev#class#sep_decl()
      " call map(members, '{"name": substitute((v:val).name, '.string(class_prefix).', "", "g")}')
      let lMembers = lh#list#transform(members, [], 'substitute((v:1_).name, '.string(class_prefix).', "", "g")')
      let lMembers = lh#list#unique_sort(lMembers)
      let members = lh#list#transform(lMembers, [], '{"name": v:1_}')
      " call s:Verbose("MEMBERS=".join(lh#list#transform(members, [], 'v:1_.name'), ','))
      let required_members = s:CheckUsed(members, extracted_lines)
      if !empty(required_members)
        " needs to be in a class
        let lClass = [class]
      else
        " may also be in a class
        let lClass = [class, '']
      endif
      call s:Verbose("REQUIRED MEMBERS=".
            \ join(lh#list#transform(required_members, [],
            \ 'v:1_.name'), ','))
    else
      " Being in a class makes no sense ?
      let lClass = []
    endif


    " 2.3- if a return statement was extracted, forward it
    let return_re = lh#ft#option#get('return_pattern', &ft, '\<return\>')
    let first_return_line = lh#list#match(extracted_lines, return_re)

    " 2.4- sort the variables extracted reused after the extracted part
    " (if more than one, propose a way to export them)

    call s:Verbose("FUNCTION=".string(fn))
    " - unused ... it speaks for itself!
    call s:Verbose("UNUSED VARIABLES=".
          \ join(lh#list#transform(before_variables, [],
          \ '(v:1_.line) .":".(v:1_.name)'), ','))
    " - variables that needs to be passed to the function called
    call s:Verbose("USED VARIABLES=".
          \ join(lh#list#transform(required_variables, [],
          \ '(v:1_.line) .":".(v:1_.name)'), ','))
    " - variables that need to be declared in the function called
    "   unless they must be exported nothing has to be done
    call s:Verbose("EXTRACTED VARIABLES=".
          \ join(lh#list#transform(extracted_variables, [],
          \ '(v:1_.line) .":".(v:1_.name)'), ','))
    " - variables that need to be exported
    " if only 1, and no return, the export may be done through return
    call s:Verbose("EXPORTED VARIABLES=".
          \ join(lh#list#transform(exported_variables, [],
          \ '(v:1_.line) .":".(v:1_.name)'), ','))
    " - variables that does not concern us
    call s:Verbose("POST VARIABLES=".
          \ join(lh#list#transform(after_variables, [],
          \ '(v:1_.line) .":".(v:1_.name)'), ','))
    " - if first_return_line != -1 && original return type != void
    "  => must reuse the return type, if it means something to the {ft}
    "  =/> we can also propose to use tuples, structs, lists, ...
    call s:Verbose("RETURN=".first_return_line.':')
    " - plus beware of required parameters a that are modified, and used in the
    "   third part


    " Prepare the unique parameter that rule them all
    let parameters = { 'list': [] }

    for p in required_variables
      let p2 = deepcopy(p)
      let p2.dir = 'in'
      let p2.formal = lh#naming#param(p2.name)
      let p2.type   = lh#dev#function#get_(p, 'type')
      let parameters.list += [p2]
    endfor

    for p in exported_variables
      let p2 = deepcopy(p)
      let p2.dir = 'out'
      let p2.formal = lh#naming#param(p2.name)
      let p2.type   = lh#dev#function#get_(p, 'type')
      let parameters.list += [p2]
    endfor

    let data = {
          \ 'orig_fn'         : fn.fn,
          \ 'class'           : lClass,
          \ 'extr_fn'         : { 'name': extr_fn_name},
          \ 'parameters'      : parameters,
          \ 'orig_lines'      : fn.lines,
          \ 'extract_begin'   : a:extract_begin,
          \ 'extract_end'     : a:extract_end,
          \ 'extracted_lines' : extracted_lines,
          \ 'hook_call'       : a:lCall,
          \ 'hook_function'   : a:lFunction
          \ }
    return lh#refactor#gui_em#open(data)
  finally
    call lh#dev#end_tag_session()
  endtry
endfunction

function! lh#refactor#_do_EM_callback(data) abort
  " todo: leave the possibility for each formal parameter to be in a
  " placeholder
  "
  " In extracted lines, replace variables names with the corresponding
  " parameters
  let replacements = []
  for p in a:data.parameters.list
    if p.formal != p.name
      let replacements += [[p.name, p.formal]] " todo: special case for vim a: variables
    endif
  endfor

  let i = 0
  while i != len(a:data.extracted_lines)
    let l = a:data.extracted_lines[i]
    for r in replacements
      " todo: make the distinction between a variable and any other identifier
      " that may have the same name
      " -> may be by injecting &isk with scope/aggregation operators like ->,
      "  ., ::, ...
      let l = substitute(l, '\<'.r[0].'\>', r[1], 'g')
    endfor
    let a:data.extracted_lines[i] = l
    let i += 1
  endwhile

  " Build signature
  let sFormalParams = lh#dev#option#call('function#_parameters_to_signature', &ft, a:data.parameters.list)
  echomsg "formal params: ".sFormalParams

  " Build call
  let sRealParams = lh#dev#option#call('function#_build_real_params_list', &ft, a:data.parameters.list)
  echomsg "real params: ".sRealParams


  let fname_full = !empty(a:data.class)
        \ ? join([a:data.class[0], a:data.extr_fn.name], lh#dev#class#sep_decl())
        \ : a:data.extr_fn.name

  let params    = {
        \ '_fname'        : a:data.extr_fn.name,
        \ '_fname_full'   : fname_full,
        \ '_real_params'  : sRealParams,
        \ '_formal_params': sFormalParams
        \ }
  let sCall     = s:Concat(&ft, 'EM', a:data.hook_call, params)
  let params['_body'] = join(a:data.extracted_lines, "\n") " reuse the same variable as _call may have added some data to params
  " inject a call that know the parameters
  let sFunction = s:Concat(&ft, 'EM', a:data.hook_function, params)
  " Preparation OK => commit the modification
  silent exe (a:data.extract_begin).','.(a:data.extract_end).'delete _'

  " Put the call to the function in place of the code extracted
  silent! put!=sCall
  " Reindent
  silent! normal! ==

  let s:function = sFunction
  let s:last_refactor='function'
endfunction

" ## Definitions {{{1

" # (re)set {{{2
if !exists('g:refactor_params') || lh#option#get("refactor_params_reset", 0, 'g')
  let g:refactor_params = {
        \ 'EM': {},
        \ 'EV': {}, 'EV_name': {},
        \ 'ET': {},
        \ 'Es': {},
        \ 'Eg': {}
        \}
endif

" # Fill function {{{2
function! s:ForceToExist(table, key) abort
  if !has_key(a:table, a:key)
    let a:table[a:key] = {}
  endif
endfunction

function! lh#refactor#fill(refactoring, ft, element, value) abort
  call s:ForceToExist(g:refactor_params[a:refactoring], a:ft)
  let familly = g:refactor_params[a:refactoring][a:ft]
  call s:ForceToExist(familly, a:element)
  let familly[a:element] = a:value
endfunction

" # Inherit function {{{2
function! lh#refactor#inherit(refactoring, ft_parent, ft_child, deepcopy) abort
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


" ## Refactorings {{{1
"
" # Extract Method                               {{{2         -----------
" Pascal                                                    {{{3         -----------
call lh#refactor#fill('EM', 'pascal', '_call',      ['ask_kind', 'call'])
call lh#refactor#fill('EM', 'pascal', 'ask_kind',   lh#refactor#let('kind_', "lh#ui#which('lh#ui#confirm', 'nature of the routine? ', 'function\nprocedure', 1)"))
call lh#refactor#fill('EM', 'pascal', '_function',  ['begin', '_body', 'return', 'end'])

call lh#refactor#fill('EM', 'pascal', 'call',       lh#function#bind("(v:1_.kind_ == 'function' ? lh#marker#txt('variable').' := ' : '') . lh#refactor#hfunc(v:1_, '_real_params').';'.lh#marker#txt()", '_fname'))
call lh#refactor#fill('EM', 'pascal', 'begin',      ['kind_', 'SPACE', 'fsig', 'NL', 'vars', 'NL', 'k_begin', 'NL'])
call lh#refactor#fill('EM', 'pascal', 'vars',       lh#refactor#placeholder('var', ';'))
call lh#refactor#fill('EM', 'pascal', 'fsig',       lh#function#bind('lh#refactor#hfunc(v:1_, "_formal_params")'))
call lh#refactor#fill('EM', 'pascal', 'SPACE',      " ")
call lh#refactor#fill('EM', 'pascal', 'NL',         "\n")
call lh#refactor#fill('EM', 'pascal', 'return',     lh#function#bind("v:1_.kind_ == 'function' ? (v:1_._fname) . ' := '.lh#marker#txt('value').';\n' : ''"))
call lh#refactor#fill('EM', 'pascal', 'end',        ['k_end', 'placeholder', 'NL'])
call lh#refactor#fill('EM', 'pascal', 'k_begin',    "begin")
call lh#refactor#fill('EM', 'pascal', 'k_end',      "end")
call lh#refactor#fill('EM', 'pascal', 'placeholder', lh#refactor#placeholder(''))

" # Refactoring expression in a new variable     {{{2         -----------

" # Extract Type                                 {{{2         -----------

" # Extract Getter                               {{{2         -----------
" Generic definition for C++ inspired OO langages           {{{3         -----------
" no _use in that case
" Options: (b|g):[cpp_]refactor_getter_open, (b|g):[cpp_]refactor_getter_close, and (b|g):[cpp_]refactor_getter_doc, e.g.
LetIfUndef g:java_refactor_getter_open "\ {\n"
LetIfUndef g:java_refactor_getter_close "\n}"
LetIfUndef g:refactor_getter_doc   "/**\ ${_ppt_name}\ getter.\ */\n"
call lh#refactor#fill('Eg', '_oo_c_', '_definition',  ['doc', 'signature', 'body'])
call lh#refactor#fill('Eg', '_oo_c_', 'space',        ' ')
call lh#refactor#fill('Eg', '_oo_c_', 'eol',          ';')
call lh#refactor#fill('Eg', '_oo_c_', 'open',         lh#function#bind ("lh#ft#option#get('refactor_getter_open', &ft, ' { ')"))
call lh#refactor#fill('Eg', '_oo_c_', 'close',        lh#function#bind ("lh#ft#option#get('refactor_getter_close', &ft, '}')"))
call lh#refactor#fill('Eg', '_oo_c_', 'return',       "return ")
" call lh#refactor#fill('Eg', '_oo_c_', 'doc_',         lh#refactor#snippet("/** ${_ppt_name} getter. */\n"))
call lh#refactor#fill('Eg', '_oo_c_', 'doc',          lh#refactor#opt_snippet ('refactor_getter_doc'))
call lh#refactor#fill('Eg', '_oo_c_', 'postfix_',     "")
call lh#refactor#fill('Eg', '_oo_c_', 'prefix_',      "")
call lh#refactor#fill('Eg', '_oo_c_', 'signature',    ['rettype', 'space', 'fsig', 'postfix_'])
call lh#refactor#fill('Eg', '_oo_c_', 'rettype',      ['prefix_', '_static', '_type'])
call lh#refactor#fill('Eg', '_oo_c_', 'fsig',         lh#function#bind('lh#refactor#hfunc(v:1_, "_void")'))
call lh#refactor#fill('Eg', '_oo_c_', 'body',         ['open', 'return', '_name', 'eol', 'close'])

" # Extract Setter                               {{{2         -----------
" Generic definition for C++ inspired OO langages           {{{3         -----------
" no _use in that case
" Options: (b|g):[cpp_]refactor_setter_open, (b|g):[cpp_]refactor_setter_close, and (b|g):[cpp_]refactor_setter_doc, e.g.
LetIfUndef g:java_refactor_setter_open "\ {\n"
LetIfUndef g:java_refactor_setter_close "\n}"
LetIfUndef g:refactor_setter_doc   "/**\ ${_ppt_name}\ setter.\ */\n"
call lh#refactor#fill('Es', '_oo_c_', '_definition',  ['doc', 'signature', 'body'])
call lh#refactor#fill('Es', '_oo_c_', 'signature',    ['rettype', 'fsig', 'postfix_'])
call lh#refactor#fill('Es', '_oo_c_', 'rettype',      ['prefix_', '_static', 'void'])
call lh#refactor#fill('Es', '_oo_c_', 'fsig',         lh#function#bind('lh#refactor#hfunc(v:1_, "_args")'))
" call lh#refactor#fill('Es', '_oo_c_', 'doc_',         lh#refactor#snippet("/** ${_ppt_name} setter. */\n"))
call lh#refactor#fill('Es', '_oo_c_', 'doc',          lh#refactor#opt_snippet ('refactor_setter_doc'))
call lh#refactor#fill('Es', '_oo_c_', 'postfix_',     "")
call lh#refactor#fill('Es', '_oo_c_', 'prefix_',      "")
call lh#refactor#fill('Es', '_oo_c_', 'void',         'void ')
call lh#refactor#fill('Es', '_oo_c_', 'space',        ' ')
call lh#refactor#fill('Es', '_oo_c_', 'eol',          ';')
call lh#refactor#fill('Es', '_oo_c_', 'body',         ['open', '_instruction', 'close'])
call lh#refactor#fill('Es', '_oo_c_', 'open',         lh#function#bind ("lh#ft#option#get('refactor_setter_open', &ft, ' { ')"))
call lh#refactor#fill('Es', '_oo_c_', 'close',        lh#function#bind ("lh#ft#option#get('refactor_setter_close', &ft, ' } ')"))

" # Fix Realloc                                  {{{2         -----------
" C & familly                                               {{{3         -----------
" call lh#refactor#fill('FR', 'c', '_use',         ['_varname'])
" call lh#refactor#fill('FR', 'c', '_definition',  ['mutable', 'type', '_varname', 'assign', '_value', 'eol'])
" call lh#refactor#fill('FR', 'c', 'assign',       ' = ')
" call lh#refactor#fill('FR', 'c', 'eol',          ';')
" call lh#refactor#fill('FR', 'c', 'type',         lh#refactor#placeholder('type', ' '))
" call lh#refactor#fill('FR', 'c', 'mutable',      lh#function#bind(function('lh#refactor#const_key'), 'v:1_._varname'))

" call lh#refactor#inherit('FR', 'c', 'cpp', 1)


" ## Misc Functions     {{{1

" # Version                                      {{{2         -----------
function! lh#refactor#version()
  return s:k_version
endfunction

" # Debug                                        {{{2         -----------
let s:verbose = get(s:, 'verbose', 0)
function! lh#refactor#verbose(...)
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

function! lh#refactor#debug(expr) abort
  return eval(a:expr)
endfunction

" # Options                                      {{{2         -----------
"
" s:Option(ft, refactoring, name, param)                    {{{3
function! s:Option(ft, refactorKind, name, param) abort
  " let opt = g:refactor_params[a:refactorKind][a:name][a:ft]
  if ! has_key(g:refactor_params, a:refactorKind)
    throw "Unknown ".(a:refactorKind)." refactoring kind"
  endif
  let kind = g:refactor_params[a:refactorKind]
  if !has_key(kind, a:ft)
    throw (a:refactorKind)." refactoring kind is not supported in ".(a:ft)
  endif
  let familly = kind[a:ft]
  if !has_key(familly, a:name)
    let msg = 'No <'.a:name.'> kind for '.(a:refactorKind).' refactoring in '.(a:ft)
    throw msg
  endif
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
function! s:Concat(ft, refactoring, lElements, variables) abort
  let result = ''
  let lElements = type(a:lElements) == type([]) ? (a:lElements) : [a:lElements]
  for element in lElements
    if has_key(a:variables, element)
      let s = a:variables[element]
    else
      let r = s:Option(a:ft, a:refactoring, element, a:variables)
      " Loop in case a functor returns another functor as
      " lh#refactor#opt_snippet() does
      while type(r) == type({}) && has_key(r, 'execute')
        let r2 = lh#function#execute(r, a:variables)
        unlet r
        let r = r2
        unlet r2
      endwhile
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
  silent! exe "call lh#refactor#".&ft.'#load()'
  let lCall     = s:Option(&ft, 'EM', '_call', '')
  let lFunction = s:Option(&ft, 'EM', '_function', '')

  try
    let a_save = @a

    " Extract what will become the body of the function into register @a
    '<,'>yank a

    " Check about data
    try
      let async = 0
      if lh#tags#ctags_is_installed()
        let async = s:SearchParameters(a:firstline, a:lastline, a:functionName, lCall, lFunction)
      else
        call s:Verbose("ctags is not available, the extract method will be dumb")
      endif
    catch /E117.*lh#tags#ctags_is_installed/
      call s:Verbose("lh-tags is not installed, the extract method will be dumb:".v:exception)
    catch /E117.*lh#dev#find_function_boundaries/
      call s:Verbose("lh-dev is not installed, the extract method will be dumb:".v:exception)
    endtry

    " Prepare the function body
    if ! async
      let params    = {'_fname': a:functionName}
      let sCall     = s:Concat(&ft, 'EM', lCall, params)
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
    endif
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
  silent! exe "call lh#refactor#".&ft.'#load()'
  let params      = {'_varname': a:variableName}
  let lUse        = s:Option(&ft, 'EV', '_use', params)
  " snippets will return text and not list of stuff
  let sUse        = type(lUse) != type([]) ? lUse : s:Concat(&ft, 'EV', lUse, params)

  try
    let a_save = @a

    " Extract the selected expression into register @a
    exe "normal! gv\"ac".sUse
    let params['_value'] = @a " reuse the same variable as _use may have added some data to params
    let lDefinition = s:Option(&ft, 'EV', '_definition', params)
    let sDefinition = type(lDefinition) != type([]) ? lDefinition : s:Concat(&ft, 'EV', lDefinition, params)
    let s:variable = sDefinition
    let s:last_refactor='variable'

    let continue = lh#ui#confirm("Replace other occurrences of `".@a."' ?", "&Yes\n&No", 1)
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
function! lh#refactor#default_varname() abort
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
  silent! exe "call lh#refactor#".&ft.'#load()'
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

    let continue = lh#ui#confirm("Replace other occurrences of `".@a."' ?", "&Yes\n&No", 1)
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

" # Extract GETTER                               {{{2         -----------
" lh#refactor#extract_getter()                              {{{3
" Main function called by :ExtractGetter
" @pre: the selection must be line-wise
" @todo: determine external variables, and returned data
function! lh#refactor#extract_getter() abort
  silent! exe "call lh#refactor#".&ft.'#load()'
  let lFunction = s:Option(&ft, 'Eg', '_definition', '')

  try
    let attribute_def = getline('.')
    let attribute = lh#dev#attribute#analyse(attribute_def)
    let name = lh#naming#variable(attribute.name)
    let getter_name = lh#naming#getter(name)

    " Prepare the function body
    let params    = {
          \ '_ppt_name': name,
          \ '_name': attribute.name, '_type': attribute.type,
          \ '_static': (has_key(attribute,'static') && attribute.static ? 'static ' : ''),
          \ '_fname': getter_name, '_void': ''}
    if has_key(attribute, 'visibility')
      let params['_visibility'] = attribute.visibility.' '
    endif
    let sGetter   = s:Concat(&ft, 'Eg', lFunction, params)
    call lh#common#warning_msg('Getter '.getter_name.' extracted')

    let s:getter = sGetter
    let s:last_refactor='getter'
  finally
  endtry
endfunction

" # Extract SETTER                               {{{2         -----------
" lh#refactor#extract_setter()                              {{{3
" Main function called by :ExtractSetter
" @pre: the selection must be line-wise
" @todo: determine external variables, and returned data
function! lh#refactor#extract_setter() abort
  silent! exe "call lh#refactor#".&ft.'#load()'
  let lFunction = s:Option(&ft, 'Es', '_definition', '')

  try
    let attribute_def = getline('.')
    let attribute   = lh#dev#attribute#analyse(attribute_def)
    let name        = lh#naming#variable(attribute.name)
    let setter_name = lh#naming#setter(name)
    let param_name  = lh#naming#param(name)
    " TODO: This should be computed in hooks
    let instruction = lh#dev#instruction#assign(attribute.name, param_name)
    " TODO: This should also be computed in hooks
    let lFormal     = [{'formal': param_name, 'dir': 'in', 'type': attribute.type}]
    let sFormal     = lh#dev#function#parameters_to_signature(lFormal)

    " Prepare the function body
    let params    = {
          \ '_ppt_name': name,
          \ '_name': attribute.name, '_type': attribute.type,
          \ '_static': (has_key(attribute,'static') && attribute.static ? 'static ' : ''),
          \ '_fname': setter_name, '_args': sFormal,
          \ '_instruction': instruction
          \ }
    if has_key(attribute, 'visibility')
      let params['_visibility'] = attribute.visibility.' '
    endif
    let sSetter   = s:Concat(&ft, 'Es', lFunction, params)
    call lh#common#warning_msg('Setter '.setter_name.' extracted')

    let s:setter = sSetter
    let s:last_refactor='setter'
  finally
  endtry
endfunction


" # Fix C p=realloc(p, size)                     {{{2         -----------
" lh#refactor#fix_realloc( [name] ) range                   {{{3
" Main function called by :FixRealloc
" @pre: there is no selection
" @pre: the current line contains everything from start to ;

function! lh#refactor#fix_realloc() abort range
  silent! exe "call lh#refactor#".&ft.'#load()'
  try
    let a_save = @a

    exe a:firstline.','.a:lastline.'yank a'
    " Extract the selected expression into register @a
    let line = substitute(@a, '\_s\+', ' ', 'g')
    " echomsg line
  finally
    " Restaure the register @a
    let @a = a_save
  endtry

  let [all, lhs, type, realloc, rhs, size, in_macro; tail] = matchlist(line,
        \ '^\s*\(.\{-}\)\s*=\s*\((.\{-}\)\=\s*\(\k*realloc\)\s*(\s*\(.\{-}\)\s*,\s*\(.\{-}\)\s*);\s*\(\\\)\=')
  if (lhs != rhs)
    throw "the pointers used in realloc mismatch: <".lhs."> != <".rhs.">. Aborting"
    return
  endif
  let expected_realloc = lh#ft#option#get('refactor_expected_realloc', &ft, 'realloc')
  if realloc !~  'realloc' && realloc != expected_realloc
    throw "This call doesn't look like a call to realloc. Aborting."
    return
  endif
  let lhs_prefix    = lh#ft#option#get('refactor_temp_prefix', &ft, 'new_')
  let free_function = lh#ft#option#get('refactor_free_function', &ft, 'free')
  let false         = lh#ft#option#get('refactor_false', &ft, 'false')
  let type          = substitute(type, '(\s*\(.\{-}\)\s*\*\s*)', '\1', '')
  " build temporary_variable identifier
  let lhs = lhs_prefix . lh#naming#variable(matchstr(lhs, '.\{-}\zs\k\+$'))
  " count=number of element * sizeof, or size
  let cnt = (size =~ 'sizeof')
        \ ? substitute(size, '\s*\(\*\s*\)\=sizeof([^)]*)\s*\(\*\s*\)\=', '', '')
        \ : size
  let args = {
        \  'ptr'    : rhs
        \, 'lhs'    : lhs
        \, 'type'   : type
        \, 'count'  : cnt
        \, 'size'   : size
        \, 'realloc': realloc
        \, 'free'   : free_function
        \, 'macro'  : in_macro
        \, 'false'  : false
        \ }
  echomsg string(args)
  exe a:firstline.','.a:lastline.'delete _'
  call append(a:firstline-1, '')
  call setpos('.', [0, a:firstline, 1, 1])
  call lh#mut#expand_and_jump(0, 'c/realloc', args)
  return
endfunction

" lh#refactor#default_varname()                             {{{2
" Helper function called by :ExtractVariable
" @pre: the selection is not expected to be line-wise
function! lh#refactor#default_varname() abort
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

" General functions                              {{{2         -----------
" lh#refactor#put_extracted_stuff(bang,what)                {{{3
function! lh#refactor#put_extracted_stuff(bang, what) abort
  " With some languages (e.g., the indenting needs to be forced)
  let indent = indent('.')
  let what = repeat(' ', indent) . a:what
  " Put the function
  if "!" == a:bang
    silent! put!=what
  else
    silent! put=what
  endif
  " Reindent the code inserted
  silent! '[,']normal! ==
endfunction


" lh#refactor#put_extracted_last()                          {{{3
function! lh#refactor#put_extracted_last(bang) abort
  call lh#refactor#put_extracted_stuff(a:bang, s:{s:last_refactor})
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
