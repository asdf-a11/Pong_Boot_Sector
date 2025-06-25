[org 0x7c00]
[BITS 16]

;Important data when booting in real hardware especily of USB stick

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

;Global varaibles
READ_SECTORS equ 64
bootMsg: db 'GS.', 0
diskReadErrMsg: db 'F', 0
diskReadSuccMsg: db 'S', 0
BOOT_DISK: db 0
BOOT_DISK_READ_SIZE: db READ_SECTORS	
PROGRAM_SPACE equ 0x7e00
VIDEO_MEMORY equ 0xb8000

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

    ;Stack grows downwards from the bootloader
    mov bp, 0x7c00 ; 0x7c00
    mov sp, bp

    ;Save the boot device for loading the later segments
    mov [BOOT_DISK], dl

    ;For deabugging to show that it has been loaded and is running
    mov bx,bootMsg
    call print

    ;Read later segments into memory
    call readDisk    
	mov bx, diskReadSuccMsg
	call print

    ;Jump to second segment where pong program exists
	jmp PROGRAM_SPACE

;Macro used for quick debugging takes a character like 'A' does not maintain registers
%macro PrintChar 1
	mov ah, 0xe
	mov al, %1
	int 0x10
%endmacro
; takes bx as string ptr clobbers registers
print: 
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
;Takes no arguments and clobbers registers
readDisk:
    mov ah, 0x02
    mov bx, PROGRAM_SPACE
    mov al, [BOOT_DISK_READ_SIZE];al is the number of sectors to read (512 bytes each)
    mov dl, [BOOT_DISK];dl is device to read from BOOT_DISK is device id from which the program was booted from
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02

    int 0x13
    jc .errorCode;carry flag is set if error occures
    ret

    .errorCode:;If error display error string and enter infinate loop
    mov bx, diskReadErrMsg
    call print
    jmp $

;%define vm VIDEO_MEMORY	
	

times 510-($-$$) db 0
dw 0xaa55
