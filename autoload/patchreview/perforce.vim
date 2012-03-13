let s:PRemote = {}
let s:perforce = {}

function! s:perforce.Detect() " {{{
  try
    let l:lines = split(system('p4 set'), "[\n\r]")
    let l:count = len(l:lines)
    let l:idx = 0
    let l:proofs_required = 2
    while l:idx < l:count
      let l:line = l:lines[l:idx]
      let l:idx += 1
      if l:line =~ '\(P4CLIENT\|P4PORT\)='
        let l:proofs_required -= 1
      endif
    endwhile
    return l:proofs_required == 0
  catch
    call s:PRemote.Echo('Exception ' . v:exception)
    call s:PRemote.Echo('From ' . v:throwpoint)
    return 0
  endtry
endfunction
" }}}

function! s:perforce.GetDiff() " {{{
  " Excepted to return an array with diff lines in it
  let l:diff = []
  let l:lines = split(system('p4 opened'), "[\n\r]")
  let l:linescount = len(l:lines)
  let l:line_num = 0
  while l:line_num < l:linescount
    let l:line = l:lines[l:line_num]
    call s:PRemote.Status('Processing ' . l:line)
    let l:line_num += 1
    let l:fwhere = substitute(l:line, '\#.*', '', '')
    let l:fwhere = split(system('p4 where ' . shellescape(l:fwhere)), "[\n\r]")[0]
    let l:fwhere = substitute(l:fwhere, '^.\+ ', '', '')
    let l:fwhere = substitute(l:fwhere, expand(getcwd(), ':p') . '/', '', '')
    if l:line =~ '\(delete \(default \)\?change\) .*\(text\|unicode\|utf16\)'
      call s:PRemote.Status('Fetching original ' . l:fwhere)
      let l:diff += ['--- ' . l:fwhere]
      let l:diff += ['+++ /dev/null']
      let l:diffl = map(split(system('p4 print -q ' . shellescape(l:fwhere)), "[\n\r]"), '"-" . v:val')
      let l:diff += ['@@ -1,' . len(l:diffl) . ' +0,0 @@']
      let l:diff += l:diffl
      unlet! l:diffl
    elseif l:line =~ '\(add \(default \)\?change\) .*\(text\|unicode\|utf16\)'
      call s:PRemote.Status('Reading ' . l:fwhere)
      let l:diff += ['--- /dev/null']
      let l:diff += ['+++ ' . l:fwhere]
      let l:diffl = map(readfile(l:fwhere, "b"), '"+" . v:val')
      let l:diff += ['@@ -0,0 +1,' . len(l:diffl) . ' @@']
      let l:diff += l:diffl
      unlet! l:diffl
    elseif l:line =~ '\(\(edit\|integrate\) \(default \)\?change\) .*\(text\|unicode\|utf16\)'
      call s:PRemote.Status('Diffing ' . l:fwhere)
      let l:diff += ['--- ' . l:fwhere]
      let l:diff += ['+++ ' . l:fwhere]
      let l:diffl = split(system('p4 diff -du ' . shellescape(l:fwhere)), "[\n\r]")
      let l:diff += l:diffl[2:]
      unlet! l:diffl
    else
      "throw "Do not recognize/handle this p4 opened file mode: " . l:line
      let l:diff += ['Binary files ' . l:fwhere . ' and ' . l:fwhere . ' differ']
    endif
  endwhile
  return {'strip': 0, 'diff': l:diff}
endfunction
" }}}

function! patchreview#perforce#register(remote) "{{{
  let s:PRemote = a:remote
  return s:perforce
endfunction
" }}}

" vim: set et fdl=99 fdm=marker fenc= ff=unix ft=vim sts=0 sw=2 ts=2 tw=79 nowrap :