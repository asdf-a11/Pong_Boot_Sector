[org 0x7c00]
[BITS 16]

;Important data when booting in real hardware especily of USB stick
READ_SECTORS equ 64
boot:
    jmp main
    TIMES 3-($-$$) DB 0x90   ; Support 2 or 3 byte encoded JMPs before BPB.

    ; Dos 4.0 EBPB 1.44MB floppy
    OEMname: db    "mkfs.fat"  ; mkfs.fat is what OEMname mkdosfs uses
    bytesPerSector:    dw    512
    sectPerCluster:    db    1
    reservedSectors:   dw    1
    numFAT:            db    2
    numRootDirEntries: dw    224
    numSectors:        dw    2880
    mediaType:         db    0xf0
    numFATsectors:     dw    9
    sectorsPerTrack:   dw    18
    numHeads:          dw    2
    numHiddenSectors:  dd    0
    numSectorsHuge:    dd    0
    driveNum:          db    0
    reserved:          db    0
    signature:         db    0x29
    volumeID:          dd    0x2d7e5a1a
    volumeLabel:       db    "NO NAME    "
    fileSysType:       db    "FAT12   "

main:
	
    ;Dont need to use segment registers so sell them to 0
    mov ax, 0x00
    mov es, ax
    mov ss, ax
    mov ds, ax
    ;Make sure direction flag is set to avoid random changes in behavoir
    cld

    ;TODO remove this
    xor ax,ax
    mov ds, ax

    ;.setStack:
    ;Stack grows downwards from the bootloader
    mov bp, 0x7c00 ; 0x7c00
    mov sp, bp
    ;.diskRead:
    ;Save the boot device for loading the later segments
    mov [BOOT_DISK], dl

    ;For deabugging to show that it has been loaded and is running
    mov bx,bootMsg
    call print

    ;Read later segments into memory
    call readDisk
	;.loop1:
    
	mov bx, diskReadSuccMsg
	call print

	;jmp switch_to_pm
    ;Jump to second segment where pong program exists
	jmp 0x7e00
	
	;jmp $
;Macro used for quick debugging takes a character like 'A' does not maintain registers
%macro PrintChar 1
	mov ah, 0xe
	mov al, %1
	int 0x10
%endmacro
;functions
print: ; takes bx as string ptr
    mov ah, 0x0e
    .loop:
    mov al, [bx]
    cmp al, 0x0
    je .end
    int 0x10
    inc bx
    jmp .loop
    .end:
    mov al, 0xa
    int 0x10
    ret
readDisk:
    mov ah, 0x02
    mov bx, PROGRAM_SPACE
    mov al, [BOOT_DISK_READ_SIZE]; 2048 Bytes read number of 512 bytes
    mov dl, [BOOT_DISK]
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02

    int 0x13
    jc .errorCode
    ret

    .errorCode:
    mov bx, diskReadErrMsg
    call print
    jmp $
	
;gdt
gdt_start:

gdt_null:           ; The mandatory null descriptor
    dd 0x0          ; dd = define double word (4 bytes)
    dd 0x0

gdt_code:           ; Code segment descriptor
    dw 0xffff       ; Limit (bites 0-15)
    dw 0x0          ; Base (bits 0-15)
    db 0x0          ; Base (bits 16-23)
    db 10011010b    ; 1st flags, type flags
    db 11001111b    ; 2nd flags, limit (bits 16-19)
    db 0x0          ; Base (bits 24-31)

gdt_data:
    dw 0xffff       ; Limit (bites 0-15)
    dw 0x0          ; Base (bits 0-15)
    db 0x0          ; Base (bits 16-23)
    db 10010010b    ; 1st flags, type flags
    db 11001111b    ; 2nd flags, limit (bits 16-19)
    db 0x0

gdt_end:            ; necessary so assembler can calculate gdt size below

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; GDT size

    dd gdt_start                ; Start adress of GDT

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

;vars
bootMsg: db 'GS.', 0
diskReadErrMsg: db 'F', 0
diskReadSuccMsg: db 'S', 0
BOOT_DISK: db 0
BOOT_DISK_READ_SIZE: db READ_SECTORS	
PROGRAM_SPACE equ 0x7e00
VIDEO_MEMORY equ 0xb8000


	
; Switch to protected mode
switch_to_pm:

    ;mov bx, MSG_SWITCHING       ; Log
    ;call print_string
	mov ax, 0x2401
	int 0x15 ; enable A20 bit
	mov ax, 0x13
	int 0x10 ; set vga text mode 3

    cli                         ; Clear interrupts

    lgdt [gdt_descriptor]       ; Load GDT

    mov eax, cr0                ; Set the first bit of cr0 to move to protected mode, cr0 can't be set directly
    or eax, 0x1                 ; Set first bit only
    mov cr0, eax

    jmp CODE_SEG:init_pm        ; Make far jump to to 32 bit code. Forces CPU to clear cache

[bits 16]
; Initialize registers and the stack once in PM
init_pm:

    mov ax, DATA_SEG            ; Now in PM, our old segments are meaningless
    mov ds, ax                  ; so we point our segment registers to the data selector defined GDT
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ;mov ebp, 0x90000            ; Move stack
    ;mov esp, ebp

    call BEGIN_PM               ; Call 32 bit PM code
	
	jmp $
	
	
%define vm VIDEO_MEMORY	

BEGIN_PM:
	;call DetectCPUID
	jmp PROGRAM_SPACE
	;jmp $
	

times 510-($-$$) db 0
dw 0xaa55
