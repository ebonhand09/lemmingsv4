;*** Graphics routines

			INCLUDE	"defines.asm"		; Coco hardware definitions

Blast8Bits		MACRO
			pulu cc,a,b,dp,x,y
			pshs cc,a,b,dp,x,y
			leas 16,s
			ENDM
BlastLine		MACRO
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			Blast8Bits
			ENDM



			SECTION .bss,bss
_cvtp_x_offset		RMB	2
_cvtp_y_counter		RMB	1
_cvtp_stack_pointer	RMB	2
_gasol_stack_pointer	RMB	2
_gasol_stack		RMB	16
			ENDSECTION

			SECTION	module_gfx
clear_virtual_screen	EXPORT
map_virtual_screen	EXPORT
get_addr_start_of_line	EXPORT
set_graphics_mode	EXPORT
set_palette		EXPORT
copy_virt_to_phys	EXPORT

;** copy_virt_to_phys
;	copy video data from the virtual screen to the physical screen
;	physical screen is 128 bytes wide, 160 bytes high
; ENTRY: X = horizontal offset (0 to 639) - TRUSTED, this should be pre-clamped

; disable ints on PIA/GIME, start U at src, S at dest+8, then pulu cc,a,b,dp,x,y; pshs cc,a,b,dp,x,y; leas 16,s
; so 31 cycles per 8 bytes plus any counting etc.
copy_virt_to_phys
			pshs	cc,a,b,dp,x,y,u
			;* disable ints
			lda	#$4C
			sta	GIME.INIT0
			;* prepare video
			sts	_cvtp_stack_pointer	;
			stx	_cvtp_x_offset
			clr	_cvtp_y_counter
			;lda	#Block_ScreenBuffer_0
			lda	_cur_vid_draw_block
			sta	Page_ScreenBuffer
			;lda	#Block_ScreenBuffer_0+1
			inca
			sta	Page_ScreenBuffer+1
			;lda	#Block_ScreenBuffer_0+2
			inca
			sta	Page_ScreenBuffer+2
			clra
			lds	#Window_ScreenBuffer+8
@_cvtp_0
			sts	_gasol_stack_pointer
			lds	#_gasol_stack+16
			lbsr	get_addr_start_of_line	; map first byte
			lds	_gasol_stack_pointer
			ldx	_cvtp_x_offset
			leau	d,x
			BlastLine
			inc	_cvtp_y_counter
			lda	_cvtp_y_counter
			cmpa	#160
			lbne	@_cvtp_0
			lda	GIME.IRQ
			lda	#$6C
			sta	GIME.INIT0
			lds	_cvtp_stack_pointer
			puls	cc,a,b,dp,x,y,u
			rts

;** clear_virtual_screen
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

			; Upper 16 bits of 19-bit starting address
			;clr	GIME.VOFFSET		; For viewing the virtual screen
							; For viewing the physical screen
			;lda	#Phys_ScreenBuffer_0	; $3C00 = page $0F
			lda	_cur_vid_show_loc
			sta	GIME.VOFFSET		; 
			clr	GIME.VOFFSET+1
			clr	GIME.VSCROLL
			clr	GIME.HOFFSET
			rts

;*** SetPalette: Configure the palette for the appropriate level. Hard-coded to Grass/0 for now
set_palette
			ldx	#GIME.PALETTE				; set some palette entries
			ldy	#_palette_data
			ldb	#0
!       	        lda     ,Y+
			sta	,X+
			incb
			cmpb    #16
			bne	<
			
			rts
                                
_palette_data
			FCB	%00000000	; 0000	- Black		#000000
			FCB	%00111111	; 0001	- White		#FFFFFF
			FCB	%00010000	; 0010	- Mid-Green	#00AA00
			FCB	%00001111	; 0011	- Off-Blue	#5555FF
			FCB	%00100111	; 0100	- Off-Red	#FF5555
			FCB	%00110111	; 0101	- Orange?	#FFFF55
			FCB	%00111000	; 0110	- Light Grey	#AAAAAA
			;** THE ABOVE ARE STANDARD BETWEEN ALL PALETTES

			;** TERRAIN SET 0 - SOIL
			FCB	%00110100	; 0111	- Duplicate of 8
			FCB	%00110100	; 1000	-		#FFAA00
			FCB	%00100010	; 1001	-		#AA5500
			FCB	%00100000	; 1010	-		#AA0000
			FCB	%00000100	; 1011	-		#550000
			FCB	%00000111	; 1100	-		#555555
			FCB	%00101010	; 1101	-		#AA55AA
			FCB	%00010100	; 1110	-		#55AA00 
			FCB	%00000010	; 1111	-		#005500

			;** TERRAIN SET 1 - HELL
			;FCB	%00110100	; 0111	- Duplicate of 8
			;FCB	%00001010	; 1000	-		#0055AA
			;FCB	%00100000	; 1001	-		#AA0000
			;FCB	%00000111	; 1010	-		#555555
			;FCB	%00000100	; 1011	-		#550000
			;FCB	%00100011	; 1100	-		#AA5555
			;FCB	%00111000	; 1101	-		#AAAAAA
			;FCB	%00100100	; 1110	-		#FF0000 
			;FCB	%00000001	; 1111	-		#000055
			ENDSECTION
