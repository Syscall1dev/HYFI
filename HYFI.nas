;+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;HyFI v0.16
;Copiright (c) 2026 $yscall-(Syscall1dev)
;More info : By default, HYFI looks for the kernel at address 0x00100000,
;exactly one megabyte of memory in 64-bit mode.
;You can use the 'real mode' command and HYFI will switch to 16-bit mode, or 'protected mode' for 32-bit mode.
;To hand over control to the kernel, you need to use the 'launch' command, BUT MAKE SURE YOU CHOOSE THE MODE FIRST!!!
;=========
;=========
HYFI:
[bits 16]
[org 0xFFFF0000]
startcli:
    cli
    invd
    mov ecx,0x00000201
    mov edx,0x00000000
    mov eax,0xFFFFF800
    wrmsr
    mov ecx,0x201
    mov edx,0x0000000F
    wrmsr
    mov ecx,0x2FF
    rdmsr
    or eax,0x800
    wrmsr
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp, 0x7C00
    jmp lol
    align 4
    gdt:
        dq 0x0000000000000000
        dq 0x00CF9A000000FFFF
        dq 0x00CF92000000FFFF
    gdt_end:
    gdt_pointer:
    dw gdt_end - gdt - 1
    dd (gdt-startcli)+0x000f0000
    lol:
    lgdt [cs:gdt_pointer] 
     mov eax,cr0
     or eax,1
     mov cr0,eax
     jmp dword 0x08:(0x000f0000+(start32-startcli))
;=============================
;=============================
;=============================
[bits 32]
start32: 

   mov eax,0x8000083E
   out 0x0CF8,eax
   in eax,0xCFC
   or eax,0x0008
   out 0x0CFC,eax

   mov eax,0x8000F880
   out 0x0CF8,eax
   mov eax,0x00700010
   out 0x0CFC,eax

   mov al,0x80
   out 0x70,al
   mov ax,0x10
   mov esp,0x8000FFFF
   mov ds,ax
   mov ss,ax
   mov es,ax

   mov eax,0x8000F804
   out 0x0CF8,eax
   in eax,0x0CFC
   or eax,0x07
   out 0x0CFC,eax

   mov eax,cr4
   or eax,0x30
   mov cr4,eax
   mov eax,cr0
   and eax,0x9FFFFFFF
   mov cr0,eax
   mov edi,0x00010000
   xor eax,eax
   mov ecx,0x1000
   rep stosd
   mov dword [0x00010000],0x00011003
   mov dword [0x00010004],0x00000000
   mov dword [0x00011000],0x00012003
   mov dword [0x00011004],0x00000000
   mov dword [0x00012000],0x0000019B
   mov dword [0x00012004],0x00000000
   mov esp,0x7C00
   mov eax,0x00010000
   mov cr3,eax
   mov ecx,0xC0000080
   rdmsr
   or eax,0x100
   wrmsr
   lgdt[0x000F0000+(gdt64_ptr-startcli)]
   mov eax,cr0
   or eax,0x80000000
   mov cr0,eax
   jmp far dword 0x08:(0x000F0000+(long_mode-startcli))
;=============================
;=============================
;=============================
[bits 64]
long_mode:

    mov ax,0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax
    jmp HYFI_MAIN
align 8

gdt64:
dq 0x0000000000000000

dq 0x00AF9A000000FFFF

dq 0x00AF92000000FFFF

gdt64_end:

gdt64_ptr:
dw gdt64_end - gdt64 - 1
dq (0x000f0000+(gdt64-startcli))

align 16
stack:
times 8192 db 0
gdt32:
dq 0
dq 0x00CF9A000000FFFF   
dq 0x00CF92000000FFFF   

gdt32_ptr:
dw gdt32_end - gdt32 - 1
dd gdt32
gdt32_end:

stack_top:
;+=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;=+=+=+=+=+=+=+=+=+=+=+=+=+=+==+=+=+=+=+=+=+=+=+=+=+=+=+=+=

