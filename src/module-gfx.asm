;*** Graphics routines

			INCLUDE	"defines.asm"		; Coco hardware definitions

			SECTION	module_gfx
clear_virtual_screen	EXPORT
map_virtual_screen	EXPORT
get_addr_start_of_line	EXPORT
set_graphics_mode	EXPORT
;** clear_virtual_screen
;
;	Set physical memory pages 0 through 0E to zero
;	through virtual window. Return virtual window
;	to previous setting upon exit.

clear_virtual_screen
			pshs	a,y,x,u			; Save registers used
			ldu	#GIME.MMU0		; Get pointer to task-0 regs
			lda	0,u			; Get current value of window
			pshs	a			; Keep value of window
			lda	#0			; Load new window value
			ldy	#0			; Load clear-value
_clr_virt_scrn_0	sta	0,u			; Write new window value to mmu
			ldx	#$0000			; Set pointer to start of window
!			sty	,x++			; Write clear-value to memory through window
			cmpx	#$2000			; Have we reached end of window?
			bne	<			; If not, go write some more
			inca				; Next bank, please
			cmpa	#$0F			; Reached last bank?
			bne	_clr_virt_scrn_0	; If not, keep going
			puls	a			; Get previous mapping back
			sta	0,u			; Restore previous mapping
			puls	a,y,x,u			; Restore previous regs
			rts				; Go home

;*** map_virtual_screen
;	set logical blocks 0, 1 and 2 pointing at the virtual screen triplet
;	specified by register A (0 - 4).
;	Assumes windows 0,1,2
; ENTRY:	a = virtual screen triplet to be mapped

map_virtual_screen
			pshs	a,u			; Save previous values
			ldu	#GIME.MMU0		; Get pointer to task-0 regs
			lsla				; multiply a by two
			adda	,s+			; add previous value of a - a = a * 3
			sta	,u			; map first page of vsbank to vswindow0
			inca				; next page
			sta	1,u			; map second page of vsbank to vswindow1
			inca				; next page
			sta	2,u			; map third page of vsbank to vswindow2
			puls	u			; clean up stack
			rts

;*** get_addr_start_of_line
;	set D to point at the first byte of vertical line specified in register A
;	Note that this routine also remaps the virtual screen
; ENTRY:	a = Vertical offset to be calculated
; EXIT:		d = first byte of vertical offset specified in register A
; DESTROYS:	a,b/d

get_addr_start_of_line
			pshs	a			; Save vertical offset for later use
			lsra				; / 2
			lsra				; / 4
			lsra				; / 8
			lsra				; / 16
			lsra				; / 32 = vsbank
			lbsr	map_virtual_screen	; a = correct vsbank to be mapped
			;** By reaching here, the correct vsbank is mapped to windows 0,1,2
			;** Calculate the start of the correct vertical line within the vswindow
			puls	a			; pushed earlier - vertical line
			anda	#31			; lower bits = vertical offset within bank
			pshs	a
			lsla				; * 2
			adda	,s+			; a = a *3
			clrb				; bottom of b isn't needed
			;** By reaching here, the correct starting byte of the line is stored in D
			rts

;*** set_graphics_mode
;	put the coco3 into 256x192x4bpp graphics mode, ntsc, starting at physical location $0000
;	Note that this will need adjusting when a real video location is selected
; ENTRY:	none
; EXIT:		none
; DESTROYS:	a
set_graphics_mode
			lda	#GIME_MMUEN|GIME_SCS|GIME_FEXX
			sta	GIME.INIT0		; Set hardware config

			lda	#GIME_BP
			sta	GIME.VMODE		; Set video mode

			lda	#GIME_LPF192|GIME_BPR128|GIME_BPP4
			sta	GIME.VRES		; Set video resolution

			clr	GIME.HOFFSET
			clr	GIME.VOFFSET
			clr	GIME.VOFFSET+1
			clr	GIME.VSCROLL
			rts

			ENDSECTION