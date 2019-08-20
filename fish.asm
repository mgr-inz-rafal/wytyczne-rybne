			opt m+r+
			
			; Selected ATARI registes
			icl 'atari.inc'

pstart			equ $2000
			
scr_rowsize		equ 40
scr_lines		equ 96
scr_lastb		equ scr_mem_0+scr_rowsize*(scr_lines-1)+(scr_rowsize-1)
scr_size		equ	scr_lastb-scr_mem_0+1

fishdimx		equ	32						; Horizontal dimension of fish (in pixels)
fishdimy		equ 32						; Vertical dimension of fish (in pixels)
fishpxperb		equ	4						; Pixels per byte (ie. 10 00 10 11)
fishbperrow		equ	fishdimx/fishpxperb		; Bytes for each row
fishsize		equ fishbperrow*fishdimy	; Bytes per fish
fishtpspprt		equ	5						; Fish types per part (ie. 5 heads, 5 tails, etc.)
fishparts		equ	4						; Head, Upper body, Lower body, Tail
fishestotal		equ fishtpspprt*fishparts	; Total number of fishes
fishtotbts		equ	fishestotal*fishsize	; Total bytes for all fishes

fish_maxy		equ scr_lines-fishdimy		; Maximum vertical fish position
fish_maxx		equ scr_rowsize-fishbperrow	; Maximum horizontal fish position

fishchain_x		equ 0
fishchain_len	equ 5
fishslot_x		equ fishbperrow
fishslot_y		equ fishdimy*2
fishslot_len	equ 4

fish_color_0	equ 21
fish_color_1	equ 98
fish_color_2	equ 207
fish_color_bg	equ 0

busted_color_0	equ 49
busted_color_1	equ 54
busted_color_2	equ $00
busted_color_bg	equ $0f

congra_color_0	equ 117
congra_color_1	equ 123
congra_color_2	equ $00
congra_color_bg	equ $0f

tool_init_y		equ $20
tool_init_x		equ $2b
tool_color		equ $0f
tool_apart		equ	$a2
tool_height		equ 64
tool_at_bottom	equ tool_height+tool_init_y-2

funnel_init_x	equ fishbperrow*2
funnel_y		equ fishdimy
funnel_at_left	equ	fishbperrow
funnel_at_right	equ	fishbperrow*fishparts

slots_y			equ fishdimy*2

number_count	equ fishslot_len	; 3, 2, 1, 0
count_delay		equ	50

level_count		equ 20
level_delay_inc	equ 13

busted_count	equ 4	; 4 segments of "BUSTED" text
busted_width	equ 111	; Pixels

congrats_count	equ 5	; 5 segments of "CONGRATULATIONS" text

titlefish_count	equ 4	; 4 segments of the title fish graphics
titlefish_width	equ 125	; Pixels

lives_count		equ 4

; Fish chain states
.zpvar	fcstate	.byte
FC_STATIONARY	equ 0
FC_MOVINGLEFT	equ 1
FC_MOVINGRIGHT	equ 2
FC_DROPPING		equ 3				; Fish going into funnel
FC_CONSTRUCTING	equ 4				; Fish going from funnel to slot

; Game states
.zpvar	gstate	.byte
GS_GUIDELINES	equ 0				; Fish guidelines are shown
GS_CUNTDOWN		equ 1				; C(o)untdown before the guidelines ;-)
GS_CONSTRUCTION	equ 2				; Player is constructing the fish
GS_GAME_OVER	equ 3				; The game is over

; Tool states
.zpvar	tstate	.byte
TS_STATIONARY	equ 0
TS_MOVING_DOWN	equ	1
TS_MOVING_UP	equ 2

; Funnel states
.zpvar	fstate	.byte
FU_STATIONARY	equ 0
FU_MOVINGLEFT	equ 1
FU_MOVINGRIGHT	equ 2

.zpvar	fishdry	.byte				; Used when moving fish vertically
.zpvar	erase_r	.byte				; Used by rectangle draving routine... 
.zpvar	erase_l	.byte				; ...to check whether rightmost or...
									; ...leftmost column should get erased
.zpvar	funnl_x	.byte				; Horizontal position of funnel
.zpvar	tool_y	.byte				; Current vertical position of tool
.zpvar	pscr	.word				; Pointer to current screen
.zpvar	pnscr	.word				; Pointer to next screen
.zpvar	ffeedof	.byte				; Fish feeding offset
.zpvar	fishmov	.byte				; Fish move counters,
									;  when =0 fish chain is aligned
									;  (used also for funnel movement)
.zpvar	ptr0	.word				; General purpose pointers
.zpvar	ptr1	.word				; ...
.zpvar	ptr2	.word				; ...ditto
.zpvar	cntr0	.byte				; General purpose counter
.zpvar	drf_x	.byte				; Used by fish-drawing routine...
.zpvar	drf_y	.byte				; ...to draw at given coordinates
.zpvar	tmp0	.byte				; General purpose temporary value
.zpvar	tmp1	.byte				; ...
.zpvar	tmp2	.byte				; ...
.zpvar	tmp3	.byte				; ...
.zpvar	tmp4	.byte				; ...ditto
.zpvar	delayt	.byte				; Delay time, used by delay routine
.zpvar	delayt2	.byte				; ...ditto
.zpvar	level	.byte				; Current level
.zpvar	lives	.byte				; Number of lives
.zpvar	english .byte				; If 1 then english version
.zpvar	silence	.byte				; If 1 then no music
.zpvar	crunched .byte				; If 1 then no more decrunching

			; Here we begin!
			org	pstart
.align 		$1000
scr_mem_0
			ins "graphics/backgrnd.sra"
