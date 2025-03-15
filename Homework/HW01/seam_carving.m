%   Copyright © 2025, Renjie Chen @ USTC


%% read image
im = imread('peppers.png');

%% draw 2 copies of the image
fig=figure('Units', 'pixel', 'Position', [100,100,1000,700], 'toolbar', 'none');
subplot(1,2,1); imshow(im); title({'Input image'});
subplot(1,2,2); himg = imshow(im*0); title({'Resized Image', 'Use the blue button to resize the input image'});
hToolResize = uipushtool('CData', reshape(repmat([0 0 1], 100, 1), [10 10 3]), 'TooltipString', 'apply seam carving method to resize image', ...
                        'ClickedCallback', @(~, ~) set(himg, 'cdata', seam_carve_image(im, size(im,1:2)-[0 300])));

%% TODO: implement function: seam_carve_image
% check the title above the image for how to use the user-interface to resize the input image
function im = seam_carve_image(im, sz)
    % 计算需要移除的列数
    num_seams = size(im,2) - sz(2);
    
    % 能量计算函数
    costfunction = @(im) sum( imfilter(im, [.5 1 .5; 1 -6 1; .5 1 .5]).^2, 3 );

    for i = 1:num_seams
        % 计算能量图
        G = costfunction(im);
        
        % 计算累积能量图（Dynamic Programming）
        M = G;
        [rows, cols] = size(G);
        for r = 2:rows
            for c = 1:cols
                if c == 1
                    M(r,c) = G(r,c) + min([M(r-1,c), M(r-1,c+1)]);
                elseif c == cols
                    M(r,c) = G(r,c) + min([M(r-1,c-1), M(r-1,c)]);
                else
                    M(r,c) = G(r,c) + min([M(r-1,c-1), M(r-1,c), M(r-1,c+1)]);
                end
            end
        end

        % 追踪最优接缝路径
        seam = zeros(rows,1);
        [~, seam(rows)] = min(M(rows,:));  % 选取最后一行的最小值起点
        for r = rows-1:-1:1
            c = seam(r+1);
            if c == 1
                [~, idx] = min([M(r,c), M(r,c+1)]);
            elseif c == cols
                [~, idx] = min([M(r,c-1), M(r,c)]);
                idx = idx - 1;
            else
                [~, idx] = min([M(r,c-1), M(r,c), M(r,c+1)]);
                idx = idx - 2;
            end
            seam(r) = c + idx;
        end

        % 移除接缝
        for r = 1:rows
            im(r, seam(r):end-1, :) = im(r, seam(r)+1:end, :);
        end
        im = im(:,1:end-1,:); % 裁剪最后一列
    end
end

% im = imresize(im, sz);

costfunction = @(im) sum( imfilter(im, [.5 1 .5; 1 -6 1; .5 1 .5]).^2, 3 );

k = size(im,2) - sz(2);
for i = 1:k
    G = costfunction(im);
    %% find a seam in G

    %% remove seam from im
end
