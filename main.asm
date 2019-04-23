section .text
global main
extern puts
extern printf
extern getaddrinfo
extern gai_strerror
extern socket
extern setsockopt
extern bind
extern listen
extern accept
extern perror
extern recv
extern memset
extern strtok
extern strlen
extern fopen
extern close
extern strcmp
extern freeaddrinfo
extern fclose
extern send

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
    mov     qword [rbp-64], rdi
    
    ;initialize addrinfo
    mov     dword [rbp-48], 1  ;ai_flags (int) = AI_PASSIVE
    mov     dword [rbp-44], 2     ;ai_family (int) = AF_INET
    mov     dword [rbp-40], 1     ;ai_socktype (int) = SOCK_STREAM

    ;init the rest to 0
    mov     dword [rbp-36], 6    ;ai_protocol (int)
    mov     qword [rbp-32], 0    ;ai_addrlen (size_t)
    mov     qword [rbp-24], 0    ;ai_canonname (char*)
    mov     qword [rbp-16], 0    ;ai_addr (sockaddr*)
    mov     qword [rbp-8 ], 0    ;ai_next (addrinfo*)

    mov     qword [rbp-56], 0    ;hostInfo (addrinfo*)

    ;push params for getaddrinfo
    mov     rsi, portStr        ;port
    mov     edi, 0          ;flags (NULL)
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
    mov     rax, qword [rbp-56]
    leave
    ret



bindSocket:
    ;function enter
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    mov     qword [rbp-8], rdi ;get addressInfo param (addrinfo*)

    ;push args to socket()
    mov     rax, rdi
    mov     edi, dword [rax+4] ;ai_family
    mov     esi, dword [rax+8] ;ai_socktype
    mov     edx, dword [rax+12] ;ai_protocol
    call    socket

    mov     dword [rbp-12], eax ;save socket file descriptor

    ;if call to socket returns an error output the error message
    cmp     eax, 0
    jnl     noSocketError
    mov     rdi, openSocketErr
    call    printf
    noSocketError:

    mov     edi, 1
    mov     dword [rbp-16], edi ; socket option = 1

    ;set socket option
    mov     edi, dword [rbp-12] ;sockfd
    mov     esi, 1 ;SOL_SOCKET
    mov     edx, 2 ;SO_REUSEADDR
    lea     rcx, [rbp-16] ;&socket option
    mov     r8, 4 ;sizeof(int)

    call    setsockopt

    ;check for set socket option return status
    cmp     rax, 0
    jnl     noSetSockOptErr
    mov     rdi, setSockOptErr
    call    perror
    noSetSockOptErr:

    ;call to bind socket
    mov     edi, dword [rbp-12] ;sockfd
    mov     rax, qword [rbp-8]
    mov     rsi, qword [rax+24] ;addressInfo->ai_addr
    mov     rdx, qword [rax+16] ;addressInfo->ai_addrlen
    call    bind
    
    ;check for bind socket status
    cmp     rax, 0
    jnl     noBindSockErr
    mov     rdi, bindSockErr
    call    perror

    noBindSockErr:
    mov     rdi, qword [rbp-8] 
    call    freeaddrinfo

    ;return socket file descriptor
    mov     eax, dword [rbp-12]

    leave
    ret

