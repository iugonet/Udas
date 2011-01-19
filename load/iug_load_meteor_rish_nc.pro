;+
;
;Name:
;iug_load_meteor_rish_nc
;
;Purpose:
;  Queries the Kyoto_RISH renkei2 servers for the NetCDF data of the meteor radar 
;  and loads data into tplot format.
;
;Syntax:
; iug_load_meteor_rish_nc, datatype = datatype, site = site, downloadonly = downloadonly, $
;                           trange = trange, verbose=verbose
;
;Keywords:
;  datatype = Observation data type. For example, iug_load_meteor_rish_nc, datatype = 'thermosphere'.
;            The default is 'thermosphere'. 
;  site  = Observatory code name.  For example, iug_load_meteor_rish_txt, site = 'srp'.
;          The default is 'all', i.e., load all available stations.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;Code:
;  A. Shinbori, 28/08/2010.
;  
;Modifications:
;  A. Shinbori, 10/09/2010.
;  A. Shinbori, 25/11/2010.
;  
;Acknowledgment:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-


pro iug_load_meteor_rish_nc, datatype = datatype, site = site, parameter = parameter, $
                             downloadonly = downloadonly, trange = trange, verbose = verbose

;**************
;keyword check:
;**************
if (not keyword_set(verbose)) then verbose=2
 
;************************************
;Load 'thermosphere' data by default:
;************************************
if (not keyword_set(datatype)) then datatype='thermosphere'

;***********
;site codes:
;***********
;--- all sites (default)
site_code_all = strsplit('ktb srp',' ', /extract)

;--- check site codes
if(not keyword_set(site)) then site='all'
site_code = thm_check_valid_name(site, site_code_all, /ignore_case, /include_all)

print, site_code

;***********
;site codes:
;***********

;--- all sites (default)
parameter_all = strsplit('_h2t60min00 _h2T60min30 _h4t60min00 _h4T60min30 _h2t60min00 _h4t240min00',' ', /extract)

;--- check parameters
if(not keyword_set(parameter)) then parameter='all'
parameter = thm_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameter

;***************
;data directory:
;***************
site_data_dir = strsplit('/meteor/netCDF/h2km_t60min00/ /meteor/netCDF/h2km_t60min30/ /meteor/netCDF/h4km_t60min00/ ' +$
                         '/meteor/netCDF/h4km_t60min30/ /meteor/netCDF/h2km_t60min00/ /meteor/netCDF/h4km_t240min00/',' ', /extract)
site_data_lastmane = strsplit('_koto_h2t60min00.nc _koto_h2T60min30.nc _koto_h4t60min00.nc _koto_h4T60min30.nc _serp_h2t60min00.nc _serp_h4t240min00.nc',' ', /extract)

;Acknowlegment string (use for creating tplot vars)
acknowledgstring = 'Scientists who want to engage in collaboration with Research Institute for Sustainable Humanosphere (RISH) ' $
+ 'should contact the principal investigator of the meteor wind (MW) radar in Indonesia ' $
+ 'Prof. Toshitaka Tsuda, Kyoto University, who will organize such collaborations. ' $
+ 'There is a possibility that the PI of the MW radar will arrange offers so that there is less overlapping of themes between our research groups' $
+ 'Before you use the MW radar data for your papers, you must agree to the following points;' $
+ '  1. Before you submit your paper, you must contact the PI (Prof. Toshitaka Tsuda: tsuda@rish.kyoto-u.ac.jp) and discuss authorship.' $
+ '  2. When you submit your paper after doing the above item 1, you must mention the source of the data in the acknowledgment section of your paper.' $
+ '  3. In all circumstances, if anything is published you must send a hardcopy to the following address:' $
+ '    Prof. Toshitaka Tsuda' $
+ '    PI of the MW radar in Indonesia' $
+ '    Director of Research Institute for Sustainable Humanosphere,' $
+ '    Kyoto University' $
+ '    Gokasyo, Uji Kyoto 611-0011, Japan' $
+ '    e-mail: tsuda@rish.kyoto-u.ac.jp' 


