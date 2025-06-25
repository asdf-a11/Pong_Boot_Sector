[org 0x7e00]
[bits 16]

jmp main

VM equ 0xA0000
TM equ 0xb8000
SX equ 320
SY equ 200
;SS for Screen Size
%define SS (SX*SY)
;Where it stores the second video buffer for storing a frame before it is renderd
BM equ 0xfff0
;Address of the timer that bios updates
TIMER equ 0x046C
TICKS_PER_SECOND equ 18
PLAYER_UP_KEY equ 'w'
PLAYER_DOWN_KEY equ 's'
ENEMY_UP_KEY equ 'j'
ENEMY_DOWN_KEY equ 'k'
keyboardAddr: dd 0; Address of keyboard buffer initiolized at program start
px: dd distFromBack
py: dd 11
ex: dd SX-distFromBack
ey: dd 0
ballX: dd SX/2
ballY: dd SY/2
ballVX: dd 0
ballVY: dd 0
ScoreE: db 0,0,0
ScoreP: db 0,0,0
;List of 32-bit pointers to each font image for 0-9 characters
FontList: times 10 dd 0
;game code
speed equ 4
batSizeY equ 30
distFromBack equ 10


%include "settings.asm"
%macro dbPixel 2
	push eax
	mov eax, BM
	add eax, %1
	mov byte[eax], %2
	pop eax
%endmacro
%include "DrawCode.asm"
main:	
	;Using VGA mode 0x13
	mov ax, 0x13
	int 0x10 
	
	;Stack allocate buffer to store keypresses
	sub esp, 256
	mov dword[keyboardAddr], esp

	;Initilize game
	call ResetBall
	call FillFontList
	
	.gameLoop:		
		call clearScreenBlack
		
		call UpdateKeyboard
		call PlayerInput
		call EnemyInput
		
		call DrawScores
		
		call DrawHalfWay
		
		call UpdateBall
		call DrawBall
		
		call DrawPlayer
		call DrawEnemy
		
		call display
		
		mov eax, 1 ;Wait one tick
		call WaitTick
	jmp .gameLoop


DrawPerson:;ecx x ptr ebx yptr
	pushad	
	mov eax, SX
	mul dword[ebx]
	add eax, BM
	add eax, dword[ecx]
	
	mov ecx, eax
	push eax
		mov eax, SX
		mov edx, batSizeY
		mul edx
		add ecx, eax
	pop eax
	
	.loop:
		cmp eax, ecx
		jge .endLoop
		
		mov byte[eax], 10
		
		add eax, SX
		jmp .loop
	.endLoop:
	popad
	ret
DrawPlayer:
	push ebx
	push edx
	
	mov ebx, py
	mov ecx, px
	call DrawPerson
	
	pop edx
	pop ebx
	ret
DrawEnemy:
	push ebx
	push edx
	
	mov ebx, ey
	mov ecx, ex
	call DrawPerson
	
	pop edx
	pop ebx
	ret
DrawHalfWay:
	pushad
	
	xor ecx, ecx
	mov edx, BM+(SX/2)
	.loop:
		cmp ecx, SY-1
		jge .endLoop
		
		mov byte[edx], 11
		
		add edx, 10*SX
		add ecx, 10
		jmp .loop	
	.endLoop:
	
	popad
	ret
DrawScores:
	pushad	
	
	
	mov eax, 6*8+8
	mov bl, byte[ScoreP]
	mul bl
	add eax, Font0
	mov edi, 100
	mov esi, 15
	call drawImg_f
	
	mov eax, 6*8+8
	mov bl, byte[ScoreP+1]
	mul bl
	add eax, Font0
	mov edi, 107
	mov esi, 15
	call drawImg_f

	mov eax, 6*8+8
	mov bl, byte[ScoreE]
	mul bl
	add eax, Font0
	mov edi, 200
	mov esi, 15
	call drawImg_f
	
	mov eax, 6*8+8
	mov bl, byte[ScoreE+1]
	mul bl
	add eax, Font0
	mov edi, 207
	mov esi, 15
	call drawImg_f
	
	popad
	ret
ResetBall:
	mov dword[ballX], SX/2
	mov dword[ballY], SY/2
	;pick random number for velocity
	mov dword[ballVX], 4
	mov dword[ballVY], 2
	ret
%macro addToString 1
	push eax
		mov al, byte[%1 +1]
		if_e al, 9
			mov byte[%1 +1], 0
			inc byte[%1]
			jmp %%endInc
		ifend
		inc byte[%1 +1]
		%%endInc:
	pop eax
