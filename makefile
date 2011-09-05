# Make life easy
LWASM=lwasm
LWASM_OPTS=--includedir=src/includes

.PHONY: all
all: final/disk.dsk

# define all source files
	
assembly_srcs := loader_stage1.asm loader_stage2.asm lemmings.asm
assembly_includes := defines.asm module-gfx.asm

assembly_objs := loader_stage1.bin loader_stage2.rawbin lemmings.bin
# prepend dirs

assembly_srcs := $(addprefix src/,$(assembly_srcs))
assembly_objs := $(addprefix bin/,$(assembly_objs))
assembly_includes := $(addprefix src/includes/,$(assembly_includes))

final/disk.dsk: bin/lemmings.img
	decb dskini $@
	decb copy $< $@,L.BIN -2 -b
	
bin/%.bin: src/%.asm $(assembly_includes)
	$(LWASM) $(LWASM_OPTS) --format=decb --list=$*.list --symbols -o $@ $<

bin/%.rawbin: src/%.asm
	$(LWASM) $(LWASM_OPTS) --format=raw -o $@ $<
	
bin/lemmings.img: $(assembly_objs)
	cat $(assembly_objs) > $@

.PHONY: clean
clean:
	rm -f bin/*.bin
	rm -f bin/*.img
	rm -f bin/*.rawbin
	rm -f final/*.dsk
	rm -f *.list
	
.PHONY: run
run:	all
	sdlmess -debug -joystick_deadzone 1.100000 -joystick_saturation 0.550000 -skip_gameinfo \
	-ramsize 524288 -keepaspect -frameskip 0 -rompath /home/david/roms -video opengl -numscreens -1 \
	-nomaximize coco3p -floppydisk1 `pwd`/final/disk.dsk \
	2>&1 | cat > /dev/null
	

	
	
