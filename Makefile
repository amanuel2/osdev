GPPARAMS =  -m32 -g -Iinclude -fno-use-cxa-atexit -o3 -nostdlib \
		    -fno-builtin -std=c++11 -fno-rtti -fno-exceptions -fno-leading-underscore \
		    
		    
LDPARAMS =  -melf_i386
objects = kernel.o boot.o
i686 = i686-elf-	
VB=virtualbox
VBM=VBoxManage


all: run_vb

compile:
	 i686-elf-g++ $(GPPARAMS) -o kernel.o -c kernel.c++ -ffreestanding
	nasm -f elf32 boot.asm -o boot.o


BoneOS.bin : linker.ld $(objects)
	ld $(LDPARAMS) -T $< -o $@ $(objects)
	
install: BoneOS.bin
	sudo cp $< /boot/BoneOS.bin

clean:
	  rm -f $(objects)
	  rm -f -rf iso
	  rm -f BoneOS.*
	  rm -f *.pcap
	  rm -f *.ini
	  rm -f qemu.log
	  rm -f bochslog.txt

qemu_compile: compile BoneOS.bin qemu
	

qemu:
	qemu-system-i386  -kernel  BoneOS.bin 

qemu_debug:
	qemu-system-i386 -kernel BoneOS.bin -s -d in_asm,cpu_reset,exec,int,guest_errors,pcall -no-reboot &>qemu.log

BoneOS.iso: BoneOS.bin 
	mkdir iso
	mkdir iso/boot
	mkdir iso/boot/grub
	cp BoneOS.bin iso/boot/BoneOS.bin
	echo 'set timeout=0'                      > iso/boot/grub/grub.cfg
	echo 'set default=0'                     >> iso/boot/grub/grub.cfg
	echo ''                                  >> iso/boot/grub/grub.cfg
	echo 'menuentry "BoneOS x86 " {' >> iso/boot/grub/grub.cfg
	echo '  multiboot /boot/BoneOS.bin'    >> iso/boot/grub/grub.cfg
	echo '  boot'                            >> iso/boot/grub/grub.cfg
	echo '}'                                 >> iso/boot/grub/grub.cfg
	grub-mkrescue --output=BoneOS.iso iso
	rm -rf iso

start-debug:
	qemu-system-i386 -S -s -kernel BoneOS.bin -m 1G -serial file:qemu-serial.log  -serial stdio -usb -device usb-host,hostbus=2,hostaddr=1
	
bochs:
	bochs -f bochsrc.txt -q

run_vb: compile BoneOS.bin BoneOS.iso
	-${VBM} unregistervm BoneOS --delete;
	echo "Creating VM"
	${VBM} createvm --name BoneOS --register
	${VBM} modifyvm BoneOS --memory 1024
	${VBM} modifyvm BoneOS --vram 64
	${VBM} modifyvm BoneOS --nic1 nat
	${VBM} modifyvm BoneOS --nictype1 82540EM
	${VBM} modifyvm BoneOS --nictrace1 on
	${VBM} modifyvm BoneOS --uart1 0x3F8 4
	${VBM} storagectl BoneOS --name "IDE Controller" --add ide
	${VBM} storageattach BoneOS --storagectl "IDE Controller" --port 0 \
	--device 0 --type dvddrive --medium BoneOS.iso 
	echo "Run VM"
	${VB} --startvm BoneOS --dbg

compile_iso: compile BoneOS.bin BoneOS.iso
