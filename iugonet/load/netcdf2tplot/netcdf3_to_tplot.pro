;+
; Procedure:
;         netcdf3_to_tplot
;
; Purpose:
;         Returns a tplot variable from general netCDF3 files
;
; Input:
;         files: netCDF files to be loaded
;
; Keywords:
;         prefix:
;         suffix:
;         verbose: request more verbose output
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro netcdf3_to_tplot, files, varnames, time_dimension=time_dimension, time_variable=time_variable, $
  v_dimension=v_dimension, v_variable=v_variable, $
  prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname,  $
  all = all, $
  verbose=verbose,$
  tplotnames=tplotnames

  ; check that netCDF is supported
  if ncdf_exists() eq 0 then begin
    dprint, 'netCDF not supported by the current IDL installation.'
    return
  endif

  ; load the netCDF file into an IDL struct
  ; this routine should work with any netCDF file,
  ; regardless of the format of the data
  netCDFi = netcdf3_load_vars(files)

  if size(netCDFi, /type) ne 8 then begin
    dprint, dlevel = 0, 'netCDFi was invalid. Trouble loading the netCDF file into an IDL structure.'
    return
  endif

  ; create tplot variables from the struct
  netcdf3_info_to_tplot, netcdfi, varnames, time_dimension=time_dimension, time_variable=time_variable, $
  v_dimension=v_dimension, v_variable=v_variable, $
  prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname,  $
  all = all, $
  verbose=verbose,$
  tplotnames=tplotnames

end
