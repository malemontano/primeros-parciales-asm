; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:
.prologo:
    push RBP
    mov RBP, RSP
    push R12

    mov RDI, 16
    call malloc ; tengo en RAX el puntero q voy a devolver, lo guardo en un reg no volatil
    mov R12, RAX ;R12 tiene el puntero a la lista(devuelvo esto)
    mov qword [RAX], 0 ;apunto first a null
    mov qword [RAX+8], 0 ;apunto last a null

.epilogo:
    mov RAX, R12
    pop R12
    pop RBP
    ret

;string_proc_node* string_proc_node_create(uint8_t type, char* hash);

string_proc_node_create_asm:
.prologo:
    push RBP ;alineada la pila
    mov RBP, RSP
    push R12 ;desalineada
    push R13 ;alineada
    push R14 ;desalineada
    sub RSP, 8 ;alineada

    movzx R13, dil ;dil son los 8bits mas bajos de RDI, lo extiendo a 64bits y guardo en R13
    mov R14, RSI ;tengo puntero a hash

    mov RDI, 32
    call malloc
    mov R12, RAX ;preservo el puntero q quiero devolver
    mov qword [RAX], 0 ;apunto next a null
    mov qword [RAX+8], 0 ;apunto prev a null
    mov byte [RAX+16], R13b ;cargo los 8bits mas bajos de r13, q son los q tienen type
    mov qword [RAX+24], R14


.epilogo:
    mov RAX, R12
    add RSP, 8
    pop R14
    pop R13
    pop R12
    pop RBP
    ret

;void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash);
;list->RDI, type->sil, hash->RDX
string_proc_list_add_node_asm:
.prologo:
    push RBP
    mov RBP, RSP
    push R12 ;desalineada
    sub RSP, 8;alineada

    mov R12, RDI;preservo el puntero a la lista pq voy a hacer un call
    movzx RDI, sil;paso a RDI para llamar a string_proc_node_create_asm
    mov RSI, RDX; paso a RSI ""
    call string_proc_node_create_asm ;tengo en RAX el puntero al nuevo nodo

    ;chequeo si la lista es vacia, quiero ver si first apunta a null
    mov RCX, qword [R12];list->first
    cmp RCX, 0
    je .lista_vacia

    ;lista no vacia
    mov R8, qword [R12+8]; pongo en R8 el puntero a last
    mov qword [RAX+8], R8 ;apunto prev al last de la lista: nuevo nodo->prev = list->last
    ;hacer last->next=nuevo nodo
    mov qword [R8], RAX ;next del ultimo nodo apunta al nuevo nodo
    ;list->last = nuevo nodo
    mov qword [R12+8], RAX ;last de la lista apunta a mi nuevo nodo
    jmp .epilogo

.lista_vacia:
    ;ya hice antes nuevo nodo->next = null
    mov qword [R12], RAX;list->first = nuevo nodo
    mov qword [R12+8], RAX;list->last = nuevo nodo

.epilogo:
    add RSP, 8
    pop R12
    pop RBP
    ret

string_proc_list_concat_asm:
    ;prologo
    push rbp
    mov rbp, rsp

    push rbx
    push r15
    push r14
    push r13

    mov r13, rsi ;preservo tipo
    mov r14, rdx ;preservo hash

    mov rdi, [rdi] ;guardo en rdi puntero a primer nodo
    
    cmp rdi, 0 ;si es null es lista vacia y termina
    je .fin

    push rdi ;guardo puntero a nodo

    and rdi, 0
    add rdi, 1
    call malloc         ;hago un string vacio para el hash
    mov rsi, rax

    mov rdi, r14 ;hash original
    mov byte [rsi], 0 ;con el str vacio

    push rsi

    call str_concat

    mov r14, rax ;guardo hash en r14 

    pop rdi ;recupero puntero a 1 byte de malloc y lo libero
    call free

    pop rdi ;recupero puntero a nodo

  


    
    .loop:
        mov r15, [rdi] ;guardo direccion de next en r15
        movzx r8, byte [rdi + 16] ;guardo tipo del nodo 
        cmp r8, r13 ;comparo tipos
        jne .no_agregar
        mov rsi, [rdi + 24] ;agarro el string si son iguales
        mov rdi, r14 ;cargo el hash

        call str_concat 
        
        mov rdi, r14 ;guardo puntero de hash anterior para liberarlo
        mov r14, rax ;actualizo el hash

        call free ;libero hash anterior

        
        .no_agregar:
            cmp r15, 0 ;si el siguiente es null termine
            je .fin
            mov rdi, r15 ;actualizo nodo a siguiente
            jmp .loop

    

    .fin:
    mov rax, r14
    pop r13
    pop r14
    pop r15
    pop rbx


    ;epilogo
    pop rbp
    ret