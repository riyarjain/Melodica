function RunHornSchunck(stem)

im1 = imread('../data/box/box.0.bmp');
im2 = imread('../data/box/box.1.bmp');

figure(1)
HornSchunck(im1, im2);
%% compare to Matlab CV Toolbox
try
    figure(2)
    opticFlow = opticalFlowHS;
    estimateFlow(opticFlow,im1);
    flow = estimateFlow(opticFlow,im2);

    imshow(im2)
    hold on
    plot(flow,'DecimationFactor',[5 5],'ScaleFactor',25)
end  
%% compare to pure Python
try
   system('python ../HornSchunck.py ../data/box/box')
end
end