;+
;Procedure: IUG_LOAD_GMAG_WDC_HAPI_READ
; iug_load_gmag_wdc_hapi_read, files, info, times, values, names
;
;Purpose:
;  Read the cached HAPI CSV chunks of one dataset into arrays.
;
;Arguments:
;  files:  cached chunk paths in time order (from iug_load_gmag_wdc_hapi_files)
;  info:   the dataset /info document (ORDEREDHASH)
;  times:  (output) unix seconds, dblarr(nt); !null when nothing was read
;  values: (output) dblarr(nt, nparam), each parameter's declared fill turned
;          into NaN. Time is not included.
;  names:  (output) the value column names, Time excluded
;
;Notes:
;  Everything is read as double. The CSV holds the server's decimal text, and
;  the WDC 1-min values carry 0.1 nT, which a float cannot hold exactly at
;  46000 nT; the angular components in degrees need the range as well.
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
pro iug_load_gmag_wdc_hapi_read, files, info, times, values, names

  compile_opt idl2

  times = !null
  values = !null
  names = !null
  if ~isa(info, 'hash') then return
  if n_elements(files) eq 0 then return

  npar = n_elements(info['parameters'])
  if npar lt 2 then return
  names = strarr(npar - 1)
  fills = strarr(npar - 1)
  for k = 1l, npar - 1 do begin
    p = (info['parameters'])[k]
    names[k-1] = p['name']
    f = p.HasKey('fill') ? p['fill'] : !null
    fills[k-1] = (f eq !null) ? '' : string(f)
  endfor

  types = ['String', replicate('Double', npar - 1)]

  for j = 0l, n_elements(files) - 1 do begin
    file = files[j]
    if ~file_test(file, /regular) then continue
    if file_lines(file) le 0 then continue      ; a chunk the server had no data for

    csv = !null
    catch, cerr
    if cerr eq 0 then csv = read_csv(file, types=types)
    catch, /cancel
    if ~isa(csv, 'struct') then begin
      dprint, dlevel=1, 'WDC HAPI: cannot read ' + file
      continue
    endif
    if n_tags(csv) ne npar then begin
      dprint, dlevel=1, 'WDC HAPI: unexpected column count in ' + file
      continue
    endif

    nrec = n_elements(csv.(0))
    chunk = dblarr(nrec, npar - 1)
    for k = 1l, npar - 1 do chunk[*, k-1] = csv.(k)

    times = [times, time_double(csv.(0))]
    values = (n_elements(values) eq 0) ? chunk : [values, chunk]
  endfor

  if n_elements(times) eq 0 then begin
    values = !null
    return
  endif

  ; the declared fill value of each parameter becomes NaN
  for k = 0l, npar - 2 do begin
    if fills[k] eq '' then continue
    fval = double(fills[k])
    bad = where(values[*, k] eq fval, nbad)
    if nbad gt 0 then values[bad, k] = !values.d_nan
  endfor
end
