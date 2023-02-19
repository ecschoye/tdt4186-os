
user/_congen:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <print>:
#include "user/user.h"

#define N 5

void print(const char *s)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
   a:	84aa                	mv	s1,a0
    write(1, s, strlen(s));
   c:	00000097          	auipc	ra,0x0
  10:	13c080e7          	jalr	316(ra) # 148 <strlen>
  14:	0005061b          	sext.w	a2,a0
  18:	85a6                	mv	a1,s1
  1a:	4505                	li	a0,1
  1c:	00000097          	auipc	ra,0x0
  20:	370080e7          	jalr	880(ra) # 38c <write>
}
  24:	60e2                	ld	ra,24(sp)
  26:	6442                	ld	s0,16(sp)
  28:	64a2                	ld	s1,8(sp)
  2a:	6105                	addi	sp,sp,32
  2c:	8082                	ret

000000000000002e <forktest>:

void forktest(void)
{
  2e:	7139                	addi	sp,sp,-64
  30:	fc06                	sd	ra,56(sp)
  32:	f822                	sd	s0,48(sp)
  34:	f426                	sd	s1,40(sp)
  36:	f04a                	sd	s2,32(sp)
  38:	ec4e                	sd	s3,24(sp)
  3a:	e852                	sd	s4,16(sp)
  3c:	e456                	sd	s5,8(sp)
  3e:	e05a                	sd	s6,0(sp)
  40:	0080                	addi	s0,sp,64
    int n, pid;

    print("fork test\n");
  42:	00001517          	auipc	a0,0x1
  46:	85e50513          	addi	a0,a0,-1954 # 8a0 <malloc+0xea>
  4a:	00000097          	auipc	ra,0x0
  4e:	fb6080e7          	jalr	-74(ra) # 0 <print>

    for (n = 0; n < N; n++)
  52:	4a01                	li	s4,0
  54:	4495                	li	s1,5
    {
        pid = fork();
  56:	00000097          	auipc	ra,0x0
  5a:	30e080e7          	jalr	782(ra) # 364 <fork>
  5e:	892a                	mv	s2,a0
        if (pid < 0)
            break;
        if (pid == 0)
  60:	00a05563          	blez	a0,6a <forktest+0x3c>
    for (n = 0; n < N; n++)
  64:	2a05                	addiw	s4,s4,1
  66:	fe9a18e3          	bne	s4,s1,56 <forktest+0x28>
            break;
    }

    for (unsigned long long i = 0; i < 100; i++)
  6a:	4481                	li	s1,0
        {
            printf("CHILD %d: %d\n", n, i);
        }
        else
        {
            printf("PARENT: %d\n", i);
  6c:	00001b17          	auipc	s6,0x1
  70:	854b0b13          	addi	s6,s6,-1964 # 8c0 <malloc+0x10a>
            printf("CHILD %d: %d\n", n, i);
  74:	00001a97          	auipc	s5,0x1
  78:	83ca8a93          	addi	s5,s5,-1988 # 8b0 <malloc+0xfa>
    for (unsigned long long i = 0; i < 100; i++)
  7c:	06400993          	li	s3,100
  80:	a811                	j	94 <forktest+0x66>
            printf("PARENT: %d\n", i);
  82:	85a6                	mv	a1,s1
  84:	855a                	mv	a0,s6
  86:	00000097          	auipc	ra,0x0
  8a:	678080e7          	jalr	1656(ra) # 6fe <printf>
    for (unsigned long long i = 0; i < 100; i++)
  8e:	0485                	addi	s1,s1,1
  90:	01348c63          	beq	s1,s3,a8 <forktest+0x7a>
        if (pid == 0)
  94:	fe0917e3          	bnez	s2,82 <forktest+0x54>
            printf("CHILD %d: %d\n", n, i);
  98:	8626                	mv	a2,s1
  9a:	85d2                	mv	a1,s4
  9c:	8556                	mv	a0,s5
  9e:	00000097          	auipc	ra,0x0
  a2:	660080e7          	jalr	1632(ra) # 6fe <printf>
  a6:	b7e5                	j	8e <forktest+0x60>
        }
    }

    print("fork test OK\n");
  a8:	00001517          	auipc	a0,0x1
  ac:	82850513          	addi	a0,a0,-2008 # 8d0 <malloc+0x11a>
  b0:	00000097          	auipc	ra,0x0
  b4:	f50080e7          	jalr	-176(ra) # 0 <print>
}
  b8:	70e2                	ld	ra,56(sp)
  ba:	7442                	ld	s0,48(sp)
  bc:	74a2                	ld	s1,40(sp)
  be:	7902                	ld	s2,32(sp)
  c0:	69e2                	ld	s3,24(sp)
  c2:	6a42                	ld	s4,16(sp)
  c4:	6aa2                	ld	s5,8(sp)
  c6:	6b02                	ld	s6,0(sp)
  c8:	6121                	addi	sp,sp,64
  ca:	8082                	ret

00000000000000cc <main>:

