; -------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; -------------------------------------------------------------

pro aurorax_example_conjunction_search
  compile_opt idl2

  ; define timeframe and distance parameters
  distance = 500
  start_dt = '2019-01-01T00:00:00'
  end_dt = '2019-01-03T23:59:59'

  ; create ground criteria block
  ground1 = aurorax_create_criteria_block(programs = ['themis-asi'], platforms = ['fort smith', 'gillam'], /ground)
  ground = list(ground1)

  ; create space criteria block
  space1 = aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern'], /space)
  space = list(space1)

  ; perform search
  response = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace)

  ; show data
  help, response
  print, ''
  help, response.data[0]
end