tab_fish_ypos_0	; Y-coordinate tabs for screen 0
.rept fish_maxy+1
			dta a(scr_mem_0+scr_rowsize*#)
.endr
tab_fish_ypos_0_len	equ *-tab_fish_ypos_0
.align 		$1000
scr_mem_1
			ins "graphics/backgrnd.sra"
tab_fish_ypos_1 ; Y-coordinate tabs for screen 1
.rept fish_maxy+1
			dta a(scr_mem_1+scr_rowsize*#)
.endr
tab_fish_ypos_1_len	equ *-tab_fish_ypos_1

fishdata
.rept fishestotal, #/fishtpspprt, #%fishtpspprt
.if :2=0
fishparts_:1
.endif
fish_:1_:2
			ins "graphics/p:1_:2.sra"
.endr
funnel_data
			ins "graphics/funnel.sra"
empty_data
			ins "graphics/empty.sra"
.rept number_count, 3-#
numbitmap_:1
			ins "graphics/no:1.sra"
.endr
level_data
.rept level_count, #+1
			ins "graphics/level:1.sra"
.endr
lives_data
.rept lives_count, 3-#
			ins "graphics/lives:1.sra"
.endr
busted_data
.rept busted_count, #+1
			ins "graphics/busted:1.sra"
.endr
congrats_data
.rept congrats_count, #+1
			ins "graphics/congrat:1.sra"
.endr
titlefish_data
.rept titlefish_count, #+1
			ins "graphics/fish:1.sra"
.endr
badfish_data
			ins "graphics/badfish.sra"
goodfish_data
			ins "graphics/goodfish.sra"

run_here
			cld
			
			ldx #1
			stx silence
			dex
			stx crunched
			
			ldy <vbi_routine
			ldx >vbi_routine
			lda #7
			jsr SETVBV
			
run_again	mwa #scr_mem_0 pscr
			mwa #scr_mem_1 pnscr
			
			jsr title_screen
			
			jsr disable_antic
			mwa #scr_size ptr2
			lda #0
			jsr fill_screen
			jsr flip_screens
			mwa #scr_size ptr2
			lda #0
			jsr fill_screen
			
			jsr game_init
			jsr enable_antic
			jsr gfx_init
			jsr game_loop

			; Unreachable :)
chuj		jmp chuj

disable_antic
			lda SDMCTL
			sta tmp4
			lda #0
			sta SDMCTL
			rts

enable_antic
			lda tmp4
			sta SDMCTL
			rts
			
title_dli_routine
			phr
			
			lda VCOUNT
			
			; Fish picture
			cmp #$0f
			bne tdr_a
			
			lda #216
			ldx #221
			ldy #$79
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK
			
			jmp tdr_x
			
			; Shade of water #1
tdr_a		cmp #$17
			bne tdr_b

			ldy #$77
			sta WSYNC
			sty COLPF2
			
			jmp tdr_x			
			
			; Shade of water #2
tdr_b		cmp #$1e
			bne tdr_c

			ldy #$75
			sta WSYNC
			sty COLPF2
			
			jmp tdr_x			
			
			; Shade of water #3
tdr_c		cmp #$25
			bne tdr_0

			ldy #$73
			sta WSYNC
			sty COLPF2
			
			jmp tdr_x			
			
			; Main title text
tdr_0		cmp #$33
			bne tdr_1
			
			lda #>pmg_base
			sta CHBASE

			lda #$7a
			ldx #$ba
			ldy #$5a
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK
			
:8			sta WSYNC
			lda #$77
			ldx #$b7
			ldy #$57
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			
			jmp tdr_x
	
			; Title separator
tdr_1		cmp #$3b
			bne tdr_2

			lda #$00
			ldx #$06
			ldy #$b2
			;sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK
			
			jmp tdr_x
	
			; First subtitle line
tdr_2		cmp #$3f
			bne tdr_3

			lda #>(pmg_base+512)
			sta CHBASE
			
			lda #223
			ldx #223
			ldy #$00
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK

			jmp tdr_x
			
			; Second subtitle line
tdr_3		cmp #$43
			bne tdr_4

			lda #216
			ldx #216
			ldy #$00
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK
			
			jmp tdr_x

			; Main text
tdr_4		cmp #$4b
			bne tdr_5

			lda #>pmg_base
			sta CHBASE
			
			lda #$00
			ldx #$0f
			ldy #$22
;			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK
			
			jmp tdr_x

			; Separator after main text
tdr_5		cmp #$63
			bne tdr_6

			lda #$00
			ldx #$00
			ldy #$00
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK

:5			sta WSYNC			

			; First footer line
			lda #$00
			ldx #$0f
			ldy #$42
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK

:7			sta WSYNC			

			; Second footer line
			lda #$00
			ldx #$07
			ldy #$82
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK
			
			jmp tdr_x
			
tdr_6
tdr_x		plr
			rti
			
decrunch_dli_routine
			phr
			
			lda VCOUNT
			
			; Fish picture
			cmp #$0f
			bne dddr_a
			
			lda #216
			ldx #221
			ldy #$79
			sta WSYNC
			sta COLPF0
			stx COLPF1
			sty COLPF2
			lda #0
			sta COLPF3
			sta COLBK
			
			jmp dddr_x
			
			; Shade of water #1
dddr_a		cmp #$17
			bne dddr_b

			ldy #$77
			sta WSYNC
			sty COLPF2
			
			jmp dddr_x			
			
			; Shade of water #2
dddr_b		cmp #$1e
			bne dddr_c

			ldy #$75
			sta WSYNC
			sty COLPF2
			
			jmp dddr_x			
			
			; Shade of water #3
dddr_c		cmp #$25
			bne dddr_0

			ldy #$73
			sta WSYNC
			sty COLPF2
			
			jmp dddr_x			
			
			; White text on black screen
dddr_0		cmp #$33
			bne dddr_x
			
			lda #$ff
			ldy #$00
			sta WSYNC
			sta COLPF0
			sty COLPF2			
			
dddr_6
dddr_x		plr
			rti

; Sets up the title screen
title_screen
			jsr disable_antic
			
			lda #$ff
			sta CH

			lda #$00
			sta COLOR0
			sta COLOR1
			sta COLOR2
			sta COLOR3
			sta COLOR4
			
			; Setup display list
			ldx <dlist_title
			ldy >dlist_title
			stx SDLSTL
			sty SDLSTL+1
			
			; Setup font
			lda #>pmg_base
			sta CHBAS
			
			; Clear graphical part of the screen
			mwa #scr_rowsize*fishdimy ptr2
			lda #%11111111
			jsr fill_screen
			
			jsr draw_title_fish

			lda crunched
			cmp #1
			beq @+
			jsr decrunching			;-)

			; Init DLI
			lda <title_dli_routine
			sta VDSLST
			lda >title_dli_routine
			sta VDSLST+1
			lda #%11000000
			sta NMIEN
			
@			jsr draw_title_content
			
			jsr enable_antic
			jsr play_title_music
			
			; Protect agains accidental game startup
			jsr short_delay

ts_1		lda HELPFG
			sta ATRACT
			cmp #0
			beq ts_0
			jsr switch_language
ts_0		lda STRIG0
			cmp #1
			beq ts_1			

			jsr stop_music			
			rts
			
; Switches the current language
switch_language
			lda #0
			sta HELPFG
			inc english
			jsr draw_title_content
			jsr short_delay
			rts
			
; Provides short delay
short_delay
			lda #50
			sta delayt
			lda #0
			sta delayt2
			jsr delay
			rts

; Provides very short delay
very_short_delay
			lda #15
			sta delayt
			lda #0
			sta delayt2
			jsr delay
			rts

; Draws the content of the title screen
draw_title_content
			mwa #scr_mem_1+scr_rowsize*fishdimy ptr0
			lda english
			and #%00000001
			cmp #0
			beq dtc_2
			mwa #title_content_data_EN ptr1
			jmp dtc_3
dtc_2		mwa #title_content_data_PL ptr1
			
dtc_3		ldy #0
dtc_1		lda (ptr1),y
			cmp #$ff
			beq dtc_0	; Done
			sta (ptr0),y
			inw ptr0
			inw ptr1
			jmp dtc_1
			
dtc_0		rts
			
title_content_data_EN
			dta d'  F'
			dta d'i'
			dta d'S'*
			dta d'H'
			dta d'y '
			dta d'g'
			dta d'U'*
			dta d'I'
			dta d'd'
			dta d'E'*
			dta d'L'
			dta d'i'
			dta d'N'*
			dta d'E'
			dta d's  '
:20			dta b(126),b(127)
			dta d'   mgr in'
			dta b(24)
			dta b(32)
			dta d' '
			dta b(8)
			dta d'afa'
			dta b(59)
			dta d'   '
			dta d'    music by '
			dta b(84)
			dta d'n'
			dta b(85)
			dta d'    '
			dta d'This is the game about joining fishes   '
			dta d'that had been sliced apart by using the '
			dta d'moving pipe with arrow. Remember the    '
			dta d'target fish, find correct pieces and    '
			dta d'reunite them! Time to remember the fish '
			dta d'decreases with each level.              '
			dta d'                                        '
			dta d'GAME-COMPO ENTRY for WAP-NIAK 2016 PARTY'*
			dta b(74)
			dta d'HELP'*
			dta b(74+128)
			dta d' - polish version             v1.1'
			dta b($ff)

title_content_data_PL
			dta d'   W'
			dta d'y'
			dta d'T'*
			dta d'Y'
			dta d'c'
			dta d'Z'*
			dta d'N'
			dta d'e '
			dta d'R'*
			dta d'Y'
			dta d'b'
			dta d'N'*
			dta d'E   '
:20			dta b(126),b(127)
			dta d'   mgr in'
			dta b(24)
			dta b(32)
			dta d' '
			dta b(8)
			dta d'afa'
			dta b(59)
			dta d'   '
			dta d'    music by '
			dta b(84)
			dta d'n'
			dta b(85)
			dta d'    '
			dta d'Jest to gra o '
			dta b(123)
			dta b(81)
			dta d'czeniu poszatkowanych   '
			dta d'ryb w ca'
			dta b(123)
			dta d'o'
			dta b(87)
			dta b(86)
			dta d' za pomoc'
			dta b(81)
			dta d' je'
			dta b(88)
			dta d'd'
			dta b(88)
			dta b(81)
			dta d'cej rury.  '
			dta d'Zapami'
			dta b(68)
			dta d'taj kszta'
			dta b(123)
			dta d't ryby, poszukaj odpo- '
			dta d'wiednich cz'
			dta b(68)
			dta b(87)
			dta d'ci i z'
			dta b(123)
			dta b(80)
			dta b(88)
			dta d' ca'
			dta b(123)
			dta d'o'
			dta b(87)
			dta b(86)
			dta d' do kupy.  '
			dta d'W miar'
			dta b(68)
			dta d' post'
			dta b(68)
			dta d'pu prac czas na zapami'
			dta b(68)
			dta d'ta- '
			dta d'nie dok'
			dta b(123)
			dta d'adnego kszta'
			dta b(123)
			dta d'tu ulega skr'
			dta b(80)
			dta d'ceniu.'
			dta d'                                        '
			dta d'GAME-COMPO ENTRY for WAP-NIAK 2016 PARTY'*
			dta b(74)
			dta d'HELP'*
			dta b(74+128)
			dta d' - english version            v1.1'
			dta b($ff)	; End

; Initializes graphics subsystem
gfx_init
			; Setup display list
			ldx <dlist
			ldy >dlist
			stx SDLSTL
			sty SDLSTL+1

			jsr init_sprites
			jsr setup_colors
			rts
			
setup_colors
			; Border
			lda #$00
			sta COLOR4
			
			; Other elements
			lda #fish_color_0
			sta COLOR0
			lda #fish_color_1
			sta COLOR1
			lda #fish_color_2
			sta COLOR2
			
			rts

process_fishchain_state
			lda fcstate
			cmp #FC_STATIONARY
			beq pfcs_2
			cmp #FC_MOVINGLEFT
			bne pfcs_1
			jsr move_fish_chain_left
			rts
pfcs_1		cmp #FC_MOVINGRIGHT
			bne pfcs_0
			jsr move_fish_chain_right
			rts
pfcs_0		cmp #FC_DROPPING
			bne pfcs_2
			jsr drop_current_fish
pfcs_2		rts

; When fish part is being dropped
; this routine will draw an empty
; slot in the place of the fish
; part being dropped
draw_empty_fish_slot
			lda funnl_x
			sta drf_x
			lda #0
			sta drf_y
			mwa #empty_data ptr1
			jsr draw_data_rectangle
			rts
			
; Sets the ptr1 to indicate the fish
; part that is located above the funnel
; Additional:
; - Stores ptr0 also in tmp1/tmp2, because
;   the fish drawing routine will destroy
;   ptr0. The caller can restore it
;   from the temporary values
; - Stores the pointer to appropriate
;   fish chain data in ptr2, so at the end
;   of the movement it can be replaced with
;   empty fish block
prepare_correct_fish_data
			jsr funnel_pos_to_ptr
			sta tmp0
			mwa #tab_fishchain ptr0

			lda ptr0
			clc
			adc tmp0
			sta ptr0
			sta ptr2
			lda ptr0+1
			adc #0
			sta ptr0+1
			sta ptr2+1
			
			ldy #0
			lda (ptr0),y
			sta ptr1
			sta tmp1
			iny
			lda (ptr0),y
			sta ptr1+1
			sta tmp2
			rts

; Moves into the funnel the fish part
; that is located directly above it
drop_current_fish
			jsr draw_empty_fish_slot
			jsr prepare_correct_fish_data
			
			; Are we dropping an empty block?
			lda ptr1
			cmp #<empty_data
			bne dcf_1
			lda ptr1+1
			cmp #>empty_data
			bne dcf_1
			; Yes. Do not drop.
			lda #FC_STATIONARY
			sta fcstate
			rts
						
			; Now ptr1 = pointer to rectangle
			; data representing correct fish part			
dcf_1		lda funnl_x
			sta drf_x
			lda fishdry
			sta drf_y
:2			inc fishdry
			jsr draw_data_rectangle
			jsr draw_funnel
			jsr flip_screens
			
			; Is fish part down an the slot?
			lda fishdry
			cmp #slots_y+2
			bne dcf_0
			; Yes.
			jsr handle_fish_part_in_slot
dcf_0		rts

; Performs all actions that need to be
; executed after the fish part has been
; dropped into the slot
handle_fish_part_in_slot
			; Stop the movement
			lda #FC_STATIONARY
			sta fcstate
