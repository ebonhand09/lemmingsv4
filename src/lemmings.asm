			INCLUDE	"defines.asm"		; Coco hardware definitions

			SECTION	.program_code_physical_map ; $FFA6
			FCB	Block_ProgramCode
			ENDSECTION

			SECTION .bss,bss
_main_chunk_counter	RMB	2
_cur_vid_draw_block	EXPORT
_alt_vid_draw_block	EXPORT
_cur_vid_show_loc	EXPORT
_alt_vid_show_loc	EXPORT
_cur_vid_draw_block	RMB	1
_alt_vid_draw_block	RMB	1
_cur_vid_show_loc	RMB	2
_alt_vid_show_loc	RMB	2
_pc_start_loc		RMB	2
			ENDSECTION

			SECTION program_code
ProgramCode		EXPORT
ProgramCode		;** To be loaded at $C000
			
			orcc	#$50			; Disable interrupts (just in case)
			lds	#Stack			; Relocate stack

			
			lda	#Block_ScreenBuffer_0	; block number for buffer 0
			sta	_cur_vid_draw_block

			lda	#Block_ScreenBuffer_1
			sta	_alt_vid_draw_block

			lda	#Phys_ScreenBuffer_0	; Physical show loc for buffer 0
			sta	_alt_vid_show_loc

			lda	#Phys_ScreenBuffer_1
			sta	_cur_vid_show_loc

			lbsr	set_graphics_mode	; 256x192x16
			lbsr	set_palette		; specified in module-gfx
	
			lbsr	clear_virtual_screen	; Go clear some ram
			;** By reaching here, pages 0 through 0E should be cleared


			;** Get LevelData into ram
			lda	#Block_LevelData	; LevelData
			sta	Page_LevelData		; $8000

			ldy	#LevelData		; y = start of level
			ldx	LevelStruct.ScreenStart,y
			stx	_pc_start_loc
			ldx	LevelStruct.TotalTerrain,y ; x now holds the count
			stx	_main_chunk_counter	; keep it
			leay	sizeof{LevelStruct},y	; y should now point to first levelchunk
_next_level_chunk	
			pshs	y			; keep struct for later
			lda	LevelTerrainStruct.PosTop,y	; vertical loc
			ldx	LevelTerrainStruct.PosLeft,y	; horizontal loc
			ldb	LevelTerrainStruct.DrawFlags,y	; get draw mode
			pshs	d
			clra
			ldb	LevelTerrainStruct.ID,y	; y now = id
			tfr	d,y
			puls	d

			;** hacky test code
			ldy	#23			; terrain id
			lda	#0			; 1px top
			ldx	#0			; 1px left
			ldb	#0			; normal draw
			lbsr	draw_terrain_chunk

			;ldy	#23			; terrain id
			;lda	#0			; top
			;ldx	#12
			;ldb	#1
			;lbsr	draw_terrain_chunk

			ldy	#21			; terrain id
			lda	#0			; 1px top
			ldx	#1			; 1px left
			ldb	#6			; normal draw
			lbsr	draw_terrain_chunk

			;ldy	#23			; terrain id
			;lda	#24			; top
			;ldx	#12
			;ldb	#1
			;lbsr	draw_terrain_chunk

			;ldy	#16			; terrain id
			;lda	#15			; top
			;ldx	#8			; left
			;ldb	#4			; black
			;lbsr	draw_terrain_chunk

			jmp	_nlc_level_complete

_nlc_post_draw		puls	y			; y = chunk just drawn
			leay	sizeof{LevelTerrainStruct},y ; move to next chunk
			ldx	_main_chunk_counter	; get and dec counter
			leax	-1,x
			stx	_main_chunk_counter
			cmpx	#0
			bne	_next_level_chunk
_nlc_level_complete
			lbsr	setup_interrupts	; Get things organised

			;ldx	_pc_start_loc		; offset to view
			ldx	#0
			
@_do_loop
			cwai	#$EF	
			pshs	x
			lbsr	copy_virt_to_phys	; render it to gfx
			puls	x
			;leax	2,x
			cmpx	#640
			blo	@_do_loop
@_do_other_loop
			cwai	#$EF	
			pshs	x
			lbsr	copy_virt_to_phys	; render it to gfx
			puls	x
			;leax	-2,x
			cmpx	#0
			bhi	@_do_other_loop
			jmp	@_do_loop

ENDLOOP			jmp	ENDLOOP
			ENDSECTION

			SECTION	.program_code_stack
Stack			EXPORT
			rmb 	255
Stack			EQU	*
			ENDSECTION
