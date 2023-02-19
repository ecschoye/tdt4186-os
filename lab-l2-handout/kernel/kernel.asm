
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9b013103          	ld	sp,-1616(sp) # 800089b0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	9c070713          	addi	a4,a4,-1600 # 80008a10 <timer_scratch>
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
    80000066:	e4e78793          	addi	a5,a5,-434 # 80005eb0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc97f>
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
int consolewrite(int user_src, uint64 src, int n)
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

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	526080e7          	jalr	1318(ra) # 80002650 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
    for (i = 0; i < n; i++)
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
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
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
    8000018e:	9c650513          	addi	a0,a0,-1594 # 80010b50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9b648493          	addi	s1,s1,-1610 # 80010b50 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a4690913          	addi	s2,s2,-1466 # 80010be8 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001aa:	4b91                	li	s7,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001ae:	4ca9                	li	s9,10
    while (n > 0)
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
        while (cons.r == cons.w)
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
            if (killed(myproc()))
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	8ca080e7          	jalr	-1846(ra) # 80001a8a <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2d2080e7          	jalr	722(ra) # 8000249a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	01c080e7          	jalr	28(ra) # 800021f2 <sleep>
        while (cons.r == cons.w)
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
        if (c == C('D'))
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
        cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	3e8080e7          	jalr	1000(ra) # 800025fa <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1
        if (c == '\n')
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	92a50513          	addi	a0,a0,-1750 # 80010b50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	91450513          	addi	a0,a0,-1772 # 80010b50 <cons>
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
            if (n < target)
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
                cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	96f72b23          	sw	a5,-1674(a4) # 80010be8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
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
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	88450513          	addi	a0,a0,-1916 # 80010b50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

    switch (c)
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3b4080e7          	jalr	948(ra) # 800026a6 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	85650513          	addi	a0,a0,-1962 # 80010b50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
    switch (c)
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	83270713          	addi	a4,a4,-1998 # 80010b50 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	80878793          	addi	a5,a5,-2040 # 80010b50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8727a783          	lw	a5,-1934(a5) # 80010be8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	7c670713          	addi	a4,a4,1990 # 80010b50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7b648493          	addi	s1,s1,1974 # 80010b50 <cons>
        while (cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
            cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
        while (cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	77a70713          	addi	a4,a4,1914 # 80010b50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	80f72223          	sw	a5,-2044(a4) # 80010bf0 <cons+0xa0>
            consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
            consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	73e78793          	addi	a5,a5,1854 # 80010b50 <cons>
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
    8000043a:	7ac7ab23          	sw	a2,1974(a5) # 80010bec <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7aa50513          	addi	a0,a0,1962 # 80010be8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e10080e7          	jalr	-496(ra) # 80002256 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	6f050513          	addi	a0,a0,1776 # 80010b50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	87078793          	addi	a5,a5,-1936 # 80020ce8 <devsw>
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
    80000550:	6c07a223          	sw	zero,1732(a5) # 80010c10 <pr+0x18>
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
    80000584:	44f72823          	sw	a5,1104(a4) # 800089d0 <panicked>
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
    800005c0:	654dad83          	lw	s11,1620(s11) # 80010c10 <pr+0x18>
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
    800005fe:	5fe50513          	addi	a0,a0,1534 # 80010bf8 <pr>
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
    8000075c:	4a050513          	addi	a0,a0,1184 # 80010bf8 <pr>
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
    80000778:	48448493          	addi	s1,s1,1156 # 80010bf8 <pr>
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
    800007d8:	44450513          	addi	a0,a0,1092 # 80010c18 <uart_tx_lock>
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
    80000804:	1d07a783          	lw	a5,464(a5) # 800089d0 <panicked>
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
    8000083c:	1a07b783          	ld	a5,416(a5) # 800089d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	1a073703          	ld	a4,416(a4) # 800089e0 <uart_tx_w>
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
    80000866:	3b6a0a13          	addi	s4,s4,950 # 80010c18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	16e48493          	addi	s1,s1,366 # 800089d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	16e98993          	addi	s3,s3,366 # 800089e0 <uart_tx_w>
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
    80000898:	9c2080e7          	jalr	-1598(ra) # 80002256 <wakeup>
    
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
    800008d4:	34850513          	addi	a0,a0,840 # 80010c18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0f07a783          	lw	a5,240(a5) # 800089d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	0f673703          	ld	a4,246(a4) # 800089e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0e67b783          	ld	a5,230(a5) # 800089d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	31a98993          	addi	s3,s3,794 # 80010c18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	0d248493          	addi	s1,s1,210 # 800089d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	0d290913          	addi	s2,s2,210 # 800089e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	8d4080e7          	jalr	-1836(ra) # 800021f2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	2e448493          	addi	s1,s1,740 # 80010c18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	08e7bc23          	sd	a4,152(a5) # 800089e0 <uart_tx_w>
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
    800009be:	25e48493          	addi	s1,s1,606 # 80010c18 <uart_tx_lock>
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
    80000a00:	48478793          	addi	a5,a5,1156 # 80021e80 <end>
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
    80000a20:	23490913          	addi	s2,s2,564 # 80010c50 <kmem>
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
    80000abe:	19650513          	addi	a0,a0,406 # 80010c50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	3b250513          	addi	a0,a0,946 # 80021e80 <end>
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
    80000af4:	16048493          	addi	s1,s1,352 # 80010c50 <kmem>
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
    80000b0c:	14850513          	addi	a0,a0,328 # 80010c50 <kmem>
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
    80000b38:	11c50513          	addi	a0,a0,284 # 80010c50 <kmem>
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
    80000b74:	efe080e7          	jalr	-258(ra) # 80001a6e <mycpu>
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
    80000ba6:	ecc080e7          	jalr	-308(ra) # 80001a6e <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	ec0080e7          	jalr	-320(ra) # 80001a6e <mycpu>
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
    80000bca:	ea8080e7          	jalr	-344(ra) # 80001a6e <mycpu>
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
    80000c0a:	e68080e7          	jalr	-408(ra) # 80001a6e <mycpu>
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
    80000c36:	e3c080e7          	jalr	-452(ra) # 80001a6e <mycpu>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd181>
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
    80000e84:	bde080e7          	jalr	-1058(ra) # 80001a5e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	b6070713          	addi	a4,a4,-1184 # 800089e8 <started>
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
    80000ea0:	bc2080e7          	jalr	-1086(ra) # 80001a5e <cpuid>
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
    80000ec2:	a0c080e7          	jalr	-1524(ra) # 800028ca <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	02a080e7          	jalr	42(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	202080e7          	jalr	514(ra) # 800020d0 <scheduler>
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
    80000f32:	a4e080e7          	jalr	-1458(ra) # 8000197c <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	96c080e7          	jalr	-1684(ra) # 800028a2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	98c080e7          	jalr	-1652(ra) # 800028ca <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	f94080e7          	jalr	-108(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	fa2080e7          	jalr	-94(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	140080e7          	jalr	320(ra) # 80003096 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	7e0080e7          	jalr	2016(ra) # 8000373e <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	786080e7          	jalr	1926(ra) # 800046ec <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	08a080e7          	jalr	138(ra) # 80005ff8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	dec080e7          	jalr	-532(ra) # 80001d62 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	a6f72223          	sw	a5,-1436(a4) # 800089e8 <started>
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
    80000f9c:	a587b783          	ld	a5,-1448(a5) # 800089f0 <kernel_pagetable>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd177>
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
    80001232:	6b8080e7          	jalr	1720(ra) # 800018e6 <proc_mapstacks>
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
    80001258:	78a7be23          	sd	a0,1948(a5) # 800089f0 <kernel_pagetable>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd180>
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

0000000080001836 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
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
  asm volatile("mv %0, tp" : "=r" (x) );
    8000184a:	8792                	mv	a5,tp
    int id = r_tp();
    8000184c:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    8000184e:	0000fa97          	auipc	s5,0xf
    80001852:	422a8a93          	addi	s5,s5,1058 # 80010c70 <cpus>
    80001856:	00779713          	slli	a4,a5,0x7
    8000185a:	00ea86b3          	add	a3,s5,a4
    8000185e:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdd180>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001862:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001866:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000186a:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    8000186e:	0721                	addi	a4,a4,8
    80001870:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    80001872:	00010497          	auipc	s1,0x10
    80001876:	82e48493          	addi	s1,s1,-2002 # 800110a0 <proc>
        if (p->state == RUNNABLE)
    8000187a:	498d                	li	s3,3
            p->state = RUNNING;
    8000187c:	4b11                	li	s6,4
            c->proc = p;
    8000187e:	079e                	slli	a5,a5,0x7
    80001880:	0000fa17          	auipc	s4,0xf
    80001884:	3f0a0a13          	addi	s4,s4,1008 # 80010c70 <cpus>
    80001888:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000188a:	00015917          	auipc	s2,0x15
    8000188e:	21690913          	addi	s2,s2,534 # 80016aa0 <tickslock>
    80001892:	a811                	j	800018a6 <rr_scheduler+0x70>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
        }
        release(&p->lock);
    80001894:	8526                	mv	a0,s1
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	3f4080e7          	jalr	1012(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000189e:	16848493          	addi	s1,s1,360
    800018a2:	03248863          	beq	s1,s2,800018d2 <rr_scheduler+0x9c>
        acquire(&p->lock);
    800018a6:	8526                	mv	a0,s1
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	32e080e7          	jalr	814(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    800018b0:	4c9c                	lw	a5,24(s1)
    800018b2:	ff3791e3          	bne	a5,s3,80001894 <rr_scheduler+0x5e>
            p->state = RUNNING;
    800018b6:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800018ba:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800018be:	06048593          	addi	a1,s1,96
    800018c2:	8556                	mv	a0,s5
    800018c4:	00001097          	auipc	ra,0x1
    800018c8:	f74080e7          	jalr	-140(ra) # 80002838 <swtch>
            c->proc = 0;
    800018cc:	000a3023          	sd	zero,0(s4)
    800018d0:	b7d1                	j	80001894 <rr_scheduler+0x5e>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800018d2:	70e2                	ld	ra,56(sp)
    800018d4:	7442                	ld	s0,48(sp)
    800018d6:	74a2                	ld	s1,40(sp)
    800018d8:	7902                	ld	s2,32(sp)
    800018da:	69e2                	ld	s3,24(sp)
    800018dc:	6a42                	ld	s4,16(sp)
    800018de:	6aa2                	ld	s5,8(sp)
    800018e0:	6b02                	ld	s6,0(sp)
    800018e2:	6121                	addi	sp,sp,64
    800018e4:	8082                	ret

00000000800018e6 <proc_mapstacks>:
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
    800018fa:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    800018fc:	0000f497          	auipc	s1,0xf
    80001900:	7a448493          	addi	s1,s1,1956 # 800110a0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001904:	8b26                	mv	s6,s1
    80001906:	00006a97          	auipc	s5,0x6
    8000190a:	6faa8a93          	addi	s5,s5,1786 # 80008000 <etext>
    8000190e:	04000937          	lui	s2,0x4000
    80001912:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001914:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001916:	00015a17          	auipc	s4,0x15
    8000191a:	18aa0a13          	addi	s4,s4,394 # 80016aa0 <tickslock>
        char *pa = kalloc();
    8000191e:	fffff097          	auipc	ra,0xfffff
    80001922:	1c8080e7          	jalr	456(ra) # 80000ae6 <kalloc>
    80001926:	862a                	mv	a2,a0
        if (pa == 0)
    80001928:	c131                	beqz	a0,8000196c <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    8000192a:	416485b3          	sub	a1,s1,s6
    8000192e:	858d                	srai	a1,a1,0x3
    80001930:	000ab783          	ld	a5,0(s5)
    80001934:	02f585b3          	mul	a1,a1,a5
    80001938:	2585                	addiw	a1,a1,1
    8000193a:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000193e:	4719                	li	a4,6
    80001940:	6685                	lui	a3,0x1
    80001942:	40b905b3          	sub	a1,s2,a1
    80001946:	854e                	mv	a0,s3
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	7f6080e7          	jalr	2038(ra) # 8000113e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001950:	16848493          	addi	s1,s1,360
    80001954:	fd4495e3          	bne	s1,s4,8000191e <proc_mapstacks+0x38>
}
    80001958:	70e2                	ld	ra,56(sp)
    8000195a:	7442                	ld	s0,48(sp)
    8000195c:	74a2                	ld	s1,40(sp)
    8000195e:	7902                	ld	s2,32(sp)
    80001960:	69e2                	ld	s3,24(sp)
    80001962:	6a42                	ld	s4,16(sp)
    80001964:	6aa2                	ld	s5,8(sp)
    80001966:	6b02                	ld	s6,0(sp)
    80001968:	6121                	addi	sp,sp,64
    8000196a:	8082                	ret
            panic("kalloc");
    8000196c:	00007517          	auipc	a0,0x7
    80001970:	86c50513          	addi	a0,a0,-1940 # 800081d8 <digits+0x198>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	bcc080e7          	jalr	-1076(ra) # 80000540 <panic>

000000008000197c <procinit>:
{
    8000197c:	7139                	addi	sp,sp,-64
    8000197e:	fc06                	sd	ra,56(sp)
    80001980:	f822                	sd	s0,48(sp)
    80001982:	f426                	sd	s1,40(sp)
    80001984:	f04a                	sd	s2,32(sp)
    80001986:	ec4e                	sd	s3,24(sp)
    80001988:	e852                	sd	s4,16(sp)
    8000198a:	e456                	sd	s5,8(sp)
    8000198c:	e05a                	sd	s6,0(sp)
    8000198e:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001990:	00007597          	auipc	a1,0x7
    80001994:	85058593          	addi	a1,a1,-1968 # 800081e0 <digits+0x1a0>
    80001998:	0000f517          	auipc	a0,0xf
    8000199c:	6d850513          	addi	a0,a0,1752 # 80011070 <pid_lock>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1a6080e7          	jalr	422(ra) # 80000b46 <initlock>
    initlock(&wait_lock, "wait_lock");
    800019a8:	00007597          	auipc	a1,0x7
    800019ac:	84058593          	addi	a1,a1,-1984 # 800081e8 <digits+0x1a8>
    800019b0:	0000f517          	auipc	a0,0xf
    800019b4:	6d850513          	addi	a0,a0,1752 # 80011088 <wait_lock>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	18e080e7          	jalr	398(ra) # 80000b46 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    800019c0:	0000f497          	auipc	s1,0xf
    800019c4:	6e048493          	addi	s1,s1,1760 # 800110a0 <proc>
        initlock(&p->lock, "proc");
    800019c8:	00007b17          	auipc	s6,0x7
    800019cc:	830b0b13          	addi	s6,s6,-2000 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int)(p - proc));
    800019d0:	8aa6                	mv	s5,s1
    800019d2:	00006a17          	auipc	s4,0x6
    800019d6:	62ea0a13          	addi	s4,s4,1582 # 80008000 <etext>
    800019da:	04000937          	lui	s2,0x4000
    800019de:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019e0:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    800019e2:	00015997          	auipc	s3,0x15
    800019e6:	0be98993          	addi	s3,s3,190 # 80016aa0 <tickslock>
        initlock(&p->lock, "proc");
    800019ea:	85da                	mv	a1,s6
    800019ec:	8526                	mv	a0,s1
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	158080e7          	jalr	344(ra) # 80000b46 <initlock>
        p->state = UNUSED;
    800019f6:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    800019fa:	415487b3          	sub	a5,s1,s5
    800019fe:	878d                	srai	a5,a5,0x3
    80001a00:	000a3703          	ld	a4,0(s4)
    80001a04:	02e787b3          	mul	a5,a5,a4
    80001a08:	2785                	addiw	a5,a5,1
    80001a0a:	00d7979b          	slliw	a5,a5,0xd
    80001a0e:	40f907b3          	sub	a5,s2,a5
    80001a12:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001a14:	16848493          	addi	s1,s1,360
    80001a18:	fd3499e3          	bne	s1,s3,800019ea <procinit+0x6e>
}
    80001a1c:	70e2                	ld	ra,56(sp)
    80001a1e:	7442                	ld	s0,48(sp)
    80001a20:	74a2                	ld	s1,40(sp)
    80001a22:	7902                	ld	s2,32(sp)
    80001a24:	69e2                	ld	s3,24(sp)
    80001a26:	6a42                	ld	s4,16(sp)
    80001a28:	6aa2                	ld	s5,8(sp)
    80001a2a:	6b02                	ld	s6,0(sp)
    80001a2c:	6121                	addi	sp,sp,64
    80001a2e:	8082                	ret

0000000080001a30 <copy_array>:
{
    80001a30:	1141                	addi	sp,sp,-16
    80001a32:	e422                	sd	s0,8(sp)
    80001a34:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001a36:	02c05163          	blez	a2,80001a58 <copy_array+0x28>
    80001a3a:	87aa                	mv	a5,a0
    80001a3c:	0505                	addi	a0,a0,1
    80001a3e:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001a40:	1602                	slli	a2,a2,0x20
    80001a42:	9201                	srli	a2,a2,0x20
    80001a44:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001a48:	0007c703          	lbu	a4,0(a5)
    80001a4c:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001a50:	0785                	addi	a5,a5,1
    80001a52:	0585                	addi	a1,a1,1
    80001a54:	fed79ae3          	bne	a5,a3,80001a48 <copy_array+0x18>
}
    80001a58:	6422                	ld	s0,8(sp)
    80001a5a:	0141                	addi	sp,sp,16
    80001a5c:	8082                	ret

0000000080001a5e <cpuid>:
{
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e422                	sd	s0,8(sp)
    80001a62:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a64:	8512                	mv	a0,tp
}
    80001a66:	2501                	sext.w	a0,a0
    80001a68:	6422                	ld	s0,8(sp)
    80001a6a:	0141                	addi	sp,sp,16
    80001a6c:	8082                	ret

0000000080001a6e <mycpu>:
{
    80001a6e:	1141                	addi	sp,sp,-16
    80001a70:	e422                	sd	s0,8(sp)
    80001a72:	0800                	addi	s0,sp,16
    80001a74:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001a76:	2781                	sext.w	a5,a5
    80001a78:	079e                	slli	a5,a5,0x7
}
    80001a7a:	0000f517          	auipc	a0,0xf
    80001a7e:	1f650513          	addi	a0,a0,502 # 80010c70 <cpus>
    80001a82:	953e                	add	a0,a0,a5
    80001a84:	6422                	ld	s0,8(sp)
    80001a86:	0141                	addi	sp,sp,16
    80001a88:	8082                	ret

0000000080001a8a <myproc>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	1000                	addi	s0,sp,32
    push_off();
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	0f6080e7          	jalr	246(ra) # 80000b8a <push_off>
    80001a9c:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001a9e:	2781                	sext.w	a5,a5
    80001aa0:	079e                	slli	a5,a5,0x7
    80001aa2:	0000f717          	auipc	a4,0xf
    80001aa6:	1ce70713          	addi	a4,a4,462 # 80010c70 <cpus>
    80001aaa:	97ba                	add	a5,a5,a4
    80001aac:	6384                	ld	s1,0(a5)
    pop_off();
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	17c080e7          	jalr	380(ra) # 80000c2a <pop_off>
}
    80001ab6:	8526                	mv	a0,s1
    80001ab8:	60e2                	ld	ra,24(sp)
    80001aba:	6442                	ld	s0,16(sp)
    80001abc:	64a2                	ld	s1,8(sp)
    80001abe:	6105                	addi	sp,sp,32
    80001ac0:	8082                	ret

0000000080001ac2 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ac2:	1141                	addi	sp,sp,-16
    80001ac4:	e406                	sd	ra,8(sp)
    80001ac6:	e022                	sd	s0,0(sp)
    80001ac8:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001aca:	00000097          	auipc	ra,0x0
    80001ace:	fc0080e7          	jalr	-64(ra) # 80001a8a <myproc>
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	1b8080e7          	jalr	440(ra) # 80000c8a <release>

    if (first)
    80001ada:	00007797          	auipc	a5,0x7
    80001ade:	e567a783          	lw	a5,-426(a5) # 80008930 <first.1>
    80001ae2:	eb89                	bnez	a5,80001af4 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001ae4:	00001097          	auipc	ra,0x1
    80001ae8:	dfe080e7          	jalr	-514(ra) # 800028e2 <usertrapret>
}
    80001aec:	60a2                	ld	ra,8(sp)
    80001aee:	6402                	ld	s0,0(sp)
    80001af0:	0141                	addi	sp,sp,16
    80001af2:	8082                	ret
        first = 0;
    80001af4:	00007797          	auipc	a5,0x7
    80001af8:	e207ae23          	sw	zero,-452(a5) # 80008930 <first.1>
        fsinit(ROOTDEV);
    80001afc:	4505                	li	a0,1
    80001afe:	00002097          	auipc	ra,0x2
    80001b02:	bc0080e7          	jalr	-1088(ra) # 800036be <fsinit>
    80001b06:	bff9                	j	80001ae4 <forkret+0x22>

0000000080001b08 <allocpid>:
{
    80001b08:	1101                	addi	sp,sp,-32
    80001b0a:	ec06                	sd	ra,24(sp)
    80001b0c:	e822                	sd	s0,16(sp)
    80001b0e:	e426                	sd	s1,8(sp)
    80001b10:	e04a                	sd	s2,0(sp)
    80001b12:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001b14:	0000f917          	auipc	s2,0xf
    80001b18:	55c90913          	addi	s2,s2,1372 # 80011070 <pid_lock>
    80001b1c:	854a                	mv	a0,s2
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	0b8080e7          	jalr	184(ra) # 80000bd6 <acquire>
    pid = nextpid;
    80001b26:	00007797          	auipc	a5,0x7
    80001b2a:	e1a78793          	addi	a5,a5,-486 # 80008940 <nextpid>
    80001b2e:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001b30:	0014871b          	addiw	a4,s1,1
    80001b34:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001b36:	854a                	mv	a0,s2
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	152080e7          	jalr	338(ra) # 80000c8a <release>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret

0000000080001b4e <proc_pagetable>:
{
    80001b4e:	1101                	addi	sp,sp,-32
    80001b50:	ec06                	sd	ra,24(sp)
    80001b52:	e822                	sd	s0,16(sp)
    80001b54:	e426                	sd	s1,8(sp)
    80001b56:	e04a                	sd	s2,0(sp)
    80001b58:	1000                	addi	s0,sp,32
    80001b5a:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	7cc080e7          	jalr	1996(ra) # 80001328 <uvmcreate>
    80001b64:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001b66:	c121                	beqz	a0,80001ba6 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b68:	4729                	li	a4,10
    80001b6a:	00005697          	auipc	a3,0x5
    80001b6e:	49668693          	addi	a3,a3,1174 # 80007000 <_trampoline>
    80001b72:	6605                	lui	a2,0x1
    80001b74:	040005b7          	lui	a1,0x4000
    80001b78:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b7a:	05b2                	slli	a1,a1,0xc
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	522080e7          	jalr	1314(ra) # 8000109e <mappages>
    80001b84:	02054863          	bltz	a0,80001bb4 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b88:	4719                	li	a4,6
    80001b8a:	05893683          	ld	a3,88(s2)
    80001b8e:	6605                	lui	a2,0x1
    80001b90:	020005b7          	lui	a1,0x2000
    80001b94:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b96:	05b6                	slli	a1,a1,0xd
    80001b98:	8526                	mv	a0,s1
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	504080e7          	jalr	1284(ra) # 8000109e <mappages>
    80001ba2:	02054163          	bltz	a0,80001bc4 <proc_pagetable+0x76>
}
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret
        uvmfree(pagetable, 0);
    80001bb4:	4581                	li	a1,0
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	976080e7          	jalr	-1674(ra) # 8000152e <uvmfree>
        return 0;
    80001bc0:	4481                	li	s1,0
    80001bc2:	b7d5                	j	80001ba6 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bc4:	4681                	li	a3,0
    80001bc6:	4605                	li	a2,1
    80001bc8:	040005b7          	lui	a1,0x4000
    80001bcc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bce:	05b2                	slli	a1,a1,0xc
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	692080e7          	jalr	1682(ra) # 80001264 <uvmunmap>
        uvmfree(pagetable, 0);
    80001bda:	4581                	li	a1,0
    80001bdc:	8526                	mv	a0,s1
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	950080e7          	jalr	-1712(ra) # 8000152e <uvmfree>
        return 0;
    80001be6:	4481                	li	s1,0
    80001be8:	bf7d                	j	80001ba6 <proc_pagetable+0x58>

0000000080001bea <proc_freepagetable>:
{
    80001bea:	1101                	addi	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	e04a                	sd	s2,0(sp)
    80001bf4:	1000                	addi	s0,sp,32
    80001bf6:	84aa                	mv	s1,a0
    80001bf8:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bfa:	4681                	li	a3,0
    80001bfc:	4605                	li	a2,1
    80001bfe:	040005b7          	lui	a1,0x4000
    80001c02:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c04:	05b2                	slli	a1,a1,0xc
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	65e080e7          	jalr	1630(ra) # 80001264 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c0e:	4681                	li	a3,0
    80001c10:	4605                	li	a2,1
    80001c12:	020005b7          	lui	a1,0x2000
    80001c16:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c18:	05b6                	slli	a1,a1,0xd
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	648080e7          	jalr	1608(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, sz);
    80001c24:	85ca                	mv	a1,s2
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	906080e7          	jalr	-1786(ra) # 8000152e <uvmfree>
}
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret

0000000080001c3c <freeproc>:
{
    80001c3c:	1101                	addi	sp,sp,-32
    80001c3e:	ec06                	sd	ra,24(sp)
    80001c40:	e822                	sd	s0,16(sp)
    80001c42:	e426                	sd	s1,8(sp)
    80001c44:	1000                	addi	s0,sp,32
    80001c46:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001c48:	6d28                	ld	a0,88(a0)
    80001c4a:	c509                	beqz	a0,80001c54 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	d9c080e7          	jalr	-612(ra) # 800009e8 <kfree>
    p->trapframe = 0;
    80001c54:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001c58:	68a8                	ld	a0,80(s1)
    80001c5a:	c511                	beqz	a0,80001c66 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001c5c:	64ac                	ld	a1,72(s1)
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	f8c080e7          	jalr	-116(ra) # 80001bea <proc_freepagetable>
    p->pagetable = 0;
    80001c66:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001c6a:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001c6e:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001c72:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001c76:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001c7a:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001c7e:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001c82:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001c86:	0004ac23          	sw	zero,24(s1)
}
    80001c8a:	60e2                	ld	ra,24(sp)
    80001c8c:	6442                	ld	s0,16(sp)
    80001c8e:	64a2                	ld	s1,8(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret

0000000080001c94 <allocproc>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	e04a                	sd	s2,0(sp)
    80001c9e:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001ca0:	0000f497          	auipc	s1,0xf
    80001ca4:	40048493          	addi	s1,s1,1024 # 800110a0 <proc>
    80001ca8:	00015917          	auipc	s2,0x15
    80001cac:	df890913          	addi	s2,s2,-520 # 80016aa0 <tickslock>
        acquire(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	f24080e7          	jalr	-220(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80001cba:	4c9c                	lw	a5,24(s1)
    80001cbc:	cf81                	beqz	a5,80001cd4 <allocproc+0x40>
            release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fca080e7          	jalr	-54(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001cc8:	16848493          	addi	s1,s1,360
    80001ccc:	ff2492e3          	bne	s1,s2,80001cb0 <allocproc+0x1c>
    return 0;
    80001cd0:	4481                	li	s1,0
    80001cd2:	a889                	j	80001d24 <allocproc+0x90>
    p->pid = allocpid();
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	e34080e7          	jalr	-460(ra) # 80001b08 <allocpid>
    80001cdc:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001cde:	4785                	li	a5,1
    80001ce0:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	e04080e7          	jalr	-508(ra) # 80000ae6 <kalloc>
    80001cea:	892a                	mv	s2,a0
    80001cec:	eca8                	sd	a0,88(s1)
    80001cee:	c131                	beqz	a0,80001d32 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	00000097          	auipc	ra,0x0
    80001cf6:	e5c080e7          	jalr	-420(ra) # 80001b4e <proc_pagetable>
    80001cfa:	892a                	mv	s2,a0
    80001cfc:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001cfe:	c531                	beqz	a0,80001d4a <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001d00:	07000613          	li	a2,112
    80001d04:	4581                	li	a1,0
    80001d06:	06048513          	addi	a0,s1,96
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	fc8080e7          	jalr	-56(ra) # 80000cd2 <memset>
    p->context.ra = (uint64)forkret;
    80001d12:	00000797          	auipc	a5,0x0
    80001d16:	db078793          	addi	a5,a5,-592 # 80001ac2 <forkret>
    80001d1a:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001d1c:	60bc                	ld	a5,64(s1)
    80001d1e:	6705                	lui	a4,0x1
    80001d20:	97ba                	add	a5,a5,a4
    80001d22:	f4bc                	sd	a5,104(s1)
}
    80001d24:	8526                	mv	a0,s1
    80001d26:	60e2                	ld	ra,24(sp)
    80001d28:	6442                	ld	s0,16(sp)
    80001d2a:	64a2                	ld	s1,8(sp)
    80001d2c:	6902                	ld	s2,0(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret
        freeproc(p);
    80001d32:	8526                	mv	a0,s1
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f08080e7          	jalr	-248(ra) # 80001c3c <freeproc>
        release(&p->lock);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	f4c080e7          	jalr	-180(ra) # 80000c8a <release>
        return 0;
    80001d46:	84ca                	mv	s1,s2
    80001d48:	bff1                	j	80001d24 <allocproc+0x90>
        freeproc(p);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	ef0080e7          	jalr	-272(ra) # 80001c3c <freeproc>
        release(&p->lock);
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f34080e7          	jalr	-204(ra) # 80000c8a <release>
        return 0;
    80001d5e:	84ca                	mv	s1,s2
    80001d60:	b7d1                	j	80001d24 <allocproc+0x90>

0000000080001d62 <userinit>:
{
    80001d62:	1101                	addi	sp,sp,-32
    80001d64:	ec06                	sd	ra,24(sp)
    80001d66:	e822                	sd	s0,16(sp)
    80001d68:	e426                	sd	s1,8(sp)
    80001d6a:	1000                	addi	s0,sp,32
    p = allocproc();
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	f28080e7          	jalr	-216(ra) # 80001c94 <allocproc>
    80001d74:	84aa                	mv	s1,a0
    initproc = p;
    80001d76:	00007797          	auipc	a5,0x7
    80001d7a:	c8a7b123          	sd	a0,-894(a5) # 800089f8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d7e:	03400613          	li	a2,52
    80001d82:	00007597          	auipc	a1,0x7
    80001d86:	bce58593          	addi	a1,a1,-1074 # 80008950 <initcode>
    80001d8a:	6928                	ld	a0,80(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	5ca080e7          	jalr	1482(ra) # 80001356 <uvmfirst>
    p->sz = PGSIZE;
    80001d94:	6785                	lui	a5,0x1
    80001d96:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001d98:	6cb8                	ld	a4,88(s1)
    80001d9a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001d9e:	6cb8                	ld	a4,88(s1)
    80001da0:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001da2:	4641                	li	a2,16
    80001da4:	00006597          	auipc	a1,0x6
    80001da8:	45c58593          	addi	a1,a1,1116 # 80008200 <digits+0x1c0>
    80001dac:	15848513          	addi	a0,s1,344
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	06c080e7          	jalr	108(ra) # 80000e1c <safestrcpy>
    p->cwd = namei("/");
    80001db8:	00006517          	auipc	a0,0x6
    80001dbc:	45850513          	addi	a0,a0,1112 # 80008210 <digits+0x1d0>
    80001dc0:	00002097          	auipc	ra,0x2
    80001dc4:	328080e7          	jalr	808(ra) # 800040e8 <namei>
    80001dc8:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001dcc:	478d                	li	a5,3
    80001dce:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001dd0:	8526                	mv	a0,s1
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	eb8080e7          	jalr	-328(ra) # 80000c8a <release>
}
    80001dda:	60e2                	ld	ra,24(sp)
    80001ddc:	6442                	ld	s0,16(sp)
    80001dde:	64a2                	ld	s1,8(sp)
    80001de0:	6105                	addi	sp,sp,32
    80001de2:	8082                	ret

0000000080001de4 <growproc>:
{
    80001de4:	1101                	addi	sp,sp,-32
    80001de6:	ec06                	sd	ra,24(sp)
    80001de8:	e822                	sd	s0,16(sp)
    80001dea:	e426                	sd	s1,8(sp)
    80001dec:	e04a                	sd	s2,0(sp)
    80001dee:	1000                	addi	s0,sp,32
    80001df0:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	c98080e7          	jalr	-872(ra) # 80001a8a <myproc>
    80001dfa:	84aa                	mv	s1,a0
    sz = p->sz;
    80001dfc:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001dfe:	01204c63          	bgtz	s2,80001e16 <growproc+0x32>
    else if (n < 0)
    80001e02:	02094663          	bltz	s2,80001e2e <growproc+0x4a>
    p->sz = sz;
    80001e06:	e4ac                	sd	a1,72(s1)
    return 0;
    80001e08:	4501                	li	a0,0
}
    80001e0a:	60e2                	ld	ra,24(sp)
    80001e0c:	6442                	ld	s0,16(sp)
    80001e0e:	64a2                	ld	s1,8(sp)
    80001e10:	6902                	ld	s2,0(sp)
    80001e12:	6105                	addi	sp,sp,32
    80001e14:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e16:	4691                	li	a3,4
    80001e18:	00b90633          	add	a2,s2,a1
    80001e1c:	6928                	ld	a0,80(a0)
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	5f2080e7          	jalr	1522(ra) # 80001410 <uvmalloc>
    80001e26:	85aa                	mv	a1,a0
    80001e28:	fd79                	bnez	a0,80001e06 <growproc+0x22>
            return -1;
    80001e2a:	557d                	li	a0,-1
    80001e2c:	bff9                	j	80001e0a <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e2e:	00b90633          	add	a2,s2,a1
    80001e32:	6928                	ld	a0,80(a0)
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	594080e7          	jalr	1428(ra) # 800013c8 <uvmdealloc>
    80001e3c:	85aa                	mv	a1,a0
    80001e3e:	b7e1                	j	80001e06 <growproc+0x22>

0000000080001e40 <ps>:
{
    80001e40:	715d                	addi	sp,sp,-80
    80001e42:	e486                	sd	ra,72(sp)
    80001e44:	e0a2                	sd	s0,64(sp)
    80001e46:	fc26                	sd	s1,56(sp)
    80001e48:	f84a                	sd	s2,48(sp)
    80001e4a:	f44e                	sd	s3,40(sp)
    80001e4c:	f052                	sd	s4,32(sp)
    80001e4e:	ec56                	sd	s5,24(sp)
    80001e50:	e85a                	sd	s6,16(sp)
    80001e52:	e45e                	sd	s7,8(sp)
    80001e54:	e062                	sd	s8,0(sp)
    80001e56:	0880                	addi	s0,sp,80
    80001e58:	84aa                	mv	s1,a0
    80001e5a:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001e5c:	00000097          	auipc	ra,0x0
    80001e60:	c2e080e7          	jalr	-978(ra) # 80001a8a <myproc>
    if (count == 0)
    80001e64:	120b8063          	beqz	s7,80001f84 <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001e68:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001e6c:	003b951b          	slliw	a0,s7,0x3
    80001e70:	0175053b          	addw	a0,a0,s7
    80001e74:	0025151b          	slliw	a0,a0,0x2
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	f6c080e7          	jalr	-148(ra) # 80001de4 <growproc>
    80001e80:	10054463          	bltz	a0,80001f88 <ps+0x148>
    struct user_proc loc_result[count];
    80001e84:	003b9a13          	slli	s4,s7,0x3
    80001e88:	9a5e                	add	s4,s4,s7
    80001e8a:	0a0a                	slli	s4,s4,0x2
    80001e8c:	00fa0793          	addi	a5,s4,15
    80001e90:	8391                	srli	a5,a5,0x4
    80001e92:	0792                	slli	a5,a5,0x4
    80001e94:	40f10133          	sub	sp,sp,a5
    80001e98:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001e9a:	007e97b7          	lui	a5,0x7e9
    80001e9e:	02f484b3          	mul	s1,s1,a5
    80001ea2:	0000f797          	auipc	a5,0xf
    80001ea6:	1fe78793          	addi	a5,a5,510 # 800110a0 <proc>
    80001eaa:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001eac:	00015797          	auipc	a5,0x15
    80001eb0:	bf478793          	addi	a5,a5,-1036 # 80016aa0 <tickslock>
    80001eb4:	0cf4fc63          	bgeu	s1,a5,80001f8c <ps+0x14c>
    80001eb8:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001ebc:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001ebe:	8c3e                	mv	s8,a5
    80001ec0:	a069                	j	80001f4a <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80001ec2:	00399793          	slli	a5,s3,0x3
    80001ec6:	97ce                	add	a5,a5,s3
    80001ec8:	078a                	slli	a5,a5,0x2
    80001eca:	97d6                	add	a5,a5,s5
    80001ecc:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	db8080e7          	jalr	-584(ra) # 80000c8a <release>
    if (localCount < count)
    80001eda:	0179f963          	bgeu	s3,s7,80001eec <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80001ede:	00399793          	slli	a5,s3,0x3
    80001ee2:	97ce                	add	a5,a5,s3
    80001ee4:	078a                	slli	a5,a5,0x2
    80001ee6:	97d6                	add	a5,a5,s5
    80001ee8:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80001eec:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	b9c080e7          	jalr	-1124(ra) # 80001a8a <myproc>
    80001ef6:	86d2                	mv	a3,s4
    80001ef8:	8656                	mv	a2,s5
    80001efa:	85da                	mv	a1,s6
    80001efc:	6928                	ld	a0,80(a0)
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	76e080e7          	jalr	1902(ra) # 8000166c <copyout>
}
    80001f06:	8526                	mv	a0,s1
    80001f08:	fb040113          	addi	sp,s0,-80
    80001f0c:	60a6                	ld	ra,72(sp)
    80001f0e:	6406                	ld	s0,64(sp)
    80001f10:	74e2                	ld	s1,56(sp)
    80001f12:	7942                	ld	s2,48(sp)
    80001f14:	79a2                	ld	s3,40(sp)
    80001f16:	7a02                	ld	s4,32(sp)
    80001f18:	6ae2                	ld	s5,24(sp)
    80001f1a:	6b42                	ld	s6,16(sp)
    80001f1c:	6ba2                	ld	s7,8(sp)
    80001f1e:	6c02                	ld	s8,0(sp)
    80001f20:	6161                	addi	sp,sp,80
    80001f22:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80001f24:	5b9c                	lw	a5,48(a5)
    80001f26:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	d5e080e7          	jalr	-674(ra) # 80000c8a <release>
        localCount++;
    80001f34:	2985                	addiw	s3,s3,1
    80001f36:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80001f3a:	16848493          	addi	s1,s1,360
    80001f3e:	f984fee3          	bgeu	s1,s8,80001eda <ps+0x9a>
        if (localCount == count)
    80001f42:	02490913          	addi	s2,s2,36
    80001f46:	fb3b83e3          	beq	s7,s3,80001eec <ps+0xac>
        acquire(&p->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	c8a080e7          	jalr	-886(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80001f54:	4c9c                	lw	a5,24(s1)
    80001f56:	d7b5                	beqz	a5,80001ec2 <ps+0x82>
        loc_result[localCount].state = p->state;
    80001f58:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80001f5c:	549c                	lw	a5,40(s1)
    80001f5e:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80001f62:	54dc                	lw	a5,44(s1)
    80001f64:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80001f68:	589c                	lw	a5,48(s1)
    80001f6a:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80001f6e:	4641                	li	a2,16
    80001f70:	85ca                	mv	a1,s2
    80001f72:	15848513          	addi	a0,s1,344
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	aba080e7          	jalr	-1350(ra) # 80001a30 <copy_array>
        if (p->parent != 0) // init
    80001f7e:	7c9c                	ld	a5,56(s1)
    80001f80:	f3d5                	bnez	a5,80001f24 <ps+0xe4>
    80001f82:	b765                	j	80001f2a <ps+0xea>
        return result;
    80001f84:	4481                	li	s1,0
    80001f86:	b741                	j	80001f06 <ps+0xc6>
        return result;
    80001f88:	4481                	li	s1,0
    80001f8a:	bfb5                	j	80001f06 <ps+0xc6>
        return result;
    80001f8c:	4481                	li	s1,0
    80001f8e:	bfa5                	j	80001f06 <ps+0xc6>

0000000080001f90 <fork>:
{
    80001f90:	7139                	addi	sp,sp,-64
    80001f92:	fc06                	sd	ra,56(sp)
    80001f94:	f822                	sd	s0,48(sp)
    80001f96:	f426                	sd	s1,40(sp)
    80001f98:	f04a                	sd	s2,32(sp)
    80001f9a:	ec4e                	sd	s3,24(sp)
    80001f9c:	e852                	sd	s4,16(sp)
    80001f9e:	e456                	sd	s5,8(sp)
    80001fa0:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	ae8080e7          	jalr	-1304(ra) # 80001a8a <myproc>
    80001faa:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	ce8080e7          	jalr	-792(ra) # 80001c94 <allocproc>
    80001fb4:	10050c63          	beqz	a0,800020cc <fork+0x13c>
    80001fb8:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fba:	048ab603          	ld	a2,72(s5)
    80001fbe:	692c                	ld	a1,80(a0)
    80001fc0:	050ab503          	ld	a0,80(s5)
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	5a4080e7          	jalr	1444(ra) # 80001568 <uvmcopy>
    80001fcc:	04054863          	bltz	a0,8000201c <fork+0x8c>
    np->sz = p->sz;
    80001fd0:	048ab783          	ld	a5,72(s5)
    80001fd4:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    80001fd8:	058ab683          	ld	a3,88(s5)
    80001fdc:	87b6                	mv	a5,a3
    80001fde:	058a3703          	ld	a4,88(s4)
    80001fe2:	12068693          	addi	a3,a3,288
    80001fe6:	0007b803          	ld	a6,0(a5)
    80001fea:	6788                	ld	a0,8(a5)
    80001fec:	6b8c                	ld	a1,16(a5)
    80001fee:	6f90                	ld	a2,24(a5)
    80001ff0:	01073023          	sd	a6,0(a4)
    80001ff4:	e708                	sd	a0,8(a4)
    80001ff6:	eb0c                	sd	a1,16(a4)
    80001ff8:	ef10                	sd	a2,24(a4)
    80001ffa:	02078793          	addi	a5,a5,32
    80001ffe:	02070713          	addi	a4,a4,32
    80002002:	fed792e3          	bne	a5,a3,80001fe6 <fork+0x56>
    np->trapframe->a0 = 0;
    80002006:	058a3783          	ld	a5,88(s4)
    8000200a:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    8000200e:	0d0a8493          	addi	s1,s5,208
    80002012:	0d0a0913          	addi	s2,s4,208
    80002016:	150a8993          	addi	s3,s5,336
    8000201a:	a00d                	j	8000203c <fork+0xac>
        freeproc(np);
    8000201c:	8552                	mv	a0,s4
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	c1e080e7          	jalr	-994(ra) # 80001c3c <freeproc>
        release(&np->lock);
    80002026:	8552                	mv	a0,s4
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	c62080e7          	jalr	-926(ra) # 80000c8a <release>
        return -1;
    80002030:	597d                	li	s2,-1
    80002032:	a059                	j	800020b8 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002034:	04a1                	addi	s1,s1,8
    80002036:	0921                	addi	s2,s2,8
    80002038:	01348b63          	beq	s1,s3,8000204e <fork+0xbe>
        if (p->ofile[i])
    8000203c:	6088                	ld	a0,0(s1)
    8000203e:	d97d                	beqz	a0,80002034 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002040:	00002097          	auipc	ra,0x2
    80002044:	73e080e7          	jalr	1854(ra) # 8000477e <filedup>
    80002048:	00a93023          	sd	a0,0(s2)
    8000204c:	b7e5                	j	80002034 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000204e:	150ab503          	ld	a0,336(s5)
    80002052:	00002097          	auipc	ra,0x2
    80002056:	8ac080e7          	jalr	-1876(ra) # 800038fe <idup>
    8000205a:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000205e:	4641                	li	a2,16
    80002060:	158a8593          	addi	a1,s5,344
    80002064:	158a0513          	addi	a0,s4,344
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	db4080e7          	jalr	-588(ra) # 80000e1c <safestrcpy>
    pid = np->pid;
    80002070:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002074:	8552                	mv	a0,s4
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	c14080e7          	jalr	-1004(ra) # 80000c8a <release>
    acquire(&wait_lock);
    8000207e:	0000f497          	auipc	s1,0xf
    80002082:	00a48493          	addi	s1,s1,10 # 80011088 <wait_lock>
    80002086:	8526                	mv	a0,s1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	b4e080e7          	jalr	-1202(ra) # 80000bd6 <acquire>
    np->parent = p;
    80002090:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002094:	8526                	mv	a0,s1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	bf4080e7          	jalr	-1036(ra) # 80000c8a <release>
    acquire(&np->lock);
    8000209e:	8552                	mv	a0,s4
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b36080e7          	jalr	-1226(ra) # 80000bd6 <acquire>
    np->state = RUNNABLE;
    800020a8:	478d                	li	a5,3
    800020aa:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800020ae:	8552                	mv	a0,s4
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	bda080e7          	jalr	-1062(ra) # 80000c8a <release>
}
    800020b8:	854a                	mv	a0,s2
    800020ba:	70e2                	ld	ra,56(sp)
    800020bc:	7442                	ld	s0,48(sp)
    800020be:	74a2                	ld	s1,40(sp)
    800020c0:	7902                	ld	s2,32(sp)
    800020c2:	69e2                	ld	s3,24(sp)
    800020c4:	6a42                	ld	s4,16(sp)
    800020c6:	6aa2                	ld	s5,8(sp)
    800020c8:	6121                	addi	sp,sp,64
    800020ca:	8082                	ret
        return -1;
    800020cc:	597d                	li	s2,-1
    800020ce:	b7ed                	j	800020b8 <fork+0x128>

00000000800020d0 <scheduler>:
{
    800020d0:	1101                	addi	sp,sp,-32
    800020d2:	ec06                	sd	ra,24(sp)
    800020d4:	e822                	sd	s0,16(sp)
    800020d6:	e426                	sd	s1,8(sp)
    800020d8:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800020da:	00007497          	auipc	s1,0x7
    800020de:	85e48493          	addi	s1,s1,-1954 # 80008938 <sched_pointer>
    800020e2:	609c                	ld	a5,0(s1)
    800020e4:	9782                	jalr	a5
    while (1)
    800020e6:	bff5                	j	800020e2 <scheduler+0x12>

00000000800020e8 <sched>:
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	994080e7          	jalr	-1644(ra) # 80001a8a <myproc>
    800020fe:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	a5c080e7          	jalr	-1444(ra) # 80000b5c <holding>
    80002108:	c53d                	beqz	a0,80002176 <sched+0x8e>
    8000210a:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000210c:	2781                	sext.w	a5,a5
    8000210e:	079e                	slli	a5,a5,0x7
    80002110:	0000f717          	auipc	a4,0xf
    80002114:	b6070713          	addi	a4,a4,-1184 # 80010c70 <cpus>
    80002118:	97ba                	add	a5,a5,a4
    8000211a:	5fb8                	lw	a4,120(a5)
    8000211c:	4785                	li	a5,1
    8000211e:	06f71463          	bne	a4,a5,80002186 <sched+0x9e>
    if (p->state == RUNNING)
    80002122:	4c98                	lw	a4,24(s1)
    80002124:	4791                	li	a5,4
    80002126:	06f70863          	beq	a4,a5,80002196 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000212a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000212e:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002130:	ebbd                	bnez	a5,800021a6 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002132:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002134:	0000f917          	auipc	s2,0xf
    80002138:	b3c90913          	addi	s2,s2,-1220 # 80010c70 <cpus>
    8000213c:	2781                	sext.w	a5,a5
    8000213e:	079e                	slli	a5,a5,0x7
    80002140:	97ca                	add	a5,a5,s2
    80002142:	07c7a983          	lw	s3,124(a5)
    80002146:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002148:	2581                	sext.w	a1,a1
    8000214a:	059e                	slli	a1,a1,0x7
    8000214c:	05a1                	addi	a1,a1,8
    8000214e:	95ca                	add	a1,a1,s2
    80002150:	06048513          	addi	a0,s1,96
    80002154:	00000097          	auipc	ra,0x0
    80002158:	6e4080e7          	jalr	1764(ra) # 80002838 <swtch>
    8000215c:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000215e:	2781                	sext.w	a5,a5
    80002160:	079e                	slli	a5,a5,0x7
    80002162:	993e                	add	s2,s2,a5
    80002164:	07392e23          	sw	s3,124(s2)
}
    80002168:	70a2                	ld	ra,40(sp)
    8000216a:	7402                	ld	s0,32(sp)
    8000216c:	64e2                	ld	s1,24(sp)
    8000216e:	6942                	ld	s2,16(sp)
    80002170:	69a2                	ld	s3,8(sp)
    80002172:	6145                	addi	sp,sp,48
    80002174:	8082                	ret
        panic("sched p->lock");
    80002176:	00006517          	auipc	a0,0x6
    8000217a:	0a250513          	addi	a0,a0,162 # 80008218 <digits+0x1d8>
    8000217e:	ffffe097          	auipc	ra,0xffffe
    80002182:	3c2080e7          	jalr	962(ra) # 80000540 <panic>
        panic("sched locks");
    80002186:	00006517          	auipc	a0,0x6
    8000218a:	0a250513          	addi	a0,a0,162 # 80008228 <digits+0x1e8>
    8000218e:	ffffe097          	auipc	ra,0xffffe
    80002192:	3b2080e7          	jalr	946(ra) # 80000540 <panic>
        panic("sched running");
    80002196:	00006517          	auipc	a0,0x6
    8000219a:	0a250513          	addi	a0,a0,162 # 80008238 <digits+0x1f8>
    8000219e:	ffffe097          	auipc	ra,0xffffe
    800021a2:	3a2080e7          	jalr	930(ra) # 80000540 <panic>
        panic("sched interruptible");
    800021a6:	00006517          	auipc	a0,0x6
    800021aa:	0a250513          	addi	a0,a0,162 # 80008248 <digits+0x208>
    800021ae:	ffffe097          	auipc	ra,0xffffe
    800021b2:	392080e7          	jalr	914(ra) # 80000540 <panic>

00000000800021b6 <yield>:
{
    800021b6:	1101                	addi	sp,sp,-32
    800021b8:	ec06                	sd	ra,24(sp)
    800021ba:	e822                	sd	s0,16(sp)
    800021bc:	e426                	sd	s1,8(sp)
    800021be:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	8ca080e7          	jalr	-1846(ra) # 80001a8a <myproc>
    800021c8:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	a0c080e7          	jalr	-1524(ra) # 80000bd6 <acquire>
    p->state = RUNNABLE;
    800021d2:	478d                	li	a5,3
    800021d4:	cc9c                	sw	a5,24(s1)
    sched();
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	f12080e7          	jalr	-238(ra) # 800020e8 <sched>
    release(&p->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	aaa080e7          	jalr	-1366(ra) # 80000c8a <release>
}
    800021e8:	60e2                	ld	ra,24(sp)
    800021ea:	6442                	ld	s0,16(sp)
    800021ec:	64a2                	ld	s1,8(sp)
    800021ee:	6105                	addi	sp,sp,32
    800021f0:	8082                	ret

00000000800021f2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021f2:	7179                	addi	sp,sp,-48
    800021f4:	f406                	sd	ra,40(sp)
    800021f6:	f022                	sd	s0,32(sp)
    800021f8:	ec26                	sd	s1,24(sp)
    800021fa:	e84a                	sd	s2,16(sp)
    800021fc:	e44e                	sd	s3,8(sp)
    800021fe:	1800                	addi	s0,sp,48
    80002200:	89aa                	mv	s3,a0
    80002202:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002204:	00000097          	auipc	ra,0x0
    80002208:	886080e7          	jalr	-1914(ra) # 80001a8a <myproc>
    8000220c:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	9c8080e7          	jalr	-1592(ra) # 80000bd6 <acquire>
    release(lk);
    80002216:	854a                	mv	a0,s2
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a72080e7          	jalr	-1422(ra) # 80000c8a <release>

    // Go to sleep.
    p->chan = chan;
    80002220:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002224:	4789                	li	a5,2
    80002226:	cc9c                	sw	a5,24(s1)

    sched();
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	ec0080e7          	jalr	-320(ra) # 800020e8 <sched>

    // Tidy up.
    p->chan = 0;
    80002230:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a54080e7          	jalr	-1452(ra) # 80000c8a <release>
    acquire(lk);
    8000223e:	854a                	mv	a0,s2
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	996080e7          	jalr	-1642(ra) # 80000bd6 <acquire>
}
    80002248:	70a2                	ld	ra,40(sp)
    8000224a:	7402                	ld	s0,32(sp)
    8000224c:	64e2                	ld	s1,24(sp)
    8000224e:	6942                	ld	s2,16(sp)
    80002250:	69a2                	ld	s3,8(sp)
    80002252:	6145                	addi	sp,sp,48
    80002254:	8082                	ret

0000000080002256 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002256:	7139                	addi	sp,sp,-64
    80002258:	fc06                	sd	ra,56(sp)
    8000225a:	f822                	sd	s0,48(sp)
    8000225c:	f426                	sd	s1,40(sp)
    8000225e:	f04a                	sd	s2,32(sp)
    80002260:	ec4e                	sd	s3,24(sp)
    80002262:	e852                	sd	s4,16(sp)
    80002264:	e456                	sd	s5,8(sp)
    80002266:	0080                	addi	s0,sp,64
    80002268:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000226a:	0000f497          	auipc	s1,0xf
    8000226e:	e3648493          	addi	s1,s1,-458 # 800110a0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002272:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002274:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002276:	00015917          	auipc	s2,0x15
    8000227a:	82a90913          	addi	s2,s2,-2006 # 80016aa0 <tickslock>
    8000227e:	a811                	j	80002292 <wakeup+0x3c>
            }
            release(&p->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000228a:	16848493          	addi	s1,s1,360
    8000228e:	03248663          	beq	s1,s2,800022ba <wakeup+0x64>
        if (p != myproc())
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	7f8080e7          	jalr	2040(ra) # 80001a8a <myproc>
    8000229a:	fea488e3          	beq	s1,a0,8000228a <wakeup+0x34>
            acquire(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800022a8:	4c9c                	lw	a5,24(s1)
    800022aa:	fd379be3          	bne	a5,s3,80002280 <wakeup+0x2a>
    800022ae:	709c                	ld	a5,32(s1)
    800022b0:	fd4798e3          	bne	a5,s4,80002280 <wakeup+0x2a>
                p->state = RUNNABLE;
    800022b4:	0154ac23          	sw	s5,24(s1)
    800022b8:	b7e1                	j	80002280 <wakeup+0x2a>
        }
    }
}
    800022ba:	70e2                	ld	ra,56(sp)
    800022bc:	7442                	ld	s0,48(sp)
    800022be:	74a2                	ld	s1,40(sp)
    800022c0:	7902                	ld	s2,32(sp)
    800022c2:	69e2                	ld	s3,24(sp)
    800022c4:	6a42                	ld	s4,16(sp)
    800022c6:	6aa2                	ld	s5,8(sp)
    800022c8:	6121                	addi	sp,sp,64
    800022ca:	8082                	ret

00000000800022cc <reparent>:
{
    800022cc:	7179                	addi	sp,sp,-48
    800022ce:	f406                	sd	ra,40(sp)
    800022d0:	f022                	sd	s0,32(sp)
    800022d2:	ec26                	sd	s1,24(sp)
    800022d4:	e84a                	sd	s2,16(sp)
    800022d6:	e44e                	sd	s3,8(sp)
    800022d8:	e052                	sd	s4,0(sp)
    800022da:	1800                	addi	s0,sp,48
    800022dc:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800022de:	0000f497          	auipc	s1,0xf
    800022e2:	dc248493          	addi	s1,s1,-574 # 800110a0 <proc>
            pp->parent = initproc;
    800022e6:	00006a17          	auipc	s4,0x6
    800022ea:	712a0a13          	addi	s4,s4,1810 # 800089f8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800022ee:	00014997          	auipc	s3,0x14
    800022f2:	7b298993          	addi	s3,s3,1970 # 80016aa0 <tickslock>
    800022f6:	a029                	j	80002300 <reparent+0x34>
    800022f8:	16848493          	addi	s1,s1,360
    800022fc:	01348d63          	beq	s1,s3,80002316 <reparent+0x4a>
        if (pp->parent == p)
    80002300:	7c9c                	ld	a5,56(s1)
    80002302:	ff279be3          	bne	a5,s2,800022f8 <reparent+0x2c>
            pp->parent = initproc;
    80002306:	000a3503          	ld	a0,0(s4)
    8000230a:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	f4a080e7          	jalr	-182(ra) # 80002256 <wakeup>
    80002314:	b7d5                	j	800022f8 <reparent+0x2c>
}
    80002316:	70a2                	ld	ra,40(sp)
    80002318:	7402                	ld	s0,32(sp)
    8000231a:	64e2                	ld	s1,24(sp)
    8000231c:	6942                	ld	s2,16(sp)
    8000231e:	69a2                	ld	s3,8(sp)
    80002320:	6a02                	ld	s4,0(sp)
    80002322:	6145                	addi	sp,sp,48
    80002324:	8082                	ret

0000000080002326 <exit>:
{
    80002326:	7179                	addi	sp,sp,-48
    80002328:	f406                	sd	ra,40(sp)
    8000232a:	f022                	sd	s0,32(sp)
    8000232c:	ec26                	sd	s1,24(sp)
    8000232e:	e84a                	sd	s2,16(sp)
    80002330:	e44e                	sd	s3,8(sp)
    80002332:	e052                	sd	s4,0(sp)
    80002334:	1800                	addi	s0,sp,48
    80002336:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	752080e7          	jalr	1874(ra) # 80001a8a <myproc>
    80002340:	89aa                	mv	s3,a0
    if (p == initproc)
    80002342:	00006797          	auipc	a5,0x6
    80002346:	6b67b783          	ld	a5,1718(a5) # 800089f8 <initproc>
    8000234a:	0d050493          	addi	s1,a0,208
    8000234e:	15050913          	addi	s2,a0,336
    80002352:	02a79363          	bne	a5,a0,80002378 <exit+0x52>
        panic("init exiting");
    80002356:	00006517          	auipc	a0,0x6
    8000235a:	f0a50513          	addi	a0,a0,-246 # 80008260 <digits+0x220>
    8000235e:	ffffe097          	auipc	ra,0xffffe
    80002362:	1e2080e7          	jalr	482(ra) # 80000540 <panic>
            fileclose(f);
    80002366:	00002097          	auipc	ra,0x2
    8000236a:	46a080e7          	jalr	1130(ra) # 800047d0 <fileclose>
            p->ofile[fd] = 0;
    8000236e:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002372:	04a1                	addi	s1,s1,8
    80002374:	01248563          	beq	s1,s2,8000237e <exit+0x58>
        if (p->ofile[fd])
    80002378:	6088                	ld	a0,0(s1)
    8000237a:	f575                	bnez	a0,80002366 <exit+0x40>
    8000237c:	bfdd                	j	80002372 <exit+0x4c>
    begin_op();
    8000237e:	00002097          	auipc	ra,0x2
    80002382:	f8a080e7          	jalr	-118(ra) # 80004308 <begin_op>
    iput(p->cwd);
    80002386:	1509b503          	ld	a0,336(s3)
    8000238a:	00001097          	auipc	ra,0x1
    8000238e:	76c080e7          	jalr	1900(ra) # 80003af6 <iput>
    end_op();
    80002392:	00002097          	auipc	ra,0x2
    80002396:	ff4080e7          	jalr	-12(ra) # 80004386 <end_op>
    p->cwd = 0;
    8000239a:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    8000239e:	0000f497          	auipc	s1,0xf
    800023a2:	cea48493          	addi	s1,s1,-790 # 80011088 <wait_lock>
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	82e080e7          	jalr	-2002(ra) # 80000bd6 <acquire>
    reparent(p);
    800023b0:	854e                	mv	a0,s3
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	f1a080e7          	jalr	-230(ra) # 800022cc <reparent>
    wakeup(p->parent);
    800023ba:	0389b503          	ld	a0,56(s3)
    800023be:	00000097          	auipc	ra,0x0
    800023c2:	e98080e7          	jalr	-360(ra) # 80002256 <wakeup>
    acquire(&p->lock);
    800023c6:	854e                	mv	a0,s3
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	80e080e7          	jalr	-2034(ra) # 80000bd6 <acquire>
    p->xstate = status;
    800023d0:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800023d4:	4795                	li	a5,5
    800023d6:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
    sched();
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	d04080e7          	jalr	-764(ra) # 800020e8 <sched>
    panic("zombie exit");
    800023ec:	00006517          	auipc	a0,0x6
    800023f0:	e8450513          	addi	a0,a0,-380 # 80008270 <digits+0x230>
    800023f4:	ffffe097          	auipc	ra,0xffffe
    800023f8:	14c080e7          	jalr	332(ra) # 80000540 <panic>

00000000800023fc <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000240c:	0000f497          	auipc	s1,0xf
    80002410:	c9448493          	addi	s1,s1,-876 # 800110a0 <proc>
    80002414:	00014997          	auipc	s3,0x14
    80002418:	68c98993          	addi	s3,s3,1676 # 80016aa0 <tickslock>
    {
        acquire(&p->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7b8080e7          	jalr	1976(ra) # 80000bd6 <acquire>
        if (p->pid == pid)
    80002426:	589c                	lw	a5,48(s1)
    80002428:	01278d63          	beq	a5,s2,80002442 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	85c080e7          	jalr	-1956(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002436:	16848493          	addi	s1,s1,360
    8000243a:	ff3491e3          	bne	s1,s3,8000241c <kill+0x20>
    }
    return -1;
    8000243e:	557d                	li	a0,-1
    80002440:	a829                	j	8000245a <kill+0x5e>
            p->killed = 1;
    80002442:	4785                	li	a5,1
    80002444:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002446:	4c98                	lw	a4,24(s1)
    80002448:	4789                	li	a5,2
    8000244a:	00f70f63          	beq	a4,a5,80002468 <kill+0x6c>
            release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	83a080e7          	jalr	-1990(ra) # 80000c8a <release>
            return 0;
    80002458:	4501                	li	a0,0
}
    8000245a:	70a2                	ld	ra,40(sp)
    8000245c:	7402                	ld	s0,32(sp)
    8000245e:	64e2                	ld	s1,24(sp)
    80002460:	6942                	ld	s2,16(sp)
    80002462:	69a2                	ld	s3,8(sp)
    80002464:	6145                	addi	sp,sp,48
    80002466:	8082                	ret
                p->state = RUNNABLE;
    80002468:	478d                	li	a5,3
    8000246a:	cc9c                	sw	a5,24(s1)
    8000246c:	b7cd                	j	8000244e <kill+0x52>

000000008000246e <setkilled>:

void setkilled(struct proc *p)
{
    8000246e:	1101                	addi	sp,sp,-32
    80002470:	ec06                	sd	ra,24(sp)
    80002472:	e822                	sd	s0,16(sp)
    80002474:	e426                	sd	s1,8(sp)
    80002476:	1000                	addi	s0,sp,32
    80002478:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	75c080e7          	jalr	1884(ra) # 80000bd6 <acquire>
    p->killed = 1;
    80002482:	4785                	li	a5,1
    80002484:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	802080e7          	jalr	-2046(ra) # 80000c8a <release>
}
    80002490:	60e2                	ld	ra,24(sp)
    80002492:	6442                	ld	s0,16(sp)
    80002494:	64a2                	ld	s1,8(sp)
    80002496:	6105                	addi	sp,sp,32
    80002498:	8082                	ret

000000008000249a <killed>:

int killed(struct proc *p)
{
    8000249a:	1101                	addi	sp,sp,-32
    8000249c:	ec06                	sd	ra,24(sp)
    8000249e:	e822                	sd	s0,16(sp)
    800024a0:	e426                	sd	s1,8(sp)
    800024a2:	e04a                	sd	s2,0(sp)
    800024a4:	1000                	addi	s0,sp,32
    800024a6:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	72e080e7          	jalr	1838(ra) # 80000bd6 <acquire>
    k = p->killed;
    800024b0:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800024b4:	8526                	mv	a0,s1
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	7d4080e7          	jalr	2004(ra) # 80000c8a <release>
    return k;
}
    800024be:	854a                	mv	a0,s2
    800024c0:	60e2                	ld	ra,24(sp)
    800024c2:	6442                	ld	s0,16(sp)
    800024c4:	64a2                	ld	s1,8(sp)
    800024c6:	6902                	ld	s2,0(sp)
    800024c8:	6105                	addi	sp,sp,32
    800024ca:	8082                	ret

00000000800024cc <wait>:
{
    800024cc:	715d                	addi	sp,sp,-80
    800024ce:	e486                	sd	ra,72(sp)
    800024d0:	e0a2                	sd	s0,64(sp)
    800024d2:	fc26                	sd	s1,56(sp)
    800024d4:	f84a                	sd	s2,48(sp)
    800024d6:	f44e                	sd	s3,40(sp)
    800024d8:	f052                	sd	s4,32(sp)
    800024da:	ec56                	sd	s5,24(sp)
    800024dc:	e85a                	sd	s6,16(sp)
    800024de:	e45e                	sd	s7,8(sp)
    800024e0:	e062                	sd	s8,0(sp)
    800024e2:	0880                	addi	s0,sp,80
    800024e4:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	5a4080e7          	jalr	1444(ra) # 80001a8a <myproc>
    800024ee:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800024f0:	0000f517          	auipc	a0,0xf
    800024f4:	b9850513          	addi	a0,a0,-1128 # 80011088 <wait_lock>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	6de080e7          	jalr	1758(ra) # 80000bd6 <acquire>
        havekids = 0;
    80002500:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002502:	4a15                	li	s4,5
                havekids = 1;
    80002504:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002506:	00014997          	auipc	s3,0x14
    8000250a:	59a98993          	addi	s3,s3,1434 # 80016aa0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000250e:	0000fc17          	auipc	s8,0xf
    80002512:	b7ac0c13          	addi	s8,s8,-1158 # 80011088 <wait_lock>
        havekids = 0;
    80002516:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002518:	0000f497          	auipc	s1,0xf
    8000251c:	b8848493          	addi	s1,s1,-1144 # 800110a0 <proc>
    80002520:	a0bd                	j	8000258e <wait+0xc2>
                    pid = pp->pid;
    80002522:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002526:	000b0e63          	beqz	s6,80002542 <wait+0x76>
    8000252a:	4691                	li	a3,4
    8000252c:	02c48613          	addi	a2,s1,44
    80002530:	85da                	mv	a1,s6
    80002532:	05093503          	ld	a0,80(s2)
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	136080e7          	jalr	310(ra) # 8000166c <copyout>
    8000253e:	02054563          	bltz	a0,80002568 <wait+0x9c>
                    freeproc(pp);
    80002542:	8526                	mv	a0,s1
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	6f8080e7          	jalr	1784(ra) # 80001c3c <freeproc>
                    release(&pp->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	73c080e7          	jalr	1852(ra) # 80000c8a <release>
                    release(&wait_lock);
    80002556:	0000f517          	auipc	a0,0xf
    8000255a:	b3250513          	addi	a0,a0,-1230 # 80011088 <wait_lock>
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	72c080e7          	jalr	1836(ra) # 80000c8a <release>
                    return pid;
    80002566:	a0b5                	j	800025d2 <wait+0x106>
                        release(&pp->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	720080e7          	jalr	1824(ra) # 80000c8a <release>
                        release(&wait_lock);
    80002572:	0000f517          	auipc	a0,0xf
    80002576:	b1650513          	addi	a0,a0,-1258 # 80011088 <wait_lock>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	710080e7          	jalr	1808(ra) # 80000c8a <release>
                        return -1;
    80002582:	59fd                	li	s3,-1
    80002584:	a0b9                	j	800025d2 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002586:	16848493          	addi	s1,s1,360
    8000258a:	03348463          	beq	s1,s3,800025b2 <wait+0xe6>
            if (pp->parent == p)
    8000258e:	7c9c                	ld	a5,56(s1)
    80002590:	ff279be3          	bne	a5,s2,80002586 <wait+0xba>
                acquire(&pp->lock);
    80002594:	8526                	mv	a0,s1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	640080e7          	jalr	1600(ra) # 80000bd6 <acquire>
                if (pp->state == ZOMBIE)
    8000259e:	4c9c                	lw	a5,24(s1)
    800025a0:	f94781e3          	beq	a5,s4,80002522 <wait+0x56>
                release(&pp->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	6e4080e7          	jalr	1764(ra) # 80000c8a <release>
                havekids = 1;
    800025ae:	8756                	mv	a4,s5
    800025b0:	bfd9                	j	80002586 <wait+0xba>
        if (!havekids || killed(p))
    800025b2:	c719                	beqz	a4,800025c0 <wait+0xf4>
    800025b4:	854a                	mv	a0,s2
    800025b6:	00000097          	auipc	ra,0x0
    800025ba:	ee4080e7          	jalr	-284(ra) # 8000249a <killed>
    800025be:	c51d                	beqz	a0,800025ec <wait+0x120>
            release(&wait_lock);
    800025c0:	0000f517          	auipc	a0,0xf
    800025c4:	ac850513          	addi	a0,a0,-1336 # 80011088 <wait_lock>
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6c2080e7          	jalr	1730(ra) # 80000c8a <release>
            return -1;
    800025d0:	59fd                	li	s3,-1
}
    800025d2:	854e                	mv	a0,s3
    800025d4:	60a6                	ld	ra,72(sp)
    800025d6:	6406                	ld	s0,64(sp)
    800025d8:	74e2                	ld	s1,56(sp)
    800025da:	7942                	ld	s2,48(sp)
    800025dc:	79a2                	ld	s3,40(sp)
    800025de:	7a02                	ld	s4,32(sp)
    800025e0:	6ae2                	ld	s5,24(sp)
    800025e2:	6b42                	ld	s6,16(sp)
    800025e4:	6ba2                	ld	s7,8(sp)
    800025e6:	6c02                	ld	s8,0(sp)
    800025e8:	6161                	addi	sp,sp,80
    800025ea:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800025ec:	85e2                	mv	a1,s8
    800025ee:	854a                	mv	a0,s2
    800025f0:	00000097          	auipc	ra,0x0
    800025f4:	c02080e7          	jalr	-1022(ra) # 800021f2 <sleep>
        havekids = 0;
    800025f8:	bf39                	j	80002516 <wait+0x4a>

00000000800025fa <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025fa:	7179                	addi	sp,sp,-48
    800025fc:	f406                	sd	ra,40(sp)
    800025fe:	f022                	sd	s0,32(sp)
    80002600:	ec26                	sd	s1,24(sp)
    80002602:	e84a                	sd	s2,16(sp)
    80002604:	e44e                	sd	s3,8(sp)
    80002606:	e052                	sd	s4,0(sp)
    80002608:	1800                	addi	s0,sp,48
    8000260a:	84aa                	mv	s1,a0
    8000260c:	892e                	mv	s2,a1
    8000260e:	89b2                	mv	s3,a2
    80002610:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	478080e7          	jalr	1144(ra) # 80001a8a <myproc>
    if (user_dst)
    8000261a:	c08d                	beqz	s1,8000263c <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000261c:	86d2                	mv	a3,s4
    8000261e:	864e                	mv	a2,s3
    80002620:	85ca                	mv	a1,s2
    80002622:	6928                	ld	a0,80(a0)
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	048080e7          	jalr	72(ra) # 8000166c <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000262c:	70a2                	ld	ra,40(sp)
    8000262e:	7402                	ld	s0,32(sp)
    80002630:	64e2                	ld	s1,24(sp)
    80002632:	6942                	ld	s2,16(sp)
    80002634:	69a2                	ld	s3,8(sp)
    80002636:	6a02                	ld	s4,0(sp)
    80002638:	6145                	addi	sp,sp,48
    8000263a:	8082                	ret
        memmove((char *)dst, src, len);
    8000263c:	000a061b          	sext.w	a2,s4
    80002640:	85ce                	mv	a1,s3
    80002642:	854a                	mv	a0,s2
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	6ea080e7          	jalr	1770(ra) # 80000d2e <memmove>
        return 0;
    8000264c:	8526                	mv	a0,s1
    8000264e:	bff9                	j	8000262c <either_copyout+0x32>

0000000080002650 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002650:	7179                	addi	sp,sp,-48
    80002652:	f406                	sd	ra,40(sp)
    80002654:	f022                	sd	s0,32(sp)
    80002656:	ec26                	sd	s1,24(sp)
    80002658:	e84a                	sd	s2,16(sp)
    8000265a:	e44e                	sd	s3,8(sp)
    8000265c:	e052                	sd	s4,0(sp)
    8000265e:	1800                	addi	s0,sp,48
    80002660:	892a                	mv	s2,a0
    80002662:	84ae                	mv	s1,a1
    80002664:	89b2                	mv	s3,a2
    80002666:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	422080e7          	jalr	1058(ra) # 80001a8a <myproc>
    if (user_src)
    80002670:	c08d                	beqz	s1,80002692 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002672:	86d2                	mv	a3,s4
    80002674:	864e                	mv	a2,s3
    80002676:	85ca                	mv	a1,s2
    80002678:	6928                	ld	a0,80(a0)
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	07e080e7          	jalr	126(ra) # 800016f8 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002682:	70a2                	ld	ra,40(sp)
    80002684:	7402                	ld	s0,32(sp)
    80002686:	64e2                	ld	s1,24(sp)
    80002688:	6942                	ld	s2,16(sp)
    8000268a:	69a2                	ld	s3,8(sp)
    8000268c:	6a02                	ld	s4,0(sp)
    8000268e:	6145                	addi	sp,sp,48
    80002690:	8082                	ret
        memmove(dst, (char *)src, len);
    80002692:	000a061b          	sext.w	a2,s4
    80002696:	85ce                	mv	a1,s3
    80002698:	854a                	mv	a0,s2
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	694080e7          	jalr	1684(ra) # 80000d2e <memmove>
        return 0;
    800026a2:	8526                	mv	a0,s1
    800026a4:	bff9                	j	80002682 <either_copyin+0x32>

00000000800026a6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800026a6:	715d                	addi	sp,sp,-80
    800026a8:	e486                	sd	ra,72(sp)
    800026aa:	e0a2                	sd	s0,64(sp)
    800026ac:	fc26                	sd	s1,56(sp)
    800026ae:	f84a                	sd	s2,48(sp)
    800026b0:	f44e                	sd	s3,40(sp)
    800026b2:	f052                	sd	s4,32(sp)
    800026b4:	ec56                	sd	s5,24(sp)
    800026b6:	e85a                	sd	s6,16(sp)
    800026b8:	e45e                	sd	s7,8(sp)
    800026ba:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800026bc:	00006517          	auipc	a0,0x6
    800026c0:	a0c50513          	addi	a0,a0,-1524 # 800080c8 <digits+0x88>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	ec6080e7          	jalr	-314(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800026cc:	0000f497          	auipc	s1,0xf
    800026d0:	b2c48493          	addi	s1,s1,-1236 # 800111f8 <proc+0x158>
    800026d4:	00014917          	auipc	s2,0x14
    800026d8:	52490913          	addi	s2,s2,1316 # 80016bf8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026dc:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800026de:	00006997          	auipc	s3,0x6
    800026e2:	ba298993          	addi	s3,s3,-1118 # 80008280 <digits+0x240>
        printf("%d <%s %s", p->pid, state, p->name);
    800026e6:	00006a97          	auipc	s5,0x6
    800026ea:	ba2a8a93          	addi	s5,s5,-1118 # 80008288 <digits+0x248>
        printf("\n");
    800026ee:	00006a17          	auipc	s4,0x6
    800026f2:	9daa0a13          	addi	s4,s4,-1574 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f6:	00006b97          	auipc	s7,0x6
    800026fa:	ca2b8b93          	addi	s7,s7,-862 # 80008398 <states.0>
    800026fe:	a00d                	j	80002720 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002700:	ed86a583          	lw	a1,-296(a3)
    80002704:	8556                	mv	a0,s5
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	e84080e7          	jalr	-380(ra) # 8000058a <printf>
        printf("\n");
    8000270e:	8552                	mv	a0,s4
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	e7a080e7          	jalr	-390(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002718:	16848493          	addi	s1,s1,360
    8000271c:	03248263          	beq	s1,s2,80002740 <procdump+0x9a>
        if (p->state == UNUSED)
    80002720:	86a6                	mv	a3,s1
    80002722:	ec04a783          	lw	a5,-320(s1)
    80002726:	dbed                	beqz	a5,80002718 <procdump+0x72>
            state = "???";
    80002728:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000272a:	fcfb6be3          	bltu	s6,a5,80002700 <procdump+0x5a>
    8000272e:	02079713          	slli	a4,a5,0x20
    80002732:	01d75793          	srli	a5,a4,0x1d
    80002736:	97de                	add	a5,a5,s7
    80002738:	6390                	ld	a2,0(a5)
    8000273a:	f279                	bnez	a2,80002700 <procdump+0x5a>
            state = "???";
    8000273c:	864e                	mv	a2,s3
    8000273e:	b7c9                	j	80002700 <procdump+0x5a>
    }
}
    80002740:	60a6                	ld	ra,72(sp)
    80002742:	6406                	ld	s0,64(sp)
    80002744:	74e2                	ld	s1,56(sp)
    80002746:	7942                	ld	s2,48(sp)
    80002748:	79a2                	ld	s3,40(sp)
    8000274a:	7a02                	ld	s4,32(sp)
    8000274c:	6ae2                	ld	s5,24(sp)
    8000274e:	6b42                	ld	s6,16(sp)
    80002750:	6ba2                	ld	s7,8(sp)
    80002752:	6161                	addi	sp,sp,80
    80002754:	8082                	ret

0000000080002756 <schedls>:

void schedls()
{
    80002756:	1141                	addi	sp,sp,-16
    80002758:	e406                	sd	ra,8(sp)
    8000275a:	e022                	sd	s0,0(sp)
    8000275c:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    8000275e:	00006517          	auipc	a0,0x6
    80002762:	b3a50513          	addi	a0,a0,-1222 # 80008298 <digits+0x258>
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	e24080e7          	jalr	-476(ra) # 8000058a <printf>
    printf("====================================\n");
    8000276e:	00006517          	auipc	a0,0x6
    80002772:	b5250513          	addi	a0,a0,-1198 # 800082c0 <digits+0x280>
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	e14080e7          	jalr	-492(ra) # 8000058a <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    8000277e:	00006717          	auipc	a4,0x6
    80002782:	21a73703          	ld	a4,538(a4) # 80008998 <available_schedulers+0x10>
    80002786:	00006797          	auipc	a5,0x6
    8000278a:	1b27b783          	ld	a5,434(a5) # 80008938 <sched_pointer>
    8000278e:	04f70663          	beq	a4,a5,800027da <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002792:	00006517          	auipc	a0,0x6
    80002796:	b5e50513          	addi	a0,a0,-1186 # 800082f0 <digits+0x2b0>
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	df0080e7          	jalr	-528(ra) # 8000058a <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800027a2:	00006617          	auipc	a2,0x6
    800027a6:	1fe62603          	lw	a2,510(a2) # 800089a0 <available_schedulers+0x18>
    800027aa:	00006597          	auipc	a1,0x6
    800027ae:	1de58593          	addi	a1,a1,478 # 80008988 <available_schedulers>
    800027b2:	00006517          	auipc	a0,0x6
    800027b6:	b4650513          	addi	a0,a0,-1210 # 800082f8 <digits+0x2b8>
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	dd0080e7          	jalr	-560(ra) # 8000058a <printf>
    }
    printf("\n*: current scheduler\n\n");
    800027c2:	00006517          	auipc	a0,0x6
    800027c6:	b3e50513          	addi	a0,a0,-1218 # 80008300 <digits+0x2c0>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	dc0080e7          	jalr	-576(ra) # 8000058a <printf>
}
    800027d2:	60a2                	ld	ra,8(sp)
    800027d4:	6402                	ld	s0,0(sp)
    800027d6:	0141                	addi	sp,sp,16
    800027d8:	8082                	ret
            printf("[*]\t");
    800027da:	00006517          	auipc	a0,0x6
    800027de:	b0e50513          	addi	a0,a0,-1266 # 800082e8 <digits+0x2a8>
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	da8080e7          	jalr	-600(ra) # 8000058a <printf>
    800027ea:	bf65                	j	800027a2 <schedls+0x4c>

00000000800027ec <schedset>:

void schedset(int id)
{
    800027ec:	1141                	addi	sp,sp,-16
    800027ee:	e406                	sd	ra,8(sp)
    800027f0:	e022                	sd	s0,0(sp)
    800027f2:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800027f4:	e90d                	bnez	a0,80002826 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800027f6:	00006797          	auipc	a5,0x6
    800027fa:	1a27b783          	ld	a5,418(a5) # 80008998 <available_schedulers+0x10>
    800027fe:	00006717          	auipc	a4,0x6
    80002802:	12f73d23          	sd	a5,314(a4) # 80008938 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002806:	00006597          	auipc	a1,0x6
    8000280a:	18258593          	addi	a1,a1,386 # 80008988 <available_schedulers>
    8000280e:	00006517          	auipc	a0,0x6
    80002812:	b3250513          	addi	a0,a0,-1230 # 80008340 <digits+0x300>
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	d74080e7          	jalr	-652(ra) # 8000058a <printf>
    8000281e:	60a2                	ld	ra,8(sp)
    80002820:	6402                	ld	s0,0(sp)
    80002822:	0141                	addi	sp,sp,16
    80002824:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002826:	00006517          	auipc	a0,0x6
    8000282a:	af250513          	addi	a0,a0,-1294 # 80008318 <digits+0x2d8>
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	d5c080e7          	jalr	-676(ra) # 8000058a <printf>
        return;
    80002836:	b7e5                	j	8000281e <schedset+0x32>

0000000080002838 <swtch>:
    80002838:	00153023          	sd	ra,0(a0)
    8000283c:	00253423          	sd	sp,8(a0)
    80002840:	e900                	sd	s0,16(a0)
    80002842:	ed04                	sd	s1,24(a0)
    80002844:	03253023          	sd	s2,32(a0)
    80002848:	03353423          	sd	s3,40(a0)
    8000284c:	03453823          	sd	s4,48(a0)
    80002850:	03553c23          	sd	s5,56(a0)
    80002854:	05653023          	sd	s6,64(a0)
    80002858:	05753423          	sd	s7,72(a0)
    8000285c:	05853823          	sd	s8,80(a0)
    80002860:	05953c23          	sd	s9,88(a0)
    80002864:	07a53023          	sd	s10,96(a0)
    80002868:	07b53423          	sd	s11,104(a0)
    8000286c:	0005b083          	ld	ra,0(a1)
    80002870:	0085b103          	ld	sp,8(a1)
    80002874:	6980                	ld	s0,16(a1)
    80002876:	6d84                	ld	s1,24(a1)
    80002878:	0205b903          	ld	s2,32(a1)
    8000287c:	0285b983          	ld	s3,40(a1)
    80002880:	0305ba03          	ld	s4,48(a1)
    80002884:	0385ba83          	ld	s5,56(a1)
    80002888:	0405bb03          	ld	s6,64(a1)
    8000288c:	0485bb83          	ld	s7,72(a1)
    80002890:	0505bc03          	ld	s8,80(a1)
    80002894:	0585bc83          	ld	s9,88(a1)
    80002898:	0605bd03          	ld	s10,96(a1)
    8000289c:	0685bd83          	ld	s11,104(a1)
    800028a0:	8082                	ret

00000000800028a2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028a2:	1141                	addi	sp,sp,-16
    800028a4:	e406                	sd	ra,8(sp)
    800028a6:	e022                	sd	s0,0(sp)
    800028a8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028aa:	00006597          	auipc	a1,0x6
    800028ae:	b1e58593          	addi	a1,a1,-1250 # 800083c8 <states.0+0x30>
    800028b2:	00014517          	auipc	a0,0x14
    800028b6:	1ee50513          	addi	a0,a0,494 # 80016aa0 <tickslock>
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	28c080e7          	jalr	652(ra) # 80000b46 <initlock>
}
    800028c2:	60a2                	ld	ra,8(sp)
    800028c4:	6402                	ld	s0,0(sp)
    800028c6:	0141                	addi	sp,sp,16
    800028c8:	8082                	ret

00000000800028ca <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028ca:	1141                	addi	sp,sp,-16
    800028cc:	e422                	sd	s0,8(sp)
    800028ce:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d0:	00003797          	auipc	a5,0x3
    800028d4:	55078793          	addi	a5,a5,1360 # 80005e20 <kernelvec>
    800028d8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028dc:	6422                	ld	s0,8(sp)
    800028de:	0141                	addi	sp,sp,16
    800028e0:	8082                	ret

00000000800028e2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028e2:	1141                	addi	sp,sp,-16
    800028e4:	e406                	sd	ra,8(sp)
    800028e6:	e022                	sd	s0,0(sp)
    800028e8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	1a0080e7          	jalr	416(ra) # 80001a8a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028f6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028fc:	00004697          	auipc	a3,0x4
    80002900:	70468693          	addi	a3,a3,1796 # 80007000 <_trampoline>
    80002904:	00004717          	auipc	a4,0x4
    80002908:	6fc70713          	addi	a4,a4,1788 # 80007000 <_trampoline>
    8000290c:	8f15                	sub	a4,a4,a3
    8000290e:	040007b7          	lui	a5,0x4000
    80002912:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002914:	07b2                	slli	a5,a5,0xc
    80002916:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002918:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000291c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000291e:	18002673          	csrr	a2,satp
    80002922:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002924:	6d30                	ld	a2,88(a0)
    80002926:	6138                	ld	a4,64(a0)
    80002928:	6585                	lui	a1,0x1
    8000292a:	972e                	add	a4,a4,a1
    8000292c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000292e:	6d38                	ld	a4,88(a0)
    80002930:	00000617          	auipc	a2,0x0
    80002934:	13060613          	addi	a2,a2,304 # 80002a60 <usertrap>
    80002938:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000293a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000293c:	8612                	mv	a2,tp
    8000293e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002940:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002944:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002948:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002950:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002952:	6f18                	ld	a4,24(a4)
    80002954:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002958:	6928                	ld	a0,80(a0)
    8000295a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000295c:	00004717          	auipc	a4,0x4
    80002960:	74070713          	addi	a4,a4,1856 # 8000709c <userret>
    80002964:	8f15                	sub	a4,a4,a3
    80002966:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002968:	577d                	li	a4,-1
    8000296a:	177e                	slli	a4,a4,0x3f
    8000296c:	8d59                	or	a0,a0,a4
    8000296e:	9782                	jalr	a5
}
    80002970:	60a2                	ld	ra,8(sp)
    80002972:	6402                	ld	s0,0(sp)
    80002974:	0141                	addi	sp,sp,16
    80002976:	8082                	ret

0000000080002978 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002978:	1101                	addi	sp,sp,-32
    8000297a:	ec06                	sd	ra,24(sp)
    8000297c:	e822                	sd	s0,16(sp)
    8000297e:	e426                	sd	s1,8(sp)
    80002980:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002982:	00014497          	auipc	s1,0x14
    80002986:	11e48493          	addi	s1,s1,286 # 80016aa0 <tickslock>
    8000298a:	8526                	mv	a0,s1
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	24a080e7          	jalr	586(ra) # 80000bd6 <acquire>
  ticks++;
    80002994:	00006517          	auipc	a0,0x6
    80002998:	06c50513          	addi	a0,a0,108 # 80008a00 <ticks>
    8000299c:	411c                	lw	a5,0(a0)
    8000299e:	2785                	addiw	a5,a5,1
    800029a0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	8b4080e7          	jalr	-1868(ra) # 80002256 <wakeup>
  release(&tickslock);
    800029aa:	8526                	mv	a0,s1
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	2de080e7          	jalr	734(ra) # 80000c8a <release>
}
    800029b4:	60e2                	ld	ra,24(sp)
    800029b6:	6442                	ld	s0,16(sp)
    800029b8:	64a2                	ld	s1,8(sp)
    800029ba:	6105                	addi	sp,sp,32
    800029bc:	8082                	ret

00000000800029be <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029be:	1101                	addi	sp,sp,-32
    800029c0:	ec06                	sd	ra,24(sp)
    800029c2:	e822                	sd	s0,16(sp)
    800029c4:	e426                	sd	s1,8(sp)
    800029c6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029cc:	00074d63          	bltz	a4,800029e6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029d0:	57fd                	li	a5,-1
    800029d2:	17fe                	slli	a5,a5,0x3f
    800029d4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029d6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029d8:	06f70363          	beq	a4,a5,80002a3e <devintr+0x80>
  }
}
    800029dc:	60e2                	ld	ra,24(sp)
    800029de:	6442                	ld	s0,16(sp)
    800029e0:	64a2                	ld	s1,8(sp)
    800029e2:	6105                	addi	sp,sp,32
    800029e4:	8082                	ret
     (scause & 0xff) == 9){
    800029e6:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800029ea:	46a5                	li	a3,9
    800029ec:	fed792e3          	bne	a5,a3,800029d0 <devintr+0x12>
    int irq = plic_claim();
    800029f0:	00003097          	auipc	ra,0x3
    800029f4:	538080e7          	jalr	1336(ra) # 80005f28 <plic_claim>
    800029f8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029fa:	47a9                	li	a5,10
    800029fc:	02f50763          	beq	a0,a5,80002a2a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a00:	4785                	li	a5,1
    80002a02:	02f50963          	beq	a0,a5,80002a34 <devintr+0x76>
    return 1;
    80002a06:	4505                	li	a0,1
    } else if(irq){
    80002a08:	d8f1                	beqz	s1,800029dc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a0a:	85a6                	mv	a1,s1
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	9c450513          	addi	a0,a0,-1596 # 800083d0 <states.0+0x38>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b76080e7          	jalr	-1162(ra) # 8000058a <printf>
      plic_complete(irq);
    80002a1c:	8526                	mv	a0,s1
    80002a1e:	00003097          	auipc	ra,0x3
    80002a22:	52e080e7          	jalr	1326(ra) # 80005f4c <plic_complete>
    return 1;
    80002a26:	4505                	li	a0,1
    80002a28:	bf55                	j	800029dc <devintr+0x1e>
      uartintr();
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	f6e080e7          	jalr	-146(ra) # 80000998 <uartintr>
    80002a32:	b7ed                	j	80002a1c <devintr+0x5e>
      virtio_disk_intr();
    80002a34:	00004097          	auipc	ra,0x4
    80002a38:	9e0080e7          	jalr	-1568(ra) # 80006414 <virtio_disk_intr>
    80002a3c:	b7c5                	j	80002a1c <devintr+0x5e>
    if(cpuid() == 0){
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	020080e7          	jalr	32(ra) # 80001a5e <cpuid>
    80002a46:	c901                	beqz	a0,80002a56 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a48:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a4e:	14479073          	csrw	sip,a5
    return 2;
    80002a52:	4509                	li	a0,2
    80002a54:	b761                	j	800029dc <devintr+0x1e>
      clockintr();
    80002a56:	00000097          	auipc	ra,0x0
    80002a5a:	f22080e7          	jalr	-222(ra) # 80002978 <clockintr>
    80002a5e:	b7ed                	j	80002a48 <devintr+0x8a>

0000000080002a60 <usertrap>:
{
    80002a60:	1101                	addi	sp,sp,-32
    80002a62:	ec06                	sd	ra,24(sp)
    80002a64:	e822                	sd	s0,16(sp)
    80002a66:	e426                	sd	s1,8(sp)
    80002a68:	e04a                	sd	s2,0(sp)
    80002a6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a70:	1007f793          	andi	a5,a5,256
    80002a74:	e3b1                	bnez	a5,80002ab8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a76:	00003797          	auipc	a5,0x3
    80002a7a:	3aa78793          	addi	a5,a5,938 # 80005e20 <kernelvec>
    80002a7e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	008080e7          	jalr	8(ra) # 80001a8a <myproc>
    80002a8a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a8c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a8e:	14102773          	csrr	a4,sepc
    80002a92:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a98:	47a1                	li	a5,8
    80002a9a:	02f70763          	beq	a4,a5,80002ac8 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	f20080e7          	jalr	-224(ra) # 800029be <devintr>
    80002aa6:	892a                	mv	s2,a0
    80002aa8:	c151                	beqz	a0,80002b2c <usertrap+0xcc>
  if(killed(p))
    80002aaa:	8526                	mv	a0,s1
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	9ee080e7          	jalr	-1554(ra) # 8000249a <killed>
    80002ab4:	c929                	beqz	a0,80002b06 <usertrap+0xa6>
    80002ab6:	a099                	j	80002afc <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	93850513          	addi	a0,a0,-1736 # 800083f0 <states.0+0x58>
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	a80080e7          	jalr	-1408(ra) # 80000540 <panic>
    if(killed(p))
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	9d2080e7          	jalr	-1582(ra) # 8000249a <killed>
    80002ad0:	e921                	bnez	a0,80002b20 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002ad2:	6cb8                	ld	a4,88(s1)
    80002ad4:	6f1c                	ld	a5,24(a4)
    80002ad6:	0791                	addi	a5,a5,4
    80002ad8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ade:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae2:	10079073          	csrw	sstatus,a5
    syscall();
    80002ae6:	00000097          	auipc	ra,0x0
    80002aea:	2d4080e7          	jalr	724(ra) # 80002dba <syscall>
  if(killed(p))
    80002aee:	8526                	mv	a0,s1
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	9aa080e7          	jalr	-1622(ra) # 8000249a <killed>
    80002af8:	c911                	beqz	a0,80002b0c <usertrap+0xac>
    80002afa:	4901                	li	s2,0
    exit(-1);
    80002afc:	557d                	li	a0,-1
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	828080e7          	jalr	-2008(ra) # 80002326 <exit>
  if(which_dev == 2)
    80002b06:	4789                	li	a5,2
    80002b08:	04f90f63          	beq	s2,a5,80002b66 <usertrap+0x106>
  usertrapret();
    80002b0c:	00000097          	auipc	ra,0x0
    80002b10:	dd6080e7          	jalr	-554(ra) # 800028e2 <usertrapret>
}
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6902                	ld	s2,0(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret
      exit(-1);
    80002b20:	557d                	li	a0,-1
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	804080e7          	jalr	-2044(ra) # 80002326 <exit>
    80002b2a:	b765                	j	80002ad2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b2c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b30:	5890                	lw	a2,48(s1)
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	8de50513          	addi	a0,a0,-1826 # 80008410 <states.0+0x78>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	a50080e7          	jalr	-1456(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b42:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b46:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b4a:	00006517          	auipc	a0,0x6
    80002b4e:	8f650513          	addi	a0,a0,-1802 # 80008440 <states.0+0xa8>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	a38080e7          	jalr	-1480(ra) # 8000058a <printf>
    setkilled(p);
    80002b5a:	8526                	mv	a0,s1
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	912080e7          	jalr	-1774(ra) # 8000246e <setkilled>
    80002b64:	b769                	j	80002aee <usertrap+0x8e>
    yield();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	650080e7          	jalr	1616(ra) # 800021b6 <yield>
    80002b6e:	bf79                	j	80002b0c <usertrap+0xac>

0000000080002b70 <kerneltrap>:
{
    80002b70:	7179                	addi	sp,sp,-48
    80002b72:	f406                	sd	ra,40(sp)
    80002b74:	f022                	sd	s0,32(sp)
    80002b76:	ec26                	sd	s1,24(sp)
    80002b78:	e84a                	sd	s2,16(sp)
    80002b7a:	e44e                	sd	s3,8(sp)
    80002b7c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b82:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b86:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b8a:	1004f793          	andi	a5,s1,256
    80002b8e:	cb85                	beqz	a5,80002bbe <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b90:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b94:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b96:	ef85                	bnez	a5,80002bce <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	e26080e7          	jalr	-474(ra) # 800029be <devintr>
    80002ba0:	cd1d                	beqz	a0,80002bde <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ba2:	4789                	li	a5,2
    80002ba4:	06f50a63          	beq	a0,a5,80002c18 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ba8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bac:	10049073          	csrw	sstatus,s1
}
    80002bb0:	70a2                	ld	ra,40(sp)
    80002bb2:	7402                	ld	s0,32(sp)
    80002bb4:	64e2                	ld	s1,24(sp)
    80002bb6:	6942                	ld	s2,16(sp)
    80002bb8:	69a2                	ld	s3,8(sp)
    80002bba:	6145                	addi	sp,sp,48
    80002bbc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bbe:	00006517          	auipc	a0,0x6
    80002bc2:	8a250513          	addi	a0,a0,-1886 # 80008460 <states.0+0xc8>
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	97a080e7          	jalr	-1670(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	8ba50513          	addi	a0,a0,-1862 # 80008488 <states.0+0xf0>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	96a080e7          	jalr	-1686(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002bde:	85ce                	mv	a1,s3
    80002be0:	00006517          	auipc	a0,0x6
    80002be4:	8c850513          	addi	a0,a0,-1848 # 800084a8 <states.0+0x110>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	9a2080e7          	jalr	-1630(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf8:	00006517          	auipc	a0,0x6
    80002bfc:	8c050513          	addi	a0,a0,-1856 # 800084b8 <states.0+0x120>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	98a080e7          	jalr	-1654(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c08:	00006517          	auipc	a0,0x6
    80002c0c:	8c850513          	addi	a0,a0,-1848 # 800084d0 <states.0+0x138>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	930080e7          	jalr	-1744(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	e72080e7          	jalr	-398(ra) # 80001a8a <myproc>
    80002c20:	d541                	beqz	a0,80002ba8 <kerneltrap+0x38>
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	e68080e7          	jalr	-408(ra) # 80001a8a <myproc>
    80002c2a:	4d18                	lw	a4,24(a0)
    80002c2c:	4791                	li	a5,4
    80002c2e:	f6f71de3          	bne	a4,a5,80002ba8 <kerneltrap+0x38>
    yield();
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	584080e7          	jalr	1412(ra) # 800021b6 <yield>
    80002c3a:	b7bd                	j	80002ba8 <kerneltrap+0x38>

0000000080002c3c <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c3c:	1101                	addi	sp,sp,-32
    80002c3e:	ec06                	sd	ra,24(sp)
    80002c40:	e822                	sd	s0,16(sp)
    80002c42:	e426                	sd	s1,8(sp)
    80002c44:	1000                	addi	s0,sp,32
    80002c46:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	e42080e7          	jalr	-446(ra) # 80001a8a <myproc>
    switch (n)
    80002c50:	4795                	li	a5,5
    80002c52:	0497e163          	bltu	a5,s1,80002c94 <argraw+0x58>
    80002c56:	048a                	slli	s1,s1,0x2
    80002c58:	00006717          	auipc	a4,0x6
    80002c5c:	8b070713          	addi	a4,a4,-1872 # 80008508 <states.0+0x170>
    80002c60:	94ba                	add	s1,s1,a4
    80002c62:	409c                	lw	a5,0(s1)
    80002c64:	97ba                	add	a5,a5,a4
    80002c66:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002c68:	6d3c                	ld	a5,88(a0)
    80002c6a:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	64a2                	ld	s1,8(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret
        return p->trapframe->a1;
    80002c76:	6d3c                	ld	a5,88(a0)
    80002c78:	7fa8                	ld	a0,120(a5)
    80002c7a:	bfcd                	j	80002c6c <argraw+0x30>
        return p->trapframe->a2;
    80002c7c:	6d3c                	ld	a5,88(a0)
    80002c7e:	63c8                	ld	a0,128(a5)
    80002c80:	b7f5                	j	80002c6c <argraw+0x30>
        return p->trapframe->a3;
    80002c82:	6d3c                	ld	a5,88(a0)
    80002c84:	67c8                	ld	a0,136(a5)
    80002c86:	b7dd                	j	80002c6c <argraw+0x30>
        return p->trapframe->a4;
    80002c88:	6d3c                	ld	a5,88(a0)
    80002c8a:	6bc8                	ld	a0,144(a5)
    80002c8c:	b7c5                	j	80002c6c <argraw+0x30>
        return p->trapframe->a5;
    80002c8e:	6d3c                	ld	a5,88(a0)
    80002c90:	6fc8                	ld	a0,152(a5)
    80002c92:	bfe9                	j	80002c6c <argraw+0x30>
    panic("argraw");
    80002c94:	00006517          	auipc	a0,0x6
    80002c98:	84c50513          	addi	a0,a0,-1972 # 800084e0 <states.0+0x148>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8a4080e7          	jalr	-1884(ra) # 80000540 <panic>

0000000080002ca4 <fetchaddr>:
{
    80002ca4:	1101                	addi	sp,sp,-32
    80002ca6:	ec06                	sd	ra,24(sp)
    80002ca8:	e822                	sd	s0,16(sp)
    80002caa:	e426                	sd	s1,8(sp)
    80002cac:	e04a                	sd	s2,0(sp)
    80002cae:	1000                	addi	s0,sp,32
    80002cb0:	84aa                	mv	s1,a0
    80002cb2:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	dd6080e7          	jalr	-554(ra) # 80001a8a <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002cbc:	653c                	ld	a5,72(a0)
    80002cbe:	02f4f863          	bgeu	s1,a5,80002cee <fetchaddr+0x4a>
    80002cc2:	00848713          	addi	a4,s1,8
    80002cc6:	02e7e663          	bltu	a5,a4,80002cf2 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cca:	46a1                	li	a3,8
    80002ccc:	8626                	mv	a2,s1
    80002cce:	85ca                	mv	a1,s2
    80002cd0:	6928                	ld	a0,80(a0)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	a26080e7          	jalr	-1498(ra) # 800016f8 <copyin>
    80002cda:	00a03533          	snez	a0,a0
    80002cde:	40a00533          	neg	a0,a0
}
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	64a2                	ld	s1,8(sp)
    80002ce8:	6902                	ld	s2,0(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret
        return -1;
    80002cee:	557d                	li	a0,-1
    80002cf0:	bfcd                	j	80002ce2 <fetchaddr+0x3e>
    80002cf2:	557d                	li	a0,-1
    80002cf4:	b7fd                	j	80002ce2 <fetchaddr+0x3e>

0000000080002cf6 <fetchstr>:
{
    80002cf6:	7179                	addi	sp,sp,-48
    80002cf8:	f406                	sd	ra,40(sp)
    80002cfa:	f022                	sd	s0,32(sp)
    80002cfc:	ec26                	sd	s1,24(sp)
    80002cfe:	e84a                	sd	s2,16(sp)
    80002d00:	e44e                	sd	s3,8(sp)
    80002d02:	1800                	addi	s0,sp,48
    80002d04:	892a                	mv	s2,a0
    80002d06:	84ae                	mv	s1,a1
    80002d08:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	d80080e7          	jalr	-640(ra) # 80001a8a <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d12:	86ce                	mv	a3,s3
    80002d14:	864a                	mv	a2,s2
    80002d16:	85a6                	mv	a1,s1
    80002d18:	6928                	ld	a0,80(a0)
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	a6c080e7          	jalr	-1428(ra) # 80001786 <copyinstr>
    80002d22:	00054e63          	bltz	a0,80002d3e <fetchstr+0x48>
    return strlen(buf);
    80002d26:	8526                	mv	a0,s1
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	126080e7          	jalr	294(ra) # 80000e4e <strlen>
}
    80002d30:	70a2                	ld	ra,40(sp)
    80002d32:	7402                	ld	s0,32(sp)
    80002d34:	64e2                	ld	s1,24(sp)
    80002d36:	6942                	ld	s2,16(sp)
    80002d38:	69a2                	ld	s3,8(sp)
    80002d3a:	6145                	addi	sp,sp,48
    80002d3c:	8082                	ret
        return -1;
    80002d3e:	557d                	li	a0,-1
    80002d40:	bfc5                	j	80002d30 <fetchstr+0x3a>

0000000080002d42 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002d42:	1101                	addi	sp,sp,-32
    80002d44:	ec06                	sd	ra,24(sp)
    80002d46:	e822                	sd	s0,16(sp)
    80002d48:	e426                	sd	s1,8(sp)
    80002d4a:	1000                	addi	s0,sp,32
    80002d4c:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	eee080e7          	jalr	-274(ra) # 80002c3c <argraw>
    80002d56:	c088                	sw	a0,0(s1)
}
    80002d58:	60e2                	ld	ra,24(sp)
    80002d5a:	6442                	ld	s0,16(sp)
    80002d5c:	64a2                	ld	s1,8(sp)
    80002d5e:	6105                	addi	sp,sp,32
    80002d60:	8082                	ret

0000000080002d62 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002d62:	1101                	addi	sp,sp,-32
    80002d64:	ec06                	sd	ra,24(sp)
    80002d66:	e822                	sd	s0,16(sp)
    80002d68:	e426                	sd	s1,8(sp)
    80002d6a:	1000                	addi	s0,sp,32
    80002d6c:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	ece080e7          	jalr	-306(ra) # 80002c3c <argraw>
    80002d76:	e088                	sd	a0,0(s1)
}
    80002d78:	60e2                	ld	ra,24(sp)
    80002d7a:	6442                	ld	s0,16(sp)
    80002d7c:	64a2                	ld	s1,8(sp)
    80002d7e:	6105                	addi	sp,sp,32
    80002d80:	8082                	ret

0000000080002d82 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d82:	7179                	addi	sp,sp,-48
    80002d84:	f406                	sd	ra,40(sp)
    80002d86:	f022                	sd	s0,32(sp)
    80002d88:	ec26                	sd	s1,24(sp)
    80002d8a:	e84a                	sd	s2,16(sp)
    80002d8c:	1800                	addi	s0,sp,48
    80002d8e:	84ae                	mv	s1,a1
    80002d90:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002d92:	fd840593          	addi	a1,s0,-40
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	fcc080e7          	jalr	-52(ra) # 80002d62 <argaddr>
    return fetchstr(addr, buf, max);
    80002d9e:	864a                	mv	a2,s2
    80002da0:	85a6                	mv	a1,s1
    80002da2:	fd843503          	ld	a0,-40(s0)
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	f50080e7          	jalr	-176(ra) # 80002cf6 <fetchstr>
}
    80002dae:	70a2                	ld	ra,40(sp)
    80002db0:	7402                	ld	s0,32(sp)
    80002db2:	64e2                	ld	s1,24(sp)
    80002db4:	6942                	ld	s2,16(sp)
    80002db6:	6145                	addi	sp,sp,48
    80002db8:	8082                	ret

0000000080002dba <syscall>:
    [SYS_schedls] sys_schedls,
    [SYS_schedset] sys_schedset,
};

void syscall(void)
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	e426                	sd	s1,8(sp)
    80002dc2:	e04a                	sd	s2,0(sp)
    80002dc4:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	cc4080e7          	jalr	-828(ra) # 80001a8a <myproc>
    80002dce:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80002dd0:	05853903          	ld	s2,88(a0)
    80002dd4:	0a893783          	ld	a5,168(s2)
    80002dd8:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002ddc:	37fd                	addiw	a5,a5,-1
    80002dde:	475d                	li	a4,23
    80002de0:	00f76f63          	bltu	a4,a5,80002dfe <syscall+0x44>
    80002de4:	00369713          	slli	a4,a3,0x3
    80002de8:	00005797          	auipc	a5,0x5
    80002dec:	73878793          	addi	a5,a5,1848 # 80008520 <syscalls>
    80002df0:	97ba                	add	a5,a5,a4
    80002df2:	639c                	ld	a5,0(a5)
    80002df4:	c789                	beqz	a5,80002dfe <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80002df6:	9782                	jalr	a5
    80002df8:	06a93823          	sd	a0,112(s2)
    80002dfc:	a839                	j	80002e1a <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80002dfe:	15848613          	addi	a2,s1,344
    80002e02:	588c                	lw	a1,48(s1)
    80002e04:	00005517          	auipc	a0,0x5
    80002e08:	6e450513          	addi	a0,a0,1764 # 800084e8 <states.0+0x150>
    80002e0c:	ffffd097          	auipc	ra,0xffffd
    80002e10:	77e080e7          	jalr	1918(ra) # 8000058a <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80002e14:	6cbc                	ld	a5,88(s1)
    80002e16:	577d                	li	a4,-1
    80002e18:	fbb8                	sd	a4,112(a5)
    }
}
    80002e1a:	60e2                	ld	ra,24(sp)
    80002e1c:	6442                	ld	s0,16(sp)
    80002e1e:	64a2                	ld	s1,8(sp)
    80002e20:	6902                	ld	s2,0(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80002e2e:	fec40593          	addi	a1,s0,-20
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	f0e080e7          	jalr	-242(ra) # 80002d42 <argint>
    exit(n);
    80002e3c:	fec42503          	lw	a0,-20(s0)
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	4e6080e7          	jalr	1254(ra) # 80002326 <exit>
    return 0; // not reached
}
    80002e48:	4501                	li	a0,0
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	6105                	addi	sp,sp,32
    80002e50:	8082                	ret

0000000080002e52 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e52:	1141                	addi	sp,sp,-16
    80002e54:	e406                	sd	ra,8(sp)
    80002e56:	e022                	sd	s0,0(sp)
    80002e58:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	c30080e7          	jalr	-976(ra) # 80001a8a <myproc>
}
    80002e62:	5908                	lw	a0,48(a0)
    80002e64:	60a2                	ld	ra,8(sp)
    80002e66:	6402                	ld	s0,0(sp)
    80002e68:	0141                	addi	sp,sp,16
    80002e6a:	8082                	ret

0000000080002e6c <sys_fork>:

uint64
sys_fork(void)
{
    80002e6c:	1141                	addi	sp,sp,-16
    80002e6e:	e406                	sd	ra,8(sp)
    80002e70:	e022                	sd	s0,0(sp)
    80002e72:	0800                	addi	s0,sp,16
    return fork();
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	11c080e7          	jalr	284(ra) # 80001f90 <fork>
}
    80002e7c:	60a2                	ld	ra,8(sp)
    80002e7e:	6402                	ld	s0,0(sp)
    80002e80:	0141                	addi	sp,sp,16
    80002e82:	8082                	ret

0000000080002e84 <sys_wait>:

uint64
sys_wait(void)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80002e8c:	fe840593          	addi	a1,s0,-24
    80002e90:	4501                	li	a0,0
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	ed0080e7          	jalr	-304(ra) # 80002d62 <argaddr>
    return wait(p);
    80002e9a:	fe843503          	ld	a0,-24(s0)
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	62e080e7          	jalr	1582(ra) # 800024cc <wait>
}
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	6105                	addi	sp,sp,32
    80002eac:	8082                	ret

0000000080002eae <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002eae:	7179                	addi	sp,sp,-48
    80002eb0:	f406                	sd	ra,40(sp)
    80002eb2:	f022                	sd	s0,32(sp)
    80002eb4:	ec26                	sd	s1,24(sp)
    80002eb6:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80002eb8:	fdc40593          	addi	a1,s0,-36
    80002ebc:	4501                	li	a0,0
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	e84080e7          	jalr	-380(ra) # 80002d42 <argint>
    addr = myproc()->sz;
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	bc4080e7          	jalr	-1084(ra) # 80001a8a <myproc>
    80002ece:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80002ed0:	fdc42503          	lw	a0,-36(s0)
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	f10080e7          	jalr	-240(ra) # 80001de4 <growproc>
    80002edc:	00054863          	bltz	a0,80002eec <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80002ee0:	8526                	mv	a0,s1
    80002ee2:	70a2                	ld	ra,40(sp)
    80002ee4:	7402                	ld	s0,32(sp)
    80002ee6:	64e2                	ld	s1,24(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret
        return -1;
    80002eec:	54fd                	li	s1,-1
    80002eee:	bfcd                	j	80002ee0 <sys_sbrk+0x32>

0000000080002ef0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ef0:	7139                	addi	sp,sp,-64
    80002ef2:	fc06                	sd	ra,56(sp)
    80002ef4:	f822                	sd	s0,48(sp)
    80002ef6:	f426                	sd	s1,40(sp)
    80002ef8:	f04a                	sd	s2,32(sp)
    80002efa:	ec4e                	sd	s3,24(sp)
    80002efc:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80002efe:	fcc40593          	addi	a1,s0,-52
    80002f02:	4501                	li	a0,0
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	e3e080e7          	jalr	-450(ra) # 80002d42 <argint>
    acquire(&tickslock);
    80002f0c:	00014517          	auipc	a0,0x14
    80002f10:	b9450513          	addi	a0,a0,-1132 # 80016aa0 <tickslock>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	cc2080e7          	jalr	-830(ra) # 80000bd6 <acquire>
    ticks0 = ticks;
    80002f1c:	00006917          	auipc	s2,0x6
    80002f20:	ae492903          	lw	s2,-1308(s2) # 80008a00 <ticks>
    while (ticks - ticks0 < n)
    80002f24:	fcc42783          	lw	a5,-52(s0)
    80002f28:	cf9d                	beqz	a5,80002f66 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80002f2a:	00014997          	auipc	s3,0x14
    80002f2e:	b7698993          	addi	s3,s3,-1162 # 80016aa0 <tickslock>
    80002f32:	00006497          	auipc	s1,0x6
    80002f36:	ace48493          	addi	s1,s1,-1330 # 80008a00 <ticks>
        if (killed(myproc()))
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	b50080e7          	jalr	-1200(ra) # 80001a8a <myproc>
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	558080e7          	jalr	1368(ra) # 8000249a <killed>
    80002f4a:	ed15                	bnez	a0,80002f86 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80002f4c:	85ce                	mv	a1,s3
    80002f4e:	8526                	mv	a0,s1
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	2a2080e7          	jalr	674(ra) # 800021f2 <sleep>
    while (ticks - ticks0 < n)
    80002f58:	409c                	lw	a5,0(s1)
    80002f5a:	412787bb          	subw	a5,a5,s2
    80002f5e:	fcc42703          	lw	a4,-52(s0)
    80002f62:	fce7ece3          	bltu	a5,a4,80002f3a <sys_sleep+0x4a>
    }
    release(&tickslock);
    80002f66:	00014517          	auipc	a0,0x14
    80002f6a:	b3a50513          	addi	a0,a0,-1222 # 80016aa0 <tickslock>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	d1c080e7          	jalr	-740(ra) # 80000c8a <release>
    return 0;
    80002f76:	4501                	li	a0,0
}
    80002f78:	70e2                	ld	ra,56(sp)
    80002f7a:	7442                	ld	s0,48(sp)
    80002f7c:	74a2                	ld	s1,40(sp)
    80002f7e:	7902                	ld	s2,32(sp)
    80002f80:	69e2                	ld	s3,24(sp)
    80002f82:	6121                	addi	sp,sp,64
    80002f84:	8082                	ret
            release(&tickslock);
    80002f86:	00014517          	auipc	a0,0x14
    80002f8a:	b1a50513          	addi	a0,a0,-1254 # 80016aa0 <tickslock>
    80002f8e:	ffffe097          	auipc	ra,0xffffe
    80002f92:	cfc080e7          	jalr	-772(ra) # 80000c8a <release>
            return -1;
    80002f96:	557d                	li	a0,-1
    80002f98:	b7c5                	j	80002f78 <sys_sleep+0x88>

0000000080002f9a <sys_kill>:

uint64
sys_kill(void)
{
    80002f9a:	1101                	addi	sp,sp,-32
    80002f9c:	ec06                	sd	ra,24(sp)
    80002f9e:	e822                	sd	s0,16(sp)
    80002fa0:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80002fa2:	fec40593          	addi	a1,s0,-20
    80002fa6:	4501                	li	a0,0
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	d9a080e7          	jalr	-614(ra) # 80002d42 <argint>
    return kill(pid);
    80002fb0:	fec42503          	lw	a0,-20(s0)
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	448080e7          	jalr	1096(ra) # 800023fc <kill>
}
    80002fbc:	60e2                	ld	ra,24(sp)
    80002fbe:	6442                	ld	s0,16(sp)
    80002fc0:	6105                	addi	sp,sp,32
    80002fc2:	8082                	ret

0000000080002fc4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fc4:	1101                	addi	sp,sp,-32
    80002fc6:	ec06                	sd	ra,24(sp)
    80002fc8:	e822                	sd	s0,16(sp)
    80002fca:	e426                	sd	s1,8(sp)
    80002fcc:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	ad250513          	addi	a0,a0,-1326 # 80016aa0 <tickslock>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	c00080e7          	jalr	-1024(ra) # 80000bd6 <acquire>
    xticks = ticks;
    80002fde:	00006497          	auipc	s1,0x6
    80002fe2:	a224a483          	lw	s1,-1502(s1) # 80008a00 <ticks>
    release(&tickslock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	aba50513          	addi	a0,a0,-1350 # 80016aa0 <tickslock>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	c9c080e7          	jalr	-868(ra) # 80000c8a <release>
    return xticks;
}
    80002ff6:	02049513          	slli	a0,s1,0x20
    80002ffa:	9101                	srli	a0,a0,0x20
    80002ffc:	60e2                	ld	ra,24(sp)
    80002ffe:	6442                	ld	s0,16(sp)
    80003000:	64a2                	ld	s1,8(sp)
    80003002:	6105                	addi	sp,sp,32
    80003004:	8082                	ret

0000000080003006 <sys_ps>:

void *
sys_ps(void)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    8000300e:	fe042623          	sw	zero,-20(s0)
    80003012:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    80003016:	fec40593          	addi	a1,s0,-20
    8000301a:	4501                	li	a0,0
    8000301c:	00000097          	auipc	ra,0x0
    80003020:	d26080e7          	jalr	-730(ra) # 80002d42 <argint>
    argint(1, &count);
    80003024:	fe840593          	addi	a1,s0,-24
    80003028:	4505                	li	a0,1
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	d18080e7          	jalr	-744(ra) # 80002d42 <argint>
    return ps((uint8)start, (uint8)count);
    80003032:	fe844583          	lbu	a1,-24(s0)
    80003036:	fec44503          	lbu	a0,-20(s0)
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	e06080e7          	jalr	-506(ra) # 80001e40 <ps>
}
    80003042:	60e2                	ld	ra,24(sp)
    80003044:	6442                	ld	s0,16(sp)
    80003046:	6105                	addi	sp,sp,32
    80003048:	8082                	ret

000000008000304a <sys_schedls>:

uint64 sys_schedls(void)
{
    8000304a:	1141                	addi	sp,sp,-16
    8000304c:	e406                	sd	ra,8(sp)
    8000304e:	e022                	sd	s0,0(sp)
    80003050:	0800                	addi	s0,sp,16
    schedls();
    80003052:	fffff097          	auipc	ra,0xfffff
    80003056:	704080e7          	jalr	1796(ra) # 80002756 <schedls>
    return 0;
}
    8000305a:	4501                	li	a0,0
    8000305c:	60a2                	ld	ra,8(sp)
    8000305e:	6402                	ld	s0,0(sp)
    80003060:	0141                	addi	sp,sp,16
    80003062:	8082                	ret

0000000080003064 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003064:	1101                	addi	sp,sp,-32
    80003066:	ec06                	sd	ra,24(sp)
    80003068:	e822                	sd	s0,16(sp)
    8000306a:	1000                	addi	s0,sp,32
    int id = 0;
    8000306c:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003070:	fec40593          	addi	a1,s0,-20
    80003074:	4501                	li	a0,0
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	ccc080e7          	jalr	-820(ra) # 80002d42 <argint>
    schedset(id - 1);
    8000307e:	fec42503          	lw	a0,-20(s0)
    80003082:	357d                	addiw	a0,a0,-1
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	768080e7          	jalr	1896(ra) # 800027ec <schedset>
    return 0;
    8000308c:	4501                	li	a0,0
    8000308e:	60e2                	ld	ra,24(sp)
    80003090:	6442                	ld	s0,16(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003096:	7179                	addi	sp,sp,-48
    80003098:	f406                	sd	ra,40(sp)
    8000309a:	f022                	sd	s0,32(sp)
    8000309c:	ec26                	sd	s1,24(sp)
    8000309e:	e84a                	sd	s2,16(sp)
    800030a0:	e44e                	sd	s3,8(sp)
    800030a2:	e052                	sd	s4,0(sp)
    800030a4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030a6:	00005597          	auipc	a1,0x5
    800030aa:	54258593          	addi	a1,a1,1346 # 800085e8 <syscalls+0xc8>
    800030ae:	00014517          	auipc	a0,0x14
    800030b2:	a0a50513          	addi	a0,a0,-1526 # 80016ab8 <bcache>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	a90080e7          	jalr	-1392(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030be:	0001c797          	auipc	a5,0x1c
    800030c2:	9fa78793          	addi	a5,a5,-1542 # 8001eab8 <bcache+0x8000>
    800030c6:	0001c717          	auipc	a4,0x1c
    800030ca:	c5a70713          	addi	a4,a4,-934 # 8001ed20 <bcache+0x8268>
    800030ce:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030d2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030d6:	00014497          	auipc	s1,0x14
    800030da:	9fa48493          	addi	s1,s1,-1542 # 80016ad0 <bcache+0x18>
    b->next = bcache.head.next;
    800030de:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030e0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030e2:	00005a17          	auipc	s4,0x5
    800030e6:	50ea0a13          	addi	s4,s4,1294 # 800085f0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800030ea:	2b893783          	ld	a5,696(s2)
    800030ee:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030f0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030f4:	85d2                	mv	a1,s4
    800030f6:	01048513          	addi	a0,s1,16
    800030fa:	00001097          	auipc	ra,0x1
    800030fe:	4c8080e7          	jalr	1224(ra) # 800045c2 <initsleeplock>
    bcache.head.next->prev = b;
    80003102:	2b893783          	ld	a5,696(s2)
    80003106:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003108:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000310c:	45848493          	addi	s1,s1,1112
    80003110:	fd349de3          	bne	s1,s3,800030ea <binit+0x54>
  }
}
    80003114:	70a2                	ld	ra,40(sp)
    80003116:	7402                	ld	s0,32(sp)
    80003118:	64e2                	ld	s1,24(sp)
    8000311a:	6942                	ld	s2,16(sp)
    8000311c:	69a2                	ld	s3,8(sp)
    8000311e:	6a02                	ld	s4,0(sp)
    80003120:	6145                	addi	sp,sp,48
    80003122:	8082                	ret

0000000080003124 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003124:	7179                	addi	sp,sp,-48
    80003126:	f406                	sd	ra,40(sp)
    80003128:	f022                	sd	s0,32(sp)
    8000312a:	ec26                	sd	s1,24(sp)
    8000312c:	e84a                	sd	s2,16(sp)
    8000312e:	e44e                	sd	s3,8(sp)
    80003130:	1800                	addi	s0,sp,48
    80003132:	892a                	mv	s2,a0
    80003134:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	98250513          	addi	a0,a0,-1662 # 80016ab8 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	a98080e7          	jalr	-1384(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003146:	0001c497          	auipc	s1,0x1c
    8000314a:	c2a4b483          	ld	s1,-982(s1) # 8001ed70 <bcache+0x82b8>
    8000314e:	0001c797          	auipc	a5,0x1c
    80003152:	bd278793          	addi	a5,a5,-1070 # 8001ed20 <bcache+0x8268>
    80003156:	02f48f63          	beq	s1,a5,80003194 <bread+0x70>
    8000315a:	873e                	mv	a4,a5
    8000315c:	a021                	j	80003164 <bread+0x40>
    8000315e:	68a4                	ld	s1,80(s1)
    80003160:	02e48a63          	beq	s1,a4,80003194 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003164:	449c                	lw	a5,8(s1)
    80003166:	ff279ce3          	bne	a5,s2,8000315e <bread+0x3a>
    8000316a:	44dc                	lw	a5,12(s1)
    8000316c:	ff3799e3          	bne	a5,s3,8000315e <bread+0x3a>
      b->refcnt++;
    80003170:	40bc                	lw	a5,64(s1)
    80003172:	2785                	addiw	a5,a5,1
    80003174:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003176:	00014517          	auipc	a0,0x14
    8000317a:	94250513          	addi	a0,a0,-1726 # 80016ab8 <bcache>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	b0c080e7          	jalr	-1268(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003186:	01048513          	addi	a0,s1,16
    8000318a:	00001097          	auipc	ra,0x1
    8000318e:	472080e7          	jalr	1138(ra) # 800045fc <acquiresleep>
      return b;
    80003192:	a8b9                	j	800031f0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003194:	0001c497          	auipc	s1,0x1c
    80003198:	bd44b483          	ld	s1,-1068(s1) # 8001ed68 <bcache+0x82b0>
    8000319c:	0001c797          	auipc	a5,0x1c
    800031a0:	b8478793          	addi	a5,a5,-1148 # 8001ed20 <bcache+0x8268>
    800031a4:	00f48863          	beq	s1,a5,800031b4 <bread+0x90>
    800031a8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031aa:	40bc                	lw	a5,64(s1)
    800031ac:	cf81                	beqz	a5,800031c4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ae:	64a4                	ld	s1,72(s1)
    800031b0:	fee49de3          	bne	s1,a4,800031aa <bread+0x86>
  panic("bget: no buffers");
    800031b4:	00005517          	auipc	a0,0x5
    800031b8:	44450513          	addi	a0,a0,1092 # 800085f8 <syscalls+0xd8>
    800031bc:	ffffd097          	auipc	ra,0xffffd
    800031c0:	384080e7          	jalr	900(ra) # 80000540 <panic>
      b->dev = dev;
    800031c4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031c8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031cc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031d0:	4785                	li	a5,1
    800031d2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d4:	00014517          	auipc	a0,0x14
    800031d8:	8e450513          	addi	a0,a0,-1820 # 80016ab8 <bcache>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	aae080e7          	jalr	-1362(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800031e4:	01048513          	addi	a0,s1,16
    800031e8:	00001097          	auipc	ra,0x1
    800031ec:	414080e7          	jalr	1044(ra) # 800045fc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031f0:	409c                	lw	a5,0(s1)
    800031f2:	cb89                	beqz	a5,80003204 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031f4:	8526                	mv	a0,s1
    800031f6:	70a2                	ld	ra,40(sp)
    800031f8:	7402                	ld	s0,32(sp)
    800031fa:	64e2                	ld	s1,24(sp)
    800031fc:	6942                	ld	s2,16(sp)
    800031fe:	69a2                	ld	s3,8(sp)
    80003200:	6145                	addi	sp,sp,48
    80003202:	8082                	ret
    virtio_disk_rw(b, 0);
    80003204:	4581                	li	a1,0
    80003206:	8526                	mv	a0,s1
    80003208:	00003097          	auipc	ra,0x3
    8000320c:	fda080e7          	jalr	-38(ra) # 800061e2 <virtio_disk_rw>
    b->valid = 1;
    80003210:	4785                	li	a5,1
    80003212:	c09c                	sw	a5,0(s1)
  return b;
    80003214:	b7c5                	j	800031f4 <bread+0xd0>

0000000080003216 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	1000                	addi	s0,sp,32
    80003220:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003222:	0541                	addi	a0,a0,16
    80003224:	00001097          	auipc	ra,0x1
    80003228:	472080e7          	jalr	1138(ra) # 80004696 <holdingsleep>
    8000322c:	cd01                	beqz	a0,80003244 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000322e:	4585                	li	a1,1
    80003230:	8526                	mv	a0,s1
    80003232:	00003097          	auipc	ra,0x3
    80003236:	fb0080e7          	jalr	-80(ra) # 800061e2 <virtio_disk_rw>
}
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	64a2                	ld	s1,8(sp)
    80003240:	6105                	addi	sp,sp,32
    80003242:	8082                	ret
    panic("bwrite");
    80003244:	00005517          	auipc	a0,0x5
    80003248:	3cc50513          	addi	a0,a0,972 # 80008610 <syscalls+0xf0>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	2f4080e7          	jalr	756(ra) # 80000540 <panic>

0000000080003254 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003254:	1101                	addi	sp,sp,-32
    80003256:	ec06                	sd	ra,24(sp)
    80003258:	e822                	sd	s0,16(sp)
    8000325a:	e426                	sd	s1,8(sp)
    8000325c:	e04a                	sd	s2,0(sp)
    8000325e:	1000                	addi	s0,sp,32
    80003260:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003262:	01050913          	addi	s2,a0,16
    80003266:	854a                	mv	a0,s2
    80003268:	00001097          	auipc	ra,0x1
    8000326c:	42e080e7          	jalr	1070(ra) # 80004696 <holdingsleep>
    80003270:	c92d                	beqz	a0,800032e2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003272:	854a                	mv	a0,s2
    80003274:	00001097          	auipc	ra,0x1
    80003278:	3de080e7          	jalr	990(ra) # 80004652 <releasesleep>

  acquire(&bcache.lock);
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	83c50513          	addi	a0,a0,-1988 # 80016ab8 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	952080e7          	jalr	-1710(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000328c:	40bc                	lw	a5,64(s1)
    8000328e:	37fd                	addiw	a5,a5,-1
    80003290:	0007871b          	sext.w	a4,a5
    80003294:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003296:	eb05                	bnez	a4,800032c6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003298:	68bc                	ld	a5,80(s1)
    8000329a:	64b8                	ld	a4,72(s1)
    8000329c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000329e:	64bc                	ld	a5,72(s1)
    800032a0:	68b8                	ld	a4,80(s1)
    800032a2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032a4:	0001c797          	auipc	a5,0x1c
    800032a8:	81478793          	addi	a5,a5,-2028 # 8001eab8 <bcache+0x8000>
    800032ac:	2b87b703          	ld	a4,696(a5)
    800032b0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032b2:	0001c717          	auipc	a4,0x1c
    800032b6:	a6e70713          	addi	a4,a4,-1426 # 8001ed20 <bcache+0x8268>
    800032ba:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032bc:	2b87b703          	ld	a4,696(a5)
    800032c0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032c2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032c6:	00013517          	auipc	a0,0x13
    800032ca:	7f250513          	addi	a0,a0,2034 # 80016ab8 <bcache>
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	9bc080e7          	jalr	-1604(ra) # 80000c8a <release>
}
    800032d6:	60e2                	ld	ra,24(sp)
    800032d8:	6442                	ld	s0,16(sp)
    800032da:	64a2                	ld	s1,8(sp)
    800032dc:	6902                	ld	s2,0(sp)
    800032de:	6105                	addi	sp,sp,32
    800032e0:	8082                	ret
    panic("brelse");
    800032e2:	00005517          	auipc	a0,0x5
    800032e6:	33650513          	addi	a0,a0,822 # 80008618 <syscalls+0xf8>
    800032ea:	ffffd097          	auipc	ra,0xffffd
    800032ee:	256080e7          	jalr	598(ra) # 80000540 <panic>

00000000800032f2 <bpin>:

void
bpin(struct buf *b) {
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	1000                	addi	s0,sp,32
    800032fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032fe:	00013517          	auipc	a0,0x13
    80003302:	7ba50513          	addi	a0,a0,1978 # 80016ab8 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	8d0080e7          	jalr	-1840(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000330e:	40bc                	lw	a5,64(s1)
    80003310:	2785                	addiw	a5,a5,1
    80003312:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003314:	00013517          	auipc	a0,0x13
    80003318:	7a450513          	addi	a0,a0,1956 # 80016ab8 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	96e080e7          	jalr	-1682(ra) # 80000c8a <release>
}
    80003324:	60e2                	ld	ra,24(sp)
    80003326:	6442                	ld	s0,16(sp)
    80003328:	64a2                	ld	s1,8(sp)
    8000332a:	6105                	addi	sp,sp,32
    8000332c:	8082                	ret

000000008000332e <bunpin>:

void
bunpin(struct buf *b) {
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	e426                	sd	s1,8(sp)
    80003336:	1000                	addi	s0,sp,32
    80003338:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000333a:	00013517          	auipc	a0,0x13
    8000333e:	77e50513          	addi	a0,a0,1918 # 80016ab8 <bcache>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	894080e7          	jalr	-1900(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000334a:	40bc                	lw	a5,64(s1)
    8000334c:	37fd                	addiw	a5,a5,-1
    8000334e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003350:	00013517          	auipc	a0,0x13
    80003354:	76850513          	addi	a0,a0,1896 # 80016ab8 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>
}
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	64a2                	ld	s1,8(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000336a:	1101                	addi	sp,sp,-32
    8000336c:	ec06                	sd	ra,24(sp)
    8000336e:	e822                	sd	s0,16(sp)
    80003370:	e426                	sd	s1,8(sp)
    80003372:	e04a                	sd	s2,0(sp)
    80003374:	1000                	addi	s0,sp,32
    80003376:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003378:	00d5d59b          	srliw	a1,a1,0xd
    8000337c:	0001c797          	auipc	a5,0x1c
    80003380:	e187a783          	lw	a5,-488(a5) # 8001f194 <sb+0x1c>
    80003384:	9dbd                	addw	a1,a1,a5
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	d9e080e7          	jalr	-610(ra) # 80003124 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000338e:	0074f713          	andi	a4,s1,7
    80003392:	4785                	li	a5,1
    80003394:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003398:	14ce                	slli	s1,s1,0x33
    8000339a:	90d9                	srli	s1,s1,0x36
    8000339c:	00950733          	add	a4,a0,s1
    800033a0:	05874703          	lbu	a4,88(a4)
    800033a4:	00e7f6b3          	and	a3,a5,a4
    800033a8:	c69d                	beqz	a3,800033d6 <bfree+0x6c>
    800033aa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033ac:	94aa                	add	s1,s1,a0
    800033ae:	fff7c793          	not	a5,a5
    800033b2:	8f7d                	and	a4,a4,a5
    800033b4:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800033b8:	00001097          	auipc	ra,0x1
    800033bc:	126080e7          	jalr	294(ra) # 800044de <log_write>
  brelse(bp);
    800033c0:	854a                	mv	a0,s2
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	e92080e7          	jalr	-366(ra) # 80003254 <brelse>
}
    800033ca:	60e2                	ld	ra,24(sp)
    800033cc:	6442                	ld	s0,16(sp)
    800033ce:	64a2                	ld	s1,8(sp)
    800033d0:	6902                	ld	s2,0(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret
    panic("freeing free block");
    800033d6:	00005517          	auipc	a0,0x5
    800033da:	24a50513          	addi	a0,a0,586 # 80008620 <syscalls+0x100>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	162080e7          	jalr	354(ra) # 80000540 <panic>

00000000800033e6 <balloc>:
{
    800033e6:	711d                	addi	sp,sp,-96
    800033e8:	ec86                	sd	ra,88(sp)
    800033ea:	e8a2                	sd	s0,80(sp)
    800033ec:	e4a6                	sd	s1,72(sp)
    800033ee:	e0ca                	sd	s2,64(sp)
    800033f0:	fc4e                	sd	s3,56(sp)
    800033f2:	f852                	sd	s4,48(sp)
    800033f4:	f456                	sd	s5,40(sp)
    800033f6:	f05a                	sd	s6,32(sp)
    800033f8:	ec5e                	sd	s7,24(sp)
    800033fa:	e862                	sd	s8,16(sp)
    800033fc:	e466                	sd	s9,8(sp)
    800033fe:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003400:	0001c797          	auipc	a5,0x1c
    80003404:	d7c7a783          	lw	a5,-644(a5) # 8001f17c <sb+0x4>
    80003408:	cff5                	beqz	a5,80003504 <balloc+0x11e>
    8000340a:	8baa                	mv	s7,a0
    8000340c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000340e:	0001cb17          	auipc	s6,0x1c
    80003412:	d6ab0b13          	addi	s6,s6,-662 # 8001f178 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003416:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003418:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000341a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000341c:	6c89                	lui	s9,0x2
    8000341e:	a061                	j	800034a6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003420:	97ca                	add	a5,a5,s2
    80003422:	8e55                	or	a2,a2,a3
    80003424:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003428:	854a                	mv	a0,s2
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	0b4080e7          	jalr	180(ra) # 800044de <log_write>
        brelse(bp);
    80003432:	854a                	mv	a0,s2
    80003434:	00000097          	auipc	ra,0x0
    80003438:	e20080e7          	jalr	-480(ra) # 80003254 <brelse>
  bp = bread(dev, bno);
    8000343c:	85a6                	mv	a1,s1
    8000343e:	855e                	mv	a0,s7
    80003440:	00000097          	auipc	ra,0x0
    80003444:	ce4080e7          	jalr	-796(ra) # 80003124 <bread>
    80003448:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000344a:	40000613          	li	a2,1024
    8000344e:	4581                	li	a1,0
    80003450:	05850513          	addi	a0,a0,88
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	87e080e7          	jalr	-1922(ra) # 80000cd2 <memset>
  log_write(bp);
    8000345c:	854a                	mv	a0,s2
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	080080e7          	jalr	128(ra) # 800044de <log_write>
  brelse(bp);
    80003466:	854a                	mv	a0,s2
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	dec080e7          	jalr	-532(ra) # 80003254 <brelse>
}
    80003470:	8526                	mv	a0,s1
    80003472:	60e6                	ld	ra,88(sp)
    80003474:	6446                	ld	s0,80(sp)
    80003476:	64a6                	ld	s1,72(sp)
    80003478:	6906                	ld	s2,64(sp)
    8000347a:	79e2                	ld	s3,56(sp)
    8000347c:	7a42                	ld	s4,48(sp)
    8000347e:	7aa2                	ld	s5,40(sp)
    80003480:	7b02                	ld	s6,32(sp)
    80003482:	6be2                	ld	s7,24(sp)
    80003484:	6c42                	ld	s8,16(sp)
    80003486:	6ca2                	ld	s9,8(sp)
    80003488:	6125                	addi	sp,sp,96
    8000348a:	8082                	ret
    brelse(bp);
    8000348c:	854a                	mv	a0,s2
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	dc6080e7          	jalr	-570(ra) # 80003254 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003496:	015c87bb          	addw	a5,s9,s5
    8000349a:	00078a9b          	sext.w	s5,a5
    8000349e:	004b2703          	lw	a4,4(s6)
    800034a2:	06eaf163          	bgeu	s5,a4,80003504 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800034a6:	41fad79b          	sraiw	a5,s5,0x1f
    800034aa:	0137d79b          	srliw	a5,a5,0x13
    800034ae:	015787bb          	addw	a5,a5,s5
    800034b2:	40d7d79b          	sraiw	a5,a5,0xd
    800034b6:	01cb2583          	lw	a1,28(s6)
    800034ba:	9dbd                	addw	a1,a1,a5
    800034bc:	855e                	mv	a0,s7
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	c66080e7          	jalr	-922(ra) # 80003124 <bread>
    800034c6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c8:	004b2503          	lw	a0,4(s6)
    800034cc:	000a849b          	sext.w	s1,s5
    800034d0:	8762                	mv	a4,s8
    800034d2:	faa4fde3          	bgeu	s1,a0,8000348c <balloc+0xa6>
      m = 1 << (bi % 8);
    800034d6:	00777693          	andi	a3,a4,7
    800034da:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034de:	41f7579b          	sraiw	a5,a4,0x1f
    800034e2:	01d7d79b          	srliw	a5,a5,0x1d
    800034e6:	9fb9                	addw	a5,a5,a4
    800034e8:	4037d79b          	sraiw	a5,a5,0x3
    800034ec:	00f90633          	add	a2,s2,a5
    800034f0:	05864603          	lbu	a2,88(a2)
    800034f4:	00c6f5b3          	and	a1,a3,a2
    800034f8:	d585                	beqz	a1,80003420 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fa:	2705                	addiw	a4,a4,1
    800034fc:	2485                	addiw	s1,s1,1
    800034fe:	fd471ae3          	bne	a4,s4,800034d2 <balloc+0xec>
    80003502:	b769                	j	8000348c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003504:	00005517          	auipc	a0,0x5
    80003508:	13450513          	addi	a0,a0,308 # 80008638 <syscalls+0x118>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	07e080e7          	jalr	126(ra) # 8000058a <printf>
  return 0;
    80003514:	4481                	li	s1,0
    80003516:	bfa9                	j	80003470 <balloc+0x8a>

0000000080003518 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	e052                	sd	s4,0(sp)
    80003526:	1800                	addi	s0,sp,48
    80003528:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000352a:	47ad                	li	a5,11
    8000352c:	02b7e863          	bltu	a5,a1,8000355c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003530:	02059793          	slli	a5,a1,0x20
    80003534:	01e7d593          	srli	a1,a5,0x1e
    80003538:	00b504b3          	add	s1,a0,a1
    8000353c:	0504a903          	lw	s2,80(s1)
    80003540:	06091e63          	bnez	s2,800035bc <bmap+0xa4>
      addr = balloc(ip->dev);
    80003544:	4108                	lw	a0,0(a0)
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	ea0080e7          	jalr	-352(ra) # 800033e6 <balloc>
    8000354e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003552:	06090563          	beqz	s2,800035bc <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003556:	0524a823          	sw	s2,80(s1)
    8000355a:	a08d                	j	800035bc <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000355c:	ff45849b          	addiw	s1,a1,-12
    80003560:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003564:	0ff00793          	li	a5,255
    80003568:	08e7e563          	bltu	a5,a4,800035f2 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000356c:	08052903          	lw	s2,128(a0)
    80003570:	00091d63          	bnez	s2,8000358a <bmap+0x72>
      addr = balloc(ip->dev);
    80003574:	4108                	lw	a0,0(a0)
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	e70080e7          	jalr	-400(ra) # 800033e6 <balloc>
    8000357e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003582:	02090d63          	beqz	s2,800035bc <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003586:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000358a:	85ca                	mv	a1,s2
    8000358c:	0009a503          	lw	a0,0(s3)
    80003590:	00000097          	auipc	ra,0x0
    80003594:	b94080e7          	jalr	-1132(ra) # 80003124 <bread>
    80003598:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000359a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000359e:	02049713          	slli	a4,s1,0x20
    800035a2:	01e75593          	srli	a1,a4,0x1e
    800035a6:	00b784b3          	add	s1,a5,a1
    800035aa:	0004a903          	lw	s2,0(s1)
    800035ae:	02090063          	beqz	s2,800035ce <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035b2:	8552                	mv	a0,s4
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	ca0080e7          	jalr	-864(ra) # 80003254 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035bc:	854a                	mv	a0,s2
    800035be:	70a2                	ld	ra,40(sp)
    800035c0:	7402                	ld	s0,32(sp)
    800035c2:	64e2                	ld	s1,24(sp)
    800035c4:	6942                	ld	s2,16(sp)
    800035c6:	69a2                	ld	s3,8(sp)
    800035c8:	6a02                	ld	s4,0(sp)
    800035ca:	6145                	addi	sp,sp,48
    800035cc:	8082                	ret
      addr = balloc(ip->dev);
    800035ce:	0009a503          	lw	a0,0(s3)
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e14080e7          	jalr	-492(ra) # 800033e6 <balloc>
    800035da:	0005091b          	sext.w	s2,a0
      if(addr){
    800035de:	fc090ae3          	beqz	s2,800035b2 <bmap+0x9a>
        a[bn] = addr;
    800035e2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035e6:	8552                	mv	a0,s4
    800035e8:	00001097          	auipc	ra,0x1
    800035ec:	ef6080e7          	jalr	-266(ra) # 800044de <log_write>
    800035f0:	b7c9                	j	800035b2 <bmap+0x9a>
  panic("bmap: out of range");
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	05e50513          	addi	a0,a0,94 # 80008650 <syscalls+0x130>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>

0000000080003602 <iget>:
{
    80003602:	7179                	addi	sp,sp,-48
    80003604:	f406                	sd	ra,40(sp)
    80003606:	f022                	sd	s0,32(sp)
    80003608:	ec26                	sd	s1,24(sp)
    8000360a:	e84a                	sd	s2,16(sp)
    8000360c:	e44e                	sd	s3,8(sp)
    8000360e:	e052                	sd	s4,0(sp)
    80003610:	1800                	addi	s0,sp,48
    80003612:	89aa                	mv	s3,a0
    80003614:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003616:	0001c517          	auipc	a0,0x1c
    8000361a:	b8250513          	addi	a0,a0,-1150 # 8001f198 <itable>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	5b8080e7          	jalr	1464(ra) # 80000bd6 <acquire>
  empty = 0;
    80003626:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003628:	0001c497          	auipc	s1,0x1c
    8000362c:	b8848493          	addi	s1,s1,-1144 # 8001f1b0 <itable+0x18>
    80003630:	0001d697          	auipc	a3,0x1d
    80003634:	61068693          	addi	a3,a3,1552 # 80020c40 <log>
    80003638:	a039                	j	80003646 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000363a:	02090b63          	beqz	s2,80003670 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000363e:	08848493          	addi	s1,s1,136
    80003642:	02d48a63          	beq	s1,a3,80003676 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003646:	449c                	lw	a5,8(s1)
    80003648:	fef059e3          	blez	a5,8000363a <iget+0x38>
    8000364c:	4098                	lw	a4,0(s1)
    8000364e:	ff3716e3          	bne	a4,s3,8000363a <iget+0x38>
    80003652:	40d8                	lw	a4,4(s1)
    80003654:	ff4713e3          	bne	a4,s4,8000363a <iget+0x38>
      ip->ref++;
    80003658:	2785                	addiw	a5,a5,1
    8000365a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000365c:	0001c517          	auipc	a0,0x1c
    80003660:	b3c50513          	addi	a0,a0,-1220 # 8001f198 <itable>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	626080e7          	jalr	1574(ra) # 80000c8a <release>
      return ip;
    8000366c:	8926                	mv	s2,s1
    8000366e:	a03d                	j	8000369c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003670:	f7f9                	bnez	a5,8000363e <iget+0x3c>
    80003672:	8926                	mv	s2,s1
    80003674:	b7e9                	j	8000363e <iget+0x3c>
  if(empty == 0)
    80003676:	02090c63          	beqz	s2,800036ae <iget+0xac>
  ip->dev = dev;
    8000367a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000367e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003682:	4785                	li	a5,1
    80003684:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003688:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000368c:	0001c517          	auipc	a0,0x1c
    80003690:	b0c50513          	addi	a0,a0,-1268 # 8001f198 <itable>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	5f6080e7          	jalr	1526(ra) # 80000c8a <release>
}
    8000369c:	854a                	mv	a0,s2
    8000369e:	70a2                	ld	ra,40(sp)
    800036a0:	7402                	ld	s0,32(sp)
    800036a2:	64e2                	ld	s1,24(sp)
    800036a4:	6942                	ld	s2,16(sp)
    800036a6:	69a2                	ld	s3,8(sp)
    800036a8:	6a02                	ld	s4,0(sp)
    800036aa:	6145                	addi	sp,sp,48
    800036ac:	8082                	ret
    panic("iget: no inodes");
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	fba50513          	addi	a0,a0,-70 # 80008668 <syscalls+0x148>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	e8a080e7          	jalr	-374(ra) # 80000540 <panic>

00000000800036be <fsinit>:
fsinit(int dev) {
    800036be:	7179                	addi	sp,sp,-48
    800036c0:	f406                	sd	ra,40(sp)
    800036c2:	f022                	sd	s0,32(sp)
    800036c4:	ec26                	sd	s1,24(sp)
    800036c6:	e84a                	sd	s2,16(sp)
    800036c8:	e44e                	sd	s3,8(sp)
    800036ca:	1800                	addi	s0,sp,48
    800036cc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036ce:	4585                	li	a1,1
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	a54080e7          	jalr	-1452(ra) # 80003124 <bread>
    800036d8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036da:	0001c997          	auipc	s3,0x1c
    800036de:	a9e98993          	addi	s3,s3,-1378 # 8001f178 <sb>
    800036e2:	02000613          	li	a2,32
    800036e6:	05850593          	addi	a1,a0,88
    800036ea:	854e                	mv	a0,s3
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	642080e7          	jalr	1602(ra) # 80000d2e <memmove>
  brelse(bp);
    800036f4:	8526                	mv	a0,s1
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	b5e080e7          	jalr	-1186(ra) # 80003254 <brelse>
  if(sb.magic != FSMAGIC)
    800036fe:	0009a703          	lw	a4,0(s3)
    80003702:	102037b7          	lui	a5,0x10203
    80003706:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000370a:	02f71263          	bne	a4,a5,8000372e <fsinit+0x70>
  initlog(dev, &sb);
    8000370e:	0001c597          	auipc	a1,0x1c
    80003712:	a6a58593          	addi	a1,a1,-1430 # 8001f178 <sb>
    80003716:	854a                	mv	a0,s2
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	b4a080e7          	jalr	-1206(ra) # 80004262 <initlog>
}
    80003720:	70a2                	ld	ra,40(sp)
    80003722:	7402                	ld	s0,32(sp)
    80003724:	64e2                	ld	s1,24(sp)
    80003726:	6942                	ld	s2,16(sp)
    80003728:	69a2                	ld	s3,8(sp)
    8000372a:	6145                	addi	sp,sp,48
    8000372c:	8082                	ret
    panic("invalid file system");
    8000372e:	00005517          	auipc	a0,0x5
    80003732:	f4a50513          	addi	a0,a0,-182 # 80008678 <syscalls+0x158>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	e0a080e7          	jalr	-502(ra) # 80000540 <panic>

000000008000373e <iinit>:
{
    8000373e:	7179                	addi	sp,sp,-48
    80003740:	f406                	sd	ra,40(sp)
    80003742:	f022                	sd	s0,32(sp)
    80003744:	ec26                	sd	s1,24(sp)
    80003746:	e84a                	sd	s2,16(sp)
    80003748:	e44e                	sd	s3,8(sp)
    8000374a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000374c:	00005597          	auipc	a1,0x5
    80003750:	f4458593          	addi	a1,a1,-188 # 80008690 <syscalls+0x170>
    80003754:	0001c517          	auipc	a0,0x1c
    80003758:	a4450513          	addi	a0,a0,-1468 # 8001f198 <itable>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	3ea080e7          	jalr	1002(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003764:	0001c497          	auipc	s1,0x1c
    80003768:	a5c48493          	addi	s1,s1,-1444 # 8001f1c0 <itable+0x28>
    8000376c:	0001d997          	auipc	s3,0x1d
    80003770:	4e498993          	addi	s3,s3,1252 # 80020c50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003774:	00005917          	auipc	s2,0x5
    80003778:	f2490913          	addi	s2,s2,-220 # 80008698 <syscalls+0x178>
    8000377c:	85ca                	mv	a1,s2
    8000377e:	8526                	mv	a0,s1
    80003780:	00001097          	auipc	ra,0x1
    80003784:	e42080e7          	jalr	-446(ra) # 800045c2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003788:	08848493          	addi	s1,s1,136
    8000378c:	ff3498e3          	bne	s1,s3,8000377c <iinit+0x3e>
}
    80003790:	70a2                	ld	ra,40(sp)
    80003792:	7402                	ld	s0,32(sp)
    80003794:	64e2                	ld	s1,24(sp)
    80003796:	6942                	ld	s2,16(sp)
    80003798:	69a2                	ld	s3,8(sp)
    8000379a:	6145                	addi	sp,sp,48
    8000379c:	8082                	ret

000000008000379e <ialloc>:
{
    8000379e:	715d                	addi	sp,sp,-80
    800037a0:	e486                	sd	ra,72(sp)
    800037a2:	e0a2                	sd	s0,64(sp)
    800037a4:	fc26                	sd	s1,56(sp)
    800037a6:	f84a                	sd	s2,48(sp)
    800037a8:	f44e                	sd	s3,40(sp)
    800037aa:	f052                	sd	s4,32(sp)
    800037ac:	ec56                	sd	s5,24(sp)
    800037ae:	e85a                	sd	s6,16(sp)
    800037b0:	e45e                	sd	s7,8(sp)
    800037b2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b4:	0001c717          	auipc	a4,0x1c
    800037b8:	9d072703          	lw	a4,-1584(a4) # 8001f184 <sb+0xc>
    800037bc:	4785                	li	a5,1
    800037be:	04e7fa63          	bgeu	a5,a4,80003812 <ialloc+0x74>
    800037c2:	8aaa                	mv	s5,a0
    800037c4:	8bae                	mv	s7,a1
    800037c6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037c8:	0001ca17          	auipc	s4,0x1c
    800037cc:	9b0a0a13          	addi	s4,s4,-1616 # 8001f178 <sb>
    800037d0:	00048b1b          	sext.w	s6,s1
    800037d4:	0044d593          	srli	a1,s1,0x4
    800037d8:	018a2783          	lw	a5,24(s4)
    800037dc:	9dbd                	addw	a1,a1,a5
    800037de:	8556                	mv	a0,s5
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	944080e7          	jalr	-1724(ra) # 80003124 <bread>
    800037e8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037ea:	05850993          	addi	s3,a0,88
    800037ee:	00f4f793          	andi	a5,s1,15
    800037f2:	079a                	slli	a5,a5,0x6
    800037f4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037f6:	00099783          	lh	a5,0(s3)
    800037fa:	c3a1                	beqz	a5,8000383a <ialloc+0x9c>
    brelse(bp);
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	a58080e7          	jalr	-1448(ra) # 80003254 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003804:	0485                	addi	s1,s1,1
    80003806:	00ca2703          	lw	a4,12(s4)
    8000380a:	0004879b          	sext.w	a5,s1
    8000380e:	fce7e1e3          	bltu	a5,a4,800037d0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003812:	00005517          	auipc	a0,0x5
    80003816:	e8e50513          	addi	a0,a0,-370 # 800086a0 <syscalls+0x180>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	d70080e7          	jalr	-656(ra) # 8000058a <printf>
  return 0;
    80003822:	4501                	li	a0,0
}
    80003824:	60a6                	ld	ra,72(sp)
    80003826:	6406                	ld	s0,64(sp)
    80003828:	74e2                	ld	s1,56(sp)
    8000382a:	7942                	ld	s2,48(sp)
    8000382c:	79a2                	ld	s3,40(sp)
    8000382e:	7a02                	ld	s4,32(sp)
    80003830:	6ae2                	ld	s5,24(sp)
    80003832:	6b42                	ld	s6,16(sp)
    80003834:	6ba2                	ld	s7,8(sp)
    80003836:	6161                	addi	sp,sp,80
    80003838:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000383a:	04000613          	li	a2,64
    8000383e:	4581                	li	a1,0
    80003840:	854e                	mv	a0,s3
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	490080e7          	jalr	1168(ra) # 80000cd2 <memset>
      dip->type = type;
    8000384a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000384e:	854a                	mv	a0,s2
    80003850:	00001097          	auipc	ra,0x1
    80003854:	c8e080e7          	jalr	-882(ra) # 800044de <log_write>
      brelse(bp);
    80003858:	854a                	mv	a0,s2
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	9fa080e7          	jalr	-1542(ra) # 80003254 <brelse>
      return iget(dev, inum);
    80003862:	85da                	mv	a1,s6
    80003864:	8556                	mv	a0,s5
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	d9c080e7          	jalr	-612(ra) # 80003602 <iget>
    8000386e:	bf5d                	j	80003824 <ialloc+0x86>

0000000080003870 <iupdate>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	e04a                	sd	s2,0(sp)
    8000387a:	1000                	addi	s0,sp,32
    8000387c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000387e:	415c                	lw	a5,4(a0)
    80003880:	0047d79b          	srliw	a5,a5,0x4
    80003884:	0001c597          	auipc	a1,0x1c
    80003888:	90c5a583          	lw	a1,-1780(a1) # 8001f190 <sb+0x18>
    8000388c:	9dbd                	addw	a1,a1,a5
    8000388e:	4108                	lw	a0,0(a0)
    80003890:	00000097          	auipc	ra,0x0
    80003894:	894080e7          	jalr	-1900(ra) # 80003124 <bread>
    80003898:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000389a:	05850793          	addi	a5,a0,88
    8000389e:	40d8                	lw	a4,4(s1)
    800038a0:	8b3d                	andi	a4,a4,15
    800038a2:	071a                	slli	a4,a4,0x6
    800038a4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800038a6:	04449703          	lh	a4,68(s1)
    800038aa:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800038ae:	04649703          	lh	a4,70(s1)
    800038b2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800038b6:	04849703          	lh	a4,72(s1)
    800038ba:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800038be:	04a49703          	lh	a4,74(s1)
    800038c2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800038c6:	44f8                	lw	a4,76(s1)
    800038c8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038ca:	03400613          	li	a2,52
    800038ce:	05048593          	addi	a1,s1,80
    800038d2:	00c78513          	addi	a0,a5,12
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	458080e7          	jalr	1112(ra) # 80000d2e <memmove>
  log_write(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00001097          	auipc	ra,0x1
    800038e4:	bfe080e7          	jalr	-1026(ra) # 800044de <log_write>
  brelse(bp);
    800038e8:	854a                	mv	a0,s2
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	96a080e7          	jalr	-1686(ra) # 80003254 <brelse>
}
    800038f2:	60e2                	ld	ra,24(sp)
    800038f4:	6442                	ld	s0,16(sp)
    800038f6:	64a2                	ld	s1,8(sp)
    800038f8:	6902                	ld	s2,0(sp)
    800038fa:	6105                	addi	sp,sp,32
    800038fc:	8082                	ret

00000000800038fe <idup>:
{
    800038fe:	1101                	addi	sp,sp,-32
    80003900:	ec06                	sd	ra,24(sp)
    80003902:	e822                	sd	s0,16(sp)
    80003904:	e426                	sd	s1,8(sp)
    80003906:	1000                	addi	s0,sp,32
    80003908:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000390a:	0001c517          	auipc	a0,0x1c
    8000390e:	88e50513          	addi	a0,a0,-1906 # 8001f198 <itable>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	2c4080e7          	jalr	708(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000391a:	449c                	lw	a5,8(s1)
    8000391c:	2785                	addiw	a5,a5,1
    8000391e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003920:	0001c517          	auipc	a0,0x1c
    80003924:	87850513          	addi	a0,a0,-1928 # 8001f198 <itable>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	362080e7          	jalr	866(ra) # 80000c8a <release>
}
    80003930:	8526                	mv	a0,s1
    80003932:	60e2                	ld	ra,24(sp)
    80003934:	6442                	ld	s0,16(sp)
    80003936:	64a2                	ld	s1,8(sp)
    80003938:	6105                	addi	sp,sp,32
    8000393a:	8082                	ret

000000008000393c <ilock>:
{
    8000393c:	1101                	addi	sp,sp,-32
    8000393e:	ec06                	sd	ra,24(sp)
    80003940:	e822                	sd	s0,16(sp)
    80003942:	e426                	sd	s1,8(sp)
    80003944:	e04a                	sd	s2,0(sp)
    80003946:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003948:	c115                	beqz	a0,8000396c <ilock+0x30>
    8000394a:	84aa                	mv	s1,a0
    8000394c:	451c                	lw	a5,8(a0)
    8000394e:	00f05f63          	blez	a5,8000396c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003952:	0541                	addi	a0,a0,16
    80003954:	00001097          	auipc	ra,0x1
    80003958:	ca8080e7          	jalr	-856(ra) # 800045fc <acquiresleep>
  if(ip->valid == 0){
    8000395c:	40bc                	lw	a5,64(s1)
    8000395e:	cf99                	beqz	a5,8000397c <ilock+0x40>
}
    80003960:	60e2                	ld	ra,24(sp)
    80003962:	6442                	ld	s0,16(sp)
    80003964:	64a2                	ld	s1,8(sp)
    80003966:	6902                	ld	s2,0(sp)
    80003968:	6105                	addi	sp,sp,32
    8000396a:	8082                	ret
    panic("ilock");
    8000396c:	00005517          	auipc	a0,0x5
    80003970:	d4c50513          	addi	a0,a0,-692 # 800086b8 <syscalls+0x198>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	bcc080e7          	jalr	-1076(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000397c:	40dc                	lw	a5,4(s1)
    8000397e:	0047d79b          	srliw	a5,a5,0x4
    80003982:	0001c597          	auipc	a1,0x1c
    80003986:	80e5a583          	lw	a1,-2034(a1) # 8001f190 <sb+0x18>
    8000398a:	9dbd                	addw	a1,a1,a5
    8000398c:	4088                	lw	a0,0(s1)
    8000398e:	fffff097          	auipc	ra,0xfffff
    80003992:	796080e7          	jalr	1942(ra) # 80003124 <bread>
    80003996:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003998:	05850593          	addi	a1,a0,88
    8000399c:	40dc                	lw	a5,4(s1)
    8000399e:	8bbd                	andi	a5,a5,15
    800039a0:	079a                	slli	a5,a5,0x6
    800039a2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039a4:	00059783          	lh	a5,0(a1)
    800039a8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039ac:	00259783          	lh	a5,2(a1)
    800039b0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039b4:	00459783          	lh	a5,4(a1)
    800039b8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039bc:	00659783          	lh	a5,6(a1)
    800039c0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039c4:	459c                	lw	a5,8(a1)
    800039c6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039c8:	03400613          	li	a2,52
    800039cc:	05b1                	addi	a1,a1,12
    800039ce:	05048513          	addi	a0,s1,80
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	35c080e7          	jalr	860(ra) # 80000d2e <memmove>
    brelse(bp);
    800039da:	854a                	mv	a0,s2
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	878080e7          	jalr	-1928(ra) # 80003254 <brelse>
    ip->valid = 1;
    800039e4:	4785                	li	a5,1
    800039e6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039e8:	04449783          	lh	a5,68(s1)
    800039ec:	fbb5                	bnez	a5,80003960 <ilock+0x24>
      panic("ilock: no type");
    800039ee:	00005517          	auipc	a0,0x5
    800039f2:	cd250513          	addi	a0,a0,-814 # 800086c0 <syscalls+0x1a0>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	b4a080e7          	jalr	-1206(ra) # 80000540 <panic>

00000000800039fe <iunlock>:
{
    800039fe:	1101                	addi	sp,sp,-32
    80003a00:	ec06                	sd	ra,24(sp)
    80003a02:	e822                	sd	s0,16(sp)
    80003a04:	e426                	sd	s1,8(sp)
    80003a06:	e04a                	sd	s2,0(sp)
    80003a08:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a0a:	c905                	beqz	a0,80003a3a <iunlock+0x3c>
    80003a0c:	84aa                	mv	s1,a0
    80003a0e:	01050913          	addi	s2,a0,16
    80003a12:	854a                	mv	a0,s2
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	c82080e7          	jalr	-894(ra) # 80004696 <holdingsleep>
    80003a1c:	cd19                	beqz	a0,80003a3a <iunlock+0x3c>
    80003a1e:	449c                	lw	a5,8(s1)
    80003a20:	00f05d63          	blez	a5,80003a3a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a24:	854a                	mv	a0,s2
    80003a26:	00001097          	auipc	ra,0x1
    80003a2a:	c2c080e7          	jalr	-980(ra) # 80004652 <releasesleep>
}
    80003a2e:	60e2                	ld	ra,24(sp)
    80003a30:	6442                	ld	s0,16(sp)
    80003a32:	64a2                	ld	s1,8(sp)
    80003a34:	6902                	ld	s2,0(sp)
    80003a36:	6105                	addi	sp,sp,32
    80003a38:	8082                	ret
    panic("iunlock");
    80003a3a:	00005517          	auipc	a0,0x5
    80003a3e:	c9650513          	addi	a0,a0,-874 # 800086d0 <syscalls+0x1b0>
    80003a42:	ffffd097          	auipc	ra,0xffffd
    80003a46:	afe080e7          	jalr	-1282(ra) # 80000540 <panic>

0000000080003a4a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a4a:	7179                	addi	sp,sp,-48
    80003a4c:	f406                	sd	ra,40(sp)
    80003a4e:	f022                	sd	s0,32(sp)
    80003a50:	ec26                	sd	s1,24(sp)
    80003a52:	e84a                	sd	s2,16(sp)
    80003a54:	e44e                	sd	s3,8(sp)
    80003a56:	e052                	sd	s4,0(sp)
    80003a58:	1800                	addi	s0,sp,48
    80003a5a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a5c:	05050493          	addi	s1,a0,80
    80003a60:	08050913          	addi	s2,a0,128
    80003a64:	a021                	j	80003a6c <itrunc+0x22>
    80003a66:	0491                	addi	s1,s1,4
    80003a68:	01248d63          	beq	s1,s2,80003a82 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a6c:	408c                	lw	a1,0(s1)
    80003a6e:	dde5                	beqz	a1,80003a66 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a70:	0009a503          	lw	a0,0(s3)
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	8f6080e7          	jalr	-1802(ra) # 8000336a <bfree>
      ip->addrs[i] = 0;
    80003a7c:	0004a023          	sw	zero,0(s1)
    80003a80:	b7dd                	j	80003a66 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a82:	0809a583          	lw	a1,128(s3)
    80003a86:	e185                	bnez	a1,80003aa6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a88:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a8c:	854e                	mv	a0,s3
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	de2080e7          	jalr	-542(ra) # 80003870 <iupdate>
}
    80003a96:	70a2                	ld	ra,40(sp)
    80003a98:	7402                	ld	s0,32(sp)
    80003a9a:	64e2                	ld	s1,24(sp)
    80003a9c:	6942                	ld	s2,16(sp)
    80003a9e:	69a2                	ld	s3,8(sp)
    80003aa0:	6a02                	ld	s4,0(sp)
    80003aa2:	6145                	addi	sp,sp,48
    80003aa4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aa6:	0009a503          	lw	a0,0(s3)
    80003aaa:	fffff097          	auipc	ra,0xfffff
    80003aae:	67a080e7          	jalr	1658(ra) # 80003124 <bread>
    80003ab2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ab4:	05850493          	addi	s1,a0,88
    80003ab8:	45850913          	addi	s2,a0,1112
    80003abc:	a021                	j	80003ac4 <itrunc+0x7a>
    80003abe:	0491                	addi	s1,s1,4
    80003ac0:	01248b63          	beq	s1,s2,80003ad6 <itrunc+0x8c>
      if(a[j])
    80003ac4:	408c                	lw	a1,0(s1)
    80003ac6:	dde5                	beqz	a1,80003abe <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003ac8:	0009a503          	lw	a0,0(s3)
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	89e080e7          	jalr	-1890(ra) # 8000336a <bfree>
    80003ad4:	b7ed                	j	80003abe <itrunc+0x74>
    brelse(bp);
    80003ad6:	8552                	mv	a0,s4
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	77c080e7          	jalr	1916(ra) # 80003254 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ae0:	0809a583          	lw	a1,128(s3)
    80003ae4:	0009a503          	lw	a0,0(s3)
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	882080e7          	jalr	-1918(ra) # 8000336a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003af0:	0809a023          	sw	zero,128(s3)
    80003af4:	bf51                	j	80003a88 <itrunc+0x3e>

0000000080003af6 <iput>:
{
    80003af6:	1101                	addi	sp,sp,-32
    80003af8:	ec06                	sd	ra,24(sp)
    80003afa:	e822                	sd	s0,16(sp)
    80003afc:	e426                	sd	s1,8(sp)
    80003afe:	e04a                	sd	s2,0(sp)
    80003b00:	1000                	addi	s0,sp,32
    80003b02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b04:	0001b517          	auipc	a0,0x1b
    80003b08:	69450513          	addi	a0,a0,1684 # 8001f198 <itable>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	0ca080e7          	jalr	202(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b14:	4498                	lw	a4,8(s1)
    80003b16:	4785                	li	a5,1
    80003b18:	02f70363          	beq	a4,a5,80003b3e <iput+0x48>
  ip->ref--;
    80003b1c:	449c                	lw	a5,8(s1)
    80003b1e:	37fd                	addiw	a5,a5,-1
    80003b20:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b22:	0001b517          	auipc	a0,0x1b
    80003b26:	67650513          	addi	a0,a0,1654 # 8001f198 <itable>
    80003b2a:	ffffd097          	auipc	ra,0xffffd
    80003b2e:	160080e7          	jalr	352(ra) # 80000c8a <release>
}
    80003b32:	60e2                	ld	ra,24(sp)
    80003b34:	6442                	ld	s0,16(sp)
    80003b36:	64a2                	ld	s1,8(sp)
    80003b38:	6902                	ld	s2,0(sp)
    80003b3a:	6105                	addi	sp,sp,32
    80003b3c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b3e:	40bc                	lw	a5,64(s1)
    80003b40:	dff1                	beqz	a5,80003b1c <iput+0x26>
    80003b42:	04a49783          	lh	a5,74(s1)
    80003b46:	fbf9                	bnez	a5,80003b1c <iput+0x26>
    acquiresleep(&ip->lock);
    80003b48:	01048913          	addi	s2,s1,16
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	00001097          	auipc	ra,0x1
    80003b52:	aae080e7          	jalr	-1362(ra) # 800045fc <acquiresleep>
    release(&itable.lock);
    80003b56:	0001b517          	auipc	a0,0x1b
    80003b5a:	64250513          	addi	a0,a0,1602 # 8001f198 <itable>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	12c080e7          	jalr	300(ra) # 80000c8a <release>
    itrunc(ip);
    80003b66:	8526                	mv	a0,s1
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	ee2080e7          	jalr	-286(ra) # 80003a4a <itrunc>
    ip->type = 0;
    80003b70:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b74:	8526                	mv	a0,s1
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	cfa080e7          	jalr	-774(ra) # 80003870 <iupdate>
    ip->valid = 0;
    80003b7e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b82:	854a                	mv	a0,s2
    80003b84:	00001097          	auipc	ra,0x1
    80003b88:	ace080e7          	jalr	-1330(ra) # 80004652 <releasesleep>
    acquire(&itable.lock);
    80003b8c:	0001b517          	auipc	a0,0x1b
    80003b90:	60c50513          	addi	a0,a0,1548 # 8001f198 <itable>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	042080e7          	jalr	66(ra) # 80000bd6 <acquire>
    80003b9c:	b741                	j	80003b1c <iput+0x26>

0000000080003b9e <iunlockput>:
{
    80003b9e:	1101                	addi	sp,sp,-32
    80003ba0:	ec06                	sd	ra,24(sp)
    80003ba2:	e822                	sd	s0,16(sp)
    80003ba4:	e426                	sd	s1,8(sp)
    80003ba6:	1000                	addi	s0,sp,32
    80003ba8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	e54080e7          	jalr	-428(ra) # 800039fe <iunlock>
  iput(ip);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	f42080e7          	jalr	-190(ra) # 80003af6 <iput>
}
    80003bbc:	60e2                	ld	ra,24(sp)
    80003bbe:	6442                	ld	s0,16(sp)
    80003bc0:	64a2                	ld	s1,8(sp)
    80003bc2:	6105                	addi	sp,sp,32
    80003bc4:	8082                	ret

0000000080003bc6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bc6:	1141                	addi	sp,sp,-16
    80003bc8:	e422                	sd	s0,8(sp)
    80003bca:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bcc:	411c                	lw	a5,0(a0)
    80003bce:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bd0:	415c                	lw	a5,4(a0)
    80003bd2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bd4:	04451783          	lh	a5,68(a0)
    80003bd8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bdc:	04a51783          	lh	a5,74(a0)
    80003be0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003be4:	04c56783          	lwu	a5,76(a0)
    80003be8:	e99c                	sd	a5,16(a1)
}
    80003bea:	6422                	ld	s0,8(sp)
    80003bec:	0141                	addi	sp,sp,16
    80003bee:	8082                	ret

0000000080003bf0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bf0:	457c                	lw	a5,76(a0)
    80003bf2:	0ed7e963          	bltu	a5,a3,80003ce4 <readi+0xf4>
{
    80003bf6:	7159                	addi	sp,sp,-112
    80003bf8:	f486                	sd	ra,104(sp)
    80003bfa:	f0a2                	sd	s0,96(sp)
    80003bfc:	eca6                	sd	s1,88(sp)
    80003bfe:	e8ca                	sd	s2,80(sp)
    80003c00:	e4ce                	sd	s3,72(sp)
    80003c02:	e0d2                	sd	s4,64(sp)
    80003c04:	fc56                	sd	s5,56(sp)
    80003c06:	f85a                	sd	s6,48(sp)
    80003c08:	f45e                	sd	s7,40(sp)
    80003c0a:	f062                	sd	s8,32(sp)
    80003c0c:	ec66                	sd	s9,24(sp)
    80003c0e:	e86a                	sd	s10,16(sp)
    80003c10:	e46e                	sd	s11,8(sp)
    80003c12:	1880                	addi	s0,sp,112
    80003c14:	8b2a                	mv	s6,a0
    80003c16:	8bae                	mv	s7,a1
    80003c18:	8a32                	mv	s4,a2
    80003c1a:	84b6                	mv	s1,a3
    80003c1c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c1e:	9f35                	addw	a4,a4,a3
    return 0;
    80003c20:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c22:	0ad76063          	bltu	a4,a3,80003cc2 <readi+0xd2>
  if(off + n > ip->size)
    80003c26:	00e7f463          	bgeu	a5,a4,80003c2e <readi+0x3e>
    n = ip->size - off;
    80003c2a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2e:	0a0a8963          	beqz	s5,80003ce0 <readi+0xf0>
    80003c32:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c34:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c38:	5c7d                	li	s8,-1
    80003c3a:	a82d                	j	80003c74 <readi+0x84>
    80003c3c:	020d1d93          	slli	s11,s10,0x20
    80003c40:	020ddd93          	srli	s11,s11,0x20
    80003c44:	05890613          	addi	a2,s2,88
    80003c48:	86ee                	mv	a3,s11
    80003c4a:	963a                	add	a2,a2,a4
    80003c4c:	85d2                	mv	a1,s4
    80003c4e:	855e                	mv	a0,s7
    80003c50:	fffff097          	auipc	ra,0xfffff
    80003c54:	9aa080e7          	jalr	-1622(ra) # 800025fa <either_copyout>
    80003c58:	05850d63          	beq	a0,s8,80003cb2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c5c:	854a                	mv	a0,s2
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	5f6080e7          	jalr	1526(ra) # 80003254 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c66:	013d09bb          	addw	s3,s10,s3
    80003c6a:	009d04bb          	addw	s1,s10,s1
    80003c6e:	9a6e                	add	s4,s4,s11
    80003c70:	0559f763          	bgeu	s3,s5,80003cbe <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c74:	00a4d59b          	srliw	a1,s1,0xa
    80003c78:	855a                	mv	a0,s6
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	89e080e7          	jalr	-1890(ra) # 80003518 <bmap>
    80003c82:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c86:	cd85                	beqz	a1,80003cbe <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c88:	000b2503          	lw	a0,0(s6)
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	498080e7          	jalr	1176(ra) # 80003124 <bread>
    80003c94:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c96:	3ff4f713          	andi	a4,s1,1023
    80003c9a:	40ec87bb          	subw	a5,s9,a4
    80003c9e:	413a86bb          	subw	a3,s5,s3
    80003ca2:	8d3e                	mv	s10,a5
    80003ca4:	2781                	sext.w	a5,a5
    80003ca6:	0006861b          	sext.w	a2,a3
    80003caa:	f8f679e3          	bgeu	a2,a5,80003c3c <readi+0x4c>
    80003cae:	8d36                	mv	s10,a3
    80003cb0:	b771                	j	80003c3c <readi+0x4c>
      brelse(bp);
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	fffff097          	auipc	ra,0xfffff
    80003cb8:	5a0080e7          	jalr	1440(ra) # 80003254 <brelse>
      tot = -1;
    80003cbc:	59fd                	li	s3,-1
  }
  return tot;
    80003cbe:	0009851b          	sext.w	a0,s3
}
    80003cc2:	70a6                	ld	ra,104(sp)
    80003cc4:	7406                	ld	s0,96(sp)
    80003cc6:	64e6                	ld	s1,88(sp)
    80003cc8:	6946                	ld	s2,80(sp)
    80003cca:	69a6                	ld	s3,72(sp)
    80003ccc:	6a06                	ld	s4,64(sp)
    80003cce:	7ae2                	ld	s5,56(sp)
    80003cd0:	7b42                	ld	s6,48(sp)
    80003cd2:	7ba2                	ld	s7,40(sp)
    80003cd4:	7c02                	ld	s8,32(sp)
    80003cd6:	6ce2                	ld	s9,24(sp)
    80003cd8:	6d42                	ld	s10,16(sp)
    80003cda:	6da2                	ld	s11,8(sp)
    80003cdc:	6165                	addi	sp,sp,112
    80003cde:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ce0:	89d6                	mv	s3,s5
    80003ce2:	bff1                	j	80003cbe <readi+0xce>
    return 0;
    80003ce4:	4501                	li	a0,0
}
    80003ce6:	8082                	ret

0000000080003ce8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ce8:	457c                	lw	a5,76(a0)
    80003cea:	10d7e863          	bltu	a5,a3,80003dfa <writei+0x112>
{
    80003cee:	7159                	addi	sp,sp,-112
    80003cf0:	f486                	sd	ra,104(sp)
    80003cf2:	f0a2                	sd	s0,96(sp)
    80003cf4:	eca6                	sd	s1,88(sp)
    80003cf6:	e8ca                	sd	s2,80(sp)
    80003cf8:	e4ce                	sd	s3,72(sp)
    80003cfa:	e0d2                	sd	s4,64(sp)
    80003cfc:	fc56                	sd	s5,56(sp)
    80003cfe:	f85a                	sd	s6,48(sp)
    80003d00:	f45e                	sd	s7,40(sp)
    80003d02:	f062                	sd	s8,32(sp)
    80003d04:	ec66                	sd	s9,24(sp)
    80003d06:	e86a                	sd	s10,16(sp)
    80003d08:	e46e                	sd	s11,8(sp)
    80003d0a:	1880                	addi	s0,sp,112
    80003d0c:	8aaa                	mv	s5,a0
    80003d0e:	8bae                	mv	s7,a1
    80003d10:	8a32                	mv	s4,a2
    80003d12:	8936                	mv	s2,a3
    80003d14:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d16:	00e687bb          	addw	a5,a3,a4
    80003d1a:	0ed7e263          	bltu	a5,a3,80003dfe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d1e:	00043737          	lui	a4,0x43
    80003d22:	0ef76063          	bltu	a4,a5,80003e02 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d26:	0c0b0863          	beqz	s6,80003df6 <writei+0x10e>
    80003d2a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d30:	5c7d                	li	s8,-1
    80003d32:	a091                	j	80003d76 <writei+0x8e>
    80003d34:	020d1d93          	slli	s11,s10,0x20
    80003d38:	020ddd93          	srli	s11,s11,0x20
    80003d3c:	05848513          	addi	a0,s1,88
    80003d40:	86ee                	mv	a3,s11
    80003d42:	8652                	mv	a2,s4
    80003d44:	85de                	mv	a1,s7
    80003d46:	953a                	add	a0,a0,a4
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	908080e7          	jalr	-1784(ra) # 80002650 <either_copyin>
    80003d50:	07850263          	beq	a0,s8,80003db4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d54:	8526                	mv	a0,s1
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	788080e7          	jalr	1928(ra) # 800044de <log_write>
    brelse(bp);
    80003d5e:	8526                	mv	a0,s1
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	4f4080e7          	jalr	1268(ra) # 80003254 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d68:	013d09bb          	addw	s3,s10,s3
    80003d6c:	012d093b          	addw	s2,s10,s2
    80003d70:	9a6e                	add	s4,s4,s11
    80003d72:	0569f663          	bgeu	s3,s6,80003dbe <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d76:	00a9559b          	srliw	a1,s2,0xa
    80003d7a:	8556                	mv	a0,s5
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	79c080e7          	jalr	1948(ra) # 80003518 <bmap>
    80003d84:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d88:	c99d                	beqz	a1,80003dbe <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d8a:	000aa503          	lw	a0,0(s5)
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	396080e7          	jalr	918(ra) # 80003124 <bread>
    80003d96:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d98:	3ff97713          	andi	a4,s2,1023
    80003d9c:	40ec87bb          	subw	a5,s9,a4
    80003da0:	413b06bb          	subw	a3,s6,s3
    80003da4:	8d3e                	mv	s10,a5
    80003da6:	2781                	sext.w	a5,a5
    80003da8:	0006861b          	sext.w	a2,a3
    80003dac:	f8f674e3          	bgeu	a2,a5,80003d34 <writei+0x4c>
    80003db0:	8d36                	mv	s10,a3
    80003db2:	b749                	j	80003d34 <writei+0x4c>
      brelse(bp);
    80003db4:	8526                	mv	a0,s1
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	49e080e7          	jalr	1182(ra) # 80003254 <brelse>
  }

  if(off > ip->size)
    80003dbe:	04caa783          	lw	a5,76(s5)
    80003dc2:	0127f463          	bgeu	a5,s2,80003dca <writei+0xe2>
    ip->size = off;
    80003dc6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dca:	8556                	mv	a0,s5
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	aa4080e7          	jalr	-1372(ra) # 80003870 <iupdate>

  return tot;
    80003dd4:	0009851b          	sext.w	a0,s3
}
    80003dd8:	70a6                	ld	ra,104(sp)
    80003dda:	7406                	ld	s0,96(sp)
    80003ddc:	64e6                	ld	s1,88(sp)
    80003dde:	6946                	ld	s2,80(sp)
    80003de0:	69a6                	ld	s3,72(sp)
    80003de2:	6a06                	ld	s4,64(sp)
    80003de4:	7ae2                	ld	s5,56(sp)
    80003de6:	7b42                	ld	s6,48(sp)
    80003de8:	7ba2                	ld	s7,40(sp)
    80003dea:	7c02                	ld	s8,32(sp)
    80003dec:	6ce2                	ld	s9,24(sp)
    80003dee:	6d42                	ld	s10,16(sp)
    80003df0:	6da2                	ld	s11,8(sp)
    80003df2:	6165                	addi	sp,sp,112
    80003df4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df6:	89da                	mv	s3,s6
    80003df8:	bfc9                	j	80003dca <writei+0xe2>
    return -1;
    80003dfa:	557d                	li	a0,-1
}
    80003dfc:	8082                	ret
    return -1;
    80003dfe:	557d                	li	a0,-1
    80003e00:	bfe1                	j	80003dd8 <writei+0xf0>
    return -1;
    80003e02:	557d                	li	a0,-1
    80003e04:	bfd1                	j	80003dd8 <writei+0xf0>

0000000080003e06 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e06:	1141                	addi	sp,sp,-16
    80003e08:	e406                	sd	ra,8(sp)
    80003e0a:	e022                	sd	s0,0(sp)
    80003e0c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e0e:	4639                	li	a2,14
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	f92080e7          	jalr	-110(ra) # 80000da2 <strncmp>
}
    80003e18:	60a2                	ld	ra,8(sp)
    80003e1a:	6402                	ld	s0,0(sp)
    80003e1c:	0141                	addi	sp,sp,16
    80003e1e:	8082                	ret

0000000080003e20 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e20:	7139                	addi	sp,sp,-64
    80003e22:	fc06                	sd	ra,56(sp)
    80003e24:	f822                	sd	s0,48(sp)
    80003e26:	f426                	sd	s1,40(sp)
    80003e28:	f04a                	sd	s2,32(sp)
    80003e2a:	ec4e                	sd	s3,24(sp)
    80003e2c:	e852                	sd	s4,16(sp)
    80003e2e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e30:	04451703          	lh	a4,68(a0)
    80003e34:	4785                	li	a5,1
    80003e36:	00f71a63          	bne	a4,a5,80003e4a <dirlookup+0x2a>
    80003e3a:	892a                	mv	s2,a0
    80003e3c:	89ae                	mv	s3,a1
    80003e3e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e40:	457c                	lw	a5,76(a0)
    80003e42:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e44:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e46:	e79d                	bnez	a5,80003e74 <dirlookup+0x54>
    80003e48:	a8a5                	j	80003ec0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e4a:	00005517          	auipc	a0,0x5
    80003e4e:	88e50513          	addi	a0,a0,-1906 # 800086d8 <syscalls+0x1b8>
    80003e52:	ffffc097          	auipc	ra,0xffffc
    80003e56:	6ee080e7          	jalr	1774(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e5a:	00005517          	auipc	a0,0x5
    80003e5e:	89650513          	addi	a0,a0,-1898 # 800086f0 <syscalls+0x1d0>
    80003e62:	ffffc097          	auipc	ra,0xffffc
    80003e66:	6de080e7          	jalr	1758(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6a:	24c1                	addiw	s1,s1,16
    80003e6c:	04c92783          	lw	a5,76(s2)
    80003e70:	04f4f763          	bgeu	s1,a5,80003ebe <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e74:	4741                	li	a4,16
    80003e76:	86a6                	mv	a3,s1
    80003e78:	fc040613          	addi	a2,s0,-64
    80003e7c:	4581                	li	a1,0
    80003e7e:	854a                	mv	a0,s2
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	d70080e7          	jalr	-656(ra) # 80003bf0 <readi>
    80003e88:	47c1                	li	a5,16
    80003e8a:	fcf518e3          	bne	a0,a5,80003e5a <dirlookup+0x3a>
    if(de.inum == 0)
    80003e8e:	fc045783          	lhu	a5,-64(s0)
    80003e92:	dfe1                	beqz	a5,80003e6a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e94:	fc240593          	addi	a1,s0,-62
    80003e98:	854e                	mv	a0,s3
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	f6c080e7          	jalr	-148(ra) # 80003e06 <namecmp>
    80003ea2:	f561                	bnez	a0,80003e6a <dirlookup+0x4a>
      if(poff)
    80003ea4:	000a0463          	beqz	s4,80003eac <dirlookup+0x8c>
        *poff = off;
    80003ea8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eac:	fc045583          	lhu	a1,-64(s0)
    80003eb0:	00092503          	lw	a0,0(s2)
    80003eb4:	fffff097          	auipc	ra,0xfffff
    80003eb8:	74e080e7          	jalr	1870(ra) # 80003602 <iget>
    80003ebc:	a011                	j	80003ec0 <dirlookup+0xa0>
  return 0;
    80003ebe:	4501                	li	a0,0
}
    80003ec0:	70e2                	ld	ra,56(sp)
    80003ec2:	7442                	ld	s0,48(sp)
    80003ec4:	74a2                	ld	s1,40(sp)
    80003ec6:	7902                	ld	s2,32(sp)
    80003ec8:	69e2                	ld	s3,24(sp)
    80003eca:	6a42                	ld	s4,16(sp)
    80003ecc:	6121                	addi	sp,sp,64
    80003ece:	8082                	ret

0000000080003ed0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ed0:	711d                	addi	sp,sp,-96
    80003ed2:	ec86                	sd	ra,88(sp)
    80003ed4:	e8a2                	sd	s0,80(sp)
    80003ed6:	e4a6                	sd	s1,72(sp)
    80003ed8:	e0ca                	sd	s2,64(sp)
    80003eda:	fc4e                	sd	s3,56(sp)
    80003edc:	f852                	sd	s4,48(sp)
    80003ede:	f456                	sd	s5,40(sp)
    80003ee0:	f05a                	sd	s6,32(sp)
    80003ee2:	ec5e                	sd	s7,24(sp)
    80003ee4:	e862                	sd	s8,16(sp)
    80003ee6:	e466                	sd	s9,8(sp)
    80003ee8:	e06a                	sd	s10,0(sp)
    80003eea:	1080                	addi	s0,sp,96
    80003eec:	84aa                	mv	s1,a0
    80003eee:	8b2e                	mv	s6,a1
    80003ef0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ef2:	00054703          	lbu	a4,0(a0)
    80003ef6:	02f00793          	li	a5,47
    80003efa:	02f70363          	beq	a4,a5,80003f20 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003efe:	ffffe097          	auipc	ra,0xffffe
    80003f02:	b8c080e7          	jalr	-1140(ra) # 80001a8a <myproc>
    80003f06:	15053503          	ld	a0,336(a0)
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	9f4080e7          	jalr	-1548(ra) # 800038fe <idup>
    80003f12:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f14:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f18:	4cb5                	li	s9,13
  len = path - s;
    80003f1a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f1c:	4c05                	li	s8,1
    80003f1e:	a87d                	j	80003fdc <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003f20:	4585                	li	a1,1
    80003f22:	4505                	li	a0,1
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	6de080e7          	jalr	1758(ra) # 80003602 <iget>
    80003f2c:	8a2a                	mv	s4,a0
    80003f2e:	b7dd                	j	80003f14 <namex+0x44>
      iunlockput(ip);
    80003f30:	8552                	mv	a0,s4
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	c6c080e7          	jalr	-916(ra) # 80003b9e <iunlockput>
      return 0;
    80003f3a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f3c:	8552                	mv	a0,s4
    80003f3e:	60e6                	ld	ra,88(sp)
    80003f40:	6446                	ld	s0,80(sp)
    80003f42:	64a6                	ld	s1,72(sp)
    80003f44:	6906                	ld	s2,64(sp)
    80003f46:	79e2                	ld	s3,56(sp)
    80003f48:	7a42                	ld	s4,48(sp)
    80003f4a:	7aa2                	ld	s5,40(sp)
    80003f4c:	7b02                	ld	s6,32(sp)
    80003f4e:	6be2                	ld	s7,24(sp)
    80003f50:	6c42                	ld	s8,16(sp)
    80003f52:	6ca2                	ld	s9,8(sp)
    80003f54:	6d02                	ld	s10,0(sp)
    80003f56:	6125                	addi	sp,sp,96
    80003f58:	8082                	ret
      iunlock(ip);
    80003f5a:	8552                	mv	a0,s4
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	aa2080e7          	jalr	-1374(ra) # 800039fe <iunlock>
      return ip;
    80003f64:	bfe1                	j	80003f3c <namex+0x6c>
      iunlockput(ip);
    80003f66:	8552                	mv	a0,s4
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	c36080e7          	jalr	-970(ra) # 80003b9e <iunlockput>
      return 0;
    80003f70:	8a4e                	mv	s4,s3
    80003f72:	b7e9                	j	80003f3c <namex+0x6c>
  len = path - s;
    80003f74:	40998633          	sub	a2,s3,s1
    80003f78:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003f7c:	09acd863          	bge	s9,s10,8000400c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003f80:	4639                	li	a2,14
    80003f82:	85a6                	mv	a1,s1
    80003f84:	8556                	mv	a0,s5
    80003f86:	ffffd097          	auipc	ra,0xffffd
    80003f8a:	da8080e7          	jalr	-600(ra) # 80000d2e <memmove>
    80003f8e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f90:	0004c783          	lbu	a5,0(s1)
    80003f94:	01279763          	bne	a5,s2,80003fa2 <namex+0xd2>
    path++;
    80003f98:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f9a:	0004c783          	lbu	a5,0(s1)
    80003f9e:	ff278de3          	beq	a5,s2,80003f98 <namex+0xc8>
    ilock(ip);
    80003fa2:	8552                	mv	a0,s4
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	998080e7          	jalr	-1640(ra) # 8000393c <ilock>
    if(ip->type != T_DIR){
    80003fac:	044a1783          	lh	a5,68(s4)
    80003fb0:	f98790e3          	bne	a5,s8,80003f30 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003fb4:	000b0563          	beqz	s6,80003fbe <namex+0xee>
    80003fb8:	0004c783          	lbu	a5,0(s1)
    80003fbc:	dfd9                	beqz	a5,80003f5a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fbe:	865e                	mv	a2,s7
    80003fc0:	85d6                	mv	a1,s5
    80003fc2:	8552                	mv	a0,s4
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	e5c080e7          	jalr	-420(ra) # 80003e20 <dirlookup>
    80003fcc:	89aa                	mv	s3,a0
    80003fce:	dd41                	beqz	a0,80003f66 <namex+0x96>
    iunlockput(ip);
    80003fd0:	8552                	mv	a0,s4
    80003fd2:	00000097          	auipc	ra,0x0
    80003fd6:	bcc080e7          	jalr	-1076(ra) # 80003b9e <iunlockput>
    ip = next;
    80003fda:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003fdc:	0004c783          	lbu	a5,0(s1)
    80003fe0:	01279763          	bne	a5,s2,80003fee <namex+0x11e>
    path++;
    80003fe4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fe6:	0004c783          	lbu	a5,0(s1)
    80003fea:	ff278de3          	beq	a5,s2,80003fe4 <namex+0x114>
  if(*path == 0)
    80003fee:	cb9d                	beqz	a5,80004024 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003ff0:	0004c783          	lbu	a5,0(s1)
    80003ff4:	89a6                	mv	s3,s1
  len = path - s;
    80003ff6:	8d5e                	mv	s10,s7
    80003ff8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ffa:	01278963          	beq	a5,s2,8000400c <namex+0x13c>
    80003ffe:	dbbd                	beqz	a5,80003f74 <namex+0xa4>
    path++;
    80004000:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004002:	0009c783          	lbu	a5,0(s3)
    80004006:	ff279ce3          	bne	a5,s2,80003ffe <namex+0x12e>
    8000400a:	b7ad                	j	80003f74 <namex+0xa4>
    memmove(name, s, len);
    8000400c:	2601                	sext.w	a2,a2
    8000400e:	85a6                	mv	a1,s1
    80004010:	8556                	mv	a0,s5
    80004012:	ffffd097          	auipc	ra,0xffffd
    80004016:	d1c080e7          	jalr	-740(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000401a:	9d56                	add	s10,s10,s5
    8000401c:	000d0023          	sb	zero,0(s10)
    80004020:	84ce                	mv	s1,s3
    80004022:	b7bd                	j	80003f90 <namex+0xc0>
  if(nameiparent){
    80004024:	f00b0ce3          	beqz	s6,80003f3c <namex+0x6c>
    iput(ip);
    80004028:	8552                	mv	a0,s4
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	acc080e7          	jalr	-1332(ra) # 80003af6 <iput>
    return 0;
    80004032:	4a01                	li	s4,0
    80004034:	b721                	j	80003f3c <namex+0x6c>

0000000080004036 <dirlink>:
{
    80004036:	7139                	addi	sp,sp,-64
    80004038:	fc06                	sd	ra,56(sp)
    8000403a:	f822                	sd	s0,48(sp)
    8000403c:	f426                	sd	s1,40(sp)
    8000403e:	f04a                	sd	s2,32(sp)
    80004040:	ec4e                	sd	s3,24(sp)
    80004042:	e852                	sd	s4,16(sp)
    80004044:	0080                	addi	s0,sp,64
    80004046:	892a                	mv	s2,a0
    80004048:	8a2e                	mv	s4,a1
    8000404a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000404c:	4601                	li	a2,0
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	dd2080e7          	jalr	-558(ra) # 80003e20 <dirlookup>
    80004056:	e93d                	bnez	a0,800040cc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004058:	04c92483          	lw	s1,76(s2)
    8000405c:	c49d                	beqz	s1,8000408a <dirlink+0x54>
    8000405e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004060:	4741                	li	a4,16
    80004062:	86a6                	mv	a3,s1
    80004064:	fc040613          	addi	a2,s0,-64
    80004068:	4581                	li	a1,0
    8000406a:	854a                	mv	a0,s2
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	b84080e7          	jalr	-1148(ra) # 80003bf0 <readi>
    80004074:	47c1                	li	a5,16
    80004076:	06f51163          	bne	a0,a5,800040d8 <dirlink+0xa2>
    if(de.inum == 0)
    8000407a:	fc045783          	lhu	a5,-64(s0)
    8000407e:	c791                	beqz	a5,8000408a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004080:	24c1                	addiw	s1,s1,16
    80004082:	04c92783          	lw	a5,76(s2)
    80004086:	fcf4ede3          	bltu	s1,a5,80004060 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000408a:	4639                	li	a2,14
    8000408c:	85d2                	mv	a1,s4
    8000408e:	fc240513          	addi	a0,s0,-62
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	d4c080e7          	jalr	-692(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000409a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409e:	4741                	li	a4,16
    800040a0:	86a6                	mv	a3,s1
    800040a2:	fc040613          	addi	a2,s0,-64
    800040a6:	4581                	li	a1,0
    800040a8:	854a                	mv	a0,s2
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	c3e080e7          	jalr	-962(ra) # 80003ce8 <writei>
    800040b2:	1541                	addi	a0,a0,-16
    800040b4:	00a03533          	snez	a0,a0
    800040b8:	40a00533          	neg	a0,a0
}
    800040bc:	70e2                	ld	ra,56(sp)
    800040be:	7442                	ld	s0,48(sp)
    800040c0:	74a2                	ld	s1,40(sp)
    800040c2:	7902                	ld	s2,32(sp)
    800040c4:	69e2                	ld	s3,24(sp)
    800040c6:	6a42                	ld	s4,16(sp)
    800040c8:	6121                	addi	sp,sp,64
    800040ca:	8082                	ret
    iput(ip);
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	a2a080e7          	jalr	-1494(ra) # 80003af6 <iput>
    return -1;
    800040d4:	557d                	li	a0,-1
    800040d6:	b7dd                	j	800040bc <dirlink+0x86>
      panic("dirlink read");
    800040d8:	00004517          	auipc	a0,0x4
    800040dc:	62850513          	addi	a0,a0,1576 # 80008700 <syscalls+0x1e0>
    800040e0:	ffffc097          	auipc	ra,0xffffc
    800040e4:	460080e7          	jalr	1120(ra) # 80000540 <panic>

00000000800040e8 <namei>:

struct inode*
namei(char *path)
{
    800040e8:	1101                	addi	sp,sp,-32
    800040ea:	ec06                	sd	ra,24(sp)
    800040ec:	e822                	sd	s0,16(sp)
    800040ee:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040f0:	fe040613          	addi	a2,s0,-32
    800040f4:	4581                	li	a1,0
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	dda080e7          	jalr	-550(ra) # 80003ed0 <namex>
}
    800040fe:	60e2                	ld	ra,24(sp)
    80004100:	6442                	ld	s0,16(sp)
    80004102:	6105                	addi	sp,sp,32
    80004104:	8082                	ret

0000000080004106 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004106:	1141                	addi	sp,sp,-16
    80004108:	e406                	sd	ra,8(sp)
    8000410a:	e022                	sd	s0,0(sp)
    8000410c:	0800                	addi	s0,sp,16
    8000410e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004110:	4585                	li	a1,1
    80004112:	00000097          	auipc	ra,0x0
    80004116:	dbe080e7          	jalr	-578(ra) # 80003ed0 <namex>
}
    8000411a:	60a2                	ld	ra,8(sp)
    8000411c:	6402                	ld	s0,0(sp)
    8000411e:	0141                	addi	sp,sp,16
    80004120:	8082                	ret

0000000080004122 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004122:	1101                	addi	sp,sp,-32
    80004124:	ec06                	sd	ra,24(sp)
    80004126:	e822                	sd	s0,16(sp)
    80004128:	e426                	sd	s1,8(sp)
    8000412a:	e04a                	sd	s2,0(sp)
    8000412c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000412e:	0001d917          	auipc	s2,0x1d
    80004132:	b1290913          	addi	s2,s2,-1262 # 80020c40 <log>
    80004136:	01892583          	lw	a1,24(s2)
    8000413a:	02892503          	lw	a0,40(s2)
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	fe6080e7          	jalr	-26(ra) # 80003124 <bread>
    80004146:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004148:	02c92683          	lw	a3,44(s2)
    8000414c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000414e:	02d05863          	blez	a3,8000417e <write_head+0x5c>
    80004152:	0001d797          	auipc	a5,0x1d
    80004156:	b1e78793          	addi	a5,a5,-1250 # 80020c70 <log+0x30>
    8000415a:	05c50713          	addi	a4,a0,92
    8000415e:	36fd                	addiw	a3,a3,-1
    80004160:	02069613          	slli	a2,a3,0x20
    80004164:	01e65693          	srli	a3,a2,0x1e
    80004168:	0001d617          	auipc	a2,0x1d
    8000416c:	b0c60613          	addi	a2,a2,-1268 # 80020c74 <log+0x34>
    80004170:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004172:	4390                	lw	a2,0(a5)
    80004174:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004176:	0791                	addi	a5,a5,4
    80004178:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000417a:	fed79ce3          	bne	a5,a3,80004172 <write_head+0x50>
  }
  bwrite(buf);
    8000417e:	8526                	mv	a0,s1
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	096080e7          	jalr	150(ra) # 80003216 <bwrite>
  brelse(buf);
    80004188:	8526                	mv	a0,s1
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	0ca080e7          	jalr	202(ra) # 80003254 <brelse>
}
    80004192:	60e2                	ld	ra,24(sp)
    80004194:	6442                	ld	s0,16(sp)
    80004196:	64a2                	ld	s1,8(sp)
    80004198:	6902                	ld	s2,0(sp)
    8000419a:	6105                	addi	sp,sp,32
    8000419c:	8082                	ret

000000008000419e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000419e:	0001d797          	auipc	a5,0x1d
    800041a2:	ace7a783          	lw	a5,-1330(a5) # 80020c6c <log+0x2c>
    800041a6:	0af05d63          	blez	a5,80004260 <install_trans+0xc2>
{
    800041aa:	7139                	addi	sp,sp,-64
    800041ac:	fc06                	sd	ra,56(sp)
    800041ae:	f822                	sd	s0,48(sp)
    800041b0:	f426                	sd	s1,40(sp)
    800041b2:	f04a                	sd	s2,32(sp)
    800041b4:	ec4e                	sd	s3,24(sp)
    800041b6:	e852                	sd	s4,16(sp)
    800041b8:	e456                	sd	s5,8(sp)
    800041ba:	e05a                	sd	s6,0(sp)
    800041bc:	0080                	addi	s0,sp,64
    800041be:	8b2a                	mv	s6,a0
    800041c0:	0001da97          	auipc	s5,0x1d
    800041c4:	ab0a8a93          	addi	s5,s5,-1360 # 80020c70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ca:	0001d997          	auipc	s3,0x1d
    800041ce:	a7698993          	addi	s3,s3,-1418 # 80020c40 <log>
    800041d2:	a00d                	j	800041f4 <install_trans+0x56>
    brelse(lbuf);
    800041d4:	854a                	mv	a0,s2
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	07e080e7          	jalr	126(ra) # 80003254 <brelse>
    brelse(dbuf);
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	074080e7          	jalr	116(ra) # 80003254 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e8:	2a05                	addiw	s4,s4,1
    800041ea:	0a91                	addi	s5,s5,4
    800041ec:	02c9a783          	lw	a5,44(s3)
    800041f0:	04fa5e63          	bge	s4,a5,8000424c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f4:	0189a583          	lw	a1,24(s3)
    800041f8:	014585bb          	addw	a1,a1,s4
    800041fc:	2585                	addiw	a1,a1,1
    800041fe:	0289a503          	lw	a0,40(s3)
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	f22080e7          	jalr	-222(ra) # 80003124 <bread>
    8000420a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000420c:	000aa583          	lw	a1,0(s5)
    80004210:	0289a503          	lw	a0,40(s3)
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	f10080e7          	jalr	-240(ra) # 80003124 <bread>
    8000421c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000421e:	40000613          	li	a2,1024
    80004222:	05890593          	addi	a1,s2,88
    80004226:	05850513          	addi	a0,a0,88
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	b04080e7          	jalr	-1276(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004232:	8526                	mv	a0,s1
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	fe2080e7          	jalr	-30(ra) # 80003216 <bwrite>
    if(recovering == 0)
    8000423c:	f80b1ce3          	bnez	s6,800041d4 <install_trans+0x36>
      bunpin(dbuf);
    80004240:	8526                	mv	a0,s1
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	0ec080e7          	jalr	236(ra) # 8000332e <bunpin>
    8000424a:	b769                	j	800041d4 <install_trans+0x36>
}
    8000424c:	70e2                	ld	ra,56(sp)
    8000424e:	7442                	ld	s0,48(sp)
    80004250:	74a2                	ld	s1,40(sp)
    80004252:	7902                	ld	s2,32(sp)
    80004254:	69e2                	ld	s3,24(sp)
    80004256:	6a42                	ld	s4,16(sp)
    80004258:	6aa2                	ld	s5,8(sp)
    8000425a:	6b02                	ld	s6,0(sp)
    8000425c:	6121                	addi	sp,sp,64
    8000425e:	8082                	ret
    80004260:	8082                	ret

0000000080004262 <initlog>:
{
    80004262:	7179                	addi	sp,sp,-48
    80004264:	f406                	sd	ra,40(sp)
    80004266:	f022                	sd	s0,32(sp)
    80004268:	ec26                	sd	s1,24(sp)
    8000426a:	e84a                	sd	s2,16(sp)
    8000426c:	e44e                	sd	s3,8(sp)
    8000426e:	1800                	addi	s0,sp,48
    80004270:	892a                	mv	s2,a0
    80004272:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004274:	0001d497          	auipc	s1,0x1d
    80004278:	9cc48493          	addi	s1,s1,-1588 # 80020c40 <log>
    8000427c:	00004597          	auipc	a1,0x4
    80004280:	49458593          	addi	a1,a1,1172 # 80008710 <syscalls+0x1f0>
    80004284:	8526                	mv	a0,s1
    80004286:	ffffd097          	auipc	ra,0xffffd
    8000428a:	8c0080e7          	jalr	-1856(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000428e:	0149a583          	lw	a1,20(s3)
    80004292:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004294:	0109a783          	lw	a5,16(s3)
    80004298:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000429a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000429e:	854a                	mv	a0,s2
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	e84080e7          	jalr	-380(ra) # 80003124 <bread>
  log.lh.n = lh->n;
    800042a8:	4d34                	lw	a3,88(a0)
    800042aa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ac:	02d05663          	blez	a3,800042d8 <initlog+0x76>
    800042b0:	05c50793          	addi	a5,a0,92
    800042b4:	0001d717          	auipc	a4,0x1d
    800042b8:	9bc70713          	addi	a4,a4,-1604 # 80020c70 <log+0x30>
    800042bc:	36fd                	addiw	a3,a3,-1
    800042be:	02069613          	slli	a2,a3,0x20
    800042c2:	01e65693          	srli	a3,a2,0x1e
    800042c6:	06050613          	addi	a2,a0,96
    800042ca:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042cc:	4390                	lw	a2,0(a5)
    800042ce:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042d0:	0791                	addi	a5,a5,4
    800042d2:	0711                	addi	a4,a4,4
    800042d4:	fed79ce3          	bne	a5,a3,800042cc <initlog+0x6a>
  brelse(buf);
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	f7c080e7          	jalr	-132(ra) # 80003254 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042e0:	4505                	li	a0,1
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	ebc080e7          	jalr	-324(ra) # 8000419e <install_trans>
  log.lh.n = 0;
    800042ea:	0001d797          	auipc	a5,0x1d
    800042ee:	9807a123          	sw	zero,-1662(a5) # 80020c6c <log+0x2c>
  write_head(); // clear the log
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	e30080e7          	jalr	-464(ra) # 80004122 <write_head>
}
    800042fa:	70a2                	ld	ra,40(sp)
    800042fc:	7402                	ld	s0,32(sp)
    800042fe:	64e2                	ld	s1,24(sp)
    80004300:	6942                	ld	s2,16(sp)
    80004302:	69a2                	ld	s3,8(sp)
    80004304:	6145                	addi	sp,sp,48
    80004306:	8082                	ret

0000000080004308 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004308:	1101                	addi	sp,sp,-32
    8000430a:	ec06                	sd	ra,24(sp)
    8000430c:	e822                	sd	s0,16(sp)
    8000430e:	e426                	sd	s1,8(sp)
    80004310:	e04a                	sd	s2,0(sp)
    80004312:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004314:	0001d517          	auipc	a0,0x1d
    80004318:	92c50513          	addi	a0,a0,-1748 # 80020c40 <log>
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	8ba080e7          	jalr	-1862(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004324:	0001d497          	auipc	s1,0x1d
    80004328:	91c48493          	addi	s1,s1,-1764 # 80020c40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000432c:	4979                	li	s2,30
    8000432e:	a039                	j	8000433c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004330:	85a6                	mv	a1,s1
    80004332:	8526                	mv	a0,s1
    80004334:	ffffe097          	auipc	ra,0xffffe
    80004338:	ebe080e7          	jalr	-322(ra) # 800021f2 <sleep>
    if(log.committing){
    8000433c:	50dc                	lw	a5,36(s1)
    8000433e:	fbed                	bnez	a5,80004330 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004340:	5098                	lw	a4,32(s1)
    80004342:	2705                	addiw	a4,a4,1
    80004344:	0007069b          	sext.w	a3,a4
    80004348:	0027179b          	slliw	a5,a4,0x2
    8000434c:	9fb9                	addw	a5,a5,a4
    8000434e:	0017979b          	slliw	a5,a5,0x1
    80004352:	54d8                	lw	a4,44(s1)
    80004354:	9fb9                	addw	a5,a5,a4
    80004356:	00f95963          	bge	s2,a5,80004368 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000435a:	85a6                	mv	a1,s1
    8000435c:	8526                	mv	a0,s1
    8000435e:	ffffe097          	auipc	ra,0xffffe
    80004362:	e94080e7          	jalr	-364(ra) # 800021f2 <sleep>
    80004366:	bfd9                	j	8000433c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004368:	0001d517          	auipc	a0,0x1d
    8000436c:	8d850513          	addi	a0,a0,-1832 # 80020c40 <log>
    80004370:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004372:	ffffd097          	auipc	ra,0xffffd
    80004376:	918080e7          	jalr	-1768(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000437a:	60e2                	ld	ra,24(sp)
    8000437c:	6442                	ld	s0,16(sp)
    8000437e:	64a2                	ld	s1,8(sp)
    80004380:	6902                	ld	s2,0(sp)
    80004382:	6105                	addi	sp,sp,32
    80004384:	8082                	ret

0000000080004386 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004386:	7139                	addi	sp,sp,-64
    80004388:	fc06                	sd	ra,56(sp)
    8000438a:	f822                	sd	s0,48(sp)
    8000438c:	f426                	sd	s1,40(sp)
    8000438e:	f04a                	sd	s2,32(sp)
    80004390:	ec4e                	sd	s3,24(sp)
    80004392:	e852                	sd	s4,16(sp)
    80004394:	e456                	sd	s5,8(sp)
    80004396:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004398:	0001d497          	auipc	s1,0x1d
    8000439c:	8a848493          	addi	s1,s1,-1880 # 80020c40 <log>
    800043a0:	8526                	mv	a0,s1
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	834080e7          	jalr	-1996(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800043aa:	509c                	lw	a5,32(s1)
    800043ac:	37fd                	addiw	a5,a5,-1
    800043ae:	0007891b          	sext.w	s2,a5
    800043b2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043b4:	50dc                	lw	a5,36(s1)
    800043b6:	e7b9                	bnez	a5,80004404 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043b8:	04091e63          	bnez	s2,80004414 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043bc:	0001d497          	auipc	s1,0x1d
    800043c0:	88448493          	addi	s1,s1,-1916 # 80020c40 <log>
    800043c4:	4785                	li	a5,1
    800043c6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	8c0080e7          	jalr	-1856(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043d2:	54dc                	lw	a5,44(s1)
    800043d4:	06f04763          	bgtz	a5,80004442 <end_op+0xbc>
    acquire(&log.lock);
    800043d8:	0001d497          	auipc	s1,0x1d
    800043dc:	86848493          	addi	s1,s1,-1944 # 80020c40 <log>
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	7f4080e7          	jalr	2036(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800043ea:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043ee:	8526                	mv	a0,s1
    800043f0:	ffffe097          	auipc	ra,0xffffe
    800043f4:	e66080e7          	jalr	-410(ra) # 80002256 <wakeup>
    release(&log.lock);
    800043f8:	8526                	mv	a0,s1
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	890080e7          	jalr	-1904(ra) # 80000c8a <release>
}
    80004402:	a03d                	j	80004430 <end_op+0xaa>
    panic("log.committing");
    80004404:	00004517          	auipc	a0,0x4
    80004408:	31450513          	addi	a0,a0,788 # 80008718 <syscalls+0x1f8>
    8000440c:	ffffc097          	auipc	ra,0xffffc
    80004410:	134080e7          	jalr	308(ra) # 80000540 <panic>
    wakeup(&log);
    80004414:	0001d497          	auipc	s1,0x1d
    80004418:	82c48493          	addi	s1,s1,-2004 # 80020c40 <log>
    8000441c:	8526                	mv	a0,s1
    8000441e:	ffffe097          	auipc	ra,0xffffe
    80004422:	e38080e7          	jalr	-456(ra) # 80002256 <wakeup>
  release(&log.lock);
    80004426:	8526                	mv	a0,s1
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
}
    80004430:	70e2                	ld	ra,56(sp)
    80004432:	7442                	ld	s0,48(sp)
    80004434:	74a2                	ld	s1,40(sp)
    80004436:	7902                	ld	s2,32(sp)
    80004438:	69e2                	ld	s3,24(sp)
    8000443a:	6a42                	ld	s4,16(sp)
    8000443c:	6aa2                	ld	s5,8(sp)
    8000443e:	6121                	addi	sp,sp,64
    80004440:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004442:	0001da97          	auipc	s5,0x1d
    80004446:	82ea8a93          	addi	s5,s5,-2002 # 80020c70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000444a:	0001ca17          	auipc	s4,0x1c
    8000444e:	7f6a0a13          	addi	s4,s4,2038 # 80020c40 <log>
    80004452:	018a2583          	lw	a1,24(s4)
    80004456:	012585bb          	addw	a1,a1,s2
    8000445a:	2585                	addiw	a1,a1,1
    8000445c:	028a2503          	lw	a0,40(s4)
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	cc4080e7          	jalr	-828(ra) # 80003124 <bread>
    80004468:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000446a:	000aa583          	lw	a1,0(s5)
    8000446e:	028a2503          	lw	a0,40(s4)
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	cb2080e7          	jalr	-846(ra) # 80003124 <bread>
    8000447a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000447c:	40000613          	li	a2,1024
    80004480:	05850593          	addi	a1,a0,88
    80004484:	05848513          	addi	a0,s1,88
    80004488:	ffffd097          	auipc	ra,0xffffd
    8000448c:	8a6080e7          	jalr	-1882(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004490:	8526                	mv	a0,s1
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	d84080e7          	jalr	-636(ra) # 80003216 <bwrite>
    brelse(from);
    8000449a:	854e                	mv	a0,s3
    8000449c:	fffff097          	auipc	ra,0xfffff
    800044a0:	db8080e7          	jalr	-584(ra) # 80003254 <brelse>
    brelse(to);
    800044a4:	8526                	mv	a0,s1
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	dae080e7          	jalr	-594(ra) # 80003254 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ae:	2905                	addiw	s2,s2,1
    800044b0:	0a91                	addi	s5,s5,4
    800044b2:	02ca2783          	lw	a5,44(s4)
    800044b6:	f8f94ee3          	blt	s2,a5,80004452 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	c68080e7          	jalr	-920(ra) # 80004122 <write_head>
    install_trans(0); // Now install writes to home locations
    800044c2:	4501                	li	a0,0
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	cda080e7          	jalr	-806(ra) # 8000419e <install_trans>
    log.lh.n = 0;
    800044cc:	0001c797          	auipc	a5,0x1c
    800044d0:	7a07a023          	sw	zero,1952(a5) # 80020c6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	c4e080e7          	jalr	-946(ra) # 80004122 <write_head>
    800044dc:	bdf5                	j	800043d8 <end_op+0x52>

00000000800044de <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	e04a                	sd	s2,0(sp)
    800044e8:	1000                	addi	s0,sp,32
    800044ea:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044ec:	0001c917          	auipc	s2,0x1c
    800044f0:	75490913          	addi	s2,s2,1876 # 80020c40 <log>
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	6e0080e7          	jalr	1760(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044fe:	02c92603          	lw	a2,44(s2)
    80004502:	47f5                	li	a5,29
    80004504:	06c7c563          	blt	a5,a2,8000456e <log_write+0x90>
    80004508:	0001c797          	auipc	a5,0x1c
    8000450c:	7547a783          	lw	a5,1876(a5) # 80020c5c <log+0x1c>
    80004510:	37fd                	addiw	a5,a5,-1
    80004512:	04f65e63          	bge	a2,a5,8000456e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004516:	0001c797          	auipc	a5,0x1c
    8000451a:	74a7a783          	lw	a5,1866(a5) # 80020c60 <log+0x20>
    8000451e:	06f05063          	blez	a5,8000457e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004522:	4781                	li	a5,0
    80004524:	06c05563          	blez	a2,8000458e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004528:	44cc                	lw	a1,12(s1)
    8000452a:	0001c717          	auipc	a4,0x1c
    8000452e:	74670713          	addi	a4,a4,1862 # 80020c70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004532:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004534:	4314                	lw	a3,0(a4)
    80004536:	04b68c63          	beq	a3,a1,8000458e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000453a:	2785                	addiw	a5,a5,1
    8000453c:	0711                	addi	a4,a4,4
    8000453e:	fef61be3          	bne	a2,a5,80004534 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004542:	0621                	addi	a2,a2,8
    80004544:	060a                	slli	a2,a2,0x2
    80004546:	0001c797          	auipc	a5,0x1c
    8000454a:	6fa78793          	addi	a5,a5,1786 # 80020c40 <log>
    8000454e:	97b2                	add	a5,a5,a2
    80004550:	44d8                	lw	a4,12(s1)
    80004552:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004554:	8526                	mv	a0,s1
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	d9c080e7          	jalr	-612(ra) # 800032f2 <bpin>
    log.lh.n++;
    8000455e:	0001c717          	auipc	a4,0x1c
    80004562:	6e270713          	addi	a4,a4,1762 # 80020c40 <log>
    80004566:	575c                	lw	a5,44(a4)
    80004568:	2785                	addiw	a5,a5,1
    8000456a:	d75c                	sw	a5,44(a4)
    8000456c:	a82d                	j	800045a6 <log_write+0xc8>
    panic("too big a transaction");
    8000456e:	00004517          	auipc	a0,0x4
    80004572:	1ba50513          	addi	a0,a0,442 # 80008728 <syscalls+0x208>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	fca080e7          	jalr	-54(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000457e:	00004517          	auipc	a0,0x4
    80004582:	1c250513          	addi	a0,a0,450 # 80008740 <syscalls+0x220>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fba080e7          	jalr	-70(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000458e:	00878693          	addi	a3,a5,8
    80004592:	068a                	slli	a3,a3,0x2
    80004594:	0001c717          	auipc	a4,0x1c
    80004598:	6ac70713          	addi	a4,a4,1708 # 80020c40 <log>
    8000459c:	9736                	add	a4,a4,a3
    8000459e:	44d4                	lw	a3,12(s1)
    800045a0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045a2:	faf609e3          	beq	a2,a5,80004554 <log_write+0x76>
  }
  release(&log.lock);
    800045a6:	0001c517          	auipc	a0,0x1c
    800045aa:	69a50513          	addi	a0,a0,1690 # 80020c40 <log>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6dc080e7          	jalr	1756(ra) # 80000c8a <release>
}
    800045b6:	60e2                	ld	ra,24(sp)
    800045b8:	6442                	ld	s0,16(sp)
    800045ba:	64a2                	ld	s1,8(sp)
    800045bc:	6902                	ld	s2,0(sp)
    800045be:	6105                	addi	sp,sp,32
    800045c0:	8082                	ret

00000000800045c2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045c2:	1101                	addi	sp,sp,-32
    800045c4:	ec06                	sd	ra,24(sp)
    800045c6:	e822                	sd	s0,16(sp)
    800045c8:	e426                	sd	s1,8(sp)
    800045ca:	e04a                	sd	s2,0(sp)
    800045cc:	1000                	addi	s0,sp,32
    800045ce:	84aa                	mv	s1,a0
    800045d0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045d2:	00004597          	auipc	a1,0x4
    800045d6:	18e58593          	addi	a1,a1,398 # 80008760 <syscalls+0x240>
    800045da:	0521                	addi	a0,a0,8
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	56a080e7          	jalr	1386(ra) # 80000b46 <initlock>
  lk->name = name;
    800045e4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045e8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ec:	0204a423          	sw	zero,40(s1)
}
    800045f0:	60e2                	ld	ra,24(sp)
    800045f2:	6442                	ld	s0,16(sp)
    800045f4:	64a2                	ld	s1,8(sp)
    800045f6:	6902                	ld	s2,0(sp)
    800045f8:	6105                	addi	sp,sp,32
    800045fa:	8082                	ret

00000000800045fc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045fc:	1101                	addi	sp,sp,-32
    800045fe:	ec06                	sd	ra,24(sp)
    80004600:	e822                	sd	s0,16(sp)
    80004602:	e426                	sd	s1,8(sp)
    80004604:	e04a                	sd	s2,0(sp)
    80004606:	1000                	addi	s0,sp,32
    80004608:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000460a:	00850913          	addi	s2,a0,8
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	5c6080e7          	jalr	1478(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004618:	409c                	lw	a5,0(s1)
    8000461a:	cb89                	beqz	a5,8000462c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000461c:	85ca                	mv	a1,s2
    8000461e:	8526                	mv	a0,s1
    80004620:	ffffe097          	auipc	ra,0xffffe
    80004624:	bd2080e7          	jalr	-1070(ra) # 800021f2 <sleep>
  while (lk->locked) {
    80004628:	409c                	lw	a5,0(s1)
    8000462a:	fbed                	bnez	a5,8000461c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000462c:	4785                	li	a5,1
    8000462e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004630:	ffffd097          	auipc	ra,0xffffd
    80004634:	45a080e7          	jalr	1114(ra) # 80001a8a <myproc>
    80004638:	591c                	lw	a5,48(a0)
    8000463a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000463c:	854a                	mv	a0,s2
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	64c080e7          	jalr	1612(ra) # 80000c8a <release>
}
    80004646:	60e2                	ld	ra,24(sp)
    80004648:	6442                	ld	s0,16(sp)
    8000464a:	64a2                	ld	s1,8(sp)
    8000464c:	6902                	ld	s2,0(sp)
    8000464e:	6105                	addi	sp,sp,32
    80004650:	8082                	ret

0000000080004652 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004652:	1101                	addi	sp,sp,-32
    80004654:	ec06                	sd	ra,24(sp)
    80004656:	e822                	sd	s0,16(sp)
    80004658:	e426                	sd	s1,8(sp)
    8000465a:	e04a                	sd	s2,0(sp)
    8000465c:	1000                	addi	s0,sp,32
    8000465e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004660:	00850913          	addi	s2,a0,8
    80004664:	854a                	mv	a0,s2
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	570080e7          	jalr	1392(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000466e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004672:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004676:	8526                	mv	a0,s1
    80004678:	ffffe097          	auipc	ra,0xffffe
    8000467c:	bde080e7          	jalr	-1058(ra) # 80002256 <wakeup>
  release(&lk->lk);
    80004680:	854a                	mv	a0,s2
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	608080e7          	jalr	1544(ra) # 80000c8a <release>
}
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	64a2                	ld	s1,8(sp)
    80004690:	6902                	ld	s2,0(sp)
    80004692:	6105                	addi	sp,sp,32
    80004694:	8082                	ret

0000000080004696 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004696:	7179                	addi	sp,sp,-48
    80004698:	f406                	sd	ra,40(sp)
    8000469a:	f022                	sd	s0,32(sp)
    8000469c:	ec26                	sd	s1,24(sp)
    8000469e:	e84a                	sd	s2,16(sp)
    800046a0:	e44e                	sd	s3,8(sp)
    800046a2:	1800                	addi	s0,sp,48
    800046a4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046a6:	00850913          	addi	s2,a0,8
    800046aa:	854a                	mv	a0,s2
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	52a080e7          	jalr	1322(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046b4:	409c                	lw	a5,0(s1)
    800046b6:	ef99                	bnez	a5,800046d4 <holdingsleep+0x3e>
    800046b8:	4481                	li	s1,0
  release(&lk->lk);
    800046ba:	854a                	mv	a0,s2
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	5ce080e7          	jalr	1486(ra) # 80000c8a <release>
  return r;
}
    800046c4:	8526                	mv	a0,s1
    800046c6:	70a2                	ld	ra,40(sp)
    800046c8:	7402                	ld	s0,32(sp)
    800046ca:	64e2                	ld	s1,24(sp)
    800046cc:	6942                	ld	s2,16(sp)
    800046ce:	69a2                	ld	s3,8(sp)
    800046d0:	6145                	addi	sp,sp,48
    800046d2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046d4:	0284a983          	lw	s3,40(s1)
    800046d8:	ffffd097          	auipc	ra,0xffffd
    800046dc:	3b2080e7          	jalr	946(ra) # 80001a8a <myproc>
    800046e0:	5904                	lw	s1,48(a0)
    800046e2:	413484b3          	sub	s1,s1,s3
    800046e6:	0014b493          	seqz	s1,s1
    800046ea:	bfc1                	j	800046ba <holdingsleep+0x24>

00000000800046ec <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046ec:	1141                	addi	sp,sp,-16
    800046ee:	e406                	sd	ra,8(sp)
    800046f0:	e022                	sd	s0,0(sp)
    800046f2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046f4:	00004597          	auipc	a1,0x4
    800046f8:	07c58593          	addi	a1,a1,124 # 80008770 <syscalls+0x250>
    800046fc:	0001c517          	auipc	a0,0x1c
    80004700:	68c50513          	addi	a0,a0,1676 # 80020d88 <ftable>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	442080e7          	jalr	1090(ra) # 80000b46 <initlock>
}
    8000470c:	60a2                	ld	ra,8(sp)
    8000470e:	6402                	ld	s0,0(sp)
    80004710:	0141                	addi	sp,sp,16
    80004712:	8082                	ret

0000000080004714 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004714:	1101                	addi	sp,sp,-32
    80004716:	ec06                	sd	ra,24(sp)
    80004718:	e822                	sd	s0,16(sp)
    8000471a:	e426                	sd	s1,8(sp)
    8000471c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000471e:	0001c517          	auipc	a0,0x1c
    80004722:	66a50513          	addi	a0,a0,1642 # 80020d88 <ftable>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	4b0080e7          	jalr	1200(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000472e:	0001c497          	auipc	s1,0x1c
    80004732:	67248493          	addi	s1,s1,1650 # 80020da0 <ftable+0x18>
    80004736:	0001d717          	auipc	a4,0x1d
    8000473a:	60a70713          	addi	a4,a4,1546 # 80021d40 <disk>
    if(f->ref == 0){
    8000473e:	40dc                	lw	a5,4(s1)
    80004740:	cf99                	beqz	a5,8000475e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004742:	02848493          	addi	s1,s1,40
    80004746:	fee49ce3          	bne	s1,a4,8000473e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000474a:	0001c517          	auipc	a0,0x1c
    8000474e:	63e50513          	addi	a0,a0,1598 # 80020d88 <ftable>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	538080e7          	jalr	1336(ra) # 80000c8a <release>
  return 0;
    8000475a:	4481                	li	s1,0
    8000475c:	a819                	j	80004772 <filealloc+0x5e>
      f->ref = 1;
    8000475e:	4785                	li	a5,1
    80004760:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004762:	0001c517          	auipc	a0,0x1c
    80004766:	62650513          	addi	a0,a0,1574 # 80020d88 <ftable>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	520080e7          	jalr	1312(ra) # 80000c8a <release>
}
    80004772:	8526                	mv	a0,s1
    80004774:	60e2                	ld	ra,24(sp)
    80004776:	6442                	ld	s0,16(sp)
    80004778:	64a2                	ld	s1,8(sp)
    8000477a:	6105                	addi	sp,sp,32
    8000477c:	8082                	ret

000000008000477e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000477e:	1101                	addi	sp,sp,-32
    80004780:	ec06                	sd	ra,24(sp)
    80004782:	e822                	sd	s0,16(sp)
    80004784:	e426                	sd	s1,8(sp)
    80004786:	1000                	addi	s0,sp,32
    80004788:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000478a:	0001c517          	auipc	a0,0x1c
    8000478e:	5fe50513          	addi	a0,a0,1534 # 80020d88 <ftable>
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	444080e7          	jalr	1092(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000479a:	40dc                	lw	a5,4(s1)
    8000479c:	02f05263          	blez	a5,800047c0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047a0:	2785                	addiw	a5,a5,1
    800047a2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047a4:	0001c517          	auipc	a0,0x1c
    800047a8:	5e450513          	addi	a0,a0,1508 # 80020d88 <ftable>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	4de080e7          	jalr	1246(ra) # 80000c8a <release>
  return f;
}
    800047b4:	8526                	mv	a0,s1
    800047b6:	60e2                	ld	ra,24(sp)
    800047b8:	6442                	ld	s0,16(sp)
    800047ba:	64a2                	ld	s1,8(sp)
    800047bc:	6105                	addi	sp,sp,32
    800047be:	8082                	ret
    panic("filedup");
    800047c0:	00004517          	auipc	a0,0x4
    800047c4:	fb850513          	addi	a0,a0,-72 # 80008778 <syscalls+0x258>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	d78080e7          	jalr	-648(ra) # 80000540 <panic>

00000000800047d0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047d0:	7139                	addi	sp,sp,-64
    800047d2:	fc06                	sd	ra,56(sp)
    800047d4:	f822                	sd	s0,48(sp)
    800047d6:	f426                	sd	s1,40(sp)
    800047d8:	f04a                	sd	s2,32(sp)
    800047da:	ec4e                	sd	s3,24(sp)
    800047dc:	e852                	sd	s4,16(sp)
    800047de:	e456                	sd	s5,8(sp)
    800047e0:	0080                	addi	s0,sp,64
    800047e2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047e4:	0001c517          	auipc	a0,0x1c
    800047e8:	5a450513          	addi	a0,a0,1444 # 80020d88 <ftable>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	3ea080e7          	jalr	1002(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047f4:	40dc                	lw	a5,4(s1)
    800047f6:	06f05163          	blez	a5,80004858 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047fa:	37fd                	addiw	a5,a5,-1
    800047fc:	0007871b          	sext.w	a4,a5
    80004800:	c0dc                	sw	a5,4(s1)
    80004802:	06e04363          	bgtz	a4,80004868 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004806:	0004a903          	lw	s2,0(s1)
    8000480a:	0094ca83          	lbu	s5,9(s1)
    8000480e:	0104ba03          	ld	s4,16(s1)
    80004812:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004816:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000481a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000481e:	0001c517          	auipc	a0,0x1c
    80004822:	56a50513          	addi	a0,a0,1386 # 80020d88 <ftable>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	464080e7          	jalr	1124(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000482e:	4785                	li	a5,1
    80004830:	04f90d63          	beq	s2,a5,8000488a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004834:	3979                	addiw	s2,s2,-2
    80004836:	4785                	li	a5,1
    80004838:	0527e063          	bltu	a5,s2,80004878 <fileclose+0xa8>
    begin_op();
    8000483c:	00000097          	auipc	ra,0x0
    80004840:	acc080e7          	jalr	-1332(ra) # 80004308 <begin_op>
    iput(ff.ip);
    80004844:	854e                	mv	a0,s3
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	2b0080e7          	jalr	688(ra) # 80003af6 <iput>
    end_op();
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	b38080e7          	jalr	-1224(ra) # 80004386 <end_op>
    80004856:	a00d                	j	80004878 <fileclose+0xa8>
    panic("fileclose");
    80004858:	00004517          	auipc	a0,0x4
    8000485c:	f2850513          	addi	a0,a0,-216 # 80008780 <syscalls+0x260>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	ce0080e7          	jalr	-800(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004868:	0001c517          	auipc	a0,0x1c
    8000486c:	52050513          	addi	a0,a0,1312 # 80020d88 <ftable>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	41a080e7          	jalr	1050(ra) # 80000c8a <release>
  }
}
    80004878:	70e2                	ld	ra,56(sp)
    8000487a:	7442                	ld	s0,48(sp)
    8000487c:	74a2                	ld	s1,40(sp)
    8000487e:	7902                	ld	s2,32(sp)
    80004880:	69e2                	ld	s3,24(sp)
    80004882:	6a42                	ld	s4,16(sp)
    80004884:	6aa2                	ld	s5,8(sp)
    80004886:	6121                	addi	sp,sp,64
    80004888:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000488a:	85d6                	mv	a1,s5
    8000488c:	8552                	mv	a0,s4
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	34c080e7          	jalr	844(ra) # 80004bda <pipeclose>
    80004896:	b7cd                	j	80004878 <fileclose+0xa8>

0000000080004898 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004898:	715d                	addi	sp,sp,-80
    8000489a:	e486                	sd	ra,72(sp)
    8000489c:	e0a2                	sd	s0,64(sp)
    8000489e:	fc26                	sd	s1,56(sp)
    800048a0:	f84a                	sd	s2,48(sp)
    800048a2:	f44e                	sd	s3,40(sp)
    800048a4:	0880                	addi	s0,sp,80
    800048a6:	84aa                	mv	s1,a0
    800048a8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048aa:	ffffd097          	auipc	ra,0xffffd
    800048ae:	1e0080e7          	jalr	480(ra) # 80001a8a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048b2:	409c                	lw	a5,0(s1)
    800048b4:	37f9                	addiw	a5,a5,-2
    800048b6:	4705                	li	a4,1
    800048b8:	04f76763          	bltu	a4,a5,80004906 <filestat+0x6e>
    800048bc:	892a                	mv	s2,a0
    ilock(f->ip);
    800048be:	6c88                	ld	a0,24(s1)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	07c080e7          	jalr	124(ra) # 8000393c <ilock>
    stati(f->ip, &st);
    800048c8:	fb840593          	addi	a1,s0,-72
    800048cc:	6c88                	ld	a0,24(s1)
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	2f8080e7          	jalr	760(ra) # 80003bc6 <stati>
    iunlock(f->ip);
    800048d6:	6c88                	ld	a0,24(s1)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	126080e7          	jalr	294(ra) # 800039fe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048e0:	46e1                	li	a3,24
    800048e2:	fb840613          	addi	a2,s0,-72
    800048e6:	85ce                	mv	a1,s3
    800048e8:	05093503          	ld	a0,80(s2)
    800048ec:	ffffd097          	auipc	ra,0xffffd
    800048f0:	d80080e7          	jalr	-640(ra) # 8000166c <copyout>
    800048f4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048f8:	60a6                	ld	ra,72(sp)
    800048fa:	6406                	ld	s0,64(sp)
    800048fc:	74e2                	ld	s1,56(sp)
    800048fe:	7942                	ld	s2,48(sp)
    80004900:	79a2                	ld	s3,40(sp)
    80004902:	6161                	addi	sp,sp,80
    80004904:	8082                	ret
  return -1;
    80004906:	557d                	li	a0,-1
    80004908:	bfc5                	j	800048f8 <filestat+0x60>

000000008000490a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000490a:	7179                	addi	sp,sp,-48
    8000490c:	f406                	sd	ra,40(sp)
    8000490e:	f022                	sd	s0,32(sp)
    80004910:	ec26                	sd	s1,24(sp)
    80004912:	e84a                	sd	s2,16(sp)
    80004914:	e44e                	sd	s3,8(sp)
    80004916:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004918:	00854783          	lbu	a5,8(a0)
    8000491c:	c3d5                	beqz	a5,800049c0 <fileread+0xb6>
    8000491e:	84aa                	mv	s1,a0
    80004920:	89ae                	mv	s3,a1
    80004922:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004924:	411c                	lw	a5,0(a0)
    80004926:	4705                	li	a4,1
    80004928:	04e78963          	beq	a5,a4,8000497a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000492c:	470d                	li	a4,3
    8000492e:	04e78d63          	beq	a5,a4,80004988 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004932:	4709                	li	a4,2
    80004934:	06e79e63          	bne	a5,a4,800049b0 <fileread+0xa6>
    ilock(f->ip);
    80004938:	6d08                	ld	a0,24(a0)
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	002080e7          	jalr	2(ra) # 8000393c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004942:	874a                	mv	a4,s2
    80004944:	5094                	lw	a3,32(s1)
    80004946:	864e                	mv	a2,s3
    80004948:	4585                	li	a1,1
    8000494a:	6c88                	ld	a0,24(s1)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	2a4080e7          	jalr	676(ra) # 80003bf0 <readi>
    80004954:	892a                	mv	s2,a0
    80004956:	00a05563          	blez	a0,80004960 <fileread+0x56>
      f->off += r;
    8000495a:	509c                	lw	a5,32(s1)
    8000495c:	9fa9                	addw	a5,a5,a0
    8000495e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004960:	6c88                	ld	a0,24(s1)
    80004962:	fffff097          	auipc	ra,0xfffff
    80004966:	09c080e7          	jalr	156(ra) # 800039fe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000496a:	854a                	mv	a0,s2
    8000496c:	70a2                	ld	ra,40(sp)
    8000496e:	7402                	ld	s0,32(sp)
    80004970:	64e2                	ld	s1,24(sp)
    80004972:	6942                	ld	s2,16(sp)
    80004974:	69a2                	ld	s3,8(sp)
    80004976:	6145                	addi	sp,sp,48
    80004978:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000497a:	6908                	ld	a0,16(a0)
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	3c6080e7          	jalr	966(ra) # 80004d42 <piperead>
    80004984:	892a                	mv	s2,a0
    80004986:	b7d5                	j	8000496a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004988:	02451783          	lh	a5,36(a0)
    8000498c:	03079693          	slli	a3,a5,0x30
    80004990:	92c1                	srli	a3,a3,0x30
    80004992:	4725                	li	a4,9
    80004994:	02d76863          	bltu	a4,a3,800049c4 <fileread+0xba>
    80004998:	0792                	slli	a5,a5,0x4
    8000499a:	0001c717          	auipc	a4,0x1c
    8000499e:	34e70713          	addi	a4,a4,846 # 80020ce8 <devsw>
    800049a2:	97ba                	add	a5,a5,a4
    800049a4:	639c                	ld	a5,0(a5)
    800049a6:	c38d                	beqz	a5,800049c8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049a8:	4505                	li	a0,1
    800049aa:	9782                	jalr	a5
    800049ac:	892a                	mv	s2,a0
    800049ae:	bf75                	j	8000496a <fileread+0x60>
    panic("fileread");
    800049b0:	00004517          	auipc	a0,0x4
    800049b4:	de050513          	addi	a0,a0,-544 # 80008790 <syscalls+0x270>
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	b88080e7          	jalr	-1144(ra) # 80000540 <panic>
    return -1;
    800049c0:	597d                	li	s2,-1
    800049c2:	b765                	j	8000496a <fileread+0x60>
      return -1;
    800049c4:	597d                	li	s2,-1
    800049c6:	b755                	j	8000496a <fileread+0x60>
    800049c8:	597d                	li	s2,-1
    800049ca:	b745                	j	8000496a <fileread+0x60>

00000000800049cc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049cc:	715d                	addi	sp,sp,-80
    800049ce:	e486                	sd	ra,72(sp)
    800049d0:	e0a2                	sd	s0,64(sp)
    800049d2:	fc26                	sd	s1,56(sp)
    800049d4:	f84a                	sd	s2,48(sp)
    800049d6:	f44e                	sd	s3,40(sp)
    800049d8:	f052                	sd	s4,32(sp)
    800049da:	ec56                	sd	s5,24(sp)
    800049dc:	e85a                	sd	s6,16(sp)
    800049de:	e45e                	sd	s7,8(sp)
    800049e0:	e062                	sd	s8,0(sp)
    800049e2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049e4:	00954783          	lbu	a5,9(a0)
    800049e8:	10078663          	beqz	a5,80004af4 <filewrite+0x128>
    800049ec:	892a                	mv	s2,a0
    800049ee:	8b2e                	mv	s6,a1
    800049f0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f2:	411c                	lw	a5,0(a0)
    800049f4:	4705                	li	a4,1
    800049f6:	02e78263          	beq	a5,a4,80004a1a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049fa:	470d                	li	a4,3
    800049fc:	02e78663          	beq	a5,a4,80004a28 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a00:	4709                	li	a4,2
    80004a02:	0ee79163          	bne	a5,a4,80004ae4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a06:	0ac05d63          	blez	a2,80004ac0 <filewrite+0xf4>
    int i = 0;
    80004a0a:	4981                	li	s3,0
    80004a0c:	6b85                	lui	s7,0x1
    80004a0e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a12:	6c05                	lui	s8,0x1
    80004a14:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a18:	a861                	j	80004ab0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a1a:	6908                	ld	a0,16(a0)
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	22e080e7          	jalr	558(ra) # 80004c4a <pipewrite>
    80004a24:	8a2a                	mv	s4,a0
    80004a26:	a045                	j	80004ac6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a28:	02451783          	lh	a5,36(a0)
    80004a2c:	03079693          	slli	a3,a5,0x30
    80004a30:	92c1                	srli	a3,a3,0x30
    80004a32:	4725                	li	a4,9
    80004a34:	0cd76263          	bltu	a4,a3,80004af8 <filewrite+0x12c>
    80004a38:	0792                	slli	a5,a5,0x4
    80004a3a:	0001c717          	auipc	a4,0x1c
    80004a3e:	2ae70713          	addi	a4,a4,686 # 80020ce8 <devsw>
    80004a42:	97ba                	add	a5,a5,a4
    80004a44:	679c                	ld	a5,8(a5)
    80004a46:	cbdd                	beqz	a5,80004afc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a48:	4505                	li	a0,1
    80004a4a:	9782                	jalr	a5
    80004a4c:	8a2a                	mv	s4,a0
    80004a4e:	a8a5                	j	80004ac6 <filewrite+0xfa>
    80004a50:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	8b4080e7          	jalr	-1868(ra) # 80004308 <begin_op>
      ilock(f->ip);
    80004a5c:	01893503          	ld	a0,24(s2)
    80004a60:	fffff097          	auipc	ra,0xfffff
    80004a64:	edc080e7          	jalr	-292(ra) # 8000393c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a68:	8756                	mv	a4,s5
    80004a6a:	02092683          	lw	a3,32(s2)
    80004a6e:	01698633          	add	a2,s3,s6
    80004a72:	4585                	li	a1,1
    80004a74:	01893503          	ld	a0,24(s2)
    80004a78:	fffff097          	auipc	ra,0xfffff
    80004a7c:	270080e7          	jalr	624(ra) # 80003ce8 <writei>
    80004a80:	84aa                	mv	s1,a0
    80004a82:	00a05763          	blez	a0,80004a90 <filewrite+0xc4>
        f->off += r;
    80004a86:	02092783          	lw	a5,32(s2)
    80004a8a:	9fa9                	addw	a5,a5,a0
    80004a8c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a90:	01893503          	ld	a0,24(s2)
    80004a94:	fffff097          	auipc	ra,0xfffff
    80004a98:	f6a080e7          	jalr	-150(ra) # 800039fe <iunlock>
      end_op();
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	8ea080e7          	jalr	-1814(ra) # 80004386 <end_op>

      if(r != n1){
    80004aa4:	009a9f63          	bne	s5,s1,80004ac2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aa8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aac:	0149db63          	bge	s3,s4,80004ac2 <filewrite+0xf6>
      int n1 = n - i;
    80004ab0:	413a04bb          	subw	s1,s4,s3
    80004ab4:	0004879b          	sext.w	a5,s1
    80004ab8:	f8fbdce3          	bge	s7,a5,80004a50 <filewrite+0x84>
    80004abc:	84e2                	mv	s1,s8
    80004abe:	bf49                	j	80004a50 <filewrite+0x84>
    int i = 0;
    80004ac0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ac2:	013a1f63          	bne	s4,s3,80004ae0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ac6:	8552                	mv	a0,s4
    80004ac8:	60a6                	ld	ra,72(sp)
    80004aca:	6406                	ld	s0,64(sp)
    80004acc:	74e2                	ld	s1,56(sp)
    80004ace:	7942                	ld	s2,48(sp)
    80004ad0:	79a2                	ld	s3,40(sp)
    80004ad2:	7a02                	ld	s4,32(sp)
    80004ad4:	6ae2                	ld	s5,24(sp)
    80004ad6:	6b42                	ld	s6,16(sp)
    80004ad8:	6ba2                	ld	s7,8(sp)
    80004ada:	6c02                	ld	s8,0(sp)
    80004adc:	6161                	addi	sp,sp,80
    80004ade:	8082                	ret
    ret = (i == n ? n : -1);
    80004ae0:	5a7d                	li	s4,-1
    80004ae2:	b7d5                	j	80004ac6 <filewrite+0xfa>
    panic("filewrite");
    80004ae4:	00004517          	auipc	a0,0x4
    80004ae8:	cbc50513          	addi	a0,a0,-836 # 800087a0 <syscalls+0x280>
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	a54080e7          	jalr	-1452(ra) # 80000540 <panic>
    return -1;
    80004af4:	5a7d                	li	s4,-1
    80004af6:	bfc1                	j	80004ac6 <filewrite+0xfa>
      return -1;
    80004af8:	5a7d                	li	s4,-1
    80004afa:	b7f1                	j	80004ac6 <filewrite+0xfa>
    80004afc:	5a7d                	li	s4,-1
    80004afe:	b7e1                	j	80004ac6 <filewrite+0xfa>

0000000080004b00 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b00:	7179                	addi	sp,sp,-48
    80004b02:	f406                	sd	ra,40(sp)
    80004b04:	f022                	sd	s0,32(sp)
    80004b06:	ec26                	sd	s1,24(sp)
    80004b08:	e84a                	sd	s2,16(sp)
    80004b0a:	e44e                	sd	s3,8(sp)
    80004b0c:	e052                	sd	s4,0(sp)
    80004b0e:	1800                	addi	s0,sp,48
    80004b10:	84aa                	mv	s1,a0
    80004b12:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b14:	0005b023          	sd	zero,0(a1)
    80004b18:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	bf8080e7          	jalr	-1032(ra) # 80004714 <filealloc>
    80004b24:	e088                	sd	a0,0(s1)
    80004b26:	c551                	beqz	a0,80004bb2 <pipealloc+0xb2>
    80004b28:	00000097          	auipc	ra,0x0
    80004b2c:	bec080e7          	jalr	-1044(ra) # 80004714 <filealloc>
    80004b30:	00aa3023          	sd	a0,0(s4)
    80004b34:	c92d                	beqz	a0,80004ba6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	fb0080e7          	jalr	-80(ra) # 80000ae6 <kalloc>
    80004b3e:	892a                	mv	s2,a0
    80004b40:	c125                	beqz	a0,80004ba0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b42:	4985                	li	s3,1
    80004b44:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b48:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b4c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b50:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b54:	00004597          	auipc	a1,0x4
    80004b58:	c5c58593          	addi	a1,a1,-932 # 800087b0 <syscalls+0x290>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	fea080e7          	jalr	-22(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004b64:	609c                	ld	a5,0(s1)
    80004b66:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b6a:	609c                	ld	a5,0(s1)
    80004b6c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b70:	609c                	ld	a5,0(s1)
    80004b72:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b76:	609c                	ld	a5,0(s1)
    80004b78:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b7c:	000a3783          	ld	a5,0(s4)
    80004b80:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b84:	000a3783          	ld	a5,0(s4)
    80004b88:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b8c:	000a3783          	ld	a5,0(s4)
    80004b90:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b94:	000a3783          	ld	a5,0(s4)
    80004b98:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b9c:	4501                	li	a0,0
    80004b9e:	a025                	j	80004bc6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ba0:	6088                	ld	a0,0(s1)
    80004ba2:	e501                	bnez	a0,80004baa <pipealloc+0xaa>
    80004ba4:	a039                	j	80004bb2 <pipealloc+0xb2>
    80004ba6:	6088                	ld	a0,0(s1)
    80004ba8:	c51d                	beqz	a0,80004bd6 <pipealloc+0xd6>
    fileclose(*f0);
    80004baa:	00000097          	auipc	ra,0x0
    80004bae:	c26080e7          	jalr	-986(ra) # 800047d0 <fileclose>
  if(*f1)
    80004bb2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bb6:	557d                	li	a0,-1
  if(*f1)
    80004bb8:	c799                	beqz	a5,80004bc6 <pipealloc+0xc6>
    fileclose(*f1);
    80004bba:	853e                	mv	a0,a5
    80004bbc:	00000097          	auipc	ra,0x0
    80004bc0:	c14080e7          	jalr	-1004(ra) # 800047d0 <fileclose>
  return -1;
    80004bc4:	557d                	li	a0,-1
}
    80004bc6:	70a2                	ld	ra,40(sp)
    80004bc8:	7402                	ld	s0,32(sp)
    80004bca:	64e2                	ld	s1,24(sp)
    80004bcc:	6942                	ld	s2,16(sp)
    80004bce:	69a2                	ld	s3,8(sp)
    80004bd0:	6a02                	ld	s4,0(sp)
    80004bd2:	6145                	addi	sp,sp,48
    80004bd4:	8082                	ret
  return -1;
    80004bd6:	557d                	li	a0,-1
    80004bd8:	b7fd                	j	80004bc6 <pipealloc+0xc6>

0000000080004bda <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bda:	1101                	addi	sp,sp,-32
    80004bdc:	ec06                	sd	ra,24(sp)
    80004bde:	e822                	sd	s0,16(sp)
    80004be0:	e426                	sd	s1,8(sp)
    80004be2:	e04a                	sd	s2,0(sp)
    80004be4:	1000                	addi	s0,sp,32
    80004be6:	84aa                	mv	s1,a0
    80004be8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	fec080e7          	jalr	-20(ra) # 80000bd6 <acquire>
  if(writable){
    80004bf2:	02090d63          	beqz	s2,80004c2c <pipeclose+0x52>
    pi->writeopen = 0;
    80004bf6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bfa:	21848513          	addi	a0,s1,536
    80004bfe:	ffffd097          	auipc	ra,0xffffd
    80004c02:	658080e7          	jalr	1624(ra) # 80002256 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c06:	2204b783          	ld	a5,544(s1)
    80004c0a:	eb95                	bnez	a5,80004c3e <pipeclose+0x64>
    release(&pi->lock);
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	07c080e7          	jalr	124(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	dd0080e7          	jalr	-560(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004c20:	60e2                	ld	ra,24(sp)
    80004c22:	6442                	ld	s0,16(sp)
    80004c24:	64a2                	ld	s1,8(sp)
    80004c26:	6902                	ld	s2,0(sp)
    80004c28:	6105                	addi	sp,sp,32
    80004c2a:	8082                	ret
    pi->readopen = 0;
    80004c2c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c30:	21c48513          	addi	a0,s1,540
    80004c34:	ffffd097          	auipc	ra,0xffffd
    80004c38:	622080e7          	jalr	1570(ra) # 80002256 <wakeup>
    80004c3c:	b7e9                	j	80004c06 <pipeclose+0x2c>
    release(&pi->lock);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	04a080e7          	jalr	74(ra) # 80000c8a <release>
}
    80004c48:	bfe1                	j	80004c20 <pipeclose+0x46>

0000000080004c4a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c4a:	711d                	addi	sp,sp,-96
    80004c4c:	ec86                	sd	ra,88(sp)
    80004c4e:	e8a2                	sd	s0,80(sp)
    80004c50:	e4a6                	sd	s1,72(sp)
    80004c52:	e0ca                	sd	s2,64(sp)
    80004c54:	fc4e                	sd	s3,56(sp)
    80004c56:	f852                	sd	s4,48(sp)
    80004c58:	f456                	sd	s5,40(sp)
    80004c5a:	f05a                	sd	s6,32(sp)
    80004c5c:	ec5e                	sd	s7,24(sp)
    80004c5e:	e862                	sd	s8,16(sp)
    80004c60:	1080                	addi	s0,sp,96
    80004c62:	84aa                	mv	s1,a0
    80004c64:	8aae                	mv	s5,a1
    80004c66:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	e22080e7          	jalr	-478(ra) # 80001a8a <myproc>
    80004c70:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c72:	8526                	mv	a0,s1
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	f62080e7          	jalr	-158(ra) # 80000bd6 <acquire>
  while(i < n){
    80004c7c:	0b405663          	blez	s4,80004d28 <pipewrite+0xde>
  int i = 0;
    80004c80:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c82:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c84:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c88:	21c48b93          	addi	s7,s1,540
    80004c8c:	a089                	j	80004cce <pipewrite+0x84>
      release(&pi->lock);
    80004c8e:	8526                	mv	a0,s1
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	ffa080e7          	jalr	-6(ra) # 80000c8a <release>
      return -1;
    80004c98:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c9a:	854a                	mv	a0,s2
    80004c9c:	60e6                	ld	ra,88(sp)
    80004c9e:	6446                	ld	s0,80(sp)
    80004ca0:	64a6                	ld	s1,72(sp)
    80004ca2:	6906                	ld	s2,64(sp)
    80004ca4:	79e2                	ld	s3,56(sp)
    80004ca6:	7a42                	ld	s4,48(sp)
    80004ca8:	7aa2                	ld	s5,40(sp)
    80004caa:	7b02                	ld	s6,32(sp)
    80004cac:	6be2                	ld	s7,24(sp)
    80004cae:	6c42                	ld	s8,16(sp)
    80004cb0:	6125                	addi	sp,sp,96
    80004cb2:	8082                	ret
      wakeup(&pi->nread);
    80004cb4:	8562                	mv	a0,s8
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	5a0080e7          	jalr	1440(ra) # 80002256 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cbe:	85a6                	mv	a1,s1
    80004cc0:	855e                	mv	a0,s7
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	530080e7          	jalr	1328(ra) # 800021f2 <sleep>
  while(i < n){
    80004cca:	07495063          	bge	s2,s4,80004d2a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004cce:	2204a783          	lw	a5,544(s1)
    80004cd2:	dfd5                	beqz	a5,80004c8e <pipewrite+0x44>
    80004cd4:	854e                	mv	a0,s3
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	7c4080e7          	jalr	1988(ra) # 8000249a <killed>
    80004cde:	f945                	bnez	a0,80004c8e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ce0:	2184a783          	lw	a5,536(s1)
    80004ce4:	21c4a703          	lw	a4,540(s1)
    80004ce8:	2007879b          	addiw	a5,a5,512
    80004cec:	fcf704e3          	beq	a4,a5,80004cb4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cf0:	4685                	li	a3,1
    80004cf2:	01590633          	add	a2,s2,s5
    80004cf6:	faf40593          	addi	a1,s0,-81
    80004cfa:	0509b503          	ld	a0,80(s3)
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	9fa080e7          	jalr	-1542(ra) # 800016f8 <copyin>
    80004d06:	03650263          	beq	a0,s6,80004d2a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d0a:	21c4a783          	lw	a5,540(s1)
    80004d0e:	0017871b          	addiw	a4,a5,1
    80004d12:	20e4ae23          	sw	a4,540(s1)
    80004d16:	1ff7f793          	andi	a5,a5,511
    80004d1a:	97a6                	add	a5,a5,s1
    80004d1c:	faf44703          	lbu	a4,-81(s0)
    80004d20:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d24:	2905                	addiw	s2,s2,1
    80004d26:	b755                	j	80004cca <pipewrite+0x80>
  int i = 0;
    80004d28:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d2a:	21848513          	addi	a0,s1,536
    80004d2e:	ffffd097          	auipc	ra,0xffffd
    80004d32:	528080e7          	jalr	1320(ra) # 80002256 <wakeup>
  release(&pi->lock);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	f52080e7          	jalr	-174(ra) # 80000c8a <release>
  return i;
    80004d40:	bfa9                	j	80004c9a <pipewrite+0x50>

0000000080004d42 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d42:	715d                	addi	sp,sp,-80
    80004d44:	e486                	sd	ra,72(sp)
    80004d46:	e0a2                	sd	s0,64(sp)
    80004d48:	fc26                	sd	s1,56(sp)
    80004d4a:	f84a                	sd	s2,48(sp)
    80004d4c:	f44e                	sd	s3,40(sp)
    80004d4e:	f052                	sd	s4,32(sp)
    80004d50:	ec56                	sd	s5,24(sp)
    80004d52:	e85a                	sd	s6,16(sp)
    80004d54:	0880                	addi	s0,sp,80
    80004d56:	84aa                	mv	s1,a0
    80004d58:	892e                	mv	s2,a1
    80004d5a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	d2e080e7          	jalr	-722(ra) # 80001a8a <myproc>
    80004d64:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d66:	8526                	mv	a0,s1
    80004d68:	ffffc097          	auipc	ra,0xffffc
    80004d6c:	e6e080e7          	jalr	-402(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d70:	2184a703          	lw	a4,536(s1)
    80004d74:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d78:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d7c:	02f71763          	bne	a4,a5,80004daa <piperead+0x68>
    80004d80:	2244a783          	lw	a5,548(s1)
    80004d84:	c39d                	beqz	a5,80004daa <piperead+0x68>
    if(killed(pr)){
    80004d86:	8552                	mv	a0,s4
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	712080e7          	jalr	1810(ra) # 8000249a <killed>
    80004d90:	e949                	bnez	a0,80004e22 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d92:	85a6                	mv	a1,s1
    80004d94:	854e                	mv	a0,s3
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	45c080e7          	jalr	1116(ra) # 800021f2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d9e:	2184a703          	lw	a4,536(s1)
    80004da2:	21c4a783          	lw	a5,540(s1)
    80004da6:	fcf70de3          	beq	a4,a5,80004d80 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004daa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dac:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dae:	05505463          	blez	s5,80004df6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004db2:	2184a783          	lw	a5,536(s1)
    80004db6:	21c4a703          	lw	a4,540(s1)
    80004dba:	02f70e63          	beq	a4,a5,80004df6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dbe:	0017871b          	addiw	a4,a5,1
    80004dc2:	20e4ac23          	sw	a4,536(s1)
    80004dc6:	1ff7f793          	andi	a5,a5,511
    80004dca:	97a6                	add	a5,a5,s1
    80004dcc:	0187c783          	lbu	a5,24(a5)
    80004dd0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd4:	4685                	li	a3,1
    80004dd6:	fbf40613          	addi	a2,s0,-65
    80004dda:	85ca                	mv	a1,s2
    80004ddc:	050a3503          	ld	a0,80(s4)
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	88c080e7          	jalr	-1908(ra) # 8000166c <copyout>
    80004de8:	01650763          	beq	a0,s6,80004df6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dec:	2985                	addiw	s3,s3,1
    80004dee:	0905                	addi	s2,s2,1
    80004df0:	fd3a91e3          	bne	s5,s3,80004db2 <piperead+0x70>
    80004df4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004df6:	21c48513          	addi	a0,s1,540
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	45c080e7          	jalr	1116(ra) # 80002256 <wakeup>
  release(&pi->lock);
    80004e02:	8526                	mv	a0,s1
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	e86080e7          	jalr	-378(ra) # 80000c8a <release>
  return i;
}
    80004e0c:	854e                	mv	a0,s3
    80004e0e:	60a6                	ld	ra,72(sp)
    80004e10:	6406                	ld	s0,64(sp)
    80004e12:	74e2                	ld	s1,56(sp)
    80004e14:	7942                	ld	s2,48(sp)
    80004e16:	79a2                	ld	s3,40(sp)
    80004e18:	7a02                	ld	s4,32(sp)
    80004e1a:	6ae2                	ld	s5,24(sp)
    80004e1c:	6b42                	ld	s6,16(sp)
    80004e1e:	6161                	addi	sp,sp,80
    80004e20:	8082                	ret
      release(&pi->lock);
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	e66080e7          	jalr	-410(ra) # 80000c8a <release>
      return -1;
    80004e2c:	59fd                	li	s3,-1
    80004e2e:	bff9                	j	80004e0c <piperead+0xca>

0000000080004e30 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e30:	1141                	addi	sp,sp,-16
    80004e32:	e422                	sd	s0,8(sp)
    80004e34:	0800                	addi	s0,sp,16
    80004e36:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e38:	8905                	andi	a0,a0,1
    80004e3a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004e3c:	8b89                	andi	a5,a5,2
    80004e3e:	c399                	beqz	a5,80004e44 <flags2perm+0x14>
      perm |= PTE_W;
    80004e40:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e44:	6422                	ld	s0,8(sp)
    80004e46:	0141                	addi	sp,sp,16
    80004e48:	8082                	ret

0000000080004e4a <exec>:

int
exec(char *path, char **argv)
{
    80004e4a:	de010113          	addi	sp,sp,-544
    80004e4e:	20113c23          	sd	ra,536(sp)
    80004e52:	20813823          	sd	s0,528(sp)
    80004e56:	20913423          	sd	s1,520(sp)
    80004e5a:	21213023          	sd	s2,512(sp)
    80004e5e:	ffce                	sd	s3,504(sp)
    80004e60:	fbd2                	sd	s4,496(sp)
    80004e62:	f7d6                	sd	s5,488(sp)
    80004e64:	f3da                	sd	s6,480(sp)
    80004e66:	efde                	sd	s7,472(sp)
    80004e68:	ebe2                	sd	s8,464(sp)
    80004e6a:	e7e6                	sd	s9,456(sp)
    80004e6c:	e3ea                	sd	s10,448(sp)
    80004e6e:	ff6e                	sd	s11,440(sp)
    80004e70:	1400                	addi	s0,sp,544
    80004e72:	892a                	mv	s2,a0
    80004e74:	dea43423          	sd	a0,-536(s0)
    80004e78:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	c0e080e7          	jalr	-1010(ra) # 80001a8a <myproc>
    80004e84:	84aa                	mv	s1,a0

  begin_op();
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	482080e7          	jalr	1154(ra) # 80004308 <begin_op>

  if((ip = namei(path)) == 0){
    80004e8e:	854a                	mv	a0,s2
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	258080e7          	jalr	600(ra) # 800040e8 <namei>
    80004e98:	c93d                	beqz	a0,80004f0e <exec+0xc4>
    80004e9a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	aa0080e7          	jalr	-1376(ra) # 8000393c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ea4:	04000713          	li	a4,64
    80004ea8:	4681                	li	a3,0
    80004eaa:	e5040613          	addi	a2,s0,-432
    80004eae:	4581                	li	a1,0
    80004eb0:	8556                	mv	a0,s5
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	d3e080e7          	jalr	-706(ra) # 80003bf0 <readi>
    80004eba:	04000793          	li	a5,64
    80004ebe:	00f51a63          	bne	a0,a5,80004ed2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ec2:	e5042703          	lw	a4,-432(s0)
    80004ec6:	464c47b7          	lui	a5,0x464c4
    80004eca:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ece:	04f70663          	beq	a4,a5,80004f1a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ed2:	8556                	mv	a0,s5
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	cca080e7          	jalr	-822(ra) # 80003b9e <iunlockput>
    end_op();
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	4aa080e7          	jalr	1194(ra) # 80004386 <end_op>
  }
  return -1;
    80004ee4:	557d                	li	a0,-1
}
    80004ee6:	21813083          	ld	ra,536(sp)
    80004eea:	21013403          	ld	s0,528(sp)
    80004eee:	20813483          	ld	s1,520(sp)
    80004ef2:	20013903          	ld	s2,512(sp)
    80004ef6:	79fe                	ld	s3,504(sp)
    80004ef8:	7a5e                	ld	s4,496(sp)
    80004efa:	7abe                	ld	s5,488(sp)
    80004efc:	7b1e                	ld	s6,480(sp)
    80004efe:	6bfe                	ld	s7,472(sp)
    80004f00:	6c5e                	ld	s8,464(sp)
    80004f02:	6cbe                	ld	s9,456(sp)
    80004f04:	6d1e                	ld	s10,448(sp)
    80004f06:	7dfa                	ld	s11,440(sp)
    80004f08:	22010113          	addi	sp,sp,544
    80004f0c:	8082                	ret
    end_op();
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	478080e7          	jalr	1144(ra) # 80004386 <end_op>
    return -1;
    80004f16:	557d                	li	a0,-1
    80004f18:	b7f9                	j	80004ee6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f1a:	8526                	mv	a0,s1
    80004f1c:	ffffd097          	auipc	ra,0xffffd
    80004f20:	c32080e7          	jalr	-974(ra) # 80001b4e <proc_pagetable>
    80004f24:	8b2a                	mv	s6,a0
    80004f26:	d555                	beqz	a0,80004ed2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f28:	e7042783          	lw	a5,-400(s0)
    80004f2c:	e8845703          	lhu	a4,-376(s0)
    80004f30:	c735                	beqz	a4,80004f9c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f32:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f34:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f38:	6a05                	lui	s4,0x1
    80004f3a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f3e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f42:	6d85                	lui	s11,0x1
    80004f44:	7d7d                	lui	s10,0xfffff
    80004f46:	ac3d                	j	80005184 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f48:	00004517          	auipc	a0,0x4
    80004f4c:	87050513          	addi	a0,a0,-1936 # 800087b8 <syscalls+0x298>
    80004f50:	ffffb097          	auipc	ra,0xffffb
    80004f54:	5f0080e7          	jalr	1520(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f58:	874a                	mv	a4,s2
    80004f5a:	009c86bb          	addw	a3,s9,s1
    80004f5e:	4581                	li	a1,0
    80004f60:	8556                	mv	a0,s5
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	c8e080e7          	jalr	-882(ra) # 80003bf0 <readi>
    80004f6a:	2501                	sext.w	a0,a0
    80004f6c:	1aa91963          	bne	s2,a0,8000511e <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004f70:	009d84bb          	addw	s1,s11,s1
    80004f74:	013d09bb          	addw	s3,s10,s3
    80004f78:	1f74f663          	bgeu	s1,s7,80005164 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004f7c:	02049593          	slli	a1,s1,0x20
    80004f80:	9181                	srli	a1,a1,0x20
    80004f82:	95e2                	add	a1,a1,s8
    80004f84:	855a                	mv	a0,s6
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	0d6080e7          	jalr	214(ra) # 8000105c <walkaddr>
    80004f8e:	862a                	mv	a2,a0
    if(pa == 0)
    80004f90:	dd45                	beqz	a0,80004f48 <exec+0xfe>
      n = PGSIZE;
    80004f92:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f94:	fd49f2e3          	bgeu	s3,s4,80004f58 <exec+0x10e>
      n = sz - i;
    80004f98:	894e                	mv	s2,s3
    80004f9a:	bf7d                	j	80004f58 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f9c:	4901                	li	s2,0
  iunlockput(ip);
    80004f9e:	8556                	mv	a0,s5
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	bfe080e7          	jalr	-1026(ra) # 80003b9e <iunlockput>
  end_op();
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	3de080e7          	jalr	990(ra) # 80004386 <end_op>
  p = myproc();
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	ada080e7          	jalr	-1318(ra) # 80001a8a <myproc>
    80004fb8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fba:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fbe:	6785                	lui	a5,0x1
    80004fc0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004fc2:	97ca                	add	a5,a5,s2
    80004fc4:	777d                	lui	a4,0xfffff
    80004fc6:	8ff9                	and	a5,a5,a4
    80004fc8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fcc:	4691                	li	a3,4
    80004fce:	6609                	lui	a2,0x2
    80004fd0:	963e                	add	a2,a2,a5
    80004fd2:	85be                	mv	a1,a5
    80004fd4:	855a                	mv	a0,s6
    80004fd6:	ffffc097          	auipc	ra,0xffffc
    80004fda:	43a080e7          	jalr	1082(ra) # 80001410 <uvmalloc>
    80004fde:	8c2a                	mv	s8,a0
  ip = 0;
    80004fe0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fe2:	12050e63          	beqz	a0,8000511e <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fe6:	75f9                	lui	a1,0xffffe
    80004fe8:	95aa                	add	a1,a1,a0
    80004fea:	855a                	mv	a0,s6
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	64e080e7          	jalr	1614(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004ff4:	7afd                	lui	s5,0xfffff
    80004ff6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ff8:	df043783          	ld	a5,-528(s0)
    80004ffc:	6388                	ld	a0,0(a5)
    80004ffe:	c925                	beqz	a0,8000506e <exec+0x224>
    80005000:	e9040993          	addi	s3,s0,-368
    80005004:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005008:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000500a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	e42080e7          	jalr	-446(ra) # 80000e4e <strlen>
    80005014:	0015079b          	addiw	a5,a0,1
    80005018:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000501c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005020:	13596663          	bltu	s2,s5,8000514c <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005024:	df043d83          	ld	s11,-528(s0)
    80005028:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000502c:	8552                	mv	a0,s4
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	e20080e7          	jalr	-480(ra) # 80000e4e <strlen>
    80005036:	0015069b          	addiw	a3,a0,1
    8000503a:	8652                	mv	a2,s4
    8000503c:	85ca                	mv	a1,s2
    8000503e:	855a                	mv	a0,s6
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	62c080e7          	jalr	1580(ra) # 8000166c <copyout>
    80005048:	10054663          	bltz	a0,80005154 <exec+0x30a>
    ustack[argc] = sp;
    8000504c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005050:	0485                	addi	s1,s1,1
    80005052:	008d8793          	addi	a5,s11,8
    80005056:	def43823          	sd	a5,-528(s0)
    8000505a:	008db503          	ld	a0,8(s11)
    8000505e:	c911                	beqz	a0,80005072 <exec+0x228>
    if(argc >= MAXARG)
    80005060:	09a1                	addi	s3,s3,8
    80005062:	fb3c95e3          	bne	s9,s3,8000500c <exec+0x1c2>
  sz = sz1;
    80005066:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000506a:	4a81                	li	s5,0
    8000506c:	a84d                	j	8000511e <exec+0x2d4>
  sp = sz;
    8000506e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005070:	4481                	li	s1,0
  ustack[argc] = 0;
    80005072:	00349793          	slli	a5,s1,0x3
    80005076:	f9078793          	addi	a5,a5,-112
    8000507a:	97a2                	add	a5,a5,s0
    8000507c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005080:	00148693          	addi	a3,s1,1
    80005084:	068e                	slli	a3,a3,0x3
    80005086:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000508a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000508e:	01597663          	bgeu	s2,s5,8000509a <exec+0x250>
  sz = sz1;
    80005092:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005096:	4a81                	li	s5,0
    80005098:	a059                	j	8000511e <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000509a:	e9040613          	addi	a2,s0,-368
    8000509e:	85ca                	mv	a1,s2
    800050a0:	855a                	mv	a0,s6
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	5ca080e7          	jalr	1482(ra) # 8000166c <copyout>
    800050aa:	0a054963          	bltz	a0,8000515c <exec+0x312>
  p->trapframe->a1 = sp;
    800050ae:	058bb783          	ld	a5,88(s7)
    800050b2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b6:	de843783          	ld	a5,-536(s0)
    800050ba:	0007c703          	lbu	a4,0(a5)
    800050be:	cf11                	beqz	a4,800050da <exec+0x290>
    800050c0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050c2:	02f00693          	li	a3,47
    800050c6:	a039                	j	800050d4 <exec+0x28a>
      last = s+1;
    800050c8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050cc:	0785                	addi	a5,a5,1
    800050ce:	fff7c703          	lbu	a4,-1(a5)
    800050d2:	c701                	beqz	a4,800050da <exec+0x290>
    if(*s == '/')
    800050d4:	fed71ce3          	bne	a4,a3,800050cc <exec+0x282>
    800050d8:	bfc5                	j	800050c8 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800050da:	4641                	li	a2,16
    800050dc:	de843583          	ld	a1,-536(s0)
    800050e0:	158b8513          	addi	a0,s7,344
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	d38080e7          	jalr	-712(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800050ec:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050f0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050f4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050f8:	058bb783          	ld	a5,88(s7)
    800050fc:	e6843703          	ld	a4,-408(s0)
    80005100:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005102:	058bb783          	ld	a5,88(s7)
    80005106:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000510a:	85ea                	mv	a1,s10
    8000510c:	ffffd097          	auipc	ra,0xffffd
    80005110:	ade080e7          	jalr	-1314(ra) # 80001bea <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005114:	0004851b          	sext.w	a0,s1
    80005118:	b3f9                	j	80004ee6 <exec+0x9c>
    8000511a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000511e:	df843583          	ld	a1,-520(s0)
    80005122:	855a                	mv	a0,s6
    80005124:	ffffd097          	auipc	ra,0xffffd
    80005128:	ac6080e7          	jalr	-1338(ra) # 80001bea <proc_freepagetable>
  if(ip){
    8000512c:	da0a93e3          	bnez	s5,80004ed2 <exec+0x88>
  return -1;
    80005130:	557d                	li	a0,-1
    80005132:	bb55                	j	80004ee6 <exec+0x9c>
    80005134:	df243c23          	sd	s2,-520(s0)
    80005138:	b7dd                	j	8000511e <exec+0x2d4>
    8000513a:	df243c23          	sd	s2,-520(s0)
    8000513e:	b7c5                	j	8000511e <exec+0x2d4>
    80005140:	df243c23          	sd	s2,-520(s0)
    80005144:	bfe9                	j	8000511e <exec+0x2d4>
    80005146:	df243c23          	sd	s2,-520(s0)
    8000514a:	bfd1                	j	8000511e <exec+0x2d4>
  sz = sz1;
    8000514c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005150:	4a81                	li	s5,0
    80005152:	b7f1                	j	8000511e <exec+0x2d4>
  sz = sz1;
    80005154:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005158:	4a81                	li	s5,0
    8000515a:	b7d1                	j	8000511e <exec+0x2d4>
  sz = sz1;
    8000515c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005160:	4a81                	li	s5,0
    80005162:	bf75                	j	8000511e <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005164:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005168:	e0843783          	ld	a5,-504(s0)
    8000516c:	0017869b          	addiw	a3,a5,1
    80005170:	e0d43423          	sd	a3,-504(s0)
    80005174:	e0043783          	ld	a5,-512(s0)
    80005178:	0387879b          	addiw	a5,a5,56
    8000517c:	e8845703          	lhu	a4,-376(s0)
    80005180:	e0e6dfe3          	bge	a3,a4,80004f9e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005184:	2781                	sext.w	a5,a5
    80005186:	e0f43023          	sd	a5,-512(s0)
    8000518a:	03800713          	li	a4,56
    8000518e:	86be                	mv	a3,a5
    80005190:	e1840613          	addi	a2,s0,-488
    80005194:	4581                	li	a1,0
    80005196:	8556                	mv	a0,s5
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	a58080e7          	jalr	-1448(ra) # 80003bf0 <readi>
    800051a0:	03800793          	li	a5,56
    800051a4:	f6f51be3          	bne	a0,a5,8000511a <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800051a8:	e1842783          	lw	a5,-488(s0)
    800051ac:	4705                	li	a4,1
    800051ae:	fae79de3          	bne	a5,a4,80005168 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800051b2:	e4043483          	ld	s1,-448(s0)
    800051b6:	e3843783          	ld	a5,-456(s0)
    800051ba:	f6f4ede3          	bltu	s1,a5,80005134 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051be:	e2843783          	ld	a5,-472(s0)
    800051c2:	94be                	add	s1,s1,a5
    800051c4:	f6f4ebe3          	bltu	s1,a5,8000513a <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800051c8:	de043703          	ld	a4,-544(s0)
    800051cc:	8ff9                	and	a5,a5,a4
    800051ce:	fbad                	bnez	a5,80005140 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051d0:	e1c42503          	lw	a0,-484(s0)
    800051d4:	00000097          	auipc	ra,0x0
    800051d8:	c5c080e7          	jalr	-932(ra) # 80004e30 <flags2perm>
    800051dc:	86aa                	mv	a3,a0
    800051de:	8626                	mv	a2,s1
    800051e0:	85ca                	mv	a1,s2
    800051e2:	855a                	mv	a0,s6
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	22c080e7          	jalr	556(ra) # 80001410 <uvmalloc>
    800051ec:	dea43c23          	sd	a0,-520(s0)
    800051f0:	d939                	beqz	a0,80005146 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051f2:	e2843c03          	ld	s8,-472(s0)
    800051f6:	e2042c83          	lw	s9,-480(s0)
    800051fa:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051fe:	f60b83e3          	beqz	s7,80005164 <exec+0x31a>
    80005202:	89de                	mv	s3,s7
    80005204:	4481                	li	s1,0
    80005206:	bb9d                	j	80004f7c <exec+0x132>

0000000080005208 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005208:	7179                	addi	sp,sp,-48
    8000520a:	f406                	sd	ra,40(sp)
    8000520c:	f022                	sd	s0,32(sp)
    8000520e:	ec26                	sd	s1,24(sp)
    80005210:	e84a                	sd	s2,16(sp)
    80005212:	1800                	addi	s0,sp,48
    80005214:	892e                	mv	s2,a1
    80005216:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005218:	fdc40593          	addi	a1,s0,-36
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	b26080e7          	jalr	-1242(ra) # 80002d42 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005224:	fdc42703          	lw	a4,-36(s0)
    80005228:	47bd                	li	a5,15
    8000522a:	02e7eb63          	bltu	a5,a4,80005260 <argfd+0x58>
    8000522e:	ffffd097          	auipc	ra,0xffffd
    80005232:	85c080e7          	jalr	-1956(ra) # 80001a8a <myproc>
    80005236:	fdc42703          	lw	a4,-36(s0)
    8000523a:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd19a>
    8000523e:	078e                	slli	a5,a5,0x3
    80005240:	953e                	add	a0,a0,a5
    80005242:	611c                	ld	a5,0(a0)
    80005244:	c385                	beqz	a5,80005264 <argfd+0x5c>
    return -1;
  if(pfd)
    80005246:	00090463          	beqz	s2,8000524e <argfd+0x46>
    *pfd = fd;
    8000524a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000524e:	4501                	li	a0,0
  if(pf)
    80005250:	c091                	beqz	s1,80005254 <argfd+0x4c>
    *pf = f;
    80005252:	e09c                	sd	a5,0(s1)
}
    80005254:	70a2                	ld	ra,40(sp)
    80005256:	7402                	ld	s0,32(sp)
    80005258:	64e2                	ld	s1,24(sp)
    8000525a:	6942                	ld	s2,16(sp)
    8000525c:	6145                	addi	sp,sp,48
    8000525e:	8082                	ret
    return -1;
    80005260:	557d                	li	a0,-1
    80005262:	bfcd                	j	80005254 <argfd+0x4c>
    80005264:	557d                	li	a0,-1
    80005266:	b7fd                	j	80005254 <argfd+0x4c>

0000000080005268 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005268:	1101                	addi	sp,sp,-32
    8000526a:	ec06                	sd	ra,24(sp)
    8000526c:	e822                	sd	s0,16(sp)
    8000526e:	e426                	sd	s1,8(sp)
    80005270:	1000                	addi	s0,sp,32
    80005272:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	816080e7          	jalr	-2026(ra) # 80001a8a <myproc>
    8000527c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000527e:	0d050793          	addi	a5,a0,208
    80005282:	4501                	li	a0,0
    80005284:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005286:	6398                	ld	a4,0(a5)
    80005288:	cb19                	beqz	a4,8000529e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000528a:	2505                	addiw	a0,a0,1
    8000528c:	07a1                	addi	a5,a5,8
    8000528e:	fed51ce3          	bne	a0,a3,80005286 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005292:	557d                	li	a0,-1
}
    80005294:	60e2                	ld	ra,24(sp)
    80005296:	6442                	ld	s0,16(sp)
    80005298:	64a2                	ld	s1,8(sp)
    8000529a:	6105                	addi	sp,sp,32
    8000529c:	8082                	ret
      p->ofile[fd] = f;
    8000529e:	01a50793          	addi	a5,a0,26
    800052a2:	078e                	slli	a5,a5,0x3
    800052a4:	963e                	add	a2,a2,a5
    800052a6:	e204                	sd	s1,0(a2)
      return fd;
    800052a8:	b7f5                	j	80005294 <fdalloc+0x2c>

00000000800052aa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052aa:	715d                	addi	sp,sp,-80
    800052ac:	e486                	sd	ra,72(sp)
    800052ae:	e0a2                	sd	s0,64(sp)
    800052b0:	fc26                	sd	s1,56(sp)
    800052b2:	f84a                	sd	s2,48(sp)
    800052b4:	f44e                	sd	s3,40(sp)
    800052b6:	f052                	sd	s4,32(sp)
    800052b8:	ec56                	sd	s5,24(sp)
    800052ba:	e85a                	sd	s6,16(sp)
    800052bc:	0880                	addi	s0,sp,80
    800052be:	8b2e                	mv	s6,a1
    800052c0:	89b2                	mv	s3,a2
    800052c2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052c4:	fb040593          	addi	a1,s0,-80
    800052c8:	fffff097          	auipc	ra,0xfffff
    800052cc:	e3e080e7          	jalr	-450(ra) # 80004106 <nameiparent>
    800052d0:	84aa                	mv	s1,a0
    800052d2:	14050f63          	beqz	a0,80005430 <create+0x186>
    return 0;

  ilock(dp);
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	666080e7          	jalr	1638(ra) # 8000393c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052de:	4601                	li	a2,0
    800052e0:	fb040593          	addi	a1,s0,-80
    800052e4:	8526                	mv	a0,s1
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	b3a080e7          	jalr	-1222(ra) # 80003e20 <dirlookup>
    800052ee:	8aaa                	mv	s5,a0
    800052f0:	c931                	beqz	a0,80005344 <create+0x9a>
    iunlockput(dp);
    800052f2:	8526                	mv	a0,s1
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	8aa080e7          	jalr	-1878(ra) # 80003b9e <iunlockput>
    ilock(ip);
    800052fc:	8556                	mv	a0,s5
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	63e080e7          	jalr	1598(ra) # 8000393c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005306:	000b059b          	sext.w	a1,s6
    8000530a:	4789                	li	a5,2
    8000530c:	02f59563          	bne	a1,a5,80005336 <create+0x8c>
    80005310:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd1c4>
    80005314:	37f9                	addiw	a5,a5,-2
    80005316:	17c2                	slli	a5,a5,0x30
    80005318:	93c1                	srli	a5,a5,0x30
    8000531a:	4705                	li	a4,1
    8000531c:	00f76d63          	bltu	a4,a5,80005336 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005320:	8556                	mv	a0,s5
    80005322:	60a6                	ld	ra,72(sp)
    80005324:	6406                	ld	s0,64(sp)
    80005326:	74e2                	ld	s1,56(sp)
    80005328:	7942                	ld	s2,48(sp)
    8000532a:	79a2                	ld	s3,40(sp)
    8000532c:	7a02                	ld	s4,32(sp)
    8000532e:	6ae2                	ld	s5,24(sp)
    80005330:	6b42                	ld	s6,16(sp)
    80005332:	6161                	addi	sp,sp,80
    80005334:	8082                	ret
    iunlockput(ip);
    80005336:	8556                	mv	a0,s5
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	866080e7          	jalr	-1946(ra) # 80003b9e <iunlockput>
    return 0;
    80005340:	4a81                	li	s5,0
    80005342:	bff9                	j	80005320 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005344:	85da                	mv	a1,s6
    80005346:	4088                	lw	a0,0(s1)
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	456080e7          	jalr	1110(ra) # 8000379e <ialloc>
    80005350:	8a2a                	mv	s4,a0
    80005352:	c539                	beqz	a0,800053a0 <create+0xf6>
  ilock(ip);
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	5e8080e7          	jalr	1512(ra) # 8000393c <ilock>
  ip->major = major;
    8000535c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005360:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005364:	4905                	li	s2,1
    80005366:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000536a:	8552                	mv	a0,s4
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	504080e7          	jalr	1284(ra) # 80003870 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005374:	000b059b          	sext.w	a1,s6
    80005378:	03258b63          	beq	a1,s2,800053ae <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000537c:	004a2603          	lw	a2,4(s4)
    80005380:	fb040593          	addi	a1,s0,-80
    80005384:	8526                	mv	a0,s1
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	cb0080e7          	jalr	-848(ra) # 80004036 <dirlink>
    8000538e:	06054f63          	bltz	a0,8000540c <create+0x162>
  iunlockput(dp);
    80005392:	8526                	mv	a0,s1
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	80a080e7          	jalr	-2038(ra) # 80003b9e <iunlockput>
  return ip;
    8000539c:	8ad2                	mv	s5,s4
    8000539e:	b749                	j	80005320 <create+0x76>
    iunlockput(dp);
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	7fc080e7          	jalr	2044(ra) # 80003b9e <iunlockput>
    return 0;
    800053aa:	8ad2                	mv	s5,s4
    800053ac:	bf95                	j	80005320 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053ae:	004a2603          	lw	a2,4(s4)
    800053b2:	00003597          	auipc	a1,0x3
    800053b6:	42658593          	addi	a1,a1,1062 # 800087d8 <syscalls+0x2b8>
    800053ba:	8552                	mv	a0,s4
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	c7a080e7          	jalr	-902(ra) # 80004036 <dirlink>
    800053c4:	04054463          	bltz	a0,8000540c <create+0x162>
    800053c8:	40d0                	lw	a2,4(s1)
    800053ca:	00003597          	auipc	a1,0x3
    800053ce:	41658593          	addi	a1,a1,1046 # 800087e0 <syscalls+0x2c0>
    800053d2:	8552                	mv	a0,s4
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	c62080e7          	jalr	-926(ra) # 80004036 <dirlink>
    800053dc:	02054863          	bltz	a0,8000540c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800053e0:	004a2603          	lw	a2,4(s4)
    800053e4:	fb040593          	addi	a1,s0,-80
    800053e8:	8526                	mv	a0,s1
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	c4c080e7          	jalr	-948(ra) # 80004036 <dirlink>
    800053f2:	00054d63          	bltz	a0,8000540c <create+0x162>
    dp->nlink++;  // for ".."
    800053f6:	04a4d783          	lhu	a5,74(s1)
    800053fa:	2785                	addiw	a5,a5,1
    800053fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005400:	8526                	mv	a0,s1
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	46e080e7          	jalr	1134(ra) # 80003870 <iupdate>
    8000540a:	b761                	j	80005392 <create+0xe8>
  ip->nlink = 0;
    8000540c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005410:	8552                	mv	a0,s4
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	45e080e7          	jalr	1118(ra) # 80003870 <iupdate>
  iunlockput(ip);
    8000541a:	8552                	mv	a0,s4
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	782080e7          	jalr	1922(ra) # 80003b9e <iunlockput>
  iunlockput(dp);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	778080e7          	jalr	1912(ra) # 80003b9e <iunlockput>
  return 0;
    8000542e:	bdcd                	j	80005320 <create+0x76>
    return 0;
    80005430:	8aaa                	mv	s5,a0
    80005432:	b5fd                	j	80005320 <create+0x76>

0000000080005434 <sys_dup>:
{
    80005434:	7179                	addi	sp,sp,-48
    80005436:	f406                	sd	ra,40(sp)
    80005438:	f022                	sd	s0,32(sp)
    8000543a:	ec26                	sd	s1,24(sp)
    8000543c:	e84a                	sd	s2,16(sp)
    8000543e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005440:	fd840613          	addi	a2,s0,-40
    80005444:	4581                	li	a1,0
    80005446:	4501                	li	a0,0
    80005448:	00000097          	auipc	ra,0x0
    8000544c:	dc0080e7          	jalr	-576(ra) # 80005208 <argfd>
    return -1;
    80005450:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005452:	02054363          	bltz	a0,80005478 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005456:	fd843903          	ld	s2,-40(s0)
    8000545a:	854a                	mv	a0,s2
    8000545c:	00000097          	auipc	ra,0x0
    80005460:	e0c080e7          	jalr	-500(ra) # 80005268 <fdalloc>
    80005464:	84aa                	mv	s1,a0
    return -1;
    80005466:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005468:	00054863          	bltz	a0,80005478 <sys_dup+0x44>
  filedup(f);
    8000546c:	854a                	mv	a0,s2
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	310080e7          	jalr	784(ra) # 8000477e <filedup>
  return fd;
    80005476:	87a6                	mv	a5,s1
}
    80005478:	853e                	mv	a0,a5
    8000547a:	70a2                	ld	ra,40(sp)
    8000547c:	7402                	ld	s0,32(sp)
    8000547e:	64e2                	ld	s1,24(sp)
    80005480:	6942                	ld	s2,16(sp)
    80005482:	6145                	addi	sp,sp,48
    80005484:	8082                	ret

0000000080005486 <sys_read>:
{
    80005486:	7179                	addi	sp,sp,-48
    80005488:	f406                	sd	ra,40(sp)
    8000548a:	f022                	sd	s0,32(sp)
    8000548c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000548e:	fd840593          	addi	a1,s0,-40
    80005492:	4505                	li	a0,1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	8ce080e7          	jalr	-1842(ra) # 80002d62 <argaddr>
  argint(2, &n);
    8000549c:	fe440593          	addi	a1,s0,-28
    800054a0:	4509                	li	a0,2
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	8a0080e7          	jalr	-1888(ra) # 80002d42 <argint>
  if(argfd(0, 0, &f) < 0)
    800054aa:	fe840613          	addi	a2,s0,-24
    800054ae:	4581                	li	a1,0
    800054b0:	4501                	li	a0,0
    800054b2:	00000097          	auipc	ra,0x0
    800054b6:	d56080e7          	jalr	-682(ra) # 80005208 <argfd>
    800054ba:	87aa                	mv	a5,a0
    return -1;
    800054bc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054be:	0007cc63          	bltz	a5,800054d6 <sys_read+0x50>
  return fileread(f, p, n);
    800054c2:	fe442603          	lw	a2,-28(s0)
    800054c6:	fd843583          	ld	a1,-40(s0)
    800054ca:	fe843503          	ld	a0,-24(s0)
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	43c080e7          	jalr	1084(ra) # 8000490a <fileread>
}
    800054d6:	70a2                	ld	ra,40(sp)
    800054d8:	7402                	ld	s0,32(sp)
    800054da:	6145                	addi	sp,sp,48
    800054dc:	8082                	ret

00000000800054de <sys_write>:
{
    800054de:	7179                	addi	sp,sp,-48
    800054e0:	f406                	sd	ra,40(sp)
    800054e2:	f022                	sd	s0,32(sp)
    800054e4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054e6:	fd840593          	addi	a1,s0,-40
    800054ea:	4505                	li	a0,1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	876080e7          	jalr	-1930(ra) # 80002d62 <argaddr>
  argint(2, &n);
    800054f4:	fe440593          	addi	a1,s0,-28
    800054f8:	4509                	li	a0,2
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	848080e7          	jalr	-1976(ra) # 80002d42 <argint>
  if(argfd(0, 0, &f) < 0)
    80005502:	fe840613          	addi	a2,s0,-24
    80005506:	4581                	li	a1,0
    80005508:	4501                	li	a0,0
    8000550a:	00000097          	auipc	ra,0x0
    8000550e:	cfe080e7          	jalr	-770(ra) # 80005208 <argfd>
    80005512:	87aa                	mv	a5,a0
    return -1;
    80005514:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005516:	0007cc63          	bltz	a5,8000552e <sys_write+0x50>
  return filewrite(f, p, n);
    8000551a:	fe442603          	lw	a2,-28(s0)
    8000551e:	fd843583          	ld	a1,-40(s0)
    80005522:	fe843503          	ld	a0,-24(s0)
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	4a6080e7          	jalr	1190(ra) # 800049cc <filewrite>
}
    8000552e:	70a2                	ld	ra,40(sp)
    80005530:	7402                	ld	s0,32(sp)
    80005532:	6145                	addi	sp,sp,48
    80005534:	8082                	ret

0000000080005536 <sys_close>:
{
    80005536:	1101                	addi	sp,sp,-32
    80005538:	ec06                	sd	ra,24(sp)
    8000553a:	e822                	sd	s0,16(sp)
    8000553c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000553e:	fe040613          	addi	a2,s0,-32
    80005542:	fec40593          	addi	a1,s0,-20
    80005546:	4501                	li	a0,0
    80005548:	00000097          	auipc	ra,0x0
    8000554c:	cc0080e7          	jalr	-832(ra) # 80005208 <argfd>
    return -1;
    80005550:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005552:	02054463          	bltz	a0,8000557a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	534080e7          	jalr	1332(ra) # 80001a8a <myproc>
    8000555e:	fec42783          	lw	a5,-20(s0)
    80005562:	07e9                	addi	a5,a5,26
    80005564:	078e                	slli	a5,a5,0x3
    80005566:	953e                	add	a0,a0,a5
    80005568:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000556c:	fe043503          	ld	a0,-32(s0)
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	260080e7          	jalr	608(ra) # 800047d0 <fileclose>
  return 0;
    80005578:	4781                	li	a5,0
}
    8000557a:	853e                	mv	a0,a5
    8000557c:	60e2                	ld	ra,24(sp)
    8000557e:	6442                	ld	s0,16(sp)
    80005580:	6105                	addi	sp,sp,32
    80005582:	8082                	ret

0000000080005584 <sys_fstat>:
{
    80005584:	1101                	addi	sp,sp,-32
    80005586:	ec06                	sd	ra,24(sp)
    80005588:	e822                	sd	s0,16(sp)
    8000558a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000558c:	fe040593          	addi	a1,s0,-32
    80005590:	4505                	li	a0,1
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	7d0080e7          	jalr	2000(ra) # 80002d62 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000559a:	fe840613          	addi	a2,s0,-24
    8000559e:	4581                	li	a1,0
    800055a0:	4501                	li	a0,0
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	c66080e7          	jalr	-922(ra) # 80005208 <argfd>
    800055aa:	87aa                	mv	a5,a0
    return -1;
    800055ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ae:	0007ca63          	bltz	a5,800055c2 <sys_fstat+0x3e>
  return filestat(f, st);
    800055b2:	fe043583          	ld	a1,-32(s0)
    800055b6:	fe843503          	ld	a0,-24(s0)
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	2de080e7          	jalr	734(ra) # 80004898 <filestat>
}
    800055c2:	60e2                	ld	ra,24(sp)
    800055c4:	6442                	ld	s0,16(sp)
    800055c6:	6105                	addi	sp,sp,32
    800055c8:	8082                	ret

00000000800055ca <sys_link>:
{
    800055ca:	7169                	addi	sp,sp,-304
    800055cc:	f606                	sd	ra,296(sp)
    800055ce:	f222                	sd	s0,288(sp)
    800055d0:	ee26                	sd	s1,280(sp)
    800055d2:	ea4a                	sd	s2,272(sp)
    800055d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d6:	08000613          	li	a2,128
    800055da:	ed040593          	addi	a1,s0,-304
    800055de:	4501                	li	a0,0
    800055e0:	ffffd097          	auipc	ra,0xffffd
    800055e4:	7a2080e7          	jalr	1954(ra) # 80002d82 <argstr>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ea:	10054e63          	bltz	a0,80005706 <sys_link+0x13c>
    800055ee:	08000613          	li	a2,128
    800055f2:	f5040593          	addi	a1,s0,-176
    800055f6:	4505                	li	a0,1
    800055f8:	ffffd097          	auipc	ra,0xffffd
    800055fc:	78a080e7          	jalr	1930(ra) # 80002d82 <argstr>
    return -1;
    80005600:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005602:	10054263          	bltz	a0,80005706 <sys_link+0x13c>
  begin_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	d02080e7          	jalr	-766(ra) # 80004308 <begin_op>
  if((ip = namei(old)) == 0){
    8000560e:	ed040513          	addi	a0,s0,-304
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	ad6080e7          	jalr	-1322(ra) # 800040e8 <namei>
    8000561a:	84aa                	mv	s1,a0
    8000561c:	c551                	beqz	a0,800056a8 <sys_link+0xde>
  ilock(ip);
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	31e080e7          	jalr	798(ra) # 8000393c <ilock>
  if(ip->type == T_DIR){
    80005626:	04449703          	lh	a4,68(s1)
    8000562a:	4785                	li	a5,1
    8000562c:	08f70463          	beq	a4,a5,800056b4 <sys_link+0xea>
  ip->nlink++;
    80005630:	04a4d783          	lhu	a5,74(s1)
    80005634:	2785                	addiw	a5,a5,1
    80005636:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	234080e7          	jalr	564(ra) # 80003870 <iupdate>
  iunlock(ip);
    80005644:	8526                	mv	a0,s1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	3b8080e7          	jalr	952(ra) # 800039fe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000564e:	fd040593          	addi	a1,s0,-48
    80005652:	f5040513          	addi	a0,s0,-176
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	ab0080e7          	jalr	-1360(ra) # 80004106 <nameiparent>
    8000565e:	892a                	mv	s2,a0
    80005660:	c935                	beqz	a0,800056d4 <sys_link+0x10a>
  ilock(dp);
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	2da080e7          	jalr	730(ra) # 8000393c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000566a:	00092703          	lw	a4,0(s2)
    8000566e:	409c                	lw	a5,0(s1)
    80005670:	04f71d63          	bne	a4,a5,800056ca <sys_link+0x100>
    80005674:	40d0                	lw	a2,4(s1)
    80005676:	fd040593          	addi	a1,s0,-48
    8000567a:	854a                	mv	a0,s2
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	9ba080e7          	jalr	-1606(ra) # 80004036 <dirlink>
    80005684:	04054363          	bltz	a0,800056ca <sys_link+0x100>
  iunlockput(dp);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	514080e7          	jalr	1300(ra) # 80003b9e <iunlockput>
  iput(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	462080e7          	jalr	1122(ra) # 80003af6 <iput>
  end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	cea080e7          	jalr	-790(ra) # 80004386 <end_op>
  return 0;
    800056a4:	4781                	li	a5,0
    800056a6:	a085                	j	80005706 <sys_link+0x13c>
    end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	cde080e7          	jalr	-802(ra) # 80004386 <end_op>
    return -1;
    800056b0:	57fd                	li	a5,-1
    800056b2:	a891                	j	80005706 <sys_link+0x13c>
    iunlockput(ip);
    800056b4:	8526                	mv	a0,s1
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	4e8080e7          	jalr	1256(ra) # 80003b9e <iunlockput>
    end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	cc8080e7          	jalr	-824(ra) # 80004386 <end_op>
    return -1;
    800056c6:	57fd                	li	a5,-1
    800056c8:	a83d                	j	80005706 <sys_link+0x13c>
    iunlockput(dp);
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	4d2080e7          	jalr	1234(ra) # 80003b9e <iunlockput>
  ilock(ip);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	266080e7          	jalr	614(ra) # 8000393c <ilock>
  ip->nlink--;
    800056de:	04a4d783          	lhu	a5,74(s1)
    800056e2:	37fd                	addiw	a5,a5,-1
    800056e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	186080e7          	jalr	390(ra) # 80003870 <iupdate>
  iunlockput(ip);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	4aa080e7          	jalr	1194(ra) # 80003b9e <iunlockput>
  end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	c8a080e7          	jalr	-886(ra) # 80004386 <end_op>
  return -1;
    80005704:	57fd                	li	a5,-1
}
    80005706:	853e                	mv	a0,a5
    80005708:	70b2                	ld	ra,296(sp)
    8000570a:	7412                	ld	s0,288(sp)
    8000570c:	64f2                	ld	s1,280(sp)
    8000570e:	6952                	ld	s2,272(sp)
    80005710:	6155                	addi	sp,sp,304
    80005712:	8082                	ret

0000000080005714 <sys_unlink>:
{
    80005714:	7151                	addi	sp,sp,-240
    80005716:	f586                	sd	ra,232(sp)
    80005718:	f1a2                	sd	s0,224(sp)
    8000571a:	eda6                	sd	s1,216(sp)
    8000571c:	e9ca                	sd	s2,208(sp)
    8000571e:	e5ce                	sd	s3,200(sp)
    80005720:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005722:	08000613          	li	a2,128
    80005726:	f3040593          	addi	a1,s0,-208
    8000572a:	4501                	li	a0,0
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	656080e7          	jalr	1622(ra) # 80002d82 <argstr>
    80005734:	18054163          	bltz	a0,800058b6 <sys_unlink+0x1a2>
  begin_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	bd0080e7          	jalr	-1072(ra) # 80004308 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005740:	fb040593          	addi	a1,s0,-80
    80005744:	f3040513          	addi	a0,s0,-208
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	9be080e7          	jalr	-1602(ra) # 80004106 <nameiparent>
    80005750:	84aa                	mv	s1,a0
    80005752:	c979                	beqz	a0,80005828 <sys_unlink+0x114>
  ilock(dp);
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	1e8080e7          	jalr	488(ra) # 8000393c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000575c:	00003597          	auipc	a1,0x3
    80005760:	07c58593          	addi	a1,a1,124 # 800087d8 <syscalls+0x2b8>
    80005764:	fb040513          	addi	a0,s0,-80
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	69e080e7          	jalr	1694(ra) # 80003e06 <namecmp>
    80005770:	14050a63          	beqz	a0,800058c4 <sys_unlink+0x1b0>
    80005774:	00003597          	auipc	a1,0x3
    80005778:	06c58593          	addi	a1,a1,108 # 800087e0 <syscalls+0x2c0>
    8000577c:	fb040513          	addi	a0,s0,-80
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	686080e7          	jalr	1670(ra) # 80003e06 <namecmp>
    80005788:	12050e63          	beqz	a0,800058c4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000578c:	f2c40613          	addi	a2,s0,-212
    80005790:	fb040593          	addi	a1,s0,-80
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	68a080e7          	jalr	1674(ra) # 80003e20 <dirlookup>
    8000579e:	892a                	mv	s2,a0
    800057a0:	12050263          	beqz	a0,800058c4 <sys_unlink+0x1b0>
  ilock(ip);
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	198080e7          	jalr	408(ra) # 8000393c <ilock>
  if(ip->nlink < 1)
    800057ac:	04a91783          	lh	a5,74(s2)
    800057b0:	08f05263          	blez	a5,80005834 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057b4:	04491703          	lh	a4,68(s2)
    800057b8:	4785                	li	a5,1
    800057ba:	08f70563          	beq	a4,a5,80005844 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057be:	4641                	li	a2,16
    800057c0:	4581                	li	a1,0
    800057c2:	fc040513          	addi	a0,s0,-64
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	50c080e7          	jalr	1292(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ce:	4741                	li	a4,16
    800057d0:	f2c42683          	lw	a3,-212(s0)
    800057d4:	fc040613          	addi	a2,s0,-64
    800057d8:	4581                	li	a1,0
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	50c080e7          	jalr	1292(ra) # 80003ce8 <writei>
    800057e4:	47c1                	li	a5,16
    800057e6:	0af51563          	bne	a0,a5,80005890 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	4785                	li	a5,1
    800057f0:	0af70863          	beq	a4,a5,800058a0 <sys_unlink+0x18c>
  iunlockput(dp);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	3a8080e7          	jalr	936(ra) # 80003b9e <iunlockput>
  ip->nlink--;
    800057fe:	04a95783          	lhu	a5,74(s2)
    80005802:	37fd                	addiw	a5,a5,-1
    80005804:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	066080e7          	jalr	102(ra) # 80003870 <iupdate>
  iunlockput(ip);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	38a080e7          	jalr	906(ra) # 80003b9e <iunlockput>
  end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	b6a080e7          	jalr	-1174(ra) # 80004386 <end_op>
  return 0;
    80005824:	4501                	li	a0,0
    80005826:	a84d                	j	800058d8 <sys_unlink+0x1c4>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	b5e080e7          	jalr	-1186(ra) # 80004386 <end_op>
    return -1;
    80005830:	557d                	li	a0,-1
    80005832:	a05d                	j	800058d8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005834:	00003517          	auipc	a0,0x3
    80005838:	fb450513          	addi	a0,a0,-76 # 800087e8 <syscalls+0x2c8>
    8000583c:	ffffb097          	auipc	ra,0xffffb
    80005840:	d04080e7          	jalr	-764(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005844:	04c92703          	lw	a4,76(s2)
    80005848:	02000793          	li	a5,32
    8000584c:	f6e7f9e3          	bgeu	a5,a4,800057be <sys_unlink+0xaa>
    80005850:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005854:	4741                	li	a4,16
    80005856:	86ce                	mv	a3,s3
    80005858:	f1840613          	addi	a2,s0,-232
    8000585c:	4581                	li	a1,0
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	390080e7          	jalr	912(ra) # 80003bf0 <readi>
    80005868:	47c1                	li	a5,16
    8000586a:	00f51b63          	bne	a0,a5,80005880 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000586e:	f1845783          	lhu	a5,-232(s0)
    80005872:	e7a1                	bnez	a5,800058ba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005874:	29c1                	addiw	s3,s3,16
    80005876:	04c92783          	lw	a5,76(s2)
    8000587a:	fcf9ede3          	bltu	s3,a5,80005854 <sys_unlink+0x140>
    8000587e:	b781                	j	800057be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005880:	00003517          	auipc	a0,0x3
    80005884:	f8050513          	addi	a0,a0,-128 # 80008800 <syscalls+0x2e0>
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	cb8080e7          	jalr	-840(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005890:	00003517          	auipc	a0,0x3
    80005894:	f8850513          	addi	a0,a0,-120 # 80008818 <syscalls+0x2f8>
    80005898:	ffffb097          	auipc	ra,0xffffb
    8000589c:	ca8080e7          	jalr	-856(ra) # 80000540 <panic>
    dp->nlink--;
    800058a0:	04a4d783          	lhu	a5,74(s1)
    800058a4:	37fd                	addiw	a5,a5,-1
    800058a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	fc4080e7          	jalr	-60(ra) # 80003870 <iupdate>
    800058b4:	b781                	j	800057f4 <sys_unlink+0xe0>
    return -1;
    800058b6:	557d                	li	a0,-1
    800058b8:	a005                	j	800058d8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058ba:	854a                	mv	a0,s2
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	2e2080e7          	jalr	738(ra) # 80003b9e <iunlockput>
  iunlockput(dp);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	2d8080e7          	jalr	728(ra) # 80003b9e <iunlockput>
  end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	ab8080e7          	jalr	-1352(ra) # 80004386 <end_op>
  return -1;
    800058d6:	557d                	li	a0,-1
}
    800058d8:	70ae                	ld	ra,232(sp)
    800058da:	740e                	ld	s0,224(sp)
    800058dc:	64ee                	ld	s1,216(sp)
    800058de:	694e                	ld	s2,208(sp)
    800058e0:	69ae                	ld	s3,200(sp)
    800058e2:	616d                	addi	sp,sp,240
    800058e4:	8082                	ret

00000000800058e6 <sys_open>:

uint64
sys_open(void)
{
    800058e6:	7131                	addi	sp,sp,-192
    800058e8:	fd06                	sd	ra,184(sp)
    800058ea:	f922                	sd	s0,176(sp)
    800058ec:	f526                	sd	s1,168(sp)
    800058ee:	f14a                	sd	s2,160(sp)
    800058f0:	ed4e                	sd	s3,152(sp)
    800058f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058f4:	f4c40593          	addi	a1,s0,-180
    800058f8:	4505                	li	a0,1
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	448080e7          	jalr	1096(ra) # 80002d42 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005902:	08000613          	li	a2,128
    80005906:	f5040593          	addi	a1,s0,-176
    8000590a:	4501                	li	a0,0
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	476080e7          	jalr	1142(ra) # 80002d82 <argstr>
    80005914:	87aa                	mv	a5,a0
    return -1;
    80005916:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005918:	0a07c963          	bltz	a5,800059ca <sys_open+0xe4>

  begin_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	9ec080e7          	jalr	-1556(ra) # 80004308 <begin_op>

  if(omode & O_CREATE){
    80005924:	f4c42783          	lw	a5,-180(s0)
    80005928:	2007f793          	andi	a5,a5,512
    8000592c:	cfc5                	beqz	a5,800059e4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000592e:	4681                	li	a3,0
    80005930:	4601                	li	a2,0
    80005932:	4589                	li	a1,2
    80005934:	f5040513          	addi	a0,s0,-176
    80005938:	00000097          	auipc	ra,0x0
    8000593c:	972080e7          	jalr	-1678(ra) # 800052aa <create>
    80005940:	84aa                	mv	s1,a0
    if(ip == 0){
    80005942:	c959                	beqz	a0,800059d8 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005944:	04449703          	lh	a4,68(s1)
    80005948:	478d                	li	a5,3
    8000594a:	00f71763          	bne	a4,a5,80005958 <sys_open+0x72>
    8000594e:	0464d703          	lhu	a4,70(s1)
    80005952:	47a5                	li	a5,9
    80005954:	0ce7ed63          	bltu	a5,a4,80005a2e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	dbc080e7          	jalr	-580(ra) # 80004714 <filealloc>
    80005960:	89aa                	mv	s3,a0
    80005962:	10050363          	beqz	a0,80005a68 <sys_open+0x182>
    80005966:	00000097          	auipc	ra,0x0
    8000596a:	902080e7          	jalr	-1790(ra) # 80005268 <fdalloc>
    8000596e:	892a                	mv	s2,a0
    80005970:	0e054763          	bltz	a0,80005a5e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005974:	04449703          	lh	a4,68(s1)
    80005978:	478d                	li	a5,3
    8000597a:	0cf70563          	beq	a4,a5,80005a44 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000597e:	4789                	li	a5,2
    80005980:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005984:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005988:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000598c:	f4c42783          	lw	a5,-180(s0)
    80005990:	0017c713          	xori	a4,a5,1
    80005994:	8b05                	andi	a4,a4,1
    80005996:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000599a:	0037f713          	andi	a4,a5,3
    8000599e:	00e03733          	snez	a4,a4
    800059a2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059a6:	4007f793          	andi	a5,a5,1024
    800059aa:	c791                	beqz	a5,800059b6 <sys_open+0xd0>
    800059ac:	04449703          	lh	a4,68(s1)
    800059b0:	4789                	li	a5,2
    800059b2:	0af70063          	beq	a4,a5,80005a52 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	046080e7          	jalr	70(ra) # 800039fe <iunlock>
  end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	9c6080e7          	jalr	-1594(ra) # 80004386 <end_op>

  return fd;
    800059c8:	854a                	mv	a0,s2
}
    800059ca:	70ea                	ld	ra,184(sp)
    800059cc:	744a                	ld	s0,176(sp)
    800059ce:	74aa                	ld	s1,168(sp)
    800059d0:	790a                	ld	s2,160(sp)
    800059d2:	69ea                	ld	s3,152(sp)
    800059d4:	6129                	addi	sp,sp,192
    800059d6:	8082                	ret
      end_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	9ae080e7          	jalr	-1618(ra) # 80004386 <end_op>
      return -1;
    800059e0:	557d                	li	a0,-1
    800059e2:	b7e5                	j	800059ca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059e4:	f5040513          	addi	a0,s0,-176
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	700080e7          	jalr	1792(ra) # 800040e8 <namei>
    800059f0:	84aa                	mv	s1,a0
    800059f2:	c905                	beqz	a0,80005a22 <sys_open+0x13c>
    ilock(ip);
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	f48080e7          	jalr	-184(ra) # 8000393c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059fc:	04449703          	lh	a4,68(s1)
    80005a00:	4785                	li	a5,1
    80005a02:	f4f711e3          	bne	a4,a5,80005944 <sys_open+0x5e>
    80005a06:	f4c42783          	lw	a5,-180(s0)
    80005a0a:	d7b9                	beqz	a5,80005958 <sys_open+0x72>
      iunlockput(ip);
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	190080e7          	jalr	400(ra) # 80003b9e <iunlockput>
      end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	970080e7          	jalr	-1680(ra) # 80004386 <end_op>
      return -1;
    80005a1e:	557d                	li	a0,-1
    80005a20:	b76d                	j	800059ca <sys_open+0xe4>
      end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	964080e7          	jalr	-1692(ra) # 80004386 <end_op>
      return -1;
    80005a2a:	557d                	li	a0,-1
    80005a2c:	bf79                	j	800059ca <sys_open+0xe4>
    iunlockput(ip);
    80005a2e:	8526                	mv	a0,s1
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	16e080e7          	jalr	366(ra) # 80003b9e <iunlockput>
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	94e080e7          	jalr	-1714(ra) # 80004386 <end_op>
    return -1;
    80005a40:	557d                	li	a0,-1
    80005a42:	b761                	j	800059ca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a44:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a48:	04649783          	lh	a5,70(s1)
    80005a4c:	02f99223          	sh	a5,36(s3)
    80005a50:	bf25                	j	80005988 <sys_open+0xa2>
    itrunc(ip);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	ff6080e7          	jalr	-10(ra) # 80003a4a <itrunc>
    80005a5c:	bfa9                	j	800059b6 <sys_open+0xd0>
      fileclose(f);
    80005a5e:	854e                	mv	a0,s3
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	d70080e7          	jalr	-656(ra) # 800047d0 <fileclose>
    iunlockput(ip);
    80005a68:	8526                	mv	a0,s1
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	134080e7          	jalr	308(ra) # 80003b9e <iunlockput>
    end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	914080e7          	jalr	-1772(ra) # 80004386 <end_op>
    return -1;
    80005a7a:	557d                	li	a0,-1
    80005a7c:	b7b9                	j	800059ca <sys_open+0xe4>

0000000080005a7e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a7e:	7175                	addi	sp,sp,-144
    80005a80:	e506                	sd	ra,136(sp)
    80005a82:	e122                	sd	s0,128(sp)
    80005a84:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	882080e7          	jalr	-1918(ra) # 80004308 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a8e:	08000613          	li	a2,128
    80005a92:	f7040593          	addi	a1,s0,-144
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	2ea080e7          	jalr	746(ra) # 80002d82 <argstr>
    80005aa0:	02054963          	bltz	a0,80005ad2 <sys_mkdir+0x54>
    80005aa4:	4681                	li	a3,0
    80005aa6:	4601                	li	a2,0
    80005aa8:	4585                	li	a1,1
    80005aaa:	f7040513          	addi	a0,s0,-144
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	7fc080e7          	jalr	2044(ra) # 800052aa <create>
    80005ab6:	cd11                	beqz	a0,80005ad2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	0e6080e7          	jalr	230(ra) # 80003b9e <iunlockput>
  end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	8c6080e7          	jalr	-1850(ra) # 80004386 <end_op>
  return 0;
    80005ac8:	4501                	li	a0,0
}
    80005aca:	60aa                	ld	ra,136(sp)
    80005acc:	640a                	ld	s0,128(sp)
    80005ace:	6149                	addi	sp,sp,144
    80005ad0:	8082                	ret
    end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	8b4080e7          	jalr	-1868(ra) # 80004386 <end_op>
    return -1;
    80005ada:	557d                	li	a0,-1
    80005adc:	b7fd                	j	80005aca <sys_mkdir+0x4c>

0000000080005ade <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ade:	7135                	addi	sp,sp,-160
    80005ae0:	ed06                	sd	ra,152(sp)
    80005ae2:	e922                	sd	s0,144(sp)
    80005ae4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	822080e7          	jalr	-2014(ra) # 80004308 <begin_op>
  argint(1, &major);
    80005aee:	f6c40593          	addi	a1,s0,-148
    80005af2:	4505                	li	a0,1
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	24e080e7          	jalr	590(ra) # 80002d42 <argint>
  argint(2, &minor);
    80005afc:	f6840593          	addi	a1,s0,-152
    80005b00:	4509                	li	a0,2
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	240080e7          	jalr	576(ra) # 80002d42 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b0a:	08000613          	li	a2,128
    80005b0e:	f7040593          	addi	a1,s0,-144
    80005b12:	4501                	li	a0,0
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	26e080e7          	jalr	622(ra) # 80002d82 <argstr>
    80005b1c:	02054b63          	bltz	a0,80005b52 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b20:	f6841683          	lh	a3,-152(s0)
    80005b24:	f6c41603          	lh	a2,-148(s0)
    80005b28:	458d                	li	a1,3
    80005b2a:	f7040513          	addi	a0,s0,-144
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	77c080e7          	jalr	1916(ra) # 800052aa <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b36:	cd11                	beqz	a0,80005b52 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	066080e7          	jalr	102(ra) # 80003b9e <iunlockput>
  end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	846080e7          	jalr	-1978(ra) # 80004386 <end_op>
  return 0;
    80005b48:	4501                	li	a0,0
}
    80005b4a:	60ea                	ld	ra,152(sp)
    80005b4c:	644a                	ld	s0,144(sp)
    80005b4e:	610d                	addi	sp,sp,160
    80005b50:	8082                	ret
    end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	834080e7          	jalr	-1996(ra) # 80004386 <end_op>
    return -1;
    80005b5a:	557d                	li	a0,-1
    80005b5c:	b7fd                	j	80005b4a <sys_mknod+0x6c>

0000000080005b5e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b5e:	7135                	addi	sp,sp,-160
    80005b60:	ed06                	sd	ra,152(sp)
    80005b62:	e922                	sd	s0,144(sp)
    80005b64:	e526                	sd	s1,136(sp)
    80005b66:	e14a                	sd	s2,128(sp)
    80005b68:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b6a:	ffffc097          	auipc	ra,0xffffc
    80005b6e:	f20080e7          	jalr	-224(ra) # 80001a8a <myproc>
    80005b72:	892a                	mv	s2,a0
  
  begin_op();
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	794080e7          	jalr	1940(ra) # 80004308 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b7c:	08000613          	li	a2,128
    80005b80:	f6040593          	addi	a1,s0,-160
    80005b84:	4501                	li	a0,0
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	1fc080e7          	jalr	508(ra) # 80002d82 <argstr>
    80005b8e:	04054b63          	bltz	a0,80005be4 <sys_chdir+0x86>
    80005b92:	f6040513          	addi	a0,s0,-160
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	552080e7          	jalr	1362(ra) # 800040e8 <namei>
    80005b9e:	84aa                	mv	s1,a0
    80005ba0:	c131                	beqz	a0,80005be4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	d9a080e7          	jalr	-614(ra) # 8000393c <ilock>
  if(ip->type != T_DIR){
    80005baa:	04449703          	lh	a4,68(s1)
    80005bae:	4785                	li	a5,1
    80005bb0:	04f71063          	bne	a4,a5,80005bf0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bb4:	8526                	mv	a0,s1
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	e48080e7          	jalr	-440(ra) # 800039fe <iunlock>
  iput(p->cwd);
    80005bbe:	15093503          	ld	a0,336(s2)
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	f34080e7          	jalr	-204(ra) # 80003af6 <iput>
  end_op();
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	7bc080e7          	jalr	1980(ra) # 80004386 <end_op>
  p->cwd = ip;
    80005bd2:	14993823          	sd	s1,336(s2)
  return 0;
    80005bd6:	4501                	li	a0,0
}
    80005bd8:	60ea                	ld	ra,152(sp)
    80005bda:	644a                	ld	s0,144(sp)
    80005bdc:	64aa                	ld	s1,136(sp)
    80005bde:	690a                	ld	s2,128(sp)
    80005be0:	610d                	addi	sp,sp,160
    80005be2:	8082                	ret
    end_op();
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	7a2080e7          	jalr	1954(ra) # 80004386 <end_op>
    return -1;
    80005bec:	557d                	li	a0,-1
    80005bee:	b7ed                	j	80005bd8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bf0:	8526                	mv	a0,s1
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	fac080e7          	jalr	-84(ra) # 80003b9e <iunlockput>
    end_op();
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	78c080e7          	jalr	1932(ra) # 80004386 <end_op>
    return -1;
    80005c02:	557d                	li	a0,-1
    80005c04:	bfd1                	j	80005bd8 <sys_chdir+0x7a>

0000000080005c06 <sys_exec>:

uint64
sys_exec(void)
{
    80005c06:	7145                	addi	sp,sp,-464
    80005c08:	e786                	sd	ra,456(sp)
    80005c0a:	e3a2                	sd	s0,448(sp)
    80005c0c:	ff26                	sd	s1,440(sp)
    80005c0e:	fb4a                	sd	s2,432(sp)
    80005c10:	f74e                	sd	s3,424(sp)
    80005c12:	f352                	sd	s4,416(sp)
    80005c14:	ef56                	sd	s5,408(sp)
    80005c16:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c18:	e3840593          	addi	a1,s0,-456
    80005c1c:	4505                	li	a0,1
    80005c1e:	ffffd097          	auipc	ra,0xffffd
    80005c22:	144080e7          	jalr	324(ra) # 80002d62 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c26:	08000613          	li	a2,128
    80005c2a:	f4040593          	addi	a1,s0,-192
    80005c2e:	4501                	li	a0,0
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	152080e7          	jalr	338(ra) # 80002d82 <argstr>
    80005c38:	87aa                	mv	a5,a0
    return -1;
    80005c3a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c3c:	0c07c363          	bltz	a5,80005d02 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005c40:	10000613          	li	a2,256
    80005c44:	4581                	li	a1,0
    80005c46:	e4040513          	addi	a0,s0,-448
    80005c4a:	ffffb097          	auipc	ra,0xffffb
    80005c4e:	088080e7          	jalr	136(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c56:	89a6                	mv	s3,s1
    80005c58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c5a:	02000a13          	li	s4,32
    80005c5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c62:	00391513          	slli	a0,s2,0x3
    80005c66:	e3040593          	addi	a1,s0,-464
    80005c6a:	e3843783          	ld	a5,-456(s0)
    80005c6e:	953e                	add	a0,a0,a5
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	034080e7          	jalr	52(ra) # 80002ca4 <fetchaddr>
    80005c78:	02054a63          	bltz	a0,80005cac <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c7c:	e3043783          	ld	a5,-464(s0)
    80005c80:	c3b9                	beqz	a5,80005cc6 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c82:	ffffb097          	auipc	ra,0xffffb
    80005c86:	e64080e7          	jalr	-412(ra) # 80000ae6 <kalloc>
    80005c8a:	85aa                	mv	a1,a0
    80005c8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c90:	cd11                	beqz	a0,80005cac <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c92:	6605                	lui	a2,0x1
    80005c94:	e3043503          	ld	a0,-464(s0)
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	05e080e7          	jalr	94(ra) # 80002cf6 <fetchstr>
    80005ca0:	00054663          	bltz	a0,80005cac <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ca4:	0905                	addi	s2,s2,1
    80005ca6:	09a1                	addi	s3,s3,8
    80005ca8:	fb491be3          	bne	s2,s4,80005c5e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cac:	f4040913          	addi	s2,s0,-192
    80005cb0:	6088                	ld	a0,0(s1)
    80005cb2:	c539                	beqz	a0,80005d00 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	d34080e7          	jalr	-716(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cbc:	04a1                	addi	s1,s1,8
    80005cbe:	ff2499e3          	bne	s1,s2,80005cb0 <sys_exec+0xaa>
  return -1;
    80005cc2:	557d                	li	a0,-1
    80005cc4:	a83d                	j	80005d02 <sys_exec+0xfc>
      argv[i] = 0;
    80005cc6:	0a8e                	slli	s5,s5,0x3
    80005cc8:	fc0a8793          	addi	a5,s5,-64
    80005ccc:	00878ab3          	add	s5,a5,s0
    80005cd0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cd4:	e4040593          	addi	a1,s0,-448
    80005cd8:	f4040513          	addi	a0,s0,-192
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	16e080e7          	jalr	366(ra) # 80004e4a <exec>
    80005ce4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce6:	f4040993          	addi	s3,s0,-192
    80005cea:	6088                	ld	a0,0(s1)
    80005cec:	c901                	beqz	a0,80005cfc <sys_exec+0xf6>
    kfree(argv[i]);
    80005cee:	ffffb097          	auipc	ra,0xffffb
    80005cf2:	cfa080e7          	jalr	-774(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf6:	04a1                	addi	s1,s1,8
    80005cf8:	ff3499e3          	bne	s1,s3,80005cea <sys_exec+0xe4>
  return ret;
    80005cfc:	854a                	mv	a0,s2
    80005cfe:	a011                	j	80005d02 <sys_exec+0xfc>
  return -1;
    80005d00:	557d                	li	a0,-1
}
    80005d02:	60be                	ld	ra,456(sp)
    80005d04:	641e                	ld	s0,448(sp)
    80005d06:	74fa                	ld	s1,440(sp)
    80005d08:	795a                	ld	s2,432(sp)
    80005d0a:	79ba                	ld	s3,424(sp)
    80005d0c:	7a1a                	ld	s4,416(sp)
    80005d0e:	6afa                	ld	s5,408(sp)
    80005d10:	6179                	addi	sp,sp,464
    80005d12:	8082                	ret

0000000080005d14 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d14:	7139                	addi	sp,sp,-64
    80005d16:	fc06                	sd	ra,56(sp)
    80005d18:	f822                	sd	s0,48(sp)
    80005d1a:	f426                	sd	s1,40(sp)
    80005d1c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d1e:	ffffc097          	auipc	ra,0xffffc
    80005d22:	d6c080e7          	jalr	-660(ra) # 80001a8a <myproc>
    80005d26:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d28:	fd840593          	addi	a1,s0,-40
    80005d2c:	4501                	li	a0,0
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	034080e7          	jalr	52(ra) # 80002d62 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d36:	fc840593          	addi	a1,s0,-56
    80005d3a:	fd040513          	addi	a0,s0,-48
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	dc2080e7          	jalr	-574(ra) # 80004b00 <pipealloc>
    return -1;
    80005d46:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d48:	0c054463          	bltz	a0,80005e10 <sys_pipe+0xfc>
  fd0 = -1;
    80005d4c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d50:	fd043503          	ld	a0,-48(s0)
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	514080e7          	jalr	1300(ra) # 80005268 <fdalloc>
    80005d5c:	fca42223          	sw	a0,-60(s0)
    80005d60:	08054b63          	bltz	a0,80005df6 <sys_pipe+0xe2>
    80005d64:	fc843503          	ld	a0,-56(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	500080e7          	jalr	1280(ra) # 80005268 <fdalloc>
    80005d70:	fca42023          	sw	a0,-64(s0)
    80005d74:	06054863          	bltz	a0,80005de4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d78:	4691                	li	a3,4
    80005d7a:	fc440613          	addi	a2,s0,-60
    80005d7e:	fd843583          	ld	a1,-40(s0)
    80005d82:	68a8                	ld	a0,80(s1)
    80005d84:	ffffc097          	auipc	ra,0xffffc
    80005d88:	8e8080e7          	jalr	-1816(ra) # 8000166c <copyout>
    80005d8c:	02054063          	bltz	a0,80005dac <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d90:	4691                	li	a3,4
    80005d92:	fc040613          	addi	a2,s0,-64
    80005d96:	fd843583          	ld	a1,-40(s0)
    80005d9a:	0591                	addi	a1,a1,4
    80005d9c:	68a8                	ld	a0,80(s1)
    80005d9e:	ffffc097          	auipc	ra,0xffffc
    80005da2:	8ce080e7          	jalr	-1842(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005da6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da8:	06055463          	bgez	a0,80005e10 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005dac:	fc442783          	lw	a5,-60(s0)
    80005db0:	07e9                	addi	a5,a5,26
    80005db2:	078e                	slli	a5,a5,0x3
    80005db4:	97a6                	add	a5,a5,s1
    80005db6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dba:	fc042783          	lw	a5,-64(s0)
    80005dbe:	07e9                	addi	a5,a5,26
    80005dc0:	078e                	slli	a5,a5,0x3
    80005dc2:	94be                	add	s1,s1,a5
    80005dc4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dc8:	fd043503          	ld	a0,-48(s0)
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	a04080e7          	jalr	-1532(ra) # 800047d0 <fileclose>
    fileclose(wf);
    80005dd4:	fc843503          	ld	a0,-56(s0)
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	9f8080e7          	jalr	-1544(ra) # 800047d0 <fileclose>
    return -1;
    80005de0:	57fd                	li	a5,-1
    80005de2:	a03d                	j	80005e10 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005de4:	fc442783          	lw	a5,-60(s0)
    80005de8:	0007c763          	bltz	a5,80005df6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005dec:	07e9                	addi	a5,a5,26
    80005dee:	078e                	slli	a5,a5,0x3
    80005df0:	97a6                	add	a5,a5,s1
    80005df2:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005df6:	fd043503          	ld	a0,-48(s0)
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	9d6080e7          	jalr	-1578(ra) # 800047d0 <fileclose>
    fileclose(wf);
    80005e02:	fc843503          	ld	a0,-56(s0)
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	9ca080e7          	jalr	-1590(ra) # 800047d0 <fileclose>
    return -1;
    80005e0e:	57fd                	li	a5,-1
}
    80005e10:	853e                	mv	a0,a5
    80005e12:	70e2                	ld	ra,56(sp)
    80005e14:	7442                	ld	s0,48(sp)
    80005e16:	74a2                	ld	s1,40(sp)
    80005e18:	6121                	addi	sp,sp,64
    80005e1a:	8082                	ret
    80005e1c:	0000                	unimp
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	d11fc0ef          	jal	ra,80002b70 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	6d0c                	ld	a1,24(a0)
    80005ebc:	7110                	ld	a2,32(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	b66080e7          	jalr	-1178(ra) # 80001a5e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	97aa                	add	a5,a5,a0
    80005f1c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	b2e080e7          	jalr	-1234(ra) # 80001a5e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5151b          	slliw	a0,a0,0xd
    80005f3c:	0c2017b7          	lui	a5,0xc201
    80005f40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f42:	43c8                	lw	a0,4(a5)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	b06080e7          	jalr	-1274(ra) # 80001a5e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f84:	0001c797          	auipc	a5,0x1c
    80005f88:	dbc78793          	addi	a5,a5,-580 # 80021d40 <disk>
    80005f8c:	97aa                	add	a5,a5,a0
    80005f8e:	0187c783          	lbu	a5,24(a5)
    80005f92:	ebb9                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f94:	00451693          	slli	a3,a0,0x4
    80005f98:	0001c797          	auipc	a5,0x1c
    80005f9c:	da878793          	addi	a5,a5,-600 # 80021d40 <disk>
    80005fa0:	6398                	ld	a4,0(a5)
    80005fa2:	9736                	add	a4,a4,a3
    80005fa4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005fa8:	6398                	ld	a4,0(a5)
    80005faa:	9736                	add	a4,a4,a3
    80005fac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fb0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fb4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	4705                	li	a4,1
    80005fbc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005fc0:	0001c517          	auipc	a0,0x1c
    80005fc4:	d9850513          	addi	a0,a0,-616 # 80021d58 <disk+0x18>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	28e080e7          	jalr	654(ra) # 80002256 <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("free_desc 1");
    80005fd8:	00003517          	auipc	a0,0x3
    80005fdc:	85050513          	addi	a0,a0,-1968 # 80008828 <syscalls+0x308>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005fe8:	00003517          	auipc	a0,0x3
    80005fec:	85050513          	addi	a0,a0,-1968 # 80008838 <syscalls+0x318>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	e04a                	sd	s2,0(sp)
    80006002:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006004:	00003597          	auipc	a1,0x3
    80006008:	84458593          	addi	a1,a1,-1980 # 80008848 <syscalls+0x328>
    8000600c:	0001c517          	auipc	a0,0x1c
    80006010:	e5c50513          	addi	a0,a0,-420 # 80021e68 <disk+0x128>
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	b32080e7          	jalr	-1230(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601c:	100017b7          	lui	a5,0x10001
    80006020:	4398                	lw	a4,0(a5)
    80006022:	2701                	sext.w	a4,a4
    80006024:	747277b7          	lui	a5,0x74727
    80006028:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602c:	14f71b63          	bne	a4,a5,80006182 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006030:	100017b7          	lui	a5,0x10001
    80006034:	43dc                	lw	a5,4(a5)
    80006036:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006038:	4709                	li	a4,2
    8000603a:	14e79463          	bne	a5,a4,80006182 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603e:	100017b7          	lui	a5,0x10001
    80006042:	479c                	lw	a5,8(a5)
    80006044:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006046:	12e79e63          	bne	a5,a4,80006182 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	12f71463          	bne	a4,a5,80006182 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	4705                	li	a4,1
    80006068:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000606a:	470d                	li	a4,3
    8000606c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006070:	c7ffe6b7          	lui	a3,0xc7ffe
    80006074:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc8df>
    80006078:	8f75                	and	a4,a4,a3
    8000607a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607c:	472d                	li	a4,11
    8000607e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006080:	5bbc                	lw	a5,112(a5)
    80006082:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006086:	8ba1                	andi	a5,a5,8
    80006088:	10078563          	beqz	a5,80006192 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006094:	43fc                	lw	a5,68(a5)
    80006096:	2781                	sext.w	a5,a5
    80006098:	10079563          	bnez	a5,800061a2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000609c:	100017b7          	lui	a5,0x10001
    800060a0:	5bdc                	lw	a5,52(a5)
    800060a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800060a4:	10078763          	beqz	a5,800061b2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800060a8:	471d                	li	a4,7
    800060aa:	10f77c63          	bgeu	a4,a5,800061c2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800060ae:	ffffb097          	auipc	ra,0xffffb
    800060b2:	a38080e7          	jalr	-1480(ra) # 80000ae6 <kalloc>
    800060b6:	0001c497          	auipc	s1,0x1c
    800060ba:	c8a48493          	addi	s1,s1,-886 # 80021d40 <disk>
    800060be:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	a26080e7          	jalr	-1498(ra) # 80000ae6 <kalloc>
    800060c8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ca:	ffffb097          	auipc	ra,0xffffb
    800060ce:	a1c080e7          	jalr	-1508(ra) # 80000ae6 <kalloc>
    800060d2:	87aa                	mv	a5,a0
    800060d4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060d6:	6088                	ld	a0,0(s1)
    800060d8:	cd6d                	beqz	a0,800061d2 <virtio_disk_init+0x1da>
    800060da:	0001c717          	auipc	a4,0x1c
    800060de:	c6e73703          	ld	a4,-914(a4) # 80021d48 <disk+0x8>
    800060e2:	cb65                	beqz	a4,800061d2 <virtio_disk_init+0x1da>
    800060e4:	c7fd                	beqz	a5,800061d2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800060e6:	6605                	lui	a2,0x1
    800060e8:	4581                	li	a1,0
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	be8080e7          	jalr	-1048(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060f2:	0001c497          	auipc	s1,0x1c
    800060f6:	c4e48493          	addi	s1,s1,-946 # 80021d40 <disk>
    800060fa:	6605                	lui	a2,0x1
    800060fc:	4581                	li	a1,0
    800060fe:	6488                	ld	a0,8(s1)
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	bd2080e7          	jalr	-1070(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006108:	6605                	lui	a2,0x1
    8000610a:	4581                	li	a1,0
    8000610c:	6888                	ld	a0,16(s1)
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	bc4080e7          	jalr	-1084(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006116:	100017b7          	lui	a5,0x10001
    8000611a:	4721                	li	a4,8
    8000611c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000611e:	4098                	lw	a4,0(s1)
    80006120:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006124:	40d8                	lw	a4,4(s1)
    80006126:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000612a:	6498                	ld	a4,8(s1)
    8000612c:	0007069b          	sext.w	a3,a4
    80006130:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006134:	9701                	srai	a4,a4,0x20
    80006136:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000613a:	6898                	ld	a4,16(s1)
    8000613c:	0007069b          	sext.w	a3,a4
    80006140:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006144:	9701                	srai	a4,a4,0x20
    80006146:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000614a:	4705                	li	a4,1
    8000614c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000614e:	00e48c23          	sb	a4,24(s1)
    80006152:	00e48ca3          	sb	a4,25(s1)
    80006156:	00e48d23          	sb	a4,26(s1)
    8000615a:	00e48da3          	sb	a4,27(s1)
    8000615e:	00e48e23          	sb	a4,28(s1)
    80006162:	00e48ea3          	sb	a4,29(s1)
    80006166:	00e48f23          	sb	a4,30(s1)
    8000616a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000616e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006172:	0727a823          	sw	s2,112(a5)
}
    80006176:	60e2                	ld	ra,24(sp)
    80006178:	6442                	ld	s0,16(sp)
    8000617a:	64a2                	ld	s1,8(sp)
    8000617c:	6902                	ld	s2,0(sp)
    8000617e:	6105                	addi	sp,sp,32
    80006180:	8082                	ret
    panic("could not find virtio disk");
    80006182:	00002517          	auipc	a0,0x2
    80006186:	6d650513          	addi	a0,a0,1750 # 80008858 <syscalls+0x338>
    8000618a:	ffffa097          	auipc	ra,0xffffa
    8000618e:	3b6080e7          	jalr	950(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	6e650513          	addi	a0,a0,1766 # 80008878 <syscalls+0x358>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3a6080e7          	jalr	934(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	6f650513          	addi	a0,a0,1782 # 80008898 <syscalls+0x378>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	396080e7          	jalr	918(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	70650513          	addi	a0,a0,1798 # 800088b8 <syscalls+0x398>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	386080e7          	jalr	902(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800061c2:	00002517          	auipc	a0,0x2
    800061c6:	71650513          	addi	a0,a0,1814 # 800088d8 <syscalls+0x3b8>
    800061ca:	ffffa097          	auipc	ra,0xffffa
    800061ce:	376080e7          	jalr	886(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800061d2:	00002517          	auipc	a0,0x2
    800061d6:	72650513          	addi	a0,a0,1830 # 800088f8 <syscalls+0x3d8>
    800061da:	ffffa097          	auipc	ra,0xffffa
    800061de:	366080e7          	jalr	870(ra) # 80000540 <panic>

00000000800061e2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061e2:	7119                	addi	sp,sp,-128
    800061e4:	fc86                	sd	ra,120(sp)
    800061e6:	f8a2                	sd	s0,112(sp)
    800061e8:	f4a6                	sd	s1,104(sp)
    800061ea:	f0ca                	sd	s2,96(sp)
    800061ec:	ecce                	sd	s3,88(sp)
    800061ee:	e8d2                	sd	s4,80(sp)
    800061f0:	e4d6                	sd	s5,72(sp)
    800061f2:	e0da                	sd	s6,64(sp)
    800061f4:	fc5e                	sd	s7,56(sp)
    800061f6:	f862                	sd	s8,48(sp)
    800061f8:	f466                	sd	s9,40(sp)
    800061fa:	f06a                	sd	s10,32(sp)
    800061fc:	ec6e                	sd	s11,24(sp)
    800061fe:	0100                	addi	s0,sp,128
    80006200:	8aaa                	mv	s5,a0
    80006202:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006204:	00c52d03          	lw	s10,12(a0)
    80006208:	001d1d1b          	slliw	s10,s10,0x1
    8000620c:	1d02                	slli	s10,s10,0x20
    8000620e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006212:	0001c517          	auipc	a0,0x1c
    80006216:	c5650513          	addi	a0,a0,-938 # 80021e68 <disk+0x128>
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	9bc080e7          	jalr	-1604(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006222:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006224:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006226:	0001cb97          	auipc	s7,0x1c
    8000622a:	b1ab8b93          	addi	s7,s7,-1254 # 80021d40 <disk>
  for(int i = 0; i < 3; i++){
    8000622e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006230:	0001cc97          	auipc	s9,0x1c
    80006234:	c38c8c93          	addi	s9,s9,-968 # 80021e68 <disk+0x128>
    80006238:	a08d                	j	8000629a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000623a:	00fb8733          	add	a4,s7,a5
    8000623e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006242:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006244:	0207c563          	bltz	a5,8000626e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006248:	2905                	addiw	s2,s2,1
    8000624a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000624c:	05690c63          	beq	s2,s6,800062a4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006250:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006252:	0001c717          	auipc	a4,0x1c
    80006256:	aee70713          	addi	a4,a4,-1298 # 80021d40 <disk>
    8000625a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000625c:	01874683          	lbu	a3,24(a4)
    80006260:	fee9                	bnez	a3,8000623a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006262:	2785                	addiw	a5,a5,1
    80006264:	0705                	addi	a4,a4,1
    80006266:	fe979be3          	bne	a5,s1,8000625c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000626a:	57fd                	li	a5,-1
    8000626c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000626e:	01205d63          	blez	s2,80006288 <virtio_disk_rw+0xa6>
    80006272:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006274:	000a2503          	lw	a0,0(s4)
    80006278:	00000097          	auipc	ra,0x0
    8000627c:	cfe080e7          	jalr	-770(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006280:	2d85                	addiw	s11,s11,1
    80006282:	0a11                	addi	s4,s4,4
    80006284:	ff2d98e3          	bne	s11,s2,80006274 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006288:	85e6                	mv	a1,s9
    8000628a:	0001c517          	auipc	a0,0x1c
    8000628e:	ace50513          	addi	a0,a0,-1330 # 80021d58 <disk+0x18>
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	f60080e7          	jalr	-160(ra) # 800021f2 <sleep>
  for(int i = 0; i < 3; i++){
    8000629a:	f8040a13          	addi	s4,s0,-128
{
    8000629e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062a0:	894e                	mv	s2,s3
    800062a2:	b77d                	j	80006250 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062a4:	f8042503          	lw	a0,-128(s0)
    800062a8:	00a50713          	addi	a4,a0,10
    800062ac:	0712                	slli	a4,a4,0x4

  if(write)
    800062ae:	0001c797          	auipc	a5,0x1c
    800062b2:	a9278793          	addi	a5,a5,-1390 # 80021d40 <disk>
    800062b6:	00e786b3          	add	a3,a5,a4
    800062ba:	01803633          	snez	a2,s8
    800062be:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062c0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800062c4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c8:	f6070613          	addi	a2,a4,-160
    800062cc:	6394                	ld	a3,0(a5)
    800062ce:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062d0:	00870593          	addi	a1,a4,8
    800062d4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062d6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062d8:	0007b803          	ld	a6,0(a5)
    800062dc:	9642                	add	a2,a2,a6
    800062de:	46c1                	li	a3,16
    800062e0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062e2:	4585                	li	a1,1
    800062e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062e8:	f8442683          	lw	a3,-124(s0)
    800062ec:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062f0:	0692                	slli	a3,a3,0x4
    800062f2:	9836                	add	a6,a6,a3
    800062f4:	058a8613          	addi	a2,s5,88
    800062f8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062fc:	0007b803          	ld	a6,0(a5)
    80006300:	96c2                	add	a3,a3,a6
    80006302:	40000613          	li	a2,1024
    80006306:	c690                	sw	a2,8(a3)
  if(write)
    80006308:	001c3613          	seqz	a2,s8
    8000630c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006310:	00166613          	ori	a2,a2,1
    80006314:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006318:	f8842603          	lw	a2,-120(s0)
    8000631c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006320:	00250693          	addi	a3,a0,2
    80006324:	0692                	slli	a3,a3,0x4
    80006326:	96be                	add	a3,a3,a5
    80006328:	58fd                	li	a7,-1
    8000632a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000632e:	0612                	slli	a2,a2,0x4
    80006330:	9832                	add	a6,a6,a2
    80006332:	f9070713          	addi	a4,a4,-112
    80006336:	973e                	add	a4,a4,a5
    80006338:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000633c:	6398                	ld	a4,0(a5)
    8000633e:	9732                	add	a4,a4,a2
    80006340:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006342:	4609                	li	a2,2
    80006344:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006348:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000634c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006350:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006354:	6794                	ld	a3,8(a5)
    80006356:	0026d703          	lhu	a4,2(a3)
    8000635a:	8b1d                	andi	a4,a4,7
    8000635c:	0706                	slli	a4,a4,0x1
    8000635e:	96ba                	add	a3,a3,a4
    80006360:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006364:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006368:	6798                	ld	a4,8(a5)
    8000636a:	00275783          	lhu	a5,2(a4)
    8000636e:	2785                	addiw	a5,a5,1
    80006370:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006374:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006378:	100017b7          	lui	a5,0x10001
    8000637c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006380:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006384:	0001c917          	auipc	s2,0x1c
    80006388:	ae490913          	addi	s2,s2,-1308 # 80021e68 <disk+0x128>
  while(b->disk == 1) {
    8000638c:	4485                	li	s1,1
    8000638e:	00b79c63          	bne	a5,a1,800063a6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006392:	85ca                	mv	a1,s2
    80006394:	8556                	mv	a0,s5
    80006396:	ffffc097          	auipc	ra,0xffffc
    8000639a:	e5c080e7          	jalr	-420(ra) # 800021f2 <sleep>
  while(b->disk == 1) {
    8000639e:	004aa783          	lw	a5,4(s5)
    800063a2:	fe9788e3          	beq	a5,s1,80006392 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800063a6:	f8042903          	lw	s2,-128(s0)
    800063aa:	00290713          	addi	a4,s2,2
    800063ae:	0712                	slli	a4,a4,0x4
    800063b0:	0001c797          	auipc	a5,0x1c
    800063b4:	99078793          	addi	a5,a5,-1648 # 80021d40 <disk>
    800063b8:	97ba                	add	a5,a5,a4
    800063ba:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063be:	0001c997          	auipc	s3,0x1c
    800063c2:	98298993          	addi	s3,s3,-1662 # 80021d40 <disk>
    800063c6:	00491713          	slli	a4,s2,0x4
    800063ca:	0009b783          	ld	a5,0(s3)
    800063ce:	97ba                	add	a5,a5,a4
    800063d0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063d4:	854a                	mv	a0,s2
    800063d6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063da:	00000097          	auipc	ra,0x0
    800063de:	b9c080e7          	jalr	-1124(ra) # 80005f76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063e2:	8885                	andi	s1,s1,1
    800063e4:	f0ed                	bnez	s1,800063c6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063e6:	0001c517          	auipc	a0,0x1c
    800063ea:	a8250513          	addi	a0,a0,-1406 # 80021e68 <disk+0x128>
    800063ee:	ffffb097          	auipc	ra,0xffffb
    800063f2:	89c080e7          	jalr	-1892(ra) # 80000c8a <release>
}
    800063f6:	70e6                	ld	ra,120(sp)
    800063f8:	7446                	ld	s0,112(sp)
    800063fa:	74a6                	ld	s1,104(sp)
    800063fc:	7906                	ld	s2,96(sp)
    800063fe:	69e6                	ld	s3,88(sp)
    80006400:	6a46                	ld	s4,80(sp)
    80006402:	6aa6                	ld	s5,72(sp)
    80006404:	6b06                	ld	s6,64(sp)
    80006406:	7be2                	ld	s7,56(sp)
    80006408:	7c42                	ld	s8,48(sp)
    8000640a:	7ca2                	ld	s9,40(sp)
    8000640c:	7d02                	ld	s10,32(sp)
    8000640e:	6de2                	ld	s11,24(sp)
    80006410:	6109                	addi	sp,sp,128
    80006412:	8082                	ret

0000000080006414 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006414:	1101                	addi	sp,sp,-32
    80006416:	ec06                	sd	ra,24(sp)
    80006418:	e822                	sd	s0,16(sp)
    8000641a:	e426                	sd	s1,8(sp)
    8000641c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000641e:	0001c497          	auipc	s1,0x1c
    80006422:	92248493          	addi	s1,s1,-1758 # 80021d40 <disk>
    80006426:	0001c517          	auipc	a0,0x1c
    8000642a:	a4250513          	addi	a0,a0,-1470 # 80021e68 <disk+0x128>
    8000642e:	ffffa097          	auipc	ra,0xffffa
    80006432:	7a8080e7          	jalr	1960(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006436:	10001737          	lui	a4,0x10001
    8000643a:	533c                	lw	a5,96(a4)
    8000643c:	8b8d                	andi	a5,a5,3
    8000643e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006440:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006444:	689c                	ld	a5,16(s1)
    80006446:	0204d703          	lhu	a4,32(s1)
    8000644a:	0027d783          	lhu	a5,2(a5)
    8000644e:	04f70863          	beq	a4,a5,8000649e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006452:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006456:	6898                	ld	a4,16(s1)
    80006458:	0204d783          	lhu	a5,32(s1)
    8000645c:	8b9d                	andi	a5,a5,7
    8000645e:	078e                	slli	a5,a5,0x3
    80006460:	97ba                	add	a5,a5,a4
    80006462:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006464:	00278713          	addi	a4,a5,2
    80006468:	0712                	slli	a4,a4,0x4
    8000646a:	9726                	add	a4,a4,s1
    8000646c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006470:	e721                	bnez	a4,800064b8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006472:	0789                	addi	a5,a5,2
    80006474:	0792                	slli	a5,a5,0x4
    80006476:	97a6                	add	a5,a5,s1
    80006478:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000647a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000647e:	ffffc097          	auipc	ra,0xffffc
    80006482:	dd8080e7          	jalr	-552(ra) # 80002256 <wakeup>

    disk.used_idx += 1;
    80006486:	0204d783          	lhu	a5,32(s1)
    8000648a:	2785                	addiw	a5,a5,1
    8000648c:	17c2                	slli	a5,a5,0x30
    8000648e:	93c1                	srli	a5,a5,0x30
    80006490:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006494:	6898                	ld	a4,16(s1)
    80006496:	00275703          	lhu	a4,2(a4)
    8000649a:	faf71ce3          	bne	a4,a5,80006452 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000649e:	0001c517          	auipc	a0,0x1c
    800064a2:	9ca50513          	addi	a0,a0,-1590 # 80021e68 <disk+0x128>
    800064a6:	ffffa097          	auipc	ra,0xffffa
    800064aa:	7e4080e7          	jalr	2020(ra) # 80000c8a <release>
}
    800064ae:	60e2                	ld	ra,24(sp)
    800064b0:	6442                	ld	s0,16(sp)
    800064b2:	64a2                	ld	s1,8(sp)
    800064b4:	6105                	addi	sp,sp,32
    800064b6:	8082                	ret
      panic("virtio_disk_intr status");
    800064b8:	00002517          	auipc	a0,0x2
    800064bc:	45850513          	addi	a0,a0,1112 # 80008910 <syscalls+0x3f0>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	080080e7          	jalr	128(ra) # 80000540 <panic>
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
