;+
;FUNCTION: IUG_LOAD_GMAG_WDC_QDDAYS
; function iug_load_gmag_wdc_qddays, $
;    trange=trange, $
;    verbose=verbose, $
;    downloadonly=downloadonly, $
;    no_download=no_download, $
;    force_download=force_download
;
;Purpose:
;  Load date list of International 5/10 quietest days
;  and International 5 disturbed days from WDC Kyoto.
;
;Keywords:
;  trange= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Whole calendar
;          years covering the range are cached and returned.
;  /verbose : set to output some useful info
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  no_download: use only data which are already in the local cache.
;  force_download: download every chunk again even when the cache looks current.
;
;Example:
;  THEMIS> timespan, '2001-1-1'
;  THEMIS> qdays = iug_load_gmag_wdc_qddays(/no_download)
;  THEMIS> help, qdays, /str
;  QDAYS            INT       = Array[12, 12]
;  THEMIS> print, qdays[*,0]
;   2001       1       1      30       6       2      19      18      27       7       5       9
;
;Notes:
;  International Q-Days and D-Days are now derived by
;  GeoForschungsZentrum (GFZ) Potsdam from Kp index.
;  reference: http://wdc.kugi.kyoto-u.ac.jp/qddays/index.html
;
;  Read from the WDC Kyoto HAPI dataset 'month_qddays'. Each returned row is
;  [year, month, Q1..Q5, Q6..Q10]; the five most disturbed days the dataset
;  also carries are not part of this return value, as before.
;
;Written by:  Daiki Yoshida,  Aug 2010
;Last Updated:  Daiki Yoshida,  Jan 11, 2010
;Updated by:  Shun Imajo, Aug 26, 2026 (read from the WDC Kyoto HAPI server)
;-

function iug_load_gmag_wdc_qddays, $
   trange=trange, $
   verbose=verbose, $
   downloadonly=downloadonly, $
   no_download=no_download, $
   force_download=force_download

  compile_opt idl2

  if !version.release lt '8.6' then begin
    dprint, dlevel=0, 'iug_load_gmag_wdc_qddays requires IDL 8.6 or later ' + $
            '(json_parse / json_serialize).'
    return, 0
  endif

  files = iug_load_gmag_wdc_hapi_files('month_qddays', trange, info=info, $
                                       no_download=no_download, $
                                       force_download=force_download)
  if keyword_set(downloadonly) then return, files
  if ~isa(info, 'hash') then begin
    dprint, 'no qddata found.'
    return, 0
  endif
  if n_elements(files) eq 0 || files[0] eq '' then begin
    dprint, 'no qddata found.'
    return, 0
  endif

  ; the fill value of the day columns is 0, which is also the natural "unknown"
  ; marker of the integer result, so read the raw numbers rather than NaN
  npar = n_elements(info['parameters'])
  names = strarr(npar - 1)
  for k = 1l, npar - 1 do names[k-1] = ((info['parameters'])[k])['name']

  types = ['String', replicate('Double', npar - 1)]
  buf = !null
  for j = 0l, n_elements(files) - 1 do begin
    file = files[j]
    if ~file_test(file, /regular) then continue
    if file_lines(file) le 0 then continue
    csv = read_csv(file, types=types)
    if n_tags(csv) ne npar then continue
    ts = time_struct(time_double(csv.(0)))
    for m = 0l, n_elements(csv.(0)) - 1 do begin
      row = [ts[m].year, ts[m].month]
      for q = 1, 10 do begin
        w = where(names eq 'quietDay' + strtrim(q, 2), nw)
        if nw eq 0 then continue
        row = [row, long((csv.(w[0] + 1))[m])]
      endfor
      if n_elements(row) ne 12 then continue
      buf = [buf, fix(row)]
    endfor
  endfor

  n = n_elements(buf) / 12
  if n ne 0 then begin
    return, reform(buf, 12, n)
  endif else begin
    dprint, 'no qddata found.'
    return, 0
  endelse

end
