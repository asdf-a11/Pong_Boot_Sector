%macro DrawImg 3
	[BITS 32]
	pushad
	push %1
	push %2
	push %3
	pop esi
	pop edi
	pop eax
	[BITS 16]
	call drawImg_f	
	popad
%endmacro
clearScreenBlack:
	pushad
	;mov eax, BM
	;.loop:
	;	cmp eax, BM+(SX*SY)
	;	jge .endLoop
	;	
	;	mov byte[eax], 0
	;	
	;	inc eax
	;	jmp .loop
	;.endLoop:
	mov ax, 0x0fff
	mov es, ax
	xor al, al
	mov cx, (SX*SY)
	xor di, di
	rep stosb
	popad
	ret
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