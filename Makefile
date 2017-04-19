.SFILES		=	jaig.s
.OFILES		=	$(.SFILES:.s=.o) 
.AFILES		=	


ASFLAGS		=		  -I$(AGBINC) -mthumb-interwork
CFLAGS		=	-g -c -O2 -I$(AGBINC) -mthumb-interwork -nostdlib #-DNDEBUG
LDFLAGS		+=  -Map $(MAPFILE) -nostartfiles \
				-Ttext 0x08000000 -Tbss 0x03000000 
MAPFILE		=	jaig.map
TARGET_ELF	=	jaig.elf
TARGET_BIN	=	jaig.bin 

.SUFFIXES:  .bin
.bin.o:
	objcopy -v -I binary -O elf32-little $< $@


$(TARGET_BIN): $(TARGET_ELF)
	objcopy -v -O binary $< $@

$(TARGET_ELF): $(.OFILES) Makefile $(DEPENDFILE)
	@echo > $(MAPFILE)
	$(CC) -g -o $@ $(.OFILES) -Wl,$(LDFLAGS)

.PHONY: all clean depend



all:	clean depend $(TARGET_BIN)

clean:
	-rm $(.OFILES) $(DEPENDFILE) $(TARGET_ELF)

depend:
	$(CC) $(CFLAGS) -M $(.CFILES) > $(DEPENDFILE)

$(DEPENDFILE): 
	$(CC) $(CFLAGS) -M $(.CFILES) > $(DEPENDFILE)

include Gasdepend


