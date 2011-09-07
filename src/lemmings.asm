			INCLUDE	"defines.asm"		; Coco hardware definitions

			SECTION	.program_code_physical_map ; $FFA6
			FCB	Block_ProgramCode
			ENDSECTION

			SECTION .bss,bss
_main_chunk_counter	RMB	2
			ENDSECTION

			SECTION program_code
ProgramCode		EXPORT
ProgramCode		;** To be loaded at $C000
			
			orcc	#$50			; Disable interrupts (just in case)
			lds	#Stack			; Relocate stack

			lbsr	set_graphics_mode	; 256x192x16
			lbsr	set_palette		; specified in module-gfx
	
			lbsr	clear_virtual_screen	; Go clear some ram
			;** By reaching here, pages 0 through 0E should be cleared


			;** Get LevelData into ram
			lda	#Block_LevelData	; LevelData
			sta	Page_LevelData		; $8000

			ldy	#LevelData		; y = start of level
			ldx	LevelStruct.TotalTerrain,y ; x now holds the count
			stx	_main_chunk_counter	; keep it
			leay	sizeof{LevelStruct},y	; y should now point to first levelchunk
_next_level_chunk	
			pshs	y			; keep struct for later
			lda	LevelTerrainStruct.PosTop,y	; vertical loc
			ldx	LevelTerrainStruct.PosLeft,y	; horizontal loc
			ldb	LevelTerrainStruct.DrawNotOverlap,y ; draw mode
			;clrb
			pshs	d
			clra
			ldb	LevelTerrainStruct.ID,y	; y now = id
			tfr	d,y
			puls	d
			lbsr	draw_terrain_chunk
			puls	y			; y = chunk just drawn
			leay	sizeof{LevelTerrainStruct},y ; move to next chunk
			ldx	_main_chunk_counter	; get and dec counter
			leax	-1,x
			stx	_main_chunk_counter
			cmpx	#0
			bne	_next_level_chunk


			ldx	#0			; offset to view

!			pshs	x
			lbsr	copy_virt_to_phys	; render it to gfx
			puls	x
			leax	4,x
			cmpx	#640
			blo	<


ENDLOOP			jmp	ENDLOOP
			ENDSECTION

			SECTION	.program_code_stack
Stack			EXPORT
			rmb 	255
Stack			EQU	*
			ENDSECTION
