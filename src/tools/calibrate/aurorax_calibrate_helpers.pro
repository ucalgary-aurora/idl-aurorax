function __perform_dark_frame_calibration, images, size
    ; This method will perform a dark frame correction by subtracting an average
    ; of a bottom corner grid from the image (ie. 4x4.).

    ; NOTE: This is an internal-only used function. It is not publicly exposed.
    
    original_dtype = (size(images))[-2]
    
    ; Add dimension if it's a single frame
    if n_elements(size(images,/dimensions)) eq 2 then begin
        images = reform(images, (size(images,/dimensions))[0], (size(images,/dimensions))[1], 1)
    endif
    
    ; Extract NxN box from lower left corner, compute means
    dark_means = ulong(mean(mean(images[0:size-1, 0:size-1, *], dimension=1), dimension=1))

    ; apply
    ;
    ; NOTE: we convert to int32 to avoid lower-bound rollover and allow
    ; for negative numbers, which we then cast to 0 and convert back to
    ; the native dtype.
    ;

    new_images = long(images)
    for i=0, (size(new_images,/dimensions))[-1]-1 do begin
        new_images[*,*,i] = new_images[*,*,i] - dark_means[i]
    endfor
    new_images[where(new_images lt 0)] = 0
    images[*,*,*] = new_images[*,*,*]
    
    ; If image was single frame to start, remove extra axis    
    return, reform(images)
    
end


function __perform_flatfield_calibration, images, cal_flatfield
    
    ; Add dimension if it's a single frame
    if n_elements(size(images,/dimensions)) eq 2 then begin
        images = reform(images, (size(images,/dimensions))[0], (size(images,/dimensions))[1], 1)
    endif
    
    ; for each image, apply multiplier
    for i=0, (size(images,/dimensions))[-1]-1 do begin
        images[*,*,i] = images[*,*,i] * cal_flatfield.flat_field_multiplier
    endfor
    
    ; remove single frame axis if one was added
    return, reform(images)
end


function __perform_rayleighs_calibration, images, cal_rayleighs, exposure_length_sec
    
    ; Add dimension if it's a single frame
    if n_elements(size(images,/dimensions)) eq 2 then begin
        images = reform(images, (size(images,/dimensions))[0], (size(images,/dimensions))[1], 1)
    endif
    
    ; convert types to maintin precision
    images = float(images)
    exposure_length_sec = float(exposure_length_sec)
    
    ; apply rayleighs conversion
    images = (images * cal_rayleighs.rayleighs_perdn_persecond) / exposure_length_sec
    
    ; remove single frame axis if one was added
    return, reform(images)
    
end
    
    
    
    