int main(void)
{
  cc:	1141                	addi	sp,sp,-16
  ce:	e406                	sd	ra,8(sp)
  d0:	e022                	sd	s0,0(sp)
  d2:	0800                	addi	s0,sp,16
    forktest();
  d4:	00000097          	auipc	ra,0x0
  d8:	f5a080e7          	jalr	-166(ra) # 2e <forktest>
    exit(0);
  dc:	4501                	li	a0,0
  de:	00000097          	auipc	ra,0x0
  e2:	28e080e7          	jalr	654(ra) # 36c <exit>

00000000000000e6 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  e6:	1141                	addi	sp,sp,-16
  e8:	e406                	sd	ra,8(sp)
  ea:	e022                	sd	s0,0(sp)
  ec:	0800                	addi	s0,sp,16
  extern int main();
  main();
  ee:	00000097          	auipc	ra,0x0
  f2:	fde080e7          	jalr	-34(ra) # cc <main>
  exit(0);
  f6:	4501                	li	a0,0
  f8:	00000097          	auipc	ra,0x0
  fc:	274080e7          	jalr	628(ra) # 36c <exit>

0000000000000100 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 100:	1141                	addi	sp,sp,-16
 102:	e422                	sd	s0,8(sp)
 104:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 106:	87aa                	mv	a5,a0
 108:	0585                	addi	a1,a1,1
 10a:	0785                	addi	a5,a5,1
 10c:	fff5c703          	lbu	a4,-1(a1)
 110:	fee78fa3          	sb	a4,-1(a5)
 114:	fb75                	bnez	a4,108 <strcpy+0x8>
    ;
  return os;
}
 116:	6422                	ld	s0,8(sp)
 118:	0141                	addi	sp,sp,16
 11a:	8082                	ret

000000000000011c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 11c:	1141                	addi	sp,sp,-16
 11e:	e422                	sd	s0,8(sp)
 120:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 122:	00054783          	lbu	a5,0(a0)
 126:	cb91                	beqz	a5,13a <strcmp+0x1e>
 128:	0005c703          	lbu	a4,0(a1)
 12c:	00f71763          	bne	a4,a5,13a <strcmp+0x1e>
    p++, q++;
 130:	0505                	addi	a0,a0,1
 132:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 134:	00054783          	lbu	a5,0(a0)
 138:	fbe5                	bnez	a5,128 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 13a:	0005c503          	lbu	a0,0(a1)
}
 13e:	40a7853b          	subw	a0,a5,a0
 142:	6422                	ld	s0,8(sp)
 144:	0141                	addi	sp,sp,16
 146:	8082                	ret

0000000000000148 <strlen>:

uint
strlen(const char *s)
{
 148:	1141                	addi	sp,sp,-16
 14a:	e422                	sd	s0,8(sp)
 14c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 14e:	00054783          	lbu	a5,0(a0)
 152:	cf91                	beqz	a5,16e <strlen+0x26>
 154:	0505                	addi	a0,a0,1
 156:	87aa                	mv	a5,a0
 158:	4685                	li	a3,1
 15a:	9e89                	subw	a3,a3,a0
 15c:	00f6853b          	addw	a0,a3,a5
 160:	0785                	addi	a5,a5,1
 162:	fff7c703          	lbu	a4,-1(a5)
 166:	fb7d                	bnez	a4,15c <strlen+0x14>
    ;
  return n;
}
 168:	6422                	ld	s0,8(sp)
 16a:	0141                	addi	sp,sp,16
 16c:	8082                	ret
  for(n = 0; s[n]; n++)
 16e:	4501                	li	a0,0
 170:	bfe5                	j	168 <strlen+0x20>

0000000000000172 <memset>:

void*
memset(void *dst, int c, uint n)
{
 172:	1141                	addi	sp,sp,-16
 174:	e422                	sd	s0,8(sp)
 176:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 178:	ca19                	beqz	a2,18e <memset+0x1c>
 17a:	87aa                	mv	a5,a0
 17c:	1602                	slli	a2,a2,0x20
 17e:	9201                	srli	a2,a2,0x20
 180:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 184:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 188:	0785                	addi	a5,a5,1
 18a:	fee79de3          	bne	a5,a4,184 <memset+0x12>
  }
  return dst;
}
 18e:	6422                	ld	s0,8(sp)
 190:	0141                	addi	sp,sp,16
 192:	8082                	ret

0000000000000194 <strchr>:

char*
strchr(const char *s, char c)
{
 194:	1141                	addi	sp,sp,-16
 196:	e422                	sd	s0,8(sp)
 198:	0800                	addi	s0,sp,16
  for(; *s; s++)
 19a:	00054783          	lbu	a5,0(a0)
 19e:	cb99                	beqz	a5,1b4 <strchr+0x20>
    if(*s == c)
 1a0:	00f58763          	beq	a1,a5,1ae <strchr+0x1a>
  for(; *s; s++)
 1a4:	0505                	addi	a0,a0,1
 1a6:	00054783          	lbu	a5,0(a0)
 1aa:	fbfd                	bnez	a5,1a0 <strchr+0xc>
      return (char*)s;
  return 0;
 1ac:	4501                	li	a0,0
}
 1ae:	6422                	ld	s0,8(sp)
 1b0:	0141                	addi	sp,sp,16
 1b2:	8082                	ret
  return 0;
 1b4:	4501                	li	a0,0
 1b6:	bfe5                	j	1ae <strchr+0x1a>

00000000000001b8 <gets>:

