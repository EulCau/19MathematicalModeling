function toolSaveCB(~, ~)
    ax = subplot(122);  
    himgChildren = get(ax, 'Children');

    imgHandle = [];
    for i = 1:length(himgChildren)
        if strcmp(get(himgChildren(i), 'Type'), 'image')
            imgHandle = himgChildren(i);
            break;
        end
    end

    if isempty(imgHandle)
        errordlg('No image found in subplot 122.', 'Error');
        return;
    end

    imgData = get(imgHandle, 'CData');

    [file, path] = uiputfile({'*.jpg'; '*.png'; '*.bmp'}, 'Save Image As');
    if ischar(file)
        imwrite(imgData, fullfile(path, file));
        msgbox('Image saved successfully!', 'Success');
    end
end
