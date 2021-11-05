;+
;
;NAME:
; iug_load_gaia_cpl_nc
;
;PURPOSE:
;  Queries the NICT servers for the GAIA model (cpl part) data
;  provided by the GAIA project and loads data into tplot format.
;
;SYNTAX:
; iug_load_gaia_cpl_nc, parameter = parameter, downloadonly = downloadonly, trange = trange, verbose = verbose, uname = uname, passwd = passwd
;
;KEYWOARDS:
;  parameter = first parameter name of GAIA data.  
;          For example, iug_load_gaia_cpl_nc, parameter = 'efp'.
;          The default is 'all', i.e., load all available parameters.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  uname = user ID to be passed to the remote server for
;          authentication.
;  passwd = password to be passed to the remote server for
;          authentication.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  verbose (In): [1,...,5], Get more detailed (higher number) command line output.
;
;CODE:
; A. Shinbori, 16/04/2021.
;
;MODIFICATIONS:
; A. Shinbori, 26/10/2021.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-

pro iug_load_gaia_cpl_nc, parameter = parameter, downloadonly = downloadonly, trange = trange, verbose = verbose, uname = uname, passwd = passwd

  ;***********************
  ;***Keyword check***
  ;***********************
   if not keyword_set(verbose) then verbose = 2

  ;***********
  ;parameters:
  ;***********
  ;--- all parameters (default)
   parameter_all = strsplit('xoi xo2i xn2i xnoi ginao ginmo ginmn ginuu ginvv ginww te ti gintmp efr eft efp cur cut cup',' ', /extract)

   ;--- check site codes
   if(not keyword_set(parameter)) then parameter='all'
   parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

   print, parameters

  ;**************************
  ;Loop on downloading files:
  ;**************************
   ks=0L
   for j=0L,n_elements(parameters)-1 do begin
   
      if ~size(fns,/type) then begin
        ;****************************
        ;Get files for ith component:
        ;****************************
         file_names = file_dailynames(file_format = 'YYYY/' + parameters[j] + 'YYYYMMDD',trange = trange,times = times, /unique)+'cpl.nc'

        ;===============================
        ;Define FILE_RETRIEVE structure:
        ;===============================
         source = file_retrieve(/struct)
         source.verbose = verbose
         source.local_data_dir = root_data_dir() + 'gaia/wk3/gaia/'+parameters[j]+'_cpl/'
         source.remote_data_dir = 'https://aer-nc-web.nict.go.jp/gaia/wk3/gaia/'+parameters[j]+'_cpl/'

        ;=======================================================
        ;Get files and local paths, and concatenate local paths:
        ;=======================================================
         local_paths = spd_download(remote_file=file_names, remote_path=source.remote_data_dir, local_path=source.local_data_dir,$
                              _extra=source,url_username=uname, url_password=passwd, /last_version)
         local_paths_all = ~(~size(local_paths_all,/type)) ? $
                            [local_paths_all, local_paths] : local_paths
         if ~(~size(local_paths_all,/type)) then local_paths = local_paths_all
      endif else file_names = fns

     ;----Download only or not----
     ;----Yes: downloadonly is not equal to 0----
     ;----No: downloadonly is equal to 0----
      if (not keyword_set(downloadonly)) then downloadonly = 0

     ;----Load the GAIA data in case of downloadonly = 0----
      if (downloadonly eq 0) then begin

        ;---Initialize data and time buffer
         unix_time = 0
         gaia_data = 0
  
         for k=ks,n_elements(local_paths)-1 do begin
            file= local_paths[k]
           ;---Check wheter the specified file exists or not---
            if file_test(/regular,file) then  dprint,'Loading gaia cpl data file: ',file $
            else begin
               dprint, 'gaia cpl data file ',file,' not found. Skipping'
               continue
            endelse

           ;---Open the netCDF data---
            cdfid = ncdf_open(file,/NOWRITE)  ; Open the file
            glob = ncdf_inquire( cdfid )    ; Find out general info

           ;---Show user the size of each dimension:
            print,'Dimensions', glob.ndims
            for i=0L,glob.ndims-1 do begin
               ncdf_diminq, cdfid, i, name,size
               if i EQ glob.recdim then  $
                  print,'    ', name, size, '(Unlimited dim)' $
               else      $
                  print,'    ', name, size  
            endfor

           ;---Now tell user about the variables:
            print
            print, 'Variables'
            for m=0L,glob.nvars-1 do begin

              ;---Get information about the variable:
               info = ncdf_varinq(cdfid, m)
               FmtStr = '(A," (",A," ) Dimension Ids = [ ", 10(I0," "),$)'
               print, FORMAT=FmtStr, info.name,info.datatype, info.dim[*]
               print, ']'

              ;---Get attributes associated with the variable:
               for l=0L,info.natts-1 do begin
                  attname = ncdf_attname(cdfid,m,l)
                  ncdf_attget,cdfid,m,attname,attvalue
                  print,' Attribute ', attname, '=', string(attvalue)
                  if (info.name eq 'time') and (attname eq 'units') then time_data = string(attvalue)
                  if (info.name eq parameters[j]) and (attname eq 'long_name') then data_long_name = string(attvalue)
                  if (info.name eq parameters[j]) and (attname eq 'units') then data_units = string(attvalue)
               endfor
            endfor  
            
           ;---Get the start time infomation from the attribute data:
            time_info=strsplit(time_data,' ',/extract)
            syymmdd=time_info[2]
            shhmmss=time_info[3]
    
           ;---Get the variable:
            ncdf_varget, cdfid, 'time', time     ;0.25 to 23.75 hrs
            ncdf_varget, cdfid, 'lat', latitude     ;90 to -90 degs
            ncdf_varget, cdfid, 'lon', longitude     ;0 to 360 degs
            ncdf_varget, cdfid, 'lvl', altitude     ;0 to 1866.7 km
            ncdf_varget, cdfid, parameters[j], data
    
           ;---Definition of arrary names:
            gaia_data = fltarr(n_elements(time),n_elements(longitude),n_elements(latitude),n_elements(altitude))

           ;---Change seconds since the midnight of every day (Local Time) into unix time (1970-01-01 00:00:00)
            unix_time = time_double(string(syymmdd)+'/00:00:00') + time*3600.0
            for i=0L, n_elements(time)-1 do begin
               data_dummy=reform(data[*,*,*,i])
               gaia_data[i,*,*,*] = data_dummy

              ;---Replace missing value by NaN: 
               a = gaia_data[i,*,*,*]            
               wbad = where(a eq 0.00000,nbad)
               if nbad gt 0 then a[wbad] = !values.f_nan
               gaia_data[i,*,*,*] =a
            endfor

           ;==============================
           ;Append array of time and data:
           ;==============================
            append_array, unix_time_app, unix_time
            append_array, gaia_data_app, gaia_data
 
           ;---Close the netCDF data---
            ncdf_close,cdfid  ; done

         endfor
        ;==============================
        ;Store data in TPLOT variables:
        ;==============================
        ;---Acknowlegment string (use for creating tplot vars)
         acknowledgstring = ''

         if size(gaia_data,/type) eq 4 then begin
           ;---Create tplot variables and options for GAIA data:
            dlimit = create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'C. Tao'))
            store_data, 'gaia_cpl_' + parameters[j], data = {x:unix_time_app, y:gaia_data_app, glat:latitude, glon:longitude, alt:altitude}, dlimit=dlimit
            options, 'gaia_cpl_' + parameters[j], ztitle = data_long_name + ' [' + data_units +']'
         endif
      endif
      new_vars = tnames('gaia_cpl_'+parameters[j])
      if new_vars[0] ne '' then begin
         print,'******************************
         print, 'Data loading is successful!!'
         print,'******************************
      endif
      
     ;---Clear buffer:
      unix_time = 0
      gaia_data = 0
      unix_time_app = 0
      gaia_data_app = 0
      
      ks = n_elements(local_paths)
   endfor
   
  ;*************************
  ;Print of acknowledgement:
  ;*************************
   print, '****************************************************************
   print, 'Acknowledgement'
   print, '****************************************************************
   print, 'Note: If you would like to use following data for scientific purpose,
   print, 'please read and follow the DATA USE POLICY'
   print, 'The dataset used for this study is from the Ground-to-topside model of Atmosphere'
   print, 'and Ionosphere for Aeronomy (GAIA) project carried out by the National Institute of'
   print, 'Information and Communications Technology (NICT), Kyushu University, and Seikei'
   print, 'University.'
   print, 'The distribution of GAIA data has been partly supported by the IUGONET'
   print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
   print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, Sports, Science'
   print, 'and Technology (MEXT), Japan.'
 end