;==================================================================
;Download files, read data, and create tplot vars at each component
;==================================================================
;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
h=0
jj=0
for ii=0,n_elements(site_code)-1 do begin

  if site_code[ii] eq 'ktb' then begin 
     h_min=0
     h_max=4
  endif
  
  if site_code[ii] eq 'srp' then begin 
     h_min=4
     h_max=6
  endif
  
  for iii=h_min,h_max-1 do begin
  
    if ~size(fns,/type) then begin

    ;Get files for ith component:
    ;***************************       
      file_names = file_dailynames( $
                   file_format='YYYY/'+$
                   'YYYYMM',trange=trange,times=times,/unique)+site_data_lastmane[iii]
    ;        
    ;Define FILE_RETRIEVE structure:
    ;===============================
       source = file_retrieve(/struct)
       source.verbose=verbose
       source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/'+site_code[ii]+site_data_dir[iii]

    ;source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/ear/data/data/ver02.0212/'
    
    ;Get files and local paths, and concatenate local paths:
    ;=======================================================
       local_paths=file_retrieve(file_names,_extra=source, /last_version)
       local_paths_all = ~(~size(local_paths_all,/type)) ? $
                        [local_paths_all, local_paths] : local_paths
       if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
    endif else file_names=fns

    ;--- Load data into tplot variables
    if(not keyword_set(downloadonly)) then downloadonly=0

    if(downloadonly eq 0) then begin

     ; Initialize data and time buffer
      site_time=0
      zon_wind=0
      mer_wind=0
      zon_thermal=0
      mer_thermal=0
      meteor_num=0 
      
 
 ;Loop on files (read the NetCDF files): 
 ;======================================
      for j=jj,n_elements(local_paths)-1 do begin
          file= local_paths[j]
          if file_test(/regular,file) then  dprint,'Loading meteor radar data file: ',file $
          else begin
             dprint,'Meteor radar data file',file,'not found. Skipping'
             continue
          endelse
    
          cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
          glob = ncdf_inquire( cdfid )    ; Find out general info

     ; Show user the size of each dimension

          print,'Dimensions', glob.ndims
          for i=0,glob.ndims-1 do begin
              ncdf_diminq, cdfid, i, name,size
              if i EQ glob.recdim then  $
                 print,'    ', name, size, '(Unlimited dim)' $
              else      $
                 print,'    ', name, size  
          endfor

     ; Now tell user about the variables

          print
          print, 'Variables'
          for m=0,glob.nvars-1 do begin

        ; Get information about the variable
              info = ncdf_varinq(cdfid, m)
              FmtStr = '(A," (",A," ) Dimension Ids = [ ", 10(I0," "),$)'
              print, FORMAT=FmtStr, info.name,info.datatype, info.dim[*]
              print, ']'

        ; Get attributes associated with the variable
              for l=0,info.natts-1 do begin
                  attname = ncdf_attname(cdfid,m,l)
                  ncdf_attget,cdfid,m,attname,attvalue
                  print,' Attribute ', attname, '=', string(attvalue)
              endfor
          endfor
    ; Get the variable
          ncdf_varget, cdfid, 'time', time
          ncdf_varget, cdfid, 'range', range
          ncdf_varget, cdfid, 'uwind', uwind
          ncdf_varget, cdfid, 'vwind', vwind
          ncdf_varget, cdfid, 'sig_uwind', sig_uwind
          ncdf_varget, cdfid, 'sig_vwind', sig_vwind
          ncdf_varget, cdfid, 'num', num
    
    ; Definition of arrary names
          timeunix = dblarr(n_elements(time))
          height=fltarr(n_elements(range))
          uwind_data=fltarr(n_elements(time),n_elements(range))
          vwind_data=fltarr(n_elements(time),n_elements(range))
          sig_uwind_data=fltarr(n_elements(time),n_elements(range))
          sig_vwind_data=fltarr(n_elements(time),n_elements(range))
          num_data=fltarr(n_elements(time),n_elements(range))

          for i=0, n_elements(time)-1 do begin
        ;Change hourtime since 1992-10-27 17:00:00 (Local Time) into unixtime (1970-01-01 00:00:00)
              timeunix[i] = double(time[i])*3600-3600*7$
                            +time_double(string(1992)+'-'+string(10)+'-'+string(27)+'/'+string(17)+':'+string(00)+':'+string(00))
                      
              for k=0, n_elements(range)-1 do begin
                  uwind_data[i,k]=uwind[0,k,i]
                  vwind_data[i,k]=vwind[0,k,i]
                  sig_uwind_data[i,k]=sig_uwind[0,k,i]
                  sig_vwind_data[i,k]=sig_vwind[0,k,i]
                  num_data[i,k]=num[0,k,i]
                  height[k]= range[k]/1000
                  
                  a = uwind_data[i,k]            
                  wbad = where(a eq -9999,nbad)
                  if nbad gt 0 then a[wbad] = !values.f_nan
                  uwind_data[i,k] =a
                  b = vwind_data[i,k]            
                  wbad = where(b eq -9999,nbad)
                  if nbad gt 0 then b[wbad] = !values.f_nan
                  vwind_data[i,k] =b
                  c = sig_uwind_data[i,k]            
                  wbad = where(c eq -9999,nbad)
                  if nbad gt 0 then c[wbad] = !values.f_nan
                  sig_uwind_data[i,k] =c
                  d = sig_vwind_data[i,k]            
                  wbad = where(d eq -9999,nbad)
                  if nbad gt 0 then d[wbad] = !values.f_nan
                  sig_vwind_data[i,k] =d
                  e = num_data[i,k]            
                  wbad = where(e eq -9999,nbad)
                  if nbad gt 0 then e[wbad] = !values.f_nan
                  num_data[i,k] =e
              endfor
          endfor
    
   ;Append data of time and wind velocity:
   ;======================================
      append_array, site_time, timeunix
      append_array, zon_wind, uwind_data
      append_array, mer_wind, vwind_data
      append_array, zon_thermal, sig_uwind_data
      append_array, mer_thermal, sig_vwind_data
      append_array, meteor_num, num_data
      ncdf_close,cdfid  ; done

  endfor

