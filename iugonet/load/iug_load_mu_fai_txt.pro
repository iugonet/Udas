;+
;
;NAME:
;iug_load_mu_fai_txt
;
;PURPOSE:
;  Queries the Kyoto_RISH servers for the FAI observation data in the CSV format 
;  taken by the MU radar and loads data into tplot format.
;
;SYNTAX:
; iug_load_mu_fai_txt, datatype = datatype, parameter1=parameter1, parameter2=parameter2 $
;                          downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  datatype = Observation data type. For example, iug_load_mu_fai_txt, datatype = 'ionosphere'.
;            The default is 'ionosphere'. 
;  parameter1 = first parameter name of MU FAI obervation data.  
;          For example, iug_load_mu_fai_txt, parameter = 'iemdc3'.
;          The default is 'all', i.e., load all available parameters.
;  parameter2 = second parameter name of MU FAI obervation data.  
;          For example, iug_load_mu_fai_txt, parameter = 'dpl1'.
;          The default is 'all', i.e., load all available parameters.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;
;CODE:
; A. Shinbori, 01/08/2013.
; A. Shinbori, 10/10/2013.
; 
;MODIFICATIONS:
;
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-

pro iug_load_mu_fai_txt, datatype = datatype, $
  parameter1=parameter1, $
  parameter2=parameter2, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;**************
;keyword check:
;**************
if (not keyword_set(verbose)) then verbose=2
 
;**********************************
;Load 'ionosphere' data by default:
;**********************************
if (not keyword_set(datatype)) then datatype='ionosphere'

;************
;parameters1:
;************
;--- all parameters1 (default)
parameter1_all = strsplit('iecob3 ieewb5 ieimga ieimgb ieimgm ieimgt ieis01 iemb5i iemcb3 iemdb3 iemdb5 '+$
                          'iemdc3 iemy3a iemy3b iemy3c iemyb5 iensb5 iepbr1 iepbr2 iepbr3 iepbr4 iepbr5 '+$
                          'iepbrt ieper1 ieper2 ieper3 ieper4 ieper5 ieper6 ieper7 ieper8 '+$
                          'iepsi5 iepsit iesp01 iess01 iess02 iess03 iess04 iess05 iess2l '+$
                          'iess3l iess4l iess8c iessb5 iesst2 iesst3 iet101 iet102 ieto02 ieto03 '+$
                          'ieto16 ietob3 ietob4 ietob5 iey4ch iey4ct ieyo4a ieyo4b ieyo4c '+$
                          'ieyo4d ieyo4e ieyo4f ieyo4g ieyo5a ieyo5b ieyo5c ieyo5d ieyo5e '+$
                          'ieyo5f ieyo5g ieyo5m ifco02 ifco03 ifco04 ifco16 ifim16 ifmb16 ifmc16 '+$
                          'ifmd16 ifmf16 ifmy01 ifmy02 ifmy03 ifmy04 ifmy05 ifmyc1 ifmyc2 '+$
                          'ifmyc3 ifmyc4 ifmyc5 ifmyc6 ifmyc7 ifmyca ifmycb ifmyt1 ifmyt2 '+$
                          'ifmyt3 ifmyt4 ifmyt5 ifmyu1 ifmyu2 ifmyu3 ifmyu4 ifmyu5 ifmyv1 '+$
                          'ifpsi1 ifpsit ifss02 iftes1 iftes2 iftes3 iftes5 iftes6 iftes7 '+$
                          'iftes8 ifts01 ifts02 ifts03 ifts04 ifts05 ifts06 ifts07',' ', /extract)
;--- check site codes
if(not keyword_set(parameter1)) then parameter1='all'
parameters = thm_check_valid_name(parameter1, parameter1_all, /ignore_case, /include_all)

print, parameters

;************
;parameters2:
;************
;--- all parameters2 (default)
parameter2_all = strsplit('dpl1 dpl2 dpl3 dpl4 dpl5 pwr1 pwr2 pwr3 pwr4 pwr5 '+$
                          'wdt1 wdt2 wdt3 wdt4 wdt5 pn1 pn2 pn3 pn4 pn5',' ', /extract)

;--- check parameters
if(not keyword_set(parameter2)) then parameter2='all'
parameters2 = thm_check_valid_name(parameter2, parameter2_all, /ignore_case, /include_all)

print, parameters2

;*****************
;defition of unit:
;*****************
;--- all parameters2 (default)
unit_all = strsplit('m/s dB',' ', /extract)

;******************************************************************
;Loop on downloading files:
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
;
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
;Definition of parameter:
jj=0
for ii=0,n_elements(parameters)-1 do begin
   for iii=0,n_elements(parameters2)-1 do begin
      if ~size(fns,/type) then begin

        ;Get files for ith component:
        ;***************************
         file_names = file_dailynames( $
         file_format='YYYY/YYYYMMDD/'+$
                     'YYYYMMDD',trange=trange,times=times,/unique)+'.'+parameters[ii]+'.'+parameters2[iii]+'.csv'
        ;
        ;Define FILE_RETRIEVE structure:
        ;===============================
         source = file_retrieve(/struct)
         source.verbose=verbose
         source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/sgk/mu/fai/csv/'
         source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/mu/fai/data/csv/'
    
        ;Get files and local paths, and concatenate local paths:
        ;=======================================================
         local_paths=file_retrieve(file_names,_extra=source)
         local_paths_all = ~(~size(local_paths_all,/type)) ? $
                          [local_paths_all, local_paths] : local_paths
         if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
      endif else file_names=fns

     ;--- Load data into tplot variables
      if (not keyword_set(downloadonly)) then downloadonly=0

      if (downloadonly eq 0) then begin

        ;===================================================
        ;read data, and create tplot vars at each parameter:
        ;===================================================
        ;Read the files:
        ;===============
   
        ;Definition of parameters:
         s=''
         u=''

        ;Initialize data and time buffer
         mu_time=0
         mu_data=0
         
        ;==============
        ;Loop on files: 
        ;==============
         for h=jj,n_elements(local_paths)-1 do begin
            file= local_paths[h]
            if file_test(/regular,file) then  dprint,'Loading MU-FAI file: ',file $
            else begin
               dprint,'MU-FAI file ',file,' not found. Skipping'
               continue
            endelse  
            
            openr,lun,file,/get_lun  
            readf, lun, s  
           ;
           ;Read information of altitude:
           ;=============================    
            readf, lun, s
          
           ;Definition of altitude and data arraies:
            h_data = strsplit(s,',',/extract)
            altitude = fltarr(n_elements(h_data)-1)
          
           ;Enter the altitude information:
            for j=0,n_elements(h_data)-2 do begin
               altitude[j] = float(h_data[j+1])
            endfor
          
           ;Enter the missing value:
            for j=0,n_elements(altitude)-1 do begin
               b = altitude[j]
               wbad = where(b eq 0,nbad)
               if nbad gt 0 then b[wbad] = !values.f_nan
               altitude[j]=b
            endfor
           ;
           ;Loop on readdata:
           ;=================
            while(not eof(lun)) do begin
               readf,lun,s
               ok=1
               if strmid(s,0,1) eq '[' then ok=0
               if ok && keyword_set(s) then begin
                  dprint,s ,dlevel=5
                  data = strsplit(s,',',/extract)
                  data2 = fltarr(1,n_elements(data)-1)+!values.f_nan
                  
                 ;Calculate time:
                 ;==============
                  u=data(0)
                  year = strmid(u,0,4)
                  month = strmid(u,5,2)
                  day = strmid(u,8,2)
                  hour = strmid(u,11,2)
                  minute = strmid(u,14,2) 
                 
                 ;====Convert time from local time to unix time:      
                  time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+hour+':'+minute) $
                          -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(9)+':'+string(0)+':'+string(0))
                 ;
                 ;Enter the missing value:
                  for j=0,n_elements(data)-2 do begin
                     a = float(data[j+1])
                     wbad = where(a eq -999,nbad)
                     if nbad gt 0 then a[wbad] = !values.f_nan
                     data2[0,j]=a
                  endfor
                 ;
                 ;Append data of time and data:
                 ;=============================
                  append_array, mu_time, time
                  append_array, mu_data, data2
               endif
            endwhile 
            free_lun,lun  
         endfor

        ;==============================
        ;Store data in TPLOT variables:
        ;==============================
        ;Acknowlegment string (use for creating tplot vars)
      acknowledgstring = 'If you acquire the middle and upper atmospher (MU) radar data, ' $
                       + 'we ask that you acknowledge us in your use of the data. This may be done by ' $
                       + 'including text such as the MU data provided by Research Institute ' $
                       + 'for Sustainable Humanosphere of Kyoto University. We would also ' $
                       + 'appreciate receiving a copy of the relevant publications. '$
                       + 'The distribution of MU radar data has been partly supported by the IUGONET '$
                       + '(Inter-university Upper atmosphere Global Observation NETwork) project '$
                       + '(http://www.iugonet.org/) funded by the Ministry of Education, Culture, '$
                       + 'Sports, Science and Technology (MEXT), Japan.'
                   
         if size(mu_data,/type) eq 4 then begin
            if strmid(parameters2[iii],0,2) eq 'dp' then o=0
            if strmid(parameters2[iii],0,2) eq 'wd' then o=0 
            if strmid(parameters2[iii],0,2) eq 'pw' then o=1
            if strmid(parameters2[iii],0,2) eq 'pn' then o=1
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'M. Yamamoto'))
            store_data,'iug_mu_fai_'+parameters[ii]+'_'+parameters2[iii],data={x:mu_time, y:mu_data, v:altitude},dlimit=dlimit
            new_vars=tnames('iug_mu_fai_'+parameters[ii]+'_'+parameters2[iii])
            if new_vars[0] ne '' then begin
                options,'iug_mu_fai_'+parameters[ii]+'_'+parameters2[iii],ytitle='MU-FAI!CHeight!C[km]',ztitle=parameters2[iii]+'!C['+unit_all[o]+']'
                options,'iug_mu_fai_'+parameters[ii]+'_'+parameters2[iii], labels='MU-FAI [km]'         
               ;Add options
                if strmid(parameters2[iii],0,2) ne 'pn' then options, 'iug_mu_fai_'+parameters[ii]+'_'+parameters2[iii], 'spec', 1         
            endif       
         endif 
     
        ;Clear time and data buffer:
         mu_time=0
         mu_data=0
     
         new_vars=tnames('iug_mu_fai_*')
         if new_vars[0] ne '' then begin    
           ;Add tdegap
            tdegap, 'iug_mu_fai_'+parameters[ii]+'_'+parameters2[iii],/overwrite
         endif
      endif
      jj=n_elements(local_paths)
   endfor
   jj=n_elements(local_paths)
endfor
  
new_vars=tnames('iug_mu_fai_*')
if new_vars[0] ne '' then begin  
   print,'*****************************
   print,'Data loading is successful!!'
   print,'*****************************
endif

;*************************
;print of acknowledgement:
;*************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire the middle and upper atmosphere (MU) radar data,'
print, 'we ask that you acknowledge us in your use of the data.' 
print, 'This may be done by including text such as MU data provided' 
print, 'by Research Institute for Sustainable Humanosphere of Kyoto University.' 
print, 'We would also appreciate receiving a copy of the relevant publications.'
print, 'The distribution of MU radar data has been partly supported by the IUGONET'
print, '(Inter-university Upper atmosphere Global Observation NETwork) project'
print, '(http://www.iugonet.org/) funded by the Ministry of Education, Culture,'
print, 'Sports, Science and Technology (MEXT), Japan.'

end

