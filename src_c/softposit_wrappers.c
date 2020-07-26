#include "softposit.h"
#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <math.h>

typedef union {
  float f;
  unsigned u;
}ufloat;

typedef union {
  double d;
  unsigned long u;
} udouble ;

unsigned char positAdd8(unsigned char a, unsigned char b)
{
	posit8_t x,y;
	x = castP8(a);
    	y = castP8(b);

	return (char)(p8_add(x,y)).v;
	
}

unsigned int positAdd32(unsigned int a, unsigned int b)
{
	posit32_t x,y;
	x = castP32(a);
    	y = castP32(b);
	return (p32_add(x,y)).v;
	
}

unsigned int positAdd16(unsigned int a, unsigned int b)
{
	posit16_t x,y;
	x = castP16(a);
    	y = castP16(b);
	return (p16_add(x,y)).v;
	
}

unsigned char positMul8(unsigned char a, unsigned char b)
{
	posit8_t x,y;
	x = castP8(a);
    	y = castP8(b);
	return (char)(p8_mul(x,y)).v;
	
}
unsigned int positMul16(unsigned int a, unsigned int b)
{
	posit16_t x,y;
	x = castP16(a);
    	y = castP16(b);
	return (p16_mul(x,y)).v;
	
}
unsigned int positMul32(unsigned int a, unsigned int b)
{
	posit_2_t x,y;
	x = castPX2(a);
    	y = castPX2(b);
	return (pX2_mul(x,y,32)).v;
	
}

unsigned char positDiv8(unsigned char a, unsigned char b)
{
	posit8_t x,y;
	x = castP8(a);
    	y = castP8(b);
	return (p8_div(x,y)).v;
	
}

unsigned int positDiv16(unsigned int a, unsigned int b)
{
	posit16_t x,y;
	x = castP16(a);
    	y = castP16(b);
	return (p16_div(x,y)).v;
	
}

unsigned int positDiv32(unsigned int a, unsigned int b)
{
	posit_2_t x,y;
	x = castPX2(a);
    	y = castPX2(b);
	return (pX2_div(x,y,32)).v;
	
}

unsigned int positMAC32(unsigned int a, unsigned int b, unsigned int c)
{
	posit32_t x,y,z;
	x = castP32(a);
    	y = castP32(b);
    	z = castP32(c);
	return (p32_mulAdd(x,y,z)).v;
	
}

unsigned int positMAC16(unsigned int a, unsigned int b, unsigned int c)
{
	posit16_t x,y,z;
	x = castP16(a);
    	y = castP16(b);
    	z = castP16(c);
	return (p16_mulAdd(x,y,z)).v;
	
}

unsigned char positMAC8(unsigned char a, unsigned char b, unsigned char c)
{
	posit8_t x,y,z;
	x = castP8(a);
    	y = castP8(b);
    	z = castP8(c);
	return (p8_mulAdd(x,y,z)).v;
	
}

unsigned int quireToPosit16(unsigned long long a, unsigned long long b)
{
	quire16_t qZ;
	qZ = q16_clr(qZ);
	qZ = castQ16(a,b);
	posit16_t pZ = q16_to_p16(qZ);	
	return pZ.v;
	
}

unsigned int quireToPosit32(unsigned long long a, unsigned long long b,unsigned long long c,unsigned long long d,unsigned long long e,unsigned long long f, unsigned long long g, unsigned long long h)
{
	quire32_t qZ;
	qZ = q32_clr(qZ);
	qZ = castQ32(a,b,c,d,e,f,g,h);
	posit32_t pZ = q32_to_p32(qZ);	
	return pZ.v;
	
}

unsigned int floatToPosit8(unsigned char a)
{
	ufloat b;
	b.u = a;
	posit8_t pZ = convertDoubleToP8(b.f);	
	return pZ.v;
	
}

unsigned int floatToPosit16(unsigned int a)
{
	ufloat b;
	b.u = a;
	posit16_t pZ = convertDoubleToP16(b.f);	
	return pZ.v;
	
}

unsigned int floatToPosit32(unsigned int a)
{
	ufloat b;
	b.u = a;
	posit32_t pZ = convertDoubleToP32(b.f);	
	return pZ.v;
	
}

unsigned int Posit8Tofloat(unsigned char a)
{
	posit8_t x;
	x = castP8(a);
	ufloat b;
	b.f = convertP8ToDouble(x);
	return b.u;	
	
}


unsigned int Posit16Tofloat(unsigned int a)
{
	posit16_t x;
	x = castP16(a);
	ufloat b;
	b.f = convertP16ToDouble(x);
	return b.u;	
	
}

unsigned int Posit32Tofloat(unsigned int a)
{
	posit32_t x;
	x = castP32(a);
	ufloat b;
	b.f = convertP32ToDouble(x);
	return b.u;
	
}

