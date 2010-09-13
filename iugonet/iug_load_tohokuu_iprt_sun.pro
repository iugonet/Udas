;+
;Procedure: iug_load_tohokuu_iprt_sun,
;  iug_load_tohokuu_iprt_sun, site = site, datatype = datatype, $
;                         trange = trange, verbose = verbose, $
;                         addmaster=addmaster, downloadonly = downloadonly
;Purpose:
;  This procedure allows you to download and plot TOHOKUU_RADIO OBSERVATION data on TDAS.
;  This is a sample code for IUGONET analysis software.
;
;Keywords:
;  site  = Observatory name. Only 'iit' is allowed.
;  datatype = The type of data to be loaded.  In this sample
;             procedure, there is only one option, the default value of 'pc3i'.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /verbose, if set, then output some useful info
;  /addmaster, if set, then times = [!values.d_nan, times]
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
; PROCEDURES USED:
;  fits_read,sxpar
;
;Example:
;  timespan,'2010-02-07',/day
;  iug_load_tohokuu_iprt_sun
;  tplot_names
;  zlim,'iprt_sun_L',0,12
;  zlim,'iprt_sun_R',0,12
;  tplot,['iprt_sun_L','iprt_sun_R']
;
;
;Code:
;  Shuji Abe, revised by M. Kagitani
;
;ChangeLog:
;  7-April-2010, abeshu, test release.
;  8-April-2010, abeshu, minor update.
;  27-JUL.-2010, revised for this procedure by M. Kagitani
;
;Acknowledgment:
;
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-



;**************************
;***** Main Procedure *****
;**************************
pro iug_load_tohokuu_iprt_sun, site=site, datatype = datatype, $
                           trange = trange, verbose = verbose, $
                           addmaster=addmaster, downloadonly = downloadonly


;*************************
;***** Keyword check *****
;*************************
; verbose
if ~keyword_set(verbose) then verbose=0

; data type
if ~keyword_set(datatype) then datatype='Sun'
if ~keyword_set(site) then datatype='iit'

; validate datatype
vns=['Sun','Jupiter']
if size(datatype,/type) eq 7 then begin
  datatype=thm_check_valid_name(datatype,vns, $
                                /ignore_case, /include_all, /no_warning)
;  if datatype[0] eq '' then return ;<=== NOTE FOR THIS LINE !!!
endif else begin
  message,'DATATYPE must be of string type.',/info
  return
endelse

site = 'iit'
; list of sites
vsnames = 'iit'
vsnames_all = strsplit(vsnames, ' ', /extract)

; validate sites
if(keyword_set(site)) then site_in = site else site_in = 'all'
magdas_sites = thm_check_valid_name(site_in, vsnames_all, $
                                    /ignore_case, /include_all, /no_warning)
;if magdas_sites[0] eq '' then return

; number of valid sites
nsites = n_elements(magdas_sites)

; acknowlegment string (use for creating tplot vars)
acknowledgstring = 'Please contact Dr. Hiroaki Misawa.'


;*************************************************************************
;***** Download files, read data, and create tplot vars at each site *****
;*************************************************************************
;=================================
;=== Loop on downloading files ===
;=================================
; make remote path, local path, and download files

for i=0, nsites-1 do begin
  ; define file names
  pathformat= strupcase(strmid(magdas_sites[i],0,3)) + '/' + $
              'iprt_sun_YYYYMMDD'
  relpathnames = file_dailynames(file_format=pathformat, $
                                 trange=trange, addmaster=addmaster)+'.fits'
  ;relpathnames = file_monthlynames_onw(file_format=pathformat, $
  ;                               trange=trange, addmaster=addmaster)

  ; define remote and local path information
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir = root_data_dir() + 'tohokuU/'
  source.remote_data_dir = 'http://pparc.gp.tohoku.ac.jp/whi/data/'

  ; download data
  local_files = file_retrieve(relpathnames, _extra=source)

  ; if downloadonly set, go to the top of this loop
  if keyword_set(downloadonly) then continue

  ;===================================
  ;=== Loop on reading MAGDAS data ===
  ;===================================
  print,(local_files)


  for j=0,n_elements(local_files)-1 do begin
    file = local_files[j]

    if file_test(/regular,file) then begin
      dprint,'Loading IPRT SOLAR RADIO DATA file: ', file
      fexist = 1
    endif else begin
      dprint,'Loading IPRT SOLAR RADIO DATA file ',file,' not found. Skipping'
      continue
    endelse

    ; create base time
    year = (strmid(relpathnames[j],strlen(relpathnames[j])-10,4))
    month = (strmid(relpathnames[j],strlen(relpathnames[j])-6,2))
    ;year = (strmid(relpathnames[j],21,4))
    ;month = (strmid(relpathnames[j],25,2))
    ;day = (strmid(relpathnames[j],27,2))
    ;day = '01'
    ;basetime = time_double(year+'-'+month+'-'+day)


    ;===================================
    fits_read,file,data,hd
    date_start = time_double(sxpar(hd,'DATE-OBS')+'/'+sxpar(hd,'TIME-OBS'))
    timearr = date_start $
         + sxpar(hd,'CRVAL1') + (dindgen(sxpar(hd,'NAXIS1'))-sxpar(hd,'CRPIX1')) * sxpar(hd,'CDELT1')
    freq = sxpar(hd,'CRVAL2') + (dindgen(sxpar(hd,'NAXIS2'))-sxpar(hd,'CRPIX2')) * sxpar(hd,'CDELT2')
    ;dindgen(sxpar(hd,'NAXIS2'))

