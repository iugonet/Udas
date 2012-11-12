;+
;
;NAME:
;iug_load_mu_meteor_nc
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the horizontal wind data (uwnd, vwnd, uwndsig, vwndsig, mwnum)
;  in the NetCDF format estimated from the meteor wind special observation of the MU radar at Shigaraki
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_meteor_nc, datatype = datatype, parameter = parameter,length = length,downloadonly = downloadonly, $
;                           trange = trange, verbose=verbose
;
;KEYWOARDS:
;  datatype = Observation data type. For example, iug_load_mu_meteor_nc, datatype = 'thermosphere'.
;            The default is 'thermosphere'.
;  length = Data length '1-day' or '1-month'. For example, iug_load_mu_meteor_nc, length = '1_day'.
;           A kind of parameters is 2 types of '1_day', and '1_month'.   
;  parameters = Data parameter. For example, iug_load_meteor_srp_nc, parameter = 'h1t60min00'. 
;             A kind of parameters is 2 types of 'h1t60min00', 'h1t30min00'.
;             The default is 'all'.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;CODE:
; A. Shinbori, 06/07/2012.
;
;MODIFICATIONS:
; A. Shinbori, 08/08/2012.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-

pro iug_load_mu_meteor_nc, datatype = datatype, $
   parameter = parameter, $
   length=length, $
   downloadonly = downloadonly, $
   trange = trange, $
   verbose = verbose
   
;**************
;keyword check:
;**************
if (not keyword_set(verbose)) then verbose=2
 
;************************************
;Load 'thermosphere' data by default:
;************************************
if (not keyword_set(datatype)) then datatype='thermosphere'

;*****************************
;Load '1_day' data by default:
;*****************************
if (not keyword_set(length)) then length='1_day'

;***********
;parameters:
;***********

;--- all parameters (default)
parameter_all = strsplit('h1t60min00 h1t60min30 h2t60min00 h2t60min30',' ', /extract)

;--- check parameters
if(not keyword_set(parameter)) then parameter='all'
parameters = thm_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;************************************
;Data directory and last names check:
;************************************

site_data_dir=strarr(n_elements(parameters))
site_data_lastmane=strarr(n_elements(parameters))

for i=0, n_elements(site_data_dir)-1 do begin
   site_data_dir[i]=strmid(parameters[i],0,2)+'km_'+strmid(parameters[i],2,strlen(parameters[i])-2)+'/'
   site_data_lastmane[i]=parameters[i]
endfor

