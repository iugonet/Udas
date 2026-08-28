;+
;Function: IUG_LOAD_GMAG_WDC_HAPI_GET
; res = iug_load_gmag_wdc_hapi_get(endpoint, query, filename=filename, $
;                                  response_code=response_code, error=error)
;
;Purpose:
;  GET one endpoint of the WDC Kyoto HAPI server.
;
;Arguments:
;  endpoint: 'capabilities', 'catalog', 'info' or 'data'
;  query:    query string without the leading '?', e.g. 'id=hour_dst'
;
;Keywords:
;  filename:      if set, the response body is written to this file and the
;                 file name is returned. Otherwise the body is returned as a
;                 string.
;  response_code: (output) HTTP status code
;  error:         (output) 1 when the request failed, 0 otherwise
;  timeout:       seconds, default 300
;
;Notes:
;  A HAPI error (e.g. status 1405, a time range outside the dataset) comes back
;  as an HTTP 4xx, which makes IDLnetURL::Get throw; it is caught here and
;  reported through error/response_code instead.
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
function iug_load_gmag_wdc_hapi_get, endpoint, query, filename=filename, $
                                     response_code=response_code, error=error, $
                                     timeout=timeout

  compile_opt idl2

  ; WDC for Geomagnetism, Kyoto: HAPI server (HAPI 3.3.1)
  url_scheme = 'https'
  url_host = 'wdc.kugi.kyoto-u.ac.jp'
  url_base = 'hapi/'

  if ~keyword_set(timeout) then timeout = 300
  error = 0
  response_code = 0

  neturl = obj_new('IDLnetURL')
  neturl->SetProperty, URL_SCHEME = url_scheme
  neturl->SetProperty, URL_HOST = url_host
  neturl->SetProperty, URL_PATH = url_base + endpoint
  if keyword_set(query) then neturl->SetProperty, URL_QUERY = query
  neturl->SetProperty, CONNECT_TIMEOUT = timeout
  neturl->SetProperty, TIMEOUT = timeout
  neturl->SetProperty, SSL_VERIFY_PEER = 0
  neturl->SetProperty, SSL_VERIFY_HOST = 0

  catch, err
  if err ne 0 then begin
    catch, /cancel
    neturl->GetProperty, RESPONSE_CODE = response_code
    obj_destroy, neturl
    error = 1
    dprint, dlevel=1, 'WDC HAPI: GET /' + endpoint + '?' + query + $
            ' failed (HTTP ' + strtrim(response_code, 2) + ')'
    return, ''
  endif

  if keyword_set(filename) then begin
    out = neturl->Get(filename=filename)
  endif else begin
    out = string(neturl->Get(/buffer))
  endelse
  neturl->GetProperty, RESPONSE_CODE = response_code
  catch, /cancel
  obj_destroy, neturl

  return, out
end