HYFI_MAIN:
[bits 64]
;==============================
mov al,0x80
mov dx,0x03FB
out dx,al
mov dx,0x03F8
mov al,0x03
out dx,al
mov al,0x00
mov dx,0x03F9
out dx,al
mov al,0x03
mov dx,0x03FB
out dx,al
mov dx,0x03FA
mov al,0xC7
out dx,al
mov dx,0x03FC
mov al,0x0B
out dx,al
;==============================
mov al,0x11
out 0x20,al
out 0xA0,al
mov al,0x20
out 0x21,al
mov al,0x28
out 0xA1, al
mov al,0x04
out 0x21,al
mov al,0x02
out 0xA1,al
mov al,0x01
out 0x21,al
out 0xA1,al
mov al,0xF8
out 0x21,al
mov al,0xFF
out 0xA1,al
;-------------------
jmp lol2
align 16
idt_table:
times 256 dq 0, 0
idt_end:
    
align 16
    align 16
idt_ptr:
dw idt_end - idt_table - 1
dq (0x000F0000+(idt_table-startcli))
lol2:
xor rcx, rcx
mov rdi,0x000F2210
lea rax,[rel irq_logic]
.fill_idt:
    mov rbx, rdi
    mov r8, rcx
    shl r8, 4
    add rbx, r8


    mov [rbx], ax


    mov word [rbx+2], 0x08

    mov byte [rbx+5], 0x8E

    mov rdx, rax
    shr rdx, 16
    mov [rbx+6], dx

mov [rbx+4],byte 0

    mov rdx,rax
    shr rdx,32
    mov dword[rbx+8],edx
    mov dword [rbx+12], 0

    inc rcx
    cmp rcx, 256
    jne .fill_idt
;+=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;=+=+=+=+=+=+=+=+=+=+=+=+=+=+==+=+=+=+=+=+=+=+=+=+=+=+=+=+=
;+=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;=+=+=+=+=+=+=+=+=+=+=+=+=+=+==+=+=+=+=+=+=+=+=+=+=+=+=+=+=
section .data
shift db 0
cmd_help db 'help',0
cmd_x16 db 'real mode',0
cmd_x32 db 'protected mode',0
cmd_x64 db 'long mode',0
cmd_launch db 'launch',0
cmd_cullers_on db 'cullers on',0
cmd_cullers_on1 db 'cullers fifty',0
cmd_cullers_on2 db 'cullers one hundred',0
cmd_cullers_off db 'cullers off',0
hyfi_buf db 0
cmd_cls db 'cls',0
;-----
section .bss
cmd_buf resb 612
;-----
   section .text
    jmp _start
    send_engine:
            push rdx
            push rax
            mov dx,0x03FD
            .loopwait:
                in al,dx
                test al,0x20
                je .loopwait
            mov dx,0x03F8
            pop rax
            out dx,al
            pop rdx
            ret
    global _start
;===================
[bits 64]
    _start:     
lea rax,[rel idt_ptr]
lidt [rax]
        mov rsi,cmd_buf
        mov cx,[hyfi_buf]
        ;mov rsp,stack1 + 4096
;+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
            mov al,'H'
            call send_engine
            mov al,'Y'
            call send_engine
            mov al,'F'
            call send_engine
            mov al,'I'
            call send_engine
            mov al,' '
            call send_engine
            mov al,'v'
            call send_engine
            mov al,'0'
            call send_engine
            mov al,'.'
            call send_engine
            mov al,'1'
            call send_engine
            mov al,'6'
            call send_engine
            mov al,' '
            call send_engine
            mov al,'A'
            call send_engine
            mov al,'S'
            call send_engine
            mov al,'U'
            call send_engine 
            mov al,'S'
            call send_engine
            mov al,' '
            call send_engine
            mov al,'e'
            call send_engine
            mov al,'d'
            call send_engine
            mov al,'i'
            call send_engine
            mov al,'t'
            call send_engine
            mov al,'o'
            call send_engine
            mov al,'n'
            call send_engine
;--------------------

sti
main:
    hlt
    jmp main
