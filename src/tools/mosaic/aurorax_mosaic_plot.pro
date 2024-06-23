;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_MOSAIC_PLOT
;
; PURPOSE:
;       Create a mosaic
;
; EXPLANATION:
;       Plot a mosaic onto a pre-defined map window, using *prepared*
;       image data and skymaps.
;
; CALLING SEQUENCE:
;       aurorax_mosaic_plot, prepped_data, prepped_skymap, image_idx, min_elevation=5

;
; PARAMETERS:
;       prepped_data          single, or array of 'prepped_data' structures (the return of aurorax_mosaic_prep_data())
;       prepped_skymaps       single, or array of 'prepped_data' structures (the return of aurorax_mosaic_prep_data())
;       frame_idx             integer specifying the frame idx of image data that is to be plotted
;       min_elevation         int/float, or array (same length as prepped_data) of ints/floats specifying the minimum
;                             elevation in degrees to begin plotting data, optional (default is 5 deg)
;       intensity_scales      a two element array, or hash of two element arrays (for scaling on a per-site basis),
;                             giving the min/max scale bounds for data (default is [0,20000])
;       colortable            an integer, or array of integers with the same length as prepped_data, specifying the
;                             IDL colortable to plot data with, optional (default is 0, i.e. gray)
;       elevation_increment   a parameter that affects the plotting algorithm - the default is 0.25 - increasing this
;                             parameter can speed up plotting, and decreasing it can help make boundaries between sites
;                             more distinct (if they appear to be getting blended)
;
; KEYWORDS:
;
; OUTPUT
;
; OUTPUT TYPE:
;
; EXAMPLES:
;       aurorax_mosaic_plot, prepped_data, prepped_skymap, image_idx, min_elevation=7, intensity_scales=[500,10000], colortable=3
;
;+
;-------------------------------------------------------------
pro aurorax_mosaic_plot, prepped_data, prepped_skymaps, frame_idx, min_elevation=min_elevation, intensity_scales=intensity_scales, colortable=colortable, elevation_increment=elevation_increment

  __DEFAULT_SCALE_MIN = 0
  __DEFAULT_SCALE_MAX = 20000
  device, get_decomposed=original_decomp

  ; Check type of prepped_data
  if typename(prepped_data) eq "HASH" then begin
    prepped_data = [prepped_data]
  endif
  if typename(prepped_data[0]) ne "HASH" then begin
    print, "[aurorax_mosaic_plot] Error: 'prepped_data' must be either a hash (return value of aurorax_mosaic_prep_data) or a list/array of hashes.
    goto, error_jump
  endif

  ; Check type of prepped_skymaps
  if typename(prepped_skymaps) eq "HASH" then begin
    prepped_skymaps = [prepped_skymaps]
  endif
  if typename(prepped_skymaps[0]) ne "HASH" then begin
    print, "[aurorax_mosaic_plot] Error: 'prepped_skymaps' must be either a hash (return value of aurorax_mosaic_prep_skymap) or a list/array of hashes.
    goto, error_jump
  endif

  if n_elements(prepped_skymaps) ne  n_elements(prepped_data) then begin
    print, "[aurorax_mosaic_plot] Error: 'prepped_data' and 'prepped_skymaps' must have the same length when entered as lists/arrays."
    goto, error_jump
  endif

  ; Check minimum elevation to match data inputs
  if keyword_set(min_elevation) then begin
    if isa(min_elevation, /scalar) then begin
      ; If scalar, transform to array with same length as data
      if min_elevation lt 0 or min_elevation gt 90 then begin
        print, "[aurorax_mosaic_plot] Error: 'min_elevation' of "+strcompress(string(min_elevation),/remove_all)+" degrees outside the range (0,90)."
        goto, error_jump
      endif
      min_elevation = replicate(min_elevation, n_elements(prepped_skymaps))
    endif else begin
      ; Otherwise, check size
      if n_elements(prepped_data) ne n_elements(min_elevation) then begin
        print, "[aurorax_mosaic_plot] Error: 'min_elevation' must have the same length as 'prepped_data' when entered a list/array."
        goto, error_jump
      endif
      foreach el, min_elevation do begin
        if el lt 0 or el gt 90 then begin
          print, "[aurorax_mosaic_plot] Error: 'min_elevation' of "+strcompress(string(el),/remove_all)+" degrees outside the range (0,90)."
          goto, error_jump
        endif
      endforeach
    endelse
  endif else begin
    ; Default to minimum elevation of 5 degrees
    min_elevation = replicate(5, n_elements(prepped_skymaps))
  endelse

  ; Check colortable to match data inputs
  all_sites_to_plot = []
  for mosaic_data_idx=0, n_elements(prepped_data)-1 do begin
    sites = (prepped_data[mosaic_data_idx])['site_uid']
    foreach site, sites do begin
      if where(site eq all_sites_to_plot, /null) eq !null then all_sites_to_plot = [all_sites_to_plot, site]
    endforeach
  endfor
  if keyword_set(colortable) then begin
    if isa(colortable, /scalar) then begin
      ; If scalar, transform to array with same length as data
      colortable = replicate(colortable, n_elements(prepped_skymaps))
    endif else begin
      ; Otherwise, check size
      if n_elements(prepped_data) ne n_elements(colortable) and n_elements(colortable) ne n_elements(all_sites_to_plot) then begin
        print, "[aurorax_mosaic_plot] Error: 'colortable' must have the same length as 'prepped_data' OR the same length as the " + $
          "total number of sites that are to be plotted when entered as a list/array. Otherwise it should be a scalar."
        goto, error_jump
      endif
    endelse
  endif else begin
    ; Default to greyscale colortable
    colortable = replicate(0, n_elements(prepped_skymaps))
  endelse

  ; Check that ALL site uids match between images and skymaps. This is crucial for order
  for mosaic_data_idx=0, n_elements(prepped_data)-1 do begin
    if not array_equal((prepped_data[mosaic_data_idx])["site_uid"], (prepped_skymaps[mosaic_data_idx])["site_uid"]) then begin
      print, "[aurorax_mosaic_plot] Error: Mismatched site_uid array between prepped_data["+string(mosaic_data_idx, format='(I1.1)') + $
        "] and prepped_skymap["+string(mosaic_data_idx, format='(I1.1)')+"]. Make sure that all image data and skymap data is " + $
        "ordered the same before using as inputs."
      goto, error_jump
    endif
  endfor

  ; Iterate through each set of prepped data/skymaps
  for mosaic_data_idx=0, n_elements(prepped_data)-1 do begin

    ; Extract this iterations data
    data = prepped_data[mosaic_data_idx]
    skymap = prepped_skymaps[mosaic_data_idx]
    min_el = min_elevation[mosaic_data_idx]
    cmap = colortable[mosaic_data_idx]

    ; Get sites - Error will be raised before this point if sites differ in composition or order betweens skymaps and images
    site_list = data['site_uid']

    ; Set the scaling bounds
    if not keyword_set(intensity_scales) then begin
      ; set all sites to default values
      image_intensity_scales = hash()
      foreach site_uid, site_list do begin
        image_intensity_scales[site_uid] = [__DEFAULT_SCALE_MIN, __DEFAULT_SCALE_MAX]
      endforeach
    endif else if isa(intensity_scales, /array) then begin
      if typename(intensity_scales) eq "HASH" then begin
        image_intensity_scales = intensity_scales
      endif else begin
        if n_elements(intensity_scales) ne 2 then begin
          print, "[aurorax_mosaic_plot] Error: Passing a non-hash into 'intensity_scales' requires " + $
            "two elements. For scaling on a per-site basis, please pass a hash of the form 'hash('site_1_uid',[scale_min,scale_max],'site_2_uid',...)'
          goto, error_jump
        endif
        image_intensity_scales_dict = hash()
        foreach site_uid, site_list do begin
          image_intensity_scales_dict[site_uid] = [intensity_scales[0], intensity_scales[1]]
        endforeach
        image_intensity_scales = image_intensity_scales_dict
      endelse
    endif else begin
      print, "[aurorax_mosaic_plot] Error: 'intensity_scales' must be a hash or array like type."
      goto, error_jump
    endelse
    intensity_scales = image_intensity_scales

    ; Initalize object to hold all images
    all_images = hash()

    ; Grab the elevation, and filling lats/lons
    elev = skymap['elevation']
    polyfill_lon = skymap['polyfill_lon']
    polyfill_lat = skymap['polyfill_lat']

    ; Now we begin to fill in the above arrays, one site at a time. Before doing so
    ; we need lists to keep track of which sites actually have data for this frame.
    sites_with_data = []
    sites_with_data_idx = []

    ; We also define a list that will hold all unique timestamps pulled from each
    ; frame's metadata. This should be of length 1, and we can check that to make
    ; sure all images being plotted correspond to the same time.
    unique_timestamps = []
    n_channels_dict = hash()
    foreach site, site_list do begin
      ; set image dimensions
      width = ((data['images_dimensions'])[site])[0]
      height = ((data['images_dimensions'])[site])[1]

      ; Grab the timestamp for this frame/site, and determine n_channels
      meta_timestamp = (data['timestamps'])[frame_idx]
      if (size((data['images'])[site], /dimensions))[0] eq 3 then begin
        n_channels = 3
      endif else begin
        n_channels = 1
      endelse
      n_channels_dict[site] = n_channels

      ; Now, obtain the frame of interest, for this site, from the image data and flatten it
      if n_channels eq 1 then begin
        img = ((data['images'])[site])[*,*,frame_idx]
        flattened_img = reform(img, width * height)
        tmp = flattened_img
      endif else begin
        img = ((data['images'])[site])[*,*,*,frame_idx]
        flattened_img = reform(img, n_channels, width * height)
        tmp = flattened_img
      endelse

      if total(tmp) eq 0. then continue ; if no data then there's nothing to add to mosaic

      ; Scale this data based on previously defined scaling bounds
      tmp = bytscl(tmp, min=(image_intensity_scales[site])[0], max=(image_intensity_scales[site])[1], top=255)

      ; Add the timestamp to tracking list if it is unique
      if where(meta_timestamp eq unique_timestamps, /null) eq !null then unique_timestamps = [unique_timestamps, meta_timestamp]

      ; Append sites to respective lists, and add image data to master list
      sites_with_data = [sites_with_data, site]
      sites_with_data_idx = [sites_with_data_idx, where(site_list eq site)]
      all_images[site] = ulong(tmp)
    endforeach

    ; Confirm that all data is from the same timestamp
    if n_elements(unique_timestamps) ne 1 then begin
      print, "[aurorax_mosaic_plot] Error: 'Images have different timestamps'"
      goto, error_jump
    endif

    ; Create an array for easily switching between colortables and n_channels
    site_ct = []
    site_nchannels = []
    ;        site_images = list()
    foreach site, sites_with_data do begin
      site_nchannels = [site_nchannels, n_channels_dict[site]]
      ;            site_images.add, all_images[site]
      if n_channels eq 1 then begin
        if n_elements(colortable) lt n_elements(all_sites_to_plot) then begin
          site_ct = [site_ct, (colortable)[mosaic_data_idx]]
        endif else begin
          site_ct = [site_ct, (colortable)[site_idx]]
        endelse
      endif else begin
        site_ct = [site_ct, 0]
      endelse
    endforeach

    ; Set up elevation increment for plotting. We start at the min elevation
    ; and plot groups of elevations until reaching 90 deg.
    if keyword_set(elevation_increment) then begin
      default_elev_delta = elevation_increment
    endif else begin
      default_elev_delta = 0.25
    endelse
    el = min_el

    ; Iterate through all elevation ranges
    while el lt 90 do begin
      ; Update elevation increment for efficiency
      elev_delta = default_elev_delta
      if el gt 20 then elev_delta = default_elev_delta*2.
      if el gt 40 then elev_delta = default_elev_delta*5.
      ; Only iterate through the sites that actually have data
      for i=0, n_elements(sites_with_data)-1 do begin

        site_id = sites_with_data[i]
        site_idx = sites_with_data_idx[i]

        ; Get this site's number of channels
        n_channels = site_nchannels[site_idx]

        ; Get all pixels within current elevation threshold
        el_idx = where(elev[site_idx] gt el and elev[site_idx] lt  el + elev_delta, /null)
        if el_idx eq !null then continue

        ; Grab this level's filling lat/lons
        el_lvl_fill_lats = (polyfill_lat[site_idx])[*, el_idx]
        el_lvl_fill_lons = (polyfill_lon[site_idx])[*, el_idx]

        ; Grab this level's data values
        if n_channels eq 1 then begin
          el_lvl_cmap_vals = (all_images[site_id])[el_idx]
        endif else begin
          el_lvl_cmap_vals = (all_images[site_id])[*,el_idx]
        endelse

        ; Set up colortable
        if n_channels eq 1 then begin
          ; single channel plotting using colortable
          device, decomposed=0
          loadct, site_ct[i], /silent
          for k=0, n_elements(el_idx)-1 do begin
            polyfill, el_lvl_fill_lons[*,k], el_lvl_fill_lats[*,k], color=el_lvl_cmap_vals[k]
          endfor
        endif else begin
          ; multi-channel plotting using decomposed color
          device, decomposed=1
          for k=0, n_elements(el_idx)-1 do begin
            polyfill, el_lvl_fill_lons[*,k], el_lvl_fill_lats[*,k], color=aurorax_get_decomposed_color(el_lvl_cmap_vals[*,k])
          endfor
        endelse

      endfor
      el += elev_delta

    endwhile
  endfor

  error_jump:
  device, get_decomposed=original_decomp

end



