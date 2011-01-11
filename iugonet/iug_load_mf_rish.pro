;+
;
;Name:
;iug_load_mf_rish
;
;Purpose:
;  Queries the Kyoto_RISH renkei2 servers for the pameungpeuk and pontiank data 
;  and loads data into tplot format.
;
;Syntax:
; iug_load_mf_rish, datatype = datatype, site=site, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;Keywords:
; datatype = Observation data type. For example, iug_load_mf_rish, datatype = 'thermosphere'.
;            The default is 'thermosphere'. 
;   site  = Observatory code name.  For example, iug_load_mf_rish, site = 'pam'.
;          The default is 'all', i.e., load all available stations.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;
;Code:
;  A. Shinbori, 10/09/2010.
;
;Modifications:
;  A. Shinbori, 25/11/2010.
;  A. Shinbori, 10/01/2011.
;  
;Acknowledgment:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-


pro iug_load_mf_rish, datatype = datatype, site=site, $
                           downloadonly=downloadonly, trange=trange, verbose=verbose



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
site_code_all = strsplit('pam pon',' ', /extract)

;--- check site codes
if(not keyword_set(site)) then site='all'
site_code = thm_check_valid_name(site, site_code_all, /ignore_case, /include_all)

print, site_code

for i=0, n_elements(site_code)-1 do begin
  if site_code[i] eq 'pam' then iug_load_mf_rish_pam_nc, site = site_code[i], downloadonly=downloadonly, trange=trange, verbose=verbose
  if site_code[i] eq 'pon' then iug_load_mf_rish_pon_txt, site = site_code[i], downloadonly=downloadonly, trange=trange, verbose=verbose
endfor

;******************************
;print of acknowledgement:
;******************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire MF radar data, we ask that you acknowledge us'
print, 'in your use of the data. This may be done by including text' 
print, 'such as MF radar data provided by Research Institute for Sustainable' 
print, 'Humanosphere of Kyoto University. We would also appreciate receiving' 
print, 'a copy of the relevant publications.'

end
