;This patch adds a second dimension of shacking the level (rather than straight up
;and down) as well as shacking at random positions when you set $1887.

;Notes

;-For some reason, bounce sprites and spinning coin from bounce sprites
; wraps the screen should their spawn point be at [$0100 = BounceSpriteYpos - ScreenYpositionDisplaced],
; despite a check at $029215 and a hijack at $029A1D.
;-This patch modifies the bottomless pit as well as the screen barrier that the player interacts with, thus such patches
; like "Pit fix" and "Disable screen barrier via RAM" can cause glitches. See the readme on how to fix this.
;-Lunar Magic version 3.00 and later modifies 38 bytes at $00A2AF, make sure you patch the "level dimension patch" in
; lunar magic by going into "Change Properties in Header" and changing the dimensions to any other than default, then
; save before installing this patch. If you are using earlier versions before 3.00, don't worry.
;-The glitter sprite still wraps, this by the way is the smoke sprite table. They do not have a high byte
; XY coordinates.
;-The layer loading tiles as the screen move doesn't react to the moved screen is INTENTIONAL, to prevent garbage tiles
; being loaded WITHIN the level boundaries when the screen goes past the top and left edges in horizontal levels.
; this method now renders garbage ONLY outside the level boundaries during a screen shake. As a side effect even not being
; at the edge of levels can still generate garbage tiles, but only a small fraction of the tiles are to be visible on the
; edge of the screen.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA1 detector:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	!dp = $0000
	!addr = $0000
	!sa1 = 0
	!gsu = 0

if read1($00FFD6) == $15
	sfxrom
	!dp = $6000
	!addr = !dp
	!gsu = 1
elseif read1($00FFD5) == $23
	sa1rom
	!dp = $3000
	!addr = $6000
	!sa1 = 1
endif

;Freeram
 if !sa1 == 0
  !Freeram_DirQuake_Layer1XDisplacement		= $60
 else
  !Freeram_DirQuake_Layer1XDisplacement		= $60
 endif
  ;^[2 bytes], same as $1888 but for X position displacement. Without this
  ; displacement ram address, sprite positions will appear also "displaced", not
  ; syncing with layer 1 (like appearing that their foot goes partially through the floor).
;Settings
 !Setting_DirQuake_OffLevelEdgeProtect		= 0
  ;^This setting is an option to disable layer 1 tile loading glitches when the screen displaces
  ; beyond the left and right edges of the level. This is done by preventing the screen itself
  ; from having such X position.
  ;^0 = off (glitched tiles appear on edges of screen).
  ; 1 = on (no glitched tiles appear), note that if you have a level 1 screen wide in a
  ; horizontal level, the screen will only move up and down.
 !Setting_DirQuake_DebugMode		= 0
  ;^0 = off (everything is normal)
  ; 1 = once $1887 is set, it won't decrement itself to zero, the quake will "freeze", and you
  ;     can control the displacement via holding SELECT + <D-pad direction>.
  ; 2 = will constantly shake the screen normally but will do endlessly once $1887 is set.
  ;
  ;If you find any glitches associated when codes check the screen coordinates (for example,
  ;sprites that assume the screen has been moved by the coordinates), use a debugger and
  ;breakpoint the code where it checks the position, and look at the memory viewer to check
  ;$1A-$1C AND $1462-$1464 (each are 2 bytes).
  ;
  ;To nullify the displacement so they don't react to moved screen, simply have the layer
  ;position, subtract that by the displacement value. Do that on both X and Y coordinates.
 
 !Setting_ApplyScrnBarrierToPlayer		= 1
  ;^0 = don't apply a no-quake for screen barrier
  ; 1 = do apply
  ;This is if you have patched any of the following that causes hijack conflicts:
  ; -Pit fix
  ; -Disable screen barrier via RAM
  ;into your hack. Be careful that patching when this is applied, then reinstalling this
  ;patch with this turned off DOES NOT undo the changes, as this was intentional with the
  ;conflicts with the other patch. I suggest using "Level constrain" instead of "Pit fix":
  ;https://www.smwcentral.net/?p=section&a=details&id=15747
  ;
  ;However if you NEED the disable screen barrier, set this to 0, and try moving the codes
  ;to those such patches.

 ;Scratch RAM due to LM eating a bunch at $02a826. Use only 1-byte addressing. So far during
 ;my testing $00 to $01 are not safe to use. These are present in the case in the future LM
 ;updates again and ends up using more scratch RAM. At the moment, you don't need to edit this
 ;until a bug happens at $02A7FC (labeled "LoadSprFromLevel:")in the future.
 !Scratchram_DirectionalQuake_1A		= $02
  ;^[2 bytes] the non-displaced version of $1A.
 !Scratchram_DirectionalQuake_1C		= $04
  ;^[2 bytes] same as above but $1C

;Note: you may barely see garbage tiles on the left edge of the level (going left
;past screen #$00). Don't worry about it. As long you don't make the screen go more
;than 4 pixels in displacement, you're fine (otherwise, glitch tiles will appear
;WITHIN the level when moving the screen up/down while beyond the left edge). This
;also happens on the original game on the top of the level.
;

