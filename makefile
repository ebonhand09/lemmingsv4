# Lemmings makefile - linker version
LWASM=lwasm
LWASM_OPTS=--pragma=cescapes,undefextern --includedir=include
LWLINK=lwlink

.PHONY: all
all: lemmings.dsk

# define all source files here
lemmings_srcs := lemmings.asm module-gfx.asm module-drawterrain.asm module-interrupt.asm payload.asm

extra_srcs := loader_stage1.asm loader_stage2.asm

# terrain / level data
terrain_0_srcs := ter_0_00.xpm ter_0_01.xpm ter_0_02.xpm ter_0_03.xpm ter_0_04.xpm ter_0_05.xpm \
	ter_0_06.xpm ter_0_07.xpm ter_0_08.xpm ter_0_09.xpm ter_0_10.xpm ter_0_11.xpm ter_0_12.xpm \
	ter_0_13.xpm ter_0_14.xpm ter_0_15.xpm ter_0_16.xpm ter_0_17.xpm ter_0_18.xpm ter_0_19.xpm \
	ter_0_20.xpm ter_0_21.xpm ter_0_22.xpm ter_0_23.xpm ter_0_24.xpm ter_0_25.xpm ter_0_26.xpm \
	ter_0_27.xpm ter_0_28.xpm ter_0_29.xpm ter_0_30.xpm ter_0_31.xpm ter_0_32.xpm ter_0_33.xpm \
	ter_0_34.xpm ter_0_35.xpm ter_0_36.xpm ter_0_37.xpm ter_0_38.xpm ter_0_39.xpm ter_0_40.xpm \
	ter_0_41.xpm ter_0_42.xpm ter_0_43.xpm ter_0_44.xpm ter_0_45.xpm ter_0_46.xpm ter_0_47.xpm \
	ter_0_48.xpm ter_0_49.xpm
	
level_srcs := 0103.dat

terrain_0_objs := $(terrain_0_srcs:%.xpm=%.dat)
level_objs := $(level_srcs:%.dat=%.lvl)

terrain_0_srcs := $(addprefix resources/gfx/terrain/,$(terrain_0_srcs))
terrain_0_objs := $(addprefix bin/gfx/terrain/,$(terrain_0_objs))
level_srcs := $(addprefix resources/lvl/,$(level_srcs))
level_objs := $(addprefix bin/lvl/,$(level_objs))

binary_objs : $(terrain_0_objs) $(level_objs)

lemmings_linkscript := src/linkscript

# prepend src to the lemmings sources

lemmings_srcs := $(addprefix src/,$(lemmings_srcs))

all_srcs := $(lemmings_srcs) $(extra_srcs)

lemmings_objs := $(lemmings_srcs:%.asm=%.o)
all_objs := $(lemmings_objs) $(extra_srcs:%.asm=%.o)

#src/payload.asm: $(terrain_0_objs) $(level_objs)
src/payload.asm: include/terrain-offset-table.asm bin/gfx/terrain0.bin $(level_objs)

lemmings.bin: $(lemmings_objs) $(lemmings_linkscript)
	$(LWLINK) --format=decb --map=lemmings.map --script=$(lemmings_linkscript) -o $@ $(lemmings_objs)

lemmings.img: loader_stage1.bin loader_stage2.rawbin lemmings.bin
	cat loader_stage1.bin loader_stage2.rawbin lemmings.bin > $@

lemmings.dsk: lemmings.img
	decb dskini $@
	decb copy $< $@,L.BIN -2 -b

.PHONY: clean
clean:
	rm -f $(kernel_objs) lemmings.bin lemmings.img lemmings.dsk loader_stage1.bin \
loader_stage2.rawbin lemmings.map
	rm -f *.list
	rm -f src/*.list
	rm -f src/*.o
	rm -f bin/gfx/terrain/*.dat
	rm -f bin/gfx/*.bin
	rm -f bin/lvl/*.lvl
	rm -f include/terrain-offset-table.asm

%.o: %.asm
	$(LWASM) $(LWASM_OPTS) --list=$*.list --symbols --format=obj -o $@ $<

%.bin: %.asm
	$(LWASM) $(LWASM_OPTS) --list=$*.list --symbols --format=decb -o $@ $<

%.rawbin: %.asm
	$(LWASM) $(LWASM_OPTS) --list=$*.list --symbols --format=raw -o $@ $<
	
bin/lvl/%.lvl: $(level_srcs) tools/read-level.php
	tools/read-level.php $(filter %.dat, $<) $@
	
include/terrain-offset-table.asm: $(terrain_0_srcs)
	tools/build-terrain-table.php > $@
	
bin/gfx/terrain0.bin: $(terrain_0_objs)
	cat $^ > $@

bin/gfx/terrain/%.dat: resources/gfx/terrain/%.xpm tools/pal-terrain-0.php 
	tools/xpm2raw.php $(filter %.xpm, $<) $@ pal-terrain-0.php
	
.PHONY: run
run:	all
	sdlmess -debug -joystick_deadzone 1.100000 -joystick_saturation 0.550000 -skip_gameinfo \
	-ramsize 524288 -keepaspect -frameskip 0 -rompath /home/david/roms -video opengl -numscreens -1 \
	-nomaximize coco3p -floppydisk1 `pwd`/lemmings.dsk \
	2>&1 | cat > /dev/null
	
