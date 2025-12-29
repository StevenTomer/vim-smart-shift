" =============================================================================
" File:        plugin/smart_shift.vim
" Description: Smart indentation, moving, and duplication for all modes.
" Maintainer:  Steven Tomer
" License:     MIT
" =============================================================================

if exists('g:loaded_smart_shift') || &cp
  finish
endif
let g:loaded_smart_shift = 1

" -----------------------------------------------------------------------------
" 1. SMART LEFT SHIFT
" -----------------------------------------------------------------------------
function! s:SmartLeftShift(context, count)
    let l:save_view = winsaveview()
    let l:op_mode = s:GetOpMode(a:context)

    let l:start_line = (l:op_mode ==# 'n') ? line('.') : line("'<")
    let l:end_line   = (l:op_mode ==# 'n') ? line('.') : line("'>")
    let l:cur_start_col = col("'<")
    let l:cur_end_col   = col("'>")
    let l:action_taken = 0

    for l:i in range(a:count)
        if l:op_mode ==# 'n' || l:op_mode ==# 'V'
            for l:lnum in range(l:start_line, l:end_line)
                let l:line = getline(l:lnum)
                let l:indent_idx = match(l:line, '\S') 
                if l:indent_idx > 0
                    let l:new_line = strpart(l:line, 0, l:indent_idx - 1) . strpart(l:line, l:indent_idx)
                    call setline(l:lnum, l:new_line)
                    let l:action_taken = 1
                endif
            endfor
        elseif l:op_mode ==# 'v' || l:op_mode ==# 'b'
            if l:cur_start_col <= 1 | break | endif
            for l:lnum in range(l:start_line, l:end_line)
                let l:line = getline(l:lnum)
                let l:idx_victim = l:cur_start_col - 2
                let l:idx_sel_start = l:cur_start_col - 1
                let l:sel_width = l:cur_end_col - l:cur_start_col + 1
                let l:pre = strpart(l:line, 0, l:idx_victim)
                let l:shifted = strpart(l:line, l:idx_sel_start, l:sel_width)
                let l:rest = strpart(l:line, l:cur_end_col)
                let l:padding = (len(l:rest) > 0) ? " " : ""
                call setline(l:lnum, l:pre . l:shifted . l:padding . l:rest)
            endfor
            let l:cur_start_col -= 1
            let l:cur_end_col -= 1
            let l:action_taken = 1
        endif
    endfor

    if !l:action_taken && a:count > 0
        execute "normal! \<Esc>"
    endif

    if l:op_mode ==# 'n'
        call winrestview(l:save_view)
    else
        call s:RestoreSelection(l:op_mode, l:start_line, l:end_line, l:cur_start_col, l:cur_end_col)
    endif
endfunction

" -----------------------------------------------------------------------------
" 2. SMART RIGHT SHIFT
" -----------------------------------------------------------------------------
function! s:SmartRightShift(context, count, is_destructive)
    let l:save_view = winsaveview()
    let l:op_mode = s:GetOpMode(a:context)

    let l:start_line = (l:op_mode ==# 'n') ? line('.') : line("'<")
    let l:end_line   = (l:op_mode ==# 'n') ? line('.') : line("'>")
    let l:cur_start_col = col("'<")
    let l:cur_end_col   = col("'>")

    for l:i in range(a:count)
        if l:op_mode ==# 'n' || l:op_mode ==# 'V'
            for l:lnum in range(l:start_line, l:end_line)
                let l:line = getline(l:lnum)
                let l:indent_idx = match(l:line, '\S') 
                if l:indent_idx == -1 | let l:indent_idx = 0 | endif
                let l:new_line = strpart(l:line, 0, l:indent_idx) . " " . strpart(l:line, l:indent_idx)
                call setline(l:lnum, l:new_line)
            endfor
        elseif l:op_mode ==# 'v' || l:op_mode ==# 'b'
            for l:lnum in range(l:start_line, l:end_line)
                let l:line = getline(l:lnum)
                let l:idx_start = l:cur_start_col - 1
                let l:pre = strpart(l:line, 0, l:idx_start)
                let l:sel = strpart(l:line, l:idx_start, l:cur_end_col - l:cur_start_col + 1)
                let l:rest = a:is_destructive ? strpart(l:line, l:cur_end_col + 1) : strpart(l:line, l:cur_end_col)
                call setline(l:lnum, l:pre . " " . l:sel . l:rest)
            endfor
            let l:cur_start_col += 1
            let l:cur_end_col += 1
        endif
    endfor

    if l:op_mode ==# 'n'
        call winrestview(l:save_view)
    else
        call s:RestoreSelection(l:op_mode, l:start_line, l:end_line, l:cur_start_col, l:cur_end_col)
    endif
endfunction

" -----------------------------------------------------------------------------
" 3. SMART UP SHIFT
" -----------------------------------------------------------------------------
function! s:SmartUpShift(context, count)
    let l:op_mode = s:GetOpMode(a:context)

    if l:op_mode ==# 'n' || l:op_mode ==# 'V'
        let l:offset = -1 - a:count
        let l:current_top = (l:op_mode ==# 'n' ? line('.') : line("'<"))
        let l:target_line = l:current_top - a:count
        
        if l:target_line < 1
            call append(0, repeat([''], 1 - l:target_line))
        endif

        if l:op_mode ==# 'n'
            silent! execute 'move ' . l:offset
            call cursor(max([1, l:target_line]), col('.'))
        else
            silent! execute "'<,'>move '<" . l:offset
            call s:RestoreSelection('V', line("'<"), line("'>"), 0, 0)
        endif

    elseif l:op_mode ==# 'v' || l:op_mode ==# 'b'
        let l:s_line = line("'<")
        let l:e_line = line("'>")
        let l:s_col = col("'<")
        let l:e_col = col("'>")

        for l:i in range(a:count)
            if l:s_line <= 1 | break | endif
            for l:r in range(l:s_line, l:e_line)
                call s:ApplyBlockLogic(l:r, l:r - 1, l:s_col, l:e_col, 1) 
            endfor
            let l:s_line -= 1
            let l:e_line -= 1
        endfor
        call s:RestoreSelection(l:op_mode, l:s_line, l:e_line, l:s_col, l:e_col)
    endif
endfunction

" -----------------------------------------------------------------------------
" 4. SMART DOWN SHIFT
" -----------------------------------------------------------------------------
function! s:SmartDownShift(context, count)
    let l:op_mode = s:GetOpMode(a:context)

    if l:op_mode ==# 'n' || l:op_mode ==# 'V'
        let l:offset = '+' . a:count
        let l:current_bottom = (l:op_mode ==# 'n' ? line('.') : line("'>"))
        let l:target_line = l:current_bottom + a:count
        let l:last_line = line('$')
        
        if l:target_line > l:last_line
            call append(l:last_line, repeat([''], l:target_line - l:last_line))
        endif

        if l:op_mode ==# 'n'
            silent! execute 'move ' . l:offset
            call cursor(min([line('$'), l:target_line]), col('.'))
        else
            silent! execute "'<,'>move '>" . l:offset
            call s:RestoreSelection('V', line("'<"), line("'>"), 0, 0)
        endif

    elseif l:op_mode ==# 'v' || l:op_mode ==# 'b'
        let l:s_line = line("'<")
        let l:e_line = line("'>")
        let l:s_col = col("'<")
        let l:e_col = col("'>")

        for l:i in range(a:count)
            if l:e_line >= line('$') | break | endif
            let l:range_list = range(l:s_line, l:e_line)
            call reverse(l:range_list)
            for l:r in l:range_list
                call s:ApplyBlockLogic(l:r, l:r + 1, l:s_col, l:e_col, 1)
            endfor
            let l:s_line += 1
            let l:e_line += 1
        endfor
        call s:RestoreSelection(l:op_mode, l:s_line, l:e_line, l:s_col, l:e_col)
    endif
endfunction

" -----------------------------------------------------------------------------
" 5. SMART DUPLICATE
" -----------------------------------------------------------------------------
function! s:SmartDuplicate(context, count, direction)
    let l:op_mode = s:GetOpMode(a:context)
    let l:save_view = winsaveview()

    if l:op_mode ==# 'n' || l:op_mode ==# 'V'
        for l:i in range(a:count)
            if a:direction == 1
                let l:target = (l:op_mode ==# 'n' ? line('.') : line("'>"))
                silent! execute "copy " . l:target
            else
                let l:target = (l:op_mode ==# 'n' ? line('.') : line("'<")) - 1
                silent! execute "copy " . l:target
            endif
        endfor
        
        if l:op_mode ==# 'n'
            call winrestview(l:save_view)
        else
            call s:RestoreSelection('V', line("'<"), line("'>"), 0, 0)
        endif

    elseif l:op_mode ==# 'v' || l:op_mode ==# 'b'
        let l:s_line = line("'<")
        let l:e_line = line("'>")
        let l:s_col = col("'<")
        let l:e_col = col("'>")
        let l:src_drift = 0
        
        for l:i in range(1, a:count)
            let l:offset = a:direction * l:i
            
            let l:tgt_start_check = (l:s_line + l:src_drift) + l:offset
            if l:tgt_start_check < 1
                let l:needed = 1 - l:tgt_start_check
                call append(0, repeat([''], l:needed))
                let l:src_drift += l:needed
            endif
            
            let l:tgt_end_check = (l:e_line + l:src_drift) + l:offset
            if l:tgt_end_check > line('$')
                call append(line('$'), repeat([''], l:tgt_end_check - line('$')))
            endif

            for l:r in range(l:s_line, l:e_line)
                let l:curr_src_row = l:r + l:src_drift
                let l:curr_tgt_row = l:curr_src_row + l:offset
                if l:curr_tgt_row >= 1 && l:curr_tgt_row <= line('$')
                    call s:ApplyBlockLogic(l:curr_src_row, l:curr_tgt_row, l:s_col, l:e_col, 0)
                endif
            endfor
        endfor
        
        let l:final_s_line = l:s_line + l:src_drift + (a:direction * a:count)
        let l:final_e_line = l:e_line + l:src_drift + (a:direction * a:count)
        
        let l:final_s_line = max([1, min([line('$'), l:final_s_line])])
        let l:final_e_line = max([1, min([line('$'), l:final_e_line])])
        call s:RestoreSelection(l:op_mode, l:final_s_line, l:final_e_line, l:s_col, l:e_col)
    endif
endfunction

" -----------------------------------------------------------------------------
" 6. HELPERS
" -----------------------------------------------------------------------------
function! s:GetOpMode(context)
    if a:context !=# 'v' | return 'n' | endif
    let l:m = visualmode()
    return (l:m ==# 'V') ? 'V' : (l:m ==# "\<C-V>" ? 'b' : 'v')
endfunction

function! s:RestoreSelection(mode, s_line, e_line, s_col, e_col)
    if mode() != 'n'
        execute "normal! \<Esc>"
    endif
    call cursor(a:s_line, a:s_col)
    if a:mode ==# 'v'
        normal! v
        call cursor(a:e_line, a:e_col)
    elseif a:mode ==# 'b'
        execute "normal! \<C-V>"
        call cursor(a:e_line, a:e_col)
    elseif a:mode ==# 'V'
        normal! V
        call cursor(a:e_line, 1)
    endif
endfunction

function! s:ApplyBlockLogic(lineSrc, lineTgt, col_start, col_end, is_move)
    let l:txtSrc = getline(a:lineSrc)
    let l:txtTgt = getline(a:lineTgt)
    
    if len(l:txtTgt) < a:col_end
        let l:txtTgt = l:txtTgt . repeat(' ', a:col_end - len(l:txtTgt))
    endif
    if len(l:txtSrc) < a:col_end
        let l:txtSrc = l:txtSrc . repeat(' ', a:col_end - len(l:txtSrc))
    endif
    
    let l:idx_start = a:col_start - 1
    let l:width = a:col_end - a:col_start + 1
    let l:block = strpart(l:txtSrc, l:idx_start, l:width)
    
    let l:newTgt = strpart(l:txtTgt, 0, l:idx_start) . l:block . strpart(l:txtTgt, a:col_end)
    call setline(a:lineTgt, l:newTgt)
    
    if a:is_move
        let l:srcRemainder = strpart(l:txtSrc, a:col_end)
        if len(l:srcRemainder) > 0
            let l:newSrc = strpart(l:txtSrc, 0, l:idx_start) . repeat(' ', l:width) . l:srcRemainder
        else
            let l:newSrc = strpart(l:txtSrc, 0, l:idx_start)
        endif
        call setline(a:lineSrc, l:newSrc)
    endif
endfunction

" -----------------------------------------------------------------------------
" 7. MAPPINGS
" -----------------------------------------------------------------------------
if !exists('g:smart_shift_no_mappings')
    nnoremap <silent> <C-h> :<C-u>call <SID>SmartLeftShift('n', v:count1)<CR>
    xnoremap <silent> <C-h> :<C-u>call <SID>SmartLeftShift('v', v:count1)<CR>

    nnoremap <silent> <C-l> :<C-u>call <SID>SmartRightShift('n', v:count1, 1)<CR>
    xnoremap <silent> <C-l> :<C-u>call <SID>SmartRightShift('v', v:count1, 1)<CR>
    nnoremap <silent> <C-S-l> :<C-u>call <SID>SmartRightShift('n', v:count1, 0)<CR>
    xnoremap <silent> <C-S-l> :<C-u>call <SID>SmartRightShift('v', v:count1, 0)<CR>

    nnoremap <silent> <C-k> :<C-u>call <SID>SmartUpShift('n', v:count1)<CR>
    xnoremap <silent> <C-k> :<C-u>call <SID>SmartUpShift('v', v:count1)<CR>

    nnoremap <silent> <C-j> :<C-u>call <SID>SmartDownShift('n', v:count1)<CR>
    xnoremap <silent> <C-j> :<C-u>call <SID>SmartDownShift('v', v:count1)<CR>

    nnoremap <silent> <C-S-k> :<C-u>call <SID>SmartDuplicate('n', v:count1, -1)<CR>
    xnoremap <silent> <C-S-k> :<C-u>call <SID>SmartDuplicate('v', v:count1, -1)<CR>

    nnoremap <silent> <C-S-j> :<C-u>call <SID>SmartDuplicate('n', v:count1, 1)<CR>
    xnoremap <silent> <C-S-j> :<C-u>call <SID>SmartDuplicate('v', v:count1, 1)<CR>
endif
