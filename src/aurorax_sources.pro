;-------------------------------------------------------------
; MIT License
;
; Copyright (c) 2022 University of Calgary
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;-------------------------------------------------------------

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_SOURCES_LIST
; 
; PURPOSE:
;       Retrieve AuroraX data sources
; 
; EXPLANATION:
;       Retrieve a list of data sources from the AuroraX platform, with optional
;       parameters used to filter unwanted data sources out.
;       
; CALLING SEQUENCE:
;       data = aurorax_sources_list()
; 
; INPUTS
;
; OUTPUTS
;
; OPTIONAL INPUT KEYWORD:
;
; EXAMPLE:
; 
; NOTES:
;
; REVISION HISTORY:
;   - Initial implementation, Feb 2022, Darren Chaddock
;-------------------------------------------------------------
function aurorax_sources_list,program=program,platform=platform,instrument_type=instrument_type,source_type=source_type,FORMAT_FULL_RECORD=format_full_record,FORMAT_IDENTIFIER_ONLY=format_identifier_only
  ; set format
  format = 'basic_info'
  if (n_elements(format_full_record) eq 1) then format = 'full_record'
  if (n_elements(format_identifier_only) eq 1) then format = 'identifier_only'

  ; set params
  param_str = 'format=' + format
  if (isa(program) eq 1) then begin
    param_str += '&program=' + program
  endif
  if (isa(platform) eq 1) then begin
    param_str += '&platform=' + platform
  endif
  if (isa(instrument_type) eq 1) then begin
    param_str += '&instrument_type=' + instrument_type
  endif
  if (isa(source_type) eq 1) then begin
    param_str += '&source_type=' + source_type
  endif

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = 'api/v1/data_sources'
  req->SetProperty,URL_QUERY = param_str

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; parse
  data = json_parse(output,/TOSTRUCT)

  ; cleanup
  OBJ_DESTROY,req

  ; return
  return,data
end