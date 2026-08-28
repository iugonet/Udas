;+
;PROCEDURE: IUG_LOAD_GMAG_WDC
; iug_load_gmag_wdc, site=site, $
;                        trange=trange, $
;                        resolution = resolution, $
;                        level=level, $
;                        verbose=verbose, $
;                        addmaster=addmaster, $
;                        downloadonly=downloadonly, $
;                        no_download=no_download, $
;                        force_download=force_download
;
;PURPOSE:
;  Loading geomagnetic index and observatory data from WDC for Geomagnetism,
;  Kyoto, through its HAPI server (https://wdc.kugi.kyoto-u.ac.jp/hapi/).
;
;KEYWORDS:
;  site  = Station ABB code or name of geomagnetic index.
;          Ex1) iug_load_gmag_wdc, site = 'kak', ...
;          Ex2) iug_load_gmag_wdc, site = ['dst', 'ae'], ...
;          If you skip this option, AE Dst SYM/ASY and KAK data are retrieved.
;  trange= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note that data
;          are cached and loaded in whole calendar chunks (a month for hourly
;          and 1-min data, a day for 1-s data), so the variables can extend
;          past the requested range.
;  resolution = Time resolution of the data: 'min', 'hour' or 'sec',
;          default set to 'min' for AE index and geomag data.
;  level = The level of the data. Indices accept 'final', 'provisional' and
;          'realtime'; observatories accept 'definitive' and 'quasidefinitive'.
;          If it is not set, the server's best-available dataset is loaded,
;          which already merges Final > Provisional > Real-time per period into
;          a single variable. A level the server does not serve for that site
;          falls back to the best-available dataset.
;  /verbose : set to output some useful info.
;  /addmaster : accepted for backward compatibility and ignored (it applied to
;          the file name lists of the retired WDC ASCII path).
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  no_download: use only data which are already in the local cache.
;  force_download: download every chunk again even when the cache looks current.
;
;EXAMPLE:
;   timespan, '2007-01-22',1,/days
;   iug_load_gmag_wdc, site = 'ae', resolution = 'min'
;
;NOTES:
;  Data come from the WDC Kyoto HAPI server and are cached locally as CSV; a
;  chunk is downloaded again only when the server says it changed. See
;  iug_load_gmag_wdc_hapi_files for the cache layout and the rules.
;
;  The Wp index is not served over HAPI and keeps its own reader
;  (iug_load_gmag_wdc_wp_index).
;
;  Timestamps are the ones the HAPI datasets declare (timeStampLocation=center):
;  hourly values are stamped at HH:29:30 and 1-min values at HH:MM:00. The
;  retired WDC ASCII path treated each record as the start of a bin and added
;  half the resolution, which put them 30 s later.
;
;Written by:  Daiki Yoshida,  Aug 2010
;Updated:  Yukinobu KOYAMA,  Oct 21, 2011
;Updated Shun Imajo, Apr, 26, 2017
;Updated by:  Shun Imajo, Mar 18, 2025
;Updated by:  Shun Imajo, Aug 26, 2026 (read from the WDC Kyoto HAPI server)

