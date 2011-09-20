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
_ter_drw_x_pixel_offset	RMB	1
_ter_drw_mode		RMB	1
_ter_drw_tmp		RMB	1
			ENDSECTION

			SECTION	module_drawterrain
draw_terrain_chunk	EXPORT

;*** draw_terrain_chunk
;	Write terrain graphic data to the virtual screen
; ENTRY:	a = vertical offset (in pixels)
;		x = horizontal offset (in pixels)
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
			clr	_ter_drw_x_pixel_offset

			;** Reset TerrainData mapping
			lda	#Block_TerrainData
			sta	Page_TerrainData

			;** Adjust X location from pixels to bytes
			; and calculate even/odd
_dtc_test_point		lbsr	dtc_adjust_pixels_to_bytes

			;** From this point forward, all horizontals are in bytes

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

			;** Check if we're doing the normal or offset draw
			
			tst	_ter_drw_x_pixel_offset
			bne	__dtc_offset_modes

			;** If we're in normal draw mode, go draw and go home
			tst	_ter_drw_mode
			bne	__dtc_post_normal_mode_check
			lbsr	dtc_execute_normal_mode
			rts
__dtc_post_normal_mode_check

			;** Check for upsidedown/nooverlap combined
			lda	_ter_drw_mode
			cmpa	#DRAW_UPSIDEDOWN|DRAW_NOOVERLAP	; Check for combined nooverlap/upsidedown modes
			bne	__dtc_post_combined_upsidedown_nooverlap_mode
			lbsr	dtc_execute_combined_upsidedown_nooverlap_mode
			;lbsr	dtc_execute_upsidedown_mode
			rts
__dtc_post_combined_upsidedown_nooverlap_mode

			;** Check for upsidedown/black combined
			lda	_ter_drw_mode
			cmpa	#DRAW_UPSIDEDOWN|DRAW_BLACK	; Check for combined upsidedown/black modes
			bne	__dtc_post_combined_upsidedown_black_mode
			lbsr	dtc_execute_combined_upsidedown_black_mode
			rts
__dtc_post_combined_upsidedown_black_mode

			;** Check for nooverlap draw mode
			lda	_ter_drw_mode
			cmpa	#DRAW_NOOVERLAP		; Check for nooverlap mode
			bne	__dtc_post_nooverlap_mode_check
			lbsr	dtc_execute_nooverlap_mode
			rts
__dtc_post_nooverlap_mode_check

			;** Check for upsidedown draw mode
			lda	_ter_drw_mode
			cmpa	#DRAW_UPSIDEDOWN	; Check for upsidedown mode
			bne	__dtc_post_upsidedown_mode_check
			lbsr	dtc_execute_upsidedown_mode
			rts
__dtc_post_upsidedown_mode_check
			
			;** Check for black draw mode
			lda	_ter_drw_mode
			cmpa	#DRAW_BLACK		; Check for black mode
			bne	__dtc_post_black_mode_check
			lbsr	dtc_execute_black_mode
			rts
__dtc_post_black_mode_check

			rts				; Fallthrough safety
;** END NORMAL MODES
;** START OFFSET MODES
__dtc_offset_modes

			;** If we're in normal draw mode, go draw and go home
			tst	_ter_drw_mode
			bne	__dtc_post_offset_normal_mode_check
			lbsr	dtc_execute_offset_normal_mode
			rts
__dtc_post_offset_normal_mode_check

			;** Check for upsidedown/nooverlap combined
			lda	_ter_drw_mode
			cmpa	#DRAW_UPSIDEDOWN|DRAW_NOOVERLAP	; Check for combined nooverlap/upsidedown modes
			bne	__dtc_post_offset_combined_upsidedown_nooverlap_mode
			lbsr	dtc_execute_offset_combined_upsidedown_nooverlap_mode
			;lbsr	dtc_execute_offset_upsidedown_mode
			rts
__dtc_post_offset_combined_upsidedown_nooverlap_mode

			;** Check for upsidedown/black combined
			lda	_ter_drw_mode
			cmpa	#DRAW_UPSIDEDOWN|DRAW_BLACK	; Check for combined upsidedown/black modes
			bne	__dtc_post_offset_combined_upsidedown_black_mode
			lbsr	dtc_execute_offset_combined_upsidedown_black_mode
			rts
