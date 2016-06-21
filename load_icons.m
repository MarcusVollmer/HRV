% ICONS for HRVTool
origin = ['icons' filesep '16' filesep 'all' filesep];
folder = dir([origin '*.png']);
icons = struct;

for i=1:size(folder,1)
    
    pic_black = importdata([origin folder(i).name]);
    pic_color = double(importdata([origin 'color' filesep folder(i).name]));
    
    icons.(matlab.lang.makeValidName(folder(i).name(1:end-4))) = NaN(16,16,3);
    icons.(matlab.lang.makeValidName(folder(i).name(1:end-4)))(pic_black<240) =...
        pic_color(pic_black<240)/255;
    
end
