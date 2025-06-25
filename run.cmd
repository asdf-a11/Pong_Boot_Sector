@echo off
:run
"C:\Program Files\NASM\nasm" -e extend.asm
REM python "Font\\imgToBin.py" "Font\\0.png" "Font\\1.png" "Font\\2.png" "Font\\3.png" "Font\\4.png" "Font\\5.png" "Font\\6.png" "Font\\7.png" "Font\\8.png" "Font\\9.png"
"C:\Program Files\NASM\nasm" -f bin bootLoader.asm -o bootLoader.bin
"C:\Program Files\NASM\nasm" -f bin extend.asm -o out.bin
copy /b bootLoader.bin + out.bin os.flp
"C:\Program Files\qemu\qemu-system-x86_64.exe" -L "C:\Program Files\qemu" os.flp
echo ----------------
pause