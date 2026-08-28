;+
;Function: IUG_LOAD_GMAG_WDC_HAPI_INFO
; info = iug_load_gmag_wdc_hapi_info(dataset, no_download=no_download)
;
;Purpose:
;  Return the /info document of a WDC Kyoto HAPI dataset as an ORDEREDHASH,
;  or !null when the dataset is unknown or unreachable and not cached.
;
;Keywords:
;  no_download: use only the copy already in the local cache.
;
;Notes:
;  The response is memoized for the session and mirrored to
;  <cache>/info/<dataset>.json, so no_download still works offline. This is the
;  only change detector available: /data carries no Last-Modified or ETag and
;  rejects HEAD, so the dataset-level modificationDate found here is what
;  iug_load_gmag_wdc_hapi_files uses to decide whether to download again.
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
function iug_load_gmag_wdc_hapi_info, dataset, no_download=no_download

  compile_opt idl2
  common iug_load_gmag_wdc_hapi_cache, hapi_info_memo, hapi_catalog_ids

  if ~isa(hapi_info_memo, 'hash') then hapi_info_memo = hash()
  if hapi_info_memo.HasKey(dataset) then begin
    cached = hapi_info_memo[dataset]
    return, isa(cached, 'string') ? !null : cached   ; '' marks "unknown dataset"
  endif

  path = iug_load_gmag_wdc_hapi_dir() + 'info/' + dataset + '.json'
  txt = ''

  if ~keyword_set(no_download) then begin
    txt = iug_load_gmag_wdc_hapi_get('info', 'id=' + dataset, $
                                     response_code=code, error=err)
    if keyword_set(err) then begin
      txt = ''
      if code eq 404 or code eq 400 then begin
        ; unknown dataset id (HAPI 1406) -- remember so we ask only once
        hapi_info_memo[dataset] = ''
        return, !null
      endif
    endif
  endif

  if txt eq '' then begin
    if ~file_test(path, /regular) then begin
      hapi_info_memo[dataset] = ''
      return, !null
    endif
    n = file_lines(path)
    if n le 0 then begin
      hapi_info_memo[dataset] = ''
      return, !null
    endif
    lines = strarr(n)
    openr, lun, path, /get_lun
    readf, lun, lines
    free_lun, lun
    txt = strjoin(lines, '')
  endif else begin
    file_mkdir, file_dirname(path)
    openw, lun, path, /get_lun
    printf, lun, txt
    free_lun, lun
  endelse

  catch, perr
  if perr ne 0 then begin
    catch, /cancel
    dprint, dlevel=1, 'WDC HAPI: cannot parse /info for ' + dataset
    hapi_info_memo[dataset] = ''
    return, !null
  endif
  info = json_parse(txt)
  catch, /cancel

  hapi_info_memo[dataset] = info
  return, info
end