;******************************
;Store data in TPLOT variables:
;******************************

;Store data of meteor wind data:
;===============================

  if site_time[0] ne 0 then begin
     dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Tsuda'))
     store_data,'iug_meteor_'+site_code[ii]+'_uwnd'+parameter[iii],data={x:site_time, y:zon_wind, v:height},dlimit=dlimit
     options,'iug_meteor_'+site_code[ii]+'_uwnd'+parameter[iii],ytitle='MW-'+site_code[ii]+'!CHeight!C[km]',ztitle='uwnd!C[m/s]'
     store_data,'iug_meteor_'+site_code[ii]+'_vwnd'+parameter[iii],data={x:site_time, y:mer_wind, v:height},dlimit=dlimit
     options,'iug_meteor_'+site_code[ii]+'_vwnd'+parameter[iii],ytitle='MW-'+site_code[ii]+'!CHeight!C[km]',ztitle='vwnd!C[m/s]'
     store_data,'iug_meteor_'+site_code[ii]+'_uwndsig'+parameter[iii],data={x:site_time, y:zon_thermal, v:height},dlimit=dlimit
     options,'iug_meteor_'+site_code[ii]+'_uwndsig'+parameter[iii],ytitle='MW-'+site_code[ii]+'!CHeight!C[km]',ztitle='uwndsig!C[m/s]'
     store_data,'iug_meteor_'+site_code[ii]+'_vwndsig'+parameter[iii],data={x:site_time, y:mer_thermal, v:height},dlimit=dlimit
     options,'iug_meteor_'+site_code[ii]+'_vwndsig'+parameter[iii],ytitle='MW-'+site_code[ii]+'!CHeight!C[km]',ztitle='vwndsig!C[m/s]'
     store_data,'iug_meteor_'+site_code[ii]+'_mwnum'+parameter[iii],data={x:site_time, y:meteor_num, v:height},dlimit=dlimit
     options,'iug_meteor_'+site_code[ii]+'_mwnum'+parameter[iii],ytitle='MW-'+site_code[ii]+'!CHeight!C[km]',ztitle='mwnum'


     ; add options
     options, ['iug_meteor_'+site_code[ii]+'_uwnd'+parameter[iii],'iug_meteor_'+site_code[ii]+'_vwnd'+parameter[iii],$
               'iug_meteor_'+site_code[ii]+'_uwndsig'+parameter[iii],'iug_meteor_'+site_code[ii]+'_vwndsig'+parameter[iii],$
               'iug_meteor_'+site_code[ii]+'_mwnum'+parameter[iii]], 'spec', 1

     ; add options of setting labels
     options,'iug_meteor_'+site_code[ii]+'_uwnd'+parameter[iii], labels='MW '+site_code[ii]+parameter[iii]+' [km]'
     options,'iug_meteor_'+site_code[ii]+'_vwnd'+parameter[iii], labels='MW '+site_code[ii]+parameter[iii]+' [km]'
     options,'iug_meteor_'+site_code[ii]+'_uwndsig'+parameter[iii], labels='MW '+site_code[ii]+parameter[iii]+' [km]'
     options,'iug_meteor_'+site_code[ii]+'_vwndsig'+parameter[iii], labels='MW '+site_code[ii]+parameter[iii]+' [km]'
     options,'iug_meteor_'+site_code[ii]+'_mwnum'+parameter[iii], labels='MW '+site_code[ii]+parameter[iii]+' [km]'
   endif
  
  ;Clear time and data buffer:
   site_time=0
   zon_wind=0
   mer_wind=0
   zon_thermal=0
   mer_thermal=0
   meteor_num=0
   ; add tdegap
   tdegap, 'iug_meteor_'+site_code[ii]+'_uwnd'+parameter[iii],/overwrite
   tdegap, 'iug_meteor_'+site_code[ii]+'_vwnd'+parameter[iii],/overwrite
   tdegap, 'iug_meteor_'+site_code[ii]+'_uwndsig'+parameter[iii],/overwrite
   tdegap, 'iug_meteor_'+site_code[ii]+'_vwndsig'+parameter[iii],/overwrite
   tdegap, 'iug_meteor_'+site_code[ii]+'_mwnum'+parameter[iii],/overwrite
   
  endif
  jj=n_elements(local_paths)
  endfor
  jj=n_elements(local_paths) 
