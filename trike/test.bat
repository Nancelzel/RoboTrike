asm86 trike.asm m1 ep db
asm86 eventq.asm m1 ep db
asm86 baud.asm m1 ep db
asm86 chips.asm m1 ep db
asm86 pport.asm m1 ep db
asm86 int.asm m1 ep db
asm86 inter.asm m1 ep db
asm86 motor.asm m1 ep db
asm86 parser.asm m1 ep db
asm86 parity.asm m1 ep db
asm86 queue.asm m1 ep db
asm86 serialr.asm m1 ep db
asm86 timer.asm m1 ep db
asm86 converts.asm m1 ep db
asm86 force.asm m1 ep db
asm86 trig.asm m1 ep db
asm86 flags.asm m1 ep db
link86 trike.obj, eventq.obj, baud.obj, chips.obj, pport.obj, int.obj, inter.obj, motor.obj TO remotep1.obj
link86 remotep1.obj, parity.obj, queue.obj, serialr.obj, timer.obj, converts.obj, parser.obj TO remotep2.obj
link86 remotep2.obj, force.obj, trig.obj, flags.obj TO trike.lnk
loc86 trike.lnk TO trike NOIC AD(SM(CODE(4000H),DATA(400H), STACK(7000H)))