__dtc_post_offset_combined_upsidedown_black_mode

			;** Check for nooverlap draw mode
			lda	_ter_drw_mode
			cmpa	#DRAW_NOOVERLAP		; Check for nooverlap mode
			bne	__dtc_post_offset_nooverlap_mode_check
			lbsr	dtc_execute_offset_nooverlap_mode
			rts
__dtc_post_offset_nooverlap_mode_check

			;** Check for upsidedown draw mode
			lda	_ter_drw_mode
			cmpa	#DRAW_UPSIDEDOWN	; Check for upsidedown mode
			bne	__dtc_post_offset_upsidedown_mode_check
			lbsr	dtc_execute_offset_upsidedown_mode
			rts
__dtc_post_offset_upsidedown_mode_check
			
			;** Check for black draw mode
			lda	_ter_drw_mode
			cmpa	#DRAW_BLACK		; Check for black mode
			bne	__dtc_post_offset_black_mode_check
			lbsr	dtc_execute_offset_black_mode
			rts
__dtc_post_offset_black_mode_check

			rts				; Fallthrough safety
;** END OFFSET MODES
;** end draw_terrain_chunk

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

;** dtc_execute_offset_normal_mode
; OFFSET VARIETY
; This subroutine handles drawing a terrain chunk with no special mode considerations
; e.g no masking of any kind. It still makes use of postional adjustments such as
; top-cropping, left-cropping, right-cropping and bottom-cropping
dtc_execute_offset_normal_mode
			dec	_ter_drw_x_skip_left	; OFFSET - Draw one extra byte per line
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
__dtc_oexnorm_new_row
			clr	_ter_drw_tmp
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
__dtc_oexnorm_draw_line
			pshs	a			; save the byte count
			ldd	,u+			; load source bytes
			tst	_ter_drw_tmp
			bne	__dtc_oexnorm_dl_skip_first_byte_adjust
			clra
			dec	_ter_drw_tmp
__dtc_oexnorm_dl_skip_first_byte_adjust
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb

			lda	,s
			deca
			bne	__dtc_oexnorm_dl_skip_last_byte_adjust
			andb	#$F0
__dtc_oexnorm_dl_skip_last_byte_adjust
			tstb
			beq	__dtc_oexnorm_dl_0	; don't write if zero

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_oexnorm_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_oexnorm_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_oexnorm_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_oexnorm_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
			stb	,x			; write merged pixel
__dtc_oexnorm_dl_0
			puls	a
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_oexnorm_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			dec	_ter_drw_lines_left
			bne	__dtc_oexnorm_new_row

			rts
;** end dtc_execute_offset_normal_mode

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

;** dtc_execute_offset_nooverlap_mode
; OFFSET VARIETY
; This subroutine handles drawing a terrain chunk with nooverlap special mode
; If the destination half-byte is zero, the half-byte from src will be written
dtc_execute_offset_nooverlap_mode
			dec	_ter_drw_x_skip_left	; OFFSET - Draw one extra byte per line
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
__dtc_oexnoov_new_row
			clr	_ter_drw_tmp
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
__dtc_oexnoov_draw_line
			pshs	a			; save the byte count
			ldd	,u+			; load source bytes
			tst	_ter_drw_tmp
			bne	__dtc_oexnoov_dl_skip_first_byte_adjust
			clra
			dec	_ter_drw_tmp
__dtc_oexnoov_dl_skip_first_byte_adjust
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb

			lda	,s
			deca
			bne	__dtc_oexnoov_dl_skip_last_byte_adjust
			andb	#$F0
__dtc_oexnoov_dl_skip_last_byte_adjust
			tstb				; load source byte
			beq	__dtc_oexnoov_dl_0	; don't write if zero

			;** Check Destination byte, and mask as appropriate
			lda	,x			; get background byte
			beq	__dtc_oexnoov_write_byte	; if background empty, just write
			bita	#$0F			; check bg rhs pixel
			beq	__dtc_oexnoov_post_bg_right_pixel	; empty = no change
			andb	#$F0			; clear rhs pixel
