.model small
.stack 100h

.data
    
    menu_msg              db 0Dh,0Ah,'Sifreleme icin 1 e basiniz',0Dh,0Ah,'Desifreleme icin 2 e basiniz',0Dh,0Ah,'Cikmak istiyorsaniz 3 e basiniz',0Dh,0Ah,'Seciminiz: $'
    prompt_plaintext      db 0Dh,0Ah,'Metni girin (ENTER ile bitir): $'
    prompt_key            db 0Dh,0Ah,'Anahtari girin (ENTER ile bitir): $'
    result_msg            db 0Dh,0Ah,'Sonuc: $'
    return_msg            db 0Dh,0Ah,'Ana menuye donmek icin 0 a basiniz: $'
    newline               db 0Dh,0Ah,'$'
    
    plaintext_size   db 100   
    plaintext_count  db 0
    plaintext_data   db 100 dup(0)      
   

    key_size  db 100   
    key_count db 0     
    key_data  db 100 dup(0) 

    result    db 101 dup(0) 

.code
main_loop:
    call clear_screen    
    mov dx,offset menu_msg
    mov ah,09h
    int 21h              
    mov ah,08h
    int 21h
    cmp al,'1'         
    je do_encrypt
    cmp al,'2'         
    je do_decrypt
    cmp al,'3'           
    je do_exit
    jmp main_loop        


do_encrypt:
    mov dx,offset prompt_plaintext   
    mov ah,09h
    int 21h
    lea dx,plaintext_size    ;dxe input buffer adresini yukler
    mov ah,0Ah
    int 21h                  
    call check_input         ;Gecersiz girisi sorguluyor
    cmp al,0
    jne do_encrypt           ;Gecersiz giris yapilirsa tekrar basa don  
       
    mov dx,offset prompt_key
    mov ah,09h
    int 21h
    lea dx,key_size
    mov ah,0Ah
    int 21h                  
    call check_key
    cmp al,0
    jne do_encrypt           ;Gecersiz anahtar yapilirsa tekrar sifreleme

    call encrypt             ;Sifreleme islemi

    mov dx,offset result_msg      ;bu kisim sonucu ve mesajlari yazdiriyor
    mov ah,09h
    int 21h
    mov dx,offset result
    mov ah,09h
    int 21h
    mov dx,offset newline
    mov ah,09h
    int 21h
    mov dx,offset return_msg
    mov ah,09h
    int 21h
return:
    mov ah,08h
    int 21h
    cmp al,'0'               ;Ana menuye donmek icin 0 
    jne return               ;eger 0 olmazsa return tekrarlaniyor
    jmp main_loop           

; --- Desifreleme --- 


do_decrypt:
    mov dx,offset prompt_plaintext
    mov ah,09h
    int 21h
    lea dx,plaintext_size       ;metin giris buffer adresini DX'e yukler
    mov ah,0Ah
    int 21h                  
    call check_input           ;girilen metni kontrol eden fonksiyonu cagirir
    cmp al,0
    jne do_decrypt            ;gecersiz giris yapilirsa tekrar desifreleme

    mov dx,offset prompt_key
    mov ah,09h
    int 21h
    lea dx,key_size            ;anahtar alinir
    mov ah,0Ah
    int 21h                  
    call check_key             ;anahtar kontrol edilir
    cmp al,0
    jne do_decrypt            ;gecersiz anahtar yapilirsa tekrar desifreleme

    call decrypt             ;desifreleme islemi

    mov dx,offset result_msg
    mov ah,09h
    int 21h
    mov dx,offset result
    mov ah,09h
    int 21h
    mov dx,offset newline
    mov ah,09h
    int 21h

    mov dx,offset return_msg
    mov ah,09h
    int 21h
return_decrytp:
    mov ah,08h                    ;0 tusunu basana kadar dongu devam eder
    int 21h
    cmp al,'0'               
    jne return_decrytp
    jmp main_loop            

 
do_exit:
    mov ah,4Ch
    int 21h          ;Programi sonlandirir


clear_screen proc
    mov ax, 3        ;yazilari siler
    int 10h          
    mov ax,@data    
    mov ds,ax
    ret
clear_screen endp  

  ;plaintext kontrol  

check_input proc
    lea si,plaintext_data    ;plaintext_data adresini si yukleriz
    mov cl,[plaintext_count] ;metnin uzunlugunu clye yukleriz
ci_loop:
    cmp cl,0
    je ci_ok      
    mov al,[si]   ;metnin sonraki karakterini yukleriz
    cmp al,'A'
    jb ci_bad     ;A harfinden kucukse gecersiz
    cmp al,'Z'
    jbe ci_next   ;Zden kucukse veya esitse A-Z arasindadir direkt nexte atla
    cmp al,'a'
    jb ci_bad     ;a harfinden kucukse gecersiz
    cmp al,'z'
    ja ci_bad     ;z harfinden buyukse gecersiz
ci_next:
    inc si    ;bir sonraki karaktere gecer
    dec cl    ;metnin uzunlugundan cikartiriz kalan dongu sayimiz
    jmp ci_loop
ci_ok:
    mov al,0  ;tum karakterler uyumlu AL=0
    ret
ci_bad:
    mov al,1  ;gecersiz harf bulundu  AL=1
    ret
check_input endp  



; --- Anahtar kontrol --- 
       
       
       

check_key proc
    lea si,key_data    ;key_data adresini si yukleriz
    mov cl,[key_count] ;anahtar uzunlugunu clye yukleriz