char*
gets(char *buf, int max)
{
 1b8:	711d                	addi	sp,sp,-96
 1ba:	ec86                	sd	ra,88(sp)
 1bc:	e8a2                	sd	s0,80(sp)
 1be:	e4a6                	sd	s1,72(sp)
 1c0:	e0ca                	sd	s2,64(sp)
 1c2:	fc4e                	sd	s3,56(sp)
 1c4:	f852                	sd	s4,48(sp)
 1c6:	f456                	sd	s5,40(sp)
 1c8:	f05a                	sd	s6,32(sp)
 1ca:	ec5e                	sd	s7,24(sp)
 1cc:	1080                	addi	s0,sp,96
 1ce:	8baa                	mv	s7,a0
 1d0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1d2:	892a                	mv	s2,a0
 1d4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1d6:	4aa9                	li	s5,10
 1d8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1da:	89a6                	mv	s3,s1
 1dc:	2485                	addiw	s1,s1,1
 1de:	0344d863          	bge	s1,s4,20e <gets+0x56>
    cc = read(0, &c, 1);
 1e2:	4605                	li	a2,1
 1e4:	faf40593          	addi	a1,s0,-81
 1e8:	4501                	li	a0,0
 1ea:	00000097          	auipc	ra,0x0
 1ee:	19a080e7          	jalr	410(ra) # 384 <read>
    if(cc < 1)
 1f2:	00a05e63          	blez	a0,20e <gets+0x56>
    buf[i++] = c;
 1f6:	faf44783          	lbu	a5,-81(s0)
 1fa:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1fe:	01578763          	beq	a5,s5,20c <gets+0x54>
 202:	0905                	addi	s2,s2,1
 204:	fd679be3          	bne	a5,s6,1da <gets+0x22>
  for(i=0; i+1 < max; ){
 208:	89a6                	mv	s3,s1
 20a:	a011                	j	20e <gets+0x56>
 20c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 20e:	99de                	add	s3,s3,s7
 210:	00098023          	sb	zero,0(s3)
  return buf;
}
 214:	855e                	mv	a0,s7
 216:	60e6                	ld	ra,88(sp)
 218:	6446                	ld	s0,80(sp)
 21a:	64a6                	ld	s1,72(sp)
 21c:	6906                	ld	s2,64(sp)
 21e:	79e2                	ld	s3,56(sp)
 220:	7a42                	ld	s4,48(sp)
 222:	7aa2                	ld	s5,40(sp)
 224:	7b02                	ld	s6,32(sp)
 226:	6be2                	ld	s7,24(sp)
 228:	6125                	addi	sp,sp,96
 22a:	8082                	ret

000000000000022c <stat>:

int
stat(const char *n, struct stat *st)
{
 22c:	1101                	addi	sp,sp,-32
 22e:	ec06                	sd	ra,24(sp)
 230:	e822                	sd	s0,16(sp)
 232:	e426                	sd	s1,8(sp)
 234:	e04a                	sd	s2,0(sp)
 236:	1000                	addi	s0,sp,32
 238:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 23a:	4581                	li	a1,0
 23c:	00000097          	auipc	ra,0x0
 240:	170080e7          	jalr	368(ra) # 3ac <open>
  if(fd < 0)
 244:	02054563          	bltz	a0,26e <stat+0x42>
 248:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 24a:	85ca                	mv	a1,s2
 24c:	00000097          	auipc	ra,0x0
 250:	178080e7          	jalr	376(ra) # 3c4 <fstat>
 254:	892a                	mv	s2,a0
  close(fd);
 256:	8526                	mv	a0,s1
 258:	00000097          	auipc	ra,0x0
 25c:	13c080e7          	jalr	316(ra) # 394 <close>
  return r;
}
 260:	854a                	mv	a0,s2
 262:	60e2                	ld	ra,24(sp)
 264:	6442                	ld	s0,16(sp)
 266:	64a2                	ld	s1,8(sp)
 268:	6902                	ld	s2,0(sp)
 26a:	6105                	addi	sp,sp,32
 26c:	8082                	ret
    return -1;
 26e:	597d                	li	s2,-1
 270:	bfc5                	j	260 <stat+0x34>

0000000000000272 <atoi>:

int
atoi(const char *s)
{
 272:	1141                	addi	sp,sp,-16
 274:	e422                	sd	s0,8(sp)
 276:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 278:	00054683          	lbu	a3,0(a0)
 27c:	fd06879b          	addiw	a5,a3,-48
 280:	0ff7f793          	zext.b	a5,a5
 284:	4625                	li	a2,9
 286:	02f66863          	bltu	a2,a5,2b6 <atoi+0x44>
 28a:	872a                	mv	a4,a0
  n = 0;
 28c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 28e:	0705                	addi	a4,a4,1
 290:	0025179b          	slliw	a5,a0,0x2
 294:	9fa9                	addw	a5,a5,a0
 296:	0017979b          	slliw	a5,a5,0x1
 29a:	9fb5                	addw	a5,a5,a3
 29c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2a0:	00074683          	lbu	a3,0(a4)
 2a4:	fd06879b          	addiw	a5,a3,-48
 2a8:	0ff7f793          	zext.b	a5,a5
 2ac:	fef671e3          	bgeu	a2,a5,28e <atoi+0x1c>
  return n;
}
 2b0:	6422                	ld	s0,8(sp)
 2b2:	0141                	addi	sp,sp,16
 2b4:	8082                	ret
  n = 0;
 2b6:	4501                	li	a0,0
 2b8:	bfe5                	j	2b0 <atoi+0x3e>

00000000000002ba <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ba:	1141                	addi	sp,sp,-16
 2bc:	e422                	sd	s0,8(sp)
 2be:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2c0:	02b57463          	bgeu	a0,a1,2e8 <memmove+0x2e>
    while(n-- > 0)
 2c4:	00c05f63          	blez	a2,2e2 <memmove+0x28>
 2c8:	1602                	slli	a2,a2,0x20
 2ca:	9201                	srli	a2,a2,0x20
 2cc:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2d0:	872a                	mv	a4,a0
      *dst++ = *src++;
 2d2:	0585                	addi	a1,a1,1
 2d4:	0705                	addi	a4,a4,1
 2d6:	fff5c683          	lbu	a3,-1(a1)
 2da:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2de:	fee79ae3          	bne	a5,a4,2d2 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2e2:	6422                	ld	s0,8(sp)
 2e4:	0141                	addi	sp,sp,16
 2e6:	8082                	ret
    dst += n;
 2e8:	00c50733          	add	a4,a0,a2
    src += n;
 2ec:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ee:	fec05ae3          	blez	a2,2e2 <memmove+0x28>
 2f2:	fff6079b          	addiw	a5,a2,-1
 2f6:	1782                	slli	a5,a5,0x20
 2f8:	9381                	srli	a5,a5,0x20
 2fa:	fff7c793          	not	a5,a5
 2fe:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 300:	15fd                	addi	a1,a1,-1
 302:	177d                	addi	a4,a4,-1
 304:	0005c683          	lbu	a3,0(a1)
 308:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 30c:	fee79ae3          	bne	a5,a4,300 <memmove+0x46>
 310:	bfc9                	j	2e2 <memmove+0x28>

0000000000000312 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 312:	1141                	addi	sp,sp,-16
 314:	e422                	sd	s0,8(sp)
 316:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 318:	ca05                	beqz	a2,348 <memcmp+0x36>
 31a:	fff6069b          	addiw	a3,a2,-1
 31e:	1682                	slli	a3,a3,0x20
 320:	9281                	srli	a3,a3,0x20
 322:	0685                	addi	a3,a3,1
 324:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 326:	00054783          	lbu	a5,0(a0)
 32a:	0005c703          	lbu	a4,0(a1)
 32e:	00e79863          	bne	a5,a4,33e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 332:	0505                	addi	a0,a0,1
    p2++;
 334:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 336:	fed518e3          	bne	a0,a3,326 <memcmp+0x14>
  }
  return 0;
 33a:	4501                	li	a0,0
 33c:	a019                	j	342 <memcmp+0x30>
      return *p1 - *p2;
 33e:	40e7853b          	subw	a0,a5,a4
}
 342:	6422                	ld	s0,8(sp)
 344:	0141                	addi	sp,sp,16
 346:	8082                	ret
  return 0;
 348:	4501                	li	a0,0
 34a:	bfe5                	j	342 <memcmp+0x30>

