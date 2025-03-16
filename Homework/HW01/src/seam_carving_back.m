%   Copyright © 2025, Renjie Chen @ USTC


%% read image
pic_name = "pic1";
pic_type = "jpg";
path_read = "../data/" + pic_name + "_source." + pic_type;
path_write = "../data/" + pic_name + "_result_back." + pic_type;
im = imread(path_read);

%% draw 2 copies of the image
fig=figure('Units', 'pixel', 'Position', [100,100,1000,700], 'toolbar', 'none');
subplot(1,2,1); imshow(im); title({'Input image'});
subplot(1,2,2); himg = imshow(im*0); title({'Resized Image', 'Use the blue button to resize the input image'});
hToolResize = uipushtool('CData', reshape(repmat([0 0 1], 100, 1), [10 10 3]), 'TooltipString', 'apply seam carving method to resize image', ...
                        'ClickedCallback', @(~, ~) set(himg, 'cdata', seam_carve_image(im, size(im,1:2)+[100 -100], path_write)));

function im = seam_carve_image(im, sz, pw)
    % 计算目标尺寸
    target_cols = sz(2);
    target_rows = sz(1);
    
    % 计算需要插入或删除的列数与行数
    col_diff = target_cols - size(im, 2);
    row_diff = target_rows - size(im, 1);

    % 定义能量计算函数（基于拉普拉斯算子）
    costfunction = @(im) sum( imfilter(im, [.5 1 .5; 1 -6 1; .5 1 .5]).^2, 3 );

    % 如果目标宽度大于当前宽度，进行插入列操作，否则进行移除操作
    for i = 1:abs(col_diff)
        G = costfunction(im);
        seam = find_vertical_seam(G);
        if col_diff > 0
            im = insert_vertical_seam(im, seam);
        elseif col_diff < 0
            im = remove_vertical_seam(im, seam);
        end
    end

    % 对高度做同样的操作
    im = permute(im, [2, 1, 3]); % 转置图像
    for i = 1:abs(row_diff)
        G = costfunction(im);
        seam = find_vertical_seam(G);
        if row_diff > 0
            im = insert_vertical_seam(im, seam);
        elseif row_diff < 0
            im = remove_vertical_seam(im, seam);
        end
    end
    im = permute(im, [2, 1, 3]); % 转置回来
    imwrite(im, pw);
end

function seam = find_vertical_seam(G)
    [rows, cols] = size(G);
    M = G;  % 累积能量矩阵
    seam = zeros(rows, 1);

    % 计算 M：动态规划求累积能量最小路径
    for r = 2:rows
        for c = 1:cols
            if c == 1
                M(r, c) = G(r, c) + min([M(r-1, c), M(r-1, c+1)]);
            elseif c == cols
                M(r, c) = G(r, c) + min([M(r-1, c-1), M(r-1, c)]);
            else
                M(r, c) = G(r, c) + min([M(r-1, c-1), M(r-1, c), M(r-1, c+1)]);
            end
        end
    end


    % 反向追踪最优接缝
    [~, seam(rows)] = min(M(rows,:));  % 选取最后一行的最小值起点
    for r = rows-1:-1:1
        c = seam(r+1);
        if c == 1
            [~, idx] = min([M(r,c), M(r,c+1)]);
            idx = idx - 1;
        elseif c == cols
            [~, idx] = min([M(r,c-1), M(r,c)]);
            idx = idx - 2;
        else
            [~, idx] = min([M(r,c-1), M(r,c), M(r,c+1)]);
            idx = idx - 2;
        end
            seam(r) = c + idx;
    end
end

function im = remove_vertical_seam(im, seam)
    [rows, cols, channels] = size(im);
    new_im = zeros(rows, cols-1, channels, 'uint8');

    for r = 1:rows
        c = seam(r);
        new_im(r, :, :) = [im(r, 1:c-1, :), im(r, c+1:end, :)];  % 删除接缝
    end

    im = new_im;
end

function im = insert_vertical_seam(im, seam)
    [rows, cols, ch] = size(im);
    new_im = zeros(rows, cols + 1, ch, 'uint8');
    
    for i = 1:rows
        c = seam(i);
        for j = 1:ch
            % 复制原像素
            new_im(i, 1:c, j) = im(i, 1:c, j);
            new_im(i, c+2:end, j) = im(i, c+1:end, j);
            
            % 插入新列，像素值取相邻像素均值
            if c == 1
                new_im(i, c+1, j) = im(i, c, j);
            elseif c == cols
                new_im(i, c+1, j) = im(i, c, j);
            else
                new_im(i, c+1, j) = uint8((double(im(i, c, j)) + double(im(i, c+1, j))) / 2);
            end
        end
    end
    im = new_im;
end
