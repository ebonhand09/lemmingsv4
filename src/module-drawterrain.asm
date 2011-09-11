;*** Terrain-drawing routines

			INCLUDE	"defines.asm"		; Coco hardware definitions

			SECTION .bss,bss
_ter_id			RMB	2
_ter_offset		RMB	2
_ter_width		RMB	1
_ter_height		RMB	1
_ter_drw_lines_left	RMB	1
_ter_drw_counter	RMB	1
_ter_drw_y_loc		RMB	1
_ter_drw_y_skip_top	RMB	1
_ter_drw_y_skip_bottom	RMB	1
_ter_drw_x_loc		RMB	2
_ter_drw_x_skip_left	RMB	1
_ter_drw_x_skip_right	RMB	1
_ter_drw_mode		RMB	1
_ter_drw_nooverlap	RMB	1
_ter_drw_upsidedown	RMB	1
_ter_drw_black		RMB	1
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
			stx	_ter_drw_x_loc		; save passed x location
			sta	_ter_drw_y_loc		; save passed y location
			sty	_ter_id			; save passed terrain id
			stb	_ter_drw_mode		; save passed draw mode

			;** Clear local variables
			clr	_ter_drw_y_skip_top	; reset height adjustment
			clr	_ter_drw_y_skip_bottom
			clr	_ter_drw_x_skip_left
			clr	_ter_drw_x_skip_right
			clr	_ter_drw_nooverlap	; reset nooverlap flag
			clr	_ter_drw_upsidedown	; reset upsidedown flag
			clr	_ter_drw_black		; reset black flag


			;** Reset TerrainData mapping
			lda	#Block_TerrainData
			sta	Page_TerrainData

			;** Put draw mode flags into local variables
			lbsr	dtc_set_draw_mode_flags

			;** Put Terrain Data into local variables
			lbsr	dtc_get_terrain_data

			;** Adjust for top-crop
			lbsr	dtc_adjust_top_crop

			;** Adjust for left-crop
			lbsr	dtc_adjust_left_crop

			;** Adjust for right-crop
			lbsr	dtc_adjust_right_crop

			;** Adjust for bottom-crop
			lbsr	dtc_adjust_bottom_crop

			;** Early Bail Conditions
			; If X location is more than 768, bail early
			ldx	_ter_drw_x_loc
			cmpx	#768
			blt	__dtc_post_early_bail_0
			rts
__dtc_post_early_bail_0
			; If chunk is entirely above virtual screen, bail early
			lda	_ter_height
			cmpa	_ter_drw_y_skip_top
			bge	__dtc_post_early_bail_1
			rts
__dtc_post_early_bail_1
			; If chunk is entirely below virtual screen, bail early
			cmpa	_ter_drw_y_skip_bottom
			bge	__dtc_post_early_bail_2
			rts
__dtc_post_early_bail_2
			; If chunk is entirely to the left of virtual screen, bail early
			lda	_ter_width
			cmpa	_ter_drw_x_skip_left
			bge	__dtc_post_early_bail_3
			rts
__dtc_post_early_bail_3
				

			;** If we're in normal draw mode, go draw and go home
			tst	_ter_drw_mode
			bne	__dtc_post_normal_mode_check
			lbsr	dtc_execute_normal_mode
			rts
__dtc_post_normal_mode_check

			;** Check for nooverlap/upsidedown combined
			lda	_ter_drw_mode
			cmpa	#3			; Check for combined nooverlap/upsidedown modes
			bne	__dtc_post_combined_nooverlap_upsidedown_mode
			;lbsr	dtc_execute_combined_nooverlap_upsidedown_mode
			rts
__dtc_post_combined_nooverlap_upsidedown_mode

			;** Check for upsidedown/black combined
			lda	_ter_drw_mode
			cmpa	#6			; Check for combined upsidedown/black modes
			bne	__dtc_post_combined_upsidedown_black_mode
			;lbsr	dtc_execute_combined_upsidedown_black_mode
			rts
__dtc_post_combined_upsidedown_black_mode

			;** Check for nooverlap draw mode
			lda	_ter_drw_mode
			cmpa	#1			; Check for nooverlap mode
			bne	__dtc_post_nooverlap_mode_check
			lbsr	dtc_execute_nooverlap_mode
			rts
__dtc_post_nooverlap_mode_check

			;** Check for upsidedown draw mode
			lda	_ter_drw_mode
			cmpa	#2			; Check for upsidedown mode
			bne	__dtc_post_upsidedown_mode_check
			;lbsr	dtc_execute_upsidedown_mode
			rts
