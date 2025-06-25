;Macro for drawing a image arg1=ptr to image arg2 = xpos arg3 = ypos
%macro DrawImg 3
	[BITS 32];Tell assemblyer to treat as 32-bit code so when pushing to stack doesnt
	pushad   ;truncate values to 16 bits
	push %1
	push %2
	push %3
	pop esi
	pop edi
	pop eax
	[BITS 16];Tell assembler real mode because processor expects call and ret to be real mode
	call drawImg_f	
	[BITS 32];So popad matches the 32-bit assembled pushad prevoisly
	popad
	[BITS 16];Tell assembler back to real mode
%endmacro
clearScreenBlack:
	pushad
	mov ax, 0x0fff
	mov es, ax
	xor al, al
	mov cx, (SX*SY)
	xor di, di
	rep stosb;Quickly sets all video memory to 0
	popad
	ret
;Takes no arguments moves the display buffer into video memory to be displayed
display:
	pushad
	mov eax, VM
	mov ecx, BM
	
	.loop:
		cmp eax, VM+(SX*SY)
		jge .endLoop
		
		mov dl, byte[ecx]
		mov byte[eax], dl
		
		inc eax
		inc ecx
		jmp .loop
	.endLoop:
	
	popad
	ret
;_f notates that this is the function to be called from a Macro
drawImg_f: ; eax = ptr edi = xpos esi = ypos
	pushad
	push eax
		mov eax, SX
		mul esi
		add edi, eax
		add edi, BM
	pop eax
	;esi ecx x,y 
	xor ecx, ecx
	mov ebx, 8;jumps sizex and sizey in img file
	.loopY:
		mov edx, dword[eax+4]
		cmp ecx, edx
		jge .endLoopY
		
		xor esi, esi
		.loopX:
			mov edx, dword[eax]
			cmp esi, edx
			jge .endLoopX
			
			push eax		
				mov al, byte[eax+ebx]
				mov byte[edi], al
			pop eax
			
			inc esi	
			inc edi
			inc ebx
			jmp .loopX
		.endLoopX:
		
		add edi, SX
		sub edi, dword[eax]
		inc ecx
		jmp .loopY
	.endLoopY:	
	popad
	ret