pro iug_load_gmag_wdc, site=site, $
                       trange=trange, $
                       resolution = resolution, $
                       level=level, $
                       verbose=verbose, $
                       addmaster=addmaster, $
                       downloadonly=downloadonly, $
                       no_download=no_download, $
                       force_download=force_download

  compile_opt idl2

  if !version.release lt '8.6' then begin
    dprint, dlevel=0, 'iug_load_gmag_wdc requires IDL 8.6 or later ' + $
            '(json_parse / json_serialize).'
    return
  endif

  ; validate site settings
  vsnames = 'kak asy sym ae dst wp'
  vsnames_sample = strsplit(vsnames, ' ', /extract)
  vsnames_all = iug_load_gmag_wdc_vsnames()
  if(keyword_set(site)) then site_in = site else site_in = vsnames_sample
  wdc_sites = ssl_check_valid_name(site_in, vsnames_all, $
    /ignore_case, /include_all)
  if wdc_sites[0] eq '' then return
  nsites = n_elements(wdc_sites)

  ; wanted HAPI parameters per site, in the order the components are stored,
  ; and the element symbol of the corresponding WDC record (used for the
  ; variable names and the plot colors)
  stn_params = ['geomagneticFieldD', 'geomagneticFieldH', 'geomagneticFieldX', $
                'geomagneticFieldY', 'geomagneticFieldZ', 'geomagneticFieldF', $
                'geomagneticFieldI']
  stn_elements = ['D', 'H', 'X', 'Y', 'Z', 'F', 'I']

  catalog_ids = iug_load_gmag_wdc_hapi_catalog(no_download=no_download)

  for i = 0l, nsites - 1 do begin

    sname = strlowcase(wdc_sites[i])

    ; the Wp index is not served over HAPI; it keeps its own reader
    if sname eq 'wp' then begin
      iug_load_gmag_wdc_wp_index, trange = trange, $
                                  downloadonly = downloadonly, $
                                  no_download = no_download
      continue
    endif

    ; ---- resolution: default 'min', forced for some sites ----
    if(~keyword_set(resolution)) then res = 'min' else res = strlowcase(resolution)
    if res eq 'hr' then res = 'hour'
    if res ne 'hour' and res ne 'sec' then res = 'min'
    if sname eq 'sym' or sname eq 'asy' then begin
      res = 'min'
    endif else if sname eq 'dst' then begin
      res = 'hour'
    endif

    level_in = keyword_set(level) ? level : ''

    dataset = iug_load_gmag_wdc_dataset(sname, res, level_in, base=base)
    if dataset ne base && n_elements(catalog_ids) gt 0 && catalog_ids[0] ne '' then begin
      if total(catalog_ids eq dataset) eq 0 then begin
        dprint, dlevel=2, 'WDC HAPI: ' + dataset + ' is not served; using ' + $
                base + ' (best available)'
        ; the variable name must not claim a level that was not loaded
        dataset = base
        level_in = ''
      endif
    endif
    if n_elements(catalog_ids) gt 0 && catalog_ids[0] ne '' then begin
      if total(catalog_ids eq dataset) eq 0 then begin
        dprint, dlevel=2, 'WDC HAPI: no dataset ' + dataset
        continue
      endif
    endif

    files = iug_load_gmag_wdc_hapi_files(dataset, trange, info=info, $
                                         no_download=no_download, $
                                         force_download=force_download)
    if ~isa(info, 'hash') then begin
      dprint, dlevel=2, 'WDC HAPI: no dataset ' + dataset
      continue
    endif
    if keyword_set(downloadonly) then continue
    if n_elements(files) eq 0 || files[0] eq '' then continue

    iug_load_gmag_wdc_hapi_read, files, info, times, values, names
    if n_elements(times) eq 0 then continue

    ; ---- pick and scale the wanted columns ----
    case sname of
      'dst': begin
        want = ['dstValue']
        want_elements = ['*']         ; the element field of a WDC Dst record
      end
      'ae': begin
        want = ['aeValue', 'auValue', 'alValue', 'aoValue']
        want_elements = ['E', 'U', 'L', 'O']    ; AE AU AL AO, as in UDAS
      end
      'sym': begin
        want = ['symDValue', 'symHValue']
        want_elements = ['D', 'H']
      end
      'asy': begin
        want = ['asyDValue', 'asyHValue']
        want_elements = ['D', 'H']
      end
      else: begin
        want = stn_params
        want_elements = stn_elements
      end
    endcase

    elemlist = !null
    databuf = !null
    for k = 0l, n_elements(want) - 1 do begin
      w = where(names eq want[k], nw)
      if nw eq 0 then continue
      col = values[*, w[0]]
      ; HAPI always emits every declared component; drop the ones this
      ; observatory does not report at all
      if total(finite(col)) eq 0 then continue
      ; HAPI reports the angular components in arcmin, UDAS in degrees
      if want[k] eq 'geomagneticFieldD' or want[k] eq 'geomagneticFieldI' then $
        col = col / 60d
      elemlist = [elemlist, want_elements[k]]
      databuf = (n_elements(databuf) eq 0) ? col : [[databuf], [col]]
    endfor
    if n_elements(elemlist) eq 0 then continue
    databuf = reform(databuf, n_elements(times), n_elements(elemlist))

    ; ---- store data to tplot variables ----
    iug_load_gmag_wdc_create_tplot_vars, $
      sname = sname, $
      element = elemlist, $
      res = res, level = level_in, $
      tplot_name, tplot_ytitle, tplot_ysubtitle, tplot_labels, $
      tplot_colors, dlimit

    store_data, $
      tplot_name, $
      data = {x:times, y:databuf}, $
      dlimit = dlimit
    options, $
      tplot_name, $
      ytitle = tplot_ytitle, ysubtitle = tplot_ysubtitle, $
      labels = tplot_labels, colors = tplot_colors, labflag = 1

    print, '**************************************************'
    print_str_maxlet, dlimit.data_att.acknowledgment
    print, '**************************************************'

    databuf = 0
    times = 0
  endfor

end