;--------------------
irq_logic:
    push rbp
    push rax
    push rbx
    push rdi
    push rsi
    push rcx
    push rdx
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
mov al,'$'
call send_engine
    in al,0x60
    test al,0x80
    jnz .reset
    call keyboard
.reset:
    mov al,0x20
    out 0x20,al

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdx
    pop rcx
    pop rsi
    pop rdi
    pop rbx
    pop rax
    pop rbp
    iretq
;--------------------
keyboard:
cmp al,0x1E
je A
cmp al,0x30
je B
cmp al,0x2E
je C
cmp al,0x20
je D
cmp al,0x1C
je ENTE
cmp al,0x12
je E
cmp al,0x21
je F
cmp al,0x22
je G
cmp al,0x23
je H
cmp al,0x17
je I
cmp al,0x24
je J
cmp al,0x25
je K
cmp al,0x26
je L
cmp al,0x32
je M
cmp al,0x31
je N 
cmp al,0x18
je O
cmp al,0x19
je P
cmp al,0x10
je Q
cmp al,0x13
je R
cmp al,0x1F
je S
cmp al,0x14
je T
cmp al,0x16
je U
cmp al,0x2F
je V
cmp al,0x11
je W
cmp al,0x2D
je X
cmp al,0x15
je Y
cmp al,0x2C
je Z
ret
;---------------------
A:
    mov al,'a'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
B:
    mov al,'b'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
C:
    mov al,'c'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
D:
    mov al,'d'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
E:
    mov al,'e'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
F:
    mov al,'f'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
G:
    mov al,'g'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
H:
    mov al,'h'
    call send_engine
    mov [rsi],al
    inc rsi
    ret 
I:
    mov al,'i'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
J:
    mov al,'j'
    call send_engine
    mov [rsi],al
    inc rsi
    ret 
K:
    mov al,'k'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
L:
    mov al,'l'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
M:
    mov al,'m'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
N:
    mov al,'n'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
O:
    mov al,'o'
    call send_engine
    mov [rsi],al
    inc rsi
    ret 
P:
    mov al,'p'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
Q:
    mov al,'q'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
R:
    mov al,'r'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
S:
    mov al,'s'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
T:
    mov al,'t'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
U:
    mov al,'u'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
V:
    mov al,'v'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
W:
    mov al,'w'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
X:
    mov al,'x'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
Y:
    mov al,'y'
    call send_engine
    mov [rsi],al
    inc rsi
    ret    
Z:
    mov al,'z'
    call send_engine
    mov [rsi],al
    inc rsi
    ret
ENTE:
    ;!!CRITICAL ZONE!!! DO NOT TOUCH PUSH POP
    ;ONE STACK ERROR TO THE CORE END!!!
    push rsi
    push rbx
mov [rsi],byte 0
mov rbx,cmd_buf
mov rsi,cmd_help
call strcmp
cmp ax,1
pop rsi
pop rbx
jne oll
mov rsi,cmd_buf
call help
ret
oll:
push rbx
push rsi
mov rbx,cmd_buf
mov rsi,cmd_x16
call strcmp
cmp ax,1
pop rsi
pop rbx
jne olll
mov rsi,cmd_buf
call x16
olll:
push rbx
push rsi
mov rbx,cmd_buf
mov rsi,cmd_x32
call strcmp
cmp ax,1
pop rsi
pop rbx
jne ollll
mov rsi,cmd_buf
call x32
ollll:
push rbx
push rsi
mov rbx,cmd_buf
mov rsi,cmd_x64
call strcmp
cmp ax,1
pop rsi
pop rbx
jne olllll
mov rsi,cmd_buf
call x64
olllll:
push rbx
push rsi
mov rbx,cmd_buf
mov rsi,cmd_launch
call strcmp
cmp ax,1
pop rsi
pop rbx
jne ol1
mov rsi,cmd_buf
call launch
ol1:
push rbx
push rsi
mov rbx,cmd_buf
mov rsi,cmd_cls
call strcmp
cmp al,1
pop rsi
pop rbx
mov rsi,cmd_buf
call cls
ret
;-------------------------
reset:
    
    mov rsi,cmd_buf
    ret
