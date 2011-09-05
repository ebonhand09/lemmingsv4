;** Definitions
;** Artlessly stolen from LWOS

GIMEREGS	struct
INIT0		rmb 1		;GIME control reg 0
INIT1		rmb 1		;GIME control reg 1
IRQ		rmb 1		;IRQ enable/status register
FIRQ		rmb 1		;FIRQ enable/status register
TIMER		rmb 2		;Timer reset value
		rmb 2
VMODE		rmb 1		;Video mode register
VRES		rmb 1		;Video resolution register
BORDER		rmb 1		;Video border colour
MEMEXT		rmb 1		;memory expansion board register (see note)
VSCROLL		rmb 1		;vertical scroll register
VOFFSET		rmb 2		;vertical offset (screen address) register
HOFFSET		rmb 1		;horizontal offset register
MMU0		rmb 8		;MMU task 0
MMU1		rmb 8		;MMU task 1
PALETTE		rmb 16		;palette registers
		endstruct
* NOTE: the memory extension register is not part of the GIME; its bits are
* defined as follows, all bits write only:
*
* 7,6	unused (maybe on 16MB expansion board)
* 5,4	high 2 bits of MMU register, 8MB board; value is latched and
*	automatically prepended to writes to regular MMU registers
* 3-0	video page (high 4 bits of screen address) except that the screen
*	cannot span video pages; pages are 512K in size

FDCREGS		struct
CMD		rmb 1		;command/status register
TRK		rmb 1		;track register
SEC		rmb 1		;sector register
DATA		rmb 1		;data register
		endstruct

PIAREGS		struct
DA		rmb 1		;data register A
CA		rmb 1		;control register A
DB		rmb 1		;data register B
CB		rmb 1		;control register B
		endstruct

SAMREGS		struct
V0CLR		rmb 1		;clear graphics mode V0
V0SET		rmb 1		;set graphics mode V0
V1CLR		rmb 1		;clear graphics mode V1
V1SET		rmb 1		;set graphics mode V1
V2CLR		rmb 1		;clear graphics mode V2
V2SET		rmb 1		;set graphics mode V2
F0CLR		rmb 1		;clear graphics mode offset F0
F0SET		rmb 1		;set graphics mode offset F0
F1CLR		rmb 1		;clear graphics mode offset F1
F1SET		rmb 1		;set graphics mode offset F1
F2CLR		rmb 1		;clear graphics mode offset F2
F2SET		rmb 1		;set graphics mode offset F2
F3CLR		rmb 1		;clear graphics mode offset F3
F3SET		rmb 1		;set graphics mode offset F3
F4CLR		rmb 1		;clear graphics mode offset F4
F4SET		rmb 1		;set graphics mode offset F4
F5CLR		rmb 1		;clear graphics mode offset F5
F5SET		rmb 1		;set graphics mode offset F5
F6CLR		rmb 1		;clear graphics mode offset F6
F6SET		rmb 1		;set graphics mode offset F6
		rmb 4		;reserved
R1CLR		rmb 1		;clear CPU rate (SLOW mode)
R1SET		rmb 1		;set CPU rate (TURBO mode)
		rmb 4		;reserved
ROMCLR		rmb 1		;set all RAM mode
ROMSET		rmb 1		;set ROM mode
		endstruct

* define actual hardware locations
		org $FEED
* Even though these are in RAM, their location is forced by the coco3 ROM
INT.FLAG	rmb 1		;interrupt bounce vector initialized flag ($55)
INT.SWI3	rmb 3		;SWI3 bounce vector
INT.SWI2	rmb 3		;SWI2 bounce vector
INT.FIRQ	rmb 3		;FIRQ bounce vector
INT.IRQ		rmb 3		;IRQ bounce vector
INT.SWI		rmb 3		;SWI bounce vector
INT.NMI		rmb 3		;NMI bounce vector
PIA0		PIAREGS		;PIA0
		rmb 28
PIA1		PIAREGS		;PIA1
		rmb 28
DSKREG		rmb 1		;floppy disk control register
		rmb 7
FDCREG		FDCREGS		;floppy disk registers
		rmb 4
		rmb 16		;unused area of SCS
		rmb 31		;random hardware
