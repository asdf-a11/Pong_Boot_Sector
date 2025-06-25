READ_SECTORS equ 64

%define false 0
%define true 1
%assign labName 0
;Macro for if equal to 
%macro if_e 2	
	%push if_e
	cmp %1, %2
	jne %$false
%endmacro
;Macro for if not equal to
%macro if_ne 2	
	%push if_ne
	cmp %1, %2
	je %$false
%endmacro
;If less than macro
%macro if_l 2	
	%push if_l
	cmp %1, %2
	jge %$false
%endmacro
;If less than or equal
%macro if_le 2	
	%push if_le
	cmp %1, %2
	jg %$false
%endmacro
;If greater than or equal
%macro if_ge 2	
	%push if_ge
	cmp %1, %2
	jl %$false
%endmacro
;If greater than
%macro if_g 2	
	%push if_g
	cmp %1, %2
	jle %$false
%endmacro

;Macro put after any if macro
%macro ifend 0	
	%$false:
	%pop
%endmacro

numToString: ;eax number ebx string ptr
	pushad
	
	mov ecx, 10
	push eax
		div ecx
		add dl, 48
		mov byte[ebx], dl
		inc ebx
	pop eax
	
	;done
	mov byte[ebx], 0
	
	popad
	ret

