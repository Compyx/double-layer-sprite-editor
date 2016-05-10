; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :
;
; Editing module
;


        BUFFER = $4000
        TEMP_DATA = $4080


set_sprite_zp
        lda view.sprite_index
        jsr view.get_sprite_data_pointer
        stx zp
        sty zp + 1

        stx $0400
        sty $0401
        rts

; Copy current sprite to buffer
buffer_copy
        jsr set_sprite_zp
        ldy #$7f
-
        lda (zp),y
        sta BUFFER,y
        dey
        bpl -
        rts

; Paste buffer into current sprite
buffer_paste
        jsr set_sprite_zp
        ldy #$7f
-
        lda BUFFER,y
        sta (zp),y
        dey
        bpl -
        jmp zoom.full_zoom

shift_up
        jsr set_sprite_zp

        ; keep first line
        ldy #0
        ldx #0
-       lda (zp),y
        sta TEMP_DATA,x
        inx
        iny
        cpy #3
        bne -
        ldy #64
-       lda (zp),y
        sta TEMP_DATA,x
        inx
        iny
        cpy #67
        bne -

        ; move all data one line up
        lda zp
        clc
        adc #3
        sta zp + 2
        lda zp + 1
        sta zp + 3

        ldy #0
-
        lda (zp + 2),y
        sta (zp),y
        iny
        cpy #60
        bne -

        ldy #64
-
        lda (zp + 2),y
        sta (zp),y
        iny
        cpy #124
        bne -

        ldy #60
        ldx #0
-
        lda TEMP_DATA,x
        sta (zp),y
        inx
        iny
        cpx #3
        bne -
        ldy #124
-       lda TEMP_DATA,x
        sta (zp),y
        inx
        iny
        cpx #6
        bne -
        
        jmp zoom.full_zoom


shift_down
        jsr set_sprite_zp

        ; keep last line
        ldy #60
        ldx #0
-       lda (zp),y
        sta TEMP_DATA,x
        inx
        iny
        cpx #3
        bne -
        ldy #124
-       lda (zp),y
        sta TEMP_DATA,x
        inx
        iny
        cpx #6
        bne -

        ; move all data one line up
        lda zp
        clc
        adc #3
        sta zp + 2
        lda zp + 1
        sta zp + 3

        ldy #59
-
        lda (zp),y
        sta (zp + 2),y
        dey
        bpl -

        ldy #123
-
        lda (zp),y
        sta (zp + 2),y
        dey
        cpy #63
        bne -

        ldy #0
        ldx #0
-
        lda TEMP_DATA,x
        sta (zp),y
        inx
        iny
        cpx #3
        bne -
        ldy #64
-       lda TEMP_DATA,x
        sta (zp),y
        inx
        iny
        cpx #6
        bne -
        
        jmp zoom.full_zoom


; ROL current sprite left
shift_left
        jsr set_sprite_zp

        ldx #0
-
        ; buffer the first two pixels of each byte
        ldy #0
-
        lda (zp),y
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        sta TEMP_DATA,y
        iny
        cpy #3
        bne -
        ldy #64
-
        lda (zp),y
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        sta TEMP_DATA - 64 + 3,y
        iny
        cpy #67
        bne -

        ; ROL each byte twice
        ldy #0
        lda (zp),y
        asl
        asl
        ora TEMP_DATA + 1
        sta (zp),y
        iny
        lda (zp),y
        asl
        asl
        ora TEMP_DATA + 2
        sta (zp),y
        iny
        lda (zp),y
        asl
        asl
        ora TEMP_DATA + 0
        sta (zp),y

        ldy #64
        lda (zp),y
        asl
        asl
        ora TEMP_DATA + 4
        sta (zp),y
        iny
        lda (zp),y
        asl
        asl
        ora TEMP_DATA + 5
        sta (zp),y
        iny
        lda (zp),y
        asl
        asl
        ora TEMP_DATA + 3
        sta (zp),y

        lda zp
        clc
        adc #3
        sta zp

        inx
        cpx #21
        bne ---
        jmp zoom.full_zoom



; ROR current sprite right
shift_right
        jsr set_sprite_zp

        ldx #0
-
        ; buffer the last two pixels of each byte
        ldy #0
-
        lda (zp),y
        asl
        asl
        asl
        asl
        asl
        asl
        sta TEMP_DATA,y
        iny
        cpy #3
        bne -
        ldy #64