MULTIPAK	rmb 1		;multipak slot register

		rmb 16		;unused
GIME		GIMEREGS	;GIME
SAM		SAMREGS		;SAM registers
		rmb 18		;MPU reserved
SWI3		rmb 2		;MPU SWI3 vector
SWI2		rmb 2		;MPU SWI2 vector
FIRQ		rmb 2		;MPU FIRQ vector
IRQ		rmb 2		;MPU IRQ vector
SWI		rmb 2		;MPU SWI vector
NMI		rmb 2		;MPU NMI vector
RESET		rmb 2		;MPU RESET vector
		endc

* definitions for various bits in various registers
* GIME.INIT0
GIME_COCO	equ 0x80	;"coco compatibility" mode
GIME_MMUEN	equ 0x40	;MMU enabled
GIME_IEN	equ 0x20	;GIME IRQ enabled
GIME_FEN	equ 0x10	;GIME FIRQ enabled
GIME_FEXX	equ 0x08	;constant page at FExx enabled
GIME_SCS	equ 0x04	;SCS at FF4x enabled
GIME_ROMI16	equ 0x00	;16K/16K internal/external ROM split
GIME_ROMI32	equ 0x02	;32K internal ROM
GIME_ROME32	equ 0x03	;32K external ROM

* GIME.INIT1
GIME_TMR70ns	equ 0x20	;"fast" timer mode (279.365ns/tick)
GIME_TMR63us	equ 0x00	;"slow" timer mode (63.695µs/tick)
GIME_TASK0	equ 0x00	;MMU task 0
GIME_TASK1	equ 0x01	;MMU task 1

* GIME interrupt register bits
GIME_INTTIMER	equ 0x20	;timer interrupt
GIME_INTHBORD	equ 0x10	;horizontal border interrupt
GIME_INTVBORD	equ 0x08	;vertical border (60Hz) interrupt
GIME_INTSERIAL	equ 0x04	;serial data interrupt (mostly useless)
GIME_INTKEYB	equ 0x02	;keyboard interrupt
GIME_INTCART	equ 0x01	;cartride interrupt (CART*)

* GIME.VMODE bits
GIME_BP		equ 0x80	;enable bit plane graphics
GIME_BPI	equ 0x40	;composite burst phase invert
GIME_MONO	equ 0x20	;composite disable colour burst
GIME_50HZ	equ 0x10	;set for 50Hz mode
GIME_LPR1	equ 0x00	;1 line per row
GIME_LPR2	equ 0x01	;2 lines per row
GIME_LPR3	equ 0x02	;3 lines per row
GIME_LPR8	equ 0x03	;8 lines per row
GIME_LPR9	equ 0x04	;9 lines per row
GIME_LPR10	equ 0x05	;10 lines per row
GIME_LPR12	equ 0x06	;12 lines per row

* GIME.VRES bits
GIME_LPF192	equ 0x00	;192 lines per screen
GIME_LPF200	equ 0x20	;200 lines per screen
* GIME_LPF210	equ 0x40	;210 lines per screen - nonfunctional
GIME_LPF225	equ 0x60	;225 lines per screen
GIME_TXT32	equ 0x00	;32 column text
GIME_TXT40	equ 0x04	;40 column text
GIME_TXT64	equ 0x10	;64 column text
GIME_TXT80	equ 0x14	;80 column text
GIME_TXTATTR	equ 0x01	;enable attributes on text screen
GIME_BPR16	equ 0x00	;16 bytes per row
GIME_BPR20	equ 0x04	;20 bytes per row
GIME_BPR32	equ 0x08	;32 bytes per row
GIME_BPR40	equ 0x0C	;40 bytes per row
GIME_BPR64	equ 0x10	;64 bytes per row
GIME_BPR80	equ 0x14	;80 bytes per row
GIME_BPR128	equ 0x18	;128 bytes per row
GIME_BPR160	equ 0x1C	;160 bytes per row
GIME_BPP1	equ 0x00	;1 bit per pixel
GIME_BPP2	equ 0x01	;2 bits per pixel
GIME_BPP4	equ 0x02	;4 bits per pixel
