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


function aurorax_atm_inverse_get_output_flags,set_all_true=set_all_true
  ; create hash
  output_flags = hash()
  output_flags['altitudes'] = 0
  output_flags['energy_flux'] = 0
  output_flags['characteristic_energy'] = 0
  output_flags['oxygen_correction_factor'] = 0
  output_flags['emission_4278'] = 0
  output_flags['emission_5577'] = 0
  output_flags['emission_6300'] = 0
  output_flags['emission_8446'] = 0
  output_flags['height_integrated_rayleighs_4278'] = 0
  output_flags['height_integrated_rayleighs_5577'] = 0
  output_flags['height_integrated_rayleighs_6300'] = 0
  output_flags['height_integrated_rayleighs_8446'] = 0
  output_flags['neutral_n2_density'] = 0
  output_flags['neutral_n_density'] = 0
  output_flags['neutral_o2_density'] = 0
  output_flags['neutral_o_density'] = 0
  output_flags['neutral_temperature'] = 0
  output_flags['plasma_electron_density'] = 0
  output_flags['plasma_electron_temperature'] = 0
  output_flags['plasma_hall_conductivity'] = 0
  output_flags['plasma_ion_temperature'] = 0
  output_flags['plasma_ionisation_rate'] = 0
  output_flags['plasma_noplus_density'] = 0
  output_flags['plasma_o2plus_density'] = 0
  output_flags['plasma_oplus_density'] = 0
  output_flags['plasma_pederson_conductivity'] = 0

  ; set all true, if necessary
  if keyword_set(set_all_true) then begin
    foreach value, output_flags, key do begin
      output_flags[key] = 1
    endforeach
  endif

  ; return
  return,output_flags
end
