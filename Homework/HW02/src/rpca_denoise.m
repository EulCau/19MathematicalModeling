% Robust PCA for image denoising in MATLAB with simple GUI

function rpca_denoise()
    figure('Name', 'RPCA Image Denoising', 'NumberTitle', 'off', ...
                 'Position', [100, 100, 1200, 400]);
    
    handles.img = [];
    handles.L = [];
    handles.S = [];
    
    handles.ax1 = axes('Units', 'pixels', 'Position', [50, 50, 300, 250]);
    handles.ax2 = axes('Units', 'pixels', 'Position', [450, 50, 300, 250]);
    handles.ax3 = axes('Units', 'pixels', 'Position', [850, 50, 300, 250]);
    
    uicontrol('Style', 'pushbutton', 'String', 'Load Image', ...
              'Position', [50, 350, 100, 30], ...
              'Callback', @(src, event) load_image(src, event, handles));
    
    uicontrol('Style', 'pushbutton', 'String', 'RPCA with each color', ...
              'Position', [200, 350, 100, 30], ...
              'Callback', @(src, event) run_rpca_1(src, event, handles));
    
    uicontrol('Style', 'pushbutton', 'String', 'Save Result', ...
              'Position', [350, 350, 100, 30], ...
              'Callback', @(src, event) save_result(src, event, handles));
end

function load_image(~, ~, handles)
    [file, path] = uigetfile({'*.png;*.jpg;*.bmp', 'Images'});
    if file
        handles.img = im2double(imread(fullfile(path, file)));
        imshow(handles.img, 'Parent', handles.ax1);
        title(handles.ax1, 'Original Image');
        guidata(handles.ax1, handles);
    end
end

function run_rpca_1(~, ~, handles)
    handles = guidata(handles.ax1);
    if isempty(handles.img)
        errordlg('Please load an image first!', 'Error');
        return;
    end
    [m, n, c] = size(handles.img);
    lambda = 1 / max(m, n);
    
    handles.L = zeros(size(handles.img));
    handles.S = zeros(size(handles.img));
    
    for i = 1:c
        [handles.L(:,:,i), handles.S(:,:,i)] = rpca(handles.img(:,:,i), lambda);
    end
    
    imshow(handles.L, 'Parent', handles.ax2);
    title(handles.ax2, 'Denoised Image');
    
    imshow(handles.S, 'Parent', handles.ax3);
    title(handles.ax3, 'Noise Component');
    
    guidata(handles.ax1, handles);
end

function run_rpca_2(~, ~, handles)
    handles = guidata(handles.ax1);
    if isempty(handles.img)
        errordlg('Please load an image first!', 'Error');
        return;
    end
    [m, n, c] = size(handles.img);
    lambda = 1 / max(m, n);
    
    handles.L = zeros(size(handles.img));
    handles.S = zeros(size(handles.img));
    A = zeros(size(handles.img));
    
    for i = 1:c
        A = A .* 256;
        A = A + handles.img(:,:,i);
    end

    [handles.L(:,:,i), handles.S(:,:,i)] = rpca(A, lambda);
    
    imshow(handles.L, 'Parent', handles.ax2);
    title(handles.ax2, 'Denoised Image');
    
    imshow(handles.S, 'Parent', handles.ax3);
    title(handles.ax3, 'Noise Component');
    
    guidata(handles.ax1, handles);
end

function save_result(~, ~, handles)
    handles = guidata(handles.ax1);
    if isempty(handles.L)
        errordlg('No result to save!', 'Error');
        return;
    end
    [file, path] = uiputfile({'*.png', 'PNG Image'; '*.jpg', 'JPEG Image'});
    if file
        imwrite(handles.L, fullfile(path, file));
    end
end

function [L,S] = rpca(A, lambda)
    tol = 1e-7;               % 收敛容忍度
    maxIter = 1000;           % 最大迭代次数
    [m, n] = size(A);
    mu = 1.25 / norm(A,2);    % 初始化 mu, norm(A,2) 为 A 的谱范数
    mu_bar = mu * 1e7;
    rho = 1.5;                % mu 的更新因子

    % 初始化变量
    L = zeros(m,n);
    S = zeros(m,n);
    Y = zeros(m,n);           % 拉格朗日乘子

    iter = 0;
    % 迭代更新
    while iter < maxIter
        iter = iter + 1;
    
        % 更新 L，使用奇异值阈值处理
        % 求解：min_{L} ||L||_* + (mu/2)*||L - (A - S + (1/mu)*Y)||_F^2
        temp = A - S + (1/mu)*Y;
        [U, Sigma, V] = svd(temp, 'econ');
        Sigma_thresh = diag(Sigma) - 1/mu;
        Sigma_thresh = max(Sigma_thresh, 0);
        L = U * diag(Sigma_thresh) * V';
    
        % 更新 S，使用软阈值函数
        % 求解：min_{S} lambda||S||_1 + (mu/2)*||S - (A - L + (1/mu)*Y)||_F^2
        temp = A - L + (1/mu)*Y;
        S = sign(temp) .* max(abs(temp) - lambda/mu, 0);
    
        % 更新拉格朗日乘子 Y
        residual = A - L - S;
        Y = Y + mu * residual;
    
        % 检查收敛条件
        err = norm(residual, 'fro') / norm(A, 'fro');
        if err < tol
            break;
        end
    
        % 更新 mu
        mu = min(mu*rho, mu_bar);
    
        % 显示每次迭代的信息（可选）
        if mod(iter, 50) == 0
            fprintf('Iteration %d, error = %e\n', iter, err);
        end
    end

    fprintf('算法迭代结束，共进行 %d 次迭代，最终误差 %e\n', iter, err);

end

