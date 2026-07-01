;+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;HyFI v0.15
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
   mov al,0x80
   out 0x70,al
   mov ax,0x10
   mov esp,0x7C00
   mov ds,ax
   mov ss,ax
   mov es,ax
   mov eax,cr4
   or eax,0x30
   mov cr4,eax
   mov eax,cr0
   and eax,0x9FFFFFFF
   mov cr0,eax
   wbinvd
   mov ecx,0x200
   mov edx,0x00000000
   mov eax,0x80000006
   wrmsr
   mov ecx,0x201
   mov edx,0x0000000F
   mov eax,0x0FFFF8800
   wrmsr
   mov ecx,0x2FF
   rdmsr
   or eax,0x800
   wrmsr
   mov edi,0x00010000
   xor eax,eax
   mov ecx,0x1000
   rep stosd
   mov dword [0x00010000],0x00011003
   mov dword [0x00010004],0x00000000
   mov dword [0x00011000],0x00012003
   mov dword [0x00011004],0x00000000
   mov dword [0x00012000],0x0000009B
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
mov al,0xFD
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
dq idt_table
lol2:
lea rdi,[rel idt_table]
xor rcx, rcx
.fill_idt:
lea rax, [rel irq_logic]

    mov rbx, rdi
    mov rdx, rcx
    shl rdx, 4
    add rbx, rdx


    mov [rbx], ax


    mov word [rbx+2], 0x08

    mov byte [rbx+5], 0x8E

    mov rdx, rax
    shr rdx, 16
    mov [rbx+6], dx
    shr rdx,16
    mov [rbx+8],edx
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
hyfi_buf db 0
cmd_cls db 'cls',0
;-----
section .bss
cmd_buf resb 612
;-----
   section .text
    global _start
;===================
[bits 64]
    _start:        
        mov dx,0x3D4
        mov al,0x11
        out dx,al
        inc dx
        in al,dx
        and al,0x7F
        out dx,al
        dec dx
        ;mov rsi,[cmd_buf]
        ;mov cx,[hyfi_buf]
        ;mov rsp,stack1 + 4096
;--------------------
        mov rax,cr0
        mov rbx,0x00000000009FFFFFFF
        and rax,rbx
        mov cr0,rax
        
        mov dx,0x3C4
        mov al,0x01
        out dx,al
        inc dx
        in al,dx
        and al,0xFD   
        out dx,al

        mov dx,0x3C4
        mov al,0x0A
        out dx,al
        inc dx
        mov al,0x03
        out dx,al
        ;----------
        dec dx
        mov al,0x04
        out dx,al
        inc dx
        mov al,0x02
        out dx,al

        mov dx,0x3C2
        mov al,0x23
        out dx,al
        
        mov dx,0x3D4
        mov al,0x00
        out dx,al
        inc dx
        mov al,0x5F
        out dx,al
        
        dec dx
        mov al,0x06
        out dx,al
        inc dx
        mov al,0xBF
        out dx,al
        dec dx
        mov al,0x17
        out dx,al
        inc dx
        mov al,0xA3
        out dx,al

        mov dx,0x3CE
        mov al,0x06
        out dx,al
        inc dx
        mov al,0x0C
        out dx,al
        
        mov dx,0x3DA
        in al,dx
        mov dx,0x3C0
        mov al,0x10
        out dx,al
        mov al,0x0C
        out dx,al

        mov dx,0x3DA
        in al,dx
        mov dx,0x3C0
        mov al,0x20
        out dx,al

        mov dx,0x3DA
        in al,dx

        mov rax,0x00000000000B8000
        mov rdi,rax
;+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
        mov [rdi],byte 'H'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte 'Y'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte 'F'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte 'I'
            mov [rdi+1],byte 0x0F
            add rdi,2
         mov [rdi],byte ' '
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte 'V'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte ' '
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte '0'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte '.'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte '1'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte '3'
            mov [rdi+1],byte 0x0F
            add rdi,2
        mov [rdi],byte '/'
            mov [rdi+1],byte 0x0F
            add rdi,160
;--------------------
lea rax,[rel idt_ptr]
lidt [rax]
sti
main:
    hlt
    jmp main
;--------------------
irq_logic:
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
    iretq
;--------------------
        keyboard:
;--------------------
cmp rdi,0x0B8000+4000
jae reset
mov rax,rsi
sub rax,cmd_buf
cmp rax,612
jae reload
;--------------------
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
;-----
cmp al,0x0E
je BACKSPACE
cmp al,0x2A
je shiftON
cmp al,0xAA
je shiftoff
;-----
cmp al,0x02
je A1
cmp al,0x03
je A2
cmp al,0x04
je A3
cmp al,0x05
je A4
cmp al,0x06
je A5
cmp al,0x07
je A6
cmp al,0x08
je A7
cmp al,0x09
je A8
cmp al,0x0A
je A9
cmp al,0x0B
je A0
ret
;---------------------
A:
    mov [rdi],byte 'a'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'a'
    inc rsi
    ret
B:
    mov [rdi],byte 'b'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'b'
    inc rsi
    ret
C:
    mov [rdi],byte 'c'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'c'
    inc rsi
    ret