__dtc_oexnoov_post_bg_right_pixel
			bita	#$F0			; check bg lhs pixel
			beq	__dtc_oexnoov_post_bg_left_pixel		; empty = no change
			andb	#$0F			; clear lhs pixel
__dtc_oexnoov_post_bg_left_pixel
			
			;** Mask terrain byte
			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_oexnoov_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_oexnoov_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_oexnoov_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_oexnoov_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
__dtc_oexnoov_write_byte
			stb	,x			; write merged pixel
__dtc_oexnoov_dl_0
			puls	a
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_oexnoov_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			dec	_ter_drw_lines_left
			bne	__dtc_oexnoov_new_row

			rts
;** end dtc_execute_offset_nooverlap_mode

;** dtc_execute_upsidedown_mode
; This subroutine handles drawing a terrain chunk with upsidedown special flag
; It reads the src data in byte order but in a line-reversed manner e.g last line will be served
; first. In all other respects, this routine is the same as dtc_execute_normal_mode
dtc_execute_upsidedown_mode
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data

			;** Set u to point at last line of src data
			lda	_ter_height
			suba	_ter_drw_y_skip_top	; we're skipping this many lines, so dont
							; include them in the fast-forward
			deca				; want to go to start of last line, not
							; past last byte - so, mul with one line less
			ldb	_ter_width
			mul				; d = total bytes to skip
			leau	d,u			; u points at first byte of last line

			;lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_exusd_new_row
			;** Remap destination pages
			lda	_ter_drw_y_loc		; y pos to draw at
			lbsr	get_addr_start_of_line	; convert a into d and remap

			ldx	_ter_drw_x_loc		; get x offset
			leax	d,x			; add vert and horiz offsets
			;** X now = Destination Byte

			lda	_ter_drw_x_skip_left
			leau	a,u			; push src forward if needed

			;** Remap source pages
			lbsr	dtc_adjust_src_both	; ensure u is mapped

			;** Final preparations
			lda	_ter_drw_counter	; number of bytes to draw
__dtc_exusd_draw_line
			ldb	,u+			; load source byte
			beq	__dtc_exusd_dl_0	; don't write if zero
			pshs	a			; save the byte count

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_exusd_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_exusd_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_exusd_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_exusd_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
			stb	,x			; write merged pixel
			puls	a
__dtc_exusd_dl_0
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_both	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_exusd_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			
			lda	_ter_width
			lsla				; multiply reverse skip by two
							; so we're doing two lines back
							; (just drawn line, plus next line to draw)
			nega				; make it negative
			leau	a,u			; move src pointer

			dec	_ter_drw_lines_left
			bne	__dtc_exusd_new_row

			rts
;** end dtc_execute_upsidedown_mode

;** dtc_execute_offset_upsidedown_mode
; OFFSET VARIETY
; This subroutine handles drawing a terrain chunk with upsidedown special flag
; It reads the src data in byte order but in a line-reversed manner e.g last line will be served
; first. In all other respects, this routine is the same as dtc_execute_normal_mode
dtc_execute_offset_upsidedown_mode
			dec	_ter_drw_x_skip_left	; OFFSET MODE
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data

			;** Set u to point at last line of src data
			lda	_ter_height
			suba	_ter_drw_y_skip_top	; we're skipping this many lines, so dont
							; include them in the fast-forward
			deca				; want to go to start of last line, not
							; past last byte - so, mul with one line less
			ldb	_ter_width
			mul				; d = total bytes to skip
			leau	d,u			; u points at first byte of last line

			;lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_oexusd_new_row
			clr	_ter_drw_tmp
			;** Remap destination pages
			lda	_ter_drw_y_loc		; y pos to draw at
			lbsr	get_addr_start_of_line	; convert a into d and remap

			ldx	_ter_drw_x_loc		; get x offset
			leax	d,x			; add vert and horiz offsets
			;** X now = Destination Byte

			lda	_ter_drw_x_skip_left
			leau	a,u			; push src forward if needed

			;** Remap source pages
			lbsr	dtc_adjust_src_both	; ensure u is mapped

			;** Final preparations
			lda	_ter_drw_counter	; number of bytes to draw
