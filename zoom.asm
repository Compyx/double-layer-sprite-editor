; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :

        ; top-left corner of grid videoram
        GRID_TOP = $04a0 + 16

        ; top left cornor of grid colorram
        GRID_COLRAM = $d8a0 + 16

        ; memory location of grid sprites
        GRID_SPRITES = $0340

; Setup zoom 'grid'
setup_grid_chars
        lda #<GRID_TOP
        ldx #>GRID_TOP
        sta zp
        stx zp + 1

        ldx #20
-
        ldy #23
        lda #$a0
-       sta (zp),y
        dey
        bpl -
        lda zp
        clc
        adc #40
        sta zp
        bcc +
        inc zp + 1
+       dex
        bpl --
        rts

; Create zoom grid sprites
setup_grid_sprites
        ldx #$7f
        lda #0
-
        sta GRID_SPRITES,x
        dex
        bpl -

        ldx #0
-
        lda grid_sprite_hires,x
        sta GRID_SPRITES,x
        lda grid_sprite_multi,x
        sta GRID_SPRITES + 64,x
        inx
        cpx #grid_sprite_multi - grid_sprite_hires
        bne -
        rts


grid_sprite_hires
        .byte %11111111, %11000000, 0
        .byte %10000000, %01000000, 0
        .byte %10000000, %01000000, 0
        .byte %10000000, %01000000, 0
        .byte %10000000, %01000000, 0
        .byte %10000000, %01000000, 0
        .byte %10000000, %01000000, 0
        .byte %10000000, %01000000, 0
        .byte %10000000, %01000000, 0
        .byte %11111111, %11000000, 0
grid_sprite_multi
        .byte %11111111, %11111111, %11000000
        .byte %10000000, %00000000, %01000000
        .byte %10000000, %00000000, %01000000
        .byte %10000000, %00000000, %01000000
        .byte %10000000, %00000000, %01000000
        .byte %10000000, %00000000, %01000000
        .byte %10000000, %00000000, %01000000
        .byte %10000000, %00000000, %01000000
        .byte %10000000, %00000000, %01000000
        .byte %11111111, %11111111, %11000000

hires_mask
        .byte $80, $40, $20, $10, $08, $04, $02, $01
multi_mask
        .byte $c0, $c0, $30, $30, $0c, $0c, $03, $03
multi_spr
        .byte $80, $80, $20, $20, $08, $08, $02, $02
multi_mc1
        .byte $40, $40, $10, $10, $04, $04, $01, $01
multi_mc2
        .byte $c0, $c0, $30, $30, $0c, $0c, $03, $03

hires_mask_out
        .byte %00111111, %11001111, %11110011, %11111100

spr_y_table
        .byte range(0, 63, 3)

        - = range(GRID_COLRAM, GRID_COLRAM + (21 * 40), 40)
grid_colram_lsb
        .byte <(-)
grid_colram_msb
        .byte >(-)



        zm_sprite_x     = zp + 4
        zm_sprite_bit   = zp + 5
        zm_colram_x     = zp + 6

        zm_sprite_data  = zp
        zm_colram_data  = zp + 2


; Zoom a single pixel
single_zoom

        ldy view.cursor_y
        lda grid_colram_lsb,y
        sta zm_colram_data
        lda grid_colram_msb,y
        sta zm_colram_data + 1

        ldy view.cursor_x
        ldx view.color_index
        bne +
        lda view.colors,x
        sta (zm_colram_data),y
        rts
+
        lda view.cursor_x
        and #$fe
        tay
        ldx view.color_index
        lda view.colors,x
        sta (zm_colram_data),y
        iny
        sta (zm_colram_data),y
        rts





; Zoom sprite
full_zoom
        ; determine sprite data location

        lda view.sprite_index
        jsr view.get_sprite_data_pointer
        stx zm_sprite_data
        sty zm_sprite_data + 1


        lda #<GRID_COLRAM
        ldx #>GRID_COLRAM
        sta zm_colram_data
        stx zm_colram_data + 1

        lda #0
        sta zm_sprite_x
        sta zm_sprite_bit
        sta zm_colram_x

fzm_more
        ldy zm_sprite_x
        ldx zm_sprite_bit
        lda (zp),y
        and hires_mask,x
        beq +
        ; plot single color pixel
        ldx #0
        jmp fzm_plot
+
        lda zm_sprite_x
        clc
        adc #$40
        tay
        lda (zp),y
        and multi_mask,x
        cmp multi_spr,x
        bne +
        ldx #1
        jmp fzm_plot
+
        cmp multi_mc1,x
        bne +
        ldx #2
        jmp fzm_plot
+
        cmp multi_mc2,x
        bne +
        ldx #3
        jmp fzm_plot
+
        ldx #4

fzm_plot
        lda view.colors,x
        ldy zm_colram_x
        sta (zp + 2),y

        inc zm_colram_x
        inc zm_sprite_bit
        lda zm_sprite_bit
        cmp #8
        bcc fzm_more

        lda #0
        sta zm_sprite_bit
        inc zm_sprite_x

        lda zm_colram_x
        cmp #24
        bcc fzm_more

        ; move to next row
        lda zm_colram_data
        clc
        adc #40
        sta zm_colram_data
        bcc +
        inc zm_colram_data + 1
+
        lda #0
        sta zm_colram_x

        lda zm_sprite_x
        cmp #63
        bcc fzm_more
        rts


plot_get_byte_offset
        lda view.cursor_x
        lsr
        lsr
        lsr
        clc
        ldy view.cursor_y
        adc spr_y_table,y
        rts


plot
        jsr view.get_sprite_data_pointer
        stx zp
        sty zp + 1
        lda view.color_index
        bne plot_mc
        ; plot single color pixel
        lda view.cursor_x
        and #7
        tax
        jsr plot_get_byte_offset
        tay
        lda (zp),y
        ora hires_mask,x
        sta (zp),y
        rts
plot_mc
        ; remove pixels
        lda view.cursor_x
        and #7
        lsr
        tax
        jsr plot_get_byte_offset
        tay
        lda (zp),y
        and hires_mask_out,x
        sta (zp),y
        tya
        clc
        adc #64
        tay
        lda (zp),y
        and hires_mask_out,x
        sta (zp),y

        ; plot multi color pixel
        lda view.color_index
        cmp #4
        beq +
        sec
        sbc #1
        asl
        asl
        asl
        sta _tmp +1
        lda view.cursor_x
        and #7
        clc
_tmp    adc #0
        tax
        lda (zp),y
        ora multi_spr,x
        sta (zp),y
+
        rts

