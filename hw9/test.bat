asm86 remote.asm m1 ep db
asm86 eventq.asm m1 ep db
asm86 baud.asm m1 ep db
asm86 chips.asm m1 ep db
asm86 display.asm m1 ep db
asm86 int.asm m1 ep db
asm86 inter.asm m1 ep db
asm86 keypad.asm m1 ep db
asm86 parity.asm m1 ep db
asm86 queue.asm m1 ep db
asm86 serialr.asm m1 ep db
asm86 timer.asm m1 ep db
asm86 converts.asm m1 ep db
asm86 segtable.asm m1 ep db
link86 remote.obj, eventq.obj, baud.obj, chips.obj, display.obj, int.obj, inter.obj, keypad.obj TO remotep1.obj
link86 remotep1.obj, parity.obj, queue.obj, serialr.obj, timer.obj, converts.obj, segtable.obj TO remote.lnk
loc86 remote.lnk TO remote NOIC AD(SM(CODE(4000H),DATA(400H), STACK(7000H)))