.model small
.stack 100H
.DATA
    ;program outputs hex numners of entered text
    ivesk   db  "Iveskite teksta: ", 13, 10, 24h
    ats     db  "Jusu ivestas tekstas:$"
    tekstas db  255, 0, 255 dup(?)
    kodai   db  "Simboliu sesioliktainiai kodai:$"
    output  db  756 dup (?)

.CODE
start:

    mov dx, @data
    mov ds, dx

    mov ah, 09H
    mov dx, offset ivesk
    int 21h

    mov ah, 0ah
    mov dx, offset tekstas
    int 21H

    mov ah, 09H
    mov dx, offset ats
    int 21h

    mov ah, 40h
    mov bx, 1
    xor cx, cx
    mov cl, [tekstas + 1]
    mov dx, offset tekstas + 2
    int 21h

    mov ah, 02H
    mov dx, 13
    int 21H
    mov dx, 10
    int 21h

    mov ah, 09H
    mov dx, offset kodai
    int 21h


;VERTIMAS I SESIOLIKTAINE

    xor cx, cx
    mov cl, [tekstas + 1]
    mov bx, offset tekstas + 2
    xor di, di


ciklas:
    xor ax, ax
    mov al, [bx]
    push ax    ;issaugau simbolio kopija stack'e
pirmas_simbolis:
      shr al, 04h
      cmp al, 10  ; tikrinu ar 10
    jb skaicius
        ;raide
        add al, 37h    ;jeigu raide
        jmp antras_simbolis
    skaicius:
      add al, 30h
      ;mov ah, 02H   ; pirmas simbolis
      ;mov dl, al    ;
      ;int 21H       ;
      mov [output + di], al
      inc di
antras_simbolis:
      pop ax
      and al, 0Fh   ; "izoliuoju" antra simboli
      cmp al, 10
    jb skaicius2
      add al, 37h   ;jeigu raide
      ;mov ah, 02H
      ;mov dl, al
      ;int 21h
      ;mov dl, ' '
      ;int 21h
      mov [output + di], al
      inc di
      mov dl, 32
      mov [output + di], dl
      inc di
      jmp pabaiga
    skaicius2:       ;jeigu skaitmuo
      add al, 30h
      ;mov dl, al
      ;mov ah, 02h
      ;int 21H
      ;mov dl, ' '
      ;int 21h
      mov [output + di], al
      inc di
      mov dl, 32
      mov [output + di], dl
      inc di

pabaiga:
inc bx

loop ciklas

    mov ah, 40h
    mov bx, 1
    mov cx, di
    mov dx, offset output
    int 21H

    mov ah, 4ch
    int 21H

end start
