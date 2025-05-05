function imdst = blendImagePoisson(im1, im2, roi, target, mixing)
    % 生成 mask 并计算 bounding box
    mask = poly2mask(roi(:,1), roi(:,2), size(im2,1), size(im2,2));
    bbox = round(regionprops(mask, 'BoundingBox').BoundingBox);
    x1 = bbox(1); y1 = bbox(2);
    w = bbox(3); h = bbox(4);

    % 提取 ROI 和掩码
    src_crop = im2(y1:y1+h-1, x1:x1+w-1, :);
    dst_int = im1;
    local_mask = mask(y1:y1+h-1, x1:x1+w-1);

    % 构造像素索引映射
    [Y, X] = find(local_mask);
    numPix = length(X);
    idxMap = zeros(h, w);
    for k = 1:numPix
        idxMap(Y(k), X(k)) = k;
    end

    persistent L U P Q R cachedNumPix

    if isempty(cachedNumPix)
        maxNZ = numPix * 5;
        I = zeros(maxNZ,1); J = zeros(maxNZ,1); V = zeros(maxNZ,1);
        idx_count = 0;
        dirs = [0 1; 0 -1; 1 0; -1 0];

        for k = 1:numPix
            i = Y(k); j = X(k);
            idx_count = idx_count + 1;
            I(idx_count) = k; J(idx_count) = k; V(idx_count) = 4;
            for d = 1:4
                ni = i + dirs(d,1);
                nj = j + dirs(d,2);
                if ni >= 1 && ni <= h && nj >= 1 && nj <= w
                    neighborIdx = idxMap(ni, nj);
                    if neighborIdx > 0
                        idx_count = idx_count + 1;
                        I(idx_count) = k;
                        J(idx_count) = neighborIdx;
                        V(idx_count) = -1;
                    end
                end
            end
        end

        A = sparse(I(1:idx_count), J(1:idx_count), V(1:idx_count), numPix, numPix);
        [L, U, P, Q, R] = lu(A);  % 预分解
        cachedNumPix = numPix;
    end

    % 计算 target 中的对应位置偏移
    offset = round(target(1,:) - roi(1,:));
    x0 = x1 + offset(1);
    y0 = y1 + offset(2);

    dirs = [0 1; 0 -1; 1 0; -1 0];  % 方向重复使用

    % 三通道处理
    for c = 1:3
        b = zeros(numPix, 1);
        src = double(src_crop(:,:,c));
        dst = double(dst_int(:,:,c));

        % 组装右侧向量
        for k = 1:numPix
            i = Y(k); j = X(k);
            grad_div = 0;
            for d = 1:4
                ni = i + dirs(d,1);
                nj = j + dirs(d,2);
                if ni >= 1 && ni <= h && nj >= 1 && nj <= w && idxMap(ni,nj) > 0
                    if mixing
                        g_src = src(i,j) - src(ni,nj);
                        g_dst = dst(y0+i-1, x0+j-1) - dst(y0+ni-1, x0+nj-1);
                        grad_div = grad_div + (abs(g_src) > abs(g_dst)) * g_src + (abs(g_src) <= abs(g_dst)) * g_dst;
                    else
                        grad_div = grad_div + src(i,j) - src(ni,nj);
                    end
                else
                    xi = x0 + nj - 1;
                    yi = y0 + ni - 1;
                    if xi >= 1 && xi <= size(dst,2) && yi >= 1 && yi <= size(dst,1)
                        grad_div = grad_div + dst(yi, xi);
                    end
                end
            end

            b(k) = grad_div;
        end

        % 使用预分解求解线性系统
        u = Q * (U \ (L \ (P * (R \ b))));

        % 写入目标图像
        for k = 1:numPix
            i = Y(k); j = X(k);
            dst_int(y0+i-1, x0+j-1, c) = uint8(round(min(max(u(k), 0), 255)));
        end
    end

    imdst = dst_int;
end