__dtc_oexusd_draw_line
			pshs	a			; save the byte count
			ldd	,u+			; load source byte
			tst	_ter_drw_tmp
			bne	__dtc_oexusd_dl_skip_first_byte_adjust
			clra
			dec	_ter_drw_tmp
__dtc_oexusd_dl_skip_first_byte_adjust
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb

			lda	,s
			deca
			bne	__dtc_oexusd_dl_skip_last_byte_adjust
			andb	#$F0
__dtc_oexusd_dl_skip_last_byte_adjust
			tstb
			beq	__dtc_oexusd_dl_0	; don't write if zero

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_oexusd_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_oexusd_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_oexusd_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_oexusd_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
			stb	,x			; write merged pixel
__dtc_oexusd_dl_0
			puls	a
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_both	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_oexusd_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			
			lda	_ter_width
			lsla				; multiply reverse skip by two
							; so we're doing two lines back
							; (just drawn line, plus next line to draw)
			nega				; make it negative
			leau	a,u			; move src pointer

			dec	_ter_drw_lines_left
			bne	__dtc_oexusd_new_row

			rts
;** end dtc_execute_offset_upsidedown_mode

;** dtc_execute_black_mode
; This subroutine handles drawing a terrain chunk in black draw mode
; It's a variant of dtc_execute_normal_mode that doesn't merge in the terrain chunk data, but only
; applies the background mask. This could probably be improved speed-wise
dtc_execute_black_mode
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
__dtc_exblk_new_row
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
__dtc_exblk_draw_line
			ldb	,u+			; load source byte
			beq	__dtc_exblk_dl_0	; don't write if zero
			pshs	a			; save the byte count

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_exblk_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_exblk_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_exblk_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_exblk_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			puls	a
__dtc_exblk_dl_0
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_exblk_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			dec	_ter_drw_lines_left
			bne	__dtc_exblk_new_row

			rts
;** end dtc_execute_black_mode

;** dtc_execute_offset_black_mode
; OFFSET VARIETY
; This subroutine handles drawing a terrain chunk in black draw mode
; It's a variant of dtc_execute_normal_mode that doesn't merge in the terrain chunk data, but only
; applies the background mask. This could probably be improved speed-wise
dtc_execute_offset_black_mode
			dec	_ter_drw_x_skip_left	; OFFSET Mode
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
__dtc_oexblk_new_row
			clr	_ter_drw_tmp
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
__dtc_oexblk_draw_line
			pshs	a
			ldd	,u+			; load source byte
			tst	_ter_drw_tmp
			bne	__dtc_oexblk_dl_skip_first_byte_adjust
			clra
			dec	_ter_drw_tmp
__dtc_oexblk_dl_skip_first_byte_adjust
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb

			lda	,s
			deca
			bne	__dtc_oexblk_dl_skip_last_byte_adjust
			andb	#$F0
__dtc_oexblk_dl_skip_last_byte_adjust
			tstb
			beq	__dtc_oexblk_dl_0	; don't write if zero

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_oexblk_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_oexblk_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_oexblk_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_oexblk_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
__dtc_oexblk_dl_0
			puls	a
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_oexblk_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			dec	_ter_drw_lines_left
			bne	__dtc_oexblk_new_row

			rts
;** end dtc_execute_offset_black_mode

;** dtc_execute_combined_upsidedown_nooverlap_mode
; This subroutine handles drawing a terrain chunk with upsidedown and nooverlap special modes
; If the destination half-byte is zero, the half-byte from src will be written
dtc_execute_combined_upsidedown_nooverlap_mode
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data

			;** Set u to point at last line of src data
			lda	_ter_height
			suba	_ter_drw_y_skip_top	; we're skipping this many lines, so
							; don't include them in the fast-forward
			deca				; move to start of last line, not past it

			ldb	_ter_width
			mul				; d = total bytes to skip
			leau	d,u			; u points to first byte of last line


			;lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_excusdnoov_new_row
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
__dtc_excusdnoov_draw_line
			ldb	,u+			; load source byte
			beq	__dtc_excusdnoov_dl_0	; don't write if zero
			pshs	a			; save the byte count

			;** Check Destination byte, and mask as appropriate
			lda	,x			; get background byte
			beq	__dtc_excusdnoov_write_byte	; if background empty, just write
			bita	#$0F			; check bg rhs pixel
			beq	__dtc_excusdnoov_post_bg_right_pixel	; empty = no change
			andb	#$F0			; clear rhs pixel
