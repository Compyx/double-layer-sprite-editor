; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass :

; Simple double layer sprite editor: one mc sprite and one sc sprite on top
;
; @author:      Bas Wassink <b.wassink@ziggo.nl>


        GETIN = $ffe4

        BG_COLOR = 11

        PROMPT_LOCATION = $0720

        zp = $14

        * = $0801

        .word (+), 2016
        .null $9e, format("%d", start)
+       .word 0

start
        jmp init

dialog  .binclude "dialog.asm"
edit    .binclude "edit.asm"
view    .binclude "view.asm"
zoom    .binclude "zoom.asm"


init
        ; Start editor
        lda #$37
        sta $01
        jsr $fda3
        jsr $fd15
        jsr $ff5b
        lda #BG_COLOR
        sta $d020
        sta $d021
        ldx #0
        lda #$0f
-       sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $db00,x
        inx
        bne -

        ; setup zoom and view
        jsr view.setup_background
        jsr zoom.setup_grid_chars
        jsr zoom.setup_grid_sprites
        jsr view.setup_info_text
        jsr view.update_info_colors
        jsr zoom.full_zoom
        jsr view.update_zoom_info

        ; setup IRQ
        sei
        lda #$7f
        sta $dc0d
        sta $dd0d
        ldx #0
        stx $dc0e
        stx $dc0f
        stx $dd0e
        stx $dd0f
        inx
        stx $d01a
        lda #$1b
        sta $d011
        lda #$17
        sta $d018
        lda #$08
        sta $d016

        lda #$2c
        ldx #<irq1
        ldy #>irq1
        sta $d012
        stx $0314
        sty $0315
        cli
        jmp event_loop

irq1
        lda #$17
        sta $d018
        lda #$ff
        sta $d015
        lda #$00
        sta $d010
        sta $d017
        sta $d01d

        lda #%10101010
        sta $d01c

        lda #$34
        sta $d001
        sta $d003
        sta $d005
        sta $d007
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f
        clc
        lda #$a4
        sta $d000
        sta $d002
        adc #48
        sta $d004
        sta $d006
        adc #48
        sta $d008
        sta $d00a
        clc
        adc #48
        sta $d00c
        sta $d00e
        lda #$f0
        sta $d010

        lda view.color_top
        sta $d027
        sta $d029
        sta $d02b
        sta $d02d
        lda view.color_bottom
        sta $d028
        sta $d02a
        sta $d02c
        sta $d02e
        lda view.color_mc1
        sta $d025
        lda view.color_mc2
        sta $d026


        lda view.sprite_index
        and #$3f
        asl
        clc
        adc #$80
        sta $07fc
        adc #1
        sta $07fd

        lda view.sprite_index
        clc
        adc #1
        and #$3f
        asl
        clc
        adc #$80
        sta $07fe
        adc #1
        sta $07ff

        lda view.sprite_index
        sec
        sbc #2
        and #$3f
        asl
        and #$7f
        adc #$80
        sta $07f8
        adc #1
        sta $07f9

        lda view.sprite_index
        sec
        sbc #1
        and #$3f
        asl
        and #$7f
        adc #$80
        sta $07fa
        adc #1
        sta $07fb


        jsr update_cursor_sprite

        lda #$50
        ldx #<irq2
        ldy #>irq2
do_irq
        sta $d012
        stx $0314
        sty $0315
        lda #1
        sta $d019
        jmp $ea81

irq2
        lda #1
        sta $d027
        sta $d028
cur_spr_y
        lda #$51
        sta $d001
cur_spr_x
        lda #$97
        sta $d000

spr_msb
        lda #$00
        sta $d010

ci_spr_y
        lda #$51        ; color index indicator sprite ypos
        sta $d003
        lda #$2f
        sta $d002
cur_spr_ptr
        lda #($0340 / 64)
        sta $07f8
ci_spr_ptr
        lda #($0340 / 64)
        sta $07f9

zoom_spr_enable
        lda #3
        sta $d015
        lda #0
        sta $d017
        sta $d01c

        lda #$2c
        ldx #<irq1
        ldy #>irq1
        sta $d012
        stx $0314
        sty $0315
        inc $d019
        jmp $ea31

event_loop
        jsr GETIN
        beq event_loop

el_color_inc
        ; check for color increments
        cmp #$21
        bcc el_color_select
        cmp #$26
        bcs el_color_select
        sec
        sbc #$21
        tax
        lda view.colors,x
        clc
        adc #1
        and #15
        sta view.colors,x
        jsr view.update_info_colors
        jsr view.update_bg_color
        jsr zoom.full_zoom
        jmp event_loop
el_color_select
        cmp #$31
        bcc el_other
        cmp #$36
        bcs el_other
        sec
        sbc #$31
        sta view.color_index
        clc
        asl
        asl
        asl
        clc
        adc #$51
        sta ci_spr_y + 1
        ldx #($0340/64)
        lda view.color_index
        beq +
        inx
        ; multi color selected, fix cursor x pos
        lda view.cursor_x
        and #$fe
        sta view.cursor_x
+
        stx ci_spr_ptr + 1
        jmp event_loop
el_other
        ; check for other keys
        ldx #0
-
        cmp event_handlers, x
        beq el_exec
        inx
        inx
        inx
        cpx #event_handlers_end-event_handlers
        bne -
        jmp event_loop
el_exec
        lda event_handlers + 1,x
        sta _exec + 1
        lda event_handlers + 2,x
        sta _exec + 2