serveRequest:
    ;function enter
    push    rbp
    mov     rbp, rsp
    sub     rsp, 1600

    ;init locals
    mov     dword [rbp-4], edi  ;request
    mov     qword [rbp-12], 0 ;method (char*)
    mov     qword [rbp-20], 0 ;url (char*)
    mov     dword [rbp-24], 0 ;reqSize (int)

    

    ;clear buffer
    lea     rdi, [rbp-1600]
    mov     rsi, 0
    mov     rdx, 1500
    call    memset


    ;call recv
    mov     edi, dword [rbp-4] ;req
    lea     rsi, [rbp-1600] ;buffer
    mov     rdx, 1500 ;REQUEST_BUFFER_SIZE
    mov     rcx, 0
    call    recv

    ;call strtok
    lea     rdi, [rbp-1600]
    mov     rsi, spaceStr
    call    strtok

    ;save method
    mov     qword [rbp-12], rax

    printHere

    mov     rdi, intOutF
    mov     rsi, qword [rbp-12]
    call    printf

    mov     rdi, strOutF
    mov     rsi, qword [rbp-12]
    call    printf

    ;if(strcmp(method, "GET") == 0)
    mov     rdi, qword [rbp-12] ;method
    mov     rsi, qword getStr ;"GET"
    call    strcmp
    printHere

    cmp     rax, 0
    jne     notGetReq


    ;serve GET request

    ;get url
    mov     rdi, 0
    mov     rsi, spaceStr
    call    strtok
    mov     qword [rbp-20], rax

    ; printHere

    ;skip beginning slash
    movzx   eax, BYTE [rbp-20]
    cmp     eax, 47
    jne     noBeginningSlash

    ; printHere

    ;url++
    inc     qword [rbp-20]
    noBeginningSlash:

    ;open a file
    mov rdi, qword [rbp-20]
    mov rsi, rStr
    call fopen

    mov qword[rbp-28], rax

    ;while read file
    lea     rdi, [rbp-1600]
    mov     rsi, 1500
    mov     rdx, qword[rbp-28]
    cmp     rax, 0
    je      serveRequestWhileFgetsEnd

    ;send buffer
    lea     rdi, [rbp-1600]
    call    strlen

    mov     edi, dword [rbp-4]
    lea     rsi, [rbp-1600]
    mov     rdx, rax
    mov     rcx, 0
    call    send

    ;clear buffer
    lea     rdi, [rbp-1600]
    mov     rsi, 0
    mov     rdx, 1500
    call    memset
    


    serveRequestWhileFgetsEnd:
    mov rdi, qword [rbp-20]
    call fclose

    notGetReq:



    

    leave
    ret

main:
    ;function enter
    push    rbp
    mov     rbp, rsp
    sub     rsp, 64

    ;port number
    mov     qword [rbp-8], portStr

    ;length of the backlog queue
    mov     dword [rbp-12], 20
    

    ;get info about the host
    mov     rdi, portStr
    call    getHostInfo

    mov     qword [rbp-20], rax ;addrinfo
    
    ;bind the socket
    mov     rdi, rax
    mov     rax, 0
    call    bindSocket

    mov     dword [rbp-24], eax ;sockfd

    ;listen onto the socket
    mov     edi, dword [rbp-24] ;sockfd
    mov     esi, dword [rbp-12] ;backlogQueueLength
    call    listen

    ;check for listen status
    cmp     rax, 0
    jnl     noListenError
    mov     rdi, sockListenErr
    call    printf
    noListenError:

    mov     rdi, listeningOnPort
    mov     rsi, qword [rbp-8]
    call    printf

    mov     dword [rbp-28], 0 ;newSocketFd
    ; struct sockaddrin is at [rbp-44]
    mov     dword [rbp-48], 16 ;client size

    mainLoop:

    ; call accept
    mov     edi, dword [rbp-24] ;sockfd
    lea     rsi, [rbp-44] ;clientAddr
    lea     rdx, [rbp-48]
    call    accept
    

    ;check for accept status
    cmp     eax, 0
    jnl     noAcceptError
    mov     rdi, acceptError
    call    printf
    noAcceptError:

    mov     rdi, intOutF
    mov     esi, dword [rbp-28]
    call    printf

    ; call serve request
    mov     edi, dword [rbp-28]
    call    serveRequest

    ; call connection close
    mov     edi, dword [rbp-28]
    call    close

    jmp     mainLoop

    mov     rax, 0x3c
    syscall
    leave
    ret
    
section .data
    portStr db "4200", 0x0
    hereMsg db "here", 0x0;, 0xa
    intOutF db "%i", 0xa, 0x0
    strOutF db "%s", 0xa, 0x0
    openSocketErr db "Error: could not open socket", 0xa, 0x0
    setSockOptErr db "Error: could not set socket option", 0xa, 0x0
    bindSockErr db "Error: could not bind socket", 0xa, 0x0
    sockListenErr db "Error: could not listen at socket", 0xa, 0x0
    acceptError db "Error on connection accept", 0xa, 0x0
    listeningOnPort db "Listening on port %s", 0xa, 0x0
    spaceStr db " ", 0x0
    getStr db "GET", 0x0
    rStr db "r", 0x0
    ; intOutF db "%#8x", 0xa