;print,time_string(date_start)
;stop
;    buf = fltarr(6)
;    line=''
;    yy=0L & mm=0L & dd=0L & doy=0L & pc3i=0. & pc3p=0.
;    openr,lun,file, /get_lun
;    readf,lun,line ; file header
;    readf,lun,line ; file header
;    readf,lun,line ; file header
    ;readf,lun,yy,mm,dd,doy,pc3i,pc3p
;    while not eof(lun) do begin
;      readf,lun,buf
      ;yy=[yy,buf[0]]
;      mm=[mm,buf[1]]
      ;dd=[dd,buf[2]]
      ;doy=[doy,buf[3]]
;      pc3i=[pc3i,buf[4]]
     ; pc3p=[pc3p,buf[5]]
    ;endwhile
;    free_lun,lun
    append_array,databufL,data[*,*,0]
    append_array,databufR,data[*,*,1]
    append_array,timebuf,timearr
    ;===================================
;stop
;    ; open file
;    openr, lun, file, /get_lun
;
;    ; seek delimiter
;    buf = bytarr(1, 1)
;    while (buf ne 26) do begin
;      readu, lun, buf
;    end
;    readu, lun, buf
;
;    ; read data
;    rdata = fltarr(7, 1440)
;    readu, lun, rdata
;    rdata = transpose(rdata)
;
;    ; close file
;    free_lun, lun
;
;    ; append data and time index
;    append_array, databuf, rdata
;    append_array, timebuf, basetime + dindgen(1440)*60d

  endfor

  ;=======================================
  ;=== Loop on creating tplot variable ===
  ;=======================================
  if size(databufL,/type) eq 1 then begin
    ; tplot variable name
    ;tplot_name = 'onw_pc3_' + strlowcase(strmid(magdas_sites[i],0,3)) + '_pc3'
    tplot_nameL = 'iprt_sun_L'
    tplot_nameR = 'iprt_sun_R'

    ; for bad data
    wbad = where(finite(databufL) gt 99999, nbad)
    if nbad gt 0 then databufL[wbad] = !values.f_nan

    wbad = where(databufL lt 0, nbad)
    if nbad gt 0 then databuL[wbad] = !values.f_nan

    ; default limit structure
    dlimit=create_struct('data_att',create_struct('acknowledgment', acknowledgstring, $
                                                  'PI_NAME', 'H. Misawa') $
                        ,'SPEC',1)

    ; store data to tplot variable
    store_data, tplot_nameL, data={x:timebuf, y:databufL, v:freq}, dlimit=dlimit
    store_data, tplot_nameR, data={x:timebuf, y:databufR, v:freq}, dlimit=dlimit

    ; add options
    options, tplot_nameL, labels=['IPRT_SUN_LCP'] , $
                         ytitle = sxpar(hd,'CTYPE2'), $
                         ysubtitle = '';, $
                         title = 'IPRT Solar radio data'
    options, tplot_nameR, labels=['IPRT_SUN_RCP'] , $
                         ytitle = sxpar(hd,'CTYPE2'), $
                         ysubtitle = '';, $
                         title = 'IPRT Solar radio data'
  endif

  ; clear data and time buffer
  databufL = 0
  databufR = 0
  timebuf = 0

; go to next site
endfor

end




