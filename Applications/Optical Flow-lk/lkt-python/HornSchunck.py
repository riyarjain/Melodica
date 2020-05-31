#!/usr/bin/env python
"""
examples:

./HornSchunck.py data/box/box
./HornSchunck.py data/office/office
./HornSchunck.py data/rubic/rubic
./HornSchunck.py data/sphere/sphere

"""
from __future__ import division
import numpy as np
from matplotlib import pyplot as plt
from scipy.ndimage.filters import gaussian_filter
from scipy.ndimage.filters import convolve as filter2
from scipy.ndimage import imread
#
from pyOpticalFlow import getimgfiles

FILTER = 7
QUIVER = 5

def HS(im1, im2, alpha, Niter):
    """
    im1: image at t=0
    im2: image at t=1
    alpha: regularization constant
    Niter: number of iteration
    """

	#set up initial velocities
    uInitial = np.zeros([im1.shape[0],im1.shape[1]])
    vInitial = np.zeros([im1.shape[0],im1.shape[1]])

	# Set initial value for the flow vectors
    U = uInitial
    V = vInitial

	# Estimate derivatives
    [fx, fy, ft] = computeDerivatives(im1, im2)

    fg,ax = plt.subplots(1,3,figsize=(18,5))
    for f,a,t in zip((fx,fy,ft),ax,('$f_x$','$f_y$','$f_t$')):
        h=a.imshow(f,cmap='bwr')
        a.set_title(t)
        fg.colorbar(h,ax=a)

	# Averaging kernel
    kernel=np.array([[1/12, 1/6, 1/12],
                      [1/6,    0, 1/6],
                      [1/12, 1/6, 1/12]],float)

    print(fx[100,100],fy[100,100],ft[100,100])

	# Iteration to reduce error
    for _ in range(Niter):
#%% Compute local averages of the flow vectors
        uAvg = filter2(U,kernel)
        vAvg = filter2(V,kernel)
#%% common part of update step
        der = (fx*uAvg + fy*vAvg + ft) / (alpha**2 + fx**2 + fy**2)
#%% iterative step
        U = uAvg - fx * der
        V = vAvg - fy * der

    return U,V

def computeDerivatives(im1, im2):
#%% build kernels for calculating derivatives
    kernelX = np.array([[-1, 1],
                         [-1, 1]]) * .25 #kernel for computing d/dx
    kernelY = np.array([[-1,-1],
                         [ 1, 1]]) * .25 #kernel for computing d/dy
    kernelT = np.ones((2,2))*.25

    fx = filter2(im1,kernelX) + filter2(im2,kernelX)
    fy = filter2(im1,kernelY) + filter2(im2,kernelY)

    #ft = im2 - im1
    ft = filter2(im1,kernelT) + filter2(im2,-kernelT)

    return fx,fy,ft

def compareGraphs(u,v,Inew,scale=3):
    """
    makes quiver
    """
    ax = plt.figure().gca()
    ax.imshow(Inew,cmap = 'gray')
    # plt.scatter(POI[:,0,1],POI[:,0,0])
    for i in range(0,len(u),QUIVER):
        for j in range(0,len(v),QUIVER):
            ax.arrow(j,i, v[i,j]*scale, u[i,j]*scale, color='red')

	# plt.arrow(POI[:,0,0],POI[:,0,1],0,-5)

    plt.draw(); plt.pause(0.01)

def demo(stem):
    flist,ext = getimgfiles(stem)

    for i in range(len(flist)-1):
        fn1 = str(stem) +'.'+ str(i) + ext
        Iold = imread(fn1,flatten=True).astype(float)  #flatten=True is rgb2gray
        Iold = gaussian_filter(Iold,FILTER)

        fn2 = str(stem) + '.' + str(i+1) + ext
        Inew = imread(fn2,flatten=True).astype(float)
        Inew = gaussian_filter(Inew,FILTER)
        #plt.imshow(imgNew)
        #plt.title('new image')

        [U,V] = HS(Iold, Inew, 1, 100)
        compareGraphs(U,V,Inew)


    return U,V


if __name__ == '__main__':
    from argparse import ArgumentParser
    p = ArgumentParser(description='Pure Python Horn Schunck Optical Flow')
    p.add_argument('stem',help='path/stem of files to analyze')
    p = p.parse_args()

    U,V = demo(p.stem)

    plt.show()