000000000000034c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 34c:	1141                	addi	sp,sp,-16
 34e:	e406                	sd	ra,8(sp)
 350:	e022                	sd	s0,0(sp)
 352:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 354:	00000097          	auipc	ra,0x0
 358:	f66080e7          	jalr	-154(ra) # 2ba <memmove>
}
 35c:	60a2                	ld	ra,8(sp)
 35e:	6402                	ld	s0,0(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret

0000000000000364 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 364:	4885                	li	a7,1
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <exit>:
.global exit
exit:
 li a7, SYS_exit
 36c:	4889                	li	a7,2
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <wait>:
.global wait
wait:
 li a7, SYS_wait
 374:	488d                	li	a7,3
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 37c:	4891                	li	a7,4
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <read>:
.global read
read:
 li a7, SYS_read
 384:	4895                	li	a7,5
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <write>:
.global write
write:
 li a7, SYS_write
 38c:	48c1                	li	a7,16
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <close>:
.global close
close:
 li a7, SYS_close
 394:	48d5                	li	a7,21
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <kill>:
.global kill
kill:
 li a7, SYS_kill
 39c:	4899                	li	a7,6
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3a4:	489d                	li	a7,7
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <open>:
.global open
open:
 li a7, SYS_open
 3ac:	48bd                	li	a7,15
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3b4:	48c5                	li	a7,17
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3bc:	48c9                	li	a7,18
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3c4:	48a1                	li	a7,8
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <link>:
.global link
link:
 li a7, SYS_link
 3cc:	48cd                	li	a7,19
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3d4:	48d1                	li	a7,20
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3dc:	48a5                	li	a7,9
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3e4:	48a9                	li	a7,10
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3ec:	48ad                	li	a7,11
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3f4:	48b1                	li	a7,12
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3fc:	48b5                	li	a7,13
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 404:	48b9                	li	a7,14
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <ps>:
.global ps
ps:
 li a7, SYS_ps
 40c:	48d9                	li	a7,22
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 414:	48dd                	li	a7,23
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 41c:	48e1                	li	a7,24
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 424:	1101                	addi	sp,sp,-32
 426:	ec06                	sd	ra,24(sp)
 428:	e822                	sd	s0,16(sp)
 42a:	1000                	addi	s0,sp,32
 42c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 430:	4605                	li	a2,1
 432:	fef40593          	addi	a1,s0,-17
 436:	00000097          	auipc	ra,0x0
 43a:	f56080e7          	jalr	-170(ra) # 38c <write>
}
 43e:	60e2                	ld	ra,24(sp)
 440:	6442                	ld	s0,16(sp)
 442:	6105                	addi	sp,sp,32
 444:	8082                	ret