;Don't touch these

	!SubOffScrnBank1_LMHijack = 0
	if read1($01ac46) == $22
		!SubOffScrnBank1_LMHijack = 1
	endif
	
	assert !SubOffScrnBank1_LMHijack == 1, "Make sure you save a level on LM V3.00."
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA-1 handling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Only include this if there is no SA-1 detection, such as including this
;in a (seperate) patch.
	!dp = $0000
	!addr = $0000
	!sa1 = 0
	!gsu = 0

if read1($00FFD6) == $15
	sfxrom
	!dp = $6000
	!addr = !dp
	!gsu = 1
elseif read1($00FFD5) == $23
	sa1rom
	!dp = $3000
	!addr = $6000
	!sa1 = 1
endif


macro define_sprite_table(name, name2, addr, addr_sa1)
if !sa1 == 0
    !<name> = <addr>
else
    !<name> = <addr_sa1>
endif
    !<name2> = !<name>
endmacro

; Regular sprite tables
%define_sprite_table(sprite_num, "9E", $9E, $3200)
%define_sprite_table(sprite_speed_y, "AA", $AA, $9E)
%define_sprite_table(sprite_speed_x, "B6", $B6, $B6)
%define_sprite_table(sprite_misc_c2, "C2", $C2, $D8)
%define_sprite_table(sprite_y_low, "D8", $D8, $3216)
%define_sprite_table(sprite_x_low, "E4", $E4, $322C)
%define_sprite_table(sprite_status, "14C8", $14C8, $3242)
%define_sprite_table(sprite_y_high, "14D4", $14D4, $3258)
%define_sprite_table(sprite_x_high, "14E0", $14E0, $326E)
%define_sprite_table(sprite_speed_y_frac, "14EC", $14EC, $74C8)
%define_sprite_table(sprite_speed_x_frac, "14F8", $14F8, $74DE)
%define_sprite_table(sprite_misc_1504, "1504", $1504, $74F4)
%define_sprite_table(sprite_misc_1510, "1510", $1510, $750A)
%define_sprite_table(sprite_misc_151c, "151C", $151C, $3284)
%define_sprite_table(sprite_misc_1528, "1528", $1528, $329A)
%define_sprite_table(sprite_misc_1534, "1534", $1534, $32B0)
%define_sprite_table(sprite_misc_1540, "1540", $1540, $32C6)
%define_sprite_table(sprite_misc_154c, "154C", $154C, $32DC)
%define_sprite_table(sprite_misc_1558, "1558", $1558, $32F2)
%define_sprite_table(sprite_misc_1564, "1564", $1564, $3308)
%define_sprite_table(sprite_misc_1570, "1570", $1570, $331E)
%define_sprite_table(sprite_misc_157c, "157C", $157C, $3334)
%define_sprite_table(sprite_blocked_status, "1588", $1588, $334A)
%define_sprite_table(sprite_misc_1594, "1594", $1594, $3360)
%define_sprite_table(sprite_off_screen_horz, "15A0", $15A0, $3376)
%define_sprite_table(sprite_misc_15ac, "15AC", $15AC, $338C)
%define_sprite_table(sprite_slope, "15B8", $15B8, $7520)
%define_sprite_table(sprite_off_screen, "15C4", $15C4, $7536)
%define_sprite_table(sprite_being_eaten, "15D0", $15D0, $754C)
%define_sprite_table(sprite_obj_interact, "15DC", $15DC, $7562)
%define_sprite_table(sprite_oam_index, "15EA", $15EA, $33A2)
%define_sprite_table(sprite_oam_properties, "15F6", $15F6, $33B8)
%define_sprite_table(sprite_misc_1602, "1602", $1602, $33CE)
%define_sprite_table(sprite_misc_160e, "160E", $160E, $33E4)
%define_sprite_table(sprite_index_in_level, "161A", $161A, $7578)
%define_sprite_table(sprite_misc_1626, "1626", $1626, $758E)
%define_sprite_table(sprite_behind_scenery, "1632", $1632, $75A4)
%define_sprite_table(sprite_misc_163e, "163E", $163E, $33FA)
%define_sprite_table(sprite_in_water, "164A", $164A, $75BA)
%define_sprite_table(sprite_tweaker_1656, "1656", $1656, $75D0)
%define_sprite_table(sprite_tweaker_1662, "1662", $1662, $75EA)
%define_sprite_table(sprite_tweaker_166e, "166E", $166E, $7600)
%define_sprite_table(sprite_tweaker_167a, "167A", $167A, $7616)
%define_sprite_table(sprite_tweaker_1686, "1686", $1686, $762C)
%define_sprite_table(sprite_off_screen_vert, "186C", $186C, $7642)
%define_sprite_table(sprite_misc_187b, "187B", $187B, $3410)
%define_sprite_table(sprite_tweaker_190f, "190F", $190F, $7658)
%define_sprite_table(sprite_misc_1fd6, "1FD6", $1FD6, $766E)
%define_sprite_table(sprite_cape_disable_time, "1FE2", $1FE2, $7FD6)

; Romi's Sprite Tool defines.
%define_sprite_table(sprite_extra_bits, "7FAB10", $7FAB10, $6040)
%define_sprite_table(sprite_new_code_flag, "7FAB1C", $7FAB1C, $6056) ;note that this is not a flag at all.
%define_sprite_table(sprite_extra_prop1, "7FAB28", $7FAB28, $6057)
%define_sprite_table(sprite_extra_prop2, "7FAB34", $7FAB34, $606D)
%define_sprite_table(sprite_custom_num, "7FAB9E", $7FAB9E, $6083)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Hijack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Display adjusted layer 1 x position.
	org $008246
	autoclean JML Layer1XScroll0
	;^This enables the graphics to be displaced.

	org $008420
	autoclean JML Layer1XScroll1
	;^Didn't use JSL despite not being around or at a branch due to lots of NOPs would've been used.

;Displace layer temporally

	org $00A2A9
	autoclean JML DisplaceLayer1
	;^had to use JML instead of JSL due to how the stack works.
	
	org $00A2EA
	autoclean JML PullLayer1Coords

;Physics
 ;Mario dies by going off-screen
 	if !Setting_ApplyScrnBarrierToPlayer != 0
		org $00E9A1
		autoclean JSL PlayerScreenKillBoundary0
		;^RAM address $7E007E is calculated before patch: MarioXPosScreen = MarioXPosition - (ScreenXPosition + displacement),
		; instead of the original position. Thus, the kill boundary (not the solid boundary that prevents the player)
		; shifts. See $00E340 for the code that calculates it. (this is the code that happens when a horizontal autoscroll crushes the player)
		
		org $00F597
		autoclean JSL VerticalScreenBoundaryForPlayer
		NOP #2
		;^The top of the screen barrier for the player.
		
		org $00F5A5
		autoclean JML Deathpit
		;^Fix the deathpit from being adjusted by displacement.
	endif
 ;Sprite suboffscreen routine (the code that deletes sprite impermanently when they go off-screen).
 ;Note: Any code made by custom resources such as pixi must be edited to be like this else your custom sprites would react.
 ;Note: Nintendo had an oversight that they use the horizontal and vertical offscreen RAM address $15a0 and $186c to prevent
 ;      OAM screenwrap gfx (what they being set to uses the displaced screen), the same used on suboffscreen to skip deleting
 ;      the sprite via JSR.w $03B8FB, which is stupid, thus they have to be NOP'ed out
	org $01AC33
	nop #5
	
	org $01AC5C
	autoclean JML SubOffScreenBank01_HorizontalLevel
	
	org read3($01ac46+1)+6
	autoclean JML SubOffScreenBank01_HorizontalLevel_LMVerticalOffScrn
	;Trick, using [<JSL/JML> read3(<LM_freespace_Location>)+<Offset>]
	;
	;Where "read3(<LM_freespace_Location>)" is the starting address in a freespace.
	;Where <Offset> is the relative address from the starting address of the freespace.
	;To find out the offset:
	;
	;<Offset> = <Address_to_modify>-<Starting_Address>
	;
	;Example: I want to hijack $108c1a, but because this is a freespace (its location varies),
	;I would do $108c1a-$108c14, which the difference is 6. Now to modify a potentially-moving
	;location, just do [JSL read3($01ac47)+6].
	;
	;Here is the disassembled code:
	;
	;Hijack LM code:
	;01ac46 jsl $108c14            ;>Jump to LM freespace code
	;
	;108c14 xba                    ;\
	;108c15 rep #$20               ;|
	;108c17 cmp $13d7     [0113d7] ;|
	;108c1a bpl $8c3f     [108c3f] ;|>Hijack starts here
	;108c1c sec                    ;|\overwritten
	;108c1d sbc $1c       [00001c] ;|/
	;108c1f cmp $0bf2     [010bf2] ;|
	;108c22 bpl $8c30     [108c30] ;|
	;108c24 sec                    ;|
	;108c25 sbc $0bf0     [010bf0] 
	;108c28 eor #$8000             
	;108c2b sep #$20               
	;108c2d bpl $8c32     [108c32] 
	;108c2f rtl                    
	;108c30 sep #$20               
	;108c32 lda $0d9b     [010d9b] 
	;108c35 cmp #$80               
	;108c37 beq $8c3c     [108c3c] 
	;108c39 lda #$00               
	;108c3b rtl                    
	;108c3c lda #$ff               
	;108c3e rtl                    
	;108c3f sep #$20               
	;108c41 rtl                    
	;
	;^oh, by the way, this is used on all 3 SubOffScreen routines, so no individual edits
	; of LM code on each, since it is reused:
	; $02d040
	; $03B872
	
	org $01ACD2
	autoclean JML SubOffScreenBank01_VerticalLevel
	
	org $02D027
	nop #5
	
	org $02D056
	autoclean JML SubOffScreenBank02_HorizontalLevel
	
	org $02D0A2
	autoclean JML SubOffScreenBank02_VerticalLevel
	
	org $03B85F
	nop #5
	
	org $03B888
	autoclean JML SubOffScreenBank03_HorizontalLevel
	
	org $03B8D4
	autoclean JML SubOffScreenBank03_VerticalLevel

 ;Sprites spawning when they enter the screen:
	org $02A809
	autoclean JML LoadSprFromLevel_VerticalLevel
	
	org $02A817
	autoclean JML LoadSprFromLevel_HorizontalLevel
	
	org read3($02a826+1)+$0F
	LDA.b !Scratchram_DirectionalQuake_1C
	;^Modify a LM's "Enhanced Sprite Loader" to use
	; the non-displaced screen Y position (scratch RAM $01).
	;02a826 jml $108db8   [108db8] 
	;Freespace code:
	;108db8 sta $01       [000001] 
	;108dba lda $0bf4     [020bf4] 
	;108dbd and #$03               
	;108dbf asl a                  
	;108dc0 tax                    
	;108dc1 rep #$21               
	;108dc3 lda $00       [000000] 
	;108dc5 sta $50       [000050] 
	;108dc7 lda $1c       [00001c] ;>Modify this LDA $1C to LDA !Scratchram_DirectionalQuake_1C.
	;108dc9 and #$fff0             
	;108dcc sta $46       [000046] 
	;108dce adc $108c04,x [108c04] 
	;108dd2 sta $52       [000052] 
	;108dd4 sta $48       [000048] 
	;108dd6 lda $46       [000046] 
	;108dd8 clc                    
	;108dd9 adc $108c0c,x [108c0c] 
	;108ddd sta $46       [000046] 
	;108ddf sec                    
	;108de0 sbc #$0010             
	;108de3 sta $4a       [00004a] 
	;108de5 lda $1a       [00001a] ;>Modify this $1A to !Scratchram_DirectionalQuake_1A
	;108de7 and #$fff0             
	;108dea sec                    
	;108deb sbc #$0030             


	
	org read3($02a826+1)+$2D
	LDA.b !Scratchram_DirectionalQuake_1A
	;^Same as above but LDA $1A to LDA $02 for the X position.


 ;Extended sprites
 ;Just as a side note, $02A211 is the code that erases extended sprites. Often branched when
 ;hitting the screen border.
	org $029FB3
	autoclean JML ExtendedSpr_PlayerFireballYOffScreen
	;^The code that checks if the player's fireball goes offscreen vertically to despawn it.
	
	org $02A1B1
	autoclean JML ExtendedSpr_PlayerFireballXOffScreen
	;^Same as above but X position. This code was also used by other extended sprites like the reznor.
	
	org $029B54
	autoclean JML ExtendedSpr_VolcanoLotusSeedsOffScreen
	
	org $02A271
	autoclean JML ExtendedSpr_BaseBallOffScreen
	
	org $029CF8
	autoclean JML ExtendedSpr_CloudCoin

 ;Other (mainly adds horizontal displacement along with the original vertical displacement)

	;org $00FF8B
	;autoclean JSL ApplyHorizDisplacement0
	;nop #1
	
	org $01A7F0
	nop #3
	;^Make most sprites without the "process every frame" interact with player even if offscreen.

 ;$15A0, the sprite off screen flag.
 ;Some notes:
 ;-$0199A6 is the code that makes bounceable blocks (?, turn, glass, blocks) not activate
 ; when hit by kicked sprites when they are offscreen.
 ;-$15A0 is used BOTH for interaction and as a prevention of graphics from wrapping the screen.

	org $0199A6
	JML $0199B7
	;^Enable bounceable blocks (? and turn, for example) to be triggered by kicked sprites
	; when offscreen.
	