__dtc_excusdnoov_post_bg_right_pixel
			bita	#$F0			; check bg lhs pixel
			beq	__dtc_excusdnoov_post_bg_left_pixel		; empty = no change
			andb	#$0F			; clear lhs pixel
__dtc_excusdnoov_post_bg_left_pixel
			
			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_excusdnoov_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_excusdnoov_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_excusdnoov_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_excusdnoov_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
__dtc_excusdnoov_write_byte
			stb	,x			; write merged pixel
			puls	a
__dtc_excusdnoov_dl_0
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_excusdnoov_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	

			lda	_ter_width
			lsla				; multiply reverse skip by two
							; so we're moving back two lines
							; (just drawn line, plus next line to draw)
			nega				; make it negative
			leau	a,u			; move src pointer

			dec	_ter_drw_lines_left
			bne	__dtc_excusdnoov_new_row

			rts
;** end dtc_execute_combined_upsidedown_nooverlap_mode

;** dtc_execute_offset_combined_upsidedown_nooverlap_mode
; OFFSET VARIETY
; This subroutine handles drawing a terrain chunk with upsidedown and nooverlap special modes
; If the destination half-byte is zero, the half-byte from src will be written
dtc_execute_offset_combined_upsidedown_nooverlap_mode
			dec	_ter_drw_x_skip_left	; OFFSET MODE
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data

			;** Set u to point at last line of src data
			lda	_ter_height
			suba	_ter_drw_y_skip_top	; we're skipping this many lines, so
							; don't include them in the fast-forward
			deca				; move to start of last line, not past it

			ldb	_ter_width
			mul				; d = total bytes to skip
			leau	d,u			; u points to first byte of last line


			;lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_oexcusdnoov_new_row
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
__dtc_oexcusdnoov_draw_line
			pshs	a			; save the byte count
			ldd	,u+			; get source byte and shifties
			tst	_ter_drw_tmp
			bne	__dtc_oexcusdnoov_dl_skip_first_byte_adjust
			clra
			dec	_ter_drw_tmp
__dtc_oexcusdnoov_dl_skip_first_byte_adjust
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb

			lda	,s
			deca
			bne	__dtc_oexcusdnoov_dl_skip_last_byte_adjust
			andb	#$F0
__dtc_oexcusdnoov_dl_skip_last_byte_adjust
			tstb
			beq	__dtc_oexcusdnoov_dl_0	; don't write if zero

			;** Check Destination byte, and mask as appropriate
			lda	,x			; get background byte
			beq	__dtc_oexcusdnoov_write_byte	; if background empty, just write
			bita	#$0F			; check bg rhs pixel
			beq	__dtc_oexcusdnoov_post_bg_right_pixel	; empty = no change
			andb	#$F0			; clear rhs pixel
__dtc_oexcusdnoov_post_bg_right_pixel
			bita	#$F0			; check bg lhs pixel
			beq	__dtc_oexcusdnoov_post_bg_left_pixel		; empty = no change
			andb	#$0F			; clear lhs pixel
__dtc_oexcusdnoov_post_bg_left_pixel
			
			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_oexcusdnoov_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_oexcusdnoov_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_oexcusdnoov_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_oexcusdnoov_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			orb	,x			; merge pixel with masked bg
__dtc_oexcusdnoov_write_byte
			stb	,x			; write merged pixel
__dtc_oexcusdnoov_dl_0
			puls	a
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_fwd	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_oexcusdnoov_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	

			lda	_ter_width
			lsla				; multiply reverse skip by two
							; so we're moving back two lines
							; (just drawn line, plus next line to draw)
			nega				; make it negative
			leau	a,u			; move src pointer

			dec	_ter_drw_lines_left
			bne	__dtc_oexcusdnoov_new_row

			rts
