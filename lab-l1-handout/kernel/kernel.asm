
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8d013103          	ld	sp,-1840(sp) # 800088d0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8e070713          	addi	a4,a4,-1824 # 80008930 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	c8e78793          	addi	a5,a5,-882 # 80005cf0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca5f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8e650513          	addi	a0,a0,-1818 # 80010a70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8d648493          	addi	s1,s1,-1834 # 80010a70 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	96690913          	addi	s2,s2,-1690 # 80010b08 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	84a50513          	addi	a0,a0,-1974 # 80010a70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	83450513          	addi	a0,a0,-1996 # 80010a70 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72b23          	sw	a5,-1898(a4) # 80010b08 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7a450513          	addi	a0,a0,1956 # 80010a70 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	77650513          	addi	a0,a0,1910 # 80010a70 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	75270713          	addi	a4,a4,1874 # 80010a70 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	72878793          	addi	a5,a5,1832 # 80010a70 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7927a783          	lw	a5,1938(a5) # 80010b08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6e670713          	addi	a4,a4,1766 # 80010a70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6d648493          	addi	s1,s1,1750 # 80010a70 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	69a70713          	addi	a4,a4,1690 # 80010a70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72223          	sw	a5,1828(a4) # 80010b10 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	65e78793          	addi	a5,a5,1630 # 80010a70 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7ab23          	sw	a2,1750(a5) # 80010b0c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ca50513          	addi	a0,a0,1738 # 80010b08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	61050513          	addi	a0,a0,1552 # 80010a70 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	79078793          	addi	a5,a5,1936 # 80020c08 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5e07a223          	sw	zero,1508(a5) # 80010b30 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	36f72823          	sw	a5,880(a4) # 800088f0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	574dad83          	lw	s11,1396(s11) # 80010b30 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	51e50513          	addi	a0,a0,1310 # 80010b18 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3c050513          	addi	a0,a0,960 # 80010b18 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3a448493          	addi	s1,s1,932 # 80010b18 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	36450513          	addi	a0,a0,868 # 80010b38 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0f07a783          	lw	a5,240(a5) # 800088f0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0c07b783          	ld	a5,192(a5) # 800088f8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0c073703          	ld	a4,192(a4) # 80008900 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2d6a0a13          	addi	s4,s4,726 # 80010b38 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	08e48493          	addi	s1,s1,142 # 800088f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	08e98993          	addi	s3,s3,142 # 80008900 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	26850513          	addi	a0,a0,616 # 80010b38 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0107a783          	lw	a5,16(a5) # 800088f0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	01673703          	ld	a4,22(a4) # 80008900 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0067b783          	ld	a5,6(a5) # 800088f8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	23a98993          	addi	s3,s3,570 # 80010b38 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	ff248493          	addi	s1,s1,-14 # 800088f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	ff290913          	addi	s2,s2,-14 # 80008900 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	20448493          	addi	s1,s1,516 # 80010b38 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fae7bc23          	sd	a4,-72(a5) # 80008900 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	17e48493          	addi	s1,s1,382 # 80010b38 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	3a478793          	addi	a5,a5,932 # 80021da0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	15490913          	addi	s2,s2,340 # 80010b70 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0b650513          	addi	a0,a0,182 # 80010b70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	2d250513          	addi	a0,a0,722 # 80021da0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	08048493          	addi	s1,s1,128 # 80010b70 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	06850513          	addi	a0,a0,104 # 80010b70 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	03c50513          	addi	a0,a0,60 # 80010b70 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd261>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a8070713          	addi	a4,a4,-1408 # 80008908 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	808080e7          	jalr	-2040(ra) # 800026c6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e6a080e7          	jalr	-406(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	768080e7          	jalr	1896(ra) # 8000269e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	788080e7          	jalr	1928(ra) # 800026c6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	dd4080e7          	jalr	-556(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	de2080e7          	jalr	-542(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	f78080e7          	jalr	-136(ra) # 80002ece <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	618080e7          	jalr	1560(ra) # 80003576 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	5be080e7          	jalr	1470(ra) # 80004524 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	eca080e7          	jalr	-310(ra) # 80005e38 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	98f72223          	sw	a5,-1660(a4) # 80008908 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9787b783          	ld	a5,-1672(a5) # 80008910 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd257>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7be23          	sd	a0,1724(a5) # 80008910 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd260>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	77448493          	addi	s1,s1,1908 # 80010fc0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	15aa0a13          	addi	s4,s4,346 # 800169c0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2a850513          	addi	a0,a0,680 # 80010b90 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2a850513          	addi	a0,a0,680 # 80010ba8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6b048493          	addi	s1,s1,1712 # 80010fc0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	08e98993          	addi	s3,s3,142 # 800169c0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	22450513          	addi	a0,a0,548 # 80010bc0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1cc70713          	addi	a4,a4,460 # 80010b90 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e847a783          	lw	a5,-380(a5) # 80008880 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	cd8080e7          	jalr	-808(ra) # 800026de <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e607a523          	sw	zero,-406(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	ad6080e7          	jalr	-1322(ra) # 800034f6 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	15a90913          	addi	s2,s2,346 # 80010b90 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e3c78793          	addi	a5,a5,-452 # 80008884 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3fe48493          	addi	s1,s1,1022 # 80010fc0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	df690913          	addi	s2,s2,-522 # 800169c0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c8a7b023          	sd	a0,-896(a5) # 80008918 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bec58593          	addi	a1,a1,-1044 # 80008890 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	23e080e7          	jalr	574(ra) # 80003f20 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	7a4080e7          	jalr	1956(ra) # 800045b6 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	912080e7          	jalr	-1774(ra) # 80003736 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d5848493          	addi	s1,s1,-680 # 80010ba8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	cd270713          	addi	a4,a4,-814 # 80010b90 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	cfc70713          	addi	a4,a4,-772 # 80010bc8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	cb4a0a13          	addi	s4,s4,-844 # 80010b90 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	ada90913          	addi	s2,s2,-1318 # 800169c0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0c648493          	addi	s1,s1,198 # 80010fc0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	700080e7          	jalr	1792(ra) # 80002634 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c2670713          	addi	a4,a4,-986 # 80010b90 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	c0090913          	addi	s2,s2,-1024 # 80010b90 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c2058593          	addi	a1,a1,-992 # 80010bc8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	67e080e7          	jalr	1662(ra) # 80002634 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	ef448493          	addi	s1,s1,-268 # 80010fc0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	8e890913          	addi	s2,s2,-1816 # 800169c0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	e8048493          	addi	s1,s1,-384 # 80010fc0 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	7d0a0a13          	addi	s4,s4,2000 # 80008918 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	87098993          	addi	s3,s3,-1936 # 800169c0 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7747b783          	ld	a5,1908(a5) # 80008918 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	440080e7          	jalr	1088(ra) # 80004608 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	f60080e7          	jalr	-160(ra) # 80004140 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	742080e7          	jalr	1858(ra) # 8000392e <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	fca080e7          	jalr	-54(ra) # 800041be <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	9a848493          	addi	s1,s1,-1624 # 80010ba8 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d5248493          	addi	s1,s1,-686 # 80010fc0 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	74a98993          	addi	s3,s3,1866 # 800169c0 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	85650513          	addi	a0,a0,-1962 # 80010ba8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	65898993          	addi	s3,s3,1624 # 800169c0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	838c0c13          	addi	s8,s8,-1992 # 80010ba8 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c4648493          	addi	s1,s1,-954 # 80010fc0 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000e517          	auipc	a0,0xe
    800023bc:	7f050513          	addi	a0,a0,2032 # 80010ba8 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	7d450513          	addi	a0,a0,2004 # 80010ba8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	78650513          	addi	a0,a0,1926 # 80010ba8 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	bea48493          	addi	s1,s1,-1046 # 80011118 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	5e290913          	addi	s2,s2,1506 # 80016b18 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d70b8b93          	addi	s7,s7,-656 # 800082c8 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <getprocesses>:

int getprocesses(struct process_info * proc_info) {
    800025b8:	7139                	addi	sp,sp,-64
    800025ba:	fc06                	sd	ra,56(sp)
    800025bc:	f822                	sd	s0,48(sp)
    800025be:	f426                	sd	s1,40(sp)
    800025c0:	f04a                	sd	s2,32(sp)
    800025c2:	ec4e                	sd	s3,24(sp)
    800025c4:	e852                	sd	s4,16(sp)
    800025c6:	e456                	sd	s5,8(sp)
    800025c8:	0080                	addi	s0,sp,64
    800025ca:	8aaa                	mv	s5,a0
    struct proc *cur_proc;
    int proc_count = 0;

    for (cur_proc = proc; cur_proc < &proc[NPROC]; cur_proc++) {
    800025cc:	0000f497          	auipc	s1,0xf
    800025d0:	b4c48493          	addi	s1,s1,-1204 # 80011118 <proc+0x158>
    800025d4:	00014a17          	auipc	s4,0x14
    800025d8:	544a0a13          	addi	s4,s4,1348 # 80016b18 <bcache+0x140>
    int proc_count = 0;
    800025dc:	4981                	li	s3,0
    800025de:	a029                	j	800025e8 <getprocesses+0x30>
    for (cur_proc = proc; cur_proc < &proc[NPROC]; cur_proc++) {
    800025e0:	16848493          	addi	s1,s1,360
    800025e4:	03448e63          	beq	s1,s4,80002620 <getprocesses+0x68>
        if (cur_proc->state == UNUSED) {
    800025e8:	ec04a783          	lw	a5,-320(s1)
    800025ec:	dbf5                	beqz	a5,800025e0 <getprocesses+0x28>
            continue;
        }

        proc_info[proc_count].pid = cur_proc->pid;
    800025ee:	00199913          	slli	s2,s3,0x1
    800025f2:	994e                	add	s2,s2,s3
    800025f4:	090e                	slli	s2,s2,0x3
    800025f6:	9956                	add	s2,s2,s5
    800025f8:	ed84a783          	lw	a5,-296(s1)
    800025fc:	00f92023          	sw	a5,0(s2)
        proc_info[proc_count].status = cur_proc->state;
    80002600:	ec04a783          	lw	a5,-320(s1)
    80002604:	00f92223          	sw	a5,4(s2)
        strncpy(proc_info[proc_count].name, cur_proc->name, sizeof(proc_info[proc_count].name) - 1);
    80002608:	463d                	li	a2,15
    8000260a:	85a6                	mv	a1,s1
    8000260c:	00890513          	addi	a0,s2,8
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	7ce080e7          	jalr	1998(ra) # 80000dde <strncpy>
        proc_info[proc_count].name[sizeof(proc_info[proc_count].name) - 1] = '\0';
    80002618:	00090ba3          	sb	zero,23(s2)
        proc_count++;
    8000261c:	2985                	addiw	s3,s3,1
    8000261e:	b7c9                	j	800025e0 <getprocesses+0x28>
    }

    return proc_count;
}
    80002620:	854e                	mv	a0,s3
    80002622:	70e2                	ld	ra,56(sp)
    80002624:	7442                	ld	s0,48(sp)
    80002626:	74a2                	ld	s1,40(sp)
    80002628:	7902                	ld	s2,32(sp)
    8000262a:	69e2                	ld	s3,24(sp)
    8000262c:	6a42                	ld	s4,16(sp)
    8000262e:	6aa2                	ld	s5,8(sp)
    80002630:	6121                	addi	sp,sp,64
    80002632:	8082                	ret

0000000080002634 <swtch>:
    80002634:	00153023          	sd	ra,0(a0)
    80002638:	00253423          	sd	sp,8(a0)
    8000263c:	e900                	sd	s0,16(a0)
    8000263e:	ed04                	sd	s1,24(a0)
    80002640:	03253023          	sd	s2,32(a0)
    80002644:	03353423          	sd	s3,40(a0)
    80002648:	03453823          	sd	s4,48(a0)
    8000264c:	03553c23          	sd	s5,56(a0)
    80002650:	05653023          	sd	s6,64(a0)
    80002654:	05753423          	sd	s7,72(a0)
    80002658:	05853823          	sd	s8,80(a0)
    8000265c:	05953c23          	sd	s9,88(a0)
    80002660:	07a53023          	sd	s10,96(a0)
    80002664:	07b53423          	sd	s11,104(a0)
    80002668:	0005b083          	ld	ra,0(a1)
    8000266c:	0085b103          	ld	sp,8(a1)
    80002670:	6980                	ld	s0,16(a1)
    80002672:	6d84                	ld	s1,24(a1)
    80002674:	0205b903          	ld	s2,32(a1)
    80002678:	0285b983          	ld	s3,40(a1)
    8000267c:	0305ba03          	ld	s4,48(a1)
    80002680:	0385ba83          	ld	s5,56(a1)
    80002684:	0405bb03          	ld	s6,64(a1)
    80002688:	0485bb83          	ld	s7,72(a1)
    8000268c:	0505bc03          	ld	s8,80(a1)
    80002690:	0585bc83          	ld	s9,88(a1)
    80002694:	0605bd03          	ld	s10,96(a1)
    80002698:	0685bd83          	ld	s11,104(a1)
    8000269c:	8082                	ret

000000008000269e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000269e:	1141                	addi	sp,sp,-16
    800026a0:	e406                	sd	ra,8(sp)
    800026a2:	e022                	sd	s0,0(sp)
    800026a4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026a6:	00006597          	auipc	a1,0x6
    800026aa:	c5258593          	addi	a1,a1,-942 # 800082f8 <states.0+0x30>
    800026ae:	00014517          	auipc	a0,0x14
    800026b2:	31250513          	addi	a0,a0,786 # 800169c0 <tickslock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	490080e7          	jalr	1168(ra) # 80000b46 <initlock>
}
    800026be:	60a2                	ld	ra,8(sp)
    800026c0:	6402                	ld	s0,0(sp)
    800026c2:	0141                	addi	sp,sp,16
    800026c4:	8082                	ret

00000000800026c6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026c6:	1141                	addi	sp,sp,-16
    800026c8:	e422                	sd	s0,8(sp)
    800026ca:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026cc:	00003797          	auipc	a5,0x3
    800026d0:	59478793          	addi	a5,a5,1428 # 80005c60 <kernelvec>
    800026d4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026d8:	6422                	ld	s0,8(sp)
    800026da:	0141                	addi	sp,sp,16
    800026dc:	8082                	ret

00000000800026de <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026de:	1141                	addi	sp,sp,-16
    800026e0:	e406                	sd	ra,8(sp)
    800026e2:	e022                	sd	s0,0(sp)
    800026e4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	2c6080e7          	jalr	710(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026f2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026f4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026f8:	00005697          	auipc	a3,0x5
    800026fc:	90868693          	addi	a3,a3,-1784 # 80007000 <_trampoline>
    80002700:	00005717          	auipc	a4,0x5
    80002704:	90070713          	addi	a4,a4,-1792 # 80007000 <_trampoline>
    80002708:	8f15                	sub	a4,a4,a3
    8000270a:	040007b7          	lui	a5,0x4000
    8000270e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002710:	07b2                	slli	a5,a5,0xc
    80002712:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002714:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002718:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000271a:	18002673          	csrr	a2,satp
    8000271e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002720:	6d30                	ld	a2,88(a0)
    80002722:	6138                	ld	a4,64(a0)
    80002724:	6585                	lui	a1,0x1
    80002726:	972e                	add	a4,a4,a1
    80002728:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000272a:	6d38                	ld	a4,88(a0)
    8000272c:	00000617          	auipc	a2,0x0
    80002730:	13060613          	addi	a2,a2,304 # 8000285c <usertrap>
    80002734:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002736:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002738:	8612                	mv	a2,tp
    8000273a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000273c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002740:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002744:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002748:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000274c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000274e:	6f18                	ld	a4,24(a4)
    80002750:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002754:	6928                	ld	a0,80(a0)
    80002756:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002758:	00005717          	auipc	a4,0x5
    8000275c:	94470713          	addi	a4,a4,-1724 # 8000709c <userret>
    80002760:	8f15                	sub	a4,a4,a3
    80002762:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002764:	577d                	li	a4,-1
    80002766:	177e                	slli	a4,a4,0x3f
    80002768:	8d59                	or	a0,a0,a4
    8000276a:	9782                	jalr	a5
}
    8000276c:	60a2                	ld	ra,8(sp)
    8000276e:	6402                	ld	s0,0(sp)
    80002770:	0141                	addi	sp,sp,16
    80002772:	8082                	ret

0000000080002774 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002774:	1101                	addi	sp,sp,-32
    80002776:	ec06                	sd	ra,24(sp)
    80002778:	e822                	sd	s0,16(sp)
    8000277a:	e426                	sd	s1,8(sp)
    8000277c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000277e:	00014497          	auipc	s1,0x14
    80002782:	24248493          	addi	s1,s1,578 # 800169c0 <tickslock>
    80002786:	8526                	mv	a0,s1
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	44e080e7          	jalr	1102(ra) # 80000bd6 <acquire>
  ticks++;
    80002790:	00006517          	auipc	a0,0x6
    80002794:	19050513          	addi	a0,a0,400 # 80008920 <ticks>
    80002798:	411c                	lw	a5,0(a0)
    8000279a:	2785                	addiw	a5,a5,1
    8000279c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000279e:	00000097          	auipc	ra,0x0
    800027a2:	91a080e7          	jalr	-1766(ra) # 800020b8 <wakeup>
  release(&tickslock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	4e2080e7          	jalr	1250(ra) # 80000c8a <release>
}
    800027b0:	60e2                	ld	ra,24(sp)
    800027b2:	6442                	ld	s0,16(sp)
    800027b4:	64a2                	ld	s1,8(sp)
    800027b6:	6105                	addi	sp,sp,32
    800027b8:	8082                	ret

00000000800027ba <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ba:	1101                	addi	sp,sp,-32
    800027bc:	ec06                	sd	ra,24(sp)
    800027be:	e822                	sd	s0,16(sp)
    800027c0:	e426                	sd	s1,8(sp)
    800027c2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027c4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027c8:	00074d63          	bltz	a4,800027e2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027cc:	57fd                	li	a5,-1
    800027ce:	17fe                	slli	a5,a5,0x3f
    800027d0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027d2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027d4:	06f70363          	beq	a4,a5,8000283a <devintr+0x80>
  }
}
    800027d8:	60e2                	ld	ra,24(sp)
    800027da:	6442                	ld	s0,16(sp)
    800027dc:	64a2                	ld	s1,8(sp)
    800027de:	6105                	addi	sp,sp,32
    800027e0:	8082                	ret
     (scause & 0xff) == 9){
    800027e2:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027e6:	46a5                	li	a3,9
    800027e8:	fed792e3          	bne	a5,a3,800027cc <devintr+0x12>
    int irq = plic_claim();
    800027ec:	00003097          	auipc	ra,0x3
    800027f0:	57c080e7          	jalr	1404(ra) # 80005d68 <plic_claim>
    800027f4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027f6:	47a9                	li	a5,10
    800027f8:	02f50763          	beq	a0,a5,80002826 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027fc:	4785                	li	a5,1
    800027fe:	02f50963          	beq	a0,a5,80002830 <devintr+0x76>
    return 1;
    80002802:	4505                	li	a0,1
    } else if(irq){
    80002804:	d8f1                	beqz	s1,800027d8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002806:	85a6                	mv	a1,s1
    80002808:	00006517          	auipc	a0,0x6
    8000280c:	af850513          	addi	a0,a0,-1288 # 80008300 <states.0+0x38>
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	d7a080e7          	jalr	-646(ra) # 8000058a <printf>
      plic_complete(irq);
    80002818:	8526                	mv	a0,s1
    8000281a:	00003097          	auipc	ra,0x3
    8000281e:	572080e7          	jalr	1394(ra) # 80005d8c <plic_complete>
    return 1;
    80002822:	4505                	li	a0,1
    80002824:	bf55                	j	800027d8 <devintr+0x1e>
      uartintr();
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	172080e7          	jalr	370(ra) # 80000998 <uartintr>
    8000282e:	b7ed                	j	80002818 <devintr+0x5e>
      virtio_disk_intr();
    80002830:	00004097          	auipc	ra,0x4
    80002834:	a24080e7          	jalr	-1500(ra) # 80006254 <virtio_disk_intr>
    80002838:	b7c5                	j	80002818 <devintr+0x5e>
    if(cpuid() == 0){
    8000283a:	fffff097          	auipc	ra,0xfffff
    8000283e:	146080e7          	jalr	326(ra) # 80001980 <cpuid>
    80002842:	c901                	beqz	a0,80002852 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002844:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002848:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000284a:	14479073          	csrw	sip,a5
    return 2;
    8000284e:	4509                	li	a0,2
    80002850:	b761                	j	800027d8 <devintr+0x1e>
      clockintr();
    80002852:	00000097          	auipc	ra,0x0
    80002856:	f22080e7          	jalr	-222(ra) # 80002774 <clockintr>
    8000285a:	b7ed                	j	80002844 <devintr+0x8a>

000000008000285c <usertrap>:
{
    8000285c:	1101                	addi	sp,sp,-32
    8000285e:	ec06                	sd	ra,24(sp)
    80002860:	e822                	sd	s0,16(sp)
    80002862:	e426                	sd	s1,8(sp)
    80002864:	e04a                	sd	s2,0(sp)
    80002866:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000286c:	1007f793          	andi	a5,a5,256
    80002870:	e3b1                	bnez	a5,800028b4 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002872:	00003797          	auipc	a5,0x3
    80002876:	3ee78793          	addi	a5,a5,1006 # 80005c60 <kernelvec>
    8000287a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	12e080e7          	jalr	302(ra) # 800019ac <myproc>
    80002886:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002888:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000288a:	14102773          	csrr	a4,sepc
    8000288e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002890:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002894:	47a1                	li	a5,8
    80002896:	02f70763          	beq	a4,a5,800028c4 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	f20080e7          	jalr	-224(ra) # 800027ba <devintr>
    800028a2:	892a                	mv	s2,a0
    800028a4:	c151                	beqz	a0,80002928 <usertrap+0xcc>
  if(killed(p))
    800028a6:	8526                	mv	a0,s1
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	a54080e7          	jalr	-1452(ra) # 800022fc <killed>
    800028b0:	c929                	beqz	a0,80002902 <usertrap+0xa6>
    800028b2:	a099                	j	800028f8 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028b4:	00006517          	auipc	a0,0x6
    800028b8:	a6c50513          	addi	a0,a0,-1428 # 80008320 <states.0+0x58>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	c84080e7          	jalr	-892(ra) # 80000540 <panic>
    if(killed(p))
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	a38080e7          	jalr	-1480(ra) # 800022fc <killed>
    800028cc:	e921                	bnez	a0,8000291c <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028ce:	6cb8                	ld	a4,88(s1)
    800028d0:	6f1c                	ld	a5,24(a4)
    800028d2:	0791                	addi	a5,a5,4
    800028d4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028da:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028de:	10079073          	csrw	sstatus,a5
    syscall();
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	2d4080e7          	jalr	724(ra) # 80002bb6 <syscall>
  if(killed(p))
    800028ea:	8526                	mv	a0,s1
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	a10080e7          	jalr	-1520(ra) # 800022fc <killed>
    800028f4:	c911                	beqz	a0,80002908 <usertrap+0xac>
    800028f6:	4901                	li	s2,0
    exit(-1);
    800028f8:	557d                	li	a0,-1
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	88e080e7          	jalr	-1906(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002902:	4789                	li	a5,2
    80002904:	04f90f63          	beq	s2,a5,80002962 <usertrap+0x106>
  usertrapret();
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	dd6080e7          	jalr	-554(ra) # 800026de <usertrapret>
}
    80002910:	60e2                	ld	ra,24(sp)
    80002912:	6442                	ld	s0,16(sp)
    80002914:	64a2                	ld	s1,8(sp)
    80002916:	6902                	ld	s2,0(sp)
    80002918:	6105                	addi	sp,sp,32
    8000291a:	8082                	ret
      exit(-1);
    8000291c:	557d                	li	a0,-1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	86a080e7          	jalr	-1942(ra) # 80002188 <exit>
    80002926:	b765                	j	800028ce <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000292c:	5890                	lw	a2,48(s1)
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	a1250513          	addi	a0,a0,-1518 # 80008340 <states.0+0x78>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c54080e7          	jalr	-940(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002942:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a2a50513          	addi	a0,a0,-1494 # 80008370 <states.0+0xa8>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c3c080e7          	jalr	-964(ra) # 8000058a <printf>
    setkilled(p);
    80002956:	8526                	mv	a0,s1
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	978080e7          	jalr	-1672(ra) # 800022d0 <setkilled>
    80002960:	b769                	j	800028ea <usertrap+0x8e>
    yield();
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	6b6080e7          	jalr	1718(ra) # 80002018 <yield>
    8000296a:	bf79                	j	80002908 <usertrap+0xac>

000000008000296c <kerneltrap>:
{
    8000296c:	7179                	addi	sp,sp,-48
    8000296e:	f406                	sd	ra,40(sp)
    80002970:	f022                	sd	s0,32(sp)
    80002972:	ec26                	sd	s1,24(sp)
    80002974:	e84a                	sd	s2,16(sp)
    80002976:	e44e                	sd	s3,8(sp)
    80002978:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002982:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002986:	1004f793          	andi	a5,s1,256
    8000298a:	cb85                	beqz	a5,800029ba <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000298c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002990:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002992:	ef85                	bnez	a5,800029ca <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002994:	00000097          	auipc	ra,0x0
    80002998:	e26080e7          	jalr	-474(ra) # 800027ba <devintr>
    8000299c:	cd1d                	beqz	a0,800029da <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000299e:	4789                	li	a5,2
    800029a0:	06f50a63          	beq	a0,a5,80002a14 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a8:	10049073          	csrw	sstatus,s1
}
    800029ac:	70a2                	ld	ra,40(sp)
    800029ae:	7402                	ld	s0,32(sp)
    800029b0:	64e2                	ld	s1,24(sp)
    800029b2:	6942                	ld	s2,16(sp)
    800029b4:	69a2                	ld	s3,8(sp)
    800029b6:	6145                	addi	sp,sp,48
    800029b8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ba:	00006517          	auipc	a0,0x6
    800029be:	9d650513          	addi	a0,a0,-1578 # 80008390 <states.0+0xc8>
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	b7e080e7          	jalr	-1154(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9ee50513          	addi	a0,a0,-1554 # 800083b8 <states.0+0xf0>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	b6e080e7          	jalr	-1170(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    800029da:	85ce                	mv	a1,s3
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	9fc50513          	addi	a0,a0,-1540 # 800083d8 <states.0+0x110>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	ba6080e7          	jalr	-1114(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	9f450513          	addi	a0,a0,-1548 # 800083e8 <states.0+0x120>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b8e080e7          	jalr	-1138(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	9fc50513          	addi	a0,a0,-1540 # 80008400 <states.0+0x138>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b34080e7          	jalr	-1228(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a14:	fffff097          	auipc	ra,0xfffff
    80002a18:	f98080e7          	jalr	-104(ra) # 800019ac <myproc>
    80002a1c:	d541                	beqz	a0,800029a4 <kerneltrap+0x38>
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	f8e080e7          	jalr	-114(ra) # 800019ac <myproc>
    80002a26:	4d18                	lw	a4,24(a0)
    80002a28:	4791                	li	a5,4
    80002a2a:	f6f71de3          	bne	a4,a5,800029a4 <kerneltrap+0x38>
    yield();
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	5ea080e7          	jalr	1514(ra) # 80002018 <yield>
    80002a36:	b7bd                	j	800029a4 <kerneltrap+0x38>

0000000080002a38 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a38:	1101                	addi	sp,sp,-32
    80002a3a:	ec06                	sd	ra,24(sp)
    80002a3c:	e822                	sd	s0,16(sp)
    80002a3e:	e426                	sd	s1,8(sp)
    80002a40:	1000                	addi	s0,sp,32
    80002a42:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	f68080e7          	jalr	-152(ra) # 800019ac <myproc>
  switch (n) {
    80002a4c:	4795                	li	a5,5
    80002a4e:	0497e163          	bltu	a5,s1,80002a90 <argraw+0x58>
    80002a52:	048a                	slli	s1,s1,0x2
    80002a54:	00006717          	auipc	a4,0x6
    80002a58:	9e470713          	addi	a4,a4,-1564 # 80008438 <states.0+0x170>
    80002a5c:	94ba                	add	s1,s1,a4
    80002a5e:	409c                	lw	a5,0(s1)
    80002a60:	97ba                	add	a5,a5,a4
    80002a62:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a64:	6d3c                	ld	a5,88(a0)
    80002a66:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6105                	addi	sp,sp,32
    80002a70:	8082                	ret
    return p->trapframe->a1;
    80002a72:	6d3c                	ld	a5,88(a0)
    80002a74:	7fa8                	ld	a0,120(a5)
    80002a76:	bfcd                	j	80002a68 <argraw+0x30>
    return p->trapframe->a2;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	63c8                	ld	a0,128(a5)
    80002a7c:	b7f5                	j	80002a68 <argraw+0x30>
    return p->trapframe->a3;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	67c8                	ld	a0,136(a5)
    80002a82:	b7dd                	j	80002a68 <argraw+0x30>
    return p->trapframe->a4;
    80002a84:	6d3c                	ld	a5,88(a0)
    80002a86:	6bc8                	ld	a0,144(a5)
    80002a88:	b7c5                	j	80002a68 <argraw+0x30>
    return p->trapframe->a5;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	6fc8                	ld	a0,152(a5)
    80002a8e:	bfe9                	j	80002a68 <argraw+0x30>
  panic("argraw");
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	98050513          	addi	a0,a0,-1664 # 80008410 <states.0+0x148>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	aa8080e7          	jalr	-1368(ra) # 80000540 <panic>

0000000080002aa0 <fetchaddr>:
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	e04a                	sd	s2,0(sp)
    80002aaa:	1000                	addi	s0,sp,32
    80002aac:	84aa                	mv	s1,a0
    80002aae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	efc080e7          	jalr	-260(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ab8:	653c                	ld	a5,72(a0)
    80002aba:	02f4f863          	bgeu	s1,a5,80002aea <fetchaddr+0x4a>
    80002abe:	00848713          	addi	a4,s1,8
    80002ac2:	02e7e663          	bltu	a5,a4,80002aee <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ac6:	46a1                	li	a3,8
    80002ac8:	8626                	mv	a2,s1
    80002aca:	85ca                	mv	a1,s2
    80002acc:	6928                	ld	a0,80(a0)
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	c2a080e7          	jalr	-982(ra) # 800016f8 <copyin>
    80002ad6:	00a03533          	snez	a0,a0
    80002ada:	40a00533          	neg	a0,a0
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6902                	ld	s2,0(sp)
    80002ae6:	6105                	addi	sp,sp,32
    80002ae8:	8082                	ret
    return -1;
    80002aea:	557d                	li	a0,-1
    80002aec:	bfcd                	j	80002ade <fetchaddr+0x3e>
    80002aee:	557d                	li	a0,-1
    80002af0:	b7fd                	j	80002ade <fetchaddr+0x3e>

0000000080002af2 <fetchstr>:
{
    80002af2:	7179                	addi	sp,sp,-48
    80002af4:	f406                	sd	ra,40(sp)
    80002af6:	f022                	sd	s0,32(sp)
    80002af8:	ec26                	sd	s1,24(sp)
    80002afa:	e84a                	sd	s2,16(sp)
    80002afc:	e44e                	sd	s3,8(sp)
    80002afe:	1800                	addi	s0,sp,48
    80002b00:	892a                	mv	s2,a0
    80002b02:	84ae                	mv	s1,a1
    80002b04:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	ea6080e7          	jalr	-346(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b0e:	86ce                	mv	a3,s3
    80002b10:	864a                	mv	a2,s2
    80002b12:	85a6                	mv	a1,s1
    80002b14:	6928                	ld	a0,80(a0)
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	c70080e7          	jalr	-912(ra) # 80001786 <copyinstr>
    80002b1e:	00054e63          	bltz	a0,80002b3a <fetchstr+0x48>
  return strlen(buf);
    80002b22:	8526                	mv	a0,s1
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	32a080e7          	jalr	810(ra) # 80000e4e <strlen>
}
    80002b2c:	70a2                	ld	ra,40(sp)
    80002b2e:	7402                	ld	s0,32(sp)
    80002b30:	64e2                	ld	s1,24(sp)
    80002b32:	6942                	ld	s2,16(sp)
    80002b34:	69a2                	ld	s3,8(sp)
    80002b36:	6145                	addi	sp,sp,48
    80002b38:	8082                	ret
    return -1;
    80002b3a:	557d                	li	a0,-1
    80002b3c:	bfc5                	j	80002b2c <fetchstr+0x3a>

0000000080002b3e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b3e:	1101                	addi	sp,sp,-32
    80002b40:	ec06                	sd	ra,24(sp)
    80002b42:	e822                	sd	s0,16(sp)
    80002b44:	e426                	sd	s1,8(sp)
    80002b46:	1000                	addi	s0,sp,32
    80002b48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	eee080e7          	jalr	-274(ra) # 80002a38 <argraw>
    80002b52:	c088                	sw	a0,0(s1)
}
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6105                	addi	sp,sp,32
    80002b5c:	8082                	ret

0000000080002b5e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b5e:	1101                	addi	sp,sp,-32
    80002b60:	ec06                	sd	ra,24(sp)
    80002b62:	e822                	sd	s0,16(sp)
    80002b64:	e426                	sd	s1,8(sp)
    80002b66:	1000                	addi	s0,sp,32
    80002b68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	ece080e7          	jalr	-306(ra) # 80002a38 <argraw>
    80002b72:	e088                	sd	a0,0(s1)
}
    80002b74:	60e2                	ld	ra,24(sp)
    80002b76:	6442                	ld	s0,16(sp)
    80002b78:	64a2                	ld	s1,8(sp)
    80002b7a:	6105                	addi	sp,sp,32
    80002b7c:	8082                	ret

0000000080002b7e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b7e:	7179                	addi	sp,sp,-48
    80002b80:	f406                	sd	ra,40(sp)
    80002b82:	f022                	sd	s0,32(sp)
    80002b84:	ec26                	sd	s1,24(sp)
    80002b86:	e84a                	sd	s2,16(sp)
    80002b88:	1800                	addi	s0,sp,48
    80002b8a:	84ae                	mv	s1,a1
    80002b8c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b8e:	fd840593          	addi	a1,s0,-40
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	fcc080e7          	jalr	-52(ra) # 80002b5e <argaddr>
  return fetchstr(addr, buf, max);
    80002b9a:	864a                	mv	a2,s2
    80002b9c:	85a6                	mv	a1,s1
    80002b9e:	fd843503          	ld	a0,-40(s0)
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	f50080e7          	jalr	-176(ra) # 80002af2 <fetchstr>
}
    80002baa:	70a2                	ld	ra,40(sp)
    80002bac:	7402                	ld	s0,32(sp)
    80002bae:	64e2                	ld	s1,24(sp)
    80002bb0:	6942                	ld	s2,16(sp)
    80002bb2:	6145                	addi	sp,sp,48
    80002bb4:	8082                	ret

0000000080002bb6 <syscall>:
[SYS_getprocessinfo]   sys_getprocessinfo
};

void
syscall(void)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	e04a                	sd	s2,0(sp)
    80002bc0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	dea080e7          	jalr	-534(ra) # 800019ac <myproc>
    80002bca:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bcc:	05853903          	ld	s2,88(a0)
    80002bd0:	0a893783          	ld	a5,168(s2)
    80002bd4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bd8:	37fd                	addiw	a5,a5,-1
    80002bda:	4755                	li	a4,21
    80002bdc:	00f76f63          	bltu	a4,a5,80002bfa <syscall+0x44>
    80002be0:	00369713          	slli	a4,a3,0x3
    80002be4:	00006797          	auipc	a5,0x6
    80002be8:	86c78793          	addi	a5,a5,-1940 # 80008450 <syscalls>
    80002bec:	97ba                	add	a5,a5,a4
    80002bee:	639c                	ld	a5,0(a5)
    80002bf0:	c789                	beqz	a5,80002bfa <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002bf2:	9782                	jalr	a5
    80002bf4:	06a93823          	sd	a0,112(s2)
    80002bf8:	a839                	j	80002c16 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bfa:	15848613          	addi	a2,s1,344
    80002bfe:	588c                	lw	a1,48(s1)
    80002c00:	00006517          	auipc	a0,0x6
    80002c04:	81850513          	addi	a0,a0,-2024 # 80008418 <states.0+0x150>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	982080e7          	jalr	-1662(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c10:	6cbc                	ld	a5,88(s1)
    80002c12:	577d                	li	a4,-1
    80002c14:	fbb8                	sd	a4,112(a5)
  }
};
    80002c16:	60e2                	ld	ra,24(sp)
    80002c18:	6442                	ld	s0,16(sp)
    80002c1a:	64a2                	ld	s1,8(sp)
    80002c1c:	6902                	ld	s2,0(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret

0000000080002c22 <sys_exit>:
#include "proc.h"
#include "syscall.h"

uint64
sys_exit(void)
{
    80002c22:	1101                	addi	sp,sp,-32
    80002c24:	ec06                	sd	ra,24(sp)
    80002c26:	e822                	sd	s0,16(sp)
    80002c28:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c2a:	fec40593          	addi	a1,s0,-20
    80002c2e:	4501                	li	a0,0
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	f0e080e7          	jalr	-242(ra) # 80002b3e <argint>
  exit(n);
    80002c38:	fec42503          	lw	a0,-20(s0)
    80002c3c:	fffff097          	auipc	ra,0xfffff
    80002c40:	54c080e7          	jalr	1356(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002c44:	4501                	li	a0,0
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret

0000000080002c4e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c4e:	1141                	addi	sp,sp,-16
    80002c50:	e406                	sd	ra,8(sp)
    80002c52:	e022                	sd	s0,0(sp)
    80002c54:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	d56080e7          	jalr	-682(ra) # 800019ac <myproc>
}
    80002c5e:	5908                	lw	a0,48(a0)
    80002c60:	60a2                	ld	ra,8(sp)
    80002c62:	6402                	ld	s0,0(sp)
    80002c64:	0141                	addi	sp,sp,16
    80002c66:	8082                	ret

0000000080002c68 <sys_fork>:

uint64
sys_fork(void)
{
    80002c68:	1141                	addi	sp,sp,-16
    80002c6a:	e406                	sd	ra,8(sp)
    80002c6c:	e022                	sd	s0,0(sp)
    80002c6e:	0800                	addi	s0,sp,16
  return fork();
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	0f2080e7          	jalr	242(ra) # 80001d62 <fork>
}
    80002c78:	60a2                	ld	ra,8(sp)
    80002c7a:	6402                	ld	s0,0(sp)
    80002c7c:	0141                	addi	sp,sp,16
    80002c7e:	8082                	ret

0000000080002c80 <sys_wait>:

uint64
sys_wait(void)
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c88:	fe840593          	addi	a1,s0,-24
    80002c8c:	4501                	li	a0,0
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	ed0080e7          	jalr	-304(ra) # 80002b5e <argaddr>
  return wait(p);
    80002c96:	fe843503          	ld	a0,-24(s0)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	694080e7          	jalr	1684(ra) # 8000232e <wait>
}
    80002ca2:	60e2                	ld	ra,24(sp)
    80002ca4:	6442                	ld	s0,16(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002caa:	7179                	addi	sp,sp,-48
    80002cac:	f406                	sd	ra,40(sp)
    80002cae:	f022                	sd	s0,32(sp)
    80002cb0:	ec26                	sd	s1,24(sp)
    80002cb2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cb4:	fdc40593          	addi	a1,s0,-36
    80002cb8:	4501                	li	a0,0
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	e84080e7          	jalr	-380(ra) # 80002b3e <argint>
  addr = myproc()->sz;
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	cea080e7          	jalr	-790(ra) # 800019ac <myproc>
    80002cca:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002ccc:	fdc42503          	lw	a0,-36(s0)
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	036080e7          	jalr	54(ra) # 80001d06 <growproc>
    80002cd8:	00054863          	bltz	a0,80002ce8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002cdc:	8526                	mv	a0,s1
    80002cde:	70a2                	ld	ra,40(sp)
    80002ce0:	7402                	ld	s0,32(sp)
    80002ce2:	64e2                	ld	s1,24(sp)
    80002ce4:	6145                	addi	sp,sp,48
    80002ce6:	8082                	ret
    return -1;
    80002ce8:	54fd                	li	s1,-1
    80002cea:	bfcd                	j	80002cdc <sys_sbrk+0x32>

0000000080002cec <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cec:	7139                	addi	sp,sp,-64
    80002cee:	fc06                	sd	ra,56(sp)
    80002cf0:	f822                	sd	s0,48(sp)
    80002cf2:	f426                	sd	s1,40(sp)
    80002cf4:	f04a                	sd	s2,32(sp)
    80002cf6:	ec4e                	sd	s3,24(sp)
    80002cf8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cfa:	fcc40593          	addi	a1,s0,-52
    80002cfe:	4501                	li	a0,0
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	e3e080e7          	jalr	-450(ra) # 80002b3e <argint>
  acquire(&tickslock);
    80002d08:	00014517          	auipc	a0,0x14
    80002d0c:	cb850513          	addi	a0,a0,-840 # 800169c0 <tickslock>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	ec6080e7          	jalr	-314(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d18:	00006917          	auipc	s2,0x6
    80002d1c:	c0892903          	lw	s2,-1016(s2) # 80008920 <ticks>
  while(ticks - ticks0 < n){
    80002d20:	fcc42783          	lw	a5,-52(s0)
    80002d24:	cf9d                	beqz	a5,80002d62 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d26:	00014997          	auipc	s3,0x14
    80002d2a:	c9a98993          	addi	s3,s3,-870 # 800169c0 <tickslock>
    80002d2e:	00006497          	auipc	s1,0x6
    80002d32:	bf248493          	addi	s1,s1,-1038 # 80008920 <ticks>
    if(killed(myproc())){
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	c76080e7          	jalr	-906(ra) # 800019ac <myproc>
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	5be080e7          	jalr	1470(ra) # 800022fc <killed>
    80002d46:	ed15                	bnez	a0,80002d82 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d48:	85ce                	mv	a1,s3
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	308080e7          	jalr	776(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002d54:	409c                	lw	a5,0(s1)
    80002d56:	412787bb          	subw	a5,a5,s2
    80002d5a:	fcc42703          	lw	a4,-52(s0)
    80002d5e:	fce7ece3          	bltu	a5,a4,80002d36 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d62:	00014517          	auipc	a0,0x14
    80002d66:	c5e50513          	addi	a0,a0,-930 # 800169c0 <tickslock>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	f20080e7          	jalr	-224(ra) # 80000c8a <release>
  return 0;
    80002d72:	4501                	li	a0,0
}
    80002d74:	70e2                	ld	ra,56(sp)
    80002d76:	7442                	ld	s0,48(sp)
    80002d78:	74a2                	ld	s1,40(sp)
    80002d7a:	7902                	ld	s2,32(sp)
    80002d7c:	69e2                	ld	s3,24(sp)
    80002d7e:	6121                	addi	sp,sp,64
    80002d80:	8082                	ret
      release(&tickslock);
    80002d82:	00014517          	auipc	a0,0x14
    80002d86:	c3e50513          	addi	a0,a0,-962 # 800169c0 <tickslock>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	f00080e7          	jalr	-256(ra) # 80000c8a <release>
      return -1;
    80002d92:	557d                	li	a0,-1
    80002d94:	b7c5                	j	80002d74 <sys_sleep+0x88>

0000000080002d96 <sys_kill>:

uint64
sys_kill(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d9e:	fec40593          	addi	a1,s0,-20
    80002da2:	4501                	li	a0,0
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	d9a080e7          	jalr	-614(ra) # 80002b3e <argint>
  return kill(pid);
    80002dac:	fec42503          	lw	a0,-20(s0)
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	4ae080e7          	jalr	1198(ra) # 8000225e <kill>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	e426                	sd	s1,8(sp)
    80002dc8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dca:	00014517          	auipc	a0,0x14
    80002dce:	bf650513          	addi	a0,a0,-1034 # 800169c0 <tickslock>
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	e04080e7          	jalr	-508(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002dda:	00006497          	auipc	s1,0x6
    80002dde:	b464a483          	lw	s1,-1210(s1) # 80008920 <ticks>
  release(&tickslock);
    80002de2:	00014517          	auipc	a0,0x14
    80002de6:	bde50513          	addi	a0,a0,-1058 # 800169c0 <tickslock>
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	ea0080e7          	jalr	-352(ra) # 80000c8a <release>
  return xticks;
}
    80002df2:	02049513          	slli	a0,s1,0x20
    80002df6:	9101                	srli	a0,a0,0x20
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret

0000000080002e02 <sys_getprocessinfo>:

uint64
sys_getprocessinfo(void)
{
    80002e02:	81010113          	addi	sp,sp,-2032
    80002e06:	7e113423          	sd	ra,2024(sp)
    80002e0a:	7e813023          	sd	s0,2016(sp)
    80002e0e:	7c913c23          	sd	s1,2008(sp)
    80002e12:	7d213823          	sd	s2,2000(sp)
    80002e16:	7d313423          	sd	s3,1992(sp)
    80002e1a:	7d413023          	sd	s4,1984(sp)
    80002e1e:	7f010413          	addi	s0,sp,2032
    80002e22:	bc010113          	addi	sp,sp,-1088
    struct process_info processes[128];
    int num_processes = getprocesses(processes);
    80002e26:	757d                	lui	a0,0xfffff
    80002e28:	3d050793          	addi	a5,a0,976 # fffffffffffff3d0 <end+0xffffffff7ffdd630>
    80002e2c:	00878533          	add	a0,a5,s0
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	788080e7          	jalr	1928(ra) # 800025b8 <getprocesses>
    80002e38:	8a2a                	mv	s4,a0
    int i = 0;

    printf("%s %s %s", "P_name", "PID", "P_stat\n");
    80002e3a:	00005697          	auipc	a3,0x5
    80002e3e:	6ce68693          	addi	a3,a3,1742 # 80008508 <syscalls+0xb8>
    80002e42:	00005617          	auipc	a2,0x5
    80002e46:	6ce60613          	addi	a2,a2,1742 # 80008510 <syscalls+0xc0>
    80002e4a:	00005597          	auipc	a1,0x5
    80002e4e:	6ce58593          	addi	a1,a1,1742 # 80008518 <syscalls+0xc8>
    80002e52:	00005517          	auipc	a0,0x5
    80002e56:	6ce50513          	addi	a0,a0,1742 # 80008520 <syscalls+0xd0>
    80002e5a:	ffffd097          	auipc	ra,0xffffd
    80002e5e:	730080e7          	jalr	1840(ra) # 8000058a <printf>
    while (i < num_processes) {
    80002e62:	05405463          	blez	s4,80002eaa <sys_getprocessinfo+0xa8>
    80002e66:	77fd                	lui	a5,0xfffff
    80002e68:	3d078793          	addi	a5,a5,976 # fffffffffffff3d0 <end+0xffffffff7ffdd630>
    80002e6c:	97a2                	add	a5,a5,s0
    80002e6e:	00878493          	addi	s1,a5,8
    80002e72:	fffa071b          	addiw	a4,s4,-1
    80002e76:	1702                	slli	a4,a4,0x20
    80002e78:	9301                	srli	a4,a4,0x20
    80002e7a:	00171913          	slli	s2,a4,0x1
    80002e7e:	993a                	add	s2,s2,a4
    80002e80:	090e                	slli	s2,s2,0x3
    80002e82:	02078793          	addi	a5,a5,32
    80002e86:	993e                	add	s2,s2,a5
        printf("%s (%d): %d\n", processes[i].name, processes[i].pid, processes[i].status);
    80002e88:	00005997          	auipc	s3,0x5
    80002e8c:	6a898993          	addi	s3,s3,1704 # 80008530 <syscalls+0xe0>
    80002e90:	ffc4a683          	lw	a3,-4(s1)
    80002e94:	ff84a603          	lw	a2,-8(s1)
    80002e98:	85a6                	mv	a1,s1
    80002e9a:	854e                	mv	a0,s3
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	6ee080e7          	jalr	1774(ra) # 8000058a <printf>
    while (i < num_processes) {
    80002ea4:	04e1                	addi	s1,s1,24
    80002ea6:	ff2495e3          	bne	s1,s2,80002e90 <sys_getprocessinfo+0x8e>
        i++;
    }
    return num_processes;
}
    80002eaa:	8552                	mv	a0,s4
    80002eac:	44010113          	addi	sp,sp,1088
    80002eb0:	7e813083          	ld	ra,2024(sp)
    80002eb4:	7e013403          	ld	s0,2016(sp)
    80002eb8:	7d813483          	ld	s1,2008(sp)
    80002ebc:	7d013903          	ld	s2,2000(sp)
    80002ec0:	7c813983          	ld	s3,1992(sp)
    80002ec4:	7c013a03          	ld	s4,1984(sp)
    80002ec8:	7f010113          	addi	sp,sp,2032
    80002ecc:	8082                	ret

0000000080002ece <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ece:	7179                	addi	sp,sp,-48
    80002ed0:	f406                	sd	ra,40(sp)
    80002ed2:	f022                	sd	s0,32(sp)
    80002ed4:	ec26                	sd	s1,24(sp)
    80002ed6:	e84a                	sd	s2,16(sp)
    80002ed8:	e44e                	sd	s3,8(sp)
    80002eda:	e052                	sd	s4,0(sp)
    80002edc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ede:	00005597          	auipc	a1,0x5
    80002ee2:	66258593          	addi	a1,a1,1634 # 80008540 <syscalls+0xf0>
    80002ee6:	00014517          	auipc	a0,0x14
    80002eea:	af250513          	addi	a0,a0,-1294 # 800169d8 <bcache>
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	c58080e7          	jalr	-936(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ef6:	0001c797          	auipc	a5,0x1c
    80002efa:	ae278793          	addi	a5,a5,-1310 # 8001e9d8 <bcache+0x8000>
    80002efe:	0001c717          	auipc	a4,0x1c
    80002f02:	d4270713          	addi	a4,a4,-702 # 8001ec40 <bcache+0x8268>
    80002f06:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f0a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f0e:	00014497          	auipc	s1,0x14
    80002f12:	ae248493          	addi	s1,s1,-1310 # 800169f0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f16:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f18:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f1a:	00005a17          	auipc	s4,0x5
    80002f1e:	62ea0a13          	addi	s4,s4,1582 # 80008548 <syscalls+0xf8>
    b->next = bcache.head.next;
    80002f22:	2b893783          	ld	a5,696(s2)
    80002f26:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f28:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f2c:	85d2                	mv	a1,s4
    80002f2e:	01048513          	addi	a0,s1,16
    80002f32:	00001097          	auipc	ra,0x1
    80002f36:	4c8080e7          	jalr	1224(ra) # 800043fa <initsleeplock>
    bcache.head.next->prev = b;
    80002f3a:	2b893783          	ld	a5,696(s2)
    80002f3e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f40:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f44:	45848493          	addi	s1,s1,1112
    80002f48:	fd349de3          	bne	s1,s3,80002f22 <binit+0x54>
  }
}
    80002f4c:	70a2                	ld	ra,40(sp)
    80002f4e:	7402                	ld	s0,32(sp)
    80002f50:	64e2                	ld	s1,24(sp)
    80002f52:	6942                	ld	s2,16(sp)
    80002f54:	69a2                	ld	s3,8(sp)
    80002f56:	6a02                	ld	s4,0(sp)
    80002f58:	6145                	addi	sp,sp,48
    80002f5a:	8082                	ret

0000000080002f5c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f5c:	7179                	addi	sp,sp,-48
    80002f5e:	f406                	sd	ra,40(sp)
    80002f60:	f022                	sd	s0,32(sp)
    80002f62:	ec26                	sd	s1,24(sp)
    80002f64:	e84a                	sd	s2,16(sp)
    80002f66:	e44e                	sd	s3,8(sp)
    80002f68:	1800                	addi	s0,sp,48
    80002f6a:	892a                	mv	s2,a0
    80002f6c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f6e:	00014517          	auipc	a0,0x14
    80002f72:	a6a50513          	addi	a0,a0,-1430 # 800169d8 <bcache>
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	c60080e7          	jalr	-928(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f7e:	0001c497          	auipc	s1,0x1c
    80002f82:	d124b483          	ld	s1,-750(s1) # 8001ec90 <bcache+0x82b8>
    80002f86:	0001c797          	auipc	a5,0x1c
    80002f8a:	cba78793          	addi	a5,a5,-838 # 8001ec40 <bcache+0x8268>
    80002f8e:	02f48f63          	beq	s1,a5,80002fcc <bread+0x70>
    80002f92:	873e                	mv	a4,a5
    80002f94:	a021                	j	80002f9c <bread+0x40>
    80002f96:	68a4                	ld	s1,80(s1)
    80002f98:	02e48a63          	beq	s1,a4,80002fcc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f9c:	449c                	lw	a5,8(s1)
    80002f9e:	ff279ce3          	bne	a5,s2,80002f96 <bread+0x3a>
    80002fa2:	44dc                	lw	a5,12(s1)
    80002fa4:	ff3799e3          	bne	a5,s3,80002f96 <bread+0x3a>
      b->refcnt++;
    80002fa8:	40bc                	lw	a5,64(s1)
    80002faa:	2785                	addiw	a5,a5,1
    80002fac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	a2a50513          	addi	a0,a0,-1494 # 800169d8 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	cd4080e7          	jalr	-812(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002fbe:	01048513          	addi	a0,s1,16
    80002fc2:	00001097          	auipc	ra,0x1
    80002fc6:	472080e7          	jalr	1138(ra) # 80004434 <acquiresleep>
      return b;
    80002fca:	a8b9                	j	80003028 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fcc:	0001c497          	auipc	s1,0x1c
    80002fd0:	cbc4b483          	ld	s1,-836(s1) # 8001ec88 <bcache+0x82b0>
    80002fd4:	0001c797          	auipc	a5,0x1c
    80002fd8:	c6c78793          	addi	a5,a5,-916 # 8001ec40 <bcache+0x8268>
    80002fdc:	00f48863          	beq	s1,a5,80002fec <bread+0x90>
    80002fe0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	cf81                	beqz	a5,80002ffc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fe6:	64a4                	ld	s1,72(s1)
    80002fe8:	fee49de3          	bne	s1,a4,80002fe2 <bread+0x86>
  panic("bget: no buffers");
    80002fec:	00005517          	auipc	a0,0x5
    80002ff0:	56450513          	addi	a0,a0,1380 # 80008550 <syscalls+0x100>
    80002ff4:	ffffd097          	auipc	ra,0xffffd
    80002ff8:	54c080e7          	jalr	1356(ra) # 80000540 <panic>
      b->dev = dev;
    80002ffc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003000:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003004:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003008:	4785                	li	a5,1
    8000300a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000300c:	00014517          	auipc	a0,0x14
    80003010:	9cc50513          	addi	a0,a0,-1588 # 800169d8 <bcache>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	c76080e7          	jalr	-906(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000301c:	01048513          	addi	a0,s1,16
    80003020:	00001097          	auipc	ra,0x1
    80003024:	414080e7          	jalr	1044(ra) # 80004434 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003028:	409c                	lw	a5,0(s1)
    8000302a:	cb89                	beqz	a5,8000303c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000302c:	8526                	mv	a0,s1
    8000302e:	70a2                	ld	ra,40(sp)
    80003030:	7402                	ld	s0,32(sp)
    80003032:	64e2                	ld	s1,24(sp)
    80003034:	6942                	ld	s2,16(sp)
    80003036:	69a2                	ld	s3,8(sp)
    80003038:	6145                	addi	sp,sp,48
    8000303a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000303c:	4581                	li	a1,0
    8000303e:	8526                	mv	a0,s1
    80003040:	00003097          	auipc	ra,0x3
    80003044:	fe2080e7          	jalr	-30(ra) # 80006022 <virtio_disk_rw>
    b->valid = 1;
    80003048:	4785                	li	a5,1
    8000304a:	c09c                	sw	a5,0(s1)
  return b;
    8000304c:	b7c5                	j	8000302c <bread+0xd0>

000000008000304e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	1000                	addi	s0,sp,32
    80003058:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000305a:	0541                	addi	a0,a0,16
    8000305c:	00001097          	auipc	ra,0x1
    80003060:	472080e7          	jalr	1138(ra) # 800044ce <holdingsleep>
    80003064:	cd01                	beqz	a0,8000307c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003066:	4585                	li	a1,1
    80003068:	8526                	mv	a0,s1
    8000306a:	00003097          	auipc	ra,0x3
    8000306e:	fb8080e7          	jalr	-72(ra) # 80006022 <virtio_disk_rw>
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret
    panic("bwrite");
    8000307c:	00005517          	auipc	a0,0x5
    80003080:	4ec50513          	addi	a0,a0,1260 # 80008568 <syscalls+0x118>
    80003084:	ffffd097          	auipc	ra,0xffffd
    80003088:	4bc080e7          	jalr	1212(ra) # 80000540 <panic>

000000008000308c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000308c:	1101                	addi	sp,sp,-32
    8000308e:	ec06                	sd	ra,24(sp)
    80003090:	e822                	sd	s0,16(sp)
    80003092:	e426                	sd	s1,8(sp)
    80003094:	e04a                	sd	s2,0(sp)
    80003096:	1000                	addi	s0,sp,32
    80003098:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000309a:	01050913          	addi	s2,a0,16
    8000309e:	854a                	mv	a0,s2
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	42e080e7          	jalr	1070(ra) # 800044ce <holdingsleep>
    800030a8:	c92d                	beqz	a0,8000311a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030aa:	854a                	mv	a0,s2
    800030ac:	00001097          	auipc	ra,0x1
    800030b0:	3de080e7          	jalr	990(ra) # 8000448a <releasesleep>

  acquire(&bcache.lock);
    800030b4:	00014517          	auipc	a0,0x14
    800030b8:	92450513          	addi	a0,a0,-1756 # 800169d8 <bcache>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	b1a080e7          	jalr	-1254(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030c4:	40bc                	lw	a5,64(s1)
    800030c6:	37fd                	addiw	a5,a5,-1
    800030c8:	0007871b          	sext.w	a4,a5
    800030cc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ce:	eb05                	bnez	a4,800030fe <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030d0:	68bc                	ld	a5,80(s1)
    800030d2:	64b8                	ld	a4,72(s1)
    800030d4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030d6:	64bc                	ld	a5,72(s1)
    800030d8:	68b8                	ld	a4,80(s1)
    800030da:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030dc:	0001c797          	auipc	a5,0x1c
    800030e0:	8fc78793          	addi	a5,a5,-1796 # 8001e9d8 <bcache+0x8000>
    800030e4:	2b87b703          	ld	a4,696(a5)
    800030e8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030ea:	0001c717          	auipc	a4,0x1c
    800030ee:	b5670713          	addi	a4,a4,-1194 # 8001ec40 <bcache+0x8268>
    800030f2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030f4:	2b87b703          	ld	a4,696(a5)
    800030f8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030fa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030fe:	00014517          	auipc	a0,0x14
    80003102:	8da50513          	addi	a0,a0,-1830 # 800169d8 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	b84080e7          	jalr	-1148(ra) # 80000c8a <release>
}
    8000310e:	60e2                	ld	ra,24(sp)
    80003110:	6442                	ld	s0,16(sp)
    80003112:	64a2                	ld	s1,8(sp)
    80003114:	6902                	ld	s2,0(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret
    panic("brelse");
    8000311a:	00005517          	auipc	a0,0x5
    8000311e:	45650513          	addi	a0,a0,1110 # 80008570 <syscalls+0x120>
    80003122:	ffffd097          	auipc	ra,0xffffd
    80003126:	41e080e7          	jalr	1054(ra) # 80000540 <panic>

000000008000312a <bpin>:

void
bpin(struct buf *b) {
    8000312a:	1101                	addi	sp,sp,-32
    8000312c:	ec06                	sd	ra,24(sp)
    8000312e:	e822                	sd	s0,16(sp)
    80003130:	e426                	sd	s1,8(sp)
    80003132:	1000                	addi	s0,sp,32
    80003134:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	8a250513          	addi	a0,a0,-1886 # 800169d8 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	a98080e7          	jalr	-1384(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003146:	40bc                	lw	a5,64(s1)
    80003148:	2785                	addiw	a5,a5,1
    8000314a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000314c:	00014517          	auipc	a0,0x14
    80003150:	88c50513          	addi	a0,a0,-1908 # 800169d8 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	b36080e7          	jalr	-1226(ra) # 80000c8a <release>
}
    8000315c:	60e2                	ld	ra,24(sp)
    8000315e:	6442                	ld	s0,16(sp)
    80003160:	64a2                	ld	s1,8(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret

0000000080003166 <bunpin>:

void
bunpin(struct buf *b) {
    80003166:	1101                	addi	sp,sp,-32
    80003168:	ec06                	sd	ra,24(sp)
    8000316a:	e822                	sd	s0,16(sp)
    8000316c:	e426                	sd	s1,8(sp)
    8000316e:	1000                	addi	s0,sp,32
    80003170:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	86650513          	addi	a0,a0,-1946 # 800169d8 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	a5c080e7          	jalr	-1444(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003182:	40bc                	lw	a5,64(s1)
    80003184:	37fd                	addiw	a5,a5,-1
    80003186:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003188:	00014517          	auipc	a0,0x14
    8000318c:	85050513          	addi	a0,a0,-1968 # 800169d8 <bcache>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	afa080e7          	jalr	-1286(ra) # 80000c8a <release>
}
    80003198:	60e2                	ld	ra,24(sp)
    8000319a:	6442                	ld	s0,16(sp)
    8000319c:	64a2                	ld	s1,8(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret

00000000800031a2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	e426                	sd	s1,8(sp)
    800031aa:	e04a                	sd	s2,0(sp)
    800031ac:	1000                	addi	s0,sp,32
    800031ae:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031b0:	00d5d59b          	srliw	a1,a1,0xd
    800031b4:	0001c797          	auipc	a5,0x1c
    800031b8:	f007a783          	lw	a5,-256(a5) # 8001f0b4 <sb+0x1c>
    800031bc:	9dbd                	addw	a1,a1,a5
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	d9e080e7          	jalr	-610(ra) # 80002f5c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031c6:	0074f713          	andi	a4,s1,7
    800031ca:	4785                	li	a5,1
    800031cc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031d0:	14ce                	slli	s1,s1,0x33
    800031d2:	90d9                	srli	s1,s1,0x36
    800031d4:	00950733          	add	a4,a0,s1
    800031d8:	05874703          	lbu	a4,88(a4)
    800031dc:	00e7f6b3          	and	a3,a5,a4
    800031e0:	c69d                	beqz	a3,8000320e <bfree+0x6c>
    800031e2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031e4:	94aa                	add	s1,s1,a0
    800031e6:	fff7c793          	not	a5,a5
    800031ea:	8f7d                	and	a4,a4,a5
    800031ec:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	126080e7          	jalr	294(ra) # 80004316 <log_write>
  brelse(bp);
    800031f8:	854a                	mv	a0,s2
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	e92080e7          	jalr	-366(ra) # 8000308c <brelse>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	64a2                	ld	s1,8(sp)
    80003208:	6902                	ld	s2,0(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret
    panic("freeing free block");
    8000320e:	00005517          	auipc	a0,0x5
    80003212:	36a50513          	addi	a0,a0,874 # 80008578 <syscalls+0x128>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	32a080e7          	jalr	810(ra) # 80000540 <panic>

000000008000321e <balloc>:
{
    8000321e:	711d                	addi	sp,sp,-96
    80003220:	ec86                	sd	ra,88(sp)
    80003222:	e8a2                	sd	s0,80(sp)
    80003224:	e4a6                	sd	s1,72(sp)
    80003226:	e0ca                	sd	s2,64(sp)
    80003228:	fc4e                	sd	s3,56(sp)
    8000322a:	f852                	sd	s4,48(sp)
    8000322c:	f456                	sd	s5,40(sp)
    8000322e:	f05a                	sd	s6,32(sp)
    80003230:	ec5e                	sd	s7,24(sp)
    80003232:	e862                	sd	s8,16(sp)
    80003234:	e466                	sd	s9,8(sp)
    80003236:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003238:	0001c797          	auipc	a5,0x1c
    8000323c:	e647a783          	lw	a5,-412(a5) # 8001f09c <sb+0x4>
    80003240:	cff5                	beqz	a5,8000333c <balloc+0x11e>
    80003242:	8baa                	mv	s7,a0
    80003244:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003246:	0001cb17          	auipc	s6,0x1c
    8000324a:	e52b0b13          	addi	s6,s6,-430 # 8001f098 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000324e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003250:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003252:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003254:	6c89                	lui	s9,0x2
    80003256:	a061                	j	800032de <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003258:	97ca                	add	a5,a5,s2
    8000325a:	8e55                	or	a2,a2,a3
    8000325c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003260:	854a                	mv	a0,s2
    80003262:	00001097          	auipc	ra,0x1
    80003266:	0b4080e7          	jalr	180(ra) # 80004316 <log_write>
        brelse(bp);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	e20080e7          	jalr	-480(ra) # 8000308c <brelse>
  bp = bread(dev, bno);
    80003274:	85a6                	mv	a1,s1
    80003276:	855e                	mv	a0,s7
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	ce4080e7          	jalr	-796(ra) # 80002f5c <bread>
    80003280:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003282:	40000613          	li	a2,1024
    80003286:	4581                	li	a1,0
    80003288:	05850513          	addi	a0,a0,88
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	a46080e7          	jalr	-1466(ra) # 80000cd2 <memset>
  log_write(bp);
    80003294:	854a                	mv	a0,s2
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	080080e7          	jalr	128(ra) # 80004316 <log_write>
  brelse(bp);
    8000329e:	854a                	mv	a0,s2
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	dec080e7          	jalr	-532(ra) # 8000308c <brelse>
}
    800032a8:	8526                	mv	a0,s1
    800032aa:	60e6                	ld	ra,88(sp)
    800032ac:	6446                	ld	s0,80(sp)
    800032ae:	64a6                	ld	s1,72(sp)
    800032b0:	6906                	ld	s2,64(sp)
    800032b2:	79e2                	ld	s3,56(sp)
    800032b4:	7a42                	ld	s4,48(sp)
    800032b6:	7aa2                	ld	s5,40(sp)
    800032b8:	7b02                	ld	s6,32(sp)
    800032ba:	6be2                	ld	s7,24(sp)
    800032bc:	6c42                	ld	s8,16(sp)
    800032be:	6ca2                	ld	s9,8(sp)
    800032c0:	6125                	addi	sp,sp,96
    800032c2:	8082                	ret
    brelse(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	dc6080e7          	jalr	-570(ra) # 8000308c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032ce:	015c87bb          	addw	a5,s9,s5
    800032d2:	00078a9b          	sext.w	s5,a5
    800032d6:	004b2703          	lw	a4,4(s6)
    800032da:	06eaf163          	bgeu	s5,a4,8000333c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032de:	41fad79b          	sraiw	a5,s5,0x1f
    800032e2:	0137d79b          	srliw	a5,a5,0x13
    800032e6:	015787bb          	addw	a5,a5,s5
    800032ea:	40d7d79b          	sraiw	a5,a5,0xd
    800032ee:	01cb2583          	lw	a1,28(s6)
    800032f2:	9dbd                	addw	a1,a1,a5
    800032f4:	855e                	mv	a0,s7
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	c66080e7          	jalr	-922(ra) # 80002f5c <bread>
    800032fe:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003300:	004b2503          	lw	a0,4(s6)
    80003304:	000a849b          	sext.w	s1,s5
    80003308:	8762                	mv	a4,s8
    8000330a:	faa4fde3          	bgeu	s1,a0,800032c4 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000330e:	00777693          	andi	a3,a4,7
    80003312:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003316:	41f7579b          	sraiw	a5,a4,0x1f
    8000331a:	01d7d79b          	srliw	a5,a5,0x1d
    8000331e:	9fb9                	addw	a5,a5,a4
    80003320:	4037d79b          	sraiw	a5,a5,0x3
    80003324:	00f90633          	add	a2,s2,a5
    80003328:	05864603          	lbu	a2,88(a2)
    8000332c:	00c6f5b3          	and	a1,a3,a2
    80003330:	d585                	beqz	a1,80003258 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003332:	2705                	addiw	a4,a4,1
    80003334:	2485                	addiw	s1,s1,1
    80003336:	fd471ae3          	bne	a4,s4,8000330a <balloc+0xec>
    8000333a:	b769                	j	800032c4 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000333c:	00005517          	auipc	a0,0x5
    80003340:	25450513          	addi	a0,a0,596 # 80008590 <syscalls+0x140>
    80003344:	ffffd097          	auipc	ra,0xffffd
    80003348:	246080e7          	jalr	582(ra) # 8000058a <printf>
  return 0;
    8000334c:	4481                	li	s1,0
    8000334e:	bfa9                	j	800032a8 <balloc+0x8a>

0000000080003350 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003350:	7179                	addi	sp,sp,-48
    80003352:	f406                	sd	ra,40(sp)
    80003354:	f022                	sd	s0,32(sp)
    80003356:	ec26                	sd	s1,24(sp)
    80003358:	e84a                	sd	s2,16(sp)
    8000335a:	e44e                	sd	s3,8(sp)
    8000335c:	e052                	sd	s4,0(sp)
    8000335e:	1800                	addi	s0,sp,48
    80003360:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003362:	47ad                	li	a5,11
    80003364:	02b7e863          	bltu	a5,a1,80003394 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003368:	02059793          	slli	a5,a1,0x20
    8000336c:	01e7d593          	srli	a1,a5,0x1e
    80003370:	00b504b3          	add	s1,a0,a1
    80003374:	0504a903          	lw	s2,80(s1)
    80003378:	06091e63          	bnez	s2,800033f4 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000337c:	4108                	lw	a0,0(a0)
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	ea0080e7          	jalr	-352(ra) # 8000321e <balloc>
    80003386:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000338a:	06090563          	beqz	s2,800033f4 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000338e:	0524a823          	sw	s2,80(s1)
    80003392:	a08d                	j	800033f4 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003394:	ff45849b          	addiw	s1,a1,-12
    80003398:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000339c:	0ff00793          	li	a5,255
    800033a0:	08e7e563          	bltu	a5,a4,8000342a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033a4:	08052903          	lw	s2,128(a0)
    800033a8:	00091d63          	bnez	s2,800033c2 <bmap+0x72>
      addr = balloc(ip->dev);
    800033ac:	4108                	lw	a0,0(a0)
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	e70080e7          	jalr	-400(ra) # 8000321e <balloc>
    800033b6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033ba:	02090d63          	beqz	s2,800033f4 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033be:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033c2:	85ca                	mv	a1,s2
    800033c4:	0009a503          	lw	a0,0(s3)
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	b94080e7          	jalr	-1132(ra) # 80002f5c <bread>
    800033d0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033d2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033d6:	02049713          	slli	a4,s1,0x20
    800033da:	01e75593          	srli	a1,a4,0x1e
    800033de:	00b784b3          	add	s1,a5,a1
    800033e2:	0004a903          	lw	s2,0(s1)
    800033e6:	02090063          	beqz	s2,80003406 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033ea:	8552                	mv	a0,s4
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	ca0080e7          	jalr	-864(ra) # 8000308c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033f4:	854a                	mv	a0,s2
    800033f6:	70a2                	ld	ra,40(sp)
    800033f8:	7402                	ld	s0,32(sp)
    800033fa:	64e2                	ld	s1,24(sp)
    800033fc:	6942                	ld	s2,16(sp)
    800033fe:	69a2                	ld	s3,8(sp)
    80003400:	6a02                	ld	s4,0(sp)
    80003402:	6145                	addi	sp,sp,48
    80003404:	8082                	ret
      addr = balloc(ip->dev);
    80003406:	0009a503          	lw	a0,0(s3)
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	e14080e7          	jalr	-492(ra) # 8000321e <balloc>
    80003412:	0005091b          	sext.w	s2,a0
      if(addr){
    80003416:	fc090ae3          	beqz	s2,800033ea <bmap+0x9a>
        a[bn] = addr;
    8000341a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000341e:	8552                	mv	a0,s4
    80003420:	00001097          	auipc	ra,0x1
    80003424:	ef6080e7          	jalr	-266(ra) # 80004316 <log_write>
    80003428:	b7c9                	j	800033ea <bmap+0x9a>
  panic("bmap: out of range");
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	17e50513          	addi	a0,a0,382 # 800085a8 <syscalls+0x158>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	10e080e7          	jalr	270(ra) # 80000540 <panic>

000000008000343a <iget>:
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	e84a                	sd	s2,16(sp)
    80003444:	e44e                	sd	s3,8(sp)
    80003446:	e052                	sd	s4,0(sp)
    80003448:	1800                	addi	s0,sp,48
    8000344a:	89aa                	mv	s3,a0
    8000344c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000344e:	0001c517          	auipc	a0,0x1c
    80003452:	c6a50513          	addi	a0,a0,-918 # 8001f0b8 <itable>
    80003456:	ffffd097          	auipc	ra,0xffffd
    8000345a:	780080e7          	jalr	1920(ra) # 80000bd6 <acquire>
  empty = 0;
    8000345e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003460:	0001c497          	auipc	s1,0x1c
    80003464:	c7048493          	addi	s1,s1,-912 # 8001f0d0 <itable+0x18>
    80003468:	0001d697          	auipc	a3,0x1d
    8000346c:	6f868693          	addi	a3,a3,1784 # 80020b60 <log>
    80003470:	a039                	j	8000347e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003472:	02090b63          	beqz	s2,800034a8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003476:	08848493          	addi	s1,s1,136
    8000347a:	02d48a63          	beq	s1,a3,800034ae <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000347e:	449c                	lw	a5,8(s1)
    80003480:	fef059e3          	blez	a5,80003472 <iget+0x38>
    80003484:	4098                	lw	a4,0(s1)
    80003486:	ff3716e3          	bne	a4,s3,80003472 <iget+0x38>
    8000348a:	40d8                	lw	a4,4(s1)
    8000348c:	ff4713e3          	bne	a4,s4,80003472 <iget+0x38>
      ip->ref++;
    80003490:	2785                	addiw	a5,a5,1
    80003492:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003494:	0001c517          	auipc	a0,0x1c
    80003498:	c2450513          	addi	a0,a0,-988 # 8001f0b8 <itable>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	7ee080e7          	jalr	2030(ra) # 80000c8a <release>
      return ip;
    800034a4:	8926                	mv	s2,s1
    800034a6:	a03d                	j	800034d4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a8:	f7f9                	bnez	a5,80003476 <iget+0x3c>
    800034aa:	8926                	mv	s2,s1
    800034ac:	b7e9                	j	80003476 <iget+0x3c>
  if(empty == 0)
    800034ae:	02090c63          	beqz	s2,800034e6 <iget+0xac>
  ip->dev = dev;
    800034b2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034b6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034ba:	4785                	li	a5,1
    800034bc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034c0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034c4:	0001c517          	auipc	a0,0x1c
    800034c8:	bf450513          	addi	a0,a0,-1036 # 8001f0b8 <itable>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	7be080e7          	jalr	1982(ra) # 80000c8a <release>
}
    800034d4:	854a                	mv	a0,s2
    800034d6:	70a2                	ld	ra,40(sp)
    800034d8:	7402                	ld	s0,32(sp)
    800034da:	64e2                	ld	s1,24(sp)
    800034dc:	6942                	ld	s2,16(sp)
    800034de:	69a2                	ld	s3,8(sp)
    800034e0:	6a02                	ld	s4,0(sp)
    800034e2:	6145                	addi	sp,sp,48
    800034e4:	8082                	ret
    panic("iget: no inodes");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	0da50513          	addi	a0,a0,218 # 800085c0 <syscalls+0x170>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	052080e7          	jalr	82(ra) # 80000540 <panic>

00000000800034f6 <fsinit>:
fsinit(int dev) {
    800034f6:	7179                	addi	sp,sp,-48
    800034f8:	f406                	sd	ra,40(sp)
    800034fa:	f022                	sd	s0,32(sp)
    800034fc:	ec26                	sd	s1,24(sp)
    800034fe:	e84a                	sd	s2,16(sp)
    80003500:	e44e                	sd	s3,8(sp)
    80003502:	1800                	addi	s0,sp,48
    80003504:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003506:	4585                	li	a1,1
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	a54080e7          	jalr	-1452(ra) # 80002f5c <bread>
    80003510:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003512:	0001c997          	auipc	s3,0x1c
    80003516:	b8698993          	addi	s3,s3,-1146 # 8001f098 <sb>
    8000351a:	02000613          	li	a2,32
    8000351e:	05850593          	addi	a1,a0,88
    80003522:	854e                	mv	a0,s3
    80003524:	ffffe097          	auipc	ra,0xffffe
    80003528:	80a080e7          	jalr	-2038(ra) # 80000d2e <memmove>
  brelse(bp);
    8000352c:	8526                	mv	a0,s1
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	b5e080e7          	jalr	-1186(ra) # 8000308c <brelse>
  if(sb.magic != FSMAGIC)
    80003536:	0009a703          	lw	a4,0(s3)
    8000353a:	102037b7          	lui	a5,0x10203
    8000353e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003542:	02f71263          	bne	a4,a5,80003566 <fsinit+0x70>
  initlog(dev, &sb);
    80003546:	0001c597          	auipc	a1,0x1c
    8000354a:	b5258593          	addi	a1,a1,-1198 # 8001f098 <sb>
    8000354e:	854a                	mv	a0,s2
    80003550:	00001097          	auipc	ra,0x1
    80003554:	b4a080e7          	jalr	-1206(ra) # 8000409a <initlog>
}
    80003558:	70a2                	ld	ra,40(sp)
    8000355a:	7402                	ld	s0,32(sp)
    8000355c:	64e2                	ld	s1,24(sp)
    8000355e:	6942                	ld	s2,16(sp)
    80003560:	69a2                	ld	s3,8(sp)
    80003562:	6145                	addi	sp,sp,48
    80003564:	8082                	ret
    panic("invalid file system");
    80003566:	00005517          	auipc	a0,0x5
    8000356a:	06a50513          	addi	a0,a0,106 # 800085d0 <syscalls+0x180>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	fd2080e7          	jalr	-46(ra) # 80000540 <panic>

0000000080003576 <iinit>:
{
    80003576:	7179                	addi	sp,sp,-48
    80003578:	f406                	sd	ra,40(sp)
    8000357a:	f022                	sd	s0,32(sp)
    8000357c:	ec26                	sd	s1,24(sp)
    8000357e:	e84a                	sd	s2,16(sp)
    80003580:	e44e                	sd	s3,8(sp)
    80003582:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003584:	00005597          	auipc	a1,0x5
    80003588:	06458593          	addi	a1,a1,100 # 800085e8 <syscalls+0x198>
    8000358c:	0001c517          	auipc	a0,0x1c
    80003590:	b2c50513          	addi	a0,a0,-1236 # 8001f0b8 <itable>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	5b2080e7          	jalr	1458(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000359c:	0001c497          	auipc	s1,0x1c
    800035a0:	b4448493          	addi	s1,s1,-1212 # 8001f0e0 <itable+0x28>
    800035a4:	0001d997          	auipc	s3,0x1d
    800035a8:	5cc98993          	addi	s3,s3,1484 # 80020b70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ac:	00005917          	auipc	s2,0x5
    800035b0:	04490913          	addi	s2,s2,68 # 800085f0 <syscalls+0x1a0>
    800035b4:	85ca                	mv	a1,s2
    800035b6:	8526                	mv	a0,s1
    800035b8:	00001097          	auipc	ra,0x1
    800035bc:	e42080e7          	jalr	-446(ra) # 800043fa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035c0:	08848493          	addi	s1,s1,136
    800035c4:	ff3498e3          	bne	s1,s3,800035b4 <iinit+0x3e>
}
    800035c8:	70a2                	ld	ra,40(sp)
    800035ca:	7402                	ld	s0,32(sp)
    800035cc:	64e2                	ld	s1,24(sp)
    800035ce:	6942                	ld	s2,16(sp)
    800035d0:	69a2                	ld	s3,8(sp)
    800035d2:	6145                	addi	sp,sp,48
    800035d4:	8082                	ret

00000000800035d6 <ialloc>:
{
    800035d6:	715d                	addi	sp,sp,-80
    800035d8:	e486                	sd	ra,72(sp)
    800035da:	e0a2                	sd	s0,64(sp)
    800035dc:	fc26                	sd	s1,56(sp)
    800035de:	f84a                	sd	s2,48(sp)
    800035e0:	f44e                	sd	s3,40(sp)
    800035e2:	f052                	sd	s4,32(sp)
    800035e4:	ec56                	sd	s5,24(sp)
    800035e6:	e85a                	sd	s6,16(sp)
    800035e8:	e45e                	sd	s7,8(sp)
    800035ea:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ec:	0001c717          	auipc	a4,0x1c
    800035f0:	ab872703          	lw	a4,-1352(a4) # 8001f0a4 <sb+0xc>
    800035f4:	4785                	li	a5,1
    800035f6:	04e7fa63          	bgeu	a5,a4,8000364a <ialloc+0x74>
    800035fa:	8aaa                	mv	s5,a0
    800035fc:	8bae                	mv	s7,a1
    800035fe:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003600:	0001ca17          	auipc	s4,0x1c
    80003604:	a98a0a13          	addi	s4,s4,-1384 # 8001f098 <sb>
    80003608:	00048b1b          	sext.w	s6,s1
    8000360c:	0044d593          	srli	a1,s1,0x4
    80003610:	018a2783          	lw	a5,24(s4)
    80003614:	9dbd                	addw	a1,a1,a5
    80003616:	8556                	mv	a0,s5
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	944080e7          	jalr	-1724(ra) # 80002f5c <bread>
    80003620:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003622:	05850993          	addi	s3,a0,88
    80003626:	00f4f793          	andi	a5,s1,15
    8000362a:	079a                	slli	a5,a5,0x6
    8000362c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000362e:	00099783          	lh	a5,0(s3)
    80003632:	c3a1                	beqz	a5,80003672 <ialloc+0x9c>
    brelse(bp);
    80003634:	00000097          	auipc	ra,0x0
    80003638:	a58080e7          	jalr	-1448(ra) # 8000308c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363c:	0485                	addi	s1,s1,1
    8000363e:	00ca2703          	lw	a4,12(s4)
    80003642:	0004879b          	sext.w	a5,s1
    80003646:	fce7e1e3          	bltu	a5,a4,80003608 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	fae50513          	addi	a0,a0,-82 # 800085f8 <syscalls+0x1a8>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	f38080e7          	jalr	-200(ra) # 8000058a <printf>
  return 0;
    8000365a:	4501                	li	a0,0
}
    8000365c:	60a6                	ld	ra,72(sp)
    8000365e:	6406                	ld	s0,64(sp)
    80003660:	74e2                	ld	s1,56(sp)
    80003662:	7942                	ld	s2,48(sp)
    80003664:	79a2                	ld	s3,40(sp)
    80003666:	7a02                	ld	s4,32(sp)
    80003668:	6ae2                	ld	s5,24(sp)
    8000366a:	6b42                	ld	s6,16(sp)
    8000366c:	6ba2                	ld	s7,8(sp)
    8000366e:	6161                	addi	sp,sp,80
    80003670:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003672:	04000613          	li	a2,64
    80003676:	4581                	li	a1,0
    80003678:	854e                	mv	a0,s3
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	658080e7          	jalr	1624(ra) # 80000cd2 <memset>
      dip->type = type;
    80003682:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003686:	854a                	mv	a0,s2
    80003688:	00001097          	auipc	ra,0x1
    8000368c:	c8e080e7          	jalr	-882(ra) # 80004316 <log_write>
      brelse(bp);
    80003690:	854a                	mv	a0,s2
    80003692:	00000097          	auipc	ra,0x0
    80003696:	9fa080e7          	jalr	-1542(ra) # 8000308c <brelse>
      return iget(dev, inum);
    8000369a:	85da                	mv	a1,s6
    8000369c:	8556                	mv	a0,s5
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	d9c080e7          	jalr	-612(ra) # 8000343a <iget>
    800036a6:	bf5d                	j	8000365c <ialloc+0x86>

00000000800036a8 <iupdate>:
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	e04a                	sd	s2,0(sp)
    800036b2:	1000                	addi	s0,sp,32
    800036b4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036b6:	415c                	lw	a5,4(a0)
    800036b8:	0047d79b          	srliw	a5,a5,0x4
    800036bc:	0001c597          	auipc	a1,0x1c
    800036c0:	9f45a583          	lw	a1,-1548(a1) # 8001f0b0 <sb+0x18>
    800036c4:	9dbd                	addw	a1,a1,a5
    800036c6:	4108                	lw	a0,0(a0)
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	894080e7          	jalr	-1900(ra) # 80002f5c <bread>
    800036d0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036d2:	05850793          	addi	a5,a0,88
    800036d6:	40d8                	lw	a4,4(s1)
    800036d8:	8b3d                	andi	a4,a4,15
    800036da:	071a                	slli	a4,a4,0x6
    800036dc:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036de:	04449703          	lh	a4,68(s1)
    800036e2:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036e6:	04649703          	lh	a4,70(s1)
    800036ea:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036ee:	04849703          	lh	a4,72(s1)
    800036f2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036f6:	04a49703          	lh	a4,74(s1)
    800036fa:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036fe:	44f8                	lw	a4,76(s1)
    80003700:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003702:	03400613          	li	a2,52
    80003706:	05048593          	addi	a1,s1,80
    8000370a:	00c78513          	addi	a0,a5,12
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	620080e7          	jalr	1568(ra) # 80000d2e <memmove>
  log_write(bp);
    80003716:	854a                	mv	a0,s2
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	bfe080e7          	jalr	-1026(ra) # 80004316 <log_write>
  brelse(bp);
    80003720:	854a                	mv	a0,s2
    80003722:	00000097          	auipc	ra,0x0
    80003726:	96a080e7          	jalr	-1686(ra) # 8000308c <brelse>
}
    8000372a:	60e2                	ld	ra,24(sp)
    8000372c:	6442                	ld	s0,16(sp)
    8000372e:	64a2                	ld	s1,8(sp)
    80003730:	6902                	ld	s2,0(sp)
    80003732:	6105                	addi	sp,sp,32
    80003734:	8082                	ret

0000000080003736 <idup>:
{
    80003736:	1101                	addi	sp,sp,-32
    80003738:	ec06                	sd	ra,24(sp)
    8000373a:	e822                	sd	s0,16(sp)
    8000373c:	e426                	sd	s1,8(sp)
    8000373e:	1000                	addi	s0,sp,32
    80003740:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003742:	0001c517          	auipc	a0,0x1c
    80003746:	97650513          	addi	a0,a0,-1674 # 8001f0b8 <itable>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	48c080e7          	jalr	1164(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003752:	449c                	lw	a5,8(s1)
    80003754:	2785                	addiw	a5,a5,1
    80003756:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003758:	0001c517          	auipc	a0,0x1c
    8000375c:	96050513          	addi	a0,a0,-1696 # 8001f0b8 <itable>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80003768:	8526                	mv	a0,s1
    8000376a:	60e2                	ld	ra,24(sp)
    8000376c:	6442                	ld	s0,16(sp)
    8000376e:	64a2                	ld	s1,8(sp)
    80003770:	6105                	addi	sp,sp,32
    80003772:	8082                	ret

0000000080003774 <ilock>:
{
    80003774:	1101                	addi	sp,sp,-32
    80003776:	ec06                	sd	ra,24(sp)
    80003778:	e822                	sd	s0,16(sp)
    8000377a:	e426                	sd	s1,8(sp)
    8000377c:	e04a                	sd	s2,0(sp)
    8000377e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003780:	c115                	beqz	a0,800037a4 <ilock+0x30>
    80003782:	84aa                	mv	s1,a0
    80003784:	451c                	lw	a5,8(a0)
    80003786:	00f05f63          	blez	a5,800037a4 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000378a:	0541                	addi	a0,a0,16
    8000378c:	00001097          	auipc	ra,0x1
    80003790:	ca8080e7          	jalr	-856(ra) # 80004434 <acquiresleep>
  if(ip->valid == 0){
    80003794:	40bc                	lw	a5,64(s1)
    80003796:	cf99                	beqz	a5,800037b4 <ilock+0x40>
}
    80003798:	60e2                	ld	ra,24(sp)
    8000379a:	6442                	ld	s0,16(sp)
    8000379c:	64a2                	ld	s1,8(sp)
    8000379e:	6902                	ld	s2,0(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret
    panic("ilock");
    800037a4:	00005517          	auipc	a0,0x5
    800037a8:	e6c50513          	addi	a0,a0,-404 # 80008610 <syscalls+0x1c0>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	d94080e7          	jalr	-620(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037b4:	40dc                	lw	a5,4(s1)
    800037b6:	0047d79b          	srliw	a5,a5,0x4
    800037ba:	0001c597          	auipc	a1,0x1c
    800037be:	8f65a583          	lw	a1,-1802(a1) # 8001f0b0 <sb+0x18>
    800037c2:	9dbd                	addw	a1,a1,a5
    800037c4:	4088                	lw	a0,0(s1)
    800037c6:	fffff097          	auipc	ra,0xfffff
    800037ca:	796080e7          	jalr	1942(ra) # 80002f5c <bread>
    800037ce:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037d0:	05850593          	addi	a1,a0,88
    800037d4:	40dc                	lw	a5,4(s1)
    800037d6:	8bbd                	andi	a5,a5,15
    800037d8:	079a                	slli	a5,a5,0x6
    800037da:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037dc:	00059783          	lh	a5,0(a1)
    800037e0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037e4:	00259783          	lh	a5,2(a1)
    800037e8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037ec:	00459783          	lh	a5,4(a1)
    800037f0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037f4:	00659783          	lh	a5,6(a1)
    800037f8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037fc:	459c                	lw	a5,8(a1)
    800037fe:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003800:	03400613          	li	a2,52
    80003804:	05b1                	addi	a1,a1,12
    80003806:	05048513          	addi	a0,s1,80
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	524080e7          	jalr	1316(ra) # 80000d2e <memmove>
    brelse(bp);
    80003812:	854a                	mv	a0,s2
    80003814:	00000097          	auipc	ra,0x0
    80003818:	878080e7          	jalr	-1928(ra) # 8000308c <brelse>
    ip->valid = 1;
    8000381c:	4785                	li	a5,1
    8000381e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003820:	04449783          	lh	a5,68(s1)
    80003824:	fbb5                	bnez	a5,80003798 <ilock+0x24>
      panic("ilock: no type");
    80003826:	00005517          	auipc	a0,0x5
    8000382a:	df250513          	addi	a0,a0,-526 # 80008618 <syscalls+0x1c8>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	d12080e7          	jalr	-750(ra) # 80000540 <panic>

0000000080003836 <iunlock>:
{
    80003836:	1101                	addi	sp,sp,-32
    80003838:	ec06                	sd	ra,24(sp)
    8000383a:	e822                	sd	s0,16(sp)
    8000383c:	e426                	sd	s1,8(sp)
    8000383e:	e04a                	sd	s2,0(sp)
    80003840:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003842:	c905                	beqz	a0,80003872 <iunlock+0x3c>
    80003844:	84aa                	mv	s1,a0
    80003846:	01050913          	addi	s2,a0,16
    8000384a:	854a                	mv	a0,s2
    8000384c:	00001097          	auipc	ra,0x1
    80003850:	c82080e7          	jalr	-894(ra) # 800044ce <holdingsleep>
    80003854:	cd19                	beqz	a0,80003872 <iunlock+0x3c>
    80003856:	449c                	lw	a5,8(s1)
    80003858:	00f05d63          	blez	a5,80003872 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000385c:	854a                	mv	a0,s2
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	c2c080e7          	jalr	-980(ra) # 8000448a <releasesleep>
}
    80003866:	60e2                	ld	ra,24(sp)
    80003868:	6442                	ld	s0,16(sp)
    8000386a:	64a2                	ld	s1,8(sp)
    8000386c:	6902                	ld	s2,0(sp)
    8000386e:	6105                	addi	sp,sp,32
    80003870:	8082                	ret
    panic("iunlock");
    80003872:	00005517          	auipc	a0,0x5
    80003876:	db650513          	addi	a0,a0,-586 # 80008628 <syscalls+0x1d8>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	cc6080e7          	jalr	-826(ra) # 80000540 <panic>

0000000080003882 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003882:	7179                	addi	sp,sp,-48
    80003884:	f406                	sd	ra,40(sp)
    80003886:	f022                	sd	s0,32(sp)
    80003888:	ec26                	sd	s1,24(sp)
    8000388a:	e84a                	sd	s2,16(sp)
    8000388c:	e44e                	sd	s3,8(sp)
    8000388e:	e052                	sd	s4,0(sp)
    80003890:	1800                	addi	s0,sp,48
    80003892:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003894:	05050493          	addi	s1,a0,80
    80003898:	08050913          	addi	s2,a0,128
    8000389c:	a021                	j	800038a4 <itrunc+0x22>
    8000389e:	0491                	addi	s1,s1,4
    800038a0:	01248d63          	beq	s1,s2,800038ba <itrunc+0x38>
    if(ip->addrs[i]){
    800038a4:	408c                	lw	a1,0(s1)
    800038a6:	dde5                	beqz	a1,8000389e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038a8:	0009a503          	lw	a0,0(s3)
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	8f6080e7          	jalr	-1802(ra) # 800031a2 <bfree>
      ip->addrs[i] = 0;
    800038b4:	0004a023          	sw	zero,0(s1)
    800038b8:	b7dd                	j	8000389e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ba:	0809a583          	lw	a1,128(s3)
    800038be:	e185                	bnez	a1,800038de <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038c0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038c4:	854e                	mv	a0,s3
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	de2080e7          	jalr	-542(ra) # 800036a8 <iupdate>
}
    800038ce:	70a2                	ld	ra,40(sp)
    800038d0:	7402                	ld	s0,32(sp)
    800038d2:	64e2                	ld	s1,24(sp)
    800038d4:	6942                	ld	s2,16(sp)
    800038d6:	69a2                	ld	s3,8(sp)
    800038d8:	6a02                	ld	s4,0(sp)
    800038da:	6145                	addi	sp,sp,48
    800038dc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038de:	0009a503          	lw	a0,0(s3)
    800038e2:	fffff097          	auipc	ra,0xfffff
    800038e6:	67a080e7          	jalr	1658(ra) # 80002f5c <bread>
    800038ea:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038ec:	05850493          	addi	s1,a0,88
    800038f0:	45850913          	addi	s2,a0,1112
    800038f4:	a021                	j	800038fc <itrunc+0x7a>
    800038f6:	0491                	addi	s1,s1,4
    800038f8:	01248b63          	beq	s1,s2,8000390e <itrunc+0x8c>
      if(a[j])
    800038fc:	408c                	lw	a1,0(s1)
    800038fe:	dde5                	beqz	a1,800038f6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003900:	0009a503          	lw	a0,0(s3)
    80003904:	00000097          	auipc	ra,0x0
    80003908:	89e080e7          	jalr	-1890(ra) # 800031a2 <bfree>
    8000390c:	b7ed                	j	800038f6 <itrunc+0x74>
    brelse(bp);
    8000390e:	8552                	mv	a0,s4
    80003910:	fffff097          	auipc	ra,0xfffff
    80003914:	77c080e7          	jalr	1916(ra) # 8000308c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003918:	0809a583          	lw	a1,128(s3)
    8000391c:	0009a503          	lw	a0,0(s3)
    80003920:	00000097          	auipc	ra,0x0
    80003924:	882080e7          	jalr	-1918(ra) # 800031a2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003928:	0809a023          	sw	zero,128(s3)
    8000392c:	bf51                	j	800038c0 <itrunc+0x3e>

000000008000392e <iput>:
{
    8000392e:	1101                	addi	sp,sp,-32
    80003930:	ec06                	sd	ra,24(sp)
    80003932:	e822                	sd	s0,16(sp)
    80003934:	e426                	sd	s1,8(sp)
    80003936:	e04a                	sd	s2,0(sp)
    80003938:	1000                	addi	s0,sp,32
    8000393a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000393c:	0001b517          	auipc	a0,0x1b
    80003940:	77c50513          	addi	a0,a0,1916 # 8001f0b8 <itable>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	292080e7          	jalr	658(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394c:	4498                	lw	a4,8(s1)
    8000394e:	4785                	li	a5,1
    80003950:	02f70363          	beq	a4,a5,80003976 <iput+0x48>
  ip->ref--;
    80003954:	449c                	lw	a5,8(s1)
    80003956:	37fd                	addiw	a5,a5,-1
    80003958:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000395a:	0001b517          	auipc	a0,0x1b
    8000395e:	75e50513          	addi	a0,a0,1886 # 8001f0b8 <itable>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	328080e7          	jalr	808(ra) # 80000c8a <release>
}
    8000396a:	60e2                	ld	ra,24(sp)
    8000396c:	6442                	ld	s0,16(sp)
    8000396e:	64a2                	ld	s1,8(sp)
    80003970:	6902                	ld	s2,0(sp)
    80003972:	6105                	addi	sp,sp,32
    80003974:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003976:	40bc                	lw	a5,64(s1)
    80003978:	dff1                	beqz	a5,80003954 <iput+0x26>
    8000397a:	04a49783          	lh	a5,74(s1)
    8000397e:	fbf9                	bnez	a5,80003954 <iput+0x26>
    acquiresleep(&ip->lock);
    80003980:	01048913          	addi	s2,s1,16
    80003984:	854a                	mv	a0,s2
    80003986:	00001097          	auipc	ra,0x1
    8000398a:	aae080e7          	jalr	-1362(ra) # 80004434 <acquiresleep>
    release(&itable.lock);
    8000398e:	0001b517          	auipc	a0,0x1b
    80003992:	72a50513          	addi	a0,a0,1834 # 8001f0b8 <itable>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	2f4080e7          	jalr	756(ra) # 80000c8a <release>
    itrunc(ip);
    8000399e:	8526                	mv	a0,s1
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	ee2080e7          	jalr	-286(ra) # 80003882 <itrunc>
    ip->type = 0;
    800039a8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ac:	8526                	mv	a0,s1
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	cfa080e7          	jalr	-774(ra) # 800036a8 <iupdate>
    ip->valid = 0;
    800039b6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ba:	854a                	mv	a0,s2
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	ace080e7          	jalr	-1330(ra) # 8000448a <releasesleep>
    acquire(&itable.lock);
    800039c4:	0001b517          	auipc	a0,0x1b
    800039c8:	6f450513          	addi	a0,a0,1780 # 8001f0b8 <itable>
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	20a080e7          	jalr	522(ra) # 80000bd6 <acquire>
    800039d4:	b741                	j	80003954 <iput+0x26>

00000000800039d6 <iunlockput>:
{
    800039d6:	1101                	addi	sp,sp,-32
    800039d8:	ec06                	sd	ra,24(sp)
    800039da:	e822                	sd	s0,16(sp)
    800039dc:	e426                	sd	s1,8(sp)
    800039de:	1000                	addi	s0,sp,32
    800039e0:	84aa                	mv	s1,a0
  iunlock(ip);
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	e54080e7          	jalr	-428(ra) # 80003836 <iunlock>
  iput(ip);
    800039ea:	8526                	mv	a0,s1
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	f42080e7          	jalr	-190(ra) # 8000392e <iput>
}
    800039f4:	60e2                	ld	ra,24(sp)
    800039f6:	6442                	ld	s0,16(sp)
    800039f8:	64a2                	ld	s1,8(sp)
    800039fa:	6105                	addi	sp,sp,32
    800039fc:	8082                	ret

00000000800039fe <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039fe:	1141                	addi	sp,sp,-16
    80003a00:	e422                	sd	s0,8(sp)
    80003a02:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a04:	411c                	lw	a5,0(a0)
    80003a06:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a08:	415c                	lw	a5,4(a0)
    80003a0a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a0c:	04451783          	lh	a5,68(a0)
    80003a10:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a14:	04a51783          	lh	a5,74(a0)
    80003a18:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a1c:	04c56783          	lwu	a5,76(a0)
    80003a20:	e99c                	sd	a5,16(a1)
}
    80003a22:	6422                	ld	s0,8(sp)
    80003a24:	0141                	addi	sp,sp,16
    80003a26:	8082                	ret

0000000080003a28 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a28:	457c                	lw	a5,76(a0)
    80003a2a:	0ed7e963          	bltu	a5,a3,80003b1c <readi+0xf4>
{
    80003a2e:	7159                	addi	sp,sp,-112
    80003a30:	f486                	sd	ra,104(sp)
    80003a32:	f0a2                	sd	s0,96(sp)
    80003a34:	eca6                	sd	s1,88(sp)
    80003a36:	e8ca                	sd	s2,80(sp)
    80003a38:	e4ce                	sd	s3,72(sp)
    80003a3a:	e0d2                	sd	s4,64(sp)
    80003a3c:	fc56                	sd	s5,56(sp)
    80003a3e:	f85a                	sd	s6,48(sp)
    80003a40:	f45e                	sd	s7,40(sp)
    80003a42:	f062                	sd	s8,32(sp)
    80003a44:	ec66                	sd	s9,24(sp)
    80003a46:	e86a                	sd	s10,16(sp)
    80003a48:	e46e                	sd	s11,8(sp)
    80003a4a:	1880                	addi	s0,sp,112
    80003a4c:	8b2a                	mv	s6,a0
    80003a4e:	8bae                	mv	s7,a1
    80003a50:	8a32                	mv	s4,a2
    80003a52:	84b6                	mv	s1,a3
    80003a54:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a56:	9f35                	addw	a4,a4,a3
    return 0;
    80003a58:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a5a:	0ad76063          	bltu	a4,a3,80003afa <readi+0xd2>
  if(off + n > ip->size)
    80003a5e:	00e7f463          	bgeu	a5,a4,80003a66 <readi+0x3e>
    n = ip->size - off;
    80003a62:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a66:	0a0a8963          	beqz	s5,80003b18 <readi+0xf0>
    80003a6a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a70:	5c7d                	li	s8,-1
    80003a72:	a82d                	j	80003aac <readi+0x84>
    80003a74:	020d1d93          	slli	s11,s10,0x20
    80003a78:	020ddd93          	srli	s11,s11,0x20
    80003a7c:	05890613          	addi	a2,s2,88
    80003a80:	86ee                	mv	a3,s11
    80003a82:	963a                	add	a2,a2,a4
    80003a84:	85d2                	mv	a1,s4
    80003a86:	855e                	mv	a0,s7
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	9d4080e7          	jalr	-1580(ra) # 8000245c <either_copyout>
    80003a90:	05850d63          	beq	a0,s8,80003aea <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a94:	854a                	mv	a0,s2
    80003a96:	fffff097          	auipc	ra,0xfffff
    80003a9a:	5f6080e7          	jalr	1526(ra) # 8000308c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9e:	013d09bb          	addw	s3,s10,s3
    80003aa2:	009d04bb          	addw	s1,s10,s1
    80003aa6:	9a6e                	add	s4,s4,s11
    80003aa8:	0559f763          	bgeu	s3,s5,80003af6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003aac:	00a4d59b          	srliw	a1,s1,0xa
    80003ab0:	855a                	mv	a0,s6
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	89e080e7          	jalr	-1890(ra) # 80003350 <bmap>
    80003aba:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003abe:	cd85                	beqz	a1,80003af6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ac0:	000b2503          	lw	a0,0(s6)
    80003ac4:	fffff097          	auipc	ra,0xfffff
    80003ac8:	498080e7          	jalr	1176(ra) # 80002f5c <bread>
    80003acc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ace:	3ff4f713          	andi	a4,s1,1023
    80003ad2:	40ec87bb          	subw	a5,s9,a4
    80003ad6:	413a86bb          	subw	a3,s5,s3
    80003ada:	8d3e                	mv	s10,a5
    80003adc:	2781                	sext.w	a5,a5
    80003ade:	0006861b          	sext.w	a2,a3
    80003ae2:	f8f679e3          	bgeu	a2,a5,80003a74 <readi+0x4c>
    80003ae6:	8d36                	mv	s10,a3
    80003ae8:	b771                	j	80003a74 <readi+0x4c>
      brelse(bp);
    80003aea:	854a                	mv	a0,s2
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	5a0080e7          	jalr	1440(ra) # 8000308c <brelse>
      tot = -1;
    80003af4:	59fd                	li	s3,-1
  }
  return tot;
    80003af6:	0009851b          	sext.w	a0,s3
}
    80003afa:	70a6                	ld	ra,104(sp)
    80003afc:	7406                	ld	s0,96(sp)
    80003afe:	64e6                	ld	s1,88(sp)
    80003b00:	6946                	ld	s2,80(sp)
    80003b02:	69a6                	ld	s3,72(sp)
    80003b04:	6a06                	ld	s4,64(sp)
    80003b06:	7ae2                	ld	s5,56(sp)
    80003b08:	7b42                	ld	s6,48(sp)
    80003b0a:	7ba2                	ld	s7,40(sp)
    80003b0c:	7c02                	ld	s8,32(sp)
    80003b0e:	6ce2                	ld	s9,24(sp)
    80003b10:	6d42                	ld	s10,16(sp)
    80003b12:	6da2                	ld	s11,8(sp)
    80003b14:	6165                	addi	sp,sp,112
    80003b16:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b18:	89d6                	mv	s3,s5
    80003b1a:	bff1                	j	80003af6 <readi+0xce>
    return 0;
    80003b1c:	4501                	li	a0,0
}
    80003b1e:	8082                	ret

0000000080003b20 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b20:	457c                	lw	a5,76(a0)
    80003b22:	10d7e863          	bltu	a5,a3,80003c32 <writei+0x112>
{
    80003b26:	7159                	addi	sp,sp,-112
    80003b28:	f486                	sd	ra,104(sp)
    80003b2a:	f0a2                	sd	s0,96(sp)
    80003b2c:	eca6                	sd	s1,88(sp)
    80003b2e:	e8ca                	sd	s2,80(sp)
    80003b30:	e4ce                	sd	s3,72(sp)
    80003b32:	e0d2                	sd	s4,64(sp)
    80003b34:	fc56                	sd	s5,56(sp)
    80003b36:	f85a                	sd	s6,48(sp)
    80003b38:	f45e                	sd	s7,40(sp)
    80003b3a:	f062                	sd	s8,32(sp)
    80003b3c:	ec66                	sd	s9,24(sp)
    80003b3e:	e86a                	sd	s10,16(sp)
    80003b40:	e46e                	sd	s11,8(sp)
    80003b42:	1880                	addi	s0,sp,112
    80003b44:	8aaa                	mv	s5,a0
    80003b46:	8bae                	mv	s7,a1
    80003b48:	8a32                	mv	s4,a2
    80003b4a:	8936                	mv	s2,a3
    80003b4c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b4e:	00e687bb          	addw	a5,a3,a4
    80003b52:	0ed7e263          	bltu	a5,a3,80003c36 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b56:	00043737          	lui	a4,0x43
    80003b5a:	0ef76063          	bltu	a4,a5,80003c3a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5e:	0c0b0863          	beqz	s6,80003c2e <writei+0x10e>
    80003b62:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b64:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b68:	5c7d                	li	s8,-1
    80003b6a:	a091                	j	80003bae <writei+0x8e>
    80003b6c:	020d1d93          	slli	s11,s10,0x20
    80003b70:	020ddd93          	srli	s11,s11,0x20
    80003b74:	05848513          	addi	a0,s1,88
    80003b78:	86ee                	mv	a3,s11
    80003b7a:	8652                	mv	a2,s4
    80003b7c:	85de                	mv	a1,s7
    80003b7e:	953a                	add	a0,a0,a4
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	932080e7          	jalr	-1742(ra) # 800024b2 <either_copyin>
    80003b88:	07850263          	beq	a0,s8,80003bec <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	788080e7          	jalr	1928(ra) # 80004316 <log_write>
    brelse(bp);
    80003b96:	8526                	mv	a0,s1
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	4f4080e7          	jalr	1268(ra) # 8000308c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	013d09bb          	addw	s3,s10,s3
    80003ba4:	012d093b          	addw	s2,s10,s2
    80003ba8:	9a6e                	add	s4,s4,s11
    80003baa:	0569f663          	bgeu	s3,s6,80003bf6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bae:	00a9559b          	srliw	a1,s2,0xa
    80003bb2:	8556                	mv	a0,s5
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	79c080e7          	jalr	1948(ra) # 80003350 <bmap>
    80003bbc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bc0:	c99d                	beqz	a1,80003bf6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bc2:	000aa503          	lw	a0,0(s5)
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	396080e7          	jalr	918(ra) # 80002f5c <bread>
    80003bce:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd0:	3ff97713          	andi	a4,s2,1023
    80003bd4:	40ec87bb          	subw	a5,s9,a4
    80003bd8:	413b06bb          	subw	a3,s6,s3
    80003bdc:	8d3e                	mv	s10,a5
    80003bde:	2781                	sext.w	a5,a5
    80003be0:	0006861b          	sext.w	a2,a3
    80003be4:	f8f674e3          	bgeu	a2,a5,80003b6c <writei+0x4c>
    80003be8:	8d36                	mv	s10,a3
    80003bea:	b749                	j	80003b6c <writei+0x4c>
      brelse(bp);
    80003bec:	8526                	mv	a0,s1
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	49e080e7          	jalr	1182(ra) # 8000308c <brelse>
  }

  if(off > ip->size)
    80003bf6:	04caa783          	lw	a5,76(s5)
    80003bfa:	0127f463          	bgeu	a5,s2,80003c02 <writei+0xe2>
    ip->size = off;
    80003bfe:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c02:	8556                	mv	a0,s5
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	aa4080e7          	jalr	-1372(ra) # 800036a8 <iupdate>

  return tot;
    80003c0c:	0009851b          	sext.w	a0,s3
}
    80003c10:	70a6                	ld	ra,104(sp)
    80003c12:	7406                	ld	s0,96(sp)
    80003c14:	64e6                	ld	s1,88(sp)
    80003c16:	6946                	ld	s2,80(sp)
    80003c18:	69a6                	ld	s3,72(sp)
    80003c1a:	6a06                	ld	s4,64(sp)
    80003c1c:	7ae2                	ld	s5,56(sp)
    80003c1e:	7b42                	ld	s6,48(sp)
    80003c20:	7ba2                	ld	s7,40(sp)
    80003c22:	7c02                	ld	s8,32(sp)
    80003c24:	6ce2                	ld	s9,24(sp)
    80003c26:	6d42                	ld	s10,16(sp)
    80003c28:	6da2                	ld	s11,8(sp)
    80003c2a:	6165                	addi	sp,sp,112
    80003c2c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c2e:	89da                	mv	s3,s6
    80003c30:	bfc9                	j	80003c02 <writei+0xe2>
    return -1;
    80003c32:	557d                	li	a0,-1
}
    80003c34:	8082                	ret
    return -1;
    80003c36:	557d                	li	a0,-1
    80003c38:	bfe1                	j	80003c10 <writei+0xf0>
    return -1;
    80003c3a:	557d                	li	a0,-1
    80003c3c:	bfd1                	j	80003c10 <writei+0xf0>

0000000080003c3e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c3e:	1141                	addi	sp,sp,-16
    80003c40:	e406                	sd	ra,8(sp)
    80003c42:	e022                	sd	s0,0(sp)
    80003c44:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c46:	4639                	li	a2,14
    80003c48:	ffffd097          	auipc	ra,0xffffd
    80003c4c:	15a080e7          	jalr	346(ra) # 80000da2 <strncmp>
}
    80003c50:	60a2                	ld	ra,8(sp)
    80003c52:	6402                	ld	s0,0(sp)
    80003c54:	0141                	addi	sp,sp,16
    80003c56:	8082                	ret

0000000080003c58 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c58:	7139                	addi	sp,sp,-64
    80003c5a:	fc06                	sd	ra,56(sp)
    80003c5c:	f822                	sd	s0,48(sp)
    80003c5e:	f426                	sd	s1,40(sp)
    80003c60:	f04a                	sd	s2,32(sp)
    80003c62:	ec4e                	sd	s3,24(sp)
    80003c64:	e852                	sd	s4,16(sp)
    80003c66:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c68:	04451703          	lh	a4,68(a0)
    80003c6c:	4785                	li	a5,1
    80003c6e:	00f71a63          	bne	a4,a5,80003c82 <dirlookup+0x2a>
    80003c72:	892a                	mv	s2,a0
    80003c74:	89ae                	mv	s3,a1
    80003c76:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c78:	457c                	lw	a5,76(a0)
    80003c7a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c7c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7e:	e79d                	bnez	a5,80003cac <dirlookup+0x54>
    80003c80:	a8a5                	j	80003cf8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c82:	00005517          	auipc	a0,0x5
    80003c86:	9ae50513          	addi	a0,a0,-1618 # 80008630 <syscalls+0x1e0>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	8b6080e7          	jalr	-1866(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c92:	00005517          	auipc	a0,0x5
    80003c96:	9b650513          	addi	a0,a0,-1610 # 80008648 <syscalls+0x1f8>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	8a6080e7          	jalr	-1882(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca2:	24c1                	addiw	s1,s1,16
    80003ca4:	04c92783          	lw	a5,76(s2)
    80003ca8:	04f4f763          	bgeu	s1,a5,80003cf6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cac:	4741                	li	a4,16
    80003cae:	86a6                	mv	a3,s1
    80003cb0:	fc040613          	addi	a2,s0,-64
    80003cb4:	4581                	li	a1,0
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	d70080e7          	jalr	-656(ra) # 80003a28 <readi>
    80003cc0:	47c1                	li	a5,16
    80003cc2:	fcf518e3          	bne	a0,a5,80003c92 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc6:	fc045783          	lhu	a5,-64(s0)
    80003cca:	dfe1                	beqz	a5,80003ca2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ccc:	fc240593          	addi	a1,s0,-62
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	f6c080e7          	jalr	-148(ra) # 80003c3e <namecmp>
    80003cda:	f561                	bnez	a0,80003ca2 <dirlookup+0x4a>
      if(poff)
    80003cdc:	000a0463          	beqz	s4,80003ce4 <dirlookup+0x8c>
        *poff = off;
    80003ce0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ce4:	fc045583          	lhu	a1,-64(s0)
    80003ce8:	00092503          	lw	a0,0(s2)
    80003cec:	fffff097          	auipc	ra,0xfffff
    80003cf0:	74e080e7          	jalr	1870(ra) # 8000343a <iget>
    80003cf4:	a011                	j	80003cf8 <dirlookup+0xa0>
  return 0;
    80003cf6:	4501                	li	a0,0
}
    80003cf8:	70e2                	ld	ra,56(sp)
    80003cfa:	7442                	ld	s0,48(sp)
    80003cfc:	74a2                	ld	s1,40(sp)
    80003cfe:	7902                	ld	s2,32(sp)
    80003d00:	69e2                	ld	s3,24(sp)
    80003d02:	6a42                	ld	s4,16(sp)
    80003d04:	6121                	addi	sp,sp,64
    80003d06:	8082                	ret

0000000080003d08 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d08:	711d                	addi	sp,sp,-96
    80003d0a:	ec86                	sd	ra,88(sp)
    80003d0c:	e8a2                	sd	s0,80(sp)
    80003d0e:	e4a6                	sd	s1,72(sp)
    80003d10:	e0ca                	sd	s2,64(sp)
    80003d12:	fc4e                	sd	s3,56(sp)
    80003d14:	f852                	sd	s4,48(sp)
    80003d16:	f456                	sd	s5,40(sp)
    80003d18:	f05a                	sd	s6,32(sp)
    80003d1a:	ec5e                	sd	s7,24(sp)
    80003d1c:	e862                	sd	s8,16(sp)
    80003d1e:	e466                	sd	s9,8(sp)
    80003d20:	e06a                	sd	s10,0(sp)
    80003d22:	1080                	addi	s0,sp,96
    80003d24:	84aa                	mv	s1,a0
    80003d26:	8b2e                	mv	s6,a1
    80003d28:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d2a:	00054703          	lbu	a4,0(a0)
    80003d2e:	02f00793          	li	a5,47
    80003d32:	02f70363          	beq	a4,a5,80003d58 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d36:	ffffe097          	auipc	ra,0xffffe
    80003d3a:	c76080e7          	jalr	-906(ra) # 800019ac <myproc>
    80003d3e:	15053503          	ld	a0,336(a0)
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	9f4080e7          	jalr	-1548(ra) # 80003736 <idup>
    80003d4a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d4c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d50:	4cb5                	li	s9,13
  len = path - s;
    80003d52:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d54:	4c05                	li	s8,1
    80003d56:	a87d                	j	80003e14 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d58:	4585                	li	a1,1
    80003d5a:	4505                	li	a0,1
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	6de080e7          	jalr	1758(ra) # 8000343a <iget>
    80003d64:	8a2a                	mv	s4,a0
    80003d66:	b7dd                	j	80003d4c <namex+0x44>
      iunlockput(ip);
    80003d68:	8552                	mv	a0,s4
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	c6c080e7          	jalr	-916(ra) # 800039d6 <iunlockput>
      return 0;
    80003d72:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d74:	8552                	mv	a0,s4
    80003d76:	60e6                	ld	ra,88(sp)
    80003d78:	6446                	ld	s0,80(sp)
    80003d7a:	64a6                	ld	s1,72(sp)
    80003d7c:	6906                	ld	s2,64(sp)
    80003d7e:	79e2                	ld	s3,56(sp)
    80003d80:	7a42                	ld	s4,48(sp)
    80003d82:	7aa2                	ld	s5,40(sp)
    80003d84:	7b02                	ld	s6,32(sp)
    80003d86:	6be2                	ld	s7,24(sp)
    80003d88:	6c42                	ld	s8,16(sp)
    80003d8a:	6ca2                	ld	s9,8(sp)
    80003d8c:	6d02                	ld	s10,0(sp)
    80003d8e:	6125                	addi	sp,sp,96
    80003d90:	8082                	ret
      iunlock(ip);
    80003d92:	8552                	mv	a0,s4
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	aa2080e7          	jalr	-1374(ra) # 80003836 <iunlock>
      return ip;
    80003d9c:	bfe1                	j	80003d74 <namex+0x6c>
      iunlockput(ip);
    80003d9e:	8552                	mv	a0,s4
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	c36080e7          	jalr	-970(ra) # 800039d6 <iunlockput>
      return 0;
    80003da8:	8a4e                	mv	s4,s3
    80003daa:	b7e9                	j	80003d74 <namex+0x6c>
  len = path - s;
    80003dac:	40998633          	sub	a2,s3,s1
    80003db0:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003db4:	09acd863          	bge	s9,s10,80003e44 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003db8:	4639                	li	a2,14
    80003dba:	85a6                	mv	a1,s1
    80003dbc:	8556                	mv	a0,s5
    80003dbe:	ffffd097          	auipc	ra,0xffffd
    80003dc2:	f70080e7          	jalr	-144(ra) # 80000d2e <memmove>
    80003dc6:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dc8:	0004c783          	lbu	a5,0(s1)
    80003dcc:	01279763          	bne	a5,s2,80003dda <namex+0xd2>
    path++;
    80003dd0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	ff278de3          	beq	a5,s2,80003dd0 <namex+0xc8>
    ilock(ip);
    80003dda:	8552                	mv	a0,s4
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	998080e7          	jalr	-1640(ra) # 80003774 <ilock>
    if(ip->type != T_DIR){
    80003de4:	044a1783          	lh	a5,68(s4)
    80003de8:	f98790e3          	bne	a5,s8,80003d68 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003dec:	000b0563          	beqz	s6,80003df6 <namex+0xee>
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	dfd9                	beqz	a5,80003d92 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003df6:	865e                	mv	a2,s7
    80003df8:	85d6                	mv	a1,s5
    80003dfa:	8552                	mv	a0,s4
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	e5c080e7          	jalr	-420(ra) # 80003c58 <dirlookup>
    80003e04:	89aa                	mv	s3,a0
    80003e06:	dd41                	beqz	a0,80003d9e <namex+0x96>
    iunlockput(ip);
    80003e08:	8552                	mv	a0,s4
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	bcc080e7          	jalr	-1076(ra) # 800039d6 <iunlockput>
    ip = next;
    80003e12:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e14:	0004c783          	lbu	a5,0(s1)
    80003e18:	01279763          	bne	a5,s2,80003e26 <namex+0x11e>
    path++;
    80003e1c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e1e:	0004c783          	lbu	a5,0(s1)
    80003e22:	ff278de3          	beq	a5,s2,80003e1c <namex+0x114>
  if(*path == 0)
    80003e26:	cb9d                	beqz	a5,80003e5c <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e28:	0004c783          	lbu	a5,0(s1)
    80003e2c:	89a6                	mv	s3,s1
  len = path - s;
    80003e2e:	8d5e                	mv	s10,s7
    80003e30:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e32:	01278963          	beq	a5,s2,80003e44 <namex+0x13c>
    80003e36:	dbbd                	beqz	a5,80003dac <namex+0xa4>
    path++;
    80003e38:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e3a:	0009c783          	lbu	a5,0(s3)
    80003e3e:	ff279ce3          	bne	a5,s2,80003e36 <namex+0x12e>
    80003e42:	b7ad                	j	80003dac <namex+0xa4>
    memmove(name, s, len);
    80003e44:	2601                	sext.w	a2,a2
    80003e46:	85a6                	mv	a1,s1
    80003e48:	8556                	mv	a0,s5
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	ee4080e7          	jalr	-284(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e52:	9d56                	add	s10,s10,s5
    80003e54:	000d0023          	sb	zero,0(s10)
    80003e58:	84ce                	mv	s1,s3
    80003e5a:	b7bd                	j	80003dc8 <namex+0xc0>
  if(nameiparent){
    80003e5c:	f00b0ce3          	beqz	s6,80003d74 <namex+0x6c>
    iput(ip);
    80003e60:	8552                	mv	a0,s4
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	acc080e7          	jalr	-1332(ra) # 8000392e <iput>
    return 0;
    80003e6a:	4a01                	li	s4,0
    80003e6c:	b721                	j	80003d74 <namex+0x6c>

0000000080003e6e <dirlink>:
{
    80003e6e:	7139                	addi	sp,sp,-64
    80003e70:	fc06                	sd	ra,56(sp)
    80003e72:	f822                	sd	s0,48(sp)
    80003e74:	f426                	sd	s1,40(sp)
    80003e76:	f04a                	sd	s2,32(sp)
    80003e78:	ec4e                	sd	s3,24(sp)
    80003e7a:	e852                	sd	s4,16(sp)
    80003e7c:	0080                	addi	s0,sp,64
    80003e7e:	892a                	mv	s2,a0
    80003e80:	8a2e                	mv	s4,a1
    80003e82:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e84:	4601                	li	a2,0
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	dd2080e7          	jalr	-558(ra) # 80003c58 <dirlookup>
    80003e8e:	e93d                	bnez	a0,80003f04 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e90:	04c92483          	lw	s1,76(s2)
    80003e94:	c49d                	beqz	s1,80003ec2 <dirlink+0x54>
    80003e96:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e98:	4741                	li	a4,16
    80003e9a:	86a6                	mv	a3,s1
    80003e9c:	fc040613          	addi	a2,s0,-64
    80003ea0:	4581                	li	a1,0
    80003ea2:	854a                	mv	a0,s2
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	b84080e7          	jalr	-1148(ra) # 80003a28 <readi>
    80003eac:	47c1                	li	a5,16
    80003eae:	06f51163          	bne	a0,a5,80003f10 <dirlink+0xa2>
    if(de.inum == 0)
    80003eb2:	fc045783          	lhu	a5,-64(s0)
    80003eb6:	c791                	beqz	a5,80003ec2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb8:	24c1                	addiw	s1,s1,16
    80003eba:	04c92783          	lw	a5,76(s2)
    80003ebe:	fcf4ede3          	bltu	s1,a5,80003e98 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ec2:	4639                	li	a2,14
    80003ec4:	85d2                	mv	a1,s4
    80003ec6:	fc240513          	addi	a0,s0,-62
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	f14080e7          	jalr	-236(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003ed2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed6:	4741                	li	a4,16
    80003ed8:	86a6                	mv	a3,s1
    80003eda:	fc040613          	addi	a2,s0,-64
    80003ede:	4581                	li	a1,0
    80003ee0:	854a                	mv	a0,s2
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	c3e080e7          	jalr	-962(ra) # 80003b20 <writei>
    80003eea:	1541                	addi	a0,a0,-16
    80003eec:	00a03533          	snez	a0,a0
    80003ef0:	40a00533          	neg	a0,a0
}
    80003ef4:	70e2                	ld	ra,56(sp)
    80003ef6:	7442                	ld	s0,48(sp)
    80003ef8:	74a2                	ld	s1,40(sp)
    80003efa:	7902                	ld	s2,32(sp)
    80003efc:	69e2                	ld	s3,24(sp)
    80003efe:	6a42                	ld	s4,16(sp)
    80003f00:	6121                	addi	sp,sp,64
    80003f02:	8082                	ret
    iput(ip);
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	a2a080e7          	jalr	-1494(ra) # 8000392e <iput>
    return -1;
    80003f0c:	557d                	li	a0,-1
    80003f0e:	b7dd                	j	80003ef4 <dirlink+0x86>
      panic("dirlink read");
    80003f10:	00004517          	auipc	a0,0x4
    80003f14:	74850513          	addi	a0,a0,1864 # 80008658 <syscalls+0x208>
    80003f18:	ffffc097          	auipc	ra,0xffffc
    80003f1c:	628080e7          	jalr	1576(ra) # 80000540 <panic>

0000000080003f20 <namei>:

struct inode*
namei(char *path)
{
    80003f20:	1101                	addi	sp,sp,-32
    80003f22:	ec06                	sd	ra,24(sp)
    80003f24:	e822                	sd	s0,16(sp)
    80003f26:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f28:	fe040613          	addi	a2,s0,-32
    80003f2c:	4581                	li	a1,0
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	dda080e7          	jalr	-550(ra) # 80003d08 <namex>
}
    80003f36:	60e2                	ld	ra,24(sp)
    80003f38:	6442                	ld	s0,16(sp)
    80003f3a:	6105                	addi	sp,sp,32
    80003f3c:	8082                	ret

0000000080003f3e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f3e:	1141                	addi	sp,sp,-16
    80003f40:	e406                	sd	ra,8(sp)
    80003f42:	e022                	sd	s0,0(sp)
    80003f44:	0800                	addi	s0,sp,16
    80003f46:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f48:	4585                	li	a1,1
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	dbe080e7          	jalr	-578(ra) # 80003d08 <namex>
}
    80003f52:	60a2                	ld	ra,8(sp)
    80003f54:	6402                	ld	s0,0(sp)
    80003f56:	0141                	addi	sp,sp,16
    80003f58:	8082                	ret

0000000080003f5a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f5a:	1101                	addi	sp,sp,-32
    80003f5c:	ec06                	sd	ra,24(sp)
    80003f5e:	e822                	sd	s0,16(sp)
    80003f60:	e426                	sd	s1,8(sp)
    80003f62:	e04a                	sd	s2,0(sp)
    80003f64:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f66:	0001d917          	auipc	s2,0x1d
    80003f6a:	bfa90913          	addi	s2,s2,-1030 # 80020b60 <log>
    80003f6e:	01892583          	lw	a1,24(s2)
    80003f72:	02892503          	lw	a0,40(s2)
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	fe6080e7          	jalr	-26(ra) # 80002f5c <bread>
    80003f7e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f80:	02c92683          	lw	a3,44(s2)
    80003f84:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f86:	02d05863          	blez	a3,80003fb6 <write_head+0x5c>
    80003f8a:	0001d797          	auipc	a5,0x1d
    80003f8e:	c0678793          	addi	a5,a5,-1018 # 80020b90 <log+0x30>
    80003f92:	05c50713          	addi	a4,a0,92
    80003f96:	36fd                	addiw	a3,a3,-1
    80003f98:	02069613          	slli	a2,a3,0x20
    80003f9c:	01e65693          	srli	a3,a2,0x1e
    80003fa0:	0001d617          	auipc	a2,0x1d
    80003fa4:	bf460613          	addi	a2,a2,-1036 # 80020b94 <log+0x34>
    80003fa8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003faa:	4390                	lw	a2,0(a5)
    80003fac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fae:	0791                	addi	a5,a5,4
    80003fb0:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fb2:	fed79ce3          	bne	a5,a3,80003faa <write_head+0x50>
  }
  bwrite(buf);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	096080e7          	jalr	150(ra) # 8000304e <bwrite>
  brelse(buf);
    80003fc0:	8526                	mv	a0,s1
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	0ca080e7          	jalr	202(ra) # 8000308c <brelse>
}
    80003fca:	60e2                	ld	ra,24(sp)
    80003fcc:	6442                	ld	s0,16(sp)
    80003fce:	64a2                	ld	s1,8(sp)
    80003fd0:	6902                	ld	s2,0(sp)
    80003fd2:	6105                	addi	sp,sp,32
    80003fd4:	8082                	ret

0000000080003fd6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd6:	0001d797          	auipc	a5,0x1d
    80003fda:	bb67a783          	lw	a5,-1098(a5) # 80020b8c <log+0x2c>
    80003fde:	0af05d63          	blez	a5,80004098 <install_trans+0xc2>
{
    80003fe2:	7139                	addi	sp,sp,-64
    80003fe4:	fc06                	sd	ra,56(sp)
    80003fe6:	f822                	sd	s0,48(sp)
    80003fe8:	f426                	sd	s1,40(sp)
    80003fea:	f04a                	sd	s2,32(sp)
    80003fec:	ec4e                	sd	s3,24(sp)
    80003fee:	e852                	sd	s4,16(sp)
    80003ff0:	e456                	sd	s5,8(sp)
    80003ff2:	e05a                	sd	s6,0(sp)
    80003ff4:	0080                	addi	s0,sp,64
    80003ff6:	8b2a                	mv	s6,a0
    80003ff8:	0001da97          	auipc	s5,0x1d
    80003ffc:	b98a8a93          	addi	s5,s5,-1128 # 80020b90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004000:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004002:	0001d997          	auipc	s3,0x1d
    80004006:	b5e98993          	addi	s3,s3,-1186 # 80020b60 <log>
    8000400a:	a00d                	j	8000402c <install_trans+0x56>
    brelse(lbuf);
    8000400c:	854a                	mv	a0,s2
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	07e080e7          	jalr	126(ra) # 8000308c <brelse>
    brelse(dbuf);
    80004016:	8526                	mv	a0,s1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	074080e7          	jalr	116(ra) # 8000308c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004020:	2a05                	addiw	s4,s4,1
    80004022:	0a91                	addi	s5,s5,4
    80004024:	02c9a783          	lw	a5,44(s3)
    80004028:	04fa5e63          	bge	s4,a5,80004084 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000402c:	0189a583          	lw	a1,24(s3)
    80004030:	014585bb          	addw	a1,a1,s4
    80004034:	2585                	addiw	a1,a1,1
    80004036:	0289a503          	lw	a0,40(s3)
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	f22080e7          	jalr	-222(ra) # 80002f5c <bread>
    80004042:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004044:	000aa583          	lw	a1,0(s5)
    80004048:	0289a503          	lw	a0,40(s3)
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	f10080e7          	jalr	-240(ra) # 80002f5c <bread>
    80004054:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004056:	40000613          	li	a2,1024
    8000405a:	05890593          	addi	a1,s2,88
    8000405e:	05850513          	addi	a0,a0,88
    80004062:	ffffd097          	auipc	ra,0xffffd
    80004066:	ccc080e7          	jalr	-820(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000406a:	8526                	mv	a0,s1
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	fe2080e7          	jalr	-30(ra) # 8000304e <bwrite>
    if(recovering == 0)
    80004074:	f80b1ce3          	bnez	s6,8000400c <install_trans+0x36>
      bunpin(dbuf);
    80004078:	8526                	mv	a0,s1
    8000407a:	fffff097          	auipc	ra,0xfffff
    8000407e:	0ec080e7          	jalr	236(ra) # 80003166 <bunpin>
    80004082:	b769                	j	8000400c <install_trans+0x36>
}
    80004084:	70e2                	ld	ra,56(sp)
    80004086:	7442                	ld	s0,48(sp)
    80004088:	74a2                	ld	s1,40(sp)
    8000408a:	7902                	ld	s2,32(sp)
    8000408c:	69e2                	ld	s3,24(sp)
    8000408e:	6a42                	ld	s4,16(sp)
    80004090:	6aa2                	ld	s5,8(sp)
    80004092:	6b02                	ld	s6,0(sp)
    80004094:	6121                	addi	sp,sp,64
    80004096:	8082                	ret
    80004098:	8082                	ret

000000008000409a <initlog>:
{
    8000409a:	7179                	addi	sp,sp,-48
    8000409c:	f406                	sd	ra,40(sp)
    8000409e:	f022                	sd	s0,32(sp)
    800040a0:	ec26                	sd	s1,24(sp)
    800040a2:	e84a                	sd	s2,16(sp)
    800040a4:	e44e                	sd	s3,8(sp)
    800040a6:	1800                	addi	s0,sp,48
    800040a8:	892a                	mv	s2,a0
    800040aa:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ac:	0001d497          	auipc	s1,0x1d
    800040b0:	ab448493          	addi	s1,s1,-1356 # 80020b60 <log>
    800040b4:	00004597          	auipc	a1,0x4
    800040b8:	5b458593          	addi	a1,a1,1460 # 80008668 <syscalls+0x218>
    800040bc:	8526                	mv	a0,s1
    800040be:	ffffd097          	auipc	ra,0xffffd
    800040c2:	a88080e7          	jalr	-1400(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800040c6:	0149a583          	lw	a1,20(s3)
    800040ca:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040cc:	0109a783          	lw	a5,16(s3)
    800040d0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040d2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040d6:	854a                	mv	a0,s2
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	e84080e7          	jalr	-380(ra) # 80002f5c <bread>
  log.lh.n = lh->n;
    800040e0:	4d34                	lw	a3,88(a0)
    800040e2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040e4:	02d05663          	blez	a3,80004110 <initlog+0x76>
    800040e8:	05c50793          	addi	a5,a0,92
    800040ec:	0001d717          	auipc	a4,0x1d
    800040f0:	aa470713          	addi	a4,a4,-1372 # 80020b90 <log+0x30>
    800040f4:	36fd                	addiw	a3,a3,-1
    800040f6:	02069613          	slli	a2,a3,0x20
    800040fa:	01e65693          	srli	a3,a2,0x1e
    800040fe:	06050613          	addi	a2,a0,96
    80004102:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004104:	4390                	lw	a2,0(a5)
    80004106:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004108:	0791                	addi	a5,a5,4
    8000410a:	0711                	addi	a4,a4,4
    8000410c:	fed79ce3          	bne	a5,a3,80004104 <initlog+0x6a>
  brelse(buf);
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	f7c080e7          	jalr	-132(ra) # 8000308c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004118:	4505                	li	a0,1
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	ebc080e7          	jalr	-324(ra) # 80003fd6 <install_trans>
  log.lh.n = 0;
    80004122:	0001d797          	auipc	a5,0x1d
    80004126:	a607a523          	sw	zero,-1430(a5) # 80020b8c <log+0x2c>
  write_head(); // clear the log
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	e30080e7          	jalr	-464(ra) # 80003f5a <write_head>
}
    80004132:	70a2                	ld	ra,40(sp)
    80004134:	7402                	ld	s0,32(sp)
    80004136:	64e2                	ld	s1,24(sp)
    80004138:	6942                	ld	s2,16(sp)
    8000413a:	69a2                	ld	s3,8(sp)
    8000413c:	6145                	addi	sp,sp,48
    8000413e:	8082                	ret

0000000080004140 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004140:	1101                	addi	sp,sp,-32
    80004142:	ec06                	sd	ra,24(sp)
    80004144:	e822                	sd	s0,16(sp)
    80004146:	e426                	sd	s1,8(sp)
    80004148:	e04a                	sd	s2,0(sp)
    8000414a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000414c:	0001d517          	auipc	a0,0x1d
    80004150:	a1450513          	addi	a0,a0,-1516 # 80020b60 <log>
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	a82080e7          	jalr	-1406(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000415c:	0001d497          	auipc	s1,0x1d
    80004160:	a0448493          	addi	s1,s1,-1532 # 80020b60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004164:	4979                	li	s2,30
    80004166:	a039                	j	80004174 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004168:	85a6                	mv	a1,s1
    8000416a:	8526                	mv	a0,s1
    8000416c:	ffffe097          	auipc	ra,0xffffe
    80004170:	ee8080e7          	jalr	-280(ra) # 80002054 <sleep>
    if(log.committing){
    80004174:	50dc                	lw	a5,36(s1)
    80004176:	fbed                	bnez	a5,80004168 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004178:	5098                	lw	a4,32(s1)
    8000417a:	2705                	addiw	a4,a4,1
    8000417c:	0007069b          	sext.w	a3,a4
    80004180:	0027179b          	slliw	a5,a4,0x2
    80004184:	9fb9                	addw	a5,a5,a4
    80004186:	0017979b          	slliw	a5,a5,0x1
    8000418a:	54d8                	lw	a4,44(s1)
    8000418c:	9fb9                	addw	a5,a5,a4
    8000418e:	00f95963          	bge	s2,a5,800041a0 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004192:	85a6                	mv	a1,s1
    80004194:	8526                	mv	a0,s1
    80004196:	ffffe097          	auipc	ra,0xffffe
    8000419a:	ebe080e7          	jalr	-322(ra) # 80002054 <sleep>
    8000419e:	bfd9                	j	80004174 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041a0:	0001d517          	auipc	a0,0x1d
    800041a4:	9c050513          	addi	a0,a0,-1600 # 80020b60 <log>
    800041a8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	ae0080e7          	jalr	-1312(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041b2:	60e2                	ld	ra,24(sp)
    800041b4:	6442                	ld	s0,16(sp)
    800041b6:	64a2                	ld	s1,8(sp)
    800041b8:	6902                	ld	s2,0(sp)
    800041ba:	6105                	addi	sp,sp,32
    800041bc:	8082                	ret

00000000800041be <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041be:	7139                	addi	sp,sp,-64
    800041c0:	fc06                	sd	ra,56(sp)
    800041c2:	f822                	sd	s0,48(sp)
    800041c4:	f426                	sd	s1,40(sp)
    800041c6:	f04a                	sd	s2,32(sp)
    800041c8:	ec4e                	sd	s3,24(sp)
    800041ca:	e852                	sd	s4,16(sp)
    800041cc:	e456                	sd	s5,8(sp)
    800041ce:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041d0:	0001d497          	auipc	s1,0x1d
    800041d4:	99048493          	addi	s1,s1,-1648 # 80020b60 <log>
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	9fc080e7          	jalr	-1540(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800041e2:	509c                	lw	a5,32(s1)
    800041e4:	37fd                	addiw	a5,a5,-1
    800041e6:	0007891b          	sext.w	s2,a5
    800041ea:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041ec:	50dc                	lw	a5,36(s1)
    800041ee:	e7b9                	bnez	a5,8000423c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041f0:	04091e63          	bnez	s2,8000424c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041f4:	0001d497          	auipc	s1,0x1d
    800041f8:	96c48493          	addi	s1,s1,-1684 # 80020b60 <log>
    800041fc:	4785                	li	a5,1
    800041fe:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004200:	8526                	mv	a0,s1
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	a88080e7          	jalr	-1400(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000420a:	54dc                	lw	a5,44(s1)
    8000420c:	06f04763          	bgtz	a5,8000427a <end_op+0xbc>
    acquire(&log.lock);
    80004210:	0001d497          	auipc	s1,0x1d
    80004214:	95048493          	addi	s1,s1,-1712 # 80020b60 <log>
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	9bc080e7          	jalr	-1604(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004222:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004226:	8526                	mv	a0,s1
    80004228:	ffffe097          	auipc	ra,0xffffe
    8000422c:	e90080e7          	jalr	-368(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004230:	8526                	mv	a0,s1
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	a58080e7          	jalr	-1448(ra) # 80000c8a <release>
}
    8000423a:	a03d                	j	80004268 <end_op+0xaa>
    panic("log.committing");
    8000423c:	00004517          	auipc	a0,0x4
    80004240:	43450513          	addi	a0,a0,1076 # 80008670 <syscalls+0x220>
    80004244:	ffffc097          	auipc	ra,0xffffc
    80004248:	2fc080e7          	jalr	764(ra) # 80000540 <panic>
    wakeup(&log);
    8000424c:	0001d497          	auipc	s1,0x1d
    80004250:	91448493          	addi	s1,s1,-1772 # 80020b60 <log>
    80004254:	8526                	mv	a0,s1
    80004256:	ffffe097          	auipc	ra,0xffffe
    8000425a:	e62080e7          	jalr	-414(ra) # 800020b8 <wakeup>
  release(&log.lock);
    8000425e:	8526                	mv	a0,s1
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>
}
    80004268:	70e2                	ld	ra,56(sp)
    8000426a:	7442                	ld	s0,48(sp)
    8000426c:	74a2                	ld	s1,40(sp)
    8000426e:	7902                	ld	s2,32(sp)
    80004270:	69e2                	ld	s3,24(sp)
    80004272:	6a42                	ld	s4,16(sp)
    80004274:	6aa2                	ld	s5,8(sp)
    80004276:	6121                	addi	sp,sp,64
    80004278:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000427a:	0001da97          	auipc	s5,0x1d
    8000427e:	916a8a93          	addi	s5,s5,-1770 # 80020b90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004282:	0001da17          	auipc	s4,0x1d
    80004286:	8dea0a13          	addi	s4,s4,-1826 # 80020b60 <log>
    8000428a:	018a2583          	lw	a1,24(s4)
    8000428e:	012585bb          	addw	a1,a1,s2
    80004292:	2585                	addiw	a1,a1,1
    80004294:	028a2503          	lw	a0,40(s4)
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	cc4080e7          	jalr	-828(ra) # 80002f5c <bread>
    800042a0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042a2:	000aa583          	lw	a1,0(s5)
    800042a6:	028a2503          	lw	a0,40(s4)
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	cb2080e7          	jalr	-846(ra) # 80002f5c <bread>
    800042b2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042b4:	40000613          	li	a2,1024
    800042b8:	05850593          	addi	a1,a0,88
    800042bc:	05848513          	addi	a0,s1,88
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	a6e080e7          	jalr	-1426(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800042c8:	8526                	mv	a0,s1
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	d84080e7          	jalr	-636(ra) # 8000304e <bwrite>
    brelse(from);
    800042d2:	854e                	mv	a0,s3
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	db8080e7          	jalr	-584(ra) # 8000308c <brelse>
    brelse(to);
    800042dc:	8526                	mv	a0,s1
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	dae080e7          	jalr	-594(ra) # 8000308c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e6:	2905                	addiw	s2,s2,1
    800042e8:	0a91                	addi	s5,s5,4
    800042ea:	02ca2783          	lw	a5,44(s4)
    800042ee:	f8f94ee3          	blt	s2,a5,8000428a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	c68080e7          	jalr	-920(ra) # 80003f5a <write_head>
    install_trans(0); // Now install writes to home locations
    800042fa:	4501                	li	a0,0
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	cda080e7          	jalr	-806(ra) # 80003fd6 <install_trans>
    log.lh.n = 0;
    80004304:	0001d797          	auipc	a5,0x1d
    80004308:	8807a423          	sw	zero,-1912(a5) # 80020b8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000430c:	00000097          	auipc	ra,0x0
    80004310:	c4e080e7          	jalr	-946(ra) # 80003f5a <write_head>
    80004314:	bdf5                	j	80004210 <end_op+0x52>

0000000080004316 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004316:	1101                	addi	sp,sp,-32
    80004318:	ec06                	sd	ra,24(sp)
    8000431a:	e822                	sd	s0,16(sp)
    8000431c:	e426                	sd	s1,8(sp)
    8000431e:	e04a                	sd	s2,0(sp)
    80004320:	1000                	addi	s0,sp,32
    80004322:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004324:	0001d917          	auipc	s2,0x1d
    80004328:	83c90913          	addi	s2,s2,-1988 # 80020b60 <log>
    8000432c:	854a                	mv	a0,s2
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	8a8080e7          	jalr	-1880(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004336:	02c92603          	lw	a2,44(s2)
    8000433a:	47f5                	li	a5,29
    8000433c:	06c7c563          	blt	a5,a2,800043a6 <log_write+0x90>
    80004340:	0001d797          	auipc	a5,0x1d
    80004344:	83c7a783          	lw	a5,-1988(a5) # 80020b7c <log+0x1c>
    80004348:	37fd                	addiw	a5,a5,-1
    8000434a:	04f65e63          	bge	a2,a5,800043a6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000434e:	0001d797          	auipc	a5,0x1d
    80004352:	8327a783          	lw	a5,-1998(a5) # 80020b80 <log+0x20>
    80004356:	06f05063          	blez	a5,800043b6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000435a:	4781                	li	a5,0
    8000435c:	06c05563          	blez	a2,800043c6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004360:	44cc                	lw	a1,12(s1)
    80004362:	0001d717          	auipc	a4,0x1d
    80004366:	82e70713          	addi	a4,a4,-2002 # 80020b90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000436a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000436c:	4314                	lw	a3,0(a4)
    8000436e:	04b68c63          	beq	a3,a1,800043c6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004372:	2785                	addiw	a5,a5,1
    80004374:	0711                	addi	a4,a4,4
    80004376:	fef61be3          	bne	a2,a5,8000436c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000437a:	0621                	addi	a2,a2,8
    8000437c:	060a                	slli	a2,a2,0x2
    8000437e:	0001c797          	auipc	a5,0x1c
    80004382:	7e278793          	addi	a5,a5,2018 # 80020b60 <log>
    80004386:	97b2                	add	a5,a5,a2
    80004388:	44d8                	lw	a4,12(s1)
    8000438a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000438c:	8526                	mv	a0,s1
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	d9c080e7          	jalr	-612(ra) # 8000312a <bpin>
    log.lh.n++;
    80004396:	0001c717          	auipc	a4,0x1c
    8000439a:	7ca70713          	addi	a4,a4,1994 # 80020b60 <log>
    8000439e:	575c                	lw	a5,44(a4)
    800043a0:	2785                	addiw	a5,a5,1
    800043a2:	d75c                	sw	a5,44(a4)
    800043a4:	a82d                	j	800043de <log_write+0xc8>
    panic("too big a transaction");
    800043a6:	00004517          	auipc	a0,0x4
    800043aa:	2da50513          	addi	a0,a0,730 # 80008680 <syscalls+0x230>
    800043ae:	ffffc097          	auipc	ra,0xffffc
    800043b2:	192080e7          	jalr	402(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800043b6:	00004517          	auipc	a0,0x4
    800043ba:	2e250513          	addi	a0,a0,738 # 80008698 <syscalls+0x248>
    800043be:	ffffc097          	auipc	ra,0xffffc
    800043c2:	182080e7          	jalr	386(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800043c6:	00878693          	addi	a3,a5,8
    800043ca:	068a                	slli	a3,a3,0x2
    800043cc:	0001c717          	auipc	a4,0x1c
    800043d0:	79470713          	addi	a4,a4,1940 # 80020b60 <log>
    800043d4:	9736                	add	a4,a4,a3
    800043d6:	44d4                	lw	a3,12(s1)
    800043d8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043da:	faf609e3          	beq	a2,a5,8000438c <log_write+0x76>
  }
  release(&log.lock);
    800043de:	0001c517          	auipc	a0,0x1c
    800043e2:	78250513          	addi	a0,a0,1922 # 80020b60 <log>
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	8a4080e7          	jalr	-1884(ra) # 80000c8a <release>
}
    800043ee:	60e2                	ld	ra,24(sp)
    800043f0:	6442                	ld	s0,16(sp)
    800043f2:	64a2                	ld	s1,8(sp)
    800043f4:	6902                	ld	s2,0(sp)
    800043f6:	6105                	addi	sp,sp,32
    800043f8:	8082                	ret

00000000800043fa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043fa:	1101                	addi	sp,sp,-32
    800043fc:	ec06                	sd	ra,24(sp)
    800043fe:	e822                	sd	s0,16(sp)
    80004400:	e426                	sd	s1,8(sp)
    80004402:	e04a                	sd	s2,0(sp)
    80004404:	1000                	addi	s0,sp,32
    80004406:	84aa                	mv	s1,a0
    80004408:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000440a:	00004597          	auipc	a1,0x4
    8000440e:	2ae58593          	addi	a1,a1,686 # 800086b8 <syscalls+0x268>
    80004412:	0521                	addi	a0,a0,8
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	732080e7          	jalr	1842(ra) # 80000b46 <initlock>
  lk->name = name;
    8000441c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004420:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004424:	0204a423          	sw	zero,40(s1)
}
    80004428:	60e2                	ld	ra,24(sp)
    8000442a:	6442                	ld	s0,16(sp)
    8000442c:	64a2                	ld	s1,8(sp)
    8000442e:	6902                	ld	s2,0(sp)
    80004430:	6105                	addi	sp,sp,32
    80004432:	8082                	ret

0000000080004434 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004434:	1101                	addi	sp,sp,-32
    80004436:	ec06                	sd	ra,24(sp)
    80004438:	e822                	sd	s0,16(sp)
    8000443a:	e426                	sd	s1,8(sp)
    8000443c:	e04a                	sd	s2,0(sp)
    8000443e:	1000                	addi	s0,sp,32
    80004440:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004442:	00850913          	addi	s2,a0,8
    80004446:	854a                	mv	a0,s2
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	78e080e7          	jalr	1934(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004450:	409c                	lw	a5,0(s1)
    80004452:	cb89                	beqz	a5,80004464 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004454:	85ca                	mv	a1,s2
    80004456:	8526                	mv	a0,s1
    80004458:	ffffe097          	auipc	ra,0xffffe
    8000445c:	bfc080e7          	jalr	-1028(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004460:	409c                	lw	a5,0(s1)
    80004462:	fbed                	bnez	a5,80004454 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004464:	4785                	li	a5,1
    80004466:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	544080e7          	jalr	1348(ra) # 800019ac <myproc>
    80004470:	591c                	lw	a5,48(a0)
    80004472:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004474:	854a                	mv	a0,s2
    80004476:	ffffd097          	auipc	ra,0xffffd
    8000447a:	814080e7          	jalr	-2028(ra) # 80000c8a <release>
}
    8000447e:	60e2                	ld	ra,24(sp)
    80004480:	6442                	ld	s0,16(sp)
    80004482:	64a2                	ld	s1,8(sp)
    80004484:	6902                	ld	s2,0(sp)
    80004486:	6105                	addi	sp,sp,32
    80004488:	8082                	ret

000000008000448a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000448a:	1101                	addi	sp,sp,-32
    8000448c:	ec06                	sd	ra,24(sp)
    8000448e:	e822                	sd	s0,16(sp)
    80004490:	e426                	sd	s1,8(sp)
    80004492:	e04a                	sd	s2,0(sp)
    80004494:	1000                	addi	s0,sp,32
    80004496:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004498:	00850913          	addi	s2,a0,8
    8000449c:	854a                	mv	a0,s2
    8000449e:	ffffc097          	auipc	ra,0xffffc
    800044a2:	738080e7          	jalr	1848(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044aa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ae:	8526                	mv	a0,s1
    800044b0:	ffffe097          	auipc	ra,0xffffe
    800044b4:	c08080e7          	jalr	-1016(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    800044b8:	854a                	mv	a0,s2
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7d0080e7          	jalr	2000(ra) # 80000c8a <release>
}
    800044c2:	60e2                	ld	ra,24(sp)
    800044c4:	6442                	ld	s0,16(sp)
    800044c6:	64a2                	ld	s1,8(sp)
    800044c8:	6902                	ld	s2,0(sp)
    800044ca:	6105                	addi	sp,sp,32
    800044cc:	8082                	ret

00000000800044ce <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ce:	7179                	addi	sp,sp,-48
    800044d0:	f406                	sd	ra,40(sp)
    800044d2:	f022                	sd	s0,32(sp)
    800044d4:	ec26                	sd	s1,24(sp)
    800044d6:	e84a                	sd	s2,16(sp)
    800044d8:	e44e                	sd	s3,8(sp)
    800044da:	1800                	addi	s0,sp,48
    800044dc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044de:	00850913          	addi	s2,a0,8
    800044e2:	854a                	mv	a0,s2
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	6f2080e7          	jalr	1778(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ec:	409c                	lw	a5,0(s1)
    800044ee:	ef99                	bnez	a5,8000450c <holdingsleep+0x3e>
    800044f0:	4481                	li	s1,0
  release(&lk->lk);
    800044f2:	854a                	mv	a0,s2
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	796080e7          	jalr	1942(ra) # 80000c8a <release>
  return r;
}
    800044fc:	8526                	mv	a0,s1
    800044fe:	70a2                	ld	ra,40(sp)
    80004500:	7402                	ld	s0,32(sp)
    80004502:	64e2                	ld	s1,24(sp)
    80004504:	6942                	ld	s2,16(sp)
    80004506:	69a2                	ld	s3,8(sp)
    80004508:	6145                	addi	sp,sp,48
    8000450a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000450c:	0284a983          	lw	s3,40(s1)
    80004510:	ffffd097          	auipc	ra,0xffffd
    80004514:	49c080e7          	jalr	1180(ra) # 800019ac <myproc>
    80004518:	5904                	lw	s1,48(a0)
    8000451a:	413484b3          	sub	s1,s1,s3
    8000451e:	0014b493          	seqz	s1,s1
    80004522:	bfc1                	j	800044f2 <holdingsleep+0x24>

0000000080004524 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004524:	1141                	addi	sp,sp,-16
    80004526:	e406                	sd	ra,8(sp)
    80004528:	e022                	sd	s0,0(sp)
    8000452a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000452c:	00004597          	auipc	a1,0x4
    80004530:	19c58593          	addi	a1,a1,412 # 800086c8 <syscalls+0x278>
    80004534:	0001c517          	auipc	a0,0x1c
    80004538:	77450513          	addi	a0,a0,1908 # 80020ca8 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	60a080e7          	jalr	1546(ra) # 80000b46 <initlock>
}
    80004544:	60a2                	ld	ra,8(sp)
    80004546:	6402                	ld	s0,0(sp)
    80004548:	0141                	addi	sp,sp,16
    8000454a:	8082                	ret

000000008000454c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000454c:	1101                	addi	sp,sp,-32
    8000454e:	ec06                	sd	ra,24(sp)
    80004550:	e822                	sd	s0,16(sp)
    80004552:	e426                	sd	s1,8(sp)
    80004554:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004556:	0001c517          	auipc	a0,0x1c
    8000455a:	75250513          	addi	a0,a0,1874 # 80020ca8 <ftable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	678080e7          	jalr	1656(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004566:	0001c497          	auipc	s1,0x1c
    8000456a:	75a48493          	addi	s1,s1,1882 # 80020cc0 <ftable+0x18>
    8000456e:	0001d717          	auipc	a4,0x1d
    80004572:	6f270713          	addi	a4,a4,1778 # 80021c60 <disk>
    if(f->ref == 0){
    80004576:	40dc                	lw	a5,4(s1)
    80004578:	cf99                	beqz	a5,80004596 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000457a:	02848493          	addi	s1,s1,40
    8000457e:	fee49ce3          	bne	s1,a4,80004576 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004582:	0001c517          	auipc	a0,0x1c
    80004586:	72650513          	addi	a0,a0,1830 # 80020ca8 <ftable>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	700080e7          	jalr	1792(ra) # 80000c8a <release>
  return 0;
    80004592:	4481                	li	s1,0
    80004594:	a819                	j	800045aa <filealloc+0x5e>
      f->ref = 1;
    80004596:	4785                	li	a5,1
    80004598:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000459a:	0001c517          	auipc	a0,0x1c
    8000459e:	70e50513          	addi	a0,a0,1806 # 80020ca8 <ftable>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	6e8080e7          	jalr	1768(ra) # 80000c8a <release>
}
    800045aa:	8526                	mv	a0,s1
    800045ac:	60e2                	ld	ra,24(sp)
    800045ae:	6442                	ld	s0,16(sp)
    800045b0:	64a2                	ld	s1,8(sp)
    800045b2:	6105                	addi	sp,sp,32
    800045b4:	8082                	ret

00000000800045b6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045b6:	1101                	addi	sp,sp,-32
    800045b8:	ec06                	sd	ra,24(sp)
    800045ba:	e822                	sd	s0,16(sp)
    800045bc:	e426                	sd	s1,8(sp)
    800045be:	1000                	addi	s0,sp,32
    800045c0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045c2:	0001c517          	auipc	a0,0x1c
    800045c6:	6e650513          	addi	a0,a0,1766 # 80020ca8 <ftable>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	60c080e7          	jalr	1548(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800045d2:	40dc                	lw	a5,4(s1)
    800045d4:	02f05263          	blez	a5,800045f8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045d8:	2785                	addiw	a5,a5,1
    800045da:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045dc:	0001c517          	auipc	a0,0x1c
    800045e0:	6cc50513          	addi	a0,a0,1740 # 80020ca8 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6a6080e7          	jalr	1702(ra) # 80000c8a <release>
  return f;
}
    800045ec:	8526                	mv	a0,s1
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret
    panic("filedup");
    800045f8:	00004517          	auipc	a0,0x4
    800045fc:	0d850513          	addi	a0,a0,216 # 800086d0 <syscalls+0x280>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	f40080e7          	jalr	-192(ra) # 80000540 <panic>

0000000080004608 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004608:	7139                	addi	sp,sp,-64
    8000460a:	fc06                	sd	ra,56(sp)
    8000460c:	f822                	sd	s0,48(sp)
    8000460e:	f426                	sd	s1,40(sp)
    80004610:	f04a                	sd	s2,32(sp)
    80004612:	ec4e                	sd	s3,24(sp)
    80004614:	e852                	sd	s4,16(sp)
    80004616:	e456                	sd	s5,8(sp)
    80004618:	0080                	addi	s0,sp,64
    8000461a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000461c:	0001c517          	auipc	a0,0x1c
    80004620:	68c50513          	addi	a0,a0,1676 # 80020ca8 <ftable>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	5b2080e7          	jalr	1458(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000462c:	40dc                	lw	a5,4(s1)
    8000462e:	06f05163          	blez	a5,80004690 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004632:	37fd                	addiw	a5,a5,-1
    80004634:	0007871b          	sext.w	a4,a5
    80004638:	c0dc                	sw	a5,4(s1)
    8000463a:	06e04363          	bgtz	a4,800046a0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000463e:	0004a903          	lw	s2,0(s1)
    80004642:	0094ca83          	lbu	s5,9(s1)
    80004646:	0104ba03          	ld	s4,16(s1)
    8000464a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000464e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004652:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004656:	0001c517          	auipc	a0,0x1c
    8000465a:	65250513          	addi	a0,a0,1618 # 80020ca8 <ftable>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	62c080e7          	jalr	1580(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004666:	4785                	li	a5,1
    80004668:	04f90d63          	beq	s2,a5,800046c2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000466c:	3979                	addiw	s2,s2,-2
    8000466e:	4785                	li	a5,1
    80004670:	0527e063          	bltu	a5,s2,800046b0 <fileclose+0xa8>
    begin_op();
    80004674:	00000097          	auipc	ra,0x0
    80004678:	acc080e7          	jalr	-1332(ra) # 80004140 <begin_op>
    iput(ff.ip);
    8000467c:	854e                	mv	a0,s3
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	2b0080e7          	jalr	688(ra) # 8000392e <iput>
    end_op();
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	b38080e7          	jalr	-1224(ra) # 800041be <end_op>
    8000468e:	a00d                	j	800046b0 <fileclose+0xa8>
    panic("fileclose");
    80004690:	00004517          	auipc	a0,0x4
    80004694:	04850513          	addi	a0,a0,72 # 800086d8 <syscalls+0x288>
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	ea8080e7          	jalr	-344(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046a0:	0001c517          	auipc	a0,0x1c
    800046a4:	60850513          	addi	a0,a0,1544 # 80020ca8 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	5e2080e7          	jalr	1506(ra) # 80000c8a <release>
  }
}
    800046b0:	70e2                	ld	ra,56(sp)
    800046b2:	7442                	ld	s0,48(sp)
    800046b4:	74a2                	ld	s1,40(sp)
    800046b6:	7902                	ld	s2,32(sp)
    800046b8:	69e2                	ld	s3,24(sp)
    800046ba:	6a42                	ld	s4,16(sp)
    800046bc:	6aa2                	ld	s5,8(sp)
    800046be:	6121                	addi	sp,sp,64
    800046c0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046c2:	85d6                	mv	a1,s5
    800046c4:	8552                	mv	a0,s4
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	34c080e7          	jalr	844(ra) # 80004a12 <pipeclose>
    800046ce:	b7cd                	j	800046b0 <fileclose+0xa8>

00000000800046d0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046d0:	715d                	addi	sp,sp,-80
    800046d2:	e486                	sd	ra,72(sp)
    800046d4:	e0a2                	sd	s0,64(sp)
    800046d6:	fc26                	sd	s1,56(sp)
    800046d8:	f84a                	sd	s2,48(sp)
    800046da:	f44e                	sd	s3,40(sp)
    800046dc:	0880                	addi	s0,sp,80
    800046de:	84aa                	mv	s1,a0
    800046e0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046e2:	ffffd097          	auipc	ra,0xffffd
    800046e6:	2ca080e7          	jalr	714(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ea:	409c                	lw	a5,0(s1)
    800046ec:	37f9                	addiw	a5,a5,-2
    800046ee:	4705                	li	a4,1
    800046f0:	04f76763          	bltu	a4,a5,8000473e <filestat+0x6e>
    800046f4:	892a                	mv	s2,a0
    ilock(f->ip);
    800046f6:	6c88                	ld	a0,24(s1)
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	07c080e7          	jalr	124(ra) # 80003774 <ilock>
    stati(f->ip, &st);
    80004700:	fb840593          	addi	a1,s0,-72
    80004704:	6c88                	ld	a0,24(s1)
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	2f8080e7          	jalr	760(ra) # 800039fe <stati>
    iunlock(f->ip);
    8000470e:	6c88                	ld	a0,24(s1)
    80004710:	fffff097          	auipc	ra,0xfffff
    80004714:	126080e7          	jalr	294(ra) # 80003836 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004718:	46e1                	li	a3,24
    8000471a:	fb840613          	addi	a2,s0,-72
    8000471e:	85ce                	mv	a1,s3
    80004720:	05093503          	ld	a0,80(s2)
    80004724:	ffffd097          	auipc	ra,0xffffd
    80004728:	f48080e7          	jalr	-184(ra) # 8000166c <copyout>
    8000472c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004730:	60a6                	ld	ra,72(sp)
    80004732:	6406                	ld	s0,64(sp)
    80004734:	74e2                	ld	s1,56(sp)
    80004736:	7942                	ld	s2,48(sp)
    80004738:	79a2                	ld	s3,40(sp)
    8000473a:	6161                	addi	sp,sp,80
    8000473c:	8082                	ret
  return -1;
    8000473e:	557d                	li	a0,-1
    80004740:	bfc5                	j	80004730 <filestat+0x60>

0000000080004742 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004742:	7179                	addi	sp,sp,-48
    80004744:	f406                	sd	ra,40(sp)
    80004746:	f022                	sd	s0,32(sp)
    80004748:	ec26                	sd	s1,24(sp)
    8000474a:	e84a                	sd	s2,16(sp)
    8000474c:	e44e                	sd	s3,8(sp)
    8000474e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004750:	00854783          	lbu	a5,8(a0)
    80004754:	c3d5                	beqz	a5,800047f8 <fileread+0xb6>
    80004756:	84aa                	mv	s1,a0
    80004758:	89ae                	mv	s3,a1
    8000475a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000475c:	411c                	lw	a5,0(a0)
    8000475e:	4705                	li	a4,1
    80004760:	04e78963          	beq	a5,a4,800047b2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004764:	470d                	li	a4,3
    80004766:	04e78d63          	beq	a5,a4,800047c0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000476a:	4709                	li	a4,2
    8000476c:	06e79e63          	bne	a5,a4,800047e8 <fileread+0xa6>
    ilock(f->ip);
    80004770:	6d08                	ld	a0,24(a0)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	002080e7          	jalr	2(ra) # 80003774 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000477a:	874a                	mv	a4,s2
    8000477c:	5094                	lw	a3,32(s1)
    8000477e:	864e                	mv	a2,s3
    80004780:	4585                	li	a1,1
    80004782:	6c88                	ld	a0,24(s1)
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	2a4080e7          	jalr	676(ra) # 80003a28 <readi>
    8000478c:	892a                	mv	s2,a0
    8000478e:	00a05563          	blez	a0,80004798 <fileread+0x56>
      f->off += r;
    80004792:	509c                	lw	a5,32(s1)
    80004794:	9fa9                	addw	a5,a5,a0
    80004796:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004798:	6c88                	ld	a0,24(s1)
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	09c080e7          	jalr	156(ra) # 80003836 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047a2:	854a                	mv	a0,s2
    800047a4:	70a2                	ld	ra,40(sp)
    800047a6:	7402                	ld	s0,32(sp)
    800047a8:	64e2                	ld	s1,24(sp)
    800047aa:	6942                	ld	s2,16(sp)
    800047ac:	69a2                	ld	s3,8(sp)
    800047ae:	6145                	addi	sp,sp,48
    800047b0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047b2:	6908                	ld	a0,16(a0)
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	3c6080e7          	jalr	966(ra) # 80004b7a <piperead>
    800047bc:	892a                	mv	s2,a0
    800047be:	b7d5                	j	800047a2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047c0:	02451783          	lh	a5,36(a0)
    800047c4:	03079693          	slli	a3,a5,0x30
    800047c8:	92c1                	srli	a3,a3,0x30
    800047ca:	4725                	li	a4,9
    800047cc:	02d76863          	bltu	a4,a3,800047fc <fileread+0xba>
    800047d0:	0792                	slli	a5,a5,0x4
    800047d2:	0001c717          	auipc	a4,0x1c
    800047d6:	43670713          	addi	a4,a4,1078 # 80020c08 <devsw>
    800047da:	97ba                	add	a5,a5,a4
    800047dc:	639c                	ld	a5,0(a5)
    800047de:	c38d                	beqz	a5,80004800 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047e0:	4505                	li	a0,1
    800047e2:	9782                	jalr	a5
    800047e4:	892a                	mv	s2,a0
    800047e6:	bf75                	j	800047a2 <fileread+0x60>
    panic("fileread");
    800047e8:	00004517          	auipc	a0,0x4
    800047ec:	f0050513          	addi	a0,a0,-256 # 800086e8 <syscalls+0x298>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	d50080e7          	jalr	-688(ra) # 80000540 <panic>
    return -1;
    800047f8:	597d                	li	s2,-1
    800047fa:	b765                	j	800047a2 <fileread+0x60>
      return -1;
    800047fc:	597d                	li	s2,-1
    800047fe:	b755                	j	800047a2 <fileread+0x60>
    80004800:	597d                	li	s2,-1
    80004802:	b745                	j	800047a2 <fileread+0x60>

0000000080004804 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004804:	715d                	addi	sp,sp,-80
    80004806:	e486                	sd	ra,72(sp)
    80004808:	e0a2                	sd	s0,64(sp)
    8000480a:	fc26                	sd	s1,56(sp)
    8000480c:	f84a                	sd	s2,48(sp)
    8000480e:	f44e                	sd	s3,40(sp)
    80004810:	f052                	sd	s4,32(sp)
    80004812:	ec56                	sd	s5,24(sp)
    80004814:	e85a                	sd	s6,16(sp)
    80004816:	e45e                	sd	s7,8(sp)
    80004818:	e062                	sd	s8,0(sp)
    8000481a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000481c:	00954783          	lbu	a5,9(a0)
    80004820:	10078663          	beqz	a5,8000492c <filewrite+0x128>
    80004824:	892a                	mv	s2,a0
    80004826:	8b2e                	mv	s6,a1
    80004828:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000482a:	411c                	lw	a5,0(a0)
    8000482c:	4705                	li	a4,1
    8000482e:	02e78263          	beq	a5,a4,80004852 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004832:	470d                	li	a4,3
    80004834:	02e78663          	beq	a5,a4,80004860 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004838:	4709                	li	a4,2
    8000483a:	0ee79163          	bne	a5,a4,8000491c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000483e:	0ac05d63          	blez	a2,800048f8 <filewrite+0xf4>
    int i = 0;
    80004842:	4981                	li	s3,0
    80004844:	6b85                	lui	s7,0x1
    80004846:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000484a:	6c05                	lui	s8,0x1
    8000484c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004850:	a861                	j	800048e8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004852:	6908                	ld	a0,16(a0)
    80004854:	00000097          	auipc	ra,0x0
    80004858:	22e080e7          	jalr	558(ra) # 80004a82 <pipewrite>
    8000485c:	8a2a                	mv	s4,a0
    8000485e:	a045                	j	800048fe <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004860:	02451783          	lh	a5,36(a0)
    80004864:	03079693          	slli	a3,a5,0x30
    80004868:	92c1                	srli	a3,a3,0x30
    8000486a:	4725                	li	a4,9
    8000486c:	0cd76263          	bltu	a4,a3,80004930 <filewrite+0x12c>
    80004870:	0792                	slli	a5,a5,0x4
    80004872:	0001c717          	auipc	a4,0x1c
    80004876:	39670713          	addi	a4,a4,918 # 80020c08 <devsw>
    8000487a:	97ba                	add	a5,a5,a4
    8000487c:	679c                	ld	a5,8(a5)
    8000487e:	cbdd                	beqz	a5,80004934 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004880:	4505                	li	a0,1
    80004882:	9782                	jalr	a5
    80004884:	8a2a                	mv	s4,a0
    80004886:	a8a5                	j	800048fe <filewrite+0xfa>
    80004888:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	8b4080e7          	jalr	-1868(ra) # 80004140 <begin_op>
      ilock(f->ip);
    80004894:	01893503          	ld	a0,24(s2)
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	edc080e7          	jalr	-292(ra) # 80003774 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048a0:	8756                	mv	a4,s5
    800048a2:	02092683          	lw	a3,32(s2)
    800048a6:	01698633          	add	a2,s3,s6
    800048aa:	4585                	li	a1,1
    800048ac:	01893503          	ld	a0,24(s2)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	270080e7          	jalr	624(ra) # 80003b20 <writei>
    800048b8:	84aa                	mv	s1,a0
    800048ba:	00a05763          	blez	a0,800048c8 <filewrite+0xc4>
        f->off += r;
    800048be:	02092783          	lw	a5,32(s2)
    800048c2:	9fa9                	addw	a5,a5,a0
    800048c4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048c8:	01893503          	ld	a0,24(s2)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	f6a080e7          	jalr	-150(ra) # 80003836 <iunlock>
      end_op();
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	8ea080e7          	jalr	-1814(ra) # 800041be <end_op>

      if(r != n1){
    800048dc:	009a9f63          	bne	s5,s1,800048fa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048e0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048e4:	0149db63          	bge	s3,s4,800048fa <filewrite+0xf6>
      int n1 = n - i;
    800048e8:	413a04bb          	subw	s1,s4,s3
    800048ec:	0004879b          	sext.w	a5,s1
    800048f0:	f8fbdce3          	bge	s7,a5,80004888 <filewrite+0x84>
    800048f4:	84e2                	mv	s1,s8
    800048f6:	bf49                	j	80004888 <filewrite+0x84>
    int i = 0;
    800048f8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048fa:	013a1f63          	bne	s4,s3,80004918 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048fe:	8552                	mv	a0,s4
    80004900:	60a6                	ld	ra,72(sp)
    80004902:	6406                	ld	s0,64(sp)
    80004904:	74e2                	ld	s1,56(sp)
    80004906:	7942                	ld	s2,48(sp)
    80004908:	79a2                	ld	s3,40(sp)
    8000490a:	7a02                	ld	s4,32(sp)
    8000490c:	6ae2                	ld	s5,24(sp)
    8000490e:	6b42                	ld	s6,16(sp)
    80004910:	6ba2                	ld	s7,8(sp)
    80004912:	6c02                	ld	s8,0(sp)
    80004914:	6161                	addi	sp,sp,80
    80004916:	8082                	ret
    ret = (i == n ? n : -1);
    80004918:	5a7d                	li	s4,-1
    8000491a:	b7d5                	j	800048fe <filewrite+0xfa>
    panic("filewrite");
    8000491c:	00004517          	auipc	a0,0x4
    80004920:	ddc50513          	addi	a0,a0,-548 # 800086f8 <syscalls+0x2a8>
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	c1c080e7          	jalr	-996(ra) # 80000540 <panic>
    return -1;
    8000492c:	5a7d                	li	s4,-1
    8000492e:	bfc1                	j	800048fe <filewrite+0xfa>
      return -1;
    80004930:	5a7d                	li	s4,-1
    80004932:	b7f1                	j	800048fe <filewrite+0xfa>
    80004934:	5a7d                	li	s4,-1
    80004936:	b7e1                	j	800048fe <filewrite+0xfa>

0000000080004938 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004938:	7179                	addi	sp,sp,-48
    8000493a:	f406                	sd	ra,40(sp)
    8000493c:	f022                	sd	s0,32(sp)
    8000493e:	ec26                	sd	s1,24(sp)
    80004940:	e84a                	sd	s2,16(sp)
    80004942:	e44e                	sd	s3,8(sp)
    80004944:	e052                	sd	s4,0(sp)
    80004946:	1800                	addi	s0,sp,48
    80004948:	84aa                	mv	s1,a0
    8000494a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000494c:	0005b023          	sd	zero,0(a1)
    80004950:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004954:	00000097          	auipc	ra,0x0
    80004958:	bf8080e7          	jalr	-1032(ra) # 8000454c <filealloc>
    8000495c:	e088                	sd	a0,0(s1)
    8000495e:	c551                	beqz	a0,800049ea <pipealloc+0xb2>
    80004960:	00000097          	auipc	ra,0x0
    80004964:	bec080e7          	jalr	-1044(ra) # 8000454c <filealloc>
    80004968:	00aa3023          	sd	a0,0(s4)
    8000496c:	c92d                	beqz	a0,800049de <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	178080e7          	jalr	376(ra) # 80000ae6 <kalloc>
    80004976:	892a                	mv	s2,a0
    80004978:	c125                	beqz	a0,800049d8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000497a:	4985                	li	s3,1
    8000497c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004980:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004984:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004988:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000498c:	00004597          	auipc	a1,0x4
    80004990:	d7c58593          	addi	a1,a1,-644 # 80008708 <syscalls+0x2b8>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	1b2080e7          	jalr	434(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    8000499c:	609c                	ld	a5,0(s1)
    8000499e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049a2:	609c                	ld	a5,0(s1)
    800049a4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049a8:	609c                	ld	a5,0(s1)
    800049aa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ae:	609c                	ld	a5,0(s1)
    800049b0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049b4:	000a3783          	ld	a5,0(s4)
    800049b8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049bc:	000a3783          	ld	a5,0(s4)
    800049c0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049c4:	000a3783          	ld	a5,0(s4)
    800049c8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049cc:	000a3783          	ld	a5,0(s4)
    800049d0:	0127b823          	sd	s2,16(a5)
  return 0;
    800049d4:	4501                	li	a0,0
    800049d6:	a025                	j	800049fe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049d8:	6088                	ld	a0,0(s1)
    800049da:	e501                	bnez	a0,800049e2 <pipealloc+0xaa>
    800049dc:	a039                	j	800049ea <pipealloc+0xb2>
    800049de:	6088                	ld	a0,0(s1)
    800049e0:	c51d                	beqz	a0,80004a0e <pipealloc+0xd6>
    fileclose(*f0);
    800049e2:	00000097          	auipc	ra,0x0
    800049e6:	c26080e7          	jalr	-986(ra) # 80004608 <fileclose>
  if(*f1)
    800049ea:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049ee:	557d                	li	a0,-1
  if(*f1)
    800049f0:	c799                	beqz	a5,800049fe <pipealloc+0xc6>
    fileclose(*f1);
    800049f2:	853e                	mv	a0,a5
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	c14080e7          	jalr	-1004(ra) # 80004608 <fileclose>
  return -1;
    800049fc:	557d                	li	a0,-1
}
    800049fe:	70a2                	ld	ra,40(sp)
    80004a00:	7402                	ld	s0,32(sp)
    80004a02:	64e2                	ld	s1,24(sp)
    80004a04:	6942                	ld	s2,16(sp)
    80004a06:	69a2                	ld	s3,8(sp)
    80004a08:	6a02                	ld	s4,0(sp)
    80004a0a:	6145                	addi	sp,sp,48
    80004a0c:	8082                	ret
  return -1;
    80004a0e:	557d                	li	a0,-1
    80004a10:	b7fd                	j	800049fe <pipealloc+0xc6>

0000000080004a12 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a12:	1101                	addi	sp,sp,-32
    80004a14:	ec06                	sd	ra,24(sp)
    80004a16:	e822                	sd	s0,16(sp)
    80004a18:	e426                	sd	s1,8(sp)
    80004a1a:	e04a                	sd	s2,0(sp)
    80004a1c:	1000                	addi	s0,sp,32
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	1b4080e7          	jalr	436(ra) # 80000bd6 <acquire>
  if(writable){
    80004a2a:	02090d63          	beqz	s2,80004a64 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a2e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a32:	21848513          	addi	a0,s1,536
    80004a36:	ffffd097          	auipc	ra,0xffffd
    80004a3a:	682080e7          	jalr	1666(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a3e:	2204b783          	ld	a5,544(s1)
    80004a42:	eb95                	bnez	a5,80004a76 <pipeclose+0x64>
    release(&pi->lock);
    80004a44:	8526                	mv	a0,s1
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	244080e7          	jalr	580(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	f98080e7          	jalr	-104(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a58:	60e2                	ld	ra,24(sp)
    80004a5a:	6442                	ld	s0,16(sp)
    80004a5c:	64a2                	ld	s1,8(sp)
    80004a5e:	6902                	ld	s2,0(sp)
    80004a60:	6105                	addi	sp,sp,32
    80004a62:	8082                	ret
    pi->readopen = 0;
    80004a64:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a68:	21c48513          	addi	a0,s1,540
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	64c080e7          	jalr	1612(ra) # 800020b8 <wakeup>
    80004a74:	b7e9                	j	80004a3e <pipeclose+0x2c>
    release(&pi->lock);
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	212080e7          	jalr	530(ra) # 80000c8a <release>
}
    80004a80:	bfe1                	j	80004a58 <pipeclose+0x46>

0000000080004a82 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a82:	711d                	addi	sp,sp,-96
    80004a84:	ec86                	sd	ra,88(sp)
    80004a86:	e8a2                	sd	s0,80(sp)
    80004a88:	e4a6                	sd	s1,72(sp)
    80004a8a:	e0ca                	sd	s2,64(sp)
    80004a8c:	fc4e                	sd	s3,56(sp)
    80004a8e:	f852                	sd	s4,48(sp)
    80004a90:	f456                	sd	s5,40(sp)
    80004a92:	f05a                	sd	s6,32(sp)
    80004a94:	ec5e                	sd	s7,24(sp)
    80004a96:	e862                	sd	s8,16(sp)
    80004a98:	1080                	addi	s0,sp,96
    80004a9a:	84aa                	mv	s1,a0
    80004a9c:	8aae                	mv	s5,a1
    80004a9e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	f0c080e7          	jalr	-244(ra) # 800019ac <myproc>
    80004aa8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	12a080e7          	jalr	298(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ab4:	0b405663          	blez	s4,80004b60 <pipewrite+0xde>
  int i = 0;
    80004ab8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aba:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004abc:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ac0:	21c48b93          	addi	s7,s1,540
    80004ac4:	a089                	j	80004b06 <pipewrite+0x84>
      release(&pi->lock);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	1c2080e7          	jalr	450(ra) # 80000c8a <release>
      return -1;
    80004ad0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ad2:	854a                	mv	a0,s2
    80004ad4:	60e6                	ld	ra,88(sp)
    80004ad6:	6446                	ld	s0,80(sp)
    80004ad8:	64a6                	ld	s1,72(sp)
    80004ada:	6906                	ld	s2,64(sp)
    80004adc:	79e2                	ld	s3,56(sp)
    80004ade:	7a42                	ld	s4,48(sp)
    80004ae0:	7aa2                	ld	s5,40(sp)
    80004ae2:	7b02                	ld	s6,32(sp)
    80004ae4:	6be2                	ld	s7,24(sp)
    80004ae6:	6c42                	ld	s8,16(sp)
    80004ae8:	6125                	addi	sp,sp,96
    80004aea:	8082                	ret
      wakeup(&pi->nread);
    80004aec:	8562                	mv	a0,s8
    80004aee:	ffffd097          	auipc	ra,0xffffd
    80004af2:	5ca080e7          	jalr	1482(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004af6:	85a6                	mv	a1,s1
    80004af8:	855e                	mv	a0,s7
    80004afa:	ffffd097          	auipc	ra,0xffffd
    80004afe:	55a080e7          	jalr	1370(ra) # 80002054 <sleep>
  while(i < n){
    80004b02:	07495063          	bge	s2,s4,80004b62 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b06:	2204a783          	lw	a5,544(s1)
    80004b0a:	dfd5                	beqz	a5,80004ac6 <pipewrite+0x44>
    80004b0c:	854e                	mv	a0,s3
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	7ee080e7          	jalr	2030(ra) # 800022fc <killed>
    80004b16:	f945                	bnez	a0,80004ac6 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b18:	2184a783          	lw	a5,536(s1)
    80004b1c:	21c4a703          	lw	a4,540(s1)
    80004b20:	2007879b          	addiw	a5,a5,512
    80004b24:	fcf704e3          	beq	a4,a5,80004aec <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b28:	4685                	li	a3,1
    80004b2a:	01590633          	add	a2,s2,s5
    80004b2e:	faf40593          	addi	a1,s0,-81
    80004b32:	0509b503          	ld	a0,80(s3)
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	bc2080e7          	jalr	-1086(ra) # 800016f8 <copyin>
    80004b3e:	03650263          	beq	a0,s6,80004b62 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b42:	21c4a783          	lw	a5,540(s1)
    80004b46:	0017871b          	addiw	a4,a5,1
    80004b4a:	20e4ae23          	sw	a4,540(s1)
    80004b4e:	1ff7f793          	andi	a5,a5,511
    80004b52:	97a6                	add	a5,a5,s1
    80004b54:	faf44703          	lbu	a4,-81(s0)
    80004b58:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b5c:	2905                	addiw	s2,s2,1
    80004b5e:	b755                	j	80004b02 <pipewrite+0x80>
  int i = 0;
    80004b60:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b62:	21848513          	addi	a0,s1,536
    80004b66:	ffffd097          	auipc	ra,0xffffd
    80004b6a:	552080e7          	jalr	1362(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	11a080e7          	jalr	282(ra) # 80000c8a <release>
  return i;
    80004b78:	bfa9                	j	80004ad2 <pipewrite+0x50>

0000000080004b7a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b7a:	715d                	addi	sp,sp,-80
    80004b7c:	e486                	sd	ra,72(sp)
    80004b7e:	e0a2                	sd	s0,64(sp)
    80004b80:	fc26                	sd	s1,56(sp)
    80004b82:	f84a                	sd	s2,48(sp)
    80004b84:	f44e                	sd	s3,40(sp)
    80004b86:	f052                	sd	s4,32(sp)
    80004b88:	ec56                	sd	s5,24(sp)
    80004b8a:	e85a                	sd	s6,16(sp)
    80004b8c:	0880                	addi	s0,sp,80
    80004b8e:	84aa                	mv	s1,a0
    80004b90:	892e                	mv	s2,a1
    80004b92:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b94:	ffffd097          	auipc	ra,0xffffd
    80004b98:	e18080e7          	jalr	-488(ra) # 800019ac <myproc>
    80004b9c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	036080e7          	jalr	54(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba8:	2184a703          	lw	a4,536(s1)
    80004bac:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bb0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb4:	02f71763          	bne	a4,a5,80004be2 <piperead+0x68>
    80004bb8:	2244a783          	lw	a5,548(s1)
    80004bbc:	c39d                	beqz	a5,80004be2 <piperead+0x68>
    if(killed(pr)){
    80004bbe:	8552                	mv	a0,s4
    80004bc0:	ffffd097          	auipc	ra,0xffffd
    80004bc4:	73c080e7          	jalr	1852(ra) # 800022fc <killed>
    80004bc8:	e949                	bnez	a0,80004c5a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bca:	85a6                	mv	a1,s1
    80004bcc:	854e                	mv	a0,s3
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	486080e7          	jalr	1158(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd6:	2184a703          	lw	a4,536(s1)
    80004bda:	21c4a783          	lw	a5,540(s1)
    80004bde:	fcf70de3          	beq	a4,a5,80004bb8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004be2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004be6:	05505463          	blez	s5,80004c2e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004bea:	2184a783          	lw	a5,536(s1)
    80004bee:	21c4a703          	lw	a4,540(s1)
    80004bf2:	02f70e63          	beq	a4,a5,80004c2e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bf6:	0017871b          	addiw	a4,a5,1
    80004bfa:	20e4ac23          	sw	a4,536(s1)
    80004bfe:	1ff7f793          	andi	a5,a5,511
    80004c02:	97a6                	add	a5,a5,s1
    80004c04:	0187c783          	lbu	a5,24(a5)
    80004c08:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c0c:	4685                	li	a3,1
    80004c0e:	fbf40613          	addi	a2,s0,-65
    80004c12:	85ca                	mv	a1,s2
    80004c14:	050a3503          	ld	a0,80(s4)
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	a54080e7          	jalr	-1452(ra) # 8000166c <copyout>
    80004c20:	01650763          	beq	a0,s6,80004c2e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c24:	2985                	addiw	s3,s3,1
    80004c26:	0905                	addi	s2,s2,1
    80004c28:	fd3a91e3          	bne	s5,s3,80004bea <piperead+0x70>
    80004c2c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c2e:	21c48513          	addi	a0,s1,540
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	486080e7          	jalr	1158(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	04e080e7          	jalr	78(ra) # 80000c8a <release>
  return i;
}
    80004c44:	854e                	mv	a0,s3
    80004c46:	60a6                	ld	ra,72(sp)
    80004c48:	6406                	ld	s0,64(sp)
    80004c4a:	74e2                	ld	s1,56(sp)
    80004c4c:	7942                	ld	s2,48(sp)
    80004c4e:	79a2                	ld	s3,40(sp)
    80004c50:	7a02                	ld	s4,32(sp)
    80004c52:	6ae2                	ld	s5,24(sp)
    80004c54:	6b42                	ld	s6,16(sp)
    80004c56:	6161                	addi	sp,sp,80
    80004c58:	8082                	ret
      release(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	02e080e7          	jalr	46(ra) # 80000c8a <release>
      return -1;
    80004c64:	59fd                	li	s3,-1
    80004c66:	bff9                	j	80004c44 <piperead+0xca>

0000000080004c68 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c68:	1141                	addi	sp,sp,-16
    80004c6a:	e422                	sd	s0,8(sp)
    80004c6c:	0800                	addi	s0,sp,16
    80004c6e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c70:	8905                	andi	a0,a0,1
    80004c72:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c74:	8b89                	andi	a5,a5,2
    80004c76:	c399                	beqz	a5,80004c7c <flags2perm+0x14>
      perm |= PTE_W;
    80004c78:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c7c:	6422                	ld	s0,8(sp)
    80004c7e:	0141                	addi	sp,sp,16
    80004c80:	8082                	ret

0000000080004c82 <exec>:

int
exec(char *path, char **argv)
{
    80004c82:	de010113          	addi	sp,sp,-544
    80004c86:	20113c23          	sd	ra,536(sp)
    80004c8a:	20813823          	sd	s0,528(sp)
    80004c8e:	20913423          	sd	s1,520(sp)
    80004c92:	21213023          	sd	s2,512(sp)
    80004c96:	ffce                	sd	s3,504(sp)
    80004c98:	fbd2                	sd	s4,496(sp)
    80004c9a:	f7d6                	sd	s5,488(sp)
    80004c9c:	f3da                	sd	s6,480(sp)
    80004c9e:	efde                	sd	s7,472(sp)
    80004ca0:	ebe2                	sd	s8,464(sp)
    80004ca2:	e7e6                	sd	s9,456(sp)
    80004ca4:	e3ea                	sd	s10,448(sp)
    80004ca6:	ff6e                	sd	s11,440(sp)
    80004ca8:	1400                	addi	s0,sp,544
    80004caa:	892a                	mv	s2,a0
    80004cac:	dea43423          	sd	a0,-536(s0)
    80004cb0:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	cf8080e7          	jalr	-776(ra) # 800019ac <myproc>
    80004cbc:	84aa                	mv	s1,a0

  begin_op();
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	482080e7          	jalr	1154(ra) # 80004140 <begin_op>

  if((ip = namei(path)) == 0){
    80004cc6:	854a                	mv	a0,s2
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	258080e7          	jalr	600(ra) # 80003f20 <namei>
    80004cd0:	c93d                	beqz	a0,80004d46 <exec+0xc4>
    80004cd2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	aa0080e7          	jalr	-1376(ra) # 80003774 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cdc:	04000713          	li	a4,64
    80004ce0:	4681                	li	a3,0
    80004ce2:	e5040613          	addi	a2,s0,-432
    80004ce6:	4581                	li	a1,0
    80004ce8:	8556                	mv	a0,s5
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	d3e080e7          	jalr	-706(ra) # 80003a28 <readi>
    80004cf2:	04000793          	li	a5,64
    80004cf6:	00f51a63          	bne	a0,a5,80004d0a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cfa:	e5042703          	lw	a4,-432(s0)
    80004cfe:	464c47b7          	lui	a5,0x464c4
    80004d02:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d06:	04f70663          	beq	a4,a5,80004d52 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d0a:	8556                	mv	a0,s5
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	cca080e7          	jalr	-822(ra) # 800039d6 <iunlockput>
    end_op();
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	4aa080e7          	jalr	1194(ra) # 800041be <end_op>
  }
  return -1;
    80004d1c:	557d                	li	a0,-1
}
    80004d1e:	21813083          	ld	ra,536(sp)
    80004d22:	21013403          	ld	s0,528(sp)
    80004d26:	20813483          	ld	s1,520(sp)
    80004d2a:	20013903          	ld	s2,512(sp)
    80004d2e:	79fe                	ld	s3,504(sp)
    80004d30:	7a5e                	ld	s4,496(sp)
    80004d32:	7abe                	ld	s5,488(sp)
    80004d34:	7b1e                	ld	s6,480(sp)
    80004d36:	6bfe                	ld	s7,472(sp)
    80004d38:	6c5e                	ld	s8,464(sp)
    80004d3a:	6cbe                	ld	s9,456(sp)
    80004d3c:	6d1e                	ld	s10,448(sp)
    80004d3e:	7dfa                	ld	s11,440(sp)
    80004d40:	22010113          	addi	sp,sp,544
    80004d44:	8082                	ret
    end_op();
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	478080e7          	jalr	1144(ra) # 800041be <end_op>
    return -1;
    80004d4e:	557d                	li	a0,-1
    80004d50:	b7f9                	j	80004d1e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	d1c080e7          	jalr	-740(ra) # 80001a70 <proc_pagetable>
    80004d5c:	8b2a                	mv	s6,a0
    80004d5e:	d555                	beqz	a0,80004d0a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d60:	e7042783          	lw	a5,-400(s0)
    80004d64:	e8845703          	lhu	a4,-376(s0)
    80004d68:	c735                	beqz	a4,80004dd4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d6a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d6c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d70:	6a05                	lui	s4,0x1
    80004d72:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d76:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d7a:	6d85                	lui	s11,0x1
    80004d7c:	7d7d                	lui	s10,0xfffff
    80004d7e:	ac3d                	j	80004fbc <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d80:	00004517          	auipc	a0,0x4
    80004d84:	99050513          	addi	a0,a0,-1648 # 80008710 <syscalls+0x2c0>
    80004d88:	ffffb097          	auipc	ra,0xffffb
    80004d8c:	7b8080e7          	jalr	1976(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d90:	874a                	mv	a4,s2
    80004d92:	009c86bb          	addw	a3,s9,s1
    80004d96:	4581                	li	a1,0
    80004d98:	8556                	mv	a0,s5
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	c8e080e7          	jalr	-882(ra) # 80003a28 <readi>
    80004da2:	2501                	sext.w	a0,a0
    80004da4:	1aa91963          	bne	s2,a0,80004f56 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004da8:	009d84bb          	addw	s1,s11,s1
    80004dac:	013d09bb          	addw	s3,s10,s3
    80004db0:	1f74f663          	bgeu	s1,s7,80004f9c <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004db4:	02049593          	slli	a1,s1,0x20
    80004db8:	9181                	srli	a1,a1,0x20
    80004dba:	95e2                	add	a1,a1,s8
    80004dbc:	855a                	mv	a0,s6
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	29e080e7          	jalr	670(ra) # 8000105c <walkaddr>
    80004dc6:	862a                	mv	a2,a0
    if(pa == 0)
    80004dc8:	dd45                	beqz	a0,80004d80 <exec+0xfe>
      n = PGSIZE;
    80004dca:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dcc:	fd49f2e3          	bgeu	s3,s4,80004d90 <exec+0x10e>
      n = sz - i;
    80004dd0:	894e                	mv	s2,s3
    80004dd2:	bf7d                	j	80004d90 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dd4:	4901                	li	s2,0
  iunlockput(ip);
    80004dd6:	8556                	mv	a0,s5
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	bfe080e7          	jalr	-1026(ra) # 800039d6 <iunlockput>
  end_op();
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	3de080e7          	jalr	990(ra) # 800041be <end_op>
  p = myproc();
    80004de8:	ffffd097          	auipc	ra,0xffffd
    80004dec:	bc4080e7          	jalr	-1084(ra) # 800019ac <myproc>
    80004df0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004df2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004df6:	6785                	lui	a5,0x1
    80004df8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004dfa:	97ca                	add	a5,a5,s2
    80004dfc:	777d                	lui	a4,0xfffff
    80004dfe:	8ff9                	and	a5,a5,a4
    80004e00:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e04:	4691                	li	a3,4
    80004e06:	6609                	lui	a2,0x2
    80004e08:	963e                	add	a2,a2,a5
    80004e0a:	85be                	mv	a1,a5
    80004e0c:	855a                	mv	a0,s6
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	602080e7          	jalr	1538(ra) # 80001410 <uvmalloc>
    80004e16:	8c2a                	mv	s8,a0
  ip = 0;
    80004e18:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e1a:	12050e63          	beqz	a0,80004f56 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e1e:	75f9                	lui	a1,0xffffe
    80004e20:	95aa                	add	a1,a1,a0
    80004e22:	855a                	mv	a0,s6
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	816080e7          	jalr	-2026(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e2c:	7afd                	lui	s5,0xfffff
    80004e2e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e30:	df043783          	ld	a5,-528(s0)
    80004e34:	6388                	ld	a0,0(a5)
    80004e36:	c925                	beqz	a0,80004ea6 <exec+0x224>
    80004e38:	e9040993          	addi	s3,s0,-368
    80004e3c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e40:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e42:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	00a080e7          	jalr	10(ra) # 80000e4e <strlen>
    80004e4c:	0015079b          	addiw	a5,a0,1
    80004e50:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e54:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e58:	13596663          	bltu	s2,s5,80004f84 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e5c:	df043d83          	ld	s11,-528(s0)
    80004e60:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e64:	8552                	mv	a0,s4
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	fe8080e7          	jalr	-24(ra) # 80000e4e <strlen>
    80004e6e:	0015069b          	addiw	a3,a0,1
    80004e72:	8652                	mv	a2,s4
    80004e74:	85ca                	mv	a1,s2
    80004e76:	855a                	mv	a0,s6
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	7f4080e7          	jalr	2036(ra) # 8000166c <copyout>
    80004e80:	10054663          	bltz	a0,80004f8c <exec+0x30a>
    ustack[argc] = sp;
    80004e84:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e88:	0485                	addi	s1,s1,1
    80004e8a:	008d8793          	addi	a5,s11,8
    80004e8e:	def43823          	sd	a5,-528(s0)
    80004e92:	008db503          	ld	a0,8(s11)
    80004e96:	c911                	beqz	a0,80004eaa <exec+0x228>
    if(argc >= MAXARG)
    80004e98:	09a1                	addi	s3,s3,8
    80004e9a:	fb3c95e3          	bne	s9,s3,80004e44 <exec+0x1c2>
  sz = sz1;
    80004e9e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ea2:	4a81                	li	s5,0
    80004ea4:	a84d                	j	80004f56 <exec+0x2d4>
  sp = sz;
    80004ea6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ea8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eaa:	00349793          	slli	a5,s1,0x3
    80004eae:	f9078793          	addi	a5,a5,-112
    80004eb2:	97a2                	add	a5,a5,s0
    80004eb4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004eb8:	00148693          	addi	a3,s1,1
    80004ebc:	068e                	slli	a3,a3,0x3
    80004ebe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ec6:	01597663          	bgeu	s2,s5,80004ed2 <exec+0x250>
  sz = sz1;
    80004eca:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ece:	4a81                	li	s5,0
    80004ed0:	a059                	j	80004f56 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed2:	e9040613          	addi	a2,s0,-368
    80004ed6:	85ca                	mv	a1,s2
    80004ed8:	855a                	mv	a0,s6
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	792080e7          	jalr	1938(ra) # 8000166c <copyout>
    80004ee2:	0a054963          	bltz	a0,80004f94 <exec+0x312>
  p->trapframe->a1 = sp;
    80004ee6:	058bb783          	ld	a5,88(s7)
    80004eea:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eee:	de843783          	ld	a5,-536(s0)
    80004ef2:	0007c703          	lbu	a4,0(a5)
    80004ef6:	cf11                	beqz	a4,80004f12 <exec+0x290>
    80004ef8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004efa:	02f00693          	li	a3,47
    80004efe:	a039                	j	80004f0c <exec+0x28a>
      last = s+1;
    80004f00:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f04:	0785                	addi	a5,a5,1
    80004f06:	fff7c703          	lbu	a4,-1(a5)
    80004f0a:	c701                	beqz	a4,80004f12 <exec+0x290>
    if(*s == '/')
    80004f0c:	fed71ce3          	bne	a4,a3,80004f04 <exec+0x282>
    80004f10:	bfc5                	j	80004f00 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f12:	4641                	li	a2,16
    80004f14:	de843583          	ld	a1,-536(s0)
    80004f18:	158b8513          	addi	a0,s7,344
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	f00080e7          	jalr	-256(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f24:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f28:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f2c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f30:	058bb783          	ld	a5,88(s7)
    80004f34:	e6843703          	ld	a4,-408(s0)
    80004f38:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f3a:	058bb783          	ld	a5,88(s7)
    80004f3e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f42:	85ea                	mv	a1,s10
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	bc8080e7          	jalr	-1080(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f4c:	0004851b          	sext.w	a0,s1
    80004f50:	b3f9                	j	80004d1e <exec+0x9c>
    80004f52:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f56:	df843583          	ld	a1,-520(s0)
    80004f5a:	855a                	mv	a0,s6
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	bb0080e7          	jalr	-1104(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004f64:	da0a93e3          	bnez	s5,80004d0a <exec+0x88>
  return -1;
    80004f68:	557d                	li	a0,-1
    80004f6a:	bb55                	j	80004d1e <exec+0x9c>
    80004f6c:	df243c23          	sd	s2,-520(s0)
    80004f70:	b7dd                	j	80004f56 <exec+0x2d4>
    80004f72:	df243c23          	sd	s2,-520(s0)
    80004f76:	b7c5                	j	80004f56 <exec+0x2d4>
    80004f78:	df243c23          	sd	s2,-520(s0)
    80004f7c:	bfe9                	j	80004f56 <exec+0x2d4>
    80004f7e:	df243c23          	sd	s2,-520(s0)
    80004f82:	bfd1                	j	80004f56 <exec+0x2d4>
  sz = sz1;
    80004f84:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f88:	4a81                	li	s5,0
    80004f8a:	b7f1                	j	80004f56 <exec+0x2d4>
  sz = sz1;
    80004f8c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f90:	4a81                	li	s5,0
    80004f92:	b7d1                	j	80004f56 <exec+0x2d4>
  sz = sz1;
    80004f94:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f98:	4a81                	li	s5,0
    80004f9a:	bf75                	j	80004f56 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f9c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa0:	e0843783          	ld	a5,-504(s0)
    80004fa4:	0017869b          	addiw	a3,a5,1
    80004fa8:	e0d43423          	sd	a3,-504(s0)
    80004fac:	e0043783          	ld	a5,-512(s0)
    80004fb0:	0387879b          	addiw	a5,a5,56
    80004fb4:	e8845703          	lhu	a4,-376(s0)
    80004fb8:	e0e6dfe3          	bge	a3,a4,80004dd6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fbc:	2781                	sext.w	a5,a5
    80004fbe:	e0f43023          	sd	a5,-512(s0)
    80004fc2:	03800713          	li	a4,56
    80004fc6:	86be                	mv	a3,a5
    80004fc8:	e1840613          	addi	a2,s0,-488
    80004fcc:	4581                	li	a1,0
    80004fce:	8556                	mv	a0,s5
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	a58080e7          	jalr	-1448(ra) # 80003a28 <readi>
    80004fd8:	03800793          	li	a5,56
    80004fdc:	f6f51be3          	bne	a0,a5,80004f52 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004fe0:	e1842783          	lw	a5,-488(s0)
    80004fe4:	4705                	li	a4,1
    80004fe6:	fae79de3          	bne	a5,a4,80004fa0 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004fea:	e4043483          	ld	s1,-448(s0)
    80004fee:	e3843783          	ld	a5,-456(s0)
    80004ff2:	f6f4ede3          	bltu	s1,a5,80004f6c <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ff6:	e2843783          	ld	a5,-472(s0)
    80004ffa:	94be                	add	s1,s1,a5
    80004ffc:	f6f4ebe3          	bltu	s1,a5,80004f72 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005000:	de043703          	ld	a4,-544(s0)
    80005004:	8ff9                	and	a5,a5,a4
    80005006:	fbad                	bnez	a5,80004f78 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005008:	e1c42503          	lw	a0,-484(s0)
    8000500c:	00000097          	auipc	ra,0x0
    80005010:	c5c080e7          	jalr	-932(ra) # 80004c68 <flags2perm>
    80005014:	86aa                	mv	a3,a0
    80005016:	8626                	mv	a2,s1
    80005018:	85ca                	mv	a1,s2
    8000501a:	855a                	mv	a0,s6
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	3f4080e7          	jalr	1012(ra) # 80001410 <uvmalloc>
    80005024:	dea43c23          	sd	a0,-520(s0)
    80005028:	d939                	beqz	a0,80004f7e <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000502a:	e2843c03          	ld	s8,-472(s0)
    8000502e:	e2042c83          	lw	s9,-480(s0)
    80005032:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005036:	f60b83e3          	beqz	s7,80004f9c <exec+0x31a>
    8000503a:	89de                	mv	s3,s7
    8000503c:	4481                	li	s1,0
    8000503e:	bb9d                	j	80004db4 <exec+0x132>

0000000080005040 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005040:	7179                	addi	sp,sp,-48
    80005042:	f406                	sd	ra,40(sp)
    80005044:	f022                	sd	s0,32(sp)
    80005046:	ec26                	sd	s1,24(sp)
    80005048:	e84a                	sd	s2,16(sp)
    8000504a:	1800                	addi	s0,sp,48
    8000504c:	892e                	mv	s2,a1
    8000504e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005050:	fdc40593          	addi	a1,s0,-36
    80005054:	ffffe097          	auipc	ra,0xffffe
    80005058:	aea080e7          	jalr	-1302(ra) # 80002b3e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000505c:	fdc42703          	lw	a4,-36(s0)
    80005060:	47bd                	li	a5,15
    80005062:	02e7eb63          	bltu	a5,a4,80005098 <argfd+0x58>
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000506e:	fdc42703          	lw	a4,-36(s0)
    80005072:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd27a>
    80005076:	078e                	slli	a5,a5,0x3
    80005078:	953e                	add	a0,a0,a5
    8000507a:	611c                	ld	a5,0(a0)
    8000507c:	c385                	beqz	a5,8000509c <argfd+0x5c>
    return -1;
  if(pfd)
    8000507e:	00090463          	beqz	s2,80005086 <argfd+0x46>
    *pfd = fd;
    80005082:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005086:	4501                	li	a0,0
  if(pf)
    80005088:	c091                	beqz	s1,8000508c <argfd+0x4c>
    *pf = f;
    8000508a:	e09c                	sd	a5,0(s1)
}
    8000508c:	70a2                	ld	ra,40(sp)
    8000508e:	7402                	ld	s0,32(sp)
    80005090:	64e2                	ld	s1,24(sp)
    80005092:	6942                	ld	s2,16(sp)
    80005094:	6145                	addi	sp,sp,48
    80005096:	8082                	ret
    return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	bfcd                	j	8000508c <argfd+0x4c>
    8000509c:	557d                	li	a0,-1
    8000509e:	b7fd                	j	8000508c <argfd+0x4c>

00000000800050a0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050a0:	1101                	addi	sp,sp,-32
    800050a2:	ec06                	sd	ra,24(sp)
    800050a4:	e822                	sd	s0,16(sp)
    800050a6:	e426                	sd	s1,8(sp)
    800050a8:	1000                	addi	s0,sp,32
    800050aa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	900080e7          	jalr	-1792(ra) # 800019ac <myproc>
    800050b4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050b6:	0d050793          	addi	a5,a0,208
    800050ba:	4501                	li	a0,0
    800050bc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050be:	6398                	ld	a4,0(a5)
    800050c0:	cb19                	beqz	a4,800050d6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050c2:	2505                	addiw	a0,a0,1
    800050c4:	07a1                	addi	a5,a5,8
    800050c6:	fed51ce3          	bne	a0,a3,800050be <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ca:	557d                	li	a0,-1
}
    800050cc:	60e2                	ld	ra,24(sp)
    800050ce:	6442                	ld	s0,16(sp)
    800050d0:	64a2                	ld	s1,8(sp)
    800050d2:	6105                	addi	sp,sp,32
    800050d4:	8082                	ret
      p->ofile[fd] = f;
    800050d6:	01a50793          	addi	a5,a0,26
    800050da:	078e                	slli	a5,a5,0x3
    800050dc:	963e                	add	a2,a2,a5
    800050de:	e204                	sd	s1,0(a2)
      return fd;
    800050e0:	b7f5                	j	800050cc <fdalloc+0x2c>

00000000800050e2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050e2:	715d                	addi	sp,sp,-80
    800050e4:	e486                	sd	ra,72(sp)
    800050e6:	e0a2                	sd	s0,64(sp)
    800050e8:	fc26                	sd	s1,56(sp)
    800050ea:	f84a                	sd	s2,48(sp)
    800050ec:	f44e                	sd	s3,40(sp)
    800050ee:	f052                	sd	s4,32(sp)
    800050f0:	ec56                	sd	s5,24(sp)
    800050f2:	e85a                	sd	s6,16(sp)
    800050f4:	0880                	addi	s0,sp,80
    800050f6:	8b2e                	mv	s6,a1
    800050f8:	89b2                	mv	s3,a2
    800050fa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050fc:	fb040593          	addi	a1,s0,-80
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	e3e080e7          	jalr	-450(ra) # 80003f3e <nameiparent>
    80005108:	84aa                	mv	s1,a0
    8000510a:	14050f63          	beqz	a0,80005268 <create+0x186>
    return 0;

  ilock(dp);
    8000510e:	ffffe097          	auipc	ra,0xffffe
    80005112:	666080e7          	jalr	1638(ra) # 80003774 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005116:	4601                	li	a2,0
    80005118:	fb040593          	addi	a1,s0,-80
    8000511c:	8526                	mv	a0,s1
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	b3a080e7          	jalr	-1222(ra) # 80003c58 <dirlookup>
    80005126:	8aaa                	mv	s5,a0
    80005128:	c931                	beqz	a0,8000517c <create+0x9a>
    iunlockput(dp);
    8000512a:	8526                	mv	a0,s1
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	8aa080e7          	jalr	-1878(ra) # 800039d6 <iunlockput>
    ilock(ip);
    80005134:	8556                	mv	a0,s5
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	63e080e7          	jalr	1598(ra) # 80003774 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000513e:	000b059b          	sext.w	a1,s6
    80005142:	4789                	li	a5,2
    80005144:	02f59563          	bne	a1,a5,8000516e <create+0x8c>
    80005148:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2a4>
    8000514c:	37f9                	addiw	a5,a5,-2
    8000514e:	17c2                	slli	a5,a5,0x30
    80005150:	93c1                	srli	a5,a5,0x30
    80005152:	4705                	li	a4,1
    80005154:	00f76d63          	bltu	a4,a5,8000516e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005158:	8556                	mv	a0,s5
    8000515a:	60a6                	ld	ra,72(sp)
    8000515c:	6406                	ld	s0,64(sp)
    8000515e:	74e2                	ld	s1,56(sp)
    80005160:	7942                	ld	s2,48(sp)
    80005162:	79a2                	ld	s3,40(sp)
    80005164:	7a02                	ld	s4,32(sp)
    80005166:	6ae2                	ld	s5,24(sp)
    80005168:	6b42                	ld	s6,16(sp)
    8000516a:	6161                	addi	sp,sp,80
    8000516c:	8082                	ret
    iunlockput(ip);
    8000516e:	8556                	mv	a0,s5
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	866080e7          	jalr	-1946(ra) # 800039d6 <iunlockput>
    return 0;
    80005178:	4a81                	li	s5,0
    8000517a:	bff9                	j	80005158 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000517c:	85da                	mv	a1,s6
    8000517e:	4088                	lw	a0,0(s1)
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	456080e7          	jalr	1110(ra) # 800035d6 <ialloc>
    80005188:	8a2a                	mv	s4,a0
    8000518a:	c539                	beqz	a0,800051d8 <create+0xf6>
  ilock(ip);
    8000518c:	ffffe097          	auipc	ra,0xffffe
    80005190:	5e8080e7          	jalr	1512(ra) # 80003774 <ilock>
  ip->major = major;
    80005194:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005198:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000519c:	4905                	li	s2,1
    8000519e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051a2:	8552                	mv	a0,s4
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	504080e7          	jalr	1284(ra) # 800036a8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ac:	000b059b          	sext.w	a1,s6
    800051b0:	03258b63          	beq	a1,s2,800051e6 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051b4:	004a2603          	lw	a2,4(s4)
    800051b8:	fb040593          	addi	a1,s0,-80
    800051bc:	8526                	mv	a0,s1
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	cb0080e7          	jalr	-848(ra) # 80003e6e <dirlink>
    800051c6:	06054f63          	bltz	a0,80005244 <create+0x162>
  iunlockput(dp);
    800051ca:	8526                	mv	a0,s1
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	80a080e7          	jalr	-2038(ra) # 800039d6 <iunlockput>
  return ip;
    800051d4:	8ad2                	mv	s5,s4
    800051d6:	b749                	j	80005158 <create+0x76>
    iunlockput(dp);
    800051d8:	8526                	mv	a0,s1
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	7fc080e7          	jalr	2044(ra) # 800039d6 <iunlockput>
    return 0;
    800051e2:	8ad2                	mv	s5,s4
    800051e4:	bf95                	j	80005158 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051e6:	004a2603          	lw	a2,4(s4)
    800051ea:	00003597          	auipc	a1,0x3
    800051ee:	54658593          	addi	a1,a1,1350 # 80008730 <syscalls+0x2e0>
    800051f2:	8552                	mv	a0,s4
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	c7a080e7          	jalr	-902(ra) # 80003e6e <dirlink>
    800051fc:	04054463          	bltz	a0,80005244 <create+0x162>
    80005200:	40d0                	lw	a2,4(s1)
    80005202:	00003597          	auipc	a1,0x3
    80005206:	53658593          	addi	a1,a1,1334 # 80008738 <syscalls+0x2e8>
    8000520a:	8552                	mv	a0,s4
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	c62080e7          	jalr	-926(ra) # 80003e6e <dirlink>
    80005214:	02054863          	bltz	a0,80005244 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005218:	004a2603          	lw	a2,4(s4)
    8000521c:	fb040593          	addi	a1,s0,-80
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	c4c080e7          	jalr	-948(ra) # 80003e6e <dirlink>
    8000522a:	00054d63          	bltz	a0,80005244 <create+0x162>
    dp->nlink++;  // for ".."
    8000522e:	04a4d783          	lhu	a5,74(s1)
    80005232:	2785                	addiw	a5,a5,1
    80005234:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	46e080e7          	jalr	1134(ra) # 800036a8 <iupdate>
    80005242:	b761                	j	800051ca <create+0xe8>
  ip->nlink = 0;
    80005244:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005248:	8552                	mv	a0,s4
    8000524a:	ffffe097          	auipc	ra,0xffffe
    8000524e:	45e080e7          	jalr	1118(ra) # 800036a8 <iupdate>
  iunlockput(ip);
    80005252:	8552                	mv	a0,s4
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	782080e7          	jalr	1922(ra) # 800039d6 <iunlockput>
  iunlockput(dp);
    8000525c:	8526                	mv	a0,s1
    8000525e:	ffffe097          	auipc	ra,0xffffe
    80005262:	778080e7          	jalr	1912(ra) # 800039d6 <iunlockput>
  return 0;
    80005266:	bdcd                	j	80005158 <create+0x76>
    return 0;
    80005268:	8aaa                	mv	s5,a0
    8000526a:	b5fd                	j	80005158 <create+0x76>

000000008000526c <sys_dup>:
{
    8000526c:	7179                	addi	sp,sp,-48
    8000526e:	f406                	sd	ra,40(sp)
    80005270:	f022                	sd	s0,32(sp)
    80005272:	ec26                	sd	s1,24(sp)
    80005274:	e84a                	sd	s2,16(sp)
    80005276:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005278:	fd840613          	addi	a2,s0,-40
    8000527c:	4581                	li	a1,0
    8000527e:	4501                	li	a0,0
    80005280:	00000097          	auipc	ra,0x0
    80005284:	dc0080e7          	jalr	-576(ra) # 80005040 <argfd>
    return -1;
    80005288:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000528a:	02054363          	bltz	a0,800052b0 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000528e:	fd843903          	ld	s2,-40(s0)
    80005292:	854a                	mv	a0,s2
    80005294:	00000097          	auipc	ra,0x0
    80005298:	e0c080e7          	jalr	-500(ra) # 800050a0 <fdalloc>
    8000529c:	84aa                	mv	s1,a0
    return -1;
    8000529e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052a0:	00054863          	bltz	a0,800052b0 <sys_dup+0x44>
  filedup(f);
    800052a4:	854a                	mv	a0,s2
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	310080e7          	jalr	784(ra) # 800045b6 <filedup>
  return fd;
    800052ae:	87a6                	mv	a5,s1
}
    800052b0:	853e                	mv	a0,a5
    800052b2:	70a2                	ld	ra,40(sp)
    800052b4:	7402                	ld	s0,32(sp)
    800052b6:	64e2                	ld	s1,24(sp)
    800052b8:	6942                	ld	s2,16(sp)
    800052ba:	6145                	addi	sp,sp,48
    800052bc:	8082                	ret

00000000800052be <sys_read>:
{
    800052be:	7179                	addi	sp,sp,-48
    800052c0:	f406                	sd	ra,40(sp)
    800052c2:	f022                	sd	s0,32(sp)
    800052c4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052c6:	fd840593          	addi	a1,s0,-40
    800052ca:	4505                	li	a0,1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	892080e7          	jalr	-1902(ra) # 80002b5e <argaddr>
  argint(2, &n);
    800052d4:	fe440593          	addi	a1,s0,-28
    800052d8:	4509                	li	a0,2
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	864080e7          	jalr	-1948(ra) # 80002b3e <argint>
  if(argfd(0, 0, &f) < 0)
    800052e2:	fe840613          	addi	a2,s0,-24
    800052e6:	4581                	li	a1,0
    800052e8:	4501                	li	a0,0
    800052ea:	00000097          	auipc	ra,0x0
    800052ee:	d56080e7          	jalr	-682(ra) # 80005040 <argfd>
    800052f2:	87aa                	mv	a5,a0
    return -1;
    800052f4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052f6:	0007cc63          	bltz	a5,8000530e <sys_read+0x50>
  return fileread(f, p, n);
    800052fa:	fe442603          	lw	a2,-28(s0)
    800052fe:	fd843583          	ld	a1,-40(s0)
    80005302:	fe843503          	ld	a0,-24(s0)
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	43c080e7          	jalr	1084(ra) # 80004742 <fileread>
}
    8000530e:	70a2                	ld	ra,40(sp)
    80005310:	7402                	ld	s0,32(sp)
    80005312:	6145                	addi	sp,sp,48
    80005314:	8082                	ret

0000000080005316 <sys_write>:
{
    80005316:	7179                	addi	sp,sp,-48
    80005318:	f406                	sd	ra,40(sp)
    8000531a:	f022                	sd	s0,32(sp)
    8000531c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000531e:	fd840593          	addi	a1,s0,-40
    80005322:	4505                	li	a0,1
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	83a080e7          	jalr	-1990(ra) # 80002b5e <argaddr>
  argint(2, &n);
    8000532c:	fe440593          	addi	a1,s0,-28
    80005330:	4509                	li	a0,2
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	80c080e7          	jalr	-2036(ra) # 80002b3e <argint>
  if(argfd(0, 0, &f) < 0)
    8000533a:	fe840613          	addi	a2,s0,-24
    8000533e:	4581                	li	a1,0
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	cfe080e7          	jalr	-770(ra) # 80005040 <argfd>
    8000534a:	87aa                	mv	a5,a0
    return -1;
    8000534c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000534e:	0007cc63          	bltz	a5,80005366 <sys_write+0x50>
  return filewrite(f, p, n);
    80005352:	fe442603          	lw	a2,-28(s0)
    80005356:	fd843583          	ld	a1,-40(s0)
    8000535a:	fe843503          	ld	a0,-24(s0)
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	4a6080e7          	jalr	1190(ra) # 80004804 <filewrite>
}
    80005366:	70a2                	ld	ra,40(sp)
    80005368:	7402                	ld	s0,32(sp)
    8000536a:	6145                	addi	sp,sp,48
    8000536c:	8082                	ret

000000008000536e <sys_close>:
{
    8000536e:	1101                	addi	sp,sp,-32
    80005370:	ec06                	sd	ra,24(sp)
    80005372:	e822                	sd	s0,16(sp)
    80005374:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005376:	fe040613          	addi	a2,s0,-32
    8000537a:	fec40593          	addi	a1,s0,-20
    8000537e:	4501                	li	a0,0
    80005380:	00000097          	auipc	ra,0x0
    80005384:	cc0080e7          	jalr	-832(ra) # 80005040 <argfd>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000538a:	02054463          	bltz	a0,800053b2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	61e080e7          	jalr	1566(ra) # 800019ac <myproc>
    80005396:	fec42783          	lw	a5,-20(s0)
    8000539a:	07e9                	addi	a5,a5,26
    8000539c:	078e                	slli	a5,a5,0x3
    8000539e:	953e                	add	a0,a0,a5
    800053a0:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053a4:	fe043503          	ld	a0,-32(s0)
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	260080e7          	jalr	608(ra) # 80004608 <fileclose>
  return 0;
    800053b0:	4781                	li	a5,0
}
    800053b2:	853e                	mv	a0,a5
    800053b4:	60e2                	ld	ra,24(sp)
    800053b6:	6442                	ld	s0,16(sp)
    800053b8:	6105                	addi	sp,sp,32
    800053ba:	8082                	ret

00000000800053bc <sys_fstat>:
{
    800053bc:	1101                	addi	sp,sp,-32
    800053be:	ec06                	sd	ra,24(sp)
    800053c0:	e822                	sd	s0,16(sp)
    800053c2:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053c4:	fe040593          	addi	a1,s0,-32
    800053c8:	4505                	li	a0,1
    800053ca:	ffffd097          	auipc	ra,0xffffd
    800053ce:	794080e7          	jalr	1940(ra) # 80002b5e <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053d2:	fe840613          	addi	a2,s0,-24
    800053d6:	4581                	li	a1,0
    800053d8:	4501                	li	a0,0
    800053da:	00000097          	auipc	ra,0x0
    800053de:	c66080e7          	jalr	-922(ra) # 80005040 <argfd>
    800053e2:	87aa                	mv	a5,a0
    return -1;
    800053e4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053e6:	0007ca63          	bltz	a5,800053fa <sys_fstat+0x3e>
  return filestat(f, st);
    800053ea:	fe043583          	ld	a1,-32(s0)
    800053ee:	fe843503          	ld	a0,-24(s0)
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	2de080e7          	jalr	734(ra) # 800046d0 <filestat>
}
    800053fa:	60e2                	ld	ra,24(sp)
    800053fc:	6442                	ld	s0,16(sp)
    800053fe:	6105                	addi	sp,sp,32
    80005400:	8082                	ret

0000000080005402 <sys_link>:
{
    80005402:	7169                	addi	sp,sp,-304
    80005404:	f606                	sd	ra,296(sp)
    80005406:	f222                	sd	s0,288(sp)
    80005408:	ee26                	sd	s1,280(sp)
    8000540a:	ea4a                	sd	s2,272(sp)
    8000540c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000540e:	08000613          	li	a2,128
    80005412:	ed040593          	addi	a1,s0,-304
    80005416:	4501                	li	a0,0
    80005418:	ffffd097          	auipc	ra,0xffffd
    8000541c:	766080e7          	jalr	1894(ra) # 80002b7e <argstr>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005422:	10054e63          	bltz	a0,8000553e <sys_link+0x13c>
    80005426:	08000613          	li	a2,128
    8000542a:	f5040593          	addi	a1,s0,-176
    8000542e:	4505                	li	a0,1
    80005430:	ffffd097          	auipc	ra,0xffffd
    80005434:	74e080e7          	jalr	1870(ra) # 80002b7e <argstr>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543a:	10054263          	bltz	a0,8000553e <sys_link+0x13c>
  begin_op();
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	d02080e7          	jalr	-766(ra) # 80004140 <begin_op>
  if((ip = namei(old)) == 0){
    80005446:	ed040513          	addi	a0,s0,-304
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	ad6080e7          	jalr	-1322(ra) # 80003f20 <namei>
    80005452:	84aa                	mv	s1,a0
    80005454:	c551                	beqz	a0,800054e0 <sys_link+0xde>
  ilock(ip);
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	31e080e7          	jalr	798(ra) # 80003774 <ilock>
  if(ip->type == T_DIR){
    8000545e:	04449703          	lh	a4,68(s1)
    80005462:	4785                	li	a5,1
    80005464:	08f70463          	beq	a4,a5,800054ec <sys_link+0xea>
  ip->nlink++;
    80005468:	04a4d783          	lhu	a5,74(s1)
    8000546c:	2785                	addiw	a5,a5,1
    8000546e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005472:	8526                	mv	a0,s1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	234080e7          	jalr	564(ra) # 800036a8 <iupdate>
  iunlock(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	3b8080e7          	jalr	952(ra) # 80003836 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005486:	fd040593          	addi	a1,s0,-48
    8000548a:	f5040513          	addi	a0,s0,-176
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	ab0080e7          	jalr	-1360(ra) # 80003f3e <nameiparent>
    80005496:	892a                	mv	s2,a0
    80005498:	c935                	beqz	a0,8000550c <sys_link+0x10a>
  ilock(dp);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	2da080e7          	jalr	730(ra) # 80003774 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054a2:	00092703          	lw	a4,0(s2)
    800054a6:	409c                	lw	a5,0(s1)
    800054a8:	04f71d63          	bne	a4,a5,80005502 <sys_link+0x100>
    800054ac:	40d0                	lw	a2,4(s1)
    800054ae:	fd040593          	addi	a1,s0,-48
    800054b2:	854a                	mv	a0,s2
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	9ba080e7          	jalr	-1606(ra) # 80003e6e <dirlink>
    800054bc:	04054363          	bltz	a0,80005502 <sys_link+0x100>
  iunlockput(dp);
    800054c0:	854a                	mv	a0,s2
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	514080e7          	jalr	1300(ra) # 800039d6 <iunlockput>
  iput(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	462080e7          	jalr	1122(ra) # 8000392e <iput>
  end_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	cea080e7          	jalr	-790(ra) # 800041be <end_op>
  return 0;
    800054dc:	4781                	li	a5,0
    800054de:	a085                	j	8000553e <sys_link+0x13c>
    end_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	cde080e7          	jalr	-802(ra) # 800041be <end_op>
    return -1;
    800054e8:	57fd                	li	a5,-1
    800054ea:	a891                	j	8000553e <sys_link+0x13c>
    iunlockput(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	4e8080e7          	jalr	1256(ra) # 800039d6 <iunlockput>
    end_op();
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	cc8080e7          	jalr	-824(ra) # 800041be <end_op>
    return -1;
    800054fe:	57fd                	li	a5,-1
    80005500:	a83d                	j	8000553e <sys_link+0x13c>
    iunlockput(dp);
    80005502:	854a                	mv	a0,s2
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	4d2080e7          	jalr	1234(ra) # 800039d6 <iunlockput>
  ilock(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	266080e7          	jalr	614(ra) # 80003774 <ilock>
  ip->nlink--;
    80005516:	04a4d783          	lhu	a5,74(s1)
    8000551a:	37fd                	addiw	a5,a5,-1
    8000551c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	186080e7          	jalr	390(ra) # 800036a8 <iupdate>
  iunlockput(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	4aa080e7          	jalr	1194(ra) # 800039d6 <iunlockput>
  end_op();
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	c8a080e7          	jalr	-886(ra) # 800041be <end_op>
  return -1;
    8000553c:	57fd                	li	a5,-1
}
    8000553e:	853e                	mv	a0,a5
    80005540:	70b2                	ld	ra,296(sp)
    80005542:	7412                	ld	s0,288(sp)
    80005544:	64f2                	ld	s1,280(sp)
    80005546:	6952                	ld	s2,272(sp)
    80005548:	6155                	addi	sp,sp,304
    8000554a:	8082                	ret

000000008000554c <sys_unlink>:
{
    8000554c:	7151                	addi	sp,sp,-240
    8000554e:	f586                	sd	ra,232(sp)
    80005550:	f1a2                	sd	s0,224(sp)
    80005552:	eda6                	sd	s1,216(sp)
    80005554:	e9ca                	sd	s2,208(sp)
    80005556:	e5ce                	sd	s3,200(sp)
    80005558:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000555a:	08000613          	li	a2,128
    8000555e:	f3040593          	addi	a1,s0,-208
    80005562:	4501                	li	a0,0
    80005564:	ffffd097          	auipc	ra,0xffffd
    80005568:	61a080e7          	jalr	1562(ra) # 80002b7e <argstr>
    8000556c:	18054163          	bltz	a0,800056ee <sys_unlink+0x1a2>
  begin_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	bd0080e7          	jalr	-1072(ra) # 80004140 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005578:	fb040593          	addi	a1,s0,-80
    8000557c:	f3040513          	addi	a0,s0,-208
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	9be080e7          	jalr	-1602(ra) # 80003f3e <nameiparent>
    80005588:	84aa                	mv	s1,a0
    8000558a:	c979                	beqz	a0,80005660 <sys_unlink+0x114>
  ilock(dp);
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	1e8080e7          	jalr	488(ra) # 80003774 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005594:	00003597          	auipc	a1,0x3
    80005598:	19c58593          	addi	a1,a1,412 # 80008730 <syscalls+0x2e0>
    8000559c:	fb040513          	addi	a0,s0,-80
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	69e080e7          	jalr	1694(ra) # 80003c3e <namecmp>
    800055a8:	14050a63          	beqz	a0,800056fc <sys_unlink+0x1b0>
    800055ac:	00003597          	auipc	a1,0x3
    800055b0:	18c58593          	addi	a1,a1,396 # 80008738 <syscalls+0x2e8>
    800055b4:	fb040513          	addi	a0,s0,-80
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	686080e7          	jalr	1670(ra) # 80003c3e <namecmp>
    800055c0:	12050e63          	beqz	a0,800056fc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055c4:	f2c40613          	addi	a2,s0,-212
    800055c8:	fb040593          	addi	a1,s0,-80
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	68a080e7          	jalr	1674(ra) # 80003c58 <dirlookup>
    800055d6:	892a                	mv	s2,a0
    800055d8:	12050263          	beqz	a0,800056fc <sys_unlink+0x1b0>
  ilock(ip);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	198080e7          	jalr	408(ra) # 80003774 <ilock>
  if(ip->nlink < 1)
    800055e4:	04a91783          	lh	a5,74(s2)
    800055e8:	08f05263          	blez	a5,8000566c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055ec:	04491703          	lh	a4,68(s2)
    800055f0:	4785                	li	a5,1
    800055f2:	08f70563          	beq	a4,a5,8000567c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055f6:	4641                	li	a2,16
    800055f8:	4581                	li	a1,0
    800055fa:	fc040513          	addi	a0,s0,-64
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	6d4080e7          	jalr	1748(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005606:	4741                	li	a4,16
    80005608:	f2c42683          	lw	a3,-212(s0)
    8000560c:	fc040613          	addi	a2,s0,-64
    80005610:	4581                	li	a1,0
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	50c080e7          	jalr	1292(ra) # 80003b20 <writei>
    8000561c:	47c1                	li	a5,16
    8000561e:	0af51563          	bne	a0,a5,800056c8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005622:	04491703          	lh	a4,68(s2)
    80005626:	4785                	li	a5,1
    80005628:	0af70863          	beq	a4,a5,800056d8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	3a8080e7          	jalr	936(ra) # 800039d6 <iunlockput>
  ip->nlink--;
    80005636:	04a95783          	lhu	a5,74(s2)
    8000563a:	37fd                	addiw	a5,a5,-1
    8000563c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005640:	854a                	mv	a0,s2
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	066080e7          	jalr	102(ra) # 800036a8 <iupdate>
  iunlockput(ip);
    8000564a:	854a                	mv	a0,s2
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	38a080e7          	jalr	906(ra) # 800039d6 <iunlockput>
  end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	b6a080e7          	jalr	-1174(ra) # 800041be <end_op>
  return 0;
    8000565c:	4501                	li	a0,0
    8000565e:	a84d                	j	80005710 <sys_unlink+0x1c4>
    end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	b5e080e7          	jalr	-1186(ra) # 800041be <end_op>
    return -1;
    80005668:	557d                	li	a0,-1
    8000566a:	a05d                	j	80005710 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000566c:	00003517          	auipc	a0,0x3
    80005670:	0d450513          	addi	a0,a0,212 # 80008740 <syscalls+0x2f0>
    80005674:	ffffb097          	auipc	ra,0xffffb
    80005678:	ecc080e7          	jalr	-308(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000567c:	04c92703          	lw	a4,76(s2)
    80005680:	02000793          	li	a5,32
    80005684:	f6e7f9e3          	bgeu	a5,a4,800055f6 <sys_unlink+0xaa>
    80005688:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000568c:	4741                	li	a4,16
    8000568e:	86ce                	mv	a3,s3
    80005690:	f1840613          	addi	a2,s0,-232
    80005694:	4581                	li	a1,0
    80005696:	854a                	mv	a0,s2
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	390080e7          	jalr	912(ra) # 80003a28 <readi>
    800056a0:	47c1                	li	a5,16
    800056a2:	00f51b63          	bne	a0,a5,800056b8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056a6:	f1845783          	lhu	a5,-232(s0)
    800056aa:	e7a1                	bnez	a5,800056f2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ac:	29c1                	addiw	s3,s3,16
    800056ae:	04c92783          	lw	a5,76(s2)
    800056b2:	fcf9ede3          	bltu	s3,a5,8000568c <sys_unlink+0x140>
    800056b6:	b781                	j	800055f6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056b8:	00003517          	auipc	a0,0x3
    800056bc:	0a050513          	addi	a0,a0,160 # 80008758 <syscalls+0x308>
    800056c0:	ffffb097          	auipc	ra,0xffffb
    800056c4:	e80080e7          	jalr	-384(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056c8:	00003517          	auipc	a0,0x3
    800056cc:	0a850513          	addi	a0,a0,168 # 80008770 <syscalls+0x320>
    800056d0:	ffffb097          	auipc	ra,0xffffb
    800056d4:	e70080e7          	jalr	-400(ra) # 80000540 <panic>
    dp->nlink--;
    800056d8:	04a4d783          	lhu	a5,74(s1)
    800056dc:	37fd                	addiw	a5,a5,-1
    800056de:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	fc4080e7          	jalr	-60(ra) # 800036a8 <iupdate>
    800056ec:	b781                	j	8000562c <sys_unlink+0xe0>
    return -1;
    800056ee:	557d                	li	a0,-1
    800056f0:	a005                	j	80005710 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056f2:	854a                	mv	a0,s2
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	2e2080e7          	jalr	738(ra) # 800039d6 <iunlockput>
  iunlockput(dp);
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	2d8080e7          	jalr	728(ra) # 800039d6 <iunlockput>
  end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	ab8080e7          	jalr	-1352(ra) # 800041be <end_op>
  return -1;
    8000570e:	557d                	li	a0,-1
}
    80005710:	70ae                	ld	ra,232(sp)
    80005712:	740e                	ld	s0,224(sp)
    80005714:	64ee                	ld	s1,216(sp)
    80005716:	694e                	ld	s2,208(sp)
    80005718:	69ae                	ld	s3,200(sp)
    8000571a:	616d                	addi	sp,sp,240
    8000571c:	8082                	ret

000000008000571e <sys_open>:

uint64
sys_open(void)
{
    8000571e:	7131                	addi	sp,sp,-192
    80005720:	fd06                	sd	ra,184(sp)
    80005722:	f922                	sd	s0,176(sp)
    80005724:	f526                	sd	s1,168(sp)
    80005726:	f14a                	sd	s2,160(sp)
    80005728:	ed4e                	sd	s3,152(sp)
    8000572a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000572c:	f4c40593          	addi	a1,s0,-180
    80005730:	4505                	li	a0,1
    80005732:	ffffd097          	auipc	ra,0xffffd
    80005736:	40c080e7          	jalr	1036(ra) # 80002b3e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000573a:	08000613          	li	a2,128
    8000573e:	f5040593          	addi	a1,s0,-176
    80005742:	4501                	li	a0,0
    80005744:	ffffd097          	auipc	ra,0xffffd
    80005748:	43a080e7          	jalr	1082(ra) # 80002b7e <argstr>
    8000574c:	87aa                	mv	a5,a0
    return -1;
    8000574e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005750:	0a07c963          	bltz	a5,80005802 <sys_open+0xe4>

  begin_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	9ec080e7          	jalr	-1556(ra) # 80004140 <begin_op>

  if(omode & O_CREATE){
    8000575c:	f4c42783          	lw	a5,-180(s0)
    80005760:	2007f793          	andi	a5,a5,512
    80005764:	cfc5                	beqz	a5,8000581c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005766:	4681                	li	a3,0
    80005768:	4601                	li	a2,0
    8000576a:	4589                	li	a1,2
    8000576c:	f5040513          	addi	a0,s0,-176
    80005770:	00000097          	auipc	ra,0x0
    80005774:	972080e7          	jalr	-1678(ra) # 800050e2 <create>
    80005778:	84aa                	mv	s1,a0
    if(ip == 0){
    8000577a:	c959                	beqz	a0,80005810 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000577c:	04449703          	lh	a4,68(s1)
    80005780:	478d                	li	a5,3
    80005782:	00f71763          	bne	a4,a5,80005790 <sys_open+0x72>
    80005786:	0464d703          	lhu	a4,70(s1)
    8000578a:	47a5                	li	a5,9
    8000578c:	0ce7ed63          	bltu	a5,a4,80005866 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	dbc080e7          	jalr	-580(ra) # 8000454c <filealloc>
    80005798:	89aa                	mv	s3,a0
    8000579a:	10050363          	beqz	a0,800058a0 <sys_open+0x182>
    8000579e:	00000097          	auipc	ra,0x0
    800057a2:	902080e7          	jalr	-1790(ra) # 800050a0 <fdalloc>
    800057a6:	892a                	mv	s2,a0
    800057a8:	0e054763          	bltz	a0,80005896 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ac:	04449703          	lh	a4,68(s1)
    800057b0:	478d                	li	a5,3
    800057b2:	0cf70563          	beq	a4,a5,8000587c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057b6:	4789                	li	a5,2
    800057b8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057bc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057c0:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057c4:	f4c42783          	lw	a5,-180(s0)
    800057c8:	0017c713          	xori	a4,a5,1
    800057cc:	8b05                	andi	a4,a4,1
    800057ce:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057d2:	0037f713          	andi	a4,a5,3
    800057d6:	00e03733          	snez	a4,a4
    800057da:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057de:	4007f793          	andi	a5,a5,1024
    800057e2:	c791                	beqz	a5,800057ee <sys_open+0xd0>
    800057e4:	04449703          	lh	a4,68(s1)
    800057e8:	4789                	li	a5,2
    800057ea:	0af70063          	beq	a4,a5,8000588a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ee:	8526                	mv	a0,s1
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	046080e7          	jalr	70(ra) # 80003836 <iunlock>
  end_op();
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	9c6080e7          	jalr	-1594(ra) # 800041be <end_op>

  return fd;
    80005800:	854a                	mv	a0,s2
}
    80005802:	70ea                	ld	ra,184(sp)
    80005804:	744a                	ld	s0,176(sp)
    80005806:	74aa                	ld	s1,168(sp)
    80005808:	790a                	ld	s2,160(sp)
    8000580a:	69ea                	ld	s3,152(sp)
    8000580c:	6129                	addi	sp,sp,192
    8000580e:	8082                	ret
      end_op();
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	9ae080e7          	jalr	-1618(ra) # 800041be <end_op>
      return -1;
    80005818:	557d                	li	a0,-1
    8000581a:	b7e5                	j	80005802 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000581c:	f5040513          	addi	a0,s0,-176
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	700080e7          	jalr	1792(ra) # 80003f20 <namei>
    80005828:	84aa                	mv	s1,a0
    8000582a:	c905                	beqz	a0,8000585a <sys_open+0x13c>
    ilock(ip);
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	f48080e7          	jalr	-184(ra) # 80003774 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005834:	04449703          	lh	a4,68(s1)
    80005838:	4785                	li	a5,1
    8000583a:	f4f711e3          	bne	a4,a5,8000577c <sys_open+0x5e>
    8000583e:	f4c42783          	lw	a5,-180(s0)
    80005842:	d7b9                	beqz	a5,80005790 <sys_open+0x72>
      iunlockput(ip);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	190080e7          	jalr	400(ra) # 800039d6 <iunlockput>
      end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	970080e7          	jalr	-1680(ra) # 800041be <end_op>
      return -1;
    80005856:	557d                	li	a0,-1
    80005858:	b76d                	j	80005802 <sys_open+0xe4>
      end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	964080e7          	jalr	-1692(ra) # 800041be <end_op>
      return -1;
    80005862:	557d                	li	a0,-1
    80005864:	bf79                	j	80005802 <sys_open+0xe4>
    iunlockput(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	16e080e7          	jalr	366(ra) # 800039d6 <iunlockput>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	94e080e7          	jalr	-1714(ra) # 800041be <end_op>
    return -1;
    80005878:	557d                	li	a0,-1
    8000587a:	b761                	j	80005802 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000587c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005880:	04649783          	lh	a5,70(s1)
    80005884:	02f99223          	sh	a5,36(s3)
    80005888:	bf25                	j	800057c0 <sys_open+0xa2>
    itrunc(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	ff6080e7          	jalr	-10(ra) # 80003882 <itrunc>
    80005894:	bfa9                	j	800057ee <sys_open+0xd0>
      fileclose(f);
    80005896:	854e                	mv	a0,s3
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	d70080e7          	jalr	-656(ra) # 80004608 <fileclose>
    iunlockput(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	134080e7          	jalr	308(ra) # 800039d6 <iunlockput>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	914080e7          	jalr	-1772(ra) # 800041be <end_op>
    return -1;
    800058b2:	557d                	li	a0,-1
    800058b4:	b7b9                	j	80005802 <sys_open+0xe4>

00000000800058b6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058b6:	7175                	addi	sp,sp,-144
    800058b8:	e506                	sd	ra,136(sp)
    800058ba:	e122                	sd	s0,128(sp)
    800058bc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	882080e7          	jalr	-1918(ra) # 80004140 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058c6:	08000613          	li	a2,128
    800058ca:	f7040593          	addi	a1,s0,-144
    800058ce:	4501                	li	a0,0
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	2ae080e7          	jalr	686(ra) # 80002b7e <argstr>
    800058d8:	02054963          	bltz	a0,8000590a <sys_mkdir+0x54>
    800058dc:	4681                	li	a3,0
    800058de:	4601                	li	a2,0
    800058e0:	4585                	li	a1,1
    800058e2:	f7040513          	addi	a0,s0,-144
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	7fc080e7          	jalr	2044(ra) # 800050e2 <create>
    800058ee:	cd11                	beqz	a0,8000590a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	0e6080e7          	jalr	230(ra) # 800039d6 <iunlockput>
  end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	8c6080e7          	jalr	-1850(ra) # 800041be <end_op>
  return 0;
    80005900:	4501                	li	a0,0
}
    80005902:	60aa                	ld	ra,136(sp)
    80005904:	640a                	ld	s0,128(sp)
    80005906:	6149                	addi	sp,sp,144
    80005908:	8082                	ret
    end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	8b4080e7          	jalr	-1868(ra) # 800041be <end_op>
    return -1;
    80005912:	557d                	li	a0,-1
    80005914:	b7fd                	j	80005902 <sys_mkdir+0x4c>

0000000080005916 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005916:	7135                	addi	sp,sp,-160
    80005918:	ed06                	sd	ra,152(sp)
    8000591a:	e922                	sd	s0,144(sp)
    8000591c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	822080e7          	jalr	-2014(ra) # 80004140 <begin_op>
  argint(1, &major);
    80005926:	f6c40593          	addi	a1,s0,-148
    8000592a:	4505                	li	a0,1
    8000592c:	ffffd097          	auipc	ra,0xffffd
    80005930:	212080e7          	jalr	530(ra) # 80002b3e <argint>
  argint(2, &minor);
    80005934:	f6840593          	addi	a1,s0,-152
    80005938:	4509                	li	a0,2
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	204080e7          	jalr	516(ra) # 80002b3e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005942:	08000613          	li	a2,128
    80005946:	f7040593          	addi	a1,s0,-144
    8000594a:	4501                	li	a0,0
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	232080e7          	jalr	562(ra) # 80002b7e <argstr>
    80005954:	02054b63          	bltz	a0,8000598a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005958:	f6841683          	lh	a3,-152(s0)
    8000595c:	f6c41603          	lh	a2,-148(s0)
    80005960:	458d                	li	a1,3
    80005962:	f7040513          	addi	a0,s0,-144
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	77c080e7          	jalr	1916(ra) # 800050e2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000596e:	cd11                	beqz	a0,8000598a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	066080e7          	jalr	102(ra) # 800039d6 <iunlockput>
  end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	846080e7          	jalr	-1978(ra) # 800041be <end_op>
  return 0;
    80005980:	4501                	li	a0,0
}
    80005982:	60ea                	ld	ra,152(sp)
    80005984:	644a                	ld	s0,144(sp)
    80005986:	610d                	addi	sp,sp,160
    80005988:	8082                	ret
    end_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	834080e7          	jalr	-1996(ra) # 800041be <end_op>
    return -1;
    80005992:	557d                	li	a0,-1
    80005994:	b7fd                	j	80005982 <sys_mknod+0x6c>

0000000080005996 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005996:	7135                	addi	sp,sp,-160
    80005998:	ed06                	sd	ra,152(sp)
    8000599a:	e922                	sd	s0,144(sp)
    8000599c:	e526                	sd	s1,136(sp)
    8000599e:	e14a                	sd	s2,128(sp)
    800059a0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059a2:	ffffc097          	auipc	ra,0xffffc
    800059a6:	00a080e7          	jalr	10(ra) # 800019ac <myproc>
    800059aa:	892a                	mv	s2,a0
  
  begin_op();
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	794080e7          	jalr	1940(ra) # 80004140 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059b4:	08000613          	li	a2,128
    800059b8:	f6040593          	addi	a1,s0,-160
    800059bc:	4501                	li	a0,0
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	1c0080e7          	jalr	448(ra) # 80002b7e <argstr>
    800059c6:	04054b63          	bltz	a0,80005a1c <sys_chdir+0x86>
    800059ca:	f6040513          	addi	a0,s0,-160
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	552080e7          	jalr	1362(ra) # 80003f20 <namei>
    800059d6:	84aa                	mv	s1,a0
    800059d8:	c131                	beqz	a0,80005a1c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	d9a080e7          	jalr	-614(ra) # 80003774 <ilock>
  if(ip->type != T_DIR){
    800059e2:	04449703          	lh	a4,68(s1)
    800059e6:	4785                	li	a5,1
    800059e8:	04f71063          	bne	a4,a5,80005a28 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ec:	8526                	mv	a0,s1
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	e48080e7          	jalr	-440(ra) # 80003836 <iunlock>
  iput(p->cwd);
    800059f6:	15093503          	ld	a0,336(s2)
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	f34080e7          	jalr	-204(ra) # 8000392e <iput>
  end_op();
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	7bc080e7          	jalr	1980(ra) # 800041be <end_op>
  p->cwd = ip;
    80005a0a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a0e:	4501                	li	a0,0
}
    80005a10:	60ea                	ld	ra,152(sp)
    80005a12:	644a                	ld	s0,144(sp)
    80005a14:	64aa                	ld	s1,136(sp)
    80005a16:	690a                	ld	s2,128(sp)
    80005a18:	610d                	addi	sp,sp,160
    80005a1a:	8082                	ret
    end_op();
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	7a2080e7          	jalr	1954(ra) # 800041be <end_op>
    return -1;
    80005a24:	557d                	li	a0,-1
    80005a26:	b7ed                	j	80005a10 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a28:	8526                	mv	a0,s1
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	fac080e7          	jalr	-84(ra) # 800039d6 <iunlockput>
    end_op();
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	78c080e7          	jalr	1932(ra) # 800041be <end_op>
    return -1;
    80005a3a:	557d                	li	a0,-1
    80005a3c:	bfd1                	j	80005a10 <sys_chdir+0x7a>

0000000080005a3e <sys_exec>:

uint64
sys_exec(void)
{
    80005a3e:	7145                	addi	sp,sp,-464
    80005a40:	e786                	sd	ra,456(sp)
    80005a42:	e3a2                	sd	s0,448(sp)
    80005a44:	ff26                	sd	s1,440(sp)
    80005a46:	fb4a                	sd	s2,432(sp)
    80005a48:	f74e                	sd	s3,424(sp)
    80005a4a:	f352                	sd	s4,416(sp)
    80005a4c:	ef56                	sd	s5,408(sp)
    80005a4e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a50:	e3840593          	addi	a1,s0,-456
    80005a54:	4505                	li	a0,1
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	108080e7          	jalr	264(ra) # 80002b5e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a5e:	08000613          	li	a2,128
    80005a62:	f4040593          	addi	a1,s0,-192
    80005a66:	4501                	li	a0,0
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	116080e7          	jalr	278(ra) # 80002b7e <argstr>
    80005a70:	87aa                	mv	a5,a0
    return -1;
    80005a72:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a74:	0c07c363          	bltz	a5,80005b3a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a78:	10000613          	li	a2,256
    80005a7c:	4581                	li	a1,0
    80005a7e:	e4040513          	addi	a0,s0,-448
    80005a82:	ffffb097          	auipc	ra,0xffffb
    80005a86:	250080e7          	jalr	592(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a8a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a8e:	89a6                	mv	s3,s1
    80005a90:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a92:	02000a13          	li	s4,32
    80005a96:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a9a:	00391513          	slli	a0,s2,0x3
    80005a9e:	e3040593          	addi	a1,s0,-464
    80005aa2:	e3843783          	ld	a5,-456(s0)
    80005aa6:	953e                	add	a0,a0,a5
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	ff8080e7          	jalr	-8(ra) # 80002aa0 <fetchaddr>
    80005ab0:	02054a63          	bltz	a0,80005ae4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ab4:	e3043783          	ld	a5,-464(s0)
    80005ab8:	c3b9                	beqz	a5,80005afe <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aba:	ffffb097          	auipc	ra,0xffffb
    80005abe:	02c080e7          	jalr	44(ra) # 80000ae6 <kalloc>
    80005ac2:	85aa                	mv	a1,a0
    80005ac4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ac8:	cd11                	beqz	a0,80005ae4 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aca:	6605                	lui	a2,0x1
    80005acc:	e3043503          	ld	a0,-464(s0)
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	022080e7          	jalr	34(ra) # 80002af2 <fetchstr>
    80005ad8:	00054663          	bltz	a0,80005ae4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005adc:	0905                	addi	s2,s2,1
    80005ade:	09a1                	addi	s3,s3,8
    80005ae0:	fb491be3          	bne	s2,s4,80005a96 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae4:	f4040913          	addi	s2,s0,-192
    80005ae8:	6088                	ld	a0,0(s1)
    80005aea:	c539                	beqz	a0,80005b38 <sys_exec+0xfa>
    kfree(argv[i]);
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	efc080e7          	jalr	-260(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af4:	04a1                	addi	s1,s1,8
    80005af6:	ff2499e3          	bne	s1,s2,80005ae8 <sys_exec+0xaa>
  return -1;
    80005afa:	557d                	li	a0,-1
    80005afc:	a83d                	j	80005b3a <sys_exec+0xfc>
      argv[i] = 0;
    80005afe:	0a8e                	slli	s5,s5,0x3
    80005b00:	fc0a8793          	addi	a5,s5,-64
    80005b04:	00878ab3          	add	s5,a5,s0
    80005b08:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b0c:	e4040593          	addi	a1,s0,-448
    80005b10:	f4040513          	addi	a0,s0,-192
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	16e080e7          	jalr	366(ra) # 80004c82 <exec>
    80005b1c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1e:	f4040993          	addi	s3,s0,-192
    80005b22:	6088                	ld	a0,0(s1)
    80005b24:	c901                	beqz	a0,80005b34 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	ec2080e7          	jalr	-318(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2e:	04a1                	addi	s1,s1,8
    80005b30:	ff3499e3          	bne	s1,s3,80005b22 <sys_exec+0xe4>
  return ret;
    80005b34:	854a                	mv	a0,s2
    80005b36:	a011                	j	80005b3a <sys_exec+0xfc>
  return -1;
    80005b38:	557d                	li	a0,-1
}
    80005b3a:	60be                	ld	ra,456(sp)
    80005b3c:	641e                	ld	s0,448(sp)
    80005b3e:	74fa                	ld	s1,440(sp)
    80005b40:	795a                	ld	s2,432(sp)
    80005b42:	79ba                	ld	s3,424(sp)
    80005b44:	7a1a                	ld	s4,416(sp)
    80005b46:	6afa                	ld	s5,408(sp)
    80005b48:	6179                	addi	sp,sp,464
    80005b4a:	8082                	ret

0000000080005b4c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b4c:	7139                	addi	sp,sp,-64
    80005b4e:	fc06                	sd	ra,56(sp)
    80005b50:	f822                	sd	s0,48(sp)
    80005b52:	f426                	sd	s1,40(sp)
    80005b54:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b56:	ffffc097          	auipc	ra,0xffffc
    80005b5a:	e56080e7          	jalr	-426(ra) # 800019ac <myproc>
    80005b5e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b60:	fd840593          	addi	a1,s0,-40
    80005b64:	4501                	li	a0,0
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	ff8080e7          	jalr	-8(ra) # 80002b5e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b6e:	fc840593          	addi	a1,s0,-56
    80005b72:	fd040513          	addi	a0,s0,-48
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	dc2080e7          	jalr	-574(ra) # 80004938 <pipealloc>
    return -1;
    80005b7e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b80:	0c054463          	bltz	a0,80005c48 <sys_pipe+0xfc>
  fd0 = -1;
    80005b84:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b88:	fd043503          	ld	a0,-48(s0)
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	514080e7          	jalr	1300(ra) # 800050a0 <fdalloc>
    80005b94:	fca42223          	sw	a0,-60(s0)
    80005b98:	08054b63          	bltz	a0,80005c2e <sys_pipe+0xe2>
    80005b9c:	fc843503          	ld	a0,-56(s0)
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	500080e7          	jalr	1280(ra) # 800050a0 <fdalloc>
    80005ba8:	fca42023          	sw	a0,-64(s0)
    80005bac:	06054863          	bltz	a0,80005c1c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb0:	4691                	li	a3,4
    80005bb2:	fc440613          	addi	a2,s0,-60
    80005bb6:	fd843583          	ld	a1,-40(s0)
    80005bba:	68a8                	ld	a0,80(s1)
    80005bbc:	ffffc097          	auipc	ra,0xffffc
    80005bc0:	ab0080e7          	jalr	-1360(ra) # 8000166c <copyout>
    80005bc4:	02054063          	bltz	a0,80005be4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bc8:	4691                	li	a3,4
    80005bca:	fc040613          	addi	a2,s0,-64
    80005bce:	fd843583          	ld	a1,-40(s0)
    80005bd2:	0591                	addi	a1,a1,4
    80005bd4:	68a8                	ld	a0,80(s1)
    80005bd6:	ffffc097          	auipc	ra,0xffffc
    80005bda:	a96080e7          	jalr	-1386(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bde:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be0:	06055463          	bgez	a0,80005c48 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005be4:	fc442783          	lw	a5,-60(s0)
    80005be8:	07e9                	addi	a5,a5,26
    80005bea:	078e                	slli	a5,a5,0x3
    80005bec:	97a6                	add	a5,a5,s1
    80005bee:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bf2:	fc042783          	lw	a5,-64(s0)
    80005bf6:	07e9                	addi	a5,a5,26
    80005bf8:	078e                	slli	a5,a5,0x3
    80005bfa:	94be                	add	s1,s1,a5
    80005bfc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c00:	fd043503          	ld	a0,-48(s0)
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	a04080e7          	jalr	-1532(ra) # 80004608 <fileclose>
    fileclose(wf);
    80005c0c:	fc843503          	ld	a0,-56(s0)
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	9f8080e7          	jalr	-1544(ra) # 80004608 <fileclose>
    return -1;
    80005c18:	57fd                	li	a5,-1
    80005c1a:	a03d                	j	80005c48 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c1c:	fc442783          	lw	a5,-60(s0)
    80005c20:	0007c763          	bltz	a5,80005c2e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c24:	07e9                	addi	a5,a5,26
    80005c26:	078e                	slli	a5,a5,0x3
    80005c28:	97a6                	add	a5,a5,s1
    80005c2a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c2e:	fd043503          	ld	a0,-48(s0)
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	9d6080e7          	jalr	-1578(ra) # 80004608 <fileclose>
    fileclose(wf);
    80005c3a:	fc843503          	ld	a0,-56(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	9ca080e7          	jalr	-1590(ra) # 80004608 <fileclose>
    return -1;
    80005c46:	57fd                	li	a5,-1
}
    80005c48:	853e                	mv	a0,a5
    80005c4a:	70e2                	ld	ra,56(sp)
    80005c4c:	7442                	ld	s0,48(sp)
    80005c4e:	74a2                	ld	s1,40(sp)
    80005c50:	6121                	addi	sp,sp,64
    80005c52:	8082                	ret
	...

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	ccdfc0ef          	jal	ra,8000296c <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	c48080e7          	jalr	-952(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	97aa                	add	a5,a5,a0
    80005d5c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	c10080e7          	jalr	-1008(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5151b          	slliw	a0,a0,0xd
    80005d7c:	0c2017b7          	lui	a5,0xc201
    80005d80:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d82:	43c8                	lw	a0,4(a5)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	be8080e7          	jalr	-1048(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	04a7cc63          	blt	a5,a0,80005e18 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	0001c797          	auipc	a5,0x1c
    80005dc8:	e9c78793          	addi	a5,a5,-356 # 80021c60 <disk>
    80005dcc:	97aa                	add	a5,a5,a0
    80005dce:	0187c783          	lbu	a5,24(a5)
    80005dd2:	ebb9                	bnez	a5,80005e28 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dd4:	00451693          	slli	a3,a0,0x4
    80005dd8:	0001c797          	auipc	a5,0x1c
    80005ddc:	e8878793          	addi	a5,a5,-376 # 80021c60 <disk>
    80005de0:	6398                	ld	a4,0(a5)
    80005de2:	9736                	add	a4,a4,a3
    80005de4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005de8:	6398                	ld	a4,0(a5)
    80005dea:	9736                	add	a4,a4,a3
    80005dec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005df0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005df4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	4705                	li	a4,1
    80005dfc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e00:	0001c517          	auipc	a0,0x1c
    80005e04:	e7850513          	addi	a0,a0,-392 # 80021c78 <disk+0x18>
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	2b0080e7          	jalr	688(ra) # 800020b8 <wakeup>
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret
    panic("free_desc 1");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	96850513          	addi	a0,a0,-1688 # 80008780 <syscalls+0x330>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	720080e7          	jalr	1824(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	96850513          	addi	a0,a0,-1688 # 80008790 <syscalls+0x340>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	710080e7          	jalr	1808(ra) # 80000540 <panic>

0000000080005e38 <virtio_disk_init>:
{
    80005e38:	1101                	addi	sp,sp,-32
    80005e3a:	ec06                	sd	ra,24(sp)
    80005e3c:	e822                	sd	s0,16(sp)
    80005e3e:	e426                	sd	s1,8(sp)
    80005e40:	e04a                	sd	s2,0(sp)
    80005e42:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e44:	00003597          	auipc	a1,0x3
    80005e48:	95c58593          	addi	a1,a1,-1700 # 800087a0 <syscalls+0x350>
    80005e4c:	0001c517          	auipc	a0,0x1c
    80005e50:	f3c50513          	addi	a0,a0,-196 # 80021d88 <disk+0x128>
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	cf2080e7          	jalr	-782(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e5c:	100017b7          	lui	a5,0x10001
    80005e60:	4398                	lw	a4,0(a5)
    80005e62:	2701                	sext.w	a4,a4
    80005e64:	747277b7          	lui	a5,0x74727
    80005e68:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e6c:	14f71b63          	bne	a4,a5,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e70:	100017b7          	lui	a5,0x10001
    80005e74:	43dc                	lw	a5,4(a5)
    80005e76:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e78:	4709                	li	a4,2
    80005e7a:	14e79463          	bne	a5,a4,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	479c                	lw	a5,8(a5)
    80005e84:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e86:	12e79e63          	bne	a5,a4,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e8a:	100017b7          	lui	a5,0x10001
    80005e8e:	47d8                	lw	a4,12(a5)
    80005e90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e92:	554d47b7          	lui	a5,0x554d4
    80005e96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e9a:	12f71463          	bne	a4,a5,80005fc2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea6:	4705                	li	a4,1
    80005ea8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	470d                	li	a4,3
    80005eac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eb0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005eb4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9bf>
    80005eb8:	8f75                	and	a4,a4,a3
    80005eba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebc:	472d                	li	a4,11
    80005ebe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ec0:	5bbc                	lw	a5,112(a5)
    80005ec2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ec6:	8ba1                	andi	a5,a5,8
    80005ec8:	10078563          	beqz	a5,80005fd2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ecc:	100017b7          	lui	a5,0x10001
    80005ed0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ed4:	43fc                	lw	a5,68(a5)
    80005ed6:	2781                	sext.w	a5,a5
    80005ed8:	10079563          	bnez	a5,80005fe2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	5bdc                	lw	a5,52(a5)
    80005ee2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee4:	10078763          	beqz	a5,80005ff2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005ee8:	471d                	li	a4,7
    80005eea:	10f77c63          	bgeu	a4,a5,80006002 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	bf8080e7          	jalr	-1032(ra) # 80000ae6 <kalloc>
    80005ef6:	0001c497          	auipc	s1,0x1c
    80005efa:	d6a48493          	addi	s1,s1,-662 # 80021c60 <disk>
    80005efe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	be6080e7          	jalr	-1050(ra) # 80000ae6 <kalloc>
    80005f08:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f0a:	ffffb097          	auipc	ra,0xffffb
    80005f0e:	bdc080e7          	jalr	-1060(ra) # 80000ae6 <kalloc>
    80005f12:	87aa                	mv	a5,a0
    80005f14:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f16:	6088                	ld	a0,0(s1)
    80005f18:	cd6d                	beqz	a0,80006012 <virtio_disk_init+0x1da>
    80005f1a:	0001c717          	auipc	a4,0x1c
    80005f1e:	d4e73703          	ld	a4,-690(a4) # 80021c68 <disk+0x8>
    80005f22:	cb65                	beqz	a4,80006012 <virtio_disk_init+0x1da>
    80005f24:	c7fd                	beqz	a5,80006012 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f26:	6605                	lui	a2,0x1
    80005f28:	4581                	li	a1,0
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	da8080e7          	jalr	-600(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f32:	0001c497          	auipc	s1,0x1c
    80005f36:	d2e48493          	addi	s1,s1,-722 # 80021c60 <disk>
    80005f3a:	6605                	lui	a2,0x1
    80005f3c:	4581                	li	a1,0
    80005f3e:	6488                	ld	a0,8(s1)
    80005f40:	ffffb097          	auipc	ra,0xffffb
    80005f44:	d92080e7          	jalr	-622(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f48:	6605                	lui	a2,0x1
    80005f4a:	4581                	li	a1,0
    80005f4c:	6888                	ld	a0,16(s1)
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	d84080e7          	jalr	-636(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f56:	100017b7          	lui	a5,0x10001
    80005f5a:	4721                	li	a4,8
    80005f5c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f5e:	4098                	lw	a4,0(s1)
    80005f60:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f64:	40d8                	lw	a4,4(s1)
    80005f66:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f6a:	6498                	ld	a4,8(s1)
    80005f6c:	0007069b          	sext.w	a3,a4
    80005f70:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f74:	9701                	srai	a4,a4,0x20
    80005f76:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f7a:	6898                	ld	a4,16(s1)
    80005f7c:	0007069b          	sext.w	a3,a4
    80005f80:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f84:	9701                	srai	a4,a4,0x20
    80005f86:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f8a:	4705                	li	a4,1
    80005f8c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f8e:	00e48c23          	sb	a4,24(s1)
    80005f92:	00e48ca3          	sb	a4,25(s1)
    80005f96:	00e48d23          	sb	a4,26(s1)
    80005f9a:	00e48da3          	sb	a4,27(s1)
    80005f9e:	00e48e23          	sb	a4,28(s1)
    80005fa2:	00e48ea3          	sb	a4,29(s1)
    80005fa6:	00e48f23          	sb	a4,30(s1)
    80005faa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fae:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb2:	0727a823          	sw	s2,112(a5)
}
    80005fb6:	60e2                	ld	ra,24(sp)
    80005fb8:	6442                	ld	s0,16(sp)
    80005fba:	64a2                	ld	s1,8(sp)
    80005fbc:	6902                	ld	s2,0(sp)
    80005fbe:	6105                	addi	sp,sp,32
    80005fc0:	8082                	ret
    panic("could not find virtio disk");
    80005fc2:	00002517          	auipc	a0,0x2
    80005fc6:	7ee50513          	addi	a0,a0,2030 # 800087b0 <syscalls+0x360>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fd2:	00002517          	auipc	a0,0x2
    80005fd6:	7fe50513          	addi	a0,a0,2046 # 800087d0 <syscalls+0x380>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	80e50513          	addi	a0,a0,-2034 # 800087f0 <syscalls+0x3a0>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	81e50513          	addi	a0,a0,-2018 # 80008810 <syscalls+0x3c0>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	82e50513          	addi	a0,a0,-2002 # 80008830 <syscalls+0x3e0>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	83e50513          	addi	a0,a0,-1986 # 80008850 <syscalls+0x400>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>

0000000080006022 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006022:	7119                	addi	sp,sp,-128
    80006024:	fc86                	sd	ra,120(sp)
    80006026:	f8a2                	sd	s0,112(sp)
    80006028:	f4a6                	sd	s1,104(sp)
    8000602a:	f0ca                	sd	s2,96(sp)
    8000602c:	ecce                	sd	s3,88(sp)
    8000602e:	e8d2                	sd	s4,80(sp)
    80006030:	e4d6                	sd	s5,72(sp)
    80006032:	e0da                	sd	s6,64(sp)
    80006034:	fc5e                	sd	s7,56(sp)
    80006036:	f862                	sd	s8,48(sp)
    80006038:	f466                	sd	s9,40(sp)
    8000603a:	f06a                	sd	s10,32(sp)
    8000603c:	ec6e                	sd	s11,24(sp)
    8000603e:	0100                	addi	s0,sp,128
    80006040:	8aaa                	mv	s5,a0
    80006042:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006044:	00c52d03          	lw	s10,12(a0)
    80006048:	001d1d1b          	slliw	s10,s10,0x1
    8000604c:	1d02                	slli	s10,s10,0x20
    8000604e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006052:	0001c517          	auipc	a0,0x1c
    80006056:	d3650513          	addi	a0,a0,-714 # 80021d88 <disk+0x128>
    8000605a:	ffffb097          	auipc	ra,0xffffb
    8000605e:	b7c080e7          	jalr	-1156(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006062:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006064:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006066:	0001cb97          	auipc	s7,0x1c
    8000606a:	bfab8b93          	addi	s7,s7,-1030 # 80021c60 <disk>
  for(int i = 0; i < 3; i++){
    8000606e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006070:	0001cc97          	auipc	s9,0x1c
    80006074:	d18c8c93          	addi	s9,s9,-744 # 80021d88 <disk+0x128>
    80006078:	a08d                	j	800060da <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000607a:	00fb8733          	add	a4,s7,a5
    8000607e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006082:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006084:	0207c563          	bltz	a5,800060ae <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006088:	2905                	addiw	s2,s2,1
    8000608a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000608c:	05690c63          	beq	s2,s6,800060e4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006090:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006092:	0001c717          	auipc	a4,0x1c
    80006096:	bce70713          	addi	a4,a4,-1074 # 80021c60 <disk>
    8000609a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000609c:	01874683          	lbu	a3,24(a4)
    800060a0:	fee9                	bnez	a3,8000607a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060a2:	2785                	addiw	a5,a5,1
    800060a4:	0705                	addi	a4,a4,1
    800060a6:	fe979be3          	bne	a5,s1,8000609c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060aa:	57fd                	li	a5,-1
    800060ac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060ae:	01205d63          	blez	s2,800060c8 <virtio_disk_rw+0xa6>
    800060b2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060b4:	000a2503          	lw	a0,0(s4)
    800060b8:	00000097          	auipc	ra,0x0
    800060bc:	cfe080e7          	jalr	-770(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    800060c0:	2d85                	addiw	s11,s11,1
    800060c2:	0a11                	addi	s4,s4,4
    800060c4:	ff2d98e3          	bne	s11,s2,800060b4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060c8:	85e6                	mv	a1,s9
    800060ca:	0001c517          	auipc	a0,0x1c
    800060ce:	bae50513          	addi	a0,a0,-1106 # 80021c78 <disk+0x18>
    800060d2:	ffffc097          	auipc	ra,0xffffc
    800060d6:	f82080e7          	jalr	-126(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    800060da:	f8040a13          	addi	s4,s0,-128
{
    800060de:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060e0:	894e                	mv	s2,s3
    800060e2:	b77d                	j	80006090 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060e4:	f8042503          	lw	a0,-128(s0)
    800060e8:	00a50713          	addi	a4,a0,10
    800060ec:	0712                	slli	a4,a4,0x4

  if(write)
    800060ee:	0001c797          	auipc	a5,0x1c
    800060f2:	b7278793          	addi	a5,a5,-1166 # 80021c60 <disk>
    800060f6:	00e786b3          	add	a3,a5,a4
    800060fa:	01803633          	snez	a2,s8
    800060fe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006100:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006104:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006108:	f6070613          	addi	a2,a4,-160
    8000610c:	6394                	ld	a3,0(a5)
    8000610e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006110:	00870593          	addi	a1,a4,8
    80006114:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006116:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006118:	0007b803          	ld	a6,0(a5)
    8000611c:	9642                	add	a2,a2,a6
    8000611e:	46c1                	li	a3,16
    80006120:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006122:	4585                	li	a1,1
    80006124:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006128:	f8442683          	lw	a3,-124(s0)
    8000612c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006130:	0692                	slli	a3,a3,0x4
    80006132:	9836                	add	a6,a6,a3
    80006134:	058a8613          	addi	a2,s5,88
    80006138:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000613c:	0007b803          	ld	a6,0(a5)
    80006140:	96c2                	add	a3,a3,a6
    80006142:	40000613          	li	a2,1024
    80006146:	c690                	sw	a2,8(a3)
  if(write)
    80006148:	001c3613          	seqz	a2,s8
    8000614c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006150:	00166613          	ori	a2,a2,1
    80006154:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006158:	f8842603          	lw	a2,-120(s0)
    8000615c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006160:	00250693          	addi	a3,a0,2
    80006164:	0692                	slli	a3,a3,0x4
    80006166:	96be                	add	a3,a3,a5
    80006168:	58fd                	li	a7,-1
    8000616a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000616e:	0612                	slli	a2,a2,0x4
    80006170:	9832                	add	a6,a6,a2
    80006172:	f9070713          	addi	a4,a4,-112
    80006176:	973e                	add	a4,a4,a5
    80006178:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000617c:	6398                	ld	a4,0(a5)
    8000617e:	9732                	add	a4,a4,a2
    80006180:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006182:	4609                	li	a2,2
    80006184:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006188:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000618c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006190:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006194:	6794                	ld	a3,8(a5)
    80006196:	0026d703          	lhu	a4,2(a3)
    8000619a:	8b1d                	andi	a4,a4,7
    8000619c:	0706                	slli	a4,a4,0x1
    8000619e:	96ba                	add	a3,a3,a4
    800061a0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061a8:	6798                	ld	a4,8(a5)
    800061aa:	00275783          	lhu	a5,2(a4)
    800061ae:	2785                	addiw	a5,a5,1
    800061b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061b8:	100017b7          	lui	a5,0x10001
    800061bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061c0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800061c4:	0001c917          	auipc	s2,0x1c
    800061c8:	bc490913          	addi	s2,s2,-1084 # 80021d88 <disk+0x128>
  while(b->disk == 1) {
    800061cc:	4485                	li	s1,1
    800061ce:	00b79c63          	bne	a5,a1,800061e6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061d2:	85ca                	mv	a1,s2
    800061d4:	8556                	mv	a0,s5
    800061d6:	ffffc097          	auipc	ra,0xffffc
    800061da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    800061de:	004aa783          	lw	a5,4(s5)
    800061e2:	fe9788e3          	beq	a5,s1,800061d2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800061e6:	f8042903          	lw	s2,-128(s0)
    800061ea:	00290713          	addi	a4,s2,2
    800061ee:	0712                	slli	a4,a4,0x4
    800061f0:	0001c797          	auipc	a5,0x1c
    800061f4:	a7078793          	addi	a5,a5,-1424 # 80021c60 <disk>
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061fe:	0001c997          	auipc	s3,0x1c
    80006202:	a6298993          	addi	s3,s3,-1438 # 80021c60 <disk>
    80006206:	00491713          	slli	a4,s2,0x4
    8000620a:	0009b783          	ld	a5,0(s3)
    8000620e:	97ba                	add	a5,a5,a4
    80006210:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006214:	854a                	mv	a0,s2
    80006216:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000621a:	00000097          	auipc	ra,0x0
    8000621e:	b9c080e7          	jalr	-1124(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006222:	8885                	andi	s1,s1,1
    80006224:	f0ed                	bnez	s1,80006206 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006226:	0001c517          	auipc	a0,0x1c
    8000622a:	b6250513          	addi	a0,a0,-1182 # 80021d88 <disk+0x128>
    8000622e:	ffffb097          	auipc	ra,0xffffb
    80006232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>
}
    80006236:	70e6                	ld	ra,120(sp)
    80006238:	7446                	ld	s0,112(sp)
    8000623a:	74a6                	ld	s1,104(sp)
    8000623c:	7906                	ld	s2,96(sp)
    8000623e:	69e6                	ld	s3,88(sp)
    80006240:	6a46                	ld	s4,80(sp)
    80006242:	6aa6                	ld	s5,72(sp)
    80006244:	6b06                	ld	s6,64(sp)
    80006246:	7be2                	ld	s7,56(sp)
    80006248:	7c42                	ld	s8,48(sp)
    8000624a:	7ca2                	ld	s9,40(sp)
    8000624c:	7d02                	ld	s10,32(sp)
    8000624e:	6de2                	ld	s11,24(sp)
    80006250:	6109                	addi	sp,sp,128
    80006252:	8082                	ret

0000000080006254 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006254:	1101                	addi	sp,sp,-32
    80006256:	ec06                	sd	ra,24(sp)
    80006258:	e822                	sd	s0,16(sp)
    8000625a:	e426                	sd	s1,8(sp)
    8000625c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000625e:	0001c497          	auipc	s1,0x1c
    80006262:	a0248493          	addi	s1,s1,-1534 # 80021c60 <disk>
    80006266:	0001c517          	auipc	a0,0x1c
    8000626a:	b2250513          	addi	a0,a0,-1246 # 80021d88 <disk+0x128>
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	968080e7          	jalr	-1688(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006276:	10001737          	lui	a4,0x10001
    8000627a:	533c                	lw	a5,96(a4)
    8000627c:	8b8d                	andi	a5,a5,3
    8000627e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006280:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006284:	689c                	ld	a5,16(s1)
    80006286:	0204d703          	lhu	a4,32(s1)
    8000628a:	0027d783          	lhu	a5,2(a5)
    8000628e:	04f70863          	beq	a4,a5,800062de <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006292:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006296:	6898                	ld	a4,16(s1)
    80006298:	0204d783          	lhu	a5,32(s1)
    8000629c:	8b9d                	andi	a5,a5,7
    8000629e:	078e                	slli	a5,a5,0x3
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062a4:	00278713          	addi	a4,a5,2
    800062a8:	0712                	slli	a4,a4,0x4
    800062aa:	9726                	add	a4,a4,s1
    800062ac:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062b0:	e721                	bnez	a4,800062f8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062b2:	0789                	addi	a5,a5,2
    800062b4:	0792                	slli	a5,a5,0x4
    800062b6:	97a6                	add	a5,a5,s1
    800062b8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062ba:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062be:	ffffc097          	auipc	ra,0xffffc
    800062c2:	dfa080e7          	jalr	-518(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    800062c6:	0204d783          	lhu	a5,32(s1)
    800062ca:	2785                	addiw	a5,a5,1
    800062cc:	17c2                	slli	a5,a5,0x30
    800062ce:	93c1                	srli	a5,a5,0x30
    800062d0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062d4:	6898                	ld	a4,16(s1)
    800062d6:	00275703          	lhu	a4,2(a4)
    800062da:	faf71ce3          	bne	a4,a5,80006292 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062de:	0001c517          	auipc	a0,0x1c
    800062e2:	aaa50513          	addi	a0,a0,-1366 # 80021d88 <disk+0x128>
    800062e6:	ffffb097          	auipc	ra,0xffffb
    800062ea:	9a4080e7          	jalr	-1628(ra) # 80000c8a <release>
}
    800062ee:	60e2                	ld	ra,24(sp)
    800062f0:	6442                	ld	s0,16(sp)
    800062f2:	64a2                	ld	s1,8(sp)
    800062f4:	6105                	addi	sp,sp,32
    800062f6:	8082                	ret
      panic("virtio_disk_intr status");
    800062f8:	00002517          	auipc	a0,0x2
    800062fc:	57050513          	addi	a0,a0,1392 # 80008868 <syscalls+0x418>
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	240080e7          	jalr	576(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