;Bounce block screenwrap gfx fixes.

	org $029A1D
	autoclean JML BounceBlockSpinningCoinFix
	;^This prevents the coin from wrapping the screen.

freecode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;freespace
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;As a side note, to obtain the sprite's position on-screen ignoring the shaking effect, the formula is this:
; SpriteScreenPosNotShooked = SpritePos - (ShookedScreenPos - Displacement)
;Alternatively:
; SpriteScreenPosNotShooked = SpritePos + (-ShookedScreenPos + Displacement)
;  which is this:
;   SpriteScreenPosNotShooked = SpritePos + Displacement - ShookedScreenPos
;The last one is used in some cases like "DeathPit" ($80 already have "SpritePos + (-ShookedScreenPos)"
;(remember, community property of addition)), cases where you do not want to modify the screen position
;value obtain but instead, the sprite position.
	Layer1XScroll0:					;>JML from $008246
	LDA $1A						;\Enable horizontal displacement
	CLC						;|
	ADC !Freeram_DirQuake_Layer1XDisplacement	;|
	STA $210D					;|
	LDA $1B						;|
	ADC !Freeram_DirQuake_Layer1XDisplacement+1	;|
	STA $210D					;/
	JML $008250
	;---------------------------------------------------------------------
	Layer1XScroll1:					;>JML from $008420
	LDA $1A						;\Apply quake displacement for horizontal.
	CLC						;|
	ADC !Freeram_DirQuake_Layer1XDisplacement	;|
	STA $210D					;|
	LDA $1B						;|
	;ADC !Freeram_DirQuake_Layer1XDisplacement+1	;|
	STA $210D					;|
	JML $00842A					;/
	;---------------------------------------------------------------------
	DisplaceLayer1:					;>JML from $00A2A9
	.PushLayerCoords
	REP #$20					;>16-bit A
	LDA $1C						;\Push layer 1 Y pos into stack
	PHA						;/
	LDA $1A						;\Push layer 1 X pos into stack
	PHA						;/
	
	.HandleTimer
	PHB						;\Save bank since I'm using tables.
	PHK						;|
	PLB						;/
	if or(equal(!Setting_DirQuake_DebugMode, 0), equal(!Setting_DirQuake_DebugMode, 2))
		LDA #$0000					;\remove displacement
		STA $1888|!addr					;|
		STA !Freeram_DirQuake_Layer1XDisplacement	;/
	endif
	LDA $1887|!addr					;
	AND #$00FF					;
	BEQ .NoDisp
	
	.Displace
	PHX						;>Just in case
	SEP #$20
	LDA $9D						;\If frozen, leave as normal
	ORA $13D4|!addr					;|
	BNE .Done					;/
	if !Setting_DirQuake_DebugMode == 0
		DEC $1887|!addr					;>Decrement timer
	endif
	if or(equal(!Setting_DirQuake_DebugMode, 0), equal(!Setting_DirQuake_DebugMode, 2))
		JSL $01ACF9					;>Execute RNG
		LDA $148D|!addr					;>Load output of RNG
		AND #$07					;>Limit its value to #$00-#$07 (MOD 8)
		ASL						;>Since each item is 2 bytes long
		TAX						;>And index it.
	endif
	REP #$20	;>16-bit A.
	if !Setting_DirQuake_DebugMode == 1
		.DebugDisplace
		..HorizontalMovement
		LDA $15
		BIT.w #%0000000000100000
		BEQ .NoControllingLayer
		AND.w #%0000000000000011
		ASL						;>due to 16-bit numbers in table, you move over by 2 bytes, thus you need to leftshift 1 space left (which is index*2)
		TAX
		
		LDA !Freeram_DirQuake_Layer1XDisplacement
		CLC
		ADC DisplaceMove,x
		STA !Freeram_DirQuake_Layer1XDisplacement
		
		..VerticalMovement
		LDA $15
		AND.w #%0000000000001100
		LSR						;>Shorthand - you move the two desired bits 2 places to the right, then 1 left
		TAX
		
		REP #$20
		LDA $1888|!addr
		CLC
		ADC DisplaceMove,x
		STA $1888|!addr
		
		.NoControllingLayer
		
		LDA $1888|!addr					;\
		CLC						;|Adjust Y position
		ADC $1C						;|
		STA $1C						;/
		LDA !Freeram_DirQuake_Layer1XDisplacement	;\Adjust X position
		CLC						;|
		ADC $1A						;|
		STA $1A						;/
	else
		LDA YDisplacementTable,x			;\Displace layer
		STA $1888|!addr					;/
		CLC						;\Adjust Y position
		ADC $1C						;|
		STA $1C						;/
		LDA XDisplacementTable,x			;\Adjust X position
		STA !Freeram_DirQuake_Layer1XDisplacement	;|
		CLC						;|
		ADC $1A						;|
		STA $1A						;/
	endif
	if !Setting_DirQuake_OffLevelEdgeProtect != 0
		.XPositionGlitchPrevention
		LDA #$0000					;\Prevent going past left border
		CMP $1A						;|
		BMI ..CheckRightSide				;|
		STA $1A						;|
		STA !Freeram_DirQuake_Layer1XDisplacement	;/
		
		..CheckRightSide
		SEP #$20
		LDA $5B
		LSR
		BCS ...VerticalLevel
		
		...HorizontalLevel
		LDA $5E
		DEC
		XBA
		LDA #$00
		REP #$20
		CMP $1A
		BPL ..XPositionGlitchPreventionDone
		STA $1A
		LDA #$0000
		STA !Freeram_DirQuake_Layer1XDisplacement
		BRA ..XPositionGlitchPreventionDone
		
		...VerticalLevel
		REP #$20
		LDA #$0100
		CMP $1A
		BPL ..XPositionGlitchPreventionDone
		STA $1A
		LDA #$0000
		STA !Freeram_DirQuake_Layer1XDisplacement
		
		..XPositionGlitchPreventionDone
	endif
	.Done
	PLX
	
	.NoDisp
	SEP #$20

	PLB			;>Restore bank
	JML $00A2D5
	if !Setting_DirQuake_DebugMode == 1
		DisplaceMove:
		dw $0000,$0001,$FFFF,$0000
	endif
	XDisplacementTable:
	dw $0000,$0002,$0002,$0002,$0000,$FFFE,$FFFE,$FFFE
	YDisplacementTable:
	dw $FFFE,$FFFE,$0000,$0002,$0002,$0002,$0000,$FFFE
	;---------------------------------------------------------------------
	PullLayer1Coords:				;>JML from $00A2EA
	REP #$20					;>16-bit A
	PLA						;\Pull layer 1 X displacement from stack
	STA $1A						;/
	PLA						;\Pull layer 1 Y displacement from stack
	STA $1C						;/
	SEP #$20					;>8-bit A
	JML $008494					;>jump to smw code
	;---------------------------------------------------------------------
	if !Setting_ApplyScrnBarrierToPlayer != 0
		PlayerScreenKillBoundary0:			;>JSL from $00E9A1
		LDA $94						
		SEC						;\See comment about this of why I divert from using $7E on this.
		SBC $1462|!addr					;/
		CMP #$F0
		RTL
	endif
	;---------------------------------------------------------------------
	if !Setting_ApplyScrnBarrierToPlayer != 0
		VerticalScreenBoundaryForPlayer:	;>JSL from $00F597
		LDA #$FF80
		CLC
		ADC $1464
		RTL
	endif
	;---------------------------------------------------------------------
	if !Setting_ApplyScrnBarrierToPlayer != 0
		Deathpit:				;>JML from $00F5A5
		LDA $80					;\MarioOnScrnNoDisp = MarioOnScrnQuakeDisp + RAM_1888
		CLC					;|(basically the distance between mario and the pit is the same instead of being being extended
		ADC $1888|!addr				;|or contracted by displacement.
		LDA $81					;|When screen displaced downwards, $80 is "displaced" upwards, thus adding was nessessary.
		ADC $1889|!addr				;/
		DEC A					;\If Mario's Y position on screen is $0100 or further down the screen (downwards is positive direction),
		BMI .Goto_00F5B6			;|kill or teleport out of level.
		JML $00F5AA				;/
		
		.Goto_00F5B6
		JML $00F5B6
	endif
	;---------------------------------------------------------------------
	;ApplyHorizDisplacement0:			;>JSL from $00FF8B
	;ADC $1888|!addr					;\Restore code
	;STA $24						;/
	;LDA #$????
	;SEC
	;SBC <on screen X position>
	;CLC
	;ADC !Freeram_DirQuake_Layer1XDisplacement
	;STA $22
	;RTL
	;---------------------------------------------------------------------
	SubOffScreenBank01_HorizontalLevel:		;>JML from $01AC5C
	LDA $1462|!addr					;\Thankfully, the alternate
	CLC						;|coordinates ($1462-$1464)
	ADC.w $AC11,y					;|don't get displaced.
	ROL $00						;|
	CMP !E4,x					;|
	PHP						;|
	LDA $1463|!addr					;/
	JML $01AC69
	;---------------------------------------------------------------------
	SubOffScreenBank01_HorizontalLevel_LMVerticalOffScrn:		;>JML from read3($01ac46+1)+6
	BPL .Addr_108c3f
	SEC
	SBC $1464|!addr
	JML read3($01ac46+1)+11
	
	.Addr_108c3f
	JML read3($01ac46+1)+43
	;---------------------------------------------------------------------
	SubOffScreenBank01_VerticalLevel:		;>JML from $01ACD2
	LDA $1464|!addr
	CLC
	ADC.w $AC0D
	ROL $00
	CMP !D8|!addr
	PHP
	LDA $1465|!addr
	JML $01ACE0
	;---------------------------------------------------------------------
	SubOffScreenBank02_HorizontalLevel:		;>JML from $02D056
	LDA $1462|!addr
	CLC
	ADC.w $02D007,y
	ROL $00
	CMP !E4,x
	PHP
	LDA $1463|!addr
	JML $02D063
	;---------------------------------------------------------------------
	SubOffScreenBank02_VerticalLevel:		;>JML from $02D0A2
	LDA $1464|!addr
	CLC
	ADC.W $02D003,y
	ROL $00
	CMP !D8,X
	PHP
	LDA.W $1465|!addr
	JML $02D0B0
	;---------------------------------------------------------------------
	SubOffScreenBank03_HorizontalLevel:		;>JML from $03B888
	LDA $1462|!addr
	CLC
	ADC.w $03B83F,y
	ROL $00
	CMP !E4,x
	PHP
	LDA $1463|!addr
	JML $03B895
	;---------------------------------------------------------------------
	SubOffScreenBank03_VerticalLevel:		;>JML from $03B8D4
	LDA $1464|!addr
	CLC
	ADC.W $03B83B,y
	ROL $00
	CMP !D8,X
	PHP
	LDA.W $1465|!addr
	JML $03B8E2
	;---------------------------------------------------------------------
	LoadSprFromLevel_VerticalLevel:			;>JML from $02A809
	;These methods don't work properly
	;-Take $1A-$1C, subtract by displacement,
	; and write to $1462-$1464. This will move the "interactive" screen border.
	;-Take $1A-$1C, subtract by displacement, and write back to
	; $1A-$1C, this will nullify the quake visual.
	;-Use $1462-$1464 directly, see comments of why.
	;
	;--Instead, I rather use:
	;  [NonDisplaced_X_Pos = RAM_1A - !Freeram_DirQuake_Layer1XDisplacement]
	;  [NonDisplaced_Y_Pos = RAM_1C - RAM_1888]
	;
	;If you don't know ASM, which is common with many hackers making mostly hacks, I'll give a brief info
	;about SEC : SBC subtraction.
	;-SEC sets the carry so the following SBC doesn't subtract an addition 1 for A.
	;-SBC is the actual subtraction. After SBC, if it underflows, the carry will be cleared, otherwise set.
	; The accumulator "A" now holds the difference.
	;
	;After subtraction, if you still need to use the non-displaced coordinates, store the difference into
	;scratch RAM (via STA $xx where $XX is $00 to $0F) that is currently not in use by other things (as in,
	;If scratch RAM $0F is used for something else and about to be read via LDA/LDX/LDY/CMP/CPX/CPY on $0F
	;later on in the code, don't write on $0F as the value in it is still in use).
	REP #$20					;\$04 to $05 = non-displaced screen Y position, unlike $1464, $1C is updated without changing $1464.
	LDA $1C						;|This is due to a screen being moved temporarily during a vertical level loading sprite
	SEC						;|spawning code at $02AC68 in which how sprites are being spawned despite not being at
	SBC $1888|!addr					;|the edge of the screen.
	STA.b !Scratchram_DirectionalQuake_1C		;|
	SEP #$20					;/
	
	LDA.b !Scratchram_DirectionalQuake_1C		;\Restore code
	CLC						;|
	ADC.w $02A7F6,y					;|
	AND #$F0					;|
	STA $00						;|
	LDA.b !Scratchram_DirectionalQuake_1C+1		;|
	JML $02A823					;/
	;---------------------------------------------------------------------
	LoadSprFromLevel_HorizontalLevel:		;>JML from $02A817
	REP #$20					;\$02 to $03 = non-displaced screen X position, unlike $1462, $1A is updated without changing $1462.
	LDA $1A						;|This is due to a screen being moved temporarily during a horizontal level loading
	SEC						;|sprite spawning code at $02ACA8 in which how sprites are being spawned despite not being at
	SBC !Freeram_DirQuake_Layer1XDisplacement	;|the edge of the screen.
	STA.b !Scratchram_DirectionalQuake_1A		;|
	SEP #$20					;/
	
	REP #$20					;\$04 to $05 = non-displaced screen Y position, unlike $1464, $1C is updated without changing $1464.
	LDA $1C						;|This is due to a screen being moved temporarily during a horizontal level loading
	SEC						;|sprite spawning code at $02ACA8 in which how sprites are being spawned despite not being at
	SBC $1888|!addr					;|the edge of the screen.
	STA.b !Scratchram_DirectionalQuake_1C		;|By the way, this is here due to LM's loading sprite vertically in horizontal levels' new dimension.
	SEP #$20					;/
	
	LDA.b !Scratchram_DirectionalQuake_1A		;\Restore code
	CLC						;|
	ADC.w $02A7F6,y					;|
	AND #$F0					;|
	STA $00						;|
	LDA.b !Scratchram_DirectionalQuake_1A+1		;|
	JML $02A823					;/
	;---------------------------------------------------------------------
	ExtendedSpr_PlayerFireballYOffScreen:		;>JML from $029FB3
	JSL ExtendedSpriteOffScrnCheck			;>Not sure why Nintendo would have to check if its off-screen vertically twice...
	JML $029FBD
	;---------------------------------------------------------------------
	ExtendedSpr_PlayerFireballXOffScreen:		;>JML from $02A1B1
	
	.DeleteFireballIfOffScrn
	JSL ExtendedSpriteOffScrnCheck
	BNE .FireballIsOffScrn			;/
	
	;OAM tile handling (won't display fireball to prevent wrapping but does not
	;delete sprite should the fireball be offscreen from the displaced screen but
	;onscreen from the non-displaced screen.)
	.OAMPositionHandle
;	LDA $171F|!addr,x			;\OAM tile X position.
;	SEC					;|
;	SBC $1A					;|
;	STA $01					;/
;	LDA $1733|!addr,x			;\If sprite is offscreen horizontally, don't display sprite
;	SBC $1B					;|
;	BNE .NoDraw				;/
;	LDA $1715|!addr,x			;\OAM tile Y position
;	SEC					;|
;	SBC $1C					;|
;	STA $02					;/
;	LDA $1729|!addr,x			;\If sprite is offscreen vertically, don't display sprite
;	SBC $1D					;|
;	BNE .NoDraw				;/
	JSL ExtendedSpriteOAMCoords
	BCS .NoDraw
	
	.DoDraw
	LDA $02
	JML $02A1D5
	
	.NoDraw
	JML $02A1D8
	
	.FireballIsOffScrn
	JML $02A211
	;---------------------------------------------------------------------
	ExtendedSpr_VolcanoLotusSeedsOffScreen:		;>JML from $029B54
	;Strangely enough, $00 is used for X position onscreen and $01 for Y,
	;instead of using $01 and $02, due to fireballs have $00 for bit 7,
	;inverts it via EOR #$80, then stores it into $00 for OAM properties.
	JSL ExtendedSpriteOffScrnCheck
	BNE .OffScreen
	JSL ExtendedSpriteOAMCoords
	BCS .NoOamToDisplay
	LDA $01				;\Move $01-$02 to $00-$01.
	STA $00				;|
	LDA $02				;|
	STA $01				;/
	JML $029B76
	
	.OffScreen
	JML $029BDA
	
	.NoOamToDisplay
	JML $029BA5
	;---------------------------------------------------------------------
	ExtendedSpr_BaseBallOffScreen:		;>JML from $02A271
	JSL ExtendedSpriteOffScrnCheck
	BNE .OffScreen
	
	JSL ExtendedSpriteOAMCoords
	LDA $01				;\Move $01-$02 to $00-$01.
	STA $00				;|
	LDA $02				;|
	STA $01				;/
	
	LDY.W $02A153,x			;\Restore
	LDA $00				;|
	STA $0200,y			;|
	JML $02A29E			;/
	
	.OffScreen
	JML $02A2BF
	;---------------------------------------------------------------------
	ExtendedSpr_CloudCoin:		;>JML from $029CF8
	;This one have a weird handling if the sprite is offscreen to delete it...
	LDA $1715|!addr,x		;\Y position to delete sprite
	SEC				;|
	SBC $1464|!addr			;|
	CMP #$F0			;|
	BCS .OffScreen			;/
	
	LDA $1715|!addr,x
	SEC
	SBC $1C
	STA $01
	LDA $1729|!addr,x
	SBC $1D
	BNE .OamOffScreen
	JML $029D04
	
	.OffScreen
	JML $029D5A
	
	.OamOffScreen
	JML $029D5D
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Extended sprite off-screen (uses non-displaced screen
	;position) detection. To be used for erasing extended sprites.
	;
	;Zero flag (use BEQ/BNE): zero if on-screen and non-zero
	;if off-screen.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ExtendedSpriteOffScrnCheck:
	LDA $171F|!addr,x		;\X position
	SEC				;|
	SBC $1462|!addr			;|
	LDA $1733|!addr,x		;|
	SBC $1463|!addr			;/
	BNE .OffScreen
	
	LDA $1715|!addr,x		;\Y position
	SEC				;|
	SBC $1464|!addr			;|
	LDA $1729|!addr,x		;|
	SBC $1465|!addr			;/
	
	.OffScreen
	RTL
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Extended sprite OAM handling.
	;This MUST use the displaced screen coordinates so that the
	;image of the sprite syncs with the shooked layer 1 position.
	;
	;Should the sprite position be off-screen, will skip drawing
	;(Y=$F0) to avoid graphics wrapping.
	;
	;Output:
	; $01 = OAM x position
	; $02 = OAM y position
	; Carry is set when offscreen, clear otherwise.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ExtendedSpriteOAMCoords:
	
	.XPosition
	LDA $171F|!addr,x			;\OAM tile X position.
	SEC					;|
	SBC $1A					;|
	STA $01					;/
	LDA $1733|!addr,x			;\If sprite is offscreen horizontally, don't display sprite
	SBC $1B					;|
	BNE .NoDraw				;/
	
	.YPosition
	LDA $1715|!addr,x			;\OAM tile Y position
	SEC					;|
	SBC $1C					;|
	STA $02					;/
	LDA $1729|!addr,x			;\If sprite is offscreen vertically, don't display sprite
	SBC $1D					;|
	BNE .NoDraw				;/
	
	..OAM16x16WrapToTopScreenPrevention
	LDA $02
	CMP #$E0
	BCS .NoDraw
	CLC
	RTL
	
	.NoDraw
	LDA #$F0
	STA $02
	SEC
	RTL
	;---------------------------------------------------------------------
	BounceBlockSpinningCoinFix:			;>JML from $029A1D
	;Include X position high byte
	LDA $001B|!dp,y
	STA $05
	
	;YPosition
	LDA $17D4|!addr,x
	CMP $02
	LDA $17E8|!addr,x
	SBC $04
	BNE .OffScreen
	
	;XPosition
	LDA $17E0|!addr,x
	CMP $03
	LDA $17EC|!addr,x
	SBC $05
	BNE .OffScreen
	
	;DrawOAM
	JML $029A29
	
	.OffScreen
	JML $029A6D
;------------------------------------------------------