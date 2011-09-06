			INCLUDE	"defines.asm"		; Coco hardware definitions

			SECTION	.program_code_physical_map ; $FFA6
			FCB	$30
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

			lda	#159			; Set vertical row to be found

			;** Establish which vsbank needs to be mapped to the vswindow
			lbsr	get_addr_start_of_line	; map, and D = offset

			ldx	#767			; Set horizontal column
			leau	d,x			; This should set U to point at X,D



ENDLOOP			jmp	ENDLOOP
			ENDSECTION

			SECTION	.program_code_stack
Stack			EXPORT
			rmb 	255
Stack			EQU	*
			ENDSECTION
