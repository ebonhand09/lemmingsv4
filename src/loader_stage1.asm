* this is a simple LOADM/CLOADM loader that will autostart its payload
*
* It works by hooking the CLOSE call that occurs immediately after the
* postamble is read. It then continues reading bytes from the file until it
* receives an EOF indicator and stores them starting at physical memory
* address 0. Once EOF is found, it closes the file and transfers control to
* physical memory address 0, entering with interrupts disabled.

		org $2000
LOADER		ldd #$176		* restore the close routine
		std $a42e		*
		; MY HACK
		LDY	#$400
		LDU	#$2020
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		
		; END MY HACK			
		clrb			set first block to load to
loader1		stb $ffa2		we use $4000-$5FFF as the scratch area
		ldx #$4000		point to start of block
loader2		jsr $a176		get a byte from the file
		tst <$70		EOF?
		bne loader3		brif not
		sta ,x+			save it in the buffer
		cmpx #$6000		end of block?
		blo loader2		brif not
		; MY HACK
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		STU	,Y++
		; END MY HACK
		incb			next block
		bra loader1		continue reading
loader3		jsr $a42d		close the file to be polite
		clr <$71		* force basic to do a cold start
		clr <$72		*
		clr <$73		*
		orcc #$50		kill interrupts
		clr $ffa0		get block 0 to logical 0
		sta $ffd9		go to turbo mode for second stage
		jmp >0			start the payload executing
		
* my hackery - a very boring text screen

* the following traps the "close" that happens as soon as the postamble is
* read; remember, this is a coco3 that is running in RAM

		org $a42e
		fdb LOADER
		
* setting the execute address is pointless but we do so anyway
		end LOADER

* Some details on how it works follow.
*
* This loader exploits the way LOADM and CLOADM are implemented to allow the
* payload to be loaded from the same file as the stub loader. LOADM and CLOADM
* call the standard basic CLOSE at $A42D immediately after reading the
* postamble. Furthermore, all byte reads from the file are done via the
* standard CONSOLE IN routine at $A176 (or by short ciruiting directly into
* the relevant implementation as in the case of LOADM).
*
* The first segment of the file consists of the actual first stage loader.
* This assumes that once control is transferred to it, the currently open
* file contains the payload to be loaded at the current file offset.
*
* The second segment replaces the JSR $176 at the start of the CLOSE routine
* with a JSR to the loader. This will cause the loader to be executed before
* the file is closed but after the first stage loader has been loaded. That
* means the loader will be started automatically with the file still open.
*
* The loader itself restores the JSR $176 instruction. Then it reads all
* of the remaining bytes from the file to physical RAM starting at $00000 and
* proceeding upward. There is no inherent size limit in the code.
*
* Once the kernel is loaded, the file is closed. This is unnecessary but it's
* polite to do so. Besides, maybe this is being loaded through another scheme
* that does benefit from the file being closed and which is also compatible
* with [C]LOADM. Note that this step is the reason this loader does not
* just replace the vector at $176; the vector itself could point anywhere
* so blindly replacing it would be a dangerous idea.
*
* The remainder of the loader just does some book keeping to pass control to
* the just loaded payload.
*
* When the payload starts executing, B will contain the highest physical block
* that data was loaded to and X will point one byte past the last byte
* loaded.
