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
 
 void buildA (posit32_t img[Y][X], int centerX, int centerY, int kernelSize, posit32_t A[][2])
 {
	 int mean = kernelSize/2;
	 int count = 0;
	 posit32_t  home = img[centerY][centerX];
	 posit32_t Ax, Ay;
	 
	 for (int j = -mean; j<mean + 1; j++)
	 {
		 for (int i = -mean; i<mean + 1; i++)
		 {
			 if (i == 0) Ax = convertDoubleToP32(0);
			 else Ax = convertDoubleToP32(convertP32ToDouble(p32_sub(home, img[centerY + j][centerX + i]))/(float)i);
				//Ax = ((float)home - (float)img[centerY + j][centerX + i])/(float)i;
			 if (j == 0) Ay = convertDoubleToP32(0);
			 else Ay = convertDoubleToP32(convertP32ToDouble(p32_sub(home, img[centerY + j][centerX + i]))/(float)j);
				//Ay = ((float)home - (float)img[centerY + j][centerX + i])/(float)j;
			 
			 A[count][0] = Ay;
			 A[count][1] = Ax;
			 count++;
		 }
	 }
 }
 
 void buildB (posit32_t imgNew[Y][X], posit32_t imgOld[Y][X], int centerX, int centerY, int kernelSize, posit32_t B[])
 {
	 int mean = kernelSize/2;
	 int count = 0;
	 posit32_t Bt;
	 
	 for (int j = -mean; j < mean + 1; j++)
	 {
		 for (int i = -mean; i < mean + 1; i++)
		 {
			 Bt = p32_sub(imgNew[centerY + j][centerX + i], imgOld[centerY + j][centerX + i]);
			 B[count] = Bt;
			 count++;
		 }
	 }
 }
 
 void calcV(posit32_t A[][2], posit32_t B[], posit32_t V[][2], int kernelSize, int i)
 {
     int Arows = kernelSize * kernelSize;
     posit32_t At[2][Arows];
     for (int row = 0; row < Arows; row++)
     {
         for (int col = 0; col < 2; col++)
         {
             At[col][row] = (A[row][col]);
         }
     }			 
     
     /********************/
     
     posit32_t AtA[2][2];
     quire32_t qZ1;		
     qZ1 = q32_clr(qZ1);	 
     for (int row = 0; row < 2; row++)
     {
         for (int col = 0; col < 2; col++)
         {

             for (int k=0; k<Arows; k++)
             {
                	qZ1 = q32_fdp_add(qZ1,At[row][k],A[k][col]);
             }	
	     AtA[row][col] = q32_to_p32(qZ1);
     	     qZ1 = q32_clr(qZ1);	 		  
         }
     }		 
                 
     qZ1 = q32_clr(qZ1);	 		  
     posit32_t AtB[2][1];			 
     for (int row = 0; row < 2; row++)
     {
         for (int col = 0; col < 1; col++)
         {
             for (int k=0; k<Arows; k++)
             {
		qZ1 = q32_fdp_add(qZ1,At[row][k],(B[k]));
             }	
	     AtB[row][col] = q32_to_p32(qZ1);
     	     qZ1 = q32_clr(qZ1);	 		  
         }
     }		 
     
    /********************/
    qZ1 = q32_clr(qZ1);	 		  
    posit32_t AtAInv[2][2];
    posit32_t Vpt[2][1];
    posit32_t det = p32_sub(p32_mul(AtA[0][0],AtA[1][1]),p32_mul(AtA[0][1],AtA[1][0]));
    if (convertP32ToDouble(det) != 0)
    {					
        AtAInv[0][0] = p32_div(AtA[1][1],det);
        AtAInv[0][1] = p32_div(p32_mul(convertDoubleToP32(-1),AtA[0][1]),det);
        AtAInv[1][0] = p32_div(p32_mul(convertDoubleToP32(-1),AtA[1][0]),det);
        AtAInv[1][1] = p32_div(AtA[0][0],det);
        
        for (int row = 0; row < 2; row++)
         {
             for (int col = 0; col < 1; col++)
             {
                 for (int k=0; k<2; k++)
                 {
                     qZ1 = q32_fdp_add(qZ1,AtAInv[row][k],AtB[k][col]);
             	}	
	     Vpt[row][col] = q32_to_p32(qZ1);
     	     qZ1 = q32_clr(qZ1);					  
             }
         }
         
         V[i][0] = (Vpt[0][0]);
         V[i][1] = (Vpt[0][1]);
    }
    else 
    {
        V[i][0] = convertDoubleToP32(0);
        V[i][1] = convertDoubleToP32(0);
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

	 posit32_t Iold[Y][X];
	 posit32_t Inew[Y][X];
	 
	 for (int i=0; i<Y; i++)
	 {
		 for (int j=0; j<X; j++)
		 {
			 fscanf(imgFile, "%e", &Iold_f[i][j]);
			 if(normalise == 0)
			 	Iold[i][j] = convertDoubleToP32(Iold_f[i][j]);
			 else
			  	Iold[i][j] = convertDoubleToP32(Iold_f[i][j]*16.0/255.0);
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
	 
	 posit32_t V[length][2];
	 posit32_t A[kernelSize*kernelSize][2];
	 posit32_t B[kernelSize*kernelSize];
	 
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
				 	Inew[i][j] = convertDoubleToP32(Inew_f[i][j]);
				  else
			 	 	Inew[i][j] = convertDoubleToP32(Inew_f[i][j]*16.0/255.0);
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
             velFile = fopen("vel_p5_322.txt", "w");
             fprintf(velFile, "%d\t%d\n", length, fileCount);
		 }
         else 
         {
             velFile = fopen("vel_p5_322.txt", "a");
             fprintf(velFile, "\n");
         }
         
		 for (int i=0; i<length; i++)
		 {
			 if (i == length - 1)
             {
                fprintf(velFile, "%10.64f\t", convertP32ToDouble(V[i][0]));
                fprintf(velFile, "%10.64f", convertP32ToDouble(V[i][1]));
                break;
             }
             fprintf(velFile, "%10.64f\t", convertP32ToDouble(V[i][0]));
		fprintf(velFile, "%10.64f\n", convertP32ToDouble(V[i][1]));
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