D:
    mov [rdi],byte 'd'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'd'
    inc rsi
    ret
E:
    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'e'
    inc rsi
    ret
F:
    mov [rdi],byte 'f'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'f'
    inc rsi
    ret
G:
    mov [rdi],byte 'g'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'g'
    inc rsi
    ret
H:
    mov [rdi],byte 'h'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'h'
    inc rsi
    ret
I:
    mov [rdi],byte 'i'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'i'
    inc rsi
    ret
J:
    mov [rdi],byte 'j'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'j'
    inc rsi
    ret
K:
    mov [rdi],byte 'k'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'k'
    inc rsi
    ret
L:
    mov [rdi],byte 'l'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'l'
    inc rsi
    ret
M:
    mov [rdi],byte 'm'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'm'
    inc rsi
    ret
N:
    mov [rdi],byte 'n'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'n'
    inc rsi
    ret
O:
    mov [rdi],byte 'o'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'o'
    inc rsi
    ret
P: 
    mov [rdi],byte 'p'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'p'
    inc rsi
    ret
Q:
    mov [rdi],byte 'q'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'q'
    inc rsi
    ret
R:
    mov [rdi],byte 'r'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'r'
    inc rsi
    ret
S:
    mov [rdi],byte 's'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 's'
    inc rsi
    ret
T:
    mov [rdi],byte 't'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 't'
    inc rsi
    ret
U:
    mov [rdi],byte 'u'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'u'
    inc rsi
    ret
V:
    mov [rdi],byte 'v'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'v'
    inc rsi
    ret
W:
    mov [rdi],byte 'w'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'w'
    inc rsi
    ret
X:
    mov [rdi],byte 'x'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'x'
    inc rsi
    ret
Y:
    mov [rdi],byte 'y'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'y'
    inc rsi
    ret
Z:
    mov [rdi],byte 'z'
    mov [rdi+1],byte 0x0F
    add rdi,2
    mov [rsi],byte 'z'
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
mov rsi,cmd_buf
call x32

push rbx
push rsi
mov rbx,cmd_buf
mov rsi,cmd_x64
call strcmp
cmp ax,1
pop rsi
pop rbx
mov rsi,cmd_buf
call x64

push rbx
push rsi
mov rbx,cmd_buf
mov rsi,cmd_launch
call strcmp
cmp ax,1
pop rsi
pop rbx
mov rsi,cmd_buf
call launch

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
BACKSPACE:
   cmp rdi,0xB8000
   jbe main
   cmp rsi,cmd_buf
   jbe main
   sub rdi,2
   dec rsi
   mov [rdi],byte ' '
   mov [rdi+1],byte 0x0F
   mov [rsi],byte 0
   ret
;--------------------
A1:
    cmp [shift],byte 1
    je B1
    mov [rdi],byte '1'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A2:
    cmp [shift],byte 1
    je B2
    mov [rdi],byte '2'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A3:
    cmp [shift],byte 1
    je B3
    mov [rdi],byte '3'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A4:
    cmp [shift],byte 1
    je B4
    mov [rdi],byte '4'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A5:
    cmp [shift],byte 1
    je B5
    mov [rdi],byte '5'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A6:
    cmp [shift],byte 1
    je B6
    mov [rdi],byte '6'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A7:
    cmp [shift],byte 1
    je B7
    mov [rdi],byte '7'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A8:
    cmp [shift],byte 1
    je B8
    mov [rdi],byte '8'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A9:
    cmp [shift],byte 1
    je B9
    mov [rdi],byte '9'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
A0:
    cmp [shift],byte 1
    je B0
    mov [rdi],byte '0'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
;--------------------
B1:
    mov [rdi],byte '!'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B2:
    mov [rdi],byte '@'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B3:
    mov [rdi],byte '#'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B4:
    mov [rdi],byte '$'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B5:
    mov [rdi],byte '%'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B6:
    mov [rdi],byte '^'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B7:
    mov [rdi],byte '&'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B8:
    mov [rdi],byte '*'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B9:
    mov [rdi],byte '('
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
B0:
    mov [rdi],byte ')'
    mov [rdi+1],byte 0x0F
    add rdi,2
    ret
;-------------------------
reset:
    mov rdi,0xB8000
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
    mov [rdi],byte 'H'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'l'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'p'
    mov [rdi+1],byte 0x0E
    add rdi,160

    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'i'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'n'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte ' '
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'H'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'Y'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'F'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'Y'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte '.'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'o'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'r'
    mov [rdi+1],byte 0x0E
    add rdi,2

    mov [rdi],byte 'g'
    mov [rdi+1],byte 0x0E
    add rdi,2
    mov rsi,cmd_buf
    mov [rsi],byte 0
    ret
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
    mov rdi,0xB8000
    mov rsi,cmd_buf
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
launch16bit:
    hlt
    ret
    [bits 64]
none:
    add rdi,160
    mov [rdi],byte 'n'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'o'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'n'
    mov [rdi+1],byte 0x0F
    add rdi,2

    mov [rdi],byte 'e'
    mov [rdi+1],byte 0x0F
    add rdi,160
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