 #include <stdio.h>	 
 #include "softposit.h"

 int X,Y;
 int normalise = 0;

 void getPOI(int kernelSize, int POI[][1][2])
 {
	  int count = 0;
	  int mean = kernelSize/2;
	  int xPos = mean;
	  int yPos = mean;
	  int xStep = (X-mean)/kernelSize;
	  int yStep = (Y-mean)/kernelSize;
	 
	 for (int i=0; i<yStep; i++)
	 {
		 for (int j=0; j<xStep; j++)
		 {
			 POI[count][0][1] = xPos;
			 POI[count][0][0] = yPos;
			 xPos += kernelSize;
			 count++;
		 }
		 xPos = mean;
		 yPos += kernelSize;
	 }
 }
 
 void buildA (posit16_t img[Y][X], int centerX, int centerY, int kernelSize, posit16_t A[][2])
 {
	 int mean = kernelSize/2;
	 int count = 0;
	 posit16_t  home = img[centerY][centerX];
	 posit16_t Ax, Ay;
	 
	 for (int j = -mean; j<mean + 1; j++)
	 {
		 for (int i = -mean; i<mean + 1; i++)
		 {
			 if (i == 0) Ax = convertDoubleToP16(0);
			 else Ax = convertDoubleToP16(convertP16ToDouble(p16_sub(home, img[centerY + j][centerX + i]))/(float)i);
				//Ax = ((float)home - (float)img[centerY + j][centerX + i])/(float)i;
			 if (j == 0) Ay = convertDoubleToP16(0);
			 else Ay = convertDoubleToP16(convertP16ToDouble(p16_sub(home, img[centerY + j][centerX + i]))/(float)j);
				//Ay = ((float)home - (float)img[centerY + j][centerX + i])/(float)j;
			 
			 A[count][0] = Ay;
			 A[count][1] = Ax;
			 count++;
		 }
	 }
 }
 
 void buildB (posit16_t imgNew[Y][X], posit16_t imgOld[Y][X], int centerX, int centerY, int kernelSize, posit16_t B[])
 {
	 int mean = kernelSize/2;
	 int count = 0;
	 posit16_t Bt;
	 
	 for (int j = -mean; j < mean + 1; j++)
	 {
		 for (int i = -mean; i < mean + 1; i++)
		 {
			 Bt = p16_sub(imgNew[centerY + j][centerX + i], imgOld[centerY + j][centerX + i]);
			 B[count] = Bt;
			 count++;
		 }
	 }
 }
 
 void calcV(posit16_t A[][2], posit16_t B[], posit16_t V[][2], int kernelSize, int i)
 {
     int Arows = kernelSize * kernelSize;
     posit16_t At[2][Arows];
     for (int row = 0; row < Arows; row++)
     {
         for (int col = 0; col < 2; col++)
         {
             At[col][row] = (A[row][col]);
         }
     }			 
     
     /********************/
     
     posit16_t AtA[2][2];
     quire16_t qZ1;		
     qZ1 = q16_clr(qZ1);	 
     for (int row = 0; row < 2; row++)
     {
         for (int col = 0; col < 2; col++)
         {

             for (int k=0; k<Arows; k++)
             {
                	qZ1 = q16_fdp_add(qZ1,At[row][k],A[k][col]);
             }	
	     AtA[row][col] = q16_to_p16(qZ1);
     	     qZ1 = q16_clr(qZ1);	 		  
         }
     }		 
                 
     qZ1 = q16_clr(qZ1);	 		  
     posit16_t AtB[2][1];			 
     for (int row = 0; row < 2; row++)
     {
         for (int col = 0; col < 1; col++)
         {
             for (int k=0; k<Arows; k++)
             {
		qZ1 = q16_fdp_add(qZ1,At[row][k],(B[k]));
             }	
	     AtB[row][col] = q16_to_p16(qZ1);
     	     qZ1 = q16_clr(qZ1);	 		  
         }
     }		 
     
    /********************/
    qZ1 = q16_clr(qZ1);	 		  
    posit16_t AtAInv[2][2];
    posit16_t Vpt[2][1];
    posit16_t det = p16_sub(p16_mul(AtA[0][0],AtA[1][1]),p16_mul(AtA[0][1],AtA[1][0]));
    if (convertP16ToDouble(det) != 0)
    {					
        AtAInv[0][0] = p16_div(AtA[1][1],det);
        AtAInv[0][1] = p16_div(p16_mul(convertDoubleToP16(-1),AtA[0][1]),det);
        AtAInv[1][0] = p16_div(p16_mul(convertDoubleToP16(-1),AtA[1][0]),det);
        AtAInv[1][1] = p16_div(AtA[0][0],det);
        
        for (int row = 0; row < 2; row++)
         {
             for (int col = 0; col < 1; col++)
             {
                 for (int k=0; k<2; k++)
                 {
                     qZ1 = q16_fdp_add(qZ1,AtAInv[row][k],AtB[k][col]);
             	}	
	     Vpt[row][col] = q16_to_p16(qZ1);
     	     qZ1 = q16_clr(qZ1);					  
             }
         }
         
         V[i][0] = (Vpt[0][0]);
         V[i][1] = (Vpt[0][1]);
    }
    else 
    {
        V[i][0] = convertDoubleToP16(0);
        V[i][1] = convertDoubleToP16(0);
    }
    
 }
	 
 int main()
 {
	 FILE *imgFile, *velFile;
	 int kernelSize = 5;
	 int fileCount;
	 
	 /****************Image Read from file************************/
	 imgFile = fopen("img_rubic.txt", "r");
	 
	 fscanf(imgFile, "%d", &X);
	 fscanf(imgFile, "%d", &Y);
	 fscanf(imgFile, "%d", &fileCount);
	 
	 float Iold_f[Y][X];
	 float Inew_f[Y][X];

	 posit16_t Iold[Y][X];
	 posit16_t Inew[Y][X];
	 
	 for (int i=0; i<Y; i++)
	 {
		 for (int j=0; j<X; j++)
		 {
			 fscanf(imgFile, "%e", &Iold_f[i][j]);
			 if(normalise == 0)
			 	Iold[i][j] = convertDoubleToP16(Iold_f[i][j]);
			 else
			  	Iold[i][j] = convertDoubleToP16(Iold_f[i][j]*16.0/255.0);
		 }
	 }
	 
	 fclose(imgFile);
	 /**********************************************/
	 
	 int length = ((X-(kernelSize/2))/kernelSize) * ((Y-(kernelSize/2))/kernelSize);	 
	 int POI[length][1][2];
	 getPOI(kernelSize, POI);
	 
	 /************GetPOI Function Test *************/
	 // for (int i=0; i<length; i++)
	 // {
		 // printf("%d\t", POI[i][0][0]);
		 // printf("%d\n", POI[i][0][1]);
	 // }
	 /**********************************************/
	 
	 posit16_t V[length][2];
	 posit16_t A[kernelSize*kernelSize][2];
	 posit16_t B[kernelSize*kernelSize];
	 
     /****************Image Read from file************************/
	 for (int fCount=1; fCount<fileCount; fCount++)
	 {
		 imgFile = fopen("img_rubic.txt", "r");	 
		 
		 int ignore;
		 
		 for (int i=0; i<3; i++) fscanf(imgFile, "%d", &ignore);
		 
		 for (int file=0; file < fCount; file++)
		 {
			for (int i=0; i<Y; i++)
			 {
				 for (int j=0; j<X; j++)
				 {
					 fscanf(imgFile, "%d", &ignore);
				 }
			 } 
		 }
		 
		 for (int i=0; i<Y; i++)
		 {
			 for (int j=0; j<X; j++)
			 {
				 fscanf(imgFile, "%e", &Inew_f[i][j]);
				  if(normalise == 0)
				 	Inew[i][j] = convertDoubleToP16(Inew_f[i][j]);
				  else
			 	 	Inew[i][j] = convertDoubleToP16(Inew_f[i][j]*16.0/255.0);
			 }
		 }	 
		 fclose(imgFile);
		 /**********************************************/

		 
		 for (int i=0; i<length; i++)
		 {
			 buildA(Inew, POI[i][0][1], POI[i][0][0], kernelSize, A);          
			 			 
			 buildB(Inew, Iold, POI[i][0][1], POI[i][0][0], kernelSize, B);
			 			 
			 calcV(A, B, V, kernelSize, i);			 
			 
		 }
         
		 
		 /************Writing Vel values to file*************/
		 if (fCount == 1)	
         {
             velFile = fopen("vel_p5_161.txt", "w");
             fprintf(velFile, "%d\t%d\n", length, fileCount);
		 }
         else 
         {
             velFile = fopen("vel_p5_161.txt", "a");
             fprintf(velFile, "\n");
         }
         
		 for (int i=0; i<length; i++)
		 {
			 if (i == length - 1)
             {
                fprintf(velFile, "%10.64f\t", convertP16ToDouble(V[i][0]));
                fprintf(velFile, "%10.64f", convertP16ToDouble(V[i][1]));
                break;
             }
             fprintf(velFile, "%10.64f\t", convertP16ToDouble(V[i][0]));
		fprintf(velFile, "%10.64f\n", convertP16ToDouble(V[i][1]));
		 }
		 fclose(velFile);
		 /*************************************************/
			 
		 /************Replacing Iold with Inew*************/
		 for (int i=0; i<Y; i++)
		 {
			 for (int j=0; j<X; j++)
			 {
				 Iold[i][j] = Inew[i][j];
			 }
		 }
		 /*************************************************/
	 }
	 
	 
	 return 0;
 }

