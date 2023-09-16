.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern scanf:proc
;extern time:proc
;extern srand:proc
;extern rand:proc
extern printf:proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "PROIECT->VAPORASE",0
area_width EQU 750
area_height EQU 550
area DD 0
n DD 0     ;nr de linii
m DD 0     ;nr de coloane
ddx DD 0   ;coordonata x
ddy DD 0   ;coordonata y
x_casuta DD 0 
y_casuta DD 0
vector DD 0
format DB "%d %d",0
succes DD 0
ratari DD 0
nedescoperite DD 0
rosu EQU 10       ;10 casute in care is parti din avioane is colorate cu rosu

counter DD 0      ; numara evenimentele de tip timer
counter_sec DD 0  ;cronometru in secunde 

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi],0E7DDDCh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
pixel macro

mov eax,[ebp+arg3]
mov ebx,area_width
mul ebx
mov ebx,[ebp+arg2]
add eax,ebx
shl eax,2
add eax,area
mov dword ptr [eax],0FF0000h
ENDM

linie_orizontala macro
local et_orizontal 
mov ecx,10
mov eax,[ebp+arg3]
mov ebx,area_width
mul ebx
mov ebx,[ebp+arg2]
add eax,ebx
shl eax,2
add eax,area
et_orizontal:
mov dword ptr [eax],0FF0000h
add eax,4
loop et_orizontal
ENDM

; linie_orizontala2 macro x,y
; local et_orizontal 
; mov ecx,80
; mov eax,y
; mov ebx,area_width
; mul ebx
; mov ebx,x
; add eax,ebx
; shl eax,2
; add eax,area
; et_orizontal:
; mov dword ptr [eax],028BCFCh
; add eax,4
; loop et_orizontal
; ENDM

linie_verticala macro
local et_vertical
mov ecx,100
mov eax,[ebp+arg3]
mov ebx,area_width
mul ebx
mov ebx,[ebp+arg2]
add eax,ebx
shl eax,2
add eax,area
et_vertical:
mov dword ptr [eax],0FF0000h
add eax,4*area_width
loop et_vertical
ENDM

; linie_verticala2 macro x,y
; local et_vertical
; mov ecx,400
; mov eax,y
; mov ebx,area_width
; mul ebx
; mov ebx,x
; add eax,ebx
; shl eax,2
; add eax,area
; et_vertical:
; mov dword ptr [eax],0FF0000h
; add eax,4*area_width
; loop et_vertical
; ENDM

dreptunghi macro x,y,lungime,latime,culoare  ;functie care creeaza si coloreaza un dreptunghi in fct de x si y si in fct de ce lungime si latime vrei
local bucla_line,bucla
mov eax,y 
mov ebx,area_width
mul ebx 
add eax,x 
shl eax,2 
add eax,area
mov ecx,latime
mov ebx,lungime
shl ebx,2
bucla : 
mov esi,ecx
mov ecx,lungime
bucla_line :
mov dword ptr[eax],culoare
add eax,4
loop bucla_line
mov ecx,esi
add eax,area_width*4
sub eax,ebx
loop bucla
ENDM

matrice_pe_coloane macro n  ;IMPARTE TABLA IN 650/n COLOANE
local et
mov ecx,n
mov eax,650
div ecx
mov ddx,eax
mov edi,50
add edi,ddx
et:
push ecx
dreptunghi edi,100,2,400,0
add edi,ddx
pop ecx
loop et
ENDM

matrice_pe_linii macro m  ;IMPARTE TABLA IN 400/m LINII
local et
mov ecx,m
mov eax,400
div ecx
mov ddy,eax
mov edi,100
add edi,ddy
et:
push ecx
dreptunghi 50,edi,650,2,0
add edi,ddy
pop ecx
loop et
ENDM