__dtc_post_upsidedown_mode_check
			
			;** Check for black draw mode
			lda	_ter_drw_mode
			cmpa	#4			; Check for black mode
			bne	__dtc_post_black_mode_check
			;lbsr	dtc_execute_black_mode
			rts
__dtc_post_black_mode_check

			rts				; Fallthrough safety

;** dtc_execute_normal_mode
; This subroutine handles drawing a terrain chunk with no special mode considerations
; e.g no masking of any kind. It still makes use of postional adjustments such as
; top-cropping, left-cropping, right-cropping and bottom-cropping
dtc_execute_normal_mode
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data
			lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_exnorm_new_row
			;** Remap destination pages
			lda	_ter_drw_y_loc		; y pos to draw at
			lbsr	get_addr_start_of_line	; convert a into d and remap

			ldx	_ter_drw_x_loc		; get x offset
			leax	d,x			; add vert and horiz offsets
			;** X now = Destination Byte

			lda	_ter_drw_x_skip_left
			leau	a,u			; push src forward if needed

			;** Remap source pages
			lbsr	dtc_adjust_src_fwd	; ensure u is mapped

			;** Final preparations
			lda	_ter_drw_counter	; number of bytes to draw
__dtc_exnorm_draw_line
			ldb	,u+			; load source byte
			beq	__dtc_exnorm_dl_0	; don't write if zero
			pshs	a			; save the byte count

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_exnorm_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_exnorm_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_exnorm_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_exnorm_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
			stb	,x			; write merged pixel
			puls	a
__dtc_exnorm_dl_0
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_exnorm_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			dec	_ter_drw_lines_left
			bne	__dtc_exnorm_new_row

			rts
;** end dtc_execute_normal_mode

;** dtc_execute_nooverlap_mode
; This subroutine handles drawing a terrain chunk with nooverlap special mode
; If the destination half-byte is zero, the half-byte from src will be written
dtc_execute_nooverlap_mode
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data
			lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_exnoov_new_row
			;** Remap destination pages
			lda	_ter_drw_y_loc		; y pos to draw at
			lbsr	get_addr_start_of_line	; convert a into d and remap

			ldx	_ter_drw_x_loc		; get x offset
			leax	d,x			; add vert and horiz offsets
			;** X now = Destination Byte

			lda	_ter_drw_x_skip_left
			leau	a,u			; push src forward if needed

			;** Remap source pages
			lbsr	dtc_adjust_src_fwd	; ensure u is mapped

			;** Final preparations
			lda	_ter_drw_counter	; number of bytes to draw
__dtc_exnoov_draw_line
			ldb	,u+			; load source byte
			beq	__dtc_exnoov_dl_0	; don't write if zero
			pshs	a			; save the byte count

			;** Check Destination byte, and mask as appropriate
			lda	,x			; get background byte
			beq	__dtc_exnoov_write_byte	; if background empty, just write
			bita	#$0F			; check bg rhs pixel
			beq	__dtc_exnoov_post_bg_right_pixel	; empty = no change
			andb	#$F0			; clear rhs pixel
__dtc_exnoov_post_bg_right_pixel
			bita	#$F0			; check bg lhs pixel
			beq	__dtc_exnoov_post_bg_left_pixel		; empty = no change
			andb	#$0F			; clear lhs pixel
__dtc_exnoov_post_bg_left_pixel
			
			;** Mask terrain byte
			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_exnoov_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_exnoov_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_exnoov_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_exnoov_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
__dtc_exnoov_write_byte
			stb	,x			; write merged pixel
			puls	a
__dtc_exnoov_dl_0
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_exnoov_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			dec	_ter_drw_lines_left
			bne	__dtc_exnoov_new_row

			rts
;** end dtc_execute_nooverlap_mode

;** dtc_adjust_src_fwd
; This subroutine checks if the current source pointer is within the
; #Window_TerrainData page, and if not, it remaps and adjusts appropriately
dtc_adjust_src_fwd
			pshs	d
__dtc_asf_0
			cmpu	#Window_TerrainData+$2000
			blo	__dtc_asf_1
			leau	-$2000,u
			inc	Page_TerrainData
			bra	__dtc_asf_0

__dtc_asf_1
			puls	d
			rts
;** end dtc_adjust_src_fwd

;** dtc_skip_top_crop_lines
; This subroutine skips over unneeded src bytes as specified by _ter_drw_y_skip_top
; U must already point at src data
dtc_skip_top_crop_lines
			tst	_ter_drw_y_skip_top
			beq	__dtc_stcl_0
			pshs	d
			lda	_ter_width		; skip this many bytes
			ldb	_ter_drw_y_skip_top	; .. this many times
			mul				; total skip in d
			leau	d,u			; skip bytes
			puls	d
__dtc_stcl_0
			rts
;** end dtc_skip_top_crop_lines

;** dtc_get_terrain_data
; This subroutine uses the Terrain Offset Table to calculate the offset of
; the terrain data, and puts all data into local variables
dtc_get_terrain_data
			pshs	d,x
			ldd	_ter_id		; a = 0, b = terrain id
			ldx	#TerrainOffsetTable
			abx
			abx
			abx
			abx
			ldd	TerrainStruct.DataPointer,X
			std	_ter_offset
			ldd	TerrainStruct.Width,X	; a = width, b = height
			std	_ter_width		; this writes height too!
			stb	_ter_drw_lines_left	; number of lines to be drawn
			puls	d,x
			rts
;** end dtc_get_start_of_terrain_data

;** dtc_adjust_top_crop
; This subroutine checks the requested y draw location
; If it's more than 159, it treats the location as negative, sets the y draw loc to zero
; and prepares _ter_drw_y_skip_top for skipping appropriate lines later
dtc_adjust_top_crop
			pshs	a
			lda	_ter_drw_y_loc
			cmpa	#$A0			; Test against 160
			blo	__dtc_atc_0		; bail if less
			nega				; invert it (turn it negative)
			sta	_ter_drw_y_skip_top	; store for later
			clr	_ter_drw_y_loc		; reset to drawing at zero
__dtc_atc_0
			puls	a
			rts
;** end dtc_adjust_top_crop

;** dtc_adjust_left_crop
; This subroutine checks the requested x draw location
; If it's negative, it calculates how many bytes to skip at the beginning of
; each line drawn, and resets the draw x location to zero
dtc_adjust_left_crop
			pshs	d
			ldd	_ter_drw_x_loc
			cmpx	#0			; Test against 0
			bge	__dtc_alc_0		; bail if 0 or more
			negb				; invert it (turn it negative)
			stb	_ter_drw_x_skip_left	; save for later
			ldx	#0
			stx	_ter_drw_x_loc		; reset draw location to zero
__dtc_alc_0
			puls	d
			rts
;** end dtc_adjust_left_crop

;** dtc_adjust_right_crop
; This subroutine checks the requested x draw location and the width of the chunk
; If bytes would be written past the right-most edge of the virtual screen,
; appropriate bytes are calculated to allow the draw routine to skip them
; x_loc should have already been checked to see if it's past the edge on it's own
dtc_adjust_right_crop
			pshs	d,x
			ldx	_ter_drw_x_loc		; get requested draw location
			ldb	_ter_width		; get width of chunk
			abx				; x = final byte location
			tfr	x,d
			subd	#768			; compare against edge
			blt	__dtc_arc_0		; if less/eq, no skip needed
			stb	_ter_drw_x_skip_right	; skip this many bytes to the right
__dtc_arc_0
			puls	d,x
			rts
;** end dtc_adjust_right_crop

;** dtc_adjust_bottom_crop
; This subroutine checks the requested y draw location and the height of the chunk
; If the chunk would be drawn past line 160, the additional lines are artificially
; skipped
dtc_adjust_bottom_crop
			pshs	d,x
			clra
			ldb	_ter_drw_y_loc		
			tfr	d,x			; get y location into x
			ldb	_ter_height
			abx				; add chunk height
			cmpx	#160			; test against 160
			blt	__dtc_abc_0		; if less, no adjust needed
			tfr	x,d
			subb	#160			; 
			stb	_ter_drw_y_skip_bottom	; skip this many lines at bottom
__dtc_abc_0
			puls	d,x
			rts
;** end dtc_adjust_bottom_crop

;** dtc_set_draw_mode_flags
; This subroutine sets the draw mode flags based upon the draw mode byte passed
; to the parent routine
dtc_set_draw_mode_flags
			pshs	b
			ldb	_ter_drw_mode
			bitb	#1			; Check for nooverlap
			beq	__dtc_sdmf_0
			dec	_ter_drw_nooverlap
__dtc_sdmf_0
			bitb	#2			; Check for upsidedown
			beq	__dtc_sdmf_1
			dec	_ter_drw_upsidedown
__dtc_sdmf_1
			bitb	#4			; Check for black
			beq	__dtc_sdmf_2
			dec	_ter_drw_black
__dtc_sdmf_2
			puls	b
			rts
;** end dtc_set_draw_mode_flags

			ENDSECTION
