section .text
global main
extern puts
extern printf
extern getaddrinfo
extern gai_strerror

%macro printHere 0
    mov rdi, hereMsg
    call puts
    mov rax, 0
%endmacro

getHostInfo:
    ;function enter
    push    rbp
    mov     rbp, rsp
    sub     rsp, 80

    ;get param value
    mov     QWORD [rbp-64], rdi
    
    ;initialize addrinfo
    mov     DWORD [rbp-48], 0x01  ;ai_flags (int) = AI_PASSIVE
    mov     DWORD [rbp-44], 2     ;ai_family (int) = AF_INET
    mov     DWORD [rbp-40], 1     ;ai_socktype (int) = SOCK_STREAM

    ;init the rest to 0
    mov     DWORD [rbp-36], 0    ;ai_protocol (int)
    mov     QWORD [rbp-32], 0    ;ai_addrlen (size_t)
    mov     QWORD [rbp-24], 0    ;ai_canonname (char*)
    mov     QWORD [rbp-16], 0    ;ai_addr (sockaddr*)
    mov     QWORD [rbp-8 ], 0    ;ai_next (addrinfo*)

    mov     QWORD [rbp-56], 0    ;hostInfo (addrinfo*)

    ;push params for getaddrinfo
    mov     rsi, rdi        ;port
    mov     rdi, 0          ;flags (NULL)
    lea     rdx, [rbp-48]   ;socketHints
    lea     rcx, [rbp-56]   ;hostInfo
    call    getaddrinfo

    ;if an error is thrown
    cmp     rax, 0
    jz      getaddrinfoNoError

    ;output the getaddrinfo error
    mov     rdi, rax
    call    gai_strerror
    mov     rdi, rax
    call    puts

    getaddrinfoNoError:
    
    ;return hostInfo
    mov     rax, QWORD [rbp-56]
    leave
    ret



bindSocket:
    ;function enter
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16

    leave
    ret

serveRequest:
    ;function enter
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16

    leave
    ret

main:
    ;function enter
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16

    ;port number
    mov QWORD [rbp-8], portStr
    ;length of the backlog queue
    mov DWORD [rbp-12], 20
    

    ;get info about the host
    mov rdi, portStr
    call getHostInfo
    mov rax, 0

    printHere



    mov rax, 0x3c
    syscall
    ret
    ;or just use leave
    ; mov rsp, rbp
    ; pop rbp

section .data
    portStr db "4200", 0x0
    hereMsg db "here", 0x0;, 0xa
    intOutF db "%i", 0xa
    ; intOutF db "%#8x", 0xa