_exec   jsr $0000
        jmp event_loop

; Event handler table: keycode, subroutine
event_handlers
        .byte $20
        .word plot_pixel

        .byte $11
        .word crsr_down

        .byte $1d
        .word crsr_right

        .byte $91
        .word crsr_up

        .byte $9d
        .word crsr_left

        .byte ","
        .word spr_index_dec

        .byte "."
        .word spr_index_inc

        .byte "<"
        .word spr_index_sub

        .byte ">"
        .word spr_index_add

        .byte $43       ; c - copy to buffer
        .word edit.buffer_copy

        .byte $50       ; p - paste from buffer
        .word edit.buffer_paste

        .byte $59       ; y - ROL up in Y direction
        .word edit.shift_up

        .byte $d9       ; Y - ROL down in Y direction
        .word edit.shift_down

        .byte $58
        .word edit.shift_left

        .byte $d8
        .word edit.shift_right

        .byte $cd
        .word edit.flip_vertical

        .byte $4d
        .word edit.flip_horizontal

        .byte $49
        .word edit.clear_sprite

        .byte $c9
        .word edit.clear_all

        .byte $85
        .word display_help

event_handlers_end


; Event handlers

crsr_up
        lda view.cursor_y
        beq +
        dec view.cursor_y
+       jmp view.update_zoom_info

crsr_down
        lda view.cursor_y
        cmp #20
        beq +
        inc view.cursor_y
+       jmp view.update_zoom_info

crsr_right
        lda view.color_index
        bne cr_multi
        ; single color movement
        lda view.cursor_x
        cmp #23
        beq +
        inc view.cursor_x
+       jmp view.update_zoom_info
cr_multi
        lda view.cursor_x
        cmp #22
        bcs +
        lda view.cursor_x
        clc
        adc #2
        and #$fe
        sta view.cursor_x
+       jmp view.update_zoom_info

crsr_left
        lda view.color_index
        bne cl_multi
        ; single color
        lda view.cursor_x
        beq +
        dec view.cursor_x
+       jmp view.update_zoom_info
cl_multi
        lda view.cursor_x
        cmp #2
        bcc +
        lda view.cursor_x
        sec
        sbc #2
        and #$fe
        sta view.cursor_x
+       jmp view.update_zoom_info

spr_index_inc
        lda view.sprite_index
        clc
        adc #1
        and #$3f
        sta view.sprite_index
        jsr zoom.full_zoom
        jmp view.update_zoom_info

spr_index_dec
        lda view.sprite_index
        sec
        sbc #1
        and #$3f
        sta view.sprite_index
        jsr zoom.full_zoom
        jmp view.update_zoom_info

spr_index_add
        lda view.sprite_index
        clc
        adc #4
        and #$3f
        sta view.sprite_index
        jsr zoom.full_zoom
        jmp view.update_zoom_info

spr_index_sub
        lda view.sprite_index
        sec
        sbc #4
        and #$3f
        sta view.sprite_index
        jsr zoom.full_zoom
        jmp view.update_zoom_info

update_cursor_sprite
        lda view.cursor_x
        asl
        asl
        asl
        clc
        adc #$97
        sta cur_spr_x + 1
        lda view.cursor_x
        cmp #14
        lda #0
        adc #0
        sta spr_msb + 1
        lda view.cursor_y
        asl
        asl
        asl
        clc
        adc #$51
        sta cur_spr_y + 1

        ldx #(zoom.GRID_SPRITES / 64)
        lda view.color_index
        beq +
        inx
+       stx cur_spr_ptr + 1
        rts

plot_pixel
        jsr zoom.plot
        jsr zoom.single_zoom
        rts


display_help
        lda #15
        ldx #<help_text
        ldy #>help_text
        jsr dialog.dialog_anykey
        rts


help_text
        .text $f1, "CRSR", $ff, "      move cursor", $80

        .text $f1, "Space", $ff, "     plot pixel", $80

        .text $f1, "1", $ff, "-", $f1, "5", $ff, "       choose color", $80

        .text $f1, "Shift", $ff, "+", $f1, "1", $ff, "-", $f1, "5", $ff
        .text " change colors", $80

        .text $f1, "c", $ff, " & ", $f1, "v", $ff
        .text "     copy to/paste from buffer", $80

        .text $f1, ",", $ff, " & ", $f1, ".", $ff
        .text "     dec/inc sprite index by 1", $80

        .text $f1, "<", $ff, " & ", $f1, ">", $ff
        .text "     dec/inc sprite index by 4", $80

        .text $f1, "x", $ff, " & ", $f1, "X", $ff
        .text "     roll sprite left/right", $80

        .text $f1, "y", $ff, " & ", $f1, "Y", $ff
        .text "     roll sprite up/down", $80

        .text $f1, "m", $ff, " & ", $f1, "M", $ff
        .text "     mirror sprite in X/Y dir.", $80

        .text $f1, "i", $ff, " & ", $f1, "I", $ff
        .text "     clear current/all sprites", $80

        .byte $80
        ;      0123456789abcdef0123456789abcdef01234567
        .text "Sprites are located at $2000-$3fff,", $80
        .text "use cartridge or emulator to load/save"
        .byte 0


; Sprite data section
; For now: load example sprites:
        * = $2000

;.binary "ball.prg", 2, 64       ; top layer
;.binary "ball.prg", 2 + 128, 64 ; bottom layer
.binary "0-9v2", 2

