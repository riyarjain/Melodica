 #include <stdio.h>	 
 
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
 
 void buildA (float img[Y][X], int centerX, int centerY, int kernelSize, float A[][2])
 {
	 int mean = kernelSize/2;
	 int count = 0;
	 float  home = img[centerY][centerX];
	 float Ax, Ay;
	 
	 for (int j = -mean; j<mean + 1; j++)
	 {
		 for (int i = -mean; i<mean + 1; i++)
		 {
			 if (i == 0) Ax = 0;
			 else Ax = ((float)home - (float)img[centerY + j][centerX + i])/(float)i;
			 if (j == 0) Ay = 0;
			 else Ay = ((float)home - (float)img[centerY + j][centerX + i])/(float)j;
			 
			 A[count][0] = Ay;
			 A[count][1] = Ax;
			 count++;
		 }
	 }
 }
 
 void buildB (float imgNew[Y][X], float imgOld[Y][X], int centerX, int centerY, int kernelSize, float B[])
 {
	 int mean = kernelSize/2;
	 int count = 0;
	 int  home = imgNew[centerY][centerX];
	 float Bt;
	 
	 for (int j = -mean; j < mean + 1; j++)
	 {
		 for (int i = -mean; i < mean + 1; i++)
		 {
			 Bt = imgNew[centerY + j][centerX + i] - imgOld[centerY + j][centerX + i];
			 B[count] = Bt;
			 count++;
		 }
	 }
 }
 
 void calcV(float A[][2], float B[], float V[][2], int kernelSize, int i)
 {
     int Arows = kernelSize * kernelSize;
     float At[2][Arows];
     for (int row = 0; row < Arows; row++)
     {
         for (int col = 0; col < 2; col++)
         {
             At[col][row] = A[row][col];
         }
     }			 
     
     /********************/
     
     float AtA[2][2] = {0};			 
     for (int row = 0; row < 2; row++)
     {
         for (int col = 0; col < 2; col++)
         {
             for (int k=0; k<Arows; k++)
             {
                 AtA[row][col] += At[row][k]*A[k][col];					
             }					  
         }
     }		 
                 
    
     float AtB[2][1] = {0};			 
     for (int row = 0; row < 2; row++)
     {
         for (int col = 0; col < 1; col++)
         {
             for (int k=0; k<Arows; k++)
             {
                 AtB[row][col] += At[row][k]*B[k];					
             }					  
         }
     }
     
    /********************/

    float AtAInv[2][2];
    float Vpt[2][1] = {0};
    float det = (AtA[0][0]*AtA[1][1])-(AtA[0][1]*AtA[1][0]);
    
    if (det != 0)
    {					
        AtAInv[0][0] = AtA[1][1]/det;
        AtAInv[0][1] = -AtA[0][1]/det;
        AtAInv[1][0] = -AtA[1][0]/det;
        AtAInv[1][1] = AtA[0][0]/det;
        
        for (int row = 0; row < 2; row++)
         {
             for (int col = 0; col < 1; col++)
             {
                 for (int k=0; k<2; k++)
                 {
                     Vpt[row][col] += AtAInv[row][k]*AtB[k][col];					
                 }					  
             }
         }
         
         V[i][0] = Vpt[0][0];
         V[i][1] = Vpt[0][1];
    }
    else 
    {
        V[i][0] = 0;
        V[i][1] = 0;
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
	 
	 float Iold[Y][X];
	 float Inew[Y][X];
	 
	 for (int i=0; i<Y; i++)
	 {
		 for (int j=0; j<X; j++)
		 {
			 fscanf(imgFile, "%e", &Iold[i][j]);
			 //Iold[i][j] = Iold[i][j]*16/255;
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
	 
	 float V[length][2];
	 float A[kernelSize*kernelSize][2];
	 float B[kernelSize*kernelSize];
	 
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
				 fscanf(imgFile, "%e", &Inew[i][j]);
				 //Inew[i][j] = Inew[i][j]*16/255;
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
             velFile = fopen("vel_f.txt", "w");
             fprintf(velFile, "%d\t%d\n", length, fileCount);
		 }
         else 
         {
             velFile = fopen("vel_f.txt", "a");
             fprintf(velFile, "\n");
         }
         
		 for (int i=0; i<length; i++)
		 {
			 if (i == length - 1)
             {
                fprintf(velFile, "%10.64f\t", V[i][0]);
                fprintf(velFile, "%10.64f", V[i][1]);
                break;
             }
             fprintf(velFile, "%10.64f\t", V[i][0]);
			 fprintf(velFile, "%10.64f\n", V[i][1]);
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

