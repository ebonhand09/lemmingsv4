PIA0_PDR_A	EQU	$FF00	* Read from this for keyboard
PIA0_PDR_B	EQU	$FF02	* Write to this to read keyboard
Keyboard_Row	EQU	$FF02
Keyboard_Scan	EQU	$FF00

****** $FE = 11111110

KB_Row_Enter	EQU	$FE
KB_Bit_Enter	EQU	$40

KB_Row_8	EQU	$FE	* Write this
KB_Bit_8	EQU	$20	* Bit this

KB_Row_0	EQU	$FE	* Write this
KB_Bit_0	EQU	$10	* Bit this

KB_Row_X	EQU	$FE	* Write this to PDR_B
KB_Bit_X	EQU	$8	* BIT this

KB_Row_P	EQU	$FE	* Write this to PDR_B
KB_Bit_P	EQU	$4	* BIT this

KB_Row_H	EQU	$FE	* Write this to PDR_B to check for H
KB_Bit_H	EQU	$2	* BIT this

KB_Row_At	EQU	$FE
KB_Bit_At	EQU	$1

****** $FD = 11111101

KB_Row_Clear	EQU	$FD
KB_Bit_Clear	EQU	$40

KB_Row_9	EQU	$FD
KB_Bit_9	EQU	$20

KB_Row_1	EQU	$FD
KB_Bit_1	EQU	$10

KB_Row_Y	EQU	$FD
KB_Bit_Y	EQU	$8

KB_Row_Q	EQU	$FD
KB_Bit_Q	EQU	$4

KB_Row_I	EQU	$FD
KB_Bit_I	EQU	$2

KB_Row_A	EQU	$FD
KB_Bit_A	EQU	$1

****** $FB = 11111011

KB_Row_Break	EQU	$FB
KB_Bit_Break	EQU	$40

KB_Row_Colon	EQU	$FB
KB_Bit_Colon	EQU	$20

KB_Row_2	EQU	$FB
KB_Bit_2	EQU	$10

KB_Row_Z	EQU	$FB
KB_Bit_Z	EQU	$8

KB_Row_R	EQU	$FB
KB_Bit_R	EQU	$4

KB_Row_J	EQU	$FB
KB_Bit_J	EQU	$2

KB_Row_B	EQU	$FB
KB_Bit_B	EQU	$1

****** $F7 = 11110111

KB_Row_Semi	EQU	$F7
KB_Bit_Semi	EQU	$20

KB_Row_3	EQU	$F7
KB_Bit_3	EQU	$10

KB_Row_Up	EQU	$F7
KB_Bit_Up	EQU	$8

KB_Row_S	EQU	$F7
KB_Bit_S	EQU	$4

KB_Row_K	EQU	$F7
KB_Bit_K	EQU	$2

KB_Row_C	EQU	$F7
KB_Bit_C	EQU	$1

****** $EF = 11101111

KB_Row_Comma	EQU	$EF
KB_Bit_Comma	EQU	$20

KB_Row_4	EQU	$EF
KB_Bit_4	EQU	$10

KB_Row_Down	EQU	$EF
KB_Bit_Down	EQU	$8

KB_Row_T	EQU	$EF
KB_Bit_T	EQU	$4

KB_Row_L	EQU	$EF
KB_Bit_L	EQU	$2

KB_Row_D	EQU	$EF
KB_Bit_D	EQU	$1

****** $DF = 11011111

KB_Row_Hyphen	EQU	$DF
KB_Bit_Hyphen	EQU	$20

KB_Row_5	EQU	$DF
KB_Bit_5	EQU	$10

KB_Row_Left	EQU	$DF
KB_Bit_Left	EQU	$8

KB_Row_U	EQU	$DF
KB_Bit_U	EQU	$4

KB_Row_M	EQU	$DF
KB_Bit_M	EQU	$2

KB_Row_E	EQU	$DF
KB_Bit_E	EQU	$1

****** $BF = 10111111

KB_Row_Period	EQU	$BF
KB_Bit_Period	EQU	$20

KB_Row_6	EQU	$BF
KB_Bit_6	EQU	$10

KB_Row_Right	EQU	$BF
KB_Bit_Right	EQU	$8

KB_Row_V	EQU	$BF
KB_Bit_V	EQU	$4

KB_Row_N	EQU	$BF
KB_Bit_N	EQU	$2

KB_Row_F	EQU	$BF
KB_Bit_F	EQU	$1

****** $7F = 01111111

KB_Row_Shift	EQU	$7F
KB_Bit_Shift	EQU	$40

KB_Row_Slash	EQU	$7F
KB_Bit_Slash	EQU	$20

KB_Row_7	EQU	$7F
KB_Bit_7	EQU	$10

KB_Row_Space	EQU	$7F
KB_Bit_Space	EQU	$8

KB_Row_W	EQU	$7F
KB_Bit_W	EQU	$4

KB_Row_O	EQU	$7F
KB_Bit_O	EQU	$2

KB_Row_G	EQU	$7F
KB_Bit_G	EQU	$1

****** End KB Defs







