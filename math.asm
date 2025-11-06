; Simple todo-list backend (NASM) for Windows x64
; Exports:
; init_todo() -> void
; add_todo(char *s) -> 0 success, -1 full
; get_count() -> number of tasks (long)
; get_task(index, outbuf, bufsize) -> 0 success, -1 invalid
; remove_todo(index) -> 0 success, -1 invalid

global init_todo
global add_todo
global get_count
global get_task
global remove_todo

section .data
MAX_TASKS equ 10
TASK_SIZE equ 80

section .bss
tasks: resb MAX_TASKS*TASK_SIZE

section .text

; void init_todo(void)
init_todo:
    mov rdi, tasks
    mov rcx, MAX_TASKS*TASK_SIZE
    xor rax, rax
    rep stosb
    ret

; long add_todo(char *s)
; rcx = src
add_todo:
    push rbx
    xor rsi, rsi            ; index = 0
.find_slot:
    cmp rsi, MAX_TASKS
    jge .full
    mov rax, rsi
    imul rax, TASK_SIZE
    mov rdi, tasks
    add rdi, rax
    cmp byte [rdi], 0
    jne .next_slot
    ; copy up to TASK_SIZE-1 bytes from rcx to rdi
    mov rbx, TASK_SIZE-1
.copy_loop:
    mov al, [rcx]
    cmp al, 0
    je .finish_copy
    mov [rdi], al
    inc rcx
    inc rdi
    dec rbx
    jz .finish_copy
    jmp .copy_loop
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
    imul rcx, TASK_SIZE
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

; long get_task(long index, char *outbuf, long bufsize)
; rcx = index, rdx = outbuf, r8 = bufsize
get_task:
    mov r9, rcx
    cmp r9, 0
    jl .gt_invalid
    mov rax, r9
    cmp rax, MAX_TASKS
    jae .gt_invalid
    ; compute slot address
    mov rax, rcx
    imul rax, TASK_SIZE
    mov rsi, tasks
    add rsi, rax
    cmp byte [rsi], 0
    je .gt_invalid
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
    ; space exhausted, null-terminate
    mov byte [rdx], 0
.gt_done:
    xor rax, rax
    ret
.gt_invalid:
    mov rax, -1
    ret

; long remove_todo(long index)
; rcx = index
remove_todo:
    mov rax, rcx
    cmp rax, 0
    jl .rm_invalid
    cmp rax, MAX_TASKS
    jae .rm_invalid
    ; if slot empty -> invalid
    mov rbx, rax
    imul rbx, TASK_SIZE
    mov rsi, tasks
    add rsi, rbx
    cmp byte [rsi], 0
    je .rm_invalid
    ; shift remaining tasks up
    mov rdi, rax
.rm_shift_loop:
    cmp rdi, MAX_TASKS-1
    jge .rm_clear_last
    ; copy slot (rdi+1) -> slot rdi
    mov rax, rdi
    imul rax, TASK_SIZE
    mov rdx, tasks
    add rdx, rax
    mov rax, rdi
    inc rax
    imul rax, TASK_SIZE
    mov rsi, tasks
    add rsi, rax
    ; copy TASK_SIZE bytes
    mov rcx, TASK_SIZE
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
    imul rax, TASK_SIZE
    mov rdi, tasks
    add rdi, rax
    mov rcx, TASK_SIZE
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