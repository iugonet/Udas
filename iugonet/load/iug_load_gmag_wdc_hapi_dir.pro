;+
;Function: IUG_LOAD_GMAG_WDC_HAPI_DIR
; dir = iug_load_gmag_wdc_hapi_dir()
;
;Purpose:
;  Return the local cache directory of the WDC Kyoto HAPI client, with a
;  trailing path separator.
;
;Notes:
;  The layout below this directory is the same one pyudas uses, so the two
;  caches can be mirrored:
;    <dir>catalog.json
;    <dir>info/<dataset>.json
;    <dir><dataset>/<dataset>_<label>.csv       (one calendar chunk of data)
;    <dir><dataset>/<dataset>_<label>.meta.json (its validation metadata)
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
function iug_load_gmag_wdc_hapi_dir
  compile_opt idl2
  return, root_data_dir() + 'iugonet/wdc_kyoto/hapi/'
end
