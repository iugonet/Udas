;+
;Function: IUG_LOAD_GMAG_WDC_HAPI_FILES
; files = iug_load_gmag_wdc_hapi_files(dataset, trange, info=info, $
;                                      no_download=no_download, $
;                                      force_download=force_download)
;
;Purpose:
;  Make the local cache cover trange for one WDC Kyoto HAPI dataset and return
;  the cached CSV paths in time order ('' when there is nothing).
;
;Keywords:
;  info:           (output) the dataset /info document (ORDEREDHASH), !null if
;                  the dataset is unavailable.
;  no_download:    use only what is already cached.
;  force_download: download every chunk again even when the cache looks current.
;
;Notes:
;  Data are cached as the server's format=csv body written verbatim, so every
;  value keeps its decimal text exactly, plus a .meta.json sidecar recording
;  what was requested and the dataset modificationDate at download time. One
;  chunk is one calendar day, month or year, chosen from the dataset cadence
;  (sub-30 s -> day, up to 1 hour -> month, coarser -> year), so a long trange
;  is always split into several requests. A dataset that declares a
;  maxRequestDuration shorter than its chunk is split further, into as many
;  requests as the limit needs, whose bodies are concatenated into the one
;  chunk file.
;
;  Skipping unchanged downloads needs two rules, because /data has no
;  Last-Modified or ETag and rejects HEAD, leaving only the dataset-level
;  modificationDate from /info -- which advances every hour for a real-time
;  dataset such as hour_dst and would otherwise invalidate every past chunk:
;    1. a chunk whose records are all at the highest processing level
;       (versionCode major 2=final for indices, 3=definitive for observatories)
;       and which is not truncated by stopDate is immutable and is never
;       fetched again;
;    2. any other chunk is reused only while its stored modificationDate still
;       matches the one the server reports now.
;
;  HAPI rejects a request reaching outside [startDate, stopDate] with an HTTP
;  400, so every chunk is clamped to that range before it is asked for.
;
;Written by:  Shun Imajo, Aug 26, 2026
;-
function iug_load_gmag_wdc_hapi_files, dataset, trange, info=info, $
                                       no_download=no_download, $
                                       force_download=force_download

  compile_opt idl2

  files = !null
  info = iug_load_gmag_wdc_hapi_info(dataset, no_download=no_download)
  if ~isa(info, 'hash') then return, ''
  if ~info.HasKey('startDate') or ~info.HasKey('stopDate') then return, ''

  ds_start = time_double(info['startDate'])
  ds_stop = time_double(info['stopDate'])

  tr = keyword_set(trange) ? time_double(trange) : timerange()
  t0 = tr[0]
  t1 = tr[1]
  if t1 le t0 then return, ''

  ; ---- cache granularity from the cadence ----
  cadence = 60d
  if info.HasKey('cadence') then begin
    c = iug_load_gmag_wdc_hapi_duration(info['cadence'])
    if c gt 0 then cadence = c
  endif
  if cadence lt 30d then unit = 'day' $
  else if cadence le 3600d then unit = 'month' $
  else unit = 'year'

  ; a dataset may cap how long a single request may span (HAPI 1408)
  max_request = -1d
  if info.HasKey('maxRequestDuration') then $
    max_request = iug_load_gmag_wdc_hapi_duration(info['maxRequestDuration'])

  ; ---- which value column carries versionCode ----
  vcol = -1
  npar = n_elements(info['parameters'])
  for k = 0l, npar - 1 do begin
    if ((info['parameters'])[k])['name'] eq 'versionCode' then vcol = k
  endfor
  ; the highest processing level of this kind of dataset
  top_level = info.HasKey('x_observatory') ? 3 : 2

  ddir = iug_load_gmag_wdc_hapi_dir() + dataset + '/'

  ; ---- walk the calendar chunks covering [t0, t1) ----
  case unit of
    'day': c0 = time_double(time_string(t0, tformat='YYYY-MM-DD'))
    'month': c0 = time_double(time_string(t0, tformat='YYYY-MM') + '-01')
    else: c0 = time_double(time_string(t0, tformat='YYYY') + '-01-01')
  endcase

  while c0 lt t1 do begin
    ts = time_struct(c0)
    case unit of
      'day': begin
        c1 = c0 + 86400d
        label = time_string(c0, tformat='YYYYMMDD')
      end
      'month': begin
        yy = ts.year
        mm = ts.month + 1
        if mm gt 12 then begin
          mm = 1
          yy += 1
        endif
        c1 = time_double(string(yy, format='(i4.4)') + '-' + $
                         string(mm, format='(i2.2)') + '-01')
        label = time_string(c0, tformat='YYYYMM')
      end
      else: begin
        c1 = time_double(string(ts.year + 1, format='(i4.4)') + '-01-01')
        label = time_string(c0, tformat='YYYY')
      end
    endcase

    ; HAPI rejects a request that reaches outside [startDate, stopDate]
    r0 = c0 > ds_start
    r1 = c1 < ds_stop
    if r1 le r0 then begin
      c0 = c1
      continue
    endif

    path = ddir + dataset + '_' + label + '.csv'
    meta_path = ddir + dataset + '_' + label + '.meta.json'
    smin = time_string(r0, tformat='YYYY-MM-DDThh:mm:ssZ')
    smax = time_string(r1, tformat='YYYY-MM-DDThh:mm:ssZ')

    ; ---- is the cached chunk still good? ----
    ok = 0
    if ~keyword_set(force_download) && file_test(path, /regular) && $
       file_test(meta_path, /regular) && file_lines(meta_path) gt 0 then begin
      mlines = strarr(file_lines(meta_path))
      openr, mlun, meta_path, /get_lun
      readf, mlun, mlines
      free_lun, mlun
      meta = !null
      catch, merr
      if merr eq 0 then meta = json_parse(strjoin(mlines, ''))
      catch, /cancel
      if isa(meta, 'hash') then begin
        if meta.HasKey('dataset') && meta.HasKey('format') && $
           meta.HasKey('time_min') && meta.HasKey('time_max') && $
           meta.HasKey('final') && meta.HasKey('complete') && $
           meta.HasKey('modificationDate') then begin
          if meta['dataset'] eq dataset && meta['format'] eq 'csv' && $
             meta['time_min'] eq smin && meta['time_max'] eq smax then begin
            if meta['final'] && meta['complete'] then begin
              ok = 1                  ; immutable: never fetch again
            endif else if meta['modificationDate'] eq info['modificationDate'] then begin
              ok = 1                  ; unchanged since it was downloaded
            endif
          endif
        endif
      endif
    endif

    if ok then begin
      files = [files, path]
      c0 = c1
      continue
    endif
    if keyword_set(no_download) then begin
      if file_test(path, /regular) then files = [files, path]
      c0 = c1
      continue
    endif

    ; ---- download this chunk ----
    ; split it further when the server caps how long one request may span.
    ; HAPI's csv format has no header line, so the pieces simply concatenate,
    ; and the cache layout does not move when the server changes the cap.
    file_mkdir, ddir
    if max_request gt 0 && (r1 - r0) gt max_request then begin
      nstep = long(ceil((r1 - r0) / max_request))
      dprint, dlevel=2, 'WDC HAPI: ' + dataset + ' ' + smin + '..' + smax + $
              ' exceeds maxRequestDuration; splitting into ' + $
              strtrim(nstep, 2) + ' requests'
    endif else nstep = 1L

    tmp = path + '.tmp'
    derr = 0
    if nstep eq 1 then begin
      query = 'id=' + dataset + '&time.min=' + smin + '&time.max=' + smax + $
              '&format=csv'
      got = iug_load_gmag_wdc_hapi_get('data', query, filename=tmp, error=derr)
    endif else begin
      openw, olun, tmp, /get_lun
      s0 = r0
      for step = 0l, nstep - 1 do begin
        s1 = ((s0 + max_request) < r1)
        query = 'id=' + dataset + $
                '&time.min=' + time_string(s0, tformat='YYYY-MM-DDThh:mm:ssZ') + $
                '&time.max=' + time_string(s1, tformat='YYYY-MM-DDThh:mm:ssZ') + $
                '&format=csv'
        part = tmp + '.part'
        got = iug_load_gmag_wdc_hapi_get('data', query, filename=part, error=derr)
        if keyword_set(derr) then begin
          file_delete, part, /allow_nonexistent, /quiet
          break
        endif
        ; copy the bytes, not the lines, so the concatenation is exactly what
        ; the server sent (the CSV uses CRLF, which a line-wise copy drops)
        nb = (file_info(part)).size
        if nb gt 0 then begin
          buf = bytarr(nb)
          openr, plun, part, /get_lun
          readu, plun, buf
          free_lun, plun
          writeu, olun, buf
        endif
        file_delete, part, /allow_nonexistent, /quiet
        s0 = s1
      endfor
      free_lun, olun
    endelse

    if keyword_set(derr) then begin
      file_delete, tmp, /allow_nonexistent, /quiet
      if file_test(path, /regular) then begin
        dprint, dlevel=1, 'WDC HAPI: keeping the cached ' + path
        files = [files, path]
      endif
      c0 = c1
      continue
    endif
    file_move, tmp, path, /overwrite

    ; every record already at the highest processing level -> immutable
    nrec = file_lines(path)
    is_final = 0
    if vcol ge 0 && nrec gt 0 then begin
      catch, rerr
      if rerr eq 0 then begin
        types = ['String', replicate('Double', npar - 1)]
        csv = read_csv(path, types=types)
        vc = long(csv.(vcol))
        is_final = (total(vc / 10 ne top_level) eq 0) ? 1 : 0
      endif
      catch, /cancel
    endif

    meta = orderedhash()
    meta['dataset'] = dataset
    meta['server'] = 'https://wdc.kugi.kyoto-u.ac.jp/hapi'
    meta['format'] = 'csv'
    meta['time_min'] = smin
    meta['time_max'] = smax
    meta['modificationDate'] = info.HasKey('modificationDate') ? info['modificationDate'] : ''
    meta['retrieved'] = time_string(systime(/seconds), tformat='YYYY-MM-DDThh:mm:ssZ')
    meta['nrecords'] = nrec
    meta['complete'] = (c1 le ds_stop) ? 1 : 0    ; not truncated by stopDate
    meta['final'] = is_final
    openw, mlun, meta_path, /get_lun
    printf, mlun, json_serialize(meta)
    free_lun, mlun

    dprint, dlevel=2, 'WDC HAPI: downloaded ' + path
    files = [files, path]
    c0 = c1
  endwhile

  if n_elements(files) eq 0 then return, ''
  return, files
end
