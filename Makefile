asm:
	nasm -f elf64 main.asm
	gcc -no-pie main.o -o test