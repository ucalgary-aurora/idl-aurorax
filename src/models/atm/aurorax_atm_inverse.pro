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

function aurorax_atm_inverse,$
  time_stamp,$
  geo_lat,$
  geo_lon,$
  intensity_4278,$
  intensity_5577,$
  intensity_6300,$
  intensity_8446,$
  output_flags,$
  precipitation_flux_spectral_type=precipitation_flux_spectral_type,$
  nrlmsis_model_version=nrlmsis_model_version,$
  atmospheric_attenuation_correction=atmospheric_attenuation_correction,$
  atm_model_version=atm_model_version,$
  no_cache=no_cache

  ; set keyword flags
  no_cache_flag = 0
  if keyword_set(no_cache) then no_cache_flag = 1

  ; convert all output flags to booleans
  foreach value, output_flags, key do begin
    output_flags[key] = boolean(value)
  endforeach

  ; set params
  request_hash = hash()
  request_hash['timestamp'] = time_stamp
  request_hash['geodetic_latitude'] = geo_lat
  request_hash['geodetic_longitude'] = geo_lon
  request_hash['output'] = output_flags
  if (no_cache_flag eq 1) then request_hash['no_cache'] = boolean(1)
  if (isa(intensity_4278) eq 1) then request_hash['intensity_4278'] = intensity_4278
  if (isa(intensity_5577) eq 1) then request_hash['intensity_5577'] = intensity_5577
  if (isa(intensity_6300) eq 1) then request_hash['intensity_6300'] = intensity_6300
  if (isa(intensity_8446) eq 1) then request_hash['intensity_8446'] = intensity_8446
  if (isa(precipitation_flux_spectral_type) eq 1) then request_hash['precipitation_flux_spectral_type'] = precipitation_flux_spectral_type
  if (isa(nrlmsis_model_version) eq 1) then request_hash['nrlmsis_model_version'] = nrlmsis_model_version
  if (isa(atmospheric_attenuation_correction) eq 1) then request_hash['atmospheric_attenuation_correction'] = atmospheric_attenuation_correction
  if (isa(atm_model_version) eq 1) then request_hash['atm_model_version'] = atm_model_version

  ; create post struct and serialize into a string
  post_str = json_serialize(request_hash,/lowercase)

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.phys.ucalgary.ca'
  req->SetProperty,URL_PATH = 'api/v1/atm/inverse'
  req->SetProperty,HEADERS = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

  ; make request
  output = req->Put(post_str, /BUFFER, /STRING_ARRAY, /POST)

  ; get status code and get response headers
  req->GetProperty,RESPONSE_CODE=status_code,RESPONSE_HEADER=response_headers

  ; cleanup this request
  obj_destroy,req

  ; check status code
  if (status_code ne 200) then begin
    if (verbose eq 1) then print,'[aurorax_atm_inverse] Error performing calculatoin: ' + output
    return,!NULL
  endif

  ; serialize into dictionary
  data = json_parse(output,/dictionary)

  ; serialize any List() objects to float arrays
  foreach value, data['data'], key do begin
    if (isa(value, 'List') eq 1) then begin
      data['data',key] = value.toArray(type='float')
    endif
  endforeach

  ; finally convert to struct
  data = data.toStruct(/recursive)

  ; return
  return,data
end