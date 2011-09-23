;** Interrupt handling routines
			INCLUDE	"defines.asm"
			INCLUDE "keyboard-definitions.asm"
			
			SECTION .bss,bss
_ih_counter		RMB	1
			ENDSECTION

			SECTION module_interrupt
setup_interrupts	EXPORT
setup_interrupts
			lda	#$34			; Turn off all ints from PIAs
			sta	PIA0.CA		; $FF01
			sta	PIA0.CB		; $FF03
			sta	PIA1.CA		; $FF21
			sta	PIA1.CB		; $FF23
			lda	PIA0.DA ; $FF00	; bleed old ints
			lda	PIA0.DB ; $FF02	; bleed
			lda	PIA1.DA ; $FF20	; bleed
			lda	PIA1.DB ; $FF22	; bleed
			lda	#$6C			; Enable Gime ints for vbord
			sta	GIME.INIT0		; $FF90
			lda	#8
			sta	GIME.IRQ		; $FF92

			lda	GIME.IRQ ; $FF92	; bleed irqs
			lda	GIME.FIRQ ; $FF93	; bleed firqs
			lda	#$7E			; JMP
			sta	INT.IRQ			; $FEF7
			ldx	#interrupt_handler	; this one is for irq
			stx	INT.IRQ+1
			
			clr	_ih_counter		;

			andcc	#$EF			; reenable ints?

			rts

interrupt_handler	EXPORT
interrupt_handler	
			lda	_cur_vid_draw_block
			ldb	_alt_vid_draw_block
			sta	_alt_vid_draw_block
			stb	_cur_vid_draw_block
			ldx	_cur_x_scroll_loc
			ldy	_alt_x_scroll_loc
			stx	_alt_x_scroll_loc
			sty	_cur_x_scroll_loc
			lda	_cur_vid_show_loc
			ldb	_alt_vid_show_loc
			sta	_alt_vid_show_loc
			stb	_cur_vid_show_loc
			stb	GIME.VOFFSET
			inc	_ih_counter

			;**	Read Keyboard for scroll
			;**	Checks to see if A or D is pressed, and if so
			;**	Updates the 'target location' variable
			lda	#KB_Row_A
			sta	PIA0.DB			; Check for 'A'
			lda	PIA0.DA			
			bita	#KB_Bit_A
			bne	@_a_not_pressed
			ldx	_target_scroll_loc
			leax	-2,x
			stx	_target_scroll_loc
@_a_not_pressed
			lda	#KB_Row_D
			sta	PIA0.DB
			lda	PIA0.DA
			bita	#KB_Bit_D
			bne	@_d_not_pressed
			ldx	_target_scroll_loc
			leax	2,x
			stx	_target_scroll_loc
@_d_not_pressed
			cmpx	#0
			bhi	@_skip_loc_clamp_left
			ldx	#0
@_skip_loc_clamp_left
			cmpx	#639
			blo	@_skip_loc_clamp_right
			ldx	#639
@_skip_loc_clamp_right


			lda	GIME.IRQ
			rti			


			ENDSECTION
				
