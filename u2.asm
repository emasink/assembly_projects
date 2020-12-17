.model small
.stack 100h

.data
;pranesimai
    msg_help        db "The program gives a hexdump of a provided file.", 0ah, 0dh, "Required input - name of the file w/ extension", 0DH, 0Ah, "there has to be only one argument representing file name followed by new_line", 0Ah, 0Dh, '$'
    arg_er          db "Argument error", 0ah, 0dh, 24h
    buff_error      db "Error reading buffer", 0Ah, 0Dh, 24h
    msg_fo_error    db "Could not open file", 0Ah, 0Dh, 24h
    msg_fo_error1   db "Could not open destination file", 0Ah, 0Dh, 24h
    msg_closing_error  db "Could not close the file", 0Ah, 0Dh, 24h
    msg_success     db "Success, look for hex dump in file rez.txt", 10, 13, '$'
    endl            db  0ah, 0dh, 24h
;kintamieji darbui su failais
     file_in        db 123 dup(0)
       fh_in          dw ?
    file_out        db "rez.txt", 0h
      fh_out          dw ?
;tarpiniai kintamieji (darbiniai)
    buffer          db 200h dup(0)
    hex_line        db 70 dup ('$')



.code

start:
    mov dx,@data
    mov ds,dx

    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    mov cl, es:[80h]
    mov si, 0081h

    cmp cl, 0
    jne next_char
    jmp no_arg
;*****************************************
;            help
;*****************************************
helping:
  next_char:
      mov al, es:[si + bx]
      inc bx
      cmp al, '/'              ;checking if it is /
      je slash                 ;jeigu yra /tikrinam, ar kitas klaustukas

      loop next_char
      jmp first_arrgument

  slash:
      mov al, es:[si + bx]
      cmp al, '?'
      je help                  ;jeigu yra help kombinacija, sokam i pagalbos funkcija
      dec cl                   ;sumazinam cikla, nes nuskaitem papildoma simboli
      jmp next_char
  help:
      mov dx, offset msg_help
      mov ah, 09h
      int 21h
      mov ax, 4c00h
      int 21h

  no_arg:
      mov ah, 09H
      mov dx, offset arg_er
      int 21H
      jmp exit
;*****************************************
;                read arguments
;*****************************************
readArguments:
  first_arrgument:
      mov si, 0080h            ;pradedam nuo 0 simbolio
      xor ax, ax

  remove_space:
      inc si
      mov al, es:[si]          ;didinam ir judam prie sekancio

      cmp al, 0DH              ;jei prasideda 0dh, error
      jne cmp_space
        mov ah, 09H
        mov dx, offset arg_er
        int 21H
        jmp exit
      cmp_space:
      cmp al, 20h              ;jei tai space, ignoruojam ir einam prie kito simbolio
      je remove_space

      mov bx, offset file_in ;jei simbolis, pradedu irasineti failo pavadinima i buferi file_in

  name_of_the_file:
      mov al, es:[si]          ;idedu i al eilutes simboli

      cmp al, 0Dh
      je start_program

      cmp al, 20h              ;vykdau, kol nera space'u
      je argument_error        ;jeigu space po vardo, arg error

        mov [bx], al             ;jegu tai simbolis, pridedu prie file_in
        inc si                   ;didinu komandos eilutes pozicija
        inc bx                   ;didinu failo pavadinimo pozicija
        jmp name_of_the_file     ;skaitau toliau

      space_after_word:
        inc si
        mov al, es:[si]
        cmp al, 20h              ;jei dar vienas space, ignoruoju
        je space_after_word
        cmp al, 0Dh              ;jei newline, prpadedu programa, jei ne, argument error
        je start_program

      argument_error:              ;jeigu paduotas tik failo vardas, iseiname is programos
        mov ah, 09h
        mov dx, offset arg_er
        int 21H
        jmp exit