shiftON:       
    mov [shift],byte 1
    ret       
shiftoff:        
    mov [shift],byte 0
    ret
reload:
    mov [cmd_buf], byte 0
    mov rsi,cmd_buf
    ret
;------------------------
help:
    
    ret
cullers_on:
    add rdi,160
    mov [rdi],byte 'c'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'u'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'l'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'l'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'r'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 's'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'o'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'n'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte '!'
    mov [rdi+1],byte 0x0F
    add rdi,160

    mov dx,0x002E
    mov al,0x87
    out dx,al
    out dx,al

    mov dx,0x002E
    mov al,0x07
    out dx,al
    
    mov dx,0x002F
    mov al,0x0B
    out dx,al
cullers_30:
    mov dx,0x002E
    mov al,0x04
    out dx,al
    mov dx,0x002F
    mov al,0x00
    out dx,al

    mov dx,0x002E
    mov al,0x01
    out dx,al
    mov dx,0x002F 
    mov al,0x4C

x16:
    mov [hyfi_buf],byte 1
    add rdi,160
    mov [rdi],byte 'x'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte '1'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte '6'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte 'm'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'o'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'd'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 's'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'l'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'c'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 't'
    mov [rdi+1],byte 0x0F
    add rdi,160
    ret
x32:
    mov [hyfi_buf],byte 2
    add rdi,160
    mov [rdi],byte 'x'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte '3'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte '2'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte 'm'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'o'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'd'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 's'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2 

    mov [rdi],byte 'l'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'c'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 't'
    mov [rdi+1],byte 0x0F
    add rdi,160
    ret
x64:
    mov [hyfi_buf],byte 3
    add rdi,160
    mov [rdi],byte 'x'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte '6'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte '4'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rdi],byte 'm'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'o'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'd'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 's'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'l'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'c'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 't'
    mov [rdi+1],byte 0x0F
    add rdi,160
    ret
cls:
    lrop:
        mov [rdi],0x0F20
        add rdi,2
        cmp rdi,0x000B8FA0
        jne lrop
        ret
launch:
    cmp byte [hyfi_buf],0
    je none
    cmp byte [hyfi_buf],1
    je launch16bit
    cmp byte [hyfi_buf],2
    je launch32bit
    cmp byte [hyfi_buf],3
    je launch64bit
    ret
;--------------------
strcmp:
    .loop:
        mov al,[rbx] 
        mov dl,[rsi]
        cmp al,dl
        jne .no
        cmp al,0
        je .yes
        inc rbx
        inc rsi
        jmp .loop
        .no:
            xor ax,ax
            ret
        .yes:
            mov ax,1
            ret
;----------------------------------------
launch64bit:
    mov rax,0x00100000
    jmp rax
launch32bit:
cli
mov ax, CODE32
push rax
lea rax, [rel compat32]
push rax
retfq
[bits 32]
compat32:
mov eax,cr0
and eax,0x7FFFFFFF
mov cr0,eax
mov ecx,0xC0000080
rdmsr
and eax,0xFFFFFEFF
wrmsr
mov ax,0x20
mov ds,ax
mov es,ax
mov ss,ax
jmp 0x00100000
endola:
    ret
launch16bit:
    hlt
    ret
    [bits 64]
none:
    mov al,'n'
    call send_engine
    mov al,'o'
    call send_engine
    mov al,'n'
    call send_engine
    mov al,'e'
    call send_engine
    ret
    [bits 64]
    gdt_gg:
dq 0

dq 0x00209A0000000000

dq 0x0000920000000000

dq 0x00CF9A000000FFFF

dq 0x00CF92000000FFFF
CODE64 equ 0x08
DATA64 equ 0x10
CODE32 equ 0x18
;=============================
[bits 16]
TIMES 65536-16-($-$$) db 0
starthd:
    db 0xEA
    dw 0x0000
    dw 0xF000
TIMES 65536 - ($-$$) db 0 
;=============================