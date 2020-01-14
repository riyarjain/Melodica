#include "softposit.h"
#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <math.h>
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
struct Tuple1 {unsigned long long a1; unsigned long long b1;};

void fdpAdd16(unsigned long long *a,unsigned int c, unsigned int d)
{
	//c*d+(a,b)
	
	printf("a %08x\n", *a[0]);
	printf("a %08x\n", *a[1]);
	printf("a %08x\n", *a[2]);
	printf("a %08x\n", *a[3]);
	printf("c %04x\n", c);
	printf("d %04x\n", d);
 	posit16_t x,y;
	x = castP16(c);
    	y = castP16(d);
	quire16_t qZ;
	qZ = q16_clr(qZ);
	//unsigned long long a1 = a[3]*(pow(10,32)) + a[2];
	//unsigned long long a0 = a[1]*(pow(10,32)) + a[0];	
	
	qZ = castQ16(a[1],a[0]);
	qZ = q16_fdp_add(qZ, x, y);
	a1 = qZ.v[0];
	a0 = qZ.v[1];
	a[3] = a1 / ((unsigned long long) pow(10,32));
	a[2] = a1 % ((unsigned long long) pow(10,32));
	a[1] = a0 / ((unsigned long long) pow(10,32));
	a[0] = a0 % ((unsigned long long) pow(10,32));
	//posit16_t pZ = q16_to_p16(qZ);	

	
}
*/

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

