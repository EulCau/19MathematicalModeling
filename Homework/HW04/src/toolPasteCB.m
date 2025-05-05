function toolPasteCB(mixing)
    persistent blendListener

    if ~isempty(blendListener) && isvalid(blendListener)
        delete(blendListener);
    end

    clear blendImagePoisson
    updateBlendLive(mixing)

    hpolys = evalin('base', 'hpolys');
    blendListener = addlistener(hpolys(2), 'MovingROI', @(src, evt) updateBlendLive(mixing));
end