init macro    ;INITIALIZARE MATRICE CU 0 SI 1 ,1 FIIND BUCATI DIN VAPORASE(CRUCIULITA)
local et
mov eax,n
mul m
mov ecx,eax
mov esi,0
et:
mov eax,[vector]
mov dword ptr[eax+esi*4],0
inc esi
loop et
mov eax,[vector]
mov dword ptr[eax+1*4], 1
mov dword ptr[eax+8*4], 1
mov dword ptr[eax+9*4], 1
mov dword ptr[eax+10*4],1
mov dword ptr[eax+17*4],1 
mov dword ptr[eax+29*4],1 
mov dword ptr[eax+36*4],1
mov dword ptr[eax+37*4],1
mov dword ptr[eax+38*4],1
mov dword ptr[eax+45*4],1

; push 0
; call time
; add esp,4
; push eax
; call srand
; add esp,4
; call rand
ENDM

colorare macro x,y     ;COLOREAZA CASUTA DIN TABLA SI CALCULEAZA UNDE AM DAT CLICK(IN CE PATRATEL DIN TABLA)
local et,continuare,final
mov esi,[vector]
cmp dword ptr x,50
jl final
cmp dword ptr y,100
jl final
cmp dword ptr x,700
jg final
cmp dword ptr y,500
jg final
mov eax,x
sub eax,50
mov edx,0
div ddx
mov x_casuta,eax
  
mov eax,y
sub eax,100
mov edx,0
div ddy
mov y_casuta,eax

mov eax,x_casuta
mul ddx
add eax,50
mov x,eax
mov eax,y_casuta
mul ddy
add eax,100
mov y,eax
 
mov eax,y_casuta
mul m
add eax,x_casuta
cmp dword ptr[esi+eax*4],1 
jne et
dreptunghi x,y,ddx,ddy,0FA1C0Ah
inc succes       ;NUMAR DE LOVITURI CU SUCCES
jmp final 
et:
dreptunghi x,y,ddx,ddy,0A23FAh
inc ratari       ;NUMAR DE LOVITURI RATATE  
final:
ENDM

draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0C5CBDAh
	push area
	call memset
	add esp, 12
	dreptunghi 50,100,650,400,0E7DDDCh  ;DREPTUNGHIUL PENTRU TABLA
	matrice_pe_coloane n                ;COLOANELE TABLEI
	matrice_pe_linii m                  ;LINIILE TABLEI
	dreptunghi 45,95,655,10,04D38BFh    ;CONTUR TABLA
	dreptunghi 45,100,10,400,04D38BFh   ;CONTUR TABLA
	dreptunghi 45,495,655,10,04D38BFh   ;CONTUR TABLA
	dreptunghi 695,95,10,410,04D38BFh   ;CONTUR TABLA
	;dreptunghi 335,70,80,2,028BCFCh    ;SUBLINIERE TITLU
	init                                ;INITIALIZARE
	jmp afisare_litere

evt_click:
    mov eax,[ebp+arg3] 
    mov ebx,area_width
    mul ebx 
    add eax,[ebp+arg2]
    shl eax,2 
    add eax,area
	cmp dword ptr[eax],0E7DDDCh     ;VERIFICAM SA NU SE DEA CLICK PE ACEEASI CASUTA COLORATA IN ALBASTRU/ROSU SI SA SE CONTORIZEZE
	jne evt_timer
	colorare [ebp+arg2],[ebp+arg3]	;COLORAM
	jmp afisare_litere
	
