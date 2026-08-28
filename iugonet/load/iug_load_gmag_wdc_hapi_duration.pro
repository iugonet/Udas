;+
;Function: IUG_LOAD_GMAG_WDC_HAPI_DURATION
; sec = iug_load_gmag_wdc_hapi_duration(text)
;
;Purpose:
;  Convert an ISO 8601 duration to seconds; return -1 when it cannot be parsed.
;
;Notes:
;  Used for both 'cadence' and 'maxRequestDuration', which share the grammar
;  P[nY][nM][nD][T[nH][nM][nS]]. Years and months are nominal (365.25 / 30.44
;  days); days, hours, minutes and seconds are exact, and those are the ones
;  the request splitting depends on.
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
function iug_load_gmag_wdc_hapi_duration, text

  compile_opt idl2

  if n_elements(text) eq 0 then return, -1d
  if ~isa(text, 'string') then return, -1d
  if text eq '' then return, -1d

  m = stregex(text, '^P(([0-9]+)Y)?(([0-9]+)M)?(([0-9]+)D)?' + $
              '(T(([0-9]+)H)?(([0-9]+)M)?(([0-9.]+)S)?)?$', /extract, /subexpr)
  if m[0] eq '' then return, -1d

  sec = 0d
  if m[2] ne '' then sec += double(m[2]) * 365.25d * 86400d
  if m[4] ne '' then sec += double(m[4]) * 30.44d * 86400d
  if m[6] ne '' then sec += double(m[6]) * 86400d
  if m[9] ne '' then sec += double(m[9]) * 3600d
  if m[11] ne '' then sec += double(m[11]) * 60d
  if m[13] ne '' then sec += double(m[13])
  return, sec
end