0000000000000446 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 446:	7139                	addi	sp,sp,-64
 448:	fc06                	sd	ra,56(sp)
 44a:	f822                	sd	s0,48(sp)
 44c:	f426                	sd	s1,40(sp)
 44e:	f04a                	sd	s2,32(sp)
 450:	ec4e                	sd	s3,24(sp)
 452:	0080                	addi	s0,sp,64
 454:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 456:	c299                	beqz	a3,45c <printint+0x16>
 458:	0805c963          	bltz	a1,4ea <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 45c:	2581                	sext.w	a1,a1
  neg = 0;
 45e:	4881                	li	a7,0
 460:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 464:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 466:	2601                	sext.w	a2,a2
 468:	00000517          	auipc	a0,0x0
 46c:	4d850513          	addi	a0,a0,1240 # 940 <digits>
 470:	883a                	mv	a6,a4
 472:	2705                	addiw	a4,a4,1
 474:	02c5f7bb          	remuw	a5,a1,a2
 478:	1782                	slli	a5,a5,0x20
 47a:	9381                	srli	a5,a5,0x20
 47c:	97aa                	add	a5,a5,a0
 47e:	0007c783          	lbu	a5,0(a5)
 482:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 486:	0005879b          	sext.w	a5,a1
 48a:	02c5d5bb          	divuw	a1,a1,a2
 48e:	0685                	addi	a3,a3,1
 490:	fec7f0e3          	bgeu	a5,a2,470 <printint+0x2a>
  if(neg)
 494:	00088c63          	beqz	a7,4ac <printint+0x66>
    buf[i++] = '-';
 498:	fd070793          	addi	a5,a4,-48
 49c:	00878733          	add	a4,a5,s0
 4a0:	02d00793          	li	a5,45
 4a4:	fef70823          	sb	a5,-16(a4)
 4a8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4ac:	02e05863          	blez	a4,4dc <printint+0x96>
 4b0:	fc040793          	addi	a5,s0,-64
 4b4:	00e78933          	add	s2,a5,a4
 4b8:	fff78993          	addi	s3,a5,-1
 4bc:	99ba                	add	s3,s3,a4
 4be:	377d                	addiw	a4,a4,-1
 4c0:	1702                	slli	a4,a4,0x20
 4c2:	9301                	srli	a4,a4,0x20
 4c4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4c8:	fff94583          	lbu	a1,-1(s2)
 4cc:	8526                	mv	a0,s1
 4ce:	00000097          	auipc	ra,0x0
 4d2:	f56080e7          	jalr	-170(ra) # 424 <putc>
  while(--i >= 0)
 4d6:	197d                	addi	s2,s2,-1
 4d8:	ff3918e3          	bne	s2,s3,4c8 <printint+0x82>
}
 4dc:	70e2                	ld	ra,56(sp)
 4de:	7442                	ld	s0,48(sp)
 4e0:	74a2                	ld	s1,40(sp)
 4e2:	7902                	ld	s2,32(sp)
 4e4:	69e2                	ld	s3,24(sp)
 4e6:	6121                	addi	sp,sp,64
 4e8:	8082                	ret
    x = -xx;
 4ea:	40b005bb          	negw	a1,a1
    neg = 1;
 4ee:	4885                	li	a7,1
    x = -xx;
 4f0:	bf85                	j	460 <printint+0x1a>