;********************************************
;       done reading arguments
;********************************************
start_program:

  open_file:
    mov ax, 3D00h
    mov dx, offset file_in
    int 21H

    check_if_file_can_be_opened:
      jnc source_file_opened
      MOV AH, 09h
      mov dx, offset msg_fo_error
      int 21h
      jmp exit
    source_file_opened:
      mov fh_in, ax

      call open_dest_file

    bufferized_read:
      zeroeing_buffer_elements:
        mov cx, 200h
        mov bx, 0
        zero:
          mov ax, 0
          mov [offset buffer + bx], ax
          inc bx
        loop zero
      getting_bufer:
        mov ax, 3f00h
        mov bx, fh_in
        mov cx, 200h
        mov dx, offset buffer
        int 21H
      checking_if_buffer_read:
          jnc buffer_read_succesfully
            mov ah, 09H
            mov dx, offset buff_error
            int 21h

          buffer_read_succesfully:
            cmp ax, cx
            jne process_last_buffer
              call dividing_buffer_into_lines
              jmp bufferized_read
          process_last_buffer:
          mov cx, ax   ; issaugau cx'e, kiek baitu nuskaiciau
          call dividing_buffer_into_lines

      call close_files

      mov ah, 09H
      mov dx, offset msg_success
      int 21h

  exit:

      mov ax, 4c00h
      int 21h
;*******************************************
;         procedures
;*******************************************
dividing_buffer_into_lines: ; (hex lines)
    push bx
    push cx
    push ax
    xor bx, bx

    mov cx, 32     ;nes 512/16=32
    loop1:
      call print_line
      add bx, 16
      mov ax, 0
      cmp [offset buffer + bx], ax          ;
      je zero_reached
    loop loop1

    zero_reached:
    pop ax
    pop cx
    pop bx
ret

print_line:    ;take bx(index to first symbol) and print dump for that line
  push cx
  push ax
  push bx

  mov di, offset hex_line
  mov si, [offset hex_line + 51]
  mov bx, ' '
  mov [si - 2], bx
  mov bx, '|'
  mov [si - 1], bx
  mov [si + 16], bx
  mov cx, 16
  pop bx
  push bx
  loop2:

    xor ax, ax
    mov al, [offset buffer + bx]  ;i al'a gaunu simbolio ascii koda
  uzrasau_gala:
      push ax
      cmp ax, 1fh
      ja palieku_simboli
        mov al, '.'
      palieku_simboli:
      mov [si], al
      inc si
      pop ax

    ;hex verčių apskaiciavimas:

      push ax   ;issaugau simbolio kopija steke
      first_symbol:
          shr al, 04h
          cmp al, 10
          jb number1
            ;raide
            add al, 37h      ;paverciu to skaitmens ascii simbolius
            jmp write_to_buffer1
          number1:
            add al, 30h
        write_to_buffer1:    ;patalpinu i buferi pirma ascii simboli
        mov [di], al
        inc di

      second_symbol:
          pop ax
          and al, 0Fh        ;antra hex skaiciaus simboli
          cmp al, 10
          jb number2
            ;raide
            add al, 37h      ;paverciu to skaitmens ascii simbolius
            jmp write_to_buffer2
          number2:
            add al, 30h
        write_to_buffer2:    ;patalpinu i buferi pirma ascii simboli
        mov [di], al
        inc di
        mov al, ' '
        mov [di], al
        inc di
        cmp cx, 9
        jne no_extra_space
          mov [di], al
          inc di
        no_extra_space:

        inc bx
  loop loop2
writing_to_screen: ;writes hex dump to DOS window
    mov ah, 09H
    mov dx, offset hex_line
    int 21H
    mov dx, offset endl
    int 21H
writing_to_file:
    mov cx, 68
    mov ah, 40H
    mov bx, fh_out
    mov dx, offset hex_line
    int 21h
    mov ah, 40h
    mov dx, offset endl
    mov cx, 2
    mov bx, fh_out
    int 21h


  pop bx
  pop ax
  pop cx
ret

open_dest_file:
    push ax
    push dx

    mov ax, 3D01h
    MOV DX, offset file_out
    int 21h
  jnc file_out_opening_success
    mov ah, 09H
    mov dx, offset msg_fo_error1
    int 21h
  file_out_opening_success:
    mov fh_out, ax

    pop dx
    pop ax
ret

close_files:
    mov ah, 3Eh
    mov bx, fh_in
    int 21H
    jnc close_f_out
      mov ah, 09h
      mov dx, offset msg_closing_error
      int 21h
    close_f_out:
      mov ah, 3Eh
      mov bx, fh_out
      int 21h
      jnc closed_successfully
        mov ah, 09h
        mov dx, offset msg_closing_error
        int 21h
        call exit
      closed_successfully:

  ret
end start
