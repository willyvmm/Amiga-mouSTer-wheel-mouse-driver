export PATH := /opt/amiga/bin:$(PATH)

OBJDIR = obj
SRCDIR = src
SCRIPDIR = scripts

MOUSTER_SETTINGS = $(SRCDIR)/mouSTer.mk

include $(MOUSTER_SETTINGS)

vpath %.c $(SRCDIR)
vpath %.h $(SRCDIR)
vpath %.s $(SRCDIR)

MOUSTERDRIVER = mouSTer.driver
MOUSTER=mouSTer
ADF=$(MOUSTER).adf
LHAFILE=$(MOUSTER).lha
OBJ = $(addprefix $(OBJDIR)/, mouSTerDriver.o mouSTerVBInterrupt.o )


TEMPLATEDIR = template
TEMPLATEBIN = $(TEMPLATEDIR)/$(MOUSTER)/$(MOUSTERDRIVER)

PREFIX = m68k-amigaos-

CC = $(PREFIX)gcc
SIZE = $(PREFIX)size

# this is replacement for built in GCC __DATE__ macro. I dont like the format.
# -Wno-builtin-macro-redefined -D__DATE__=$(shell date '+"\"%d-%m-%Y\""')
CFLAGS = -s -Os -Werror -fomit-frame-pointer -Wno-builtin-macro-redefined -D__DATE__=$(shell date '+"\"%d-%m-%Y\""')
LDFLAGS = -noixemul -fbaserel 

VASM = vasmm68k_mot

INCLUDE = /opt/amiga/m68k-amigaos/ndk-include/
VASMFLAGS = -Fhunk -I $(INCLUDE) 

DEPS = newmouse.h mouSTer_protocol.h

$(OBJDIR)/%.o: %.s $(DEPS)
	$(VASM) $(VASMFLAGS) -L $(basename $@)'.lst' -o $@ $<

$(OBJDIR)/%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS) -DBUILD_VERSION=$(shell echo $(MOUSTER_VERSION_STRING))



all: $(MOUSTERDRIVER) inc_build

.PHONY: adf noparity inc_build debug help

$(MOUSTERDRIVER): $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJ)  
	$(SIZE) $@	
	cp -f $(MOUSTERDRIVER) ${TEMPLATEBIN}

noparity: VASMFLAGS += -DNO_PARITY
noparity: clean $(MOUSTERDRIVER) adf

debug: VASMFLAGS += -DDEBUG
debug: CFLAGS += -DDEBUG
debug: clean $(MOUSTERDRIVER) adf


clean:
	rm -rf $(OBJDIR)/*.* ${TEMPLATEBIN} $(MOUSTERDRIVER) $(MOUSTER).*

adf: $(MOUSTERDRIVER)
	@$(SCRIPDIR)/makeadf.sh $(TEMPLATEDIR) $(ADF)

pendrive: adf
	@$(SCRIPDIR)/makependrive.sh $(ADF)

inc_build: $(MOUSTERDRIVER)
	@sed -i -r 's/(MOUSTER_DRIVER_VER_BUILD = )([0-9]+)/echo "\1$$((\2+${MOUSTER_DRIVER_VER_BUILD_INC}))"/ge' ${MOUSTER_SETTINGS}

lha: $(MOUSTERDRIVER)
	@echo "creating $(LHAFILE)"
	@rm -f $(LHAFILE)
	@cd $(TEMPLATEDIR); lha a ../$(LHAFILE) * ; cd ..

help:
	@echo "Available targets:"
	@echo "all - build mouSTer.driver"
	@echo "adf - build mouSTer.adf image file"
	@echo "pendrive - build mouSTer.adf and copy to the first available USB pendrive (aka: USB Stisk, aka: USB Memory)"
	@echo "lha - build lha archive"
	@echo "debug - build with some debug options"
	@echo "noparity - build without parity check. Not recommended."