-
        lda (zp),y
        asl
        asl
        asl
        asl
        asl
        asl
        sta TEMP_DATA - 64 + 3,y
        iny
        cpy #67
        bne -

        ; ROR each byte twice
        ldy #0
        lda (zp),y
        lsr
        lsr
        and #$3f
        ora TEMP_DATA + 2
        sta (zp),y
        iny
        lda (zp),y
        lsr
        lsr
        and #$3f
        ora TEMP_DATA + 0
        sta (zp),y
        iny
        lda (zp),y
        lsr
        lsr
        and #$3f
        ora TEMP_DATA + 1
        sta (zp),y

        ldy #64
        lda (zp),y
        lsr
        lsr
        and #$3f
        ora TEMP_DATA + 5
        sta (zp),y
        iny
        lda (zp),y
        lsr
        lsr
        and #$3f
        ora TEMP_DATA + 3
        sta (zp),y
        iny
        lda (zp),y
        lsr
        lsr
        and #$3f
        ora TEMP_DATA + 4
        sta (zp),y

        lda zp
        clc
        adc #3
        sta zp

        inx
        cpx #21
        bne ---
        jmp zoom.full_zoom


; Flip current sprite verically
flip_vertical
        jsr set_sprite_zp

        lda zp
        clc
        adc #60
        sta zp + 2
        lda zp + 1
        sta zp + 3
        jsr fv_worker

        jsr set_sprite_zp
        lda zp
        clc
        adc #64
        sta zp
        adc #60
        sta zp + 2
        jsr fv_worker
        jmp zoom.full_zoom

fv_worker
        ldx #0
-
        ldy #2
-
        lda (zp),y
        sta TEMP_DATA,y
        lda (zp + 2),y
        sta (zp),y
        lda TEMP_DATA,y
        sta (zp + 2),y
        dey
        bpl -

        lda zp
        clc
        adc #3
        sta zp
        lda zp + 2
        sec
        sbc #3
        sta zp + 2
        inx
        cpx #10
        bne --
        rts


fh_and  .byte $80, $40, $20, $10, $08, $04, $02, $01
fh_ora  .byte $01, $02, $04, $08, $10, $20, $40, $80


fh_hires_byte
        sta zp + 4
        stx zp + 5

        ldx #0
        stx TEMP_DATA
-
        lda zp + 4
        and fh_and,x
        beq +
        lda TEMP_DATA
        ora fh_ora,x
        sta TEMP_DATA
+
        inx
        cpx #8
        bne -
        lda TEMP_DATA
        ldx zp + 5
        rts

fh_multi_byte
        sta zp + 4

        lda #0
        sta TEMP_DATA

        lda zp + 4
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        sta TEMP_DATA
        lda zp + 4
        lsr
        lsr
        and #%00001100
        ora TEMP_DATA
        sta TEMP_DATA
        lda zp + 4
        asl
        asl
        and #%00110000
        ora TEMP_DATA
        sta TEMP_DATA
        lda zp + 4
        asl
        asl
        asl
        asl
        asl
        asl
        ora TEMP_DATA
        rts




; Flip sprite horizontally
flip_horizontal
        jsr set_sprite_zp

        ldy #0
-
        lda (zp),y
        jsr fh_hires_byte
        sta TEMP_DATA + 1
        iny
        lda (zp),y
        jsr fh_hires_byte
        sta (zp),y
        iny
        lda (zp),y
        jsr fh_hires_byte
        dey
        dey
        sta (zp),y
        lda TEMP_DATA + 1
        iny
        iny
        sta (zp),y

        iny
        cpy #63
        bne -


        ldy #64
-
        lda (zp),y
        jsr fh_multi_byte
        sta TEMP_DATA + 1
        iny
        lda (zp),y
        jsr fh_multi_byte
        sta (zp),y
        iny
        lda (zp),y
        jsr fh_multi_byte
        dey
        dey
        sta (zp),y
        lda TEMP_DATA + 1
        iny
        iny
        sta (zp),y
        iny
        cpy #127
        bne -

        jmp zoom.full_zoom


; Clear the current
clear_sprite
        lda #1
        ldx #<clr_spr_text
        ldy #>clr_spr_text
        jsr dialog.dialog_yesno
        bcs +
        rts
+
        jsr view.get_sprite_data_pointer
        stx zp
        sty zp + 1
        ldy #$7f
        lda #0
-       sta (zp),y
        dey
        bpl -
        jmp zoom.full_zoom


; Clear all sprites ($2000-$3fff)
clear_all
        lda #1
        ldx #<clr_all_text
        ldy #>clr_all_text
        jsr dialog.dialog_yesno
        bcs +
        rts
+
        lda #$00
        ldx #$20
        sta zp
        stx zp + 1
        ldx #$1f
        ldy #0
-       sta (zp),y
        iny
        bne -
        inc zp + 1
        dex
        bpl -
        jmp zoom.full_zoom


DL_YESNO .macro
        ; "(yes/no)" with white 'y' and 'n'
        .enc screen
        .text "(", $f1, "Y", $ff, "es/", $f1, "N", $ff, "o)", 0
        .endm

DL_ANYKEY .macro
        .enc screen
        "(press any key)"
        .endm


clr_spr_text
        .enc screen
        .text "Clear current sprite? "
        .DL_YESNO


clr_all_text
        .enc screen
        .text "Clear all sprites? "
        .DL_YESNO

