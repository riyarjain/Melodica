 #include <stdio.h>	
#include <stdlib.h> 
static unsigned char *texels;
static int width, height;

int main()
 {
     char inp[]="rubic_4.bmp";
readBmp(inp);
//outFile =fopen(output,"w");
//fclose(outFile);

}
 void readBmp(char *filename)
{
FILE *fd, *out;
fd = fopen(filename, "rb");
out = fopen("out.txt", "a");
if (fd == NULL)
{
printf("Error: fopen failed\n");
return;
}

unsigned char header[54];

// Read header
fread(header, sizeof(unsigned char), 54, fd);

// Capture dimensions
width = *(int*)&header[18];
height = *(int*)&header[22];
printf("width %d",width);
printf("height %d",height);
int padding = 0;

// Calculate padding
while ((width * 3 + padding) % 4 != 0)
{
padding++;
}

// Compute new width, which includes padding
int widthnew = width * 3 + padding;

// Allocate memory to store image data (non-padded)
texels = (unsigned char *)malloc(width * height * 3 * sizeof(unsigned char));
if (texels == NULL)
{
printf("Error: Malloc failed\n");
return;
}

// Allocate temporary memory to read widthnew size of data
unsigned char* data = (unsigned char *)malloc(widthnew * sizeof (unsigned int));

// Read row by row of data and remove padded data.
for (int i = 0; i<height; i++)
{
// Read widthnew length of data
fread(data, sizeof(unsigned char), widthnew, fd);

// Retain width length of data, and swizzle RB component.
// BMP stores in BGR format, my usecase needs RGB format
for (int j = 0; j < width * 3; j += 3)
{
int index = (i * width * 3) + (j);
int sum = ((int)data[j + 2] + (int)data[j + 1] + (int)data[j + 0] )/3;
fprintf(out,"%d\t",sum);
}
fprintf(out,"\n");
}
fprintf(out,"\n");
fprintf(out,"\n");
fprintf(out,"\n");
free(data);
fclose(fd);
}
