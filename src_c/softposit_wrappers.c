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

unsigned long long fdpAdd161(unsigned long long a,unsigned long long b,unsigned int c, unsigned int d)
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

unsigned long long fdpAdd162(unsigned long long a,unsigned long long b,unsigned int c, unsigned int d)
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
}
unsigned long long fdpAdd8(unsigned long long a,unsigned char c, unsigned char d)
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

