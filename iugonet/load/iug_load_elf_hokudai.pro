;+
; PROCEDURE:
;   iug_load_elf_hokudai, site = site, $
;                     trange=trange, $
;                     verbose=verbose, $
;                     downloadonly=downloadonly, $
;                     no_download=no_download
;
; PURPOSE:
;   This procedure loads the induction magnetometer data obtained 
;   by Hokkaido University.
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_elf_hokudai, site='syo',
;           the default is 'all', i.e., load all available stations.
;           Available sites: syo
;   trange : (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   iug_load_elf_hokudai, site = 'syo'
;
; Written by Y.-M. Tanaka, June 5, 2020
;-

pro iug_load_elf_hokudai, site=site, $
        trange=trange, verbose=verbose, downloadonly=downloadonly, $
	    no_download=no_download

;===== Keyword check =====;
;----- default -----;
if ~keyword_set(verbose) then verbose=0
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_download) then no_download=0

;----- site -----;
site_code_all = strsplit('syo', /extract)
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

print, site_code

instr='elf'

;===== Download files, read data, and create tplot vars at each site =====
;----- Loop -----
for i=0,n_elements(site_code)-1 do begin
  
  ;----- Set parameters for file_retrieve and download data files -----;
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir  = root_data_dir() + 'iugonet/hokudai/'
  source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/'
  if keyword_set(no_download) then source.no_download = 1
  if keyword_set(downloadonly) then source.downloadonly = 1

  file_format = instr + '/' + site_code[i] + '/YYYY/MM/YYYYMMDD/' + $
    'geon_' + instr + '_' + site_code[i] + '_YYYYMMDD_hh_v??.cdf'
  relpathnames  = file_dailynames(file_format=file_format,trange=trange,/hour_res)
  
  files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, no_server=no_server, no_download=no_download, _extra=source, /last_version)

  filestest=file_test(files)
  if total(filestest) ge 1 then begin
    files=files(where(filestest eq 1))
  endif

  ;----- Print PI info and rules of the road -----;
  if(file_test(files[0])) then begin
    gatt = cdf_var_atts(files[0])
    print, '**************************************************************************************'
    ;print, gatt.project
    print, gatt.Logical_source_description
    print, ''
    print, 'Information about ', gatt.Station_code
    print, 'PI: ', gatt.PI_name
    print, 'Affiliations: ', gatt.PI_affiliation
    print, ''
    print, 'Rules of the Road for Hokudai Induction Magnetometer Data:'
    print, ''
	for j=0, n_elements(gatt.TEXT)-1 do begin
        print_str_maxlet, gatt.TEXT[j]
	endfor
    print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
    print, '**************************************************************************************'
  endif

  ;----- Load data into tplot variables -----;
  if(downloadonly eq 0) then begin
    ;----- Rename tplot variables of hdz_tres -----;
    prefix='hokudai_'
	suffix='_'+site_code[i]
    cdf2tplot, file=files, verbose=source.verbose, prefix=prefix, suffix=suffix

    ;----- Missing data -1.e+31 --> NaN -----;
;    tclip, tplot_name_new, -1e+5, 1e+5, /overwrite;

    ;----- Labels -----;
    options, /def, 'hokudai_elf_*', labels=['H-comp.','D-comp.'], $
        labflag=1,colors=[2,4]
  endif

endfor

;---
return
end
