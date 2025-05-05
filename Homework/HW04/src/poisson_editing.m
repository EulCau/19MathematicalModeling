[dstFile, dstPath] = uigetfile({'*.png;*.jpg;*.bmp', '图像文件'}, '选择目标图像');
if isequal(dstFile, 0)
    error('未选择目标图像');
end
im1 = imread(fullfile(dstPath, dstFile));

[srcFile, srcPath] = uigetfile({'*.png;*.jpg;*.bmp', '图像文件'}, '选择源图像');
if isequal(srcFile, 0)
    error('未选择源图像');
end
im2 = imread(fullfile(srcPath, srcFile));

figure('Units', 'pixel', 'Position',...
    [100,100,1000,700], 'toolbar', 'none');

subplot(121);
imshow(im2);
title({'Foreground',...
    'press red tool button to mark polygon as copying region'});

subplot(122);
himg = imshow(im1);
title({'Background',...
    'press blue tool button to compute blended image'});

hpolys = [];

hToolMark = uipushtool(...
    'CData', reshape(repmat([1 0 0], 100, 1), [10 10 3]),...
    'TooltipString', 'define copying region on the foreground image',...
    'ClickedCallback', @toolMarkCB);

hToolWarp = uipushtool(...
    'CData', reshape(repmat([1 0 1], 100, 1), [10 10 3]),...
    'TooltipString', 'compute blended image',...
    'ClickedCallback', @(src, evt)toolPasteCB(false));

hToolWarpMix = uipushtool(...
    'CData', reshape(repmat([0 1 1], 100, 1), [10 10 3]),...
    'TooltipString', 'compute blended image with mixing gradients',...
    'ClickedCallback', @(src, evt)toolPasteCB(true));

hToolShowROI = uipushtool(...
    'CData', reshape(repmat([0 0 1], 100, 1), [10 10 3]),...
    'TooltipString', 'Show ROI polygon',...
    'ClickedCallback', @(src, evt) showROICB());

hToolSave = uipushtool(...
    'CData', reshape(repmat([0 1 0], 100, 1), [10 10 3]),...
    'TooltipString', 'save blended image to file',...
    'ClickedCallback', @toolSaveCB);

function showROICB()
    persistent showed
    if isempty(showed)
        showed = true;
    end
    hpolys = evalin('base', 'hpolys');
    if length(hpolys) >= 2
        if showed
            set(hpolys(2), 'Visible', 'off');
            showed = false;
        else
            set(hpolys(2), 'Visible', 'on');
            showed = true;
        end
    end
end