00000000000004f2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4f2:	7119                	addi	sp,sp,-128
 4f4:	fc86                	sd	ra,120(sp)
 4f6:	f8a2                	sd	s0,112(sp)
 4f8:	f4a6                	sd	s1,104(sp)
 4fa:	f0ca                	sd	s2,96(sp)
 4fc:	ecce                	sd	s3,88(sp)
 4fe:	e8d2                	sd	s4,80(sp)
 500:	e4d6                	sd	s5,72(sp)
 502:	e0da                	sd	s6,64(sp)
 504:	fc5e                	sd	s7,56(sp)
 506:	f862                	sd	s8,48(sp)
 508:	f466                	sd	s9,40(sp)
 50a:	f06a                	sd	s10,32(sp)
 50c:	ec6e                	sd	s11,24(sp)
 50e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 510:	0005c903          	lbu	s2,0(a1)
 514:	18090f63          	beqz	s2,6b2 <vprintf+0x1c0>
 518:	8aaa                	mv	s5,a0
 51a:	8b32                	mv	s6,a2
 51c:	00158493          	addi	s1,a1,1
  state = 0;
 520:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 522:	02500a13          	li	s4,37
 526:	4c55                	li	s8,21
 528:	00000c97          	auipc	s9,0x0
 52c:	3c0c8c93          	addi	s9,s9,960 # 8e8 <malloc+0x132>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 530:	02800d93          	li	s11,40
  putc(fd, 'x');
 534:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 536:	00000b97          	auipc	s7,0x0
 53a:	40ab8b93          	addi	s7,s7,1034 # 940 <digits>
 53e:	a839                	j	55c <vprintf+0x6a>
        putc(fd, c);
 540:	85ca                	mv	a1,s2
 542:	8556                	mv	a0,s5
 544:	00000097          	auipc	ra,0x0
 548:	ee0080e7          	jalr	-288(ra) # 424 <putc>
 54c:	a019                	j	552 <vprintf+0x60>
    } else if(state == '%'){
 54e:	01498d63          	beq	s3,s4,568 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 552:	0485                	addi	s1,s1,1
 554:	fff4c903          	lbu	s2,-1(s1)
 558:	14090d63          	beqz	s2,6b2 <vprintf+0x1c0>
    if(state == 0){
 55c:	fe0999e3          	bnez	s3,54e <vprintf+0x5c>
      if(c == '%'){
 560:	ff4910e3          	bne	s2,s4,540 <vprintf+0x4e>
        state = '%';
 564:	89d2                	mv	s3,s4
 566:	b7f5                	j	552 <vprintf+0x60>
      if(c == 'd'){
 568:	11490c63          	beq	s2,s4,680 <vprintf+0x18e>
 56c:	f9d9079b          	addiw	a5,s2,-99
 570:	0ff7f793          	zext.b	a5,a5
 574:	10fc6e63          	bltu	s8,a5,690 <vprintf+0x19e>
 578:	f9d9079b          	addiw	a5,s2,-99
 57c:	0ff7f713          	zext.b	a4,a5
 580:	10ec6863          	bltu	s8,a4,690 <vprintf+0x19e>
 584:	00271793          	slli	a5,a4,0x2
 588:	97e6                	add	a5,a5,s9
 58a:	439c                	lw	a5,0(a5)
 58c:	97e6                	add	a5,a5,s9
 58e:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 590:	008b0913          	addi	s2,s6,8
 594:	4685                	li	a3,1
 596:	4629                	li	a2,10
 598:	000b2583          	lw	a1,0(s6)
 59c:	8556                	mv	a0,s5
 59e:	00000097          	auipc	ra,0x0
 5a2:	ea8080e7          	jalr	-344(ra) # 446 <printint>
 5a6:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 5a8:	4981                	li	s3,0
 5aa:	b765                	j	552 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5ac:	008b0913          	addi	s2,s6,8
 5b0:	4681                	li	a3,0
 5b2:	4629                	li	a2,10
 5b4:	000b2583          	lw	a1,0(s6)
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	e8c080e7          	jalr	-372(ra) # 446 <printint>
 5c2:	8b4a                	mv	s6,s2
      state = 0;
 5c4:	4981                	li	s3,0
 5c6:	b771                	j	552 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5c8:	008b0913          	addi	s2,s6,8
 5cc:	4681                	li	a3,0
 5ce:	866a                	mv	a2,s10
 5d0:	000b2583          	lw	a1,0(s6)
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	e70080e7          	jalr	-400(ra) # 446 <printint>
 5de:	8b4a                	mv	s6,s2
      state = 0;
 5e0:	4981                	li	s3,0
 5e2:	bf85                	j	552 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5e4:	008b0793          	addi	a5,s6,8
 5e8:	f8f43423          	sd	a5,-120(s0)
 5ec:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5f0:	03000593          	li	a1,48
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	e2e080e7          	jalr	-466(ra) # 424 <putc>
  putc(fd, 'x');
 5fe:	07800593          	li	a1,120
 602:	8556                	mv	a0,s5
 604:	00000097          	auipc	ra,0x0
 608:	e20080e7          	jalr	-480(ra) # 424 <putc>
 60c:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 60e:	03c9d793          	srli	a5,s3,0x3c
 612:	97de                	add	a5,a5,s7
 614:	0007c583          	lbu	a1,0(a5)
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	e0a080e7          	jalr	-502(ra) # 424 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 622:	0992                	slli	s3,s3,0x4
 624:	397d                	addiw	s2,s2,-1
 626:	fe0914e3          	bnez	s2,60e <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 62a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 62e:	4981                	li	s3,0
 630:	b70d                	j	552 <vprintf+0x60>
        s = va_arg(ap, char*);
 632:	008b0913          	addi	s2,s6,8
 636:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 63a:	02098163          	beqz	s3,65c <vprintf+0x16a>
        while(*s != 0){
 63e:	0009c583          	lbu	a1,0(s3)
 642:	c5ad                	beqz	a1,6ac <vprintf+0x1ba>
          putc(fd, *s);
 644:	8556                	mv	a0,s5
 646:	00000097          	auipc	ra,0x0
 64a:	dde080e7          	jalr	-546(ra) # 424 <putc>
          s++;
 64e:	0985                	addi	s3,s3,1
        while(*s != 0){
 650:	0009c583          	lbu	a1,0(s3)
 654:	f9e5                	bnez	a1,644 <vprintf+0x152>
        s = va_arg(ap, char*);
 656:	8b4a                	mv	s6,s2
      state = 0;
 658:	4981                	li	s3,0
 65a:	bde5                	j	552 <vprintf+0x60>
          s = "(null)";
 65c:	00000997          	auipc	s3,0x0
 660:	28498993          	addi	s3,s3,644 # 8e0 <malloc+0x12a>
        while(*s != 0){
 664:	85ee                	mv	a1,s11
 666:	bff9                	j	644 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 668:	008b0913          	addi	s2,s6,8
 66c:	000b4583          	lbu	a1,0(s6)
 670:	8556                	mv	a0,s5
 672:	00000097          	auipc	ra,0x0
 676:	db2080e7          	jalr	-590(ra) # 424 <putc>
 67a:	8b4a                	mv	s6,s2
      state = 0;
 67c:	4981                	li	s3,0
 67e:	bdd1                	j	552 <vprintf+0x60>
        putc(fd, c);
 680:	85d2                	mv	a1,s4
 682:	8556                	mv	a0,s5
 684:	00000097          	auipc	ra,0x0
 688:	da0080e7          	jalr	-608(ra) # 424 <putc>
      state = 0;
 68c:	4981                	li	s3,0
 68e:	b5d1                	j	552 <vprintf+0x60>
        putc(fd, '%');
 690:	85d2                	mv	a1,s4
 692:	8556                	mv	a0,s5
 694:	00000097          	auipc	ra,0x0
 698:	d90080e7          	jalr	-624(ra) # 424 <putc>
        putc(fd, c);
 69c:	85ca                	mv	a1,s2
 69e:	8556                	mv	a0,s5
 6a0:	00000097          	auipc	ra,0x0
 6a4:	d84080e7          	jalr	-636(ra) # 424 <putc>
      state = 0;
 6a8:	4981                	li	s3,0
 6aa:	b565                	j	552 <vprintf+0x60>
        s = va_arg(ap, char*);
 6ac:	8b4a                	mv	s6,s2
      state = 0;
 6ae:	4981                	li	s3,0
 6b0:	b54d                	j	552 <vprintf+0x60>
    }
  }
}
 6b2:	70e6                	ld	ra,120(sp)
 6b4:	7446                	ld	s0,112(sp)
 6b6:	74a6                	ld	s1,104(sp)
 6b8:	7906                	ld	s2,96(sp)
 6ba:	69e6                	ld	s3,88(sp)
 6bc:	6a46                	ld	s4,80(sp)
 6be:	6aa6                	ld	s5,72(sp)
 6c0:	6b06                	ld	s6,64(sp)
 6c2:	7be2                	ld	s7,56(sp)
 6c4:	7c42                	ld	s8,48(sp)
 6c6:	7ca2                	ld	s9,40(sp)
 6c8:	7d02                	ld	s10,32(sp)
 6ca:	6de2                	ld	s11,24(sp)
 6cc:	6109                	addi	sp,sp,128
 6ce:	8082                	ret

00000000000006d0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6d0:	715d                	addi	sp,sp,-80
 6d2:	ec06                	sd	ra,24(sp)
 6d4:	e822                	sd	s0,16(sp)
 6d6:	1000                	addi	s0,sp,32
 6d8:	e010                	sd	a2,0(s0)
 6da:	e414                	sd	a3,8(s0)
 6dc:	e818                	sd	a4,16(s0)
 6de:	ec1c                	sd	a5,24(s0)
 6e0:	03043023          	sd	a6,32(s0)
 6e4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6e8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6ec:	8622                	mv	a2,s0
 6ee:	00000097          	auipc	ra,0x0
 6f2:	e04080e7          	jalr	-508(ra) # 4f2 <vprintf>
}
 6f6:	60e2                	ld	ra,24(sp)
 6f8:	6442                	ld	s0,16(sp)
 6fa:	6161                	addi	sp,sp,80
 6fc:	8082                	ret

00000000000006fe <printf>:

void
printf(const char *fmt, ...)
{
 6fe:	711d                	addi	sp,sp,-96
 700:	ec06                	sd	ra,24(sp)
 702:	e822                	sd	s0,16(sp)
 704:	1000                	addi	s0,sp,32
 706:	e40c                	sd	a1,8(s0)
 708:	e810                	sd	a2,16(s0)
 70a:	ec14                	sd	a3,24(s0)
 70c:	f018                	sd	a4,32(s0)
 70e:	f41c                	sd	a5,40(s0)
 710:	03043823          	sd	a6,48(s0)
 714:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 718:	00840613          	addi	a2,s0,8
 71c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 720:	85aa                	mv	a1,a0
 722:	4505                	li	a0,1
 724:	00000097          	auipc	ra,0x0
 728:	dce080e7          	jalr	-562(ra) # 4f2 <vprintf>
}
 72c:	60e2                	ld	ra,24(sp)
 72e:	6442                	ld	s0,16(sp)
 730:	6125                	addi	sp,sp,96
 732:	8082                	ret

0000000000000734 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 734:	1141                	addi	sp,sp,-16
 736:	e422                	sd	s0,8(sp)
 738:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 73a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 73e:	00001797          	auipc	a5,0x1
 742:	8c27b783          	ld	a5,-1854(a5) # 1000 <freep>
 746:	a02d                	j	770 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 748:	4618                	lw	a4,8(a2)
 74a:	9f2d                	addw	a4,a4,a1
 74c:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 750:	6398                	ld	a4,0(a5)
 752:	6310                	ld	a2,0(a4)
 754:	a83d                	j	792 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 756:	ff852703          	lw	a4,-8(a0)
 75a:	9f31                	addw	a4,a4,a2
 75c:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 75e:	ff053683          	ld	a3,-16(a0)
 762:	a091                	j	7a6 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 764:	6398                	ld	a4,0(a5)
 766:	00e7e463          	bltu	a5,a4,76e <free+0x3a>
 76a:	00e6ea63          	bltu	a3,a4,77e <free+0x4a>
{
 76e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 770:	fed7fae3          	bgeu	a5,a3,764 <free+0x30>
 774:	6398                	ld	a4,0(a5)
 776:	00e6e463          	bltu	a3,a4,77e <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 77a:	fee7eae3          	bltu	a5,a4,76e <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 77e:	ff852583          	lw	a1,-8(a0)
 782:	6390                	ld	a2,0(a5)
 784:	02059813          	slli	a6,a1,0x20
 788:	01c85713          	srli	a4,a6,0x1c
 78c:	9736                	add	a4,a4,a3
 78e:	fae60de3          	beq	a2,a4,748 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 792:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 796:	4790                	lw	a2,8(a5)
 798:	02061593          	slli	a1,a2,0x20
 79c:	01c5d713          	srli	a4,a1,0x1c
 7a0:	973e                	add	a4,a4,a5
 7a2:	fae68ae3          	beq	a3,a4,756 <free+0x22>
    p->s.ptr = bp->s.ptr;
 7a6:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 7a8:	00001717          	auipc	a4,0x1
 7ac:	84f73c23          	sd	a5,-1960(a4) # 1000 <freep>
}
 7b0:	6422                	ld	s0,8(sp)
 7b2:	0141                	addi	sp,sp,16
 7b4:	8082                	ret

00000000000007b6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7b6:	7139                	addi	sp,sp,-64
 7b8:	fc06                	sd	ra,56(sp)
 7ba:	f822                	sd	s0,48(sp)
 7bc:	f426                	sd	s1,40(sp)
 7be:	f04a                	sd	s2,32(sp)
 7c0:	ec4e                	sd	s3,24(sp)
 7c2:	e852                	sd	s4,16(sp)
 7c4:	e456                	sd	s5,8(sp)
 7c6:	e05a                	sd	s6,0(sp)
 7c8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7ca:	02051493          	slli	s1,a0,0x20
 7ce:	9081                	srli	s1,s1,0x20
 7d0:	04bd                	addi	s1,s1,15
 7d2:	8091                	srli	s1,s1,0x4
 7d4:	0014899b          	addiw	s3,s1,1
 7d8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7da:	00001517          	auipc	a0,0x1
 7de:	82653503          	ld	a0,-2010(a0) # 1000 <freep>
 7e2:	c515                	beqz	a0,80e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e6:	4798                	lw	a4,8(a5)
 7e8:	02977f63          	bgeu	a4,s1,826 <malloc+0x70>
 7ec:	8a4e                	mv	s4,s3
 7ee:	0009871b          	sext.w	a4,s3
 7f2:	6685                	lui	a3,0x1
 7f4:	00d77363          	bgeu	a4,a3,7fa <malloc+0x44>
 7f8:	6a05                	lui	s4,0x1
 7fa:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7fe:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 802:	00000917          	auipc	s2,0x0
 806:	7fe90913          	addi	s2,s2,2046 # 1000 <freep>
  if(p == (char*)-1)
 80a:	5afd                	li	s5,-1
 80c:	a895                	j	880 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 80e:	00001797          	auipc	a5,0x1
 812:	80278793          	addi	a5,a5,-2046 # 1010 <base>
 816:	00000717          	auipc	a4,0x0
 81a:	7ef73523          	sd	a5,2026(a4) # 1000 <freep>
 81e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 820:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 824:	b7e1                	j	7ec <malloc+0x36>
      if(p->s.size == nunits)
 826:	02e48c63          	beq	s1,a4,85e <malloc+0xa8>
        p->s.size -= nunits;
 82a:	4137073b          	subw	a4,a4,s3
 82e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 830:	02071693          	slli	a3,a4,0x20
 834:	01c6d713          	srli	a4,a3,0x1c
 838:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 83a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 83e:	00000717          	auipc	a4,0x0
 842:	7ca73123          	sd	a0,1986(a4) # 1000 <freep>
      return (void*)(p + 1);
 846:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 84a:	70e2                	ld	ra,56(sp)
 84c:	7442                	ld	s0,48(sp)
 84e:	74a2                	ld	s1,40(sp)
 850:	7902                	ld	s2,32(sp)
 852:	69e2                	ld	s3,24(sp)
 854:	6a42                	ld	s4,16(sp)
 856:	6aa2                	ld	s5,8(sp)
 858:	6b02                	ld	s6,0(sp)
 85a:	6121                	addi	sp,sp,64
 85c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 85e:	6398                	ld	a4,0(a5)
 860:	e118                	sd	a4,0(a0)
 862:	bff1                	j	83e <malloc+0x88>
  hp->s.size = nu;
 864:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 868:	0541                	addi	a0,a0,16
 86a:	00000097          	auipc	ra,0x0
 86e:	eca080e7          	jalr	-310(ra) # 734 <free>
  return freep;
 872:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 876:	d971                	beqz	a0,84a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 878:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 87a:	4798                	lw	a4,8(a5)
 87c:	fa9775e3          	bgeu	a4,s1,826 <malloc+0x70>
    if(p == freep)
 880:	00093703          	ld	a4,0(s2)
 884:	853e                	mv	a0,a5
 886:	fef719e3          	bne	a4,a5,878 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 88a:	8552                	mv	a0,s4
 88c:	00000097          	auipc	ra,0x0
 890:	b68080e7          	jalr	-1176(ra) # 3f4 <sbrk>
  if(p == (char*)-1)
 894:	fd5518e3          	bne	a0,s5,864 <malloc+0xae>
        return 0;
 898:	4501                	li	a0,0
 89a:	bf45                	j	84a <malloc+0x94>