;** end dtc_execute_combined_upsidedown_nooverlap_mode

;** dtc_execute_combined_upsidedown_black_mode
; This subroutine handles drawing a terrain chunk with upsidedown special flag
; It reads the src data in byte order but in a line-reversed manner e.g last line will be served
; first. In all other respects, this routine is the same as dtc_execute_normal_mode
dtc_execute_combined_upsidedown_black_mode
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data

			;** Set u to point at last line of src data
			lda	_ter_height
			suba	_ter_drw_y_skip_top	; we're skipping this many lines, so dont
							; include them in the fast-forward
			deca				; want to go to start of last line, not
							; past last byte - so, mul with one line less
			ldb	_ter_width
			mul				; d = total bytes to skip
			leau	d,u			; u points at first byte of last line

			;lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_excusblk_new_row
			;** Remap destination pages
			lda	_ter_drw_y_loc		; y pos to draw at
			lbsr	get_addr_start_of_line	; convert a into d and remap

			ldx	_ter_drw_x_loc		; get x offset
			leax	d,x			; add vert and horiz offsets
			;** X now = Destination Byte

			lda	_ter_drw_x_skip_left
			leau	a,u			; push src forward if needed

			;** Remap source pages
			lbsr	dtc_adjust_src_both	; ensure u is mapped

			;** Final preparations
			lda	_ter_drw_counter	; number of bytes to draw
__dtc_excusblk_draw_line
			ldb	,u+			; load source byte
			beq	__dtc_excusblk_dl_0	; don't write if zero
			pshs	a			; save the byte count

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_excusblk_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_excusblk_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_excusblk_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_excusblk_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			;orb	,x			; merge pixel with masked bg
			;stb	,x			; write merged pixel
			puls	a
__dtc_excusblk_dl_0
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_both	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_excusblk_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			
			lda	_ter_width
			lsla				; multiply reverse skip by two
							; so we're doing two lines back
							; (just drawn line, plus next line to draw)
			nega				; make it negative
			leau	a,u			; move src pointer

			dec	_ter_drw_lines_left
			bne	__dtc_excusblk_new_row

			rts
;** end dtc_execute_combined_upsidedown_black_mode

;** dtc_execute_offset_combined_upsidedown_black_mode
; OFFSET VARIETY
; This subroutine handles drawing a terrain chunk with upsidedown special flag
; It reads the src data in byte order but in a line-reversed manner e.g last line will be served
; first. In all other respects, this routine is the same as dtc_execute_normal_mode
dtc_execute_offset_combined_upsidedown_black_mode
			dec	_ter_drw_x_skip_left	; OFFSET MODE
			lda	_ter_width		; number of bytes to draw
			suba	_ter_drw_x_skip_left	; skip bytes to the left
			suba	_ter_drw_x_skip_right	; skip bytes to the right
			sta	_ter_drw_counter	; draw this many bytes per line

			lda	_ter_drw_lines_left	; number of lines to draw
			suba	_ter_drw_y_skip_top	; skip lines to the top
			suba	_ter_drw_y_skip_bottom	; skip lines to the bottom
			sta	_ter_drw_lines_left

			ldu	_ter_offset		; point u at data

			;** Set u to point at last line of src data
			lda	_ter_height
			suba	_ter_drw_y_skip_top	; we're skipping this many lines, so dont
							; include them in the fast-forward
			deca				; want to go to start of last line, not
							; past last byte - so, mul with one line less
			ldb	_ter_width
			mul				; d = total bytes to skip
			leau	d,u			; u points at first byte of last line

			;lbsr	dtc_skip_top_crop_lines	; adjust src as needed
__dtc_oexcusblk_new_row
			clr	_ter_drw_tmp
			;** Remap destination pages
			lda	_ter_drw_y_loc		; y pos to draw at
			lbsr	get_addr_start_of_line	; convert a into d and remap

			ldx	_ter_drw_x_loc		; get x offset
			leax	d,x			; add vert and horiz offsets
			;** X now = Destination Byte

			lda	_ter_drw_x_skip_left
			leau	a,u			; push src forward if needed

			;** Remap source pages
			lbsr	dtc_adjust_src_both	; ensure u is mapped

			;** Final preparations
			lda	_ter_drw_counter	; number of bytes to draw
