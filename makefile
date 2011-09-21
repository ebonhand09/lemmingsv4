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
terrain_0_objs := ter_0_00.dat ter_0_01.dat ter_0_02.dat ter_0_03.dat ter_0_04.dat ter_0_05.dat \
	ter_0_06.dat ter_0_07.dat ter_0_08.dat ter_0_09.dat ter_0_10.dat ter_0_11.dat ter_0_12.dat \
	ter_0_13.dat ter_0_14.dat ter_0_15.dat ter_0_16.dat ter_0_17.dat ter_0_18.dat ter_0_19.dat \
	ter_0_20.dat ter_0_21.dat ter_0_22.dat ter_0_23.dat ter_0_24.dat ter_0_25.dat ter_0_26.dat \
	ter_0_27.dat ter_0_28.dat ter_0_29.dat ter_0_30.dat ter_0_31.dat ter_0_32.dat ter_0_33.dat \
	ter_0_34.dat ter_0_35.dat ter_0_36.dat ter_0_37.dat ter_0_38.dat ter_0_39.dat ter_0_40.dat \
	ter_0_41.dat ter_0_42.dat ter_0_43.dat ter_0_44.dat ter_0_45.dat ter_0_46.dat ter_0_47.dat \
	ter_0_48.dat ter_0_49.dat	


terrain_1_objs := ter_1_00.dat ter_1_01.dat ter_1_02.dat ter_1_03.dat ter_1_04.dat ter_1_05.dat \
	ter_1_06.dat ter_1_07.dat ter_1_08.dat ter_1_09.dat ter_1_10.dat ter_1_11.dat ter_1_12.dat \
	ter_1_13.dat ter_1_14.dat ter_1_15.dat ter_1_16.dat ter_1_17.dat ter_1_18.dat ter_1_19.dat \
	ter_1_20.dat ter_1_21.dat ter_1_22.dat ter_1_23.dat ter_1_24.dat ter_1_25.dat ter_1_26.dat \
	ter_1_27.dat ter_1_28.dat ter_1_29.dat ter_1_30.dat ter_1_31.dat ter_1_32.dat ter_1_33.dat \
	ter_1_34.dat ter_1_35.dat ter_1_36.dat ter_1_37.dat ter_1_38.dat ter_1_39.dat ter_1_40.dat \
	ter_1_41.dat ter_1_42.dat ter_1_43.dat ter_1_44.dat ter_1_45.dat ter_1_46.dat ter_1_47.dat \
	ter_1_48.dat ter_1_49.dat ter_1_50.dat ter_1_51.dat ter_1_52.dat ter_1_53.dat ter_1_54.dat \
	ter_1_55.dat ter_1_56.dat ter_1_57.dat ter_1_58.dat ter_1_59.dat ter_1_60.dat ter_1_61.dat \
	ter_1_62.dat ter_1_63.dat

level_srcs := 0323.dat

level_objs := $(level_srcs:%.dat=%.lvl)

terrain_0_objs := $(addprefix bin/gfx/extracted_terrain/,$(terrain_0_objs))
terrain_1_objs := $(addprefix bin/gfx/extracted_terrain/,$(terrain_1_objs))
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
#src/payload.asm: include/terrain-offset-table.asm bin/gfx/terrain0.bin $(level_objs)
src/payload.asm: include/terrain-offset-table.asm bin/gfx/terrain1.bin $(level_objs)

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
	rm -f bin/gfx/extracted_terrain/*.dat
	rm -f bin/gfx/*.bin
	rm -f bin/lvl/*.lvl
	rm -f include/terrain-offset-table.asm
	rm -f resources/*.php

%.o: %.asm
	$(LWASM) $(LWASM_OPTS) --list=$*.list --symbols --format=obj -o $@ $<

%.bin: %.asm
	$(LWASM) $(LWASM_OPTS) --list=$*.list --symbols --format=decb -o $@ $<

%.rawbin: %.asm
	$(LWASM) $(LWASM_OPTS) --list=$*.list --symbols --format=raw -o $@ $<
	
bin/lvl/%.lvl: $(level_srcs) tools/read-level.php
	tools/read-level.php $(filter %.dat, $<) $@
	
include/terrain-offset-table.asm: 
	tools/extract-terrain.php > $@
	
bin/gfx/terrain1.bin: $(terrain_1_objs)
	cat $^ > $@

bin/gfx/terrain/%.dat: tools/extract.terrain.php include/terrain-offset-table.asm
#	tools/xpm2raw.php $(filter %.xpm, $<) $@ pal-terrain-0.php
	
.PHONY: run
run:	all
	sdlmess -debug -joystick_deadzone 1.100000 -joystick_saturation 0.550000 -skip_gameinfo \
	-ramsize 524288 -keepaspect -frameskip 0 -rompath /home/david/roms -video opengl -numscreens -1 \
	-nomaximize coco3p -floppydisk1 `pwd`/lemmings.dsk \
	2>&1 | cat > /dev/null
	
