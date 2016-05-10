; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :
;
; Sprite view related code

VIEW_POS = $0411
VIEW_COL = $d811

colors
color_top       .byte 0         ; $d027, $d029, $d02b, $d02d
color_bottom    .byte 1         ; $d028, $d02a, $d02c, $d02e
color_mc1       .byte 15        ; $d025
color_mc2       .byte 14        ; $d026
color_bg        .byte 6         ; background color

color_index     .byte 0         ; color index for plotting

cursor_x        .byte 0         ; zoom cursor x position
cursor_y        .byte 0         ; zoom cursor y position


sprite_index    .byte 2



setup_background
        ldx #0
        jsr setup_bg_block
        ldx #6
        jsr setup_bg_block
        ldx #12
        jsr setup_bg_block
        ldx #18
        jsr setup_bg_block
        jsr update_info_colors
        jmp update_bg_color

setup_bg_block
        lda #$a0
        sta VIEW_POS,x
        sta VIEW_POS + 1,x
        sta VIEW_POS + 2,x
        sta VIEW_POS + 3,x
        sta VIEW_POS + 40,x
        sta VIEW_POS + 41,x
        sta VIEW_POS + 42,x
        sta VIEW_POS + 43,x
        sta VIEW_POS + 80,x
        sta VIEW_POS + 81,x
        sta VIEW_POS + 82,x
        sta VIEW_POS + 83,x
        rts

update_bg_color
        lda color_bg
        ldx #0
-       sta VIEW_COL,x
        sta VIEW_COL + 40,x
        sta VIEW_COL + 80,x
        sta VIEW_COL + 120,x
        inx
        cpx #23
        bne -
        rts

setup_info_text
        lda #<info_text
        ldx #>info_text
        sta zp
        stx zp + 1
        lda #$00
        ldx #$04
        ldy #$d8
        sta zp + 2
        sta zp + 4
        stx zp + 3
        sty zp + 5

        ldx #0
-
        ldy #0
-
        lda (zp),y
        sta (zp + 2),y
        lda #$0f
        sta (zp + 4),y
        iny
        cpy #16
        bne -
        lda zp
        clc
        adc #16
        sta zp
        bcc +
        inc zp + 1
+
        lda zp + 2
        clc
        adc #40
        sta zp + 2
        sta zp + 4
        bcc +
        inc zp + 3
        inc zp + 5
+
        inx
        cpx #(info_text_end - info_text) / 16
        bne --

        cpx #25
        bcc +
        rts
+
        ; clear rest of the screen
-
        ldy #15
-       lda #$20
        sta (zp + 2),y
        lda #$0f
        sta (zp + 4),y
        dey
        bpl -
        lda zp + 2
        clc
        adc #40
        sta zp + 2
        sta zp + 4
        bcc +
        inc zp + 3
        inc zp + 5
+
        inx
        cpx #25
        bne --


        rts


update_info_colors
        lda color_top
        sta $d8a3
        lda color_bottom
        sta $d8cb
        sta $d8cc
        lda color_mc1
        sta $d8f3
        sta $d8f4
        lda color_mc2
        sta $d91b
        sta $d91c
        lda color_bg
        sta $d943
        sta $d944
        rts


decimal_digits
        ldx #$30
-
        cmp #10
        bcc +
        inx
        sbc #10
        bcs -
+
        clc
        adc #$30
        tay
        rts

hex_digits
        pha
        and #$0f
        adc #$30
        cmp #$3a
        bcc +
        adc #$06
+
        tay
        pla
        and #$f0
        lsr
        lsr
        lsr
        lsr
        clc
        adc #$30
        cmp #$3a
        bcc +
        adc #$06
+
        tax
        rts

get_sprite_data_pointer
        lda sprite_index
        and #1
        beq +
        lda #$80
+
        tax
        lda sprite_index
        lsr
        clc
        adc #$20
        tay
        rts




; update cursor position and sprite location
update_zoom_info
        lda cursor_x
        jsr decimal_digits
        stx $0592
        sty $0593
        lda cursor_y
        jsr decimal_digits
        stx $0597
        sty $0598
        lda sprite_index
        jsr decimal_digits
        stx $059e
        sty $059f
        rts


info_text
        .enc screen
        ;      0123456789abcdef
        .text " Double layer   "
        .text " sprite editor  "
        .text "2016, Cpx/Focus "
        .text "                "
        .text "1: ", $a0, "  ($d027)   "
        .text "2: ", $a0, $a0, " ($d028)   "
        .text "3: ", $a0, $a0, " ($d025)   "
        .text "4: ", $a0, $a0, " ($d026)   "
        .text "5: ", $a0, $a0, " ($d021)   "
        .text "                "
        .text "X:00 Y:00 Spr:00"
        .text "                "
        .text "Use F1 for help "
info_text_end
