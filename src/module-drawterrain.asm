;*** Terrain-drawing routines

			INCLUDE	"defines.asm"		; Coco hardware definitions

			SECTION .bss,bss
_ter_height_adjust	RMB	1
_ter_width		RMB	1
_ter_height		RMB	1
_ter_drw_lines_left	RMB	1
_ter_drw_counter	RMB	1
_ter_drw_y_loc		RMB	1
_ter_drw_x_loc		RMB	2
_ter_drw_ter_id		RMB	2
_ter_drw_mode		RMB	1
_ter_drw_nooverlap	RMB	1
			ENDSECTION

			SECTION	module_drawterrain
draw_terrain_chunk	EXPORT


;*** draw_terrain_chunk
;	Write terrain graphic data to the virtual screen
; ENTRY:	a = vertical offset (in pixels)
;		x = horizontal offset (in bytes)
;		y = terrain_id to be drawn
;		b = draw mode (bitmask)

draw_terrain_chunk
			stx	_ter_drw_x_loc		; save untouched original
			sta	_ter_drw_y_loc		; save untouched original
			sty	_ter_drw_ter_id		; save untouched original
			stb	_ter_drw_mode		; save untouched original
			clr	_ter_height_adjust	; start off with zero
			clr	_ter_drw_nooverlap	; start off with normal mode
			lda	#Block_TerrainData
			sta	Page_TerrainData
			lda	_ter_drw_y_loc
			andb	#1
			beq	_dtc_skip_nooverlap_store
			dec	_ter_drw_nooverlap	; should roll back to FF
_dtc_skip_nooverlap_store	
			; Adjust for top-crop
			cmpa	#$A0	; see if vertical offset is more than 159 - if so, it's negative
			blo	_dtc_skip_negative_adjustment ; if within range, skip all this
			nega				; this calculates how many rows to skip to get to 0
			sta	_ter_height_adjust	; use this to know how many to skip
			clr	_ter_drw_y_loc		; draw at row zero
_dtc_skip_negative_adjustment
			; Adjust for bottom-crop
			; Adjust for left-crop
			; Adjust for right-crop

			;** Calculate start of terrain data
			ldd	_ter_drw_ter_id		; A = 0, B = ID
			ldx	#TerrainOffsetTable
			abx
			abx
			abx
			abx
			; X now points to TerrainStruct block for ter_id

			;** Get data from TerrainStruct at X
			ldu	TerrainStruct.DataPointer,X	; U = ter_data
			ldd	TerrainStruct.Width,X	; A = Width, B = Height
			std	_ter_width	; save the width and height for loop u
			stb	_ter_drw_lines_left	; number of lines to be drawn
			; all terrain info is now in local vars


			;** Skip rows based upon _ter_height_adjust
			tst	_ter_height_adjust	; are there rows to skip?
			beq	_dtc_skip_height_adjust
			lda	_ter_width		; this many bytes per row to skip
			ldb	_ter_height_adjust	; b = counter
!			leau	a,u			; skip bytes as per width
			dec	_ter_drw_lines_left	; row not to be drawn later
			decb
			bne	<
_dtc_skip_height_adjust

			;** adjust u
			cmpu	#Window_TerrainData+$2000
			blo	_dtc_skip_adjust_src0
			tfr	u,d
			suba	#$20
			tfr	d,u
			inc	Page_TerrainData
			bra	_dtc_skip_height_adjust	; go again
_dtc_skip_adjust_src0
			;** Point X at destination (virtual screen)
_dtc_new_row		lda	_ter_drw_y_loc	; get y offset to draw at
			cmpa	#160		; see if we're within bounds
			blo	_dtc_continue	; skip the return if we're out-of-bounds
			rts
_dtc_continue		lbsr	get_addr_start_of_line ; convert a into d and remap
			ldx	_ter_drw_x_loc	; get x offset
			leax	d,x		; add vert and horizontal offsets
			; X now points to dest, U to src

_dtc_line_start		
			lda	_ter_width	; get number of bytes to write
			sta	_ter_drw_counter
_dtc_line_loop
			ldb	,u+		; get byte to write
			beq	_dtc_skip_write	; if it's empty, don't write it

			;** Check for no-overlap
			tst	_ter_drw_nooverlap ; are we in no-overlap mode?
			beq	_dtc_mask_ter	; nope, so skip this stuff
			lda	,x		; get bg pixel
			beq	_dtc_write	; no bg, so just write
			bita	#$0F		; check bg rhs contents
			beq	_dtc_mask_bg_0	; if empty, don't change ter byte
			andb	#$F0		; empty ter rhs
_dtc_mask_bg_0		bita	#$F0		; check bg lhs contents
			beq	_dtc_mask_ter	; if empty, don't change ter byte
			andb	#$0F		; empty ter lhs
_dtc_mask_ter		;** Mask terrain byte
			clra			; a = mask
			bitb	#$0F		; text right-hand pixel
			bne	_dtc_mask_ter_0	; has something to write, skip mask
			ora	#$0F		; rhs mask lets bg through
_dtc_mask_ter_0		bitb	#$F0		; text left-hand pixel
			bne	_dtc_mask_ter_1	; has something to write, skip mask
			ora	#$F0		; lhs mask lets bg through
_dtc_mask_ter_1		anda	,x		; merge mask with bg
			sta	,x		; write updated bg pixel
			orb	,x		; merge pixel with masked bg
_dtc_write		stb	,x+		; write updated bg pixel and move on
			bra	_dtc_done_writing
			; Done drawing, skip the skip
_dtc_skip_write
			leax	1,x		; don't write anything
_dtc_done_writing	dec	_ter_drw_counter ; dec number of bytes left to write
			bne	_dtc_line_loop	; more to write? go back
			inc	_ter_drw_y_loc	; next line
			;** adjust u
_dtc_adjust_u		cmpu	#Window_TerrainData+$2000
			blo	_dtc_skip_adjust_src
			tfr	u,d
			suba	#$20
			tfr	d,u
			inc	Page_TerrainData
			bra	_dtc_adjust_u
_dtc_skip_adjust_src
			dec	_ter_drw_lines_left ; more lines to go?
			bne	_dtc_new_row	; go and do it again
			rts
			ENDSECTION
