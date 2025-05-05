function updateBlendLive(mixing)
    hpolys = evalin('base', 'hpolys');
    im1 = evalin('base', 'im1');
    im2 = evalin('base', 'im2');
    himg = evalin('base', 'himg');

    roi = hpolys(1).Position();
    targetPosition = roi + ceil(hpolys(2).Position - roi);

    imdst = blendImagePoisson(im1, im2, roi, targetPosition, mixing);
    set(himg, 'CData', imdst);
end