void fmaAdd16 (unsigned int* result, unsigned int* a, unsigned int c, unsigned int d) {
	posit16_t x,y; quire16_t qZ;
	x = castP16(c); y = castP16(d); qZ = q16_clr(qZ);
	unsigned long long var1= a[1];
	unsigned long long var2= a[3];
	var1 = (var1<<32) + a[0];
	var2 = (var2<<32) + a[2];
	qZ = castQ16(var2,var1);  
	qZ = q16_fdp_add(qZ, x, y);
	for (int idx=0; idx<4; idx++) result[idx] = qZ.v[idx];
	return;
	$printf("result[0]",result[0]);
}

void fmaAdd32 (unsigned int* result, unsigned int* a, unsigned int c, unsigned int d) {
	posit32_t x,y; quire32_t qZ;
	x = castP32(c); y = castP32(d); qZ = q32_clr(qZ);
	unsigned long long var1= a[1];
	unsigned long long var2= a[3];
	unsigned long long var3= a[5];
	unsigned long long var4= a[7];
	unsigned long long var5= a[9];
	unsigned long long var6= a[11];
	unsigned long long var7= a[13];
	unsigned long long var8= a[15];
	var1 = (var1<<32) + a[0];
	var2 = (var2<<32) + a[2];
	var3 = (var3<<32) + a[4];
	var4 = (var4<<32) + a[6];
	var5 = (var5<<32) + a[8];
	var6 = (var6<<32) + a[10];
	var7 = (var7<<32) + a[12];
	var8 = (var8<<32) + a[14];
	qZ = castQ32(var8,var7,var6,var5,var4,var3,var2,var1);  
	qZ = q32_fdp_add(qZ, x, y);
	for (int idx=0; idx<16; idx++) result[idx] = qZ.v[idx];
	return;
}




/*unsigned long long fmaAdd161(unsigned long long a,unsigned long long b,unsigned int c, unsigned int d)
{
	posit16_t x,y;
	x = castP16(c);
    	y = castP16(d);
	quire16_t qZ;
	qZ = q16_clr(qZ);
	qZ = castQ16(a,b);
	qZ = q16_fdp_add(qZ, x, y);
	return qZ.v[0];
}

unsigned long long fmaAdd162(unsigned long long a,unsigned long long b,unsigned int c, unsigned int d)
{
	//c*d+(a,b)
	posit16_t x,y;
	x = castP16(c);
    	y = castP16(d);
	quire16_t qZ;
	qZ = q16_clr(qZ);
	qZ = castQ16(a,b);
	qZ = q16_fdp_add(qZ, x, y);
	return qZ.v[1];
}*/
unsigned long long fmaAdd8(unsigned long long a,unsigned char c, unsigned char d)
{
	//c*d+(a,b)
	posit8_t x,y,z;
	x = castP8(c);
    	y = castP8(d);
	quire8_t qZ;
	qZ = q8_clr(qZ);
	qZ = castQ8(a);
	qZ = q8_fdp_add(qZ, x, y);
	return qZ.v;
}

unsigned long long fdaAdd8(unsigned long long a,unsigned char c, unsigned char d)
{
	//c*d+(a,b)
	posit8_t x,y;
	x = castP8(c);
    	y = castP8(d);
	posit8_t pZ = p8_div(x,y);
	quire8_t qZ;
	qZ = q8_clr(qZ);
	qZ = castQ8(a);
	qZ = q8_fdp_add(qZ, pZ, castP8(1));
	return qZ.v;
}

unsigned long long fdaAdd161(unsigned long long a,unsigned long long b,unsigned int c, unsigned int d)
{
	unsigned int one = 1;	
	posit16_t x,y;
	x = castP16(c);
    	y = castP16(d);
	posit16_t pZ = p16_div(x,y);
	quire16_t qZ;
	qZ = q16_clr(qZ);
	qZ = castQ16(a,b);
	qZ = q16_fdp_add(qZ, pZ, castP16(one));
	return qZ.v[0];
}

unsigned long long fdaAdd162(unsigned long long a,unsigned long long b,unsigned int c, unsigned int d)
{
	//c*d+(a,b)
	unsigned int one = 1;
	posit16_t x,y;
	x = castP16(c);
    	y = castP16(d);
	posit16_t pZ = p16_div(x,y);
	quire16_t qZ;
	qZ = q16_clr(qZ);
	qZ = castQ16(a,b);
	qZ = q16_fdp_add(qZ, pZ, castP16(one));
	return qZ.v[1];
}
/*
unsigned char positSub8(unsigned char a, unsigned char b)
{
	posit8_t x,y;
	x = castP8(a);
    	y = castP8(b);
	return (char)(p8_sub(x,y)).v;
	
}



unsigned int positSub16(unsigned int a, unsigned int b)
{
	posit16_t x,y;
	x = castP16(a);
    	y = castP16(b);
	return (p16_sub(x,y)).v;
	
}
*/