evt_timer:
	inc counter
	cmp counter,5     ;TRANSFORMAM TIMPUL IN SECUNDE
	jne afisare_litere
	mov counter,0
	inc counter_sec 
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)	
	mov ebx, 10
	mov eax, counter_sec
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	
	make_text_macro edx, area, 10, 10
	
	;scriem un mesaj
	make_text_macro 'N', area, 315, 530
	make_text_macro 'E', area, 325, 530
	make_text_macro 'D', area, 335, 530
	make_text_macro 'E', area, 345, 530
	make_text_macro 'S', area, 355, 530
	make_text_macro 'C', area, 365, 530
	make_text_macro 'O', area, 375, 530 
	make_text_macro 'P', area, 385, 530
	make_text_macro 'E', area, 395, 530
	make_text_macro 'R', area, 405, 530
	make_text_macro 'I', area, 415, 530
	make_text_macro 'T', area, 425, 530
	make_text_macro 'E', area, 435, 530
	
	mov edi,rosu
    mov nedescoperite,edi
    mov edi,succes
    sub nedescoperite,edi
	mov ebx, 10
	mov eax, nedescoperite
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 470, 530
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 460, 530
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 450, 530
	
	
	make_text_macro 'V', area, 335, 50
	make_text_macro 'A', area, 345, 50
	make_text_macro 'P', area, 355, 50
	make_text_macro 'O', area, 365, 50
	make_text_macro 'R', area, 375, 50
	make_text_macro 'A', area, 385, 50
	make_text_macro 'S', area, 395, 50
	make_text_macro 'E', area, 405, 50 
	 
	make_text_macro 'S', area, 10, 510
	make_text_macro 'U', area, 20, 510
	make_text_macro 'C', area, 30, 510
	make_text_macro 'C', area, 40, 510
	make_text_macro 'E', area, 50, 510
	make_text_macro 'S', area, 60, 510
	 
	mov ebx, 10
	mov eax, succes
	cmp eax,10
	jge success
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 95, 510
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 85, 510
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 75, 510
	
	make_text_macro 'R', area, 645, 510
	make_text_macro 'A', area, 655, 510
	make_text_macro 'T', area, 665, 510
	make_text_macro 'A', area, 675, 510
	make_text_macro 'R', area, 685, 510
	make_text_macro 'I', area, 695, 510
	
	mov ebx, 10
	mov eax, ratari
	cmp eax,25
	jg joc_pierdut
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 730, 510
	;cifra zecilor
	mov edx, 0
	div ebx 
	add edx, '0'
	make_text_macro edx, area, 720, 510
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 710, 510
	
    jmp final_draw
	
	joc_pierdut:
	make_text_macro 'J', area, 318, 15
	make_text_macro 'O', area, 328, 15
	make_text_macro 'C', area, 338, 15
	
	make_text_macro 'P', area, 358, 15
	make_text_macro 'I', area, 368, 15
	make_text_macro 'E', area, 378, 15
	make_text_macro 'R', area, 388, 15
	make_text_macro 'D', area, 398, 15
	make_text_macro 'U', area, 408, 15
	make_text_macro 'T', area, 418, 15
	make_text_macro 'X', area, 428, 15
	jmp final_draw
	
	success:
	make_text_macro 'F', area, 278, 15
	make_text_macro 'E', area, 288, 15
	make_text_macro 'L', area, 298, 15
	make_text_macro 'I', area, 308, 15
	make_text_macro 'C', area, 318, 15
	make_text_macro 'I', area, 328, 15
	make_text_macro 'T', area, 338, 15
	make_text_macro 'A', area, 348, 15 
	make_text_macro 'R', area, 358, 15
	make_text_macro 'I', area, 368, 15
	make_text_macro 'X', area, 378, 15
	
	make_text_macro 'A', area, 398, 15
	make_text_macro 'I', area, 408, 15
	
	make_text_macro 'C', area, 428, 15
	make_text_macro 'A', area, 438, 15
	make_text_macro 'S', area, 448, 15
	make_text_macro 'T', area, 458, 15
	make_text_macro 'I', area, 468, 15
	make_text_macro 'G', area, 478, 15
	make_text_macro 'A', area, 488, 15
	make_text_macro 'T', area, 498, 15
	make_text_macro 'X', area, 508, 15
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
    push offset n
    push offset m
    push offset format
    call scanf
    add esp,12
	
	
	mov eax, m     ;CITIM M SI N DE LA TASTATURA 
	mov ebx, n
	mul ebx
	shl eax,2
	push eax
	call malloc
	add esp, 4
	mov vector,eax
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