:2			dec fishdry
			
			; Recover ptr1 used to draw the rectangle
			; from temporary values
			lda tmp1
			sta ptr1
			lda tmp2
			sta ptr1+1
			
			; Draw funnel
			lda funnl_x
			sta drf_x
			lda fishdry
			sta drf_y
			jsr draw_data_rectangle
			jsr flip_screens		
			
			; Once again, recover ptr1
			; from temporary values
			lda tmp1
			sta ptr1
			lda tmp2
			sta ptr1+1

			; Setup pointers in chain and in slots
			jsr adapt_for_empty_block
			jsr adapt_dropped_fish
			
			; Check if fish is completed
			jsr check_fish_completion
			cpx #0
			beq hfpis_1
			
			; Validate constructed fish
			jsr validate_fish
			cpx #0
			beq hfpis_0
			
			; The fish is good
			jsr good_fish
			rts

hfpis_0		jsr bad_fish				
hfpis_1		rts

; Draws the image of the bad fish
draw_bad_fish
			lda #0
			sta drf_x
			lda #funnel_y
			sta drf_y
			mwa #badfish_data ptr1
			jsr draw_data_rectangle
			rts
			
; Draws the image of the good fish
draw_good_fish
			lda #0
			sta drf_x
			lda #funnel_y
			sta drf_y
			mwa #goodfish_data ptr1
			jsr draw_data_rectangle
			rts
			
; Called when constructed fish is incorrect
bad_fish
			jsr stop_music
			dec lives
			jsr draw_bad_fish
			jsr flip_screens
			jsr wait_for_fire
			
			lda lives
			cmp #0
			beq bf_0
			
			; Still more lives
			jsr draw_lives
			jsr flip_screens
			jsr draw_lives
			
			jsr initialize_target_fish
			lda #GS_CUNTDOWN
			sta gstate
			rts
			
bf_0		; No more lives
			jsr handle_game_over		
			rts
			
; Called when constructed fish is correct
good_fish
			jsr stop_music
			inc level
			jsr draw_good_fish
			jsr flip_screens
			jsr wait_for_fire
			
			lda level
			cmp #level_count+1
			beq gf_0
			
			; Still more levels
			jsr draw_level
			jsr draw_lives
			jsr flip_screens
			jsr draw_level
			jsr draw_lives
			
			jsr initialize_target_fish
			lda #GS_CUNTDOWN
			sta gstate
			rts
			
gf_0		; No more levels
			jsr handle_congrats
			rts
			
; Performs all actions required to handle
; the finished game process
handle_congrats
			lda #GS_GAME_OVER
			sta gstate
			
			mwa #scr_size ptr2
			lda #$ff
			jsr fill_screen
			jsr draw_congrats
			
			; Set appropriate colors
			lda #congra_color_0
			sta COLOR0
			lda #congra_color_1
			sta COLOR1
			lda #congra_color_2
			sta COLOR3
			lda #congra_color_bg
			sta COLOR2
			
			; Hide tool
			lda #0
			sta HPOSP0
			sta HPOSP1
			
			jsr flip_screens
			
			rts

; Performs all actions required to handle
; the game over process			
handle_game_over
			lda #GS_GAME_OVER
			sta gstate
			
			mwa #scr_size ptr2
			lda #$ff
			jsr fill_screen
			jsr draw_busted
			
			; Set appropriate colors
			lda #busted_color_0
			sta COLOR0
			lda #busted_color_1
			sta COLOR1
			lda #busted_color_2
			sta COLOR3
			lda #busted_color_bg
			sta COLOR2
			
			; Hide tool
			lda #0
			sta HPOSP0
			sta HPOSP1
			
			jsr flip_screens
			
			rts
			
; Fills the screen with the byte
; stored in A
; Precondition:
; - "ptr2" stores the count of bytes
;   that should be cleared
fill_screen
			sta tmp0
			
			mwa #0 ptr1
			mwa pnscr ptr0
			
fs_1		lda tmp0
			ldy #0
			sta (ptr0),y
			adw ptr0 #1
			inw ptr1
			
			#if .word ptr1 = ptr2
				jmp fs_0
			#end
			jmp fs_1
			
fs_0		rts
						
; Draws the "BUSTED" message
draw_busted
			ldx #busted_count
			lda #(scr_rowsize-(busted_width/fishpxperb))/2
			sta drf_x
			pha
			lda #funnel_y
			sta drf_y
			mwa #busted_data ptr1
db_3		jsr draw_data_rectangle

			dex
			cpx #0
			beq db_0
			pla
			clc
			adc #fishbperrow
			sta drf_x
			pha
			jmp db_3
db_0		pla
			rts
			
; Draws the "CONGRATS" message
draw_congrats
			ldx #congrats_count
			lda #0
			sta drf_x
			pha
			lda #funnel_y
			sta drf_y
			mwa #congrats_data ptr1
dc_3		jsr draw_data_rectangle

			dex
			cpx #0
			beq dc_0
			pla
			clc
			adc #fishbperrow
			sta drf_x
			pha
			jmp dc_3
dc_0		pla
			rts

; Draws the title fish
draw_title_fish
			ldx #titlefish_count
			lda #(scr_rowsize-(titlefish_width/fishpxperb))/2
			sta drf_x
			pha
			lda #0
			sta drf_y
			mwa #titlefish_data ptr1
dtf_3		jsr draw_data_rectangle

			dex
			cpx #0
			beq dtf_0
			pla
			clc
			adc #fishbperrow
			sta drf_x
			pha
			jmp dtf_3
dtf_0		pla
			rts
			
			
; Waits until the joystick button is pressed
wait_for_fire
@			lda STRIG0
			cmp #1
			beq @-
			rts

; Checks whether slots are filled
; with correct fish parts
; Retrun:
;	X = 0 - fish not valid
;	X = 1 - fish valid
validate_fish
			ldx #0
.rept fishslot_len, #*2
			#if .word tab_fishslots+:1 <> tab_fishguidelines+:1
				rts
			#end
.endr
			inx
			rts
			
; Checks whether all slots are filled
; with fish parts.
; Retrun:
;	X = 0 - fish not completed
;	X = 1 - fish completed
check_fish_completion
			ldx #0		
			; If any slot is empty
			; fish is not completed
.rept fishslot_len, #*2
			#if .word tab_fishslots+:1 = #empty_data
				rts
			#end
.endr
			inx
			rts

; Converts funnel position
; to the array index
funnel_pos_to_ptr
			lda funnl_x
			lsr
			lsr
			rts

; Fills the appropriate slot with the
; fish that has been dropped into it
; Precondition:
; - "ptr1" still valid (pointing to fish
;   part being dropped)
adapt_dropped_fish
			jsr funnel_pos_to_ptr
			sec
			sbc #2	; Skip position #0 since
					; it is not used in slots
			tay
			
			lda ptr1
			sta tab_fishslots,y
			iny
			lda ptr1+1
			sta tab_fishslots,y
			
			rts

; At the end of the fish drop
; this routine modifies the content
; of the fish chain (it inserts
; the pointer to empty block in the
; correct pleace, precalculated in ptr2)
adapt_for_empty_block
			ldy #0
			lda #<empty_data
			sta (ptr2),y
			iny
			lda #>empty_data
			sta (ptr2),y
			rts

