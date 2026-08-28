;+
;Function: IUG_LOAD_GMAG_WDC_DATASET
; dataset = iug_load_gmag_wdc_dataset(sname, res, level, base=base)
;
;Purpose:
;  Turn a UDAS site / resolution / level into a WDC Kyoto HAPI dataset id.
;
;Arguments:
;  sname: site abbreviation or index name, lower case ('kak', 'dst', ...)
;  res:   'min', 'hour' or 'sec'
;  level: processing level, or '' for the server's best-available dataset
;
;Keywords:
;  base:  (output) the best-available dataset id, i.e. the return value with
;         any level suffix removed. Used to fall back when the server does not
;         serve the requested level for that site.
;
;Notes:
;  Indices accept final / provisional / realtime, observatories accept
;  definitive / quasidefinitive. With no level the best-available dataset is
;  returned, which already merges the levels per period.
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
function iug_load_gmag_wdc_dataset, sname, res, level, base=base

  compile_opt idl2

  s = strlowcase(sname)
  r = strlowcase(res)
  if r eq 'hr' then r = 'hour'

  if s eq 'dst' then base = 'hour_dst' $
  else if s eq 'ae' then base = r + '_ae' $
  else if s eq 'sym' or s eq 'asy' then base = 'min_asysym' $
  else base = r + '_' + s

  suffix = ''
  if keyword_set(level) then begin
    lv = strlowcase(level)
    if strcmp(lv, 'fin', 3) then suffix = 'final' $
    else if strcmp(lv, 'prov', 4) then suffix = 'provisional' $
    else if strcmp(lv, 'real', 4) or lv eq 'rt' then suffix = 'realtime' $
    else if strcmp(lv, 'def', 3) then suffix = 'definitive' $
    else if strcmp(lv, 'quas', 4) or lv eq 'qd' or lv eq 'ql' or $
            lv eq 'quicklook' then suffix = 'quasidefinitive'
  endif

  if suffix eq '' then return, base
  return, base + '_' + suffix
end