ck_loop:
    cmp cl,0
    je ck_ok
    mov al,[si]     ;anahtarin sonraki karakterini yukleriz
    cmp al,'A'
    jb ck_bad       ;A harfinden kucukse gecersiz
    cmp al,'Z'
    jbe ck_next     ;Zden kucukse veya esitse A-Z arasindadir direkt nexte atla
    cmp al,'a'
    jb ck_bad       ;a harfinden kucukse gecersiz
    cmp al,'z'
    ja ck_bad       ;z harfinden buyukse gecersiz
ck_next:
    inc si          ;bir sonraki karaktere gecer
    dec cl          ;metnin uzunlugundan cikartiriz kalan dongu sayimiz
    jmp ck_loop
ck_ok:
    mov al,0        ;tum karakterler uyumlu AL=0
    ret
ck_bad:
    mov al,1        ;gecersiz harf bulundu  AL=1
    ret
check_key endp

  ;sifreleme

encrypt proc                    
    xor bx,bx                    ;BX'i sifirla
    lea si,plaintext_data        ;SI = plaintext_data adresi
    lea di,result                ;DI = result adresi
    mov cl,[plaintext_count]     ;Metnin uzunlugu = cl
    mov ch,0

encrypt_loop:
    cmp cx,0
    je encrypt_done              ;cx = 0 olunca metin sonlanir
    mov al,[si]
    cmp al,'a'
    jb encrypt_skip_lower        ;Kucukk harf degilse gecç
    cmp al,'z'
    ja encrypt_skip_lower        ;burada kucuk harfi
    sub al,32              
encrypt_skip_lower:
    sub al,'A'                  ;alfabeyi 0-26 arasina cevirir
    mov dl,[key_data+bx]        ;DL = anahtar karakteri (BX index)
    cmp dl,'a'                  ;DL kucuk harf mi kontrol
    jb encrypt_skip_lower_x     ;Kucuk harf degilse atla
    cmp dl,'z'                  ;DL z'den buyuk mu
    ja encrypt_skip_lower_x     ;z'den buyukse  atla
    sub dl,32                   ;kucuk harfi buyuk harfe cevir
encrypt_skip_lower_x:
    sub dl,'A'             ;A'dan çcikart
    add al,dl              ;metin ve anahtar harflerini topla
    cmp al,26              ;sonuc 26'dan buyuk mu
    jb encrypt_no          ;eger 26'dan kucukse islemi bitir
    sub al,26              ;26'dan buyukse 'A' harfine geri sar
encrypt_no:
    add al,'A'             ;A ekle sonuca ve ASCII cevirir
    mov [di],al            ;sonucu di isaret ettigi yere yazar yani resulta
    inc di
    inc bx
    mov dl,[key_count]     ;DL = anahtar uzunlugu
    mov dh,0
    cmp bx,dx              ;bx dx'i gecti mi
    jb encrypt_skip_reset  ;eger anahtarin sonuna gelmediysek gecç
    xor bx,bx              ;anahtari sifirla
encrypt_skip_reset:
    inc si                 ;metnin bir sonraki karakterine geciyoruz.
    dec cx                 ;cxi 1 azaltiyoruz 0 olunca dongu sonlancak cs=harf sayisi
    jmp encrypt_loop       ;sifreleme islemine geri don

encrypt_done:
    mov byte ptr [di],'$'   
    ret                    ;sifreleme islemi bitti geri don
encrypt endp

;   desifreleme

 
decrypt proc
    xor bx,bx                 ;BX'i sifirla
    lea si,plaintext_data     ;Metin verisini SI'ya yükle
    lea di,result             ;Sonuç verisini DI'ya yükle
    mov cl,[plaintext_count]  ;Okunan metin uzunlugunu CL'ye yükle
    mov ch,0

decrypt_loop:
    cmp cx,0
    je decrypt_done             ;Eger tum metin islendi ise sonlandir
    mov al,[si]
    cmp al,'a'
    jb decrypt_skip_lower       ;Kucuk harf degilse gecerç
    cmp al,'z'
    ja decrypt_skip_lower
    sub al,32                   ;Kucuk harfi buyuk harfe cevirir
decrypt_skip_lower:
    sub al,'A'                  ;alfabeyi 0-26 arasina cevirir
    mov dl,[key_data+bx]        ;DL = anahtar karakteri (BX index)
    cmp dl,'a'                  ;DL kucuk harf mi kontrol
    jb decrypt_skip_lower_x     ;Kucuk harf degilse atla
    cmp dl,'z'                  ;DL z'den buyuk mu
    ja decrypt_skip_lower_x     ;z'den buyukse  atla
    sub dl,32                   ;kucuk harfi buyuk harfe çcevir
decrypt_skip_lower_x:
    sub dl,'A'             ;A'dan çcikart 
    add al,26              ;26 ile topla
    sub al,dl              ;Anahtari çikar
    cmp al,26
    jb decrypt_no          ;Eger 26'dan kucukse islemi bitir
    sub al,26              ;26'dan buyukse 'A' harfine geri sar 26 cikart
decrypt_no:
    add al,'A'             ;Sonuç harfini 'A' ile baslat
    mov [di],al            ;Sonuç karakterini DI'ya yaz
    inc di
    inc bx
    mov dl,[key_count]     ;Anahtarin uzunlugunu kontrol et
    mov dh,0
    cmp bx,dx
    jb decrypt_skip_reset   ;Eger anahtarin sonuna gelmediysek gecç
    xor bx,bx              ;Anahtari sifirla
decrypt_skip_reset:
    inc si         ;metnin bir sonraki karakterine geciyoruz.
    dec cx         ;cxi 1 azaltiyoruz 0 olunca dongu sonlancak cs=harf sayisi
    jmp decrypt_loop     ;sifreleme islemine geri don

decrypt_done:
    mov byte ptr [di],'$'   
    ret
decrypt endp