process_tool_state
			lda tstate
			cmp #TS_STATIONARY
			beq pts_0
			cmp #TS_MOVING_DOWN
			bne pts_1
			jsr move_tool_down
			rts
pts_1		cmp #TS_MOVING_UP
			bne pts_0
			jsr move_tool_up
pts_0		rts

process_funnel_state
			lda fstate
			cmp #FU_STATIONARY
			beq pfs_0
			cmp #FU_MOVINGLEFT
			bne pfs_1
			jsr move_funnel_left
			rts
pfs_1		cmp #FC_MOVINGRIGHT
			bne pfs_0
			jsr move_funnel_right
pfs_0		rts

move_funnel_left		
			jsr is_funnel_movement_finished
			dec funnl_x
			
			inc erase_r
			jsr draw_funnel
			jsr flip_screens
			jsr draw_funnel
			dec erase_r
			
			rts

move_funnel_right
			jsr is_funnel_movement_finished
			inc funnl_x
			
			inc erase_l
			jsr draw_funnel
			jsr flip_screens
			jsr draw_funnel
			dec erase_l
			
			rts

move_tool_up
			ldx #0
			lda tool_y
			clc
			adc #2
			tay
@			lda pmg_p0,y
			dey
			sta pmg_p0,y
			iny
			lda pmg_p1,y
			dey
			sta pmg_p1,y
			iny
			iny
			inx
			cpx #tool_height+1
			bne @-
			
			dec tool_y
			
			; At the top?
			lda tool_y
			cmp #tool_init_y-2
			bne mtu_0			; No
			lda	#TS_STATIONARY	; Yes
			sta tstate
			
mtu_0		rts

move_tool_down
			lda tool_y
			clc
			adc #tool_height
			tay
			iny
@			lda pmg_p0,y
			iny
			sta pmg_p0,y
			dey
			lda pmg_p1,y
			iny
			sta pmg_p1,y
			dey
			dey
			cpy tool_y
			bne @-

			inc tool_y
		
			; At the bottom?
			lda tool_y
			cmp #tool_at_bottom
			bne mtd_0			; No
			lda	#TS_STATIONARY	; Yes
			sta tstate
			
mtd_0		rts

; Short delay used during countdown
countdown_delay
			lda #count_delay
			sta delayt
			lda #0
			sta delayt2
			jsr delay
			rts

; Shows the countdown sequence
process_countdown
			jsr countdown_delay
.rept number_count, 3-#, #*2
			jsr play_lo_beep
			mwa #numbitmap_:1 tab_fishslots+:2
			jsr draw_fish_slots
			jsr flip_screens
			jsr countdown_delay
.endr
			lda #GS_GUIDELINES
			sta gstate
			rts
			
; Pauses for the amount of time
; appropriate to the current level
provide_guidelines_delay
			ldy level
			dey
			lda delay_tab_1,y
			sta delayt
			lda delay_tab_0,y
			sta delayt2
			jsr delay

			; Clear accidental key presses
			; made during waiting time
			lda #$ff
			sta CH
			
			rts
			
