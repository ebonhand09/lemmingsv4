* This is the second stage loader. It must be assembled as a *raw* binary.

* This always executes starting at address 0
		org 0
loader		ldx #payload+$2000	point to start of payload in logical block 1
		clra			initialize block counter
		sta >$ffa1		initialize the MMU
		lds #tempstack+6	temporary stack location
loader0		bsr getbyte		fetch block flag
		bne loader2		brif postamble
		bsr getbyte		fetch msb of block size
		stb >tword		stow it
		bsr getbyte		fetch lsb of block size
		stb >tword+1		stow it
		ldy >tword		get block size in Y for counting
		bsr getbyte		get msb of address
		stb >tword		stow it
		bsr getbyte		get lsb of address
		stb >tword+1		stow it
		ldu >tword		get address to U
loader1		bsr getbyte		fetch a byte
		stb ,u+			save it
		leay -1,y		finished this block?
		bne loader1		brif not
		bra loader0		get next block
loader2		bsr getbyte		skip unused byte
		bsr getbyte		skip second unused byte
		bsr getbyte		fetch msb of execute address
		stb >tword		stow it
		bsr getbyte		fetch lsb of execute address
		stb >tword+1		stow it
		bsr getbyte		get first byte of "root device"
		pshs b			save it
		bsr getbyte		get second byte of root device
		puls a			get back first byte
		tfr d,u			put root device in U
		jmp [tword]		transfer control to system
tword		fdb 0			temp storage used above
tempstack	fdb 0,0,0		stack buffer for calling getbyte
* read a byte from A,X and bump pointer
getbyte		ldb ,x+			read byte
		cmpx #$4000		end of block?
		blo getbyte0		brif not
		ldx #$2000		reset to start of block
		inca			bump block counter
		sta >$ffa1		save block in MMU
getbyte0	tstb			set flags
		rts			return
payload		equ *			payload starts here

* How the loader works:
*
* Upon entry, interrupts must be disabled and this loader must be located
* in physical memory block 0 and logical memory block 0. The payload to be
* loaded must immediately follow this code and must be in "loadm" format.
* Also, the MMU must be enabled and set to task 0.
*
* The loader proceeds by reading the payload byte by byte and interpreting
* it just as LOADM does. However, it does not do any verification that bytes
* written are readable. When it finds the postamble, it fetches the execute
* address from it and transfers control there. Once control is transferred,
* A,X still contains a pointer to the next byte.
*
* The only restrictions on the payload are as follows:
*
* 1. It must not affect MMU blocks 0 and 1.
* 2. It must not load anything below $4000.
* 3. It must avoid scribbling on the payload area while loading. That means
*    it cannot use the low memory blocks. It is likely the loader will
*    crash if these are overwritten.
* 4. It must not disable the MMU or switch memory map modes.
*
* It is free to do any number of other things such as adjusting hardware
* registers, etc.
*
* When control is transferred to the payload, interrupts are disabled.