;==================================================================
;Download files, read data, and create tplot vars at each component
;==================================================================
;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
jj=0
for iii=0,n_elements(parameters)-1 do begin
   if ~size(fns,/type) then begin     
      if length eq '1_day' then begin 
        ;
        ;Get files for ith component:
        ;***************************       
         file_names = file_dailynames( $
                      file_format='YYYY/W'+$
                      'YYYYMMDD',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.nc'
      endif else if length eq '1_month' then begin
        ;
        ;Get files for ith component:
        ;***************************       
         file_names = file_dailynames( $
                      file_format='YYYY/W'+$
                      'YYYYMM',trange=trange,times=times,/unique)+'.'+site_data_lastmane[iii]+'.nc'
      endif
     ;        
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/sgk/mu/meteor/nc/'+length+'/'+site_data_dir[iii]
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/meteor/data/netcdf/'+length+'/'+site_data_dir[iii]
    
     ;Get files and local paths, and concatenate local paths:
     ;=======================================================
      local_paths=file_retrieve(file_names,_extra=source, /last_version)
      local_paths_all = ~(~size(local_paths_all,/type)) ? $
                       [local_paths_all, local_paths] : local_paths
      if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
   endif else file_names=fns

  ;--- Load data into tplot variables
   if (not keyword_set(downloadonly)) then downloadonly=0

   if (downloadonly eq 0) then begin
      
     ;Loop on files (read the NetCDF files): 
     ;======================================
      for j=jj,n_elements(local_paths)-1 do begin
         file= local_paths[j]
         if file_test(/regular,file) then  dprint,'Loading the wind data estimated from the meteor observation of the MU radar: ',file $
         else begin
            dprint,'The wind data estimated from the meteor observation of the MU radar ',file,' not found. Skipping'
            continue
         endelse
    
         cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
         glob = ncdf_inquire( cdfid )    ; Find out general info

        ;Show user the size of each dimension

         print,'Dimensions', glob.ndims
         for i=0,glob.ndims-1 do begin
            ncdf_diminq, cdfid, i, name,size
            if i EQ glob.recdim then  $
               print,'    ', name, size, '(Unlimited dim)' $
            else      $
               print,'    ', name, size  
         endfor
   
        ;Now tell user about the variables
   
          print
          print, 'Variables'
          for m=0,glob.nvars-1 do begin
   
            ;Get information about the variable
             info = ncdf_varinq(cdfid, m)
             FmtStr = '(A," (",A," ) Dimension Ids = [ ", 10(I0," "),$)'
             print, FORMAT=FmtStr, info.name,info.datatype, info.dim[*]
             print, ']'

            ;Get attributes associated with the variable
             for l=0,info.natts-1 do begin
                attname = ncdf_attname(cdfid,m,l)
                ncdf_attget,cdfid,m,attname,attvalue
                print,' Attribute ', attname, '=', string(attvalue)
                if (info.name eq 'time') and (attname eq 'units') then time_data=string(attvalue)
             endfor
          endfor

         ;Calculation the start time infomation from the attribute data:
          time_info=strsplit(time_data,' ',/extract)
          syymmdd=time_info[2]
          shhmmss=time_info[3]
          time_diff=strsplit(time_info[4],':',/extract)
          time_diff2=fix(time_diff[0])*3600+fix(time_diff[1])*60 

         ;Get the variable
          ncdf_varget, cdfid, 'time', time
          ncdf_varget, cdfid, 'range', range
          ncdf_varget, cdfid, 'uwind', uwind
          ncdf_varget, cdfid, 'vwind', vwind
          ncdf_varget, cdfid, 'sig_uwind', sig_uwind
          ncdf_varget, cdfid, 'sig_vwind', sig_vwind
          ncdf_varget, cdfid, 'num', num

         ;Definition of arrary names
          unix_time = dblarr(n_elements(time))
          height=fltarr(n_elements(range))
          uwind_data=fltarr(n_elements(time),n_elements(range))
          vwind_data=fltarr(n_elements(time),n_elements(range))
          sig_uwind_data=fltarr(n_elements(time),n_elements(range))
          sig_vwind_data=fltarr(n_elements(time),n_elements(range))
          num_data=fltarr(n_elements(time),n_elements(range))

          for i=0, n_elements(time)-1 do begin
            ;Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)    
             unix_time[i] = double(time[i])+time_double(syymmdd+'/'+shhmmss)-time_diff2 
            ;Replace the missing value by NAN for meteor observations: 
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
         ;======================================     
         ;Append data of time and wind velocity:
         ;======================================
          append_array, site_time, unix_time
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

     ;Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'If you acquire the middle and upper atmospher (MU) radar data, ' $
                       + 'we ask that you acknowledge us in your use of the data. This may be done by' $
                       + 'including text such as the MU data provided by Research Institute' $
                       + 'for Sustainable Humanosphere of Kyoto University. We would also' $
                       + 'appreciate receiving a copy of the relevant publications.'

      if size(zon_wind,/type) eq 4 then begin
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'T. Nakamura'))
         store_data,'iug_mu_meteor_uwnd_'+parameters[iii],data={x:site_time, y:zon_wind, v:height},dlimit=dlimit
         options,'iug_mu_meteor_uwnd_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='uwnd!C[m/s]'
         store_data,'iug_mu_meteor_vwnd_'+parameters[iii],data={x:site_time, y:mer_wind, v:height},dlimit=dlimit
         options,'iug_mu_meteor_vwnd_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='vwnd!C[m/s]'
         store_data,'iug_mu_meteor_uwndsig_'+parameters[iii],data={x:site_time, y:zon_thermal, v:height},dlimit=dlimit
         options,'iug_mu_meteor_uwndsig_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='uwndsig!C[m/s]'
         store_data,'iug_mu_meteor_vwndsig_'+parameters[iii],data={x:site_time, y:mer_thermal, v:height},dlimit=dlimit
         options,'iug_mu_meteor_vwndsig_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='vwndsig!C[m/s]'
         store_data,'iug_mu_meteor_mwnum_'+parameters[iii],data={x:site_time, y:meteor_num, v:height},dlimit=dlimit
         options,'iug_mu_meteor_mwnum_'+parameters[iii],ytitle='MU-meteor!CHeight!C[km]',ztitle='mwnum'

         new_vars=tnames('iug_mu_meteor_*')
         if new_vars[0] ne '' then begin
           ;Add options
            options, ['iug_mu_meteor_uwnd_'+parameters[iii],'iug_mu_meteor_vwnd_'+parameters[iii],$
                      'iug_mu_meteor_uwndsig_'+parameters[iii],'iug_mu_meteor_vwndsig_'+parameters[iii],$
                      'iug_mu_meteor_mwnum_'+parameters[iii]], 'spec', 1

           ;Add options of setting labels
            options,'iug_mu_meteor_uwnd_'+parameters[iii], labels='MU meteor'+parameters[iii]+' [km]'
            options,'iug_mu_meteor_vwnd_'+parameters[iii], labels='MU meteor'+parameters[iii]+' [km]'
            options,'iug_mu_meteor_uwndsig_'+parameters[iii], labels='MU meteor'+parameters[iii]+' [km]'
            options,'iug_mu_meteor_vwndsig_'+parameters[iii], labels='MU meteor'+parameters[iii]+' [km]'
            options,'iug_mu_meteor_mwnum_'+parameters[iii], labels='MU meteor'+parameters[iii]+' [km]'
         endif
      endif
  
     ;Clear time and data buffer:
      site_time=0
      zon_wind=0
      mer_wind=0
      zon_thermal=0
      mer_thermal=0
      meteor_num=0

      new_vars=tnames('iug_mu_meteor_*')
      if new_vars[0] ne '' then begin  
        ;Add tdegap
         tdegap, 'iug_mu_meteor_uwnd_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_vwnd_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_uwndsig_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_vwndsig_'+parameters[iii],dt=3600,/overwrite
         tdegap, 'iug_mu_meteor_mwnum_'+parameters[iii],dt=3600,/overwrite
   
        ;Add tclip
         tclip, 'iug_mu_meteor_uwnd_'+parameters[iii],-400,400,/overwrite
         tclip, 'iug_mu_meteor_vwnd_'+parameters[iii],-400,400,/overwrite
         tclip, 'iug_mu_meteor_uwndsig_'+parameters[iii],0,800,/overwrite
         tclip, 'iug_mu_meteor_vwndsig_'+parameters[iii],0,800,/overwrite
         tclip, 'iug_mu_meteor_mwnum_'+parameters[iii],0,1200,/overwrite  
      endif
   endif
   jj=n_elements(local_paths)
endfor

new_vars=tnames('iug_mu_meteor_*')
if new_vars[0] ne '' then begin
   print,'******************************
   print, 'Data loading is successful!!'
   print,'******************************
endif

;******************************
;print of acknowledgement:
;******************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire the middle and upper atmosphere (MU) radar data, '
print, 'we ask that you acknowledge us in your use of the data. ' 
print, 'This may be done by including text such as MU data provided ' 
print, 'by Research Institute for Sustainable Humanosphere of Kyoto University. ' 
print, 'We would also appreciate receiving a copy of the relevant publications.'

end

