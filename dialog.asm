; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :
;
; Simple dialog module
;

        FRAME_BORDERCOLOR = $0e
        FRAME_TEXTCOLOR   = $0f

        FRAME_TOPLEFT     = $70
        FRAME_HORIZONTAL  = $40
        FRAME_TOPRIGHT    = $6e
        FRAME_BOTTOMLEFT  = $6d
        FRAME_VERTICAL    = $5d
        FRAME_BOTTOMRIGHT = $7d

        dl_screen       = zp
        dl_colram       = zp + 2
        dl_text         = zp + 4
        dl_height       = zp + 6
        dl_width        = zp + 7
        dl_color        = zp + 8

dl_cleanup
        jsr view.setup_info_text
        jsr view.update_info_colors
        jsr zoom.setup_grid_chars
        jsr zoom.full_zoom
        lda #3
        sta zoom_spr_enable + 1
        rts


; Display yes/no prompt
;
; @param A:     number of lines to reserve for prompt
; @param X:     message LSB
; @param Y:     message MSB
;
; @return:      answer in Carry (carry set = yes, carry cleard = no)
dialog_yesno
        jsr dl_setup
        jmp dl_query_yesno



dialog_anykey
        jsr dl_setup
-       jsr GETIN
        beq -
        jmp dl_cleanup


dl_setup
        sta dl_height
        stx dl_text
        sty dl_text +1

        lda #0
        sta zoom_spr_enable + 1

        jsr dl_render_frame
        jsr dl_render_text
        rts

dl_query_yesno
-       jsr GETIN
        cmp #$59
        beq +
        cmp #$4e
        bne -
        jsr dl_cleanup
        clc
        rts
+
        jsr dl_cleanup
        sec
        rts





dl_render_frame
        lda #23
        sec
        sbc dl_height
        tax
        lda dl_scrtab_lsb,x
        sta dl_screen
        sta dl_colram
        lda dl_scrtab_msb,x
        sta dl_screen + 1
        clc
        adc #$d4
        sta dl_colram + 1


        ; render top of frame
        ldy #39
        lda #FRAME_BORDERCOLOR
-       sta (dl_colram),y
        dey
        bpl -

        ldy #0
        sta (dl_colram),y
        lda #FRAME_TOPLEFT
        sta (dl_screen),y
        iny

        lda #FRAME_HORIZONTAL
-
        sta (dl_screen),y
        iny
        cpy #39
        bne -
        lda #FRAME_TOPRIGHT
        sta (dl_screen),y

        ; render left and right of frame, clear the inside of frame
        ldx dl_height
-
        lda dl_screen
        clc
        adc #40
        sta dl_screen
        sta dl_colram
        bcc +
        inc dl_screen + 1
        inc dl_colram + 1
+
        ldy #0
        lda #FRAME_VERTICAL
        sta (dl_screen),y
        lda #FRAME_BORDERCOLOR
        sta (dl_colram),y
        iny
-
        lda #$20
        sta (dl_screen),y
        lda #FRAME_TEXTCOLOR
        sta (dl_colram),y
        iny
        cpy #39
        bne -

        lda #FRAME_BORDERCOLOR
        sta (dl_colram),y
        lda #FRAME_VERTICAL
        sta (dl_screen),y

        dex
        bne --

        ldy #79
        lda #FRAME_BORDERCOLOR
-
        sta (dl_colram),y
        dey
        cpy #39
        bne -
        iny
        lda #FRAME_BOTTOMLEFT
        sta (dl_screen),y
        iny
        lda #FRAME_HORIZONTAL
-       sta (dl_screen),y
        iny
        cpy #79
        bne -
        lda #FRAME_BOTTOMRIGHT
        sta (dl_screen),y
        rts

dl_render_text
        ; set default color
        lda #FRAME_TEXTCOLOR
        sta dl_color
        lda #24
        sec
        sbc dl_height
        tax
        lda dl_scrtab_lsb,x
        clc
        adc #1
        sta dl_screen
        sta dl_colram
        lda dl_scrtab_msb,x
        sta dl_screen + 1
        clc
        adc #$d4
        sta dl_colram + 1

dl_rt_more
        lda #0
        sta dl_width
-
        ldy #0
        lda (dl_text),y
        bne +
        rts
+
        cmp #$f0                ; $f0-$ff = set color
        bcc ++
        and #$0f
        sta dl_color
        inc dl_text
        bne +
        inc dl_text + 1
+       jmp -
+
        cmp #$80                ; $80 = linefeed
        bne +++
        lda dl_screen
        clc
        adc #40
        sta dl_screen
        sta dl_colram
        bcc +
        inc dl_screen + 1
        inc dl_colram + 1
+
        inc dl_text
        bne +
        inc dl_text + 1
+
        jmp dl_rt_more

+
        ldy dl_width
        sta (dl_screen),y
        lda dl_color
        sta (dl_colram),y

        inc dl_text
        bne +
        inc dl_text + 1
+
        inc dl_width
        lda dl_width
        cmp #38
        bcc -
dl_rt_cr
        lda dl_screen
        clc
        adc #40
        sta dl_screen
        sta dl_colram
        bcc +
        inc dl_screen + 1
        inc dl_colram + 1
+
        lda #0
        sta dl_width
        jmp dl_rt_more




; screen lines table

        - = range($0400, $07e8, 40)

dl_scrtab_lsb
        .byte <(-)
dl_scrtab_msb
        .byte >(-)