endfor 

print,'******************************
print, 'Data loading is successful!!'
print,'******************************

;******************************
;print of acknowledgement:
;******************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'Scientists who want to engage in collaboration with Research Institute for Sustainable Humanosphere (RISH) ' 
print, 'should contact the principal investigator of the meteor wind (MW) radar in Indonesia ' 
print, 'Prof. Toshitaka Tsuda, Kyoto University, who will organize such collaborations. ' 
print, 'There is a possibility that the PI of the MW radar will arrange offers so that there is less overlapping of themes between our research groups' 
print, 'Before you use the MW radar data for your papers, you must agree to the following points;' 
print, '  1. Before you submit your paper, you must contact the PI (Prof. Toshitaka Tsuda: tsuda@rish.kyoto-u.ac.jp) and discuss authorship.' 
print, '  2. When you submit your paper after doing the above item 1, you must mention the source of the data in the acknowledgment section of your paper.' 
print, '  3. In all circumstances, if anything is published you must send a hardcopy to the following address:' 
print, '    Prof. Toshitaka Tsuda' 
print, '    PI of the MW radar in Indonesia' 
print, '    Director of Research Institute for Sustainable Humanosphere,' 
print, '    Kyoto University' 
print, '    Gokasyo, Uji Kyoto 611-0011, Japan' 
print, '    e-mail: tsuda@rish.kyoto-u.ac.jp'  

end
