/*  
 *  Copyright 2013 buaa.byl@gmail.com
 *
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

//#define DEBUG_FADD
//#define DEBUG_FMUL
//#define DEBUG_FDIV
//#define SELF_TEST

enum ColorsEnum
{
	C_BLACK        = 0,
	C_BLUE         = 1,
	C_DARK_GREEN   = 2,
	C_LIGHT_BLUE   = 3,
	C_RED          = 4,
	C_PURPLE       = 5,
	C_ORANGE       = 6,
	C_GREY         = 7,
	C_DARKER_GREY  = 8,
	C_MEDIUM_BLUE  = 9,
	C_LIGHT_GREEN  = 10,
	C_TEAL         = 11,
	C_RED_ORANGE   = 12,
	C_LIGHT_PURPLE = 13,
	C_YELLOW       = 14,
	C_WHITE        = 15,
};

void set_color(unsigned short color)
{
	SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), color);
}

//@ref https://en.wikipedia.org/wiki/IEEE_754-1985
//special value
//  --------+---+-----------+---------------
//  digit   |s  |exponent   |significand    
//  --------+---+-----------+---------------
//  +0      |0  |0          |0
//  -0      |1  |0          |0
//  +1      |0  |127        |0
//  -1      |1  |127        |0
//  +oo     |0  |255        |0
//  -oo     |1  |255        |0
//  NaN     |*  |255        |!=0
//  --------+---+-----------+---------------
typedef struct {
    unsigned int significand:23;
    unsigned int exponent:8;
    unsigned int s:1;
}ieee754_t;

typedef unsigned long uint32_t;

float _faddsub(float a, float b);

//res = a+b
float fadd(float a, float b);
//res = a-b
float fsub(float a, float b);
//res = a*b
float fmul(float a, float b);
//res = a/b
float fdiv(float a, float b);

void dump_bits(uint32_t v);
void dump_bits_mask(uint32_t v, uint32_t mask);
void dump_float(float v);

////////////////////////////////////////////////////////////
void dump_bits(uint32_t v)
{
    int i;

    for (i = 31;i >= 0;i--) {
        set_color(C_WHITE);
        if (v & (1 << i)) {
            printf("1");
        } else {
            printf("0");
        }
        if (((i % 8) == 0) && (i != 0)) {
            set_color(C_DARKER_GREY);
            printf("_");
        }
    }
    set_color(C_GREY);
}

void dump_bits_mask(uint32_t v, uint32_t mask)
{
    int i;

    for (i = 31;i >= 0;i--) {
        if (mask & (1 << i)) {
            set_color(C_WHITE);
            if (v & (1 << i)) {
                printf("1");
            } else {
                printf("0");
            }
        } else {
            set_color(C_DARKER_GREY);
            printf("x");
        }
        if (((i % 8) == 0) && (i != 0)) {
            set_color(C_DARKER_GREY);
            printf("_");
        }
    }
    set_color(C_GREY);
}

void dump_float(float v)
{
    unsigned char* p;
    int exponent;
    float fval;
    ieee754_t* iee;
    int i;

    p = (unsigned char*)&v;
    iee = (ieee754_t*)p;

    printf("%20.10e| ", v);

    printf("%02X %02X %02X %02X| ",
            p[3] & 0xFFu, p[2] & 0xFFu, p[1] & 0xFFu, p[0] & 0xFFu);

    printf("s=%d, exponent=%3d, significand=%6x|",
            iee->s, iee->exponent, iee->significand);

    if ((iee->exponent == 0) && (iee->significand == 0)) {
        fval = 0.0f;
    } else {
        fval = 1.0f + (float)iee->significand / (1 << 23);
        exponent = iee->exponent - 127;

        if (exponent >= 0) {
            for (i = 0;i < exponent;i++) {
                fval = fval * 2;
            }
        } else if (exponent < 0) {
            for (i = exponent;i < 0;i++) {
                fval = fval / 2;
            }
        }
    }
    if (iee->s) {
        fval = fval * -1;
    }
    printf("%f", fval);

    printf("\n");
}

////////////////////////////////////////////////////////////
uint32_t mul32lo(uint32_t a, uint32_t b)
{
    unsigned long long lla;
    unsigned long long llb;
    unsigned long long llq;
    uint32_t q;

    lla = (unsigned long long)a;
    llb = (unsigned long long)b;
    llq = lla * llb;
    q = llq & 0xFFFFFFFFu;

    return q;
}

uint32_t mul32hi(uint32_t a, uint32_t b)
{
    unsigned long long lla;
    unsigned long long llb;
    unsigned long long llq;
    uint32_t q;

    lla = (unsigned long long)a;
    llb = (unsigned long long)b;
    llq = lla * llb;
    llq = llq >> 32;
    q = llq & 0xFFFFFFFFu;

    return q;
}

//full parallel:
//  float to u32:   2 * 4 * mul18x18 as barrel-shifter
//  addsub      :   1 * addr32x32
//  u32 to float:   4 * mul18x18 as barrel-shifter
//
//
//base_e := max_e - 7
//      mul32x32 : 4 * mul18x18
//      addr32x32
//
//  stage0: unpack float-a,
//          unpack float-b,
//          find common exponentonential
//  stage1: convert float-a to u32-a (shift)
//  stage2: convert float-b to u32-b (shift)
//  stage3: add, sub
//  stage4: rounding
//  stage5: convert u32-c to float-c "normalization"
//
//base_e := max_e
//      let a > b
//      mul32x32 : 4 * mul18x18
//      addr25x25
//
//  stage0: unpack float-a,
//          unpack float-b,
//          find max exponentonential
//  stage1: convert float-a to u25-b
//          convert float-b to u25-b (shift)
//  stage2: add, sub
//  stage3: rounding
//  stage4: convert u25-c to float-c "normalization"
//
float _faddsub(float a, float b)
{
    float c = 0;
    ieee754_t* pa = (ieee754_t*)&a;
    ieee754_t* pb = (ieee754_t*)&b;
    ieee754_t* pc = (ieee754_t*)&c;
    uint32_t a32;
    uint32_t b32;
    uint32_t res;
    uint32_t tmp;
    int aexponent;
    int bexponent;
    int asign;
    int bsign;
    int base_e;
    int csign;

#ifdef DEBUG_FADD
    printf("\n");
    printf(" LOG: a=   0x%08x, exponent=%3d, sign=%d\n",
      pa->significand+0x800000, pa->exponent, pa->s);
    printf(" LOG: b=   0x%08x, exponent=%3d, sign=%d\n",
      pb->significand+0x800000, pb->exponent, pb->s);
#endif

    ////////////////////////////////////////////////////////
    //check zero and add prefix 1.xxxxx
    //
    if ((pa->exponent == 0) && (pa->significand == 0)) {
        a32 = 0;
    } else {
        a32 = 0x800000 | pa->significand;
    }
    if ((pb->exponent == 0) && (pb->significand == 0)) {
        b32 = 0;
    } else {
        b32 = 0x800000 | pb->significand;
    }

    //swap a b when b > a
    if ((pa->exponent < pb->exponent) || ((pa->exponent == pb->exponent) && (a32 < b32))) {
        aexponent = pb->exponent;
        bexponent = pa->exponent;
        asign     = pb->s;
        bsign     = pa->s;
        tmp = a32;
        a32 = b32;
        b32 = tmp;
    } else {
        aexponent = pa->exponent;
        bexponent = pb->exponent;
        asign     = pa->s;
        bsign     = pb->s;
    }

#ifdef DEBUG_FADD
    printf("\n");
    printf(" LOG: a=   0x%08x, exponent=%3d, sign=%d\n",
      pa->significand+0x800000, pa->exponent, pa->s);
    printf(" LOG: b=   0x%08x, exponent=%3d, sign=%d\n",
      pb->significand+0x800000, pb->exponent, pb->s);
#endif

    ////////////////////////////////////////////////////////
    //bigger one means have more weight,
    //so I let the bigger one shift 7 left to make sure
    //less one have more bits left.
    //
    //bigger: |31...24|23|...0|
    //                 vvvvvvv
    //
    //             <<<---- shift 7 left.
    //
    //bigger: |31|30...8|7...0|
    //            vvvvvv
    //
    //for fast convert, just let base_e = maxexponent!
    base_e = aexponent - 7;

#ifdef DEBUG_FADD
    printf(" Tip: base_e = %3d, a.exponent-base_e=%d, b.exponent-base_e=%d\n",
            base_e, aexponent-base_e, bexponent-base_e);
#endif

    ////////////////////////////////////
    //for (i = base_e;i < aexponent;i++) {
    //    a32 = a32 << 1;
    //}
    //  <=>
    //a32 = a32 << 7;
    a32 = mul32lo(a32, 0x80);

    if (bexponent == base_e) {
    } else if (bexponent > base_e) {
        //for (i = base_e;i < bexponent;i++) {
        //    b32 = b32 << 1;
        //}
        switch (bexponent - base_e) {
            case 1:tmp = 0x02;break;
            case 2:tmp = 0x04;break;
            case 3:tmp = 0x08;break;
            case 4:tmp = 0x10;break;
            case 5:tmp = 0x20;break;
            case 6:tmp = 0x40;break;
            case 7:tmp = 0x80;break;
            default:
                   printf("%s:%d:Error\n", __FILE__, __LINE__);
                   printf(" bexponent - base_e = %d\n", bexponent - base_e);
                   break;
        }
        b32 = mul32lo(b32, tmp);

    } else {
        //for (i = bexponent;i < base_e;i++) {
        //    b32 = b32 >> 1;
        //}
        if (base_e - bexponent > 16) {// <=> maxexponent - minexponent >= 24
            b32 = 0;
        } else {
            switch (base_e - bexponent) {
                case 1 :tmp = 1 << (32 - 1);break;
                case 2 :tmp = 1 << (32 - 2);break;
                case 3 :tmp = 1 << (32 - 3);break;
                case 4 :tmp = 1 << (32 - 4);break;
                case 5 :tmp = 1 << (32 - 5);break;
                case 6 :tmp = 1 << (32 - 6);break;
                case 7 :tmp = 1 << (32 - 7);break;
                case 8 :tmp = 1 << (32 - 8);break;
                case 9 :tmp = 1 << (32 - 9);break;
                case 10:tmp = 1 << (32 - 10);break;
                case 11:tmp = 1 << (32 - 11);break;
                case 12:tmp = 1 << (32 - 12);break;
                case 13:tmp = 1 << (32 - 13);break;
                case 14:tmp = 1 << (32 - 14);break;
                case 15:tmp = 1 << (32 - 15);break;
                case 16:tmp = 1 << (32 - 16);break;
                default:
                   printf("%s:%d:Error\n", __FILE__, __LINE__);
                   break;
            }

            b32 = mul32hi(b32, tmp);
        }
    }

#ifdef DEBUG_FADD
    printf(" LOG: a=   0x%08x(normal), exponent=%3d\n",
          a32, base_e);
    printf(" LOG: b=   0x%08x(normal), exponent=%3d\n",
          b32, base_e);
#endif

    //because bigger digit shift 7 left first
    //then do arithmetic, so we can check bit6
    //for rounding.
    if (a32 == 0) {
        res   = b32;
        csign = bsign;

    } else if (b32 == 0) {
        res   = a32;
        csign = asign;

    } else if (asign == bsign) {
        res   = a32 + b32;
        csign = asign;
        if (res & 0x40) {//rounding
            res = res + 0x40;
        }

    } else {
        res   = a32 - b32;
        csign = asign;
        if (res & 0x40) {//rounding
            res = res + 0x40;
        }
    }

#ifdef DEBUG_FADD
    printf(" LOG: res= 0x%08x, exponent=%3d\n", res, base_e);
#endif

    ////////////////////////////////////
    //to ieee
    if (res < 0x0000000F) {
        base_e = 0;
        res = 0;

    } else if ((res & ~0x007FFFFF) == 0x00800000) {//just ok

    } else if ((res &  0xFF000000) != 0) {//bigger
        //while ((res & ~0x7FFFFF) > 0x800000) {
        //    res = res >> 1;
        //    base_e++;
        //}

        if (res & 0x80000000) {
            tmp = 1 << (32 - 8);
            base_e += 8;
        } else if (res & 0x40000000) {
            tmp = 1 << (32 - 7);
            base_e += 7;
        } else if (res & 0x20000000) {
            tmp = 1 << (32 - 6);
            base_e += 6;
        } else if (res & 0x10000000) {
            tmp = 1 << (32 - 5);
            base_e += 5;
        } else if (res & 0x08000000) {
            tmp = 1 << (32 - 4);
            base_e += 4;
        } else if (res & 0x04000000) {
            tmp = 1 << (32 - 3);
            base_e += 3;
        } else if (res & 0x02000000) {
            tmp = 1 << (32 - 2);
            base_e += 2;
        } else if (res & 0x01000000) {
            tmp = 1 << (32 - 1);
            base_e += 1;
        } else {
            printf("%s:%d:Error\n", __FILE__, __LINE__);
        }

        res = mul32hi(res, tmp);

    } else {//smaller
        //while (res < 0x00800000) {
        //    res = res << 1;
        //    base_e--;
        //}

        //this is 16-4 encoder
        //  res & 0x0040 0000    <=> tmp = 0x0000 0002
        //  res & 0x0020 0000    <=> tmp = 0x0000 0004
        //  res & 0x0010 0000    <=> tmp = 0x0000 0008
        //  res & 0x0008 0000    <=> tmp = 0x0000 0010
        //  res & 0x0004 0000    <=> tmp = 0x0000 0020
        //  res & 0x0002 0000    <=> tmp = 0x0000 0040
        //  res & 0x0001 0000    <=> tmp = 0x0000 0080
        //  res & 0x0000 8000    <=> tmp = 0x0000 0100
        //  res & 0x0000 4000    <=> tmp = 0x0000 0200
        //  res & 0x0000 2000    <=> tmp = 0x0000 0400
        //  res & 0x0000 1000    <=> tmp = 0x0000 0800
        //  res & 0x0000 0800    <=> tmp = 0x0000 1000
        //  res & 0x0000 0400    <=> tmp = 0x0000 2000
        //  res & 0x0000 0200    <=> tmp = 0x0000 4000
        //  res & 0x0000 0100    <=> tmp = 0x0000 8000
        if (res & 0x00400000) {
            tmp     = 0x0002;
            base_e -= 1;
        } else if (res & 0x00200000) {
            tmp     = 0x0004;
            base_e -= 2;
        } else if (res & 0x00100000) {
            tmp     = 0x0008;
            base_e -= 3;
        } else if (res & 0x00080000) {
            tmp     = 0x0010;
            base_e -= 4;
        } else if (res & 0x00040000) {
            tmp     = 0x0020;
            base_e -= 5;
        } else if (res & 0x00020000) {
            tmp     = 0x0040;
            base_e -= 6;
        } else if (res & 0x00010000) {
            tmp     = 0x0080;
            base_e -= 7;
        } else if (res & 0x00008000) {
            tmp     = 0x0100;
            base_e -= 8;
        } else if (res & 0x00004000) {
            tmp     = 0x0200;
            base_e -= 9;
        } else if (res & 0x00002000) {
            tmp     = 0x0400;
            base_e -= 10;
        } else if (res & 0x00001000) {
            tmp     = 0x0800;
            base_e -= 11;
        } else if (res & 0x00000800) {
            tmp     = 0x1000;
            base_e -= 12;
        } else if (res & 0x00000400) {
            tmp     = 0x2000;
            base_e -= 13;
        } else if (res & 0x00000200) {
            tmp     = 0x4000;
            base_e -= 14;
        } else if (res & 0x00000100) {
            tmp     = 0x8000;
            base_e -= 15;
        } else {
            printf("%s:%d:Error\n", __FILE__, __LINE__);
        }

        res = mul32lo(res, tmp);
    }

#ifdef DEBUG_FADD
    printf(" LOG: res= 0x%08x, exponent=%3d\n", res, base_e);
#endif

    pc->s           = csign;
    pc->exponent    = base_e;
    pc->significand = res;

#ifdef DEBUG_FADD
    printf("\n");
#endif

    return c;
}


float fadd(float a, float b)
{
    return _faddsub(a, b);
}

float fsub(float a, float b)
{
    ieee754_t* pa = (ieee754_t*)&a;
    ieee754_t* pb = (ieee754_t*)&b;

    if (pb->s) {
        pb->s = 0;
    } else {
        pb->s = 1;
    }

    return _faddsub(a, b);
}

float fmul(float a, float b)
{
    float c = 0;
    ieee754_t* pa = (ieee754_t*)&a;
    ieee754_t* pb = (ieee754_t*)&b;
    ieee754_t* pc = (ieee754_t*)&c;
    unsigned long long a64;
    unsigned long long b64;
    unsigned long long res64;
    uint32_t a32;
    uint32_t b32;
    uint32_t res;
    int aexponent;
    int bexponent;
    int base_e;

    ////////////////////////////////////////////////////////
    //check zero and add prefix 1.xxxxx
    //
    aexponent = pa->exponent;
    bexponent = pb->exponent;
    if ((pa->exponent == 0) && (pa->significand == 0)) {
        a32 = 0;
    } else {
        a32 = 0x800000 | pa->significand;
    }
    if ((pb->exponent == 0) && (pb->significand == 0)) {
        b32 = 0;
    } else {
        b32 = 0x800000 | pb->significand;
    }

#ifdef DEBUG_FMUL
    printf("\n");
    printf(" LOG: a=   0x%08x, exponent=%3d, sign=%d\n",
      pa->significand+0x800000, pa->exponent, pa->s);
    printf(" LOG: b=   0x%08x, exponent=%3d, sign=%d\n",
      pb->significand+0x800000, pb->exponent, pb->s);
#endif

    if ((a32 == 0) || (b32 == 0)) {
        pc->s = 0;
        pc->exponent = 0;
        pc->significand = 0;
        return c;
    }

    ////////////////////////////////////
    a64 = (unsigned long long)a32;
    b64 = (unsigned long long)b32;
    res64 = a64 * b64;
#ifdef DEBUG_FMUL
    printf(" LOG:res=  0x%016I64x\n",
            res64);
#endif

    if (res64 & 0x00800000) {//rounding
        res64 = res64 + 0x00800000;
    }

#ifdef DEBUG_FMUL
    printf(" LOG:res=  0x%016I64x\n",
            res64);
#endif
    
    //actual result is 47bits or 48bits valid
    //
    //bacause base.exponent is a.exponent + b.exponent
    //so result's lower 23bits drop.
    //
    base_e = aexponent + bexponent - 127;
    if ((res64 >> 47) & 1) {
        res = (uint32_t)(res64 >> 24);
        base_e = base_e + 1;
    } else {
        res = (uint32_t)(res64 >> 23);
    }

#ifdef DEBUG_FMUL
    printf(" LOG:res=  0x%016I64x, exponent=%3d\n",
            res64, base_e);
    printf(" LOG:res=  0x%08x, exponent=%3d\n",
            res, base_e);
#endif

    pc->s           = pa->s ^ pb->s;
    pc->exponent    = base_e;
    pc->significand = res;

#ifdef DEBUG_FMUL
    printf(" LOG:c  =  0x%08x, exponent=%3d\n",
            pc->significand, pc->exponent);
#endif

    return c;
}

float fdiv(float a, float b)
{
    float c = 0;
    ieee754_t* pa = (ieee754_t*)&a;
    ieee754_t* pb = (ieee754_t*)&b;
    ieee754_t* pc = (ieee754_t*)&c;
    uint32_t a32;
    uint32_t b32;
    int aexponent;
    int bexponent;
    int base_e;

    uint32_t A;
    uint32_t Q;
    uint32_t M;
    uint32_t mask;

    int i;


    ////////////////////////////////////////////////////////
    //check zero and add prefix 1.xxxxx
    //
    aexponent = pa->exponent;
    bexponent = pb->exponent;
    if ((pa->exponent == 0) && (pa->significand == 0)) {
        a32 = 0;
    } else {
        a32 = 0x800000 | pa->significand;
    }
    if ((pb->exponent == 0) && (pb->significand == 0)) {
        b32 = 0;
    } else {
        b32 = 0x800000 | pb->significand;
    }

    //div 0
    if (b32 == 0) {//return Infinite
        pc->s = pa->s ^ pb->s;
        pc->significand = 0;
        pc->exponent    = 255;
    }

    // divident = divisor * quotient + reminder
    // A(init)      M(const)   Q(result)  A(result)

    base_e = aexponent - bexponent + 127;
    A = a32;
    Q = 0;
    M = b32;
    mask = 0;

#ifdef DEBUG_FDIV
    printf("     ");
    printf("A: ");
    dump_bits(A);
    printf(", ");

    printf("Q: ");
    dump_bits(Q);
    printf("\n");

    printf("     ");
    printf("M: ");
    dump_bits(M);
    printf("\n");

    printf("\n");
#endif

    //do one more divide to get better precision
    for (i = 0;i < 25;i++) {
#ifdef DEBUG_FDIV
        printf("%2d) ", i);
        if (A >= M) {
            printf("*");
        } else {
            printf(" ");
        }
#endif

        Q = Q << 1;
        if (A >= M) {
            A = A - M;
            Q = Q | 1;
        }
        A = A << 1;

        mask = (mask << 1) | 1;

#ifdef DEBUG_FDIV
        printf("A: ");
        dump_bits(A);
        printf(", ");

        printf("Q: ");
        dump_bits_mask(Q, mask);
        printf("\n");
#endif
    }

    //because divde more clock, so check bit24, nor bit23:)
    //so no need to rounding
    if (Q & 0x01000000) {
        pc->s           = pa->s ^ pb->s;
        pc->significand = Q >> 1;
        pc->exponent    = base_e;
    } else {
        pc->s           = pa->s ^ pb->s;
        pc->significand = Q;
        pc->exponent    = base_e - 1;
    }

    return c;
}

#ifdef SELF_TEST
typedef float (*FPU_ALGORITHM)(float, float);

void runtest(float a, char op, float b, float expect, FPU_ALGORITHM pf)
{
    float val;

    val = pf(a, b);
    printf("CHK: %15e %c %15e = %15e, eps = %15e\n",
            a, op, b, val, expect-val);
    dump_float(a);
    dump_float(b);
    dump_float(val);
    printf("\n");
}

int main(int argc, char* argv[])
{
    float fval = 0;
    float fa;
    float fb;
    float fexpect = 0;
    unsigned char* p;
    ieee754_t* iee;

    // we know: 8.75f == 1000.11b
    //
    // so 1000.11b >> 3 == 1.00011b
    // let exponent = 3 + 127 = 130 (10000010b)
    //     significand = [1.]00011000....
    //
    //  bit||31|30....23|22........0|
    //  val||0 |10000010|00011000..0|
    //               130    0x0C0000
    p = (unsigned char*)&fval;
    iee = (ieee754_t*)p;
    iee->s = 0;
    iee->exponent = 130;
    iee->significand = 0x0c0000;

    /*
    dump_float(fval);

    dump_float(0.0f);
    dump_float(1.0f);
    dump_float(10000.0f);
    dump_float(0.001f);
    dump_float(3.141592653f);
    dump_float(-3.141592653f);
    printf("\n");
    */






    /*
    ////////////////////////////////////////////////////////
    fa   = 1.0f;
    fb   = 3.11f;
    fval = fadd(fa, fb);
    fexpect = fa + fb;
    printf("CHK: %15e + %15e = %15e, eps = %15.15f\n", fa, fb, fval, fexpect-fval);

    fa   = 1.0f;
    fb   = 3.11f;
    fval = fsub(fa, fb);
    fexpect = fa - fb;
    printf("CHK: %15e - %15e = %15e, eps = %15.15f\n", fa, fb, fval, fexpect-fval);

    fa   = 1.0e7f;
    fb   = 3.11f;
    fval = fadd(fa, fb);
    fexpect = fa + fb;
    printf("CHK: %15e + %15e = %15e, eps = %15.15f\n", fa, fb, fval, fexpect-fval);

    fa   = 1.0e7f;
    fb   = 3.11f;
    fval = fsub(fa, fb);
    fexpect = fa - fb;
    printf("CHK: %15e - %15e = %15e, eps = %15.15f\n", fa, fb, fval, fexpect-fval);
    */

    fa   = 990.f;
    fb   = 1192.f;
    runtest(fa, '+', fb, fa+fb, fadd);

    fa   = 990.f;
    fb   = 1192.f;
    runtest(fa, '-', fb, fa-fb, fsub);

    fa   = -10.f;
    fb   = 1.f;
    runtest(fa, '+', fb, fa+fb, fadd);

    fa   = -10.f;
    fb   = -91.f;
    runtest(fa, '-', fb, fa-fb, fsub);

    fa   = 0.f;
    fb   = 1.f;
    runtest(fa, '+', fb, fa+fb, fadd);

    fa   = 0.f;
    fb   = -1.f;
    runtest(fa, '+', fb, fa+fb, fadd);

    fa   = 0.f;
    fb   = -1.f;
    runtest(fa, '-', fb, fa-fb, fsub);

    fa   = 1.f;
    fb   = 1.f;
    runtest(fa, '+', fb, fa+fb, fadd);

    fa   = 1.f;
    fb   = 1.f;
    runtest(fa, '-', fb, fa-fb, fsub);

    fa   = 100003.f;
    fb   = 100000.f;
    runtest(fa, '+', fb, fa+fb, fadd);

    fa   = 123456789.f;
    fb   = 10.f;
    runtest(fa, '-', fb, fa-fb, fsub);

    ////////////////////////////////////////////////////////
    fa   = 123456789.f;
    fb   = 10.f;
    runtest(fa, '*', fb, fa*fb, fmul);

    fa   = 0.123456789f;
    fb   = 10.f;
    runtest(fa, '*', fb, fa*fb, fmul);

    ////////////////////////////////////////////////////////
    fa   = 10.f;
    fb   = 3.f;
    runtest(fa, '/', fb, fa/fb, fdiv);

    fa   = 19.f;
    fb   = 3.1415f;
    runtest(fa, '/', fb, fa/fb, fdiv);

    fa   = -10.f;
    fb   = 3.f;
    runtest(fa, '/', fb, fa/fb, fdiv);

    fa   = 1.1232e20f;
    fb   = 3.988e5f;
    runtest(fa, '/', fb, fa/fb, fdiv);


    return 0;
}
#endif