%endmacro
UpdateBall:
	push eax
		mov eax, dword[ballX]
		add eax, dword[ballVX]
		mov dword[ballX], eax
		
		mov eax, dword[ballY]
		add eax, dword[ballVY]
		mov dword[ballY], eax
		
		;Enemy end
		if_ge dword[ballX], SX-distFromBack-1
			mov eax, dword[ey]
			if_ge dword[ballY], eax
				add eax, batSizeY
				if_le dword[ballY], eax
					mov eax, dword[ballVX]
					add eax, eax; double value
					;inc eax;increase speed
					sub dword[ballVX], eax ; set signed bit
				ifend
			ifend
		ifend
		if_ge dword[ballX], SX-1
			addToString ScoreP
			call ResetBall
		ifend
		;Player end
		if_le dword[ballX], distFromBack
			mov eax, dword[py]
			if_ge dword[ballY], eax
				add eax, batSizeY
				if_le dword[ballY], eax
					mov eax, dword[ballVX]
					add eax, eax; double value
					;dec eax
					sub dword[ballVX], eax ; set signed bit
				ifend
			ifend
		ifend
		if_le dword[ballX], 1
			addToString ScoreE
			call ResetBall
		ifend
		;top of the screen
		if_le dword[ballY], 1
			mov eax, dword[ballVY]
			add eax, eax
			sub dword[ballVY], eax
		ifend
		;bottem of the screen
		if_ge dword[ballY], SY-1
			mov eax, dword[ballVY]
			add eax, eax
			sub dword[ballVY], eax
		ifend
	pop eax
	ret
DrawBall:
	push eax
	mov eax, SX
	mul dword[ballY]
	add eax, dword[ballX]
	add eax, BM
	mov byte[eax], 9; ball colour
	pop eax
	ret
PlayerInput:
	push eax
	mov al, PLAYER_UP_KEY
	call CheckKey
	if_e al, 1
		mov eax, dword[py]		
		if_g eax, 0
			sub eax, speed
			mov dword[py], eax
		ifend
	ifend
	mov al, PLAYER_DOWN_KEY
	call CheckKey
	if_e al, 1
		mov eax, dword[py]
		if_l eax, SY-batSizeY
			add eax, speed
			mov dword[py], eax
		ifend
	ifend
	pop eax
	ret
EnemyInput:
	push eax
	mov al, ENEMY_UP_KEY
	call CheckKey
	if_e al, 1
		mov eax, dword[ey]		
		if_g eax, 0
			sub eax, speed
			mov dword[ey], eax
		ifend
	ifend
	mov al, ENEMY_DOWN_KEY
	call CheckKey
	if_e al, 1
		mov eax, dword[ey]
		if_l eax, SY-batSizeY
			add eax, speed
			mov dword[ey], eax
		ifend
	ifend
	pop eax
	ret
FillFontList:
	mov dword[FontList+0], Font0
	mov dword[FontList+4], Font1
	mov dword[FontList+8], Font2
	mov dword[FontList+12], Font3
	mov dword[FontList+16], Font4
	mov dword[FontList+20], Font5
	mov dword[FontList+24], Font6
	mov dword[FontList+28], Font7
	mov dword[FontList+32], Font8
	mov dword[FontList+36], Font9
	ret
UpdateKeyboard:
	pushad
	mov eax, dword[keyboardAddr]
	mov ecx, eax
	add ecx, 256;end buffer
	.loop:
		cmp eax, ecx
		jge .endLoop
		
		mov byte[eax], 0
		
		inc eax
		jmp .loop
	.endLoop:
	
	xor eax, eax
	pushad	
	.nextKey:
		mov ah,0x01
		int 0x16
		jz .doneKeypresses
		mov ah,0x00
		int 0x16
		;al keypresses
        ;mov ah, 0xe
        ;int 0x10
		;dbPixel SX*4+200, ah
		mov edx, dword[keyboardAddr]
		add dl,al
		mov byte[edx], 1		
		jmp .nextKey
	.doneKeypresses:
	popad
	
	popad
	ret
CheckKey:;al key
	push edx
	mov edx, dword[keyboardAddr]
	add dl, al
	mov al, byte[edx]
	pop edx
	ret
;return al bool
WaitSeconds:; eax = seconds
	pushad
	mov ebx, dword[TIMER]
	mov edx, TICKS_PER_SECOND
	mul edx
	add ebx, eax
	.loop:
	cmp dword[TIMER], ebx
	js .loop	
	popad
	ret
;Eax is the number of ticks to wait
WaitTick:
	pushad
	mov bx, word[TIMER]
	add bx, ax
	.loop:
		cmp word[TIMER], bx
		js .loop	
	popad
	ret


;Include all font images as part of the program
%assign i 0
%rep 10
Font%[i]:
	;%define quot "
	;%define stringify(x) quot %+ x %+ quot
	%defstr myString Font\\%[i].bin
	incbin myString
	%assign i i+1
%endrep

times 512* READ_SECTORS -($-$$) db 0