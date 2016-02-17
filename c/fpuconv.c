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


typedef struct {
    unsigned int exponent:8;//0x80 >>, 0x00 <<
    unsigned int significand:24;
}pcap24_float;

typedef struct {
    unsigned int significand:23;
    unsigned int exponent:8;
    unsigned int s:1;
}ieee754_t;

int int48_to_f24(unsigned long long v, pcap24_float* f)
{
    int i;
    int cnt;
    unsigned long long chk = ((unsigned long long)1) << 47;
    
    for (i = 0;i < 48;i++) {
        if (chk & (v << i)) {
            break;
        }
    }

    if (i < 24) {
        cnt = 24 - i;
        v = v >> cnt;
    } else {
        cnt = i - 24;
        v = v << cnt;
        cnt |= 0x80;
    }

    f->exponent = cnt;
    f->significand = v & 0xFFFF00u;

    return 0;
}

int int48_to_f32(unsigned long long v, ieee754_t* f)
{
    float tmp;

    tmp = (float)v;

    *f = *(ieee754_t*)&tmp;

    return 0;
}

int f24_to_f32(pcap24_float* f24, ieee754_t* f32)
{
    int shift = 0;

    if (f24->exponent & 0x80) {
        shift = -1 * (f24->exponent & ~0x80);
    } else {
        shift = f24->exponent;
    }

    f32->exponent = shift + 23 + 127;
    f32->significand = f24->significand & ~0x800000;

    return 0;
}

void dump_f24(pcap24_float* f)
{
    int i;

    if (f->exponent & 0x80) {
        printf("exponent=-0x%07x, significand=24'b", f->exponent & ~0x80);
    } else {
        printf("exponent=+0x%07x, significand=24'b", f->exponent);
    }

    for (i = 23;i >= 0;i--) {
        if (f->significand & (1 << i)) {
            printf("1");
        } else {
            printf("0");
        }
        if (((i % 4) == 0) && (i != 0)) {
            printf("_");
        }
    }
    printf("\n");
}

void dump_f32(ieee754_t* f)
{
    int i;

    printf("exponent=0x%08x, significand=24'b1", f->exponent);

    for (i = 22;i >= 0;i--) {
        if (f->significand & (1 << i)) {
            printf("1");
        } else {
            printf("0");
        }
        if (((i % 4) == 0) && (i != 0)) {
            printf("_");
        }
    }
    printf("\n");
}

void print_f32(ieee754_t* f)
{
    unsigned long v;
    int shift;

    if ((f->significand == 0) && (f->exponent == 0)) {
        v = 0;

    } else {
        v = 0x800000 | f->significand;
        shift = f->exponent - 23;
        if (shift > 127) {
            printf("<< %d\n", (shift - 127));
            v = v << (shift - 127);
        } else {
            printf(">> %d\n", (127 - shift));
            v = v >> (127 - shift);
        }
    }

    printf("0x%08x\n", v);
}

int main(int argc, char* argv[])
{
    pcap24_float f24;
    ieee754_t f32;
    ieee754_t f32_1;

    int48_to_f24(0x00012340, &f24);
    int48_to_f32(0x00012340, &f32);
    print_f32(&f32);
    printf("pcap24 : 0x%06x\n", f24.significand | f24.exponent);
    printf("float32: 0x%08x\n", *(unsigned int*)&f32);

    f24_to_f32(&f24, &f32_1);
    dump_f24(&f24);
    dump_f32(&f32);
    dump_f32(&f32_1);
    printf("\n");


    ////////////////////////////////////
    int48_to_f24(0xFEE12340, &f24);
    int48_to_f32(0xFEE12340, &f32);
    print_f32(&f32);
    printf("pcap24 : 0x%06x\n", f24.significand | f24.exponent);
    printf("float32: 0x%08x\n", *(unsigned int*)&f32);

    f24_to_f32(&f24, &f32_1);
    dump_f24(&f24);
    dump_f32(&f32);
    dump_f32(&f32_1);
    printf("\n");


    return 0;
}

