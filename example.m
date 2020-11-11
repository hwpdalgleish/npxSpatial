%% Load data
% Load pos and spk. Convert spk to tet format
KsDir = '/Users/henrydalgleish/Documents/Data/SWC/misc/OpenField_CrossTask/m4349/OpenField/2020-03-13_10-19-43';
npx = loadNpx(KsDir);
npx = processNpx(npx);
npx = npx2tet(npx);

%% Plot a ratemap and polar plot
unit = 475;
smthRm = easy_make_ratemap_npx(npx,1,unit,'smoothKern','gauss','smoothWidth',2);
smthDir = easy_make_polarplot_npx(npx,1,unit,'smoothWidth',2);

figure
subplot(1,2,1)
image_rm(smthRm,'jet')
subplot(1,2,2)
polarplot(smthDir)