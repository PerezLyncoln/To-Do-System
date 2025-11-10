global init_todo
global add_todo
global get_count
global get_task
global get_priority
global get_timestamp
global update_task
global set_priority
global remove_todo

section .data
MAX_TASKS equ 10
TEXT_SIZE equ 80
RECORD_HDR equ 9            ; 1 byte priority + 8 bytes timestamp
RECORD_SIZE equ RECORD_HDR + TEXT_SIZE

section .bss
tasks: resb MAX_TASKS*RECORD_SIZE

section .text

; void init_todo(void)
init_todo:
    mov rdi, tasks
    mov rcx, MAX_TASKS*RECORD_SIZE
    xor rax, rax
    rep stosb
    ret

; long add_todo(const char *text, long priority, long timestamp)
; rcx = text, rdx = priority, r8 = timestamp
add_todo:
    push rbx
    xor rsi, rsi            ; index = 0
.find_slot:
    cmp rsi, MAX_TASKS
    jge .full
    mov rax, rsi
    imul rax, RECORD_SIZE
    mov rdi, tasks
    add rdi, rax            ; rdi = slot base
    cmp byte [rdi], 0
    jne .next_slot
    ; store priority (low byte of rdx)
    mov bl, dl
    mov [rdi], bl
    ; store timestamp qword at [rdi+1]
    mov qword [rdi+1], r8
    ; copy text into slot+RECORD_HDR, up to TEXT_SIZE-1
    mov rbx, TEXT_SIZE-1
    mov rsi, rcx            ; src
    lea rdi, [rdi + RECORD_HDR]
.copy_txt:
    mov al, [rsi]
    cmp al, 0
    je .finish_copy
    mov [rdi], al
    inc rsi
    inc rdi
    dec rbx
    jz .finish_copy
    jmp .copy_txt
.finish_copy:
    mov byte [rdi], 0
    pop rbx
    xor rax, rax
    ret
.next_slot:
    inc rsi
    jmp .find_slot
.full:
    pop rbx
    mov rax, -1
    ret

; long get_count(void)
get_count:
    xor rax, rax    ; count
    xor rbx, rbx    ; index
.gc_loop:
    cmp rbx, MAX_TASKS
    jge .gc_done
    mov rcx, rbx
    imul rcx, RECORD_SIZE
    mov rdx, tasks
    add rdx, rcx
    cmp byte [rdx], 0
    je .gc_next
    inc rax
.gc_next:
    inc rbx
    jmp .gc_loop
.gc_done:
    ret

; long get_task(index, outbuf, bufsize)
; rcx = index, rdx = outbuf, r8 = bufsize
get_task:
    mov r9, rcx
    cmp r9, 0
    jl .gt_invalid
    mov rax, r9
    cmp rax, MAX_TASKS
    jae .gt_invalid
    ; slot base = tasks + index*RECORD_SIZE
    mov rax, rcx
    imul rax, RECORD_SIZE
    mov rsi, tasks
    add rsi, rax            ; rsi = slot base
    cmp byte [rsi], 0
    je .gt_invalid
    ; source text = rsi + RECORD_HDR
    lea rsi, [rsi + RECORD_HDR]
    ; copy up to bufsize-1
    mov r10, r8
    dec r10
    cmp r10, 0
    jle .gt_invalid
.gt_copy:
    mov al, [rsi]
    mov [rdx], al
    inc rsi
    inc rdx
    dec r10
    cmp al, 0
    je .gt_done
    jg .gt_loop_continue
    jmp .gt_done
.gt_loop_continue:
    cmp r10, 0
    jg .gt_copy
    mov byte [rdx], 0
.gt_done:
    xor rax, rax
    ret
.gt_invalid:
    mov rax, -1
    ret

; long get_priority(index)
; rcx = index -> rax = priority or -1
get_priority:
    mov rax, rcx
    cmp rax, 0
    jl .gp_invalid
    cmp rax, MAX_TASKS
    jae .gp_invalid
    mov rbx, rax
    imul rbx, RECORD_SIZE
    mov rdx, tasks
    add rdx, rbx
    movzx rax, byte [rdx]
    cmp al, 0
    je .gp_invalid
    ret
.gp_invalid:
    mov rax, -1
    ret

; long get_timestamp(index)
; rcx = index -> rax = timestamp (qword) or -1
get_timestamp:
    mov rax, rcx
    cmp rax, 0
    jl .gtm_invalid
    cmp rax, MAX_TASKS
    jae .gtm_invalid
    mov rbx, rax
    imul rbx, RECORD_SIZE
    mov rdx, tasks
    add rdx, rbx
    cmp byte [rdx], 0
    je .gtm_invalid
    mov rax, [rdx+1]
    ret
.gtm_invalid:
    mov rax, -1
    ret

; long update_task(index, newtext)
; rcx = index, rdx = newtext
update_task:
    mov rax, rcx
    cmp rax, 0
    jl .ut_invalid
    cmp rax, MAX_TASKS
    jae .ut_invalid
    mov rbx, rax
    imul rbx, RECORD_SIZE
    mov rdi, tasks
    add rdi, rbx            ; rdi = slot base
    cmp byte [rdi], 0
    je .ut_invalid
    lea rdi, [rdi + RECORD_HDR]
    mov rsi, rdx            ; src
    mov rcx, TEXT_SIZE-1
.ut_copy:
    mov al, [rsi]
    cmp al, 0
    je .ut_done
    mov [rdi], al
    inc rsi
    inc rdi
    dec rcx
    jz .ut_done
    jmp .ut_copy
.ut_done:
    mov byte [rdi], 0
    xor rax, rax
    ret
.ut_invalid:
    mov rax, -1
    ret

; long set_priority(index, priority)
; rcx = index, rdx = priority
set_priority:
    mov rax, rcx
    cmp rax, 0
    jl .sp_invalid
    cmp rax, MAX_TASKS
    jae .sp_invalid
    mov rbx, rax
    imul rbx, RECORD_SIZE
    mov rdi, tasks
    add rdi, rbx
    cmp byte [rdi], 0
    je .sp_invalid
    mov bl, dl
    mov [rdi], bl
    xor rax, rax
    ret
.sp_invalid:
    mov rax, -1
    ret

; long remove_todo(index)
; rcx = index
remove_todo:
    mov rax, rcx
    cmp rax, 0
    jl .rm_invalid
    cmp rax, MAX_TASKS
    jae .rm_invalid
    mov rbx, rax
    imul rbx, RECORD_SIZE
    mov rsi, tasks
    add rsi, rbx
    cmp byte [rsi], 0
    je .rm_invalid
    ; shift remaining slots up
    mov rdi, rax
.rm_shift_loop:
    cmp rdi, MAX_TASKS-1
    jge .rm_clear_last
    ; copy slot (rdi+1) -> slot rdi
    mov rax, rdi
    imul rax, RECORD_SIZE
    mov rdx, tasks
    add rdx, rax
    mov rax, rdi
    inc rax
    imul rax, RECORD_SIZE
    mov rsi, tasks
    add rsi, rax
    mov rcx, RECORD_SIZE
.rm_copy_bytes:
    mov al, [rsi]
    mov [rdx], al
    inc rsi
    inc rdx
    dec rcx
    jnz .rm_copy_bytes
    inc rdi
    jmp .rm_shift_loop
.rm_clear_last:
    ; clear last slot
    mov rax, MAX_TASKS-1
    imul rax, RECORD_SIZE
    mov rdi, tasks
    add rdi, rax
    mov rcx, RECORD_SIZE
    xor al, al
.rm_clear_loop:
    mov [rdi], al
    inc rdi
    dec rcx
    jnz .rm_clear_loop
    xor rax, rax
    ret
.rm_invalid:
    mov rax, -1
    ret