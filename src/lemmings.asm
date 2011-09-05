			INCLUDE	"defines.asm"		; Coco hardware definitions


			;** Some hand EQU's
ProgramCode		EQU	$30

			ORG	$FFA6			; Switch storage block - put our code at $C000
			FCB	ProgramCode		; Start of program code in physical ram
			ORG	$C000			; Physical block 'ProgramCode', Virtual Page 0

			orcc	#$50			; Disable interrupts (just in case)
			lds	#STACK+255		; Relocate stack

			lbsr	set_graphics_mode	; 256x192x16			
	
			lbsr	clear_virtual_screen	; Go clear some ram
			;** By reaching here, pages 0 through 0E should be cleared

			lda	#159			; Set vertical row to be found

			;** Establish which vsbank needs to be mapped to the vswindow
			lbsr	get_addr_start_of_line	; map, and D = offset

			ldx	#767			; Set horizontal column
			leau	d,x			; This should set U to point at X,D



ENDLOOP			jmp	ENDLOOP

			INCLUDE	"module-gfx.asm"

STACK			rmb 	256

			END	$C000

