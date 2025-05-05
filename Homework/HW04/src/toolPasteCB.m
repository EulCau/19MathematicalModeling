function toolPasteCB(mixing)
    persistent blendListener

    if ~isempty(blendListener) && isvalid(blendListener)
        delete(blendListener);
    end

    clear blendImagePoisson

    hpolys = evalin('base', 'hpolys');

    if length(hpolys) >= 2
        updateBlendLive(mixing)

        movedOnce = false;
        blendListener = addlistener(hpolys(2), 'MovingROI', @(src, evt) update(src, evt, mixing));
        addlistener(hpolys(2), 'ROIMoved', @(src, evt) onMoveEnd(src, evt));
    end

    function update(src, ~, mixing)
        if ~movedOnce
            set(src, 'Visible', 'off');
            movedOnce = true;
        end
        updateBlendLive(mixing);
    end

    function onMoveEnd(src, ~)
        set(src, 'Visible', 'on');
        movedOnce = false;
    end
end