delay_tab_0
:level_count			dta b(level_delay_inc*(level_count-#)/256)
delay_tab_1
:level_count			dta b(level_delay_inc*(level_count-#)-((level_delay_inc*(level_count-#)/256)*256))
		
; Shows the fish to be constructed
process_guidelines
			ldy #0
pg_0		lda tab_fishguidelines,y
			sta tab_fishslots,y
			iny
			cpy #(fishslot_len*2)
			bne pg_0
			
			jsr draw_fish_slots
			jsr flip_screens
		
			jsr play_hi_beep
			jsr provide_guidelines_delay
			
			; Hide the guidelines
:fishslot_len	mwa #empty_data tab_fishslots+#*2
			jsr draw_fish_slots
			jsr flip_screens
			jsr draw_fish_slots
			
			; Begin construction
			jsr play_game_music
			lda #GS_CONSTRUCTION
			sta gstate
			
			rts

; Processes all machine states
; used during the game
process_game_state
			lda CH
			cmp #$1c	; ESC
			bne pgs_4
			
			; Returning to the title screen

			; Clear stack, so we can jmp out
			; and start from scratch
			pla
			pla
			pla
			pla
			
			; Hide tool
			lda #0
			sta HPOSP0
			sta HPOSP1

			jmp run_again

pgs_4		lda gstate
			cmp #GS_CUNTDOWN
			bne pgs_0
			jsr process_countdown
			rts
			
pgs_0		cmp #GS_CONSTRUCTION
			bne pgs_1
			jsr process_fishchain_state
			jsr process_tool_state
			jsr process_funnel_state
			rts
			
pgs_1		cmp #GS_GUIDELINES
			bne pgs_2
			jsr process_guidelines
			rts

pgs_2		cmp #GS_GAME_OVER
			bne pgs_3
			jsr process_game_over
pgs_3		rts

; Waits for fire and returns to title screen
process_game_over
			jsr wait_for_fire
			
			; Clear stack, so we can jmp out
			; and start from scratch
			pla
			pla
			pla
			pla
			pla
			pla
			
			jmp run_again
			
game_init_common_tasks
			mwa #scr_size ptr2
			lda #$00
			jsr fill_screen
			jsr draw_fish_chain
			jsr draw_fish_slots
			jsr draw_funnel
			jsr draw_level
			jsr draw_lives
			rts

game_init
			; Variables
			lda #funnel_init_x
			sta funnl_x
			lda #0
			sta erase_l
			sta erase_r
			lda #1
			sta level
			lda #lives_count
			sta lives
			
			; Initial position and colors
			lda #tool_init_x
			sta HPOSP0
			clc
			adc #tool_apart
			sta HPOSP1
			lda #tool_color
			sta PCOLR0
			sta PCOLR1			
			
			; Fish species to be built
			jsr initialize_target_fish
			
			; Reset empty slots
:fishslot_len	mwa #empty_data tab_fishslots+#*2

			; Draw initial graphics
			; on both screens
			jsr randomize_fish_chain
			jsr game_init_common_tasks
			jsr flip_screens
			jsr game_init_common_tasks
			
			; Setup state machines
			lda #FC_STATIONARY
			sta fcstate
			lda #GS_CUNTDOWN
			sta gstate
			lda #TS_STATIONARY
			sta tstate
			lda #FU_STATIONARY
			sta fstate
						
			rts
			
; Draws the tile with level number
draw_level
			mwa #level_data ptr1
			ldx level
dl_1		dex
			cpx #0
			beq dl_0
			adw ptr1 #fishsize
			jmp dl_1
dl_0		lda #0
			sta drf_x
			lda #slots_y
			sta drf_y
			jsr draw_data_rectangle
			rts

; Draws the lives indicator
draw_lives
			mwa #lives_data ptr1
			ldx lives
dli_1		dex
			cpx #0
			beq dli_0
			adw ptr1 #fishsize
			jmp dli_1
dli_0		lda #0
			sta drf_x
			lda #funnel_y
			sta drf_y
			jsr draw_data_rectangle
			rts
			
; Calls "prepare_target_fish" for each part
initialize_target_fish
.rept fishparts, #, #*2
			mwa #fishparts_:1 ptr0
			ldy #:2
			jsr prepare_target_fish
.endr
			rts

; Randomizes each part of the target fish
; Precondition:
; - "ptr0" contains the base of the fish
;   part to be generated
; - Y contains the target pointer offset
;   where generated fish should be stored
prepare_target_fish
			; Put random number [0 to 4] in X
			lda RANDOM
			and #%00111111
			tax
			lda prepare_fish_lut,x
			tax
			
			; Apply random shift to the offset
ptf3		cpx #0
			beq ptf1
			adw ptr0 #fishsize
			dex
			jmp ptf3
			
ptf1		; Store in appropriate pointer
			mwa ptr0 tab_fishguidelines,y
			rts
			
; LUT for fast fish randomization
prepare_fish_lut
:$100/2/2	dta(#%fishtpspprt)
			
init_sprites
			lda #>pmg_base
			sta PMBASE
			lda #%00000001
			sta GPRIOR
			lda #%00000011
			sta GRACTL
			lda SDMCTL
			ora #%00011100
			sta SDMCTL			
			lda #0
			sta SIZEP0
			sta SIZEP1
			rts
			
draw_funnel
			mwa #funnel_data ptr1
			lda funnl_x
			sta drf_x
			lda #funnel_y
			sta drf_y
			jsr draw_data_rectangle
			rts

; Flips the screen buffer			
flip_screens
			jsr synchro

			lda pscr
			pha
			lda pscr+1
			pha
			lda pnscr
			sta pscr
			sta scr_mem_antic
			lda pnscr+1
			sta pscr+1
			sta scr_mem_antic+1
			pla
			sta pnscr+1
			pla
			sta pnscr

			rts

game_loop
			jsr process_game_state
			
			lda STICK0
			sta ATRACT
			cmp #7
			beq	stick_right
			lda STICK0
			cmp #11
			beq stick_left
			lda STICK0
			cmp #13
			beq stick_down
			lda STICK0
			cmp #14
			beq stick_up
			lda STRIG0
			cmp #0
			beq button_down
			jmp game_loop
stick_right
			jsr stick_moved_right
			jmp game_loop
stick_left
			jsr stick_moved_left
			jmp game_loop
stick_down
			jsr init_tool_move_down
			jmp game_loop
stick_up
			jsr init_tool_move_up
			jmp game_loop
button_down
			jsr init_fish_drop
			jmp game_loop
			
init_fish_drop
			; Fish chain must be stopped
			lda fcstate
			cmp #FC_STATIONARY
			bne ifd_0
			; Funnel must be stopped
			lda fstate
			cmp #FU_STATIONARY
			bne ifd_0

			lda #FC_DROPPING
			sta fcstate
			lda #2
			sta fishdry
ifd_0		rts
			
stick_moved_left
			; Tool at the bottom?
			lda tool_y
			cmp #tool_at_bottom
			bne sml_0			; No
			; Yes - check if funnel can move further
			lda funnl_x
			cmp #funnel_at_left
			beq sml_1
			; Check if fish part is not being dropped
			lda fcstate
			cmp #FC_STATIONARY
			bne sml_1
			
			lda #FU_MOVINGLEFT	
			sta tmp0
			jsr init_funnel_move
sml_1		rts
sml_0		lda #FC_MOVINGLEFT
			sta tmp0
			jsr init_fish_chain_move
			rts
			
stick_moved_right
			; Tool at the bottom?
			lda tool_y
			cmp #tool_at_bottom
			bne smr_0			; No
			; Yes - check if funnel can move further
			lda funnl_x
			cmp #funnel_at_right
			beq smr_1
			; Check if fish part is not being dropped
			lda fcstate
			cmp #FC_STATIONARY
			bne smr_1

			lda #FU_MOVINGRIGHT			
			sta tmp0
			jsr init_funnel_move
smr_1		rts
smr_0		lda #FC_MOVINGRIGHT
			sta tmp0
			jsr init_fish_chain_move
			rts
			
init_tool_move_down
			; Don't move if at the bottom
			lda tool_y
			cmp #tool_at_bottom
			beq itmd_0
			; Don't move if fish chain is moving
			lda fcstate
			cmp #FC_STATIONARY
			bne itmd_0
			lda #TS_MOVING_DOWN
			sta tstate
itmd_0		rts
			
init_tool_move_up
			; Don't move if at the top
			lda tool_y
			cmp #tool_init_y-2
			beq itmu_0
			; Don't move if fish chain is moving
			lda fcstate
			cmp #FC_STATIONARY
			bne itmu_0
			lda #TS_MOVING_UP
			sta tstate
itmu_0		rts
			
; Fills the initial fish chain
; with random fish-parts
randomize_fish_chain			
			mwa #tab_fishchain ptr1

			ldx #fishchain_len
			
rfc_1		jsr pick_random_fish_part
			ldy #0
			mwa ptr0 (ptr1),y
			dex
			cpx #0
			beq rfc_0
			adw ptr1 #2
			jmp rfc_1
						
rfc_0		jsr randomize_approaching_fish_segment
			rts
	
; Randomly picks the new fish segment
; to be scrolled in into the chain	
randomize_approaching_fish_segment
			jsr pick_random_fish_part
			mwa ptr0 tab_fish_random
			rts
			
; Picks one random fish part
; and points "ptr0" to it
pick_random_fish_part
			ldy RANDOM
			lda random_fish_chain_table,y
			tay
			mwa #fishdata ptr0
prfp_1		cpy #0
			beq prfp_0
			adw ptr0 #fishsize
			dey
			jmp prfp_1		
prfp_0		rts

; Helper for randomizing the fish chain
random_fish_chain_table
:$100		dta b(:1 % fishestotal)

; Modifies the fishchain data pointers
; to reflect situation after movement
adapt_fish_chain_data
			lda tmp0
			cmp #FC_MOVINGLEFT
			bne afcd_0
			
			; Adapt to the left
:fishchain_len-1	mwa tab_fishchain+#*2+2 tab_fishchain+#*2
					mwa tab_fish_random tab_fishchain+((fishchain_len-1)*2)
			
			rts
afcd_0		; Adapt to the right
:fishchain_len-1	mwa tab_fishchain+(((fishchain_len-2)-#)*2) tab_fishchain+(((fishchain_len-2)-#)*2)+2
					mwa tab_fish_random tab_fishchain

			rts

; Inits the move of a fish chain
; accordingly to the content of "tmp0" (direction)
init_fish_chain_move
			lda fcstate
			cmp #FC_STATIONARY
			bne ifcml_0
			jsr adapt_fish_chain_data
			lda #(0-1)
			sta fishmov
			lda #0
			sta ffeedof
			lda tmp0
			sta fcstate
ifcml_0		rts

; Inits the move of a funnel
; accordingly to the content of "tmp0" (direction)
init_funnel_move
			lda fstate
			cmp #FU_STATIONARY
			bne ifm_0
			lda #(0-1)
			sta fishmov
			lda tmp0
			sta fstate
ifm_0		rts

move_fish_chain_right
			jsr is_movement_finished
			
			; Continue moving
mfcr_3		lda #0
			sta tmp0
			mwa pscr ptr0
			mwa pnscr ptr2
			ldx #0
mfcr_1		ldy #(scr_rowsize-2)
mfcr_0		lda #0
			lda (ptr0),y
			iny
			sta (ptr2),y
			dey
			dey
			cpy #(0-1)
			bne mfcr_0
			inx
			cpx #fishdimy
			beq mfcr_2
			adw ptr0 #scr_rowsize
			adw ptr2 #scr_rowsize
			jmp mfcr_1
mfcr_2		
			; Feed newly appearing column with
			; data of the random fish
			mwa pnscr ptr0
			mwa tab_fish_random ptr1
			
			ldx ffeedof
mfcr_7		cpx #0
			beq mfcr_6
			sbw ptr1 #1
			dex
			jmp mfcr_7
			
mfcr_6		ldx #0
mfcr_5		ldy #(fishbperrow-1)
			lda (ptr1),y
			ldy #0
			sta (ptr0),y
			inx
			cpx #fishdimy
			beq mfcr_4
			jsr modify_fish_chain_movement_pointers
			jmp mfcr_5
		
mfcr_4		inc ffeedof

			jsr flip_screens

			rts
			
move_fish_chain_left
			jsr is_movement_finished
			
			; Continue moving
mfcl_3		lda #0
			sta tmp0
			mwa pscr ptr0
			mwa pnscr ptr2
			ldx #0
mfcl_1		ldy #1
mfcl_0		lda (ptr0),y
			dey
			sta (ptr2),y
			iny
			iny
			cpy #scr_rowsize
			bne mfcl_0
			inx
			cpx #fishdimy
			beq mfcl_2
			adw ptr0 #scr_rowsize
			adw ptr2 #scr_rowsize
			jmp mfcl_1
mfcl_2		
			; Feed newly appearing column with
			; data of the random fish			
			mwa pnscr ptr0
			adw ptr0 #(scr_rowsize-1)
			mwa tab_fish_random ptr1
			
			ldx ffeedof
mfcl_7		cpx #0
			beq mfcl_6
			adw ptr1 #1
			dex
			jmp mfcl_7
			
mfcl_6		ldx #0
mfcl_5		ldy #0
			lda (ptr1),y
			sta (ptr0),y
			inx
			cpx #fishdimy
			beq mfcl_4
			jsr modify_fish_chain_movement_pointers
			jmp mfcl_5
		
mfcl_4		inc ffeedof
			
			jsr flip_screens

			rts
			
; If full move of the funnel is finished
; this routine will move to next state
is_funnel_movement_finished
			inc fishmov
			lda fishmov
			cmp #fishbperrow
			bne ifmf_0
			
			lda #FU_STATIONARY
			sta fstate
			pla
			pla
			
			; Make sure funnel position
			; is consistent over two
			; screens
			jsr draw_funnel
			jsr flip_screens
			
ifmf_0		rts
		
; If full move-segment of the fish chain is finished
; this routine will move to next state
is_movement_finished
			inc fishmov
			lda fishmov
			cmp #fishbperrow
			bne @+
			; Segment moved
			lda #FC_STATIONARY
			sta fcstate
			jsr randomize_approaching_fish_segment

			jsr draw_fish_chain
			jsr flip_screens
			
			pla
			pla
			
			; Continue moving
@			rts

modify_fish_chain_movement_pointers
			adw ptr1 #fishbperrow
			adw ptr0 #scr_rowsize
			rts

; Draws the entire fish chain
; accordingly to the "tab_fishchain" content
draw_fish_chain
			; tmp3 stores the Y-position of the
			; chain. Required by "draw_chains_internal"
			lda #0
			sta tmp3
			
			mwa #(tab_fishchain-2) ptr2
			lda #(fishchain_x-8)
			sta tmp1
			
			lda #fishchain_len
			jsr draw_chains_internal
			
			rts

; Array of pointers representing
; the current content of the fish chain
tab_fishchain
:fishchain_len	dta a($0000)
; Random fish part that will be spawned
; when fish chain is moved
tab_fish_random
				dta a($0000)

; Draws the full set of fish slots
draw_fish_slots
			; tmp3 stores the Y-position of the
			; chain. Required by "draw_chains_internal"
			lda #fishslot_y
			sta tmp3

			mwa #(tab_fishslots-2) ptr2
			lda #(fishslot_x-8)
			sta tmp1
			
			lda #fishslot_len
			jsr draw_chains_internal
				
			rts

; Array of pointers representing
; the current content of the fish slots
tab_fishslots
:fishslot_len	dta a($0000)
; Array of pointers representing
; the target fish species to be built
tab_fishguidelines
:fishslot_len	dta a($0000)

; Helper routine used by
; "draw_fish_chain" and "draw_fish_slots".
; Iterates through pointers to rectangles
; and draws them at the specified position
draw_chains_internal
			sta tmp2
@			adw ptr2 #2
			lda tmp1
			clc
			adc #fishbperrow
			sta tmp1
			sta drf_x
			lda tmp3
			sta drf_y
			ldy #0
			lda (ptr2),y
			sta ptr1
			iny
			lda (ptr2),y
			sta ptr1+1
			jsr draw_data_rectangle

			dec tmp2
			lda tmp2
			cmp #0
			bne @-
			rts

; Initializes the source rectangle data pointer
; accordinlgy to the selected y-location.
; Preservers "ptr1"
draw_data_rectangle_initpos
			lda ptr1
			pha
			lda ptr1+1
			pha

			; Tables with Y-coordinates
			; are located directly after
			; the screen memory
			mwa pnscr ptr1
			adw ptr1 #scr_size

			lda drf_y
			asl
			tay
			lda (ptr1),y
			sta ptr0
			iny
			lda (ptr1),y
			sta ptr0+1
			
			pla
			sta ptr1+1
			pla
			sta ptr1
			rts
			
			
; Draws a data rectangle on the specified location
;	drf_x	- Horizontal position	(4 pixels precision)
;	drf_y	- Vertical position		(1 pixel precision)
;	ptr1	- Pointer to rectangle data
;	erase_r - Should the rightmost column be erased?
;	erase_l - Should the leftmost column be erased?
draw_data_rectangle
			mva #0 cntr0
			jsr draw_data_rectangle_initpos
		
ddr_1		ldy #0
ddr_0		lda (ptr1),y
			sty tmp0
			ldy drf_x
			sta (ptr0),y
			inc drf_x
			ldy tmp0
			iny
			cpy #fishbperrow
			bne ddr_0
			
			; Erase rightmost column if necessary
			lda erase_r
			cmp #0
			beq ddr_4
			lda #0
			ldy drf_x
			sta (ptr0),y

			; Erase leftmost column if necessary
ddr_4		lda erase_l
			cmp #0
			beq ddr_3
			lda drf_x
			sec
			sbc #fishbperrow+1
			tay
			lda #0
			sta (ptr0),y 
			
ddr_3		adw ptr0 #scr_rowsize
			adw ptr1 #fishbperrow
			inc cntr0
			lda cntr0
			cmp #fishdimy
			bne ddr_2			
			rts
ddr_2		lda drf_x
			sec
			sbc #fishbperrow
			sta drf_x
			jmp ddr_1

delay
			inc CDTMF4
			lda delayt
			sta CDTMV4
			lda delayt2
			sta CDTMV4+1
@			lda CDTMF4
			bne @-
			rts
			
synchro
			lda PAL
			cmp #1
			bne synchr1
			lda #145	; PAL
			jmp synchr2
synchr1 	lda #120	; NTSC
synchr2		cmp VCOUNT
			bne synchr2
			rts
			
vbi_routine
			lda silence
			cmp #0
			bne @+
			jsr RASTERMUSICTRACKER+3
@			jmp XITVBV
			
stop_music
			lda #1
			sta silence
			jsr RASTERMUSICTRACKER+9
			rts
			
play_music_common
			lda #0
			sta silence
			ldx #<MODUL
			ldy #>MODUL
			rts
			
play_lo_beep
			jsr play_music_common
			lda #05
			jsr RASTERMUSICTRACKER	;Init
			rts

play_hi_beep
			jsr play_music_common
			lda #$0d
			jsr RASTERMUSICTRACKER	;Init
			rts

play_title_music
			jsr play_music_common
			lda #07
			jsr RASTERMUSICTRACKER	;Init
			rts

play_game_music
			jsr play_music_common
			lda #00
			jsr RASTERMUSICTRACKER	;Init
			rts

play_error_music
			jsr play_music_common
			lda #$0f
			jsr RASTERMUSICTRACKER	;Init
			rts
			
; Align to 2k for single-line resolution sprites
.align		$800
pmg_base
:$800			dta b(0)
pmg_p0			equ pmg_base+$400
pmg_p1			equ pmg_base+$500
pmg_p2			equ pmg_base+$600
pmg_p3			equ pmg_base+$700

			org pmg_p0+tool_init_y
:2			dta b(15)
:2			dta b(31)
:56			dta b(48)
:2			dta b(31)
:2			dta b(15)
			org pmg_p1+tool_init_y
:2			dta b(240)
:2			dta b(248)
:56			dta b(12)
:2			dta b(248)
:2			dta b(240)

.align		$400
dlist
:3			dta b($70)
			dta b($4d)
scr_mem_antic
			dta a($0000)
:95			dta	b($0d)
			dta b($41),a(dlist)
dlist_title
:2			dta b($70)
			dta b($f0)			; DLI - before fish (VCOUNT=$0f)
			dta b($4d)
			dta a(scr_mem_1)
:6			dta	b($0d)
			dta b($8d)			; DLI - shades of water (VCOUNT=$17)
:6			dta	b($0d)
			dta b($8d)			; DLI - shades of water (VCOUNT=$1e)
:6			dta	b($0d)
			dta b($8d)			; DLI - shades of water (VCOUNT=$25)
:10			dta	b($0d)
			dta b($f0)			; DLI - before title line (VCOUNT=$33)
			dta b($87)			; DLI - before title separator (VCOUNT=$3b)
			dta b($82)			; DLI - before first subtitle (VCOUNT=$3f)
			dta b($86)			; DLI - before second subtitle (VCOUNT=$43)
			dta b($06)
			dta b($f0)			; DLI - before text (VCOUNT=$4b)
:5			dta b($02)
			dta b($82)			; DLI - after last text line (VCOUNT=$63)
			dta b($02)			
			dta b($02)
			dta b($02)
			dta b($41),a(dlist)
			
MODUL		equ $a100
			org MODUL
			opt h-
			ins "music/musA100.rmt"
			opt h+
			
MUSICPLAYER	equ $b000
			org MUSICPLAYER
			icl "rmtplayr.a65"
			
clear_decrunch_panel
			mwa #scr_mem_1+scr_rowsize*fishdimy ptr0
			mwa #0 ptr1
			
			ldy #0
cdp_0		lda #0
			sta (ptr0),y
			adw ptr0 #1
			adw ptr1 #1
			
			lda ptr1+1
			cmp #1
			bne cdp_0
			lda ptr1
			cmp #204
			bne cdp_0
			
			rts
			
write_decrunch_line
			adw ptr0 tmp0
			ldy #0
wdl_1		lda (ptr2),y
			cmp #$9b
			beq wdl_0
			sta (ptr0),y
			iny
			jmp wdl_1
wdl_0		rts
			
decrunching
			inc crunched
			
			jsr play_game_music
			
			; Init DLI
			lda <decrunch_dli_routine
			sta VDSLST
			lda >decrunch_dli_routine
			sta VDSLST+1
			lda #%11000000
			sta NMIEN

			jsr clear_decrunch_panel

			jsr enable_antic
			mwa #scr_mem_1+scr_rowsize*fishdimy ptr0
			
			; Draw decrunching text and initial progress bar
			mwa #text_decrunch ptr2
			mva #113 tmp0
			jsr write_decrunch_line
			
			; Paint decrunching progrsss
			mwa #text_decrunch_progress ptr2
			mva #71 tmp0
			jsr write_decrunch_line

			; Animate progress
			ldx #0
			ldy #1
dec_4		lda #94
			sta (ptr0),y
			jsr very_short_delay
			iny
			inx
			cpx #7
			beq	dec_5
			cpx #12
			beq dec_5
			cpx #21
			beq dec_5
			cpx #30
			beq dec_6
			cpx #44
			beq dec_7
			jmp dec_4
dec_5
:2			jsr short_delay
			jmp dec_4
			
dec_6
:4			jsr short_delay
			jmp dec_4
dec_7
:4			jsr short_delay
			
			; Draw error text
			ldx #0
			ldy #76
dec_9		lda text_chuj,x
			cmp #$9b
			beq dec_8
			sta (ptr0),y
			iny
			inx
			jmp dec_9
dec_8		
			jsr play_error_music
:3			jsr short_delay
			jsr stop_music

			; Back to the normal program
			jsr disable_antic
:6			jsr short_delay
			rts

text_decrunch
			dta	d"Decrunching...",b($9b)
text_decrunch_progress
			dta	b(92)
:30			dta b(93)
			dta b(95)
			dta b($9b)
text_chuj
			dta	d" ERROR W CHUJ !!! "*,b($9b)

; Fit font into unused space of PMG memory			
			org pmg_base
			ins "font.fnt"
			
			; Start with polish version
			org english
			dta b(0)

			; Init tool position on load only
			org tool_y
			dta b(tool_init_y-2)

			org RUNAD
			dta a(run_here)