__dtc_oexcusblk_draw_line
			pshs	a			; save the byte count
			ldd	,u+			; load source byte
			tst	_ter_drw_tmp
			bne	__dtc_oexcusblk_dl_skip_first_byte_adjust
			clra
			dec	_ter_drw_tmp
__dtc_oexcusblk_dl_skip_first_byte_adjust
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb
			lsra
			rorb

			lda	,s
			deca
			bne	__dtc_oexcusblk_dl_skip_last_byte_adjust
			andb	#$F0
__dtc_oexcusblk_dl_skip_last_byte_adjust
			tstb
			beq	__dtc_oexcusblk_dl_0	; don't write if zero

			;** Mask terrain byte

			clra
			bitb	#$0F			; test right pixel
			bne	__dtc_oexcusblk_post_right_pixel
			ora	#$0F			; rhs mask lets bg through
__dtc_oexcusblk_post_right_pixel
			bitb	#$F0			; test left pixel
			bne	__dtc_oexcusblk_post_left_pixel
			ora	#$F0			; lhs mask lets bg through
__dtc_oexcusblk_post_left_pixel
			anda	,x			; merge mask with bg
			sta	,x			; write mask
			;orb	,x			; merge pixel with masked bg
			;stb	,x			; write merged pixel
__dtc_oexcusblk_dl_0
			puls	a
			leax	1,x			; move to next dest byte
			lbsr	dtc_adjust_src_both	; ensure u is within range
			deca				; decrease byte count
			bne	__dtc_oexcusblk_draw_line	; loop for new byte

			lda	_ter_drw_x_skip_right
			leau	a,u			; skip bytes to the right
			inc	_ter_drw_y_loc		; point at next line	
			
			lda	_ter_width
			lsla				; multiply reverse skip by two
							; so we're doing two lines back
							; (just drawn line, plus next line to draw)
			nega				; make it negative
			leau	a,u			; move src pointer

			dec	_ter_drw_lines_left
			bne	__dtc_oexcusblk_new_row

			rts
;** end dtc_execute_offset_combined_upsidedown_black_mode

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

;** dtc_adjust_src_both
; This subroutine checks if the current source pointer is within the
; #Window_TerrainData page, and if not, it remaps and adjusts appropriately
dtc_adjust_src_both
			pshs	d
__dtc_asb_0
			cmpu	#Window_TerrainData+$2000
			blo	__dtc_asb_1
			leau	-$2000,u
			inc	Page_TerrainData
			bra	__dtc_asb_0
__dtc_asb_1
			cmpu	#Window_TerrainData
			bhs	__dtc_asb_2
			leau	$2000,u
			dec	Page_TerrainData
			bra	__dtc_asb_1
__dtc_asb_2
			puls	d
			rts
;** end dtc_adjust_src_both

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
;** end dtc_get_terrain_data

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

;** dtc_adjust_pixels_to_bytes
; This subroutine converts the X position figure from pixels to bytes, and stores whether
; the destination is byte-aligned or pixel-offset in _ter_drw_x_pixel_offset
dtc_adjust_pixels_to_bytes
			pshs	d			; save previous data
			clr	_ter_drw_x_pixel_offset	; clear previous setting
			ldd	_ter_drw_x_loc		; get the x loc in pixels
			asra				; divide by two and..
			rorb				; .. capture the remainder
			bcc	_dtc_ap2b_1		; remainder? brif not
			dec	_ter_drw_x_pixel_offset	; if remainder, set flag
_dtc_ap2b_1
			;tst	_ter_drw_x_loc		; test unshifted value
			;bpl	_dtc_ap2b_2		; positive, no adjust needed
			;inc	_ter_drw_x_pixel_offset ; reverse remainder
							; ff + 1 = 00 + 1 = 01
							; test pix offset for 0/non-0
_dtc_ap2b_2
			std	_ter_drw_x_loc		; store shifted value
			puls	d			; restore previous data
			rts
;** end dtc_adjust_pixels_to_bytes

			ENDSECTION
