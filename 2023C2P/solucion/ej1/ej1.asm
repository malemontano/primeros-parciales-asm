section .text

global contar_pagos_aprobados_asm
global contar_pagos_rechazados_asm

global split_pagos_usuario_asm

extern malloc
extern free
extern strcmp


;########### SECCION DE TEXTO (PROGRAMA)

; uint8_t contar_pagos_aprobados_asm(list_t* pList, char* usuario);
;RDI-> pList RSI-> usuario
contar_pagos_aprobados_asm:
    .prologo:
    push RBP
    mov RBP, RSP
    push rbx ;desalineada
    push r13 ;alineada
    push r15 ;desalineada
    push r14 ;alineada

    xor r14, r14 ;uso r14 como contador

    mov rbx, [rdi];en rbx tengo el puntero a la lista, en los primeros bytes tengo la dir de listElem
    cmp rbx, 0
    je .epilogo

    mov r15, rsi ;en r15 tengo el usuario

    .loop:

    mov r13, [rbx];accedo a data
    mov rdi, [r13+16] ;agarro el pagador
    mov rsi, r15 ;pongo en RSI el usuario
    call strcmp
    ;tengo en rax 0 si son iguales
    cmp rax, 0
    jne .no_sumar ;no es el usuario, paso al siguiente
    ;es el usuario

    movzx rdi, byte [r13+1]
    cmp rdi, 1
    jne .no_sumar
    add r14, 1 ;si es aprobado suma 1 sino 0
    
    .no_sumar:
    mov rbx, [rbx+8] ;avanzo el puntero
    cmp rbx, 0 ;si es null termine
    je .epilogo
    jmp .loop
    

    .epilogo:
    mov rax, r14

    pop r14
    pop r15
    pop r13
    pop rbx
    pop RBP
    ret
; uint8_t contar_pagos_rechazados_asm(list_t* pList, char* usuario);
contar_pagos_rechazados_asm:
        push rbp
        mov rbp, rsp
        push rbx
        push r15
        push r14
        push r13

        and r14, 0 ;uso r14 de contador

        mov rbx, [rdi] ;entro a la direccion de la lista, en los primeros 8 bytes tengo la direccion de listelem

        cmp rbx, 0 ;si no tiene elems la lista termino aca
        je .fin

        
        mov r15, rsi ;guardo nombre para no perderlo
        

        .loop:
        mov r13, [rbx] ;accedo a direccion de pago_t
        mov rdi, [r13 + 16] ;cargo en rdi el nombre del cobrador
        mov rsi, r15 ;cargo en rsi el nombre a contar
        
        call strcmp ;en rdi tengo nombre de cobrador y en rsi nombre de usuario a comparar

        cmp rax, 0
        jne .no_sumar

        movzx rdi, byte [r13 + 1] ;agarro aprobado
        cmp rdi, 0
        jne .no_sumar
        add r14, 1

        .no_sumar:
        mov rbx, [rbx + 8] ;me muevo a siguiente listelem
        cmp rbx, 0 ;si es null termino
        je .fin
        jmp .loop
        
        .fin:
        mov rax, r14
        pop r13
        pop r14
        pop r15
        pop rbx
        pop rbp
        ret
; pagoSplitted_t* split_pagos_usuario_asm(list_t* pList, char* usuario);
split_pagos_usuario_asm:

