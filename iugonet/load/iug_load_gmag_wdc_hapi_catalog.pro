;+
;Function: IUG_LOAD_GMAG_WDC_HAPI_CATALOG
; ids = iug_load_gmag_wdc_hapi_catalog(no_download=no_download)
;
;Purpose:
;  Return the dataset ids the WDC Kyoto HAPI server offers, as a string array
;  ('' when the catalog is neither reachable nor cached).
;
;Notes:
;  Fetched once per session and mirrored to <cache>/catalog.json. Used to skip
;  sites the server does not carry without spending one failing request each --
;  site='all' asks about several hundred.
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
function iug_load_gmag_wdc_hapi_catalog, no_download=no_download

  compile_opt idl2
  common iug_load_gmag_wdc_hapi_cache, hapi_info_memo, hapi_catalog_ids

  if isa(hapi_catalog_ids, 'string') then return, hapi_catalog_ids

  path = iug_load_gmag_wdc_hapi_dir() + 'catalog.json'
  txt = ''

  if ~keyword_set(no_download) then begin
    txt = iug_load_gmag_wdc_hapi_get('catalog', '', error=err)
    if keyword_set(err) then txt = ''
  endif

  if txt eq '' then begin
    if file_test(path, /regular) && file_lines(path) gt 0 then begin
      lines = strarr(file_lines(path))
      openr, lun, path, /get_lun
      readf, lun, lines
      free_lun, lun
      txt = strjoin(lines, '')
    endif
  endif else begin
    file_mkdir, file_dirname(path)
    openw, lun, path, /get_lun
    printf, lun, txt
    free_lun, lun
  endelse

  if txt eq '' then begin
    hapi_catalog_ids = ''
    return, hapi_catalog_ids
  endif

  catch, perr
  if perr ne 0 then begin
    catch, /cancel
    hapi_catalog_ids = ''
    return, hapi_catalog_ids
  endif
  doc = json_parse(txt)
  catch, /cancel

  entries = doc['catalog']
  ids = strarr(n_elements(entries))
  for i = 0l, n_elements(entries) - 1 do ids[i] = (entries[i])['id']
  hapi_catalog_ids = ids
  return, ids
end
