;+
;
;  Name: SPD_UI_LOAD_SPEDAS_NETCDF
;  
;  Purpose: Loads data from a NetCDF chosen by user. Note that only NetCDFs that conform to SPEDAS standards can be opened. 
;  NetCDFs that do not conform may produce unhelpful error messages. 
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-02-07 10:44:31 -0800 (Wed, 07 Feb 2018) $
;$LastChangedRevision: 24665 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/tags/spedas_4_1/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_load_spedas_netcdf.pro $
;-
pro spd_ui_load_spedas_netcdf,info

  compile_opt idl2
  
  catch,Error_status

  if (Error_status NE 0) then begin
    statusmsg = !ERROR_STATE.MSG
    result=dialog_message('Error attempting to load netCDF. File may not conform to SPEDAS standards. See History for more details.', $
                            /info,/center, title='Load SPEDAS netCDF')
    info.historywin->Update,'Error attempting to load netCDF: '
    info.historywin->Update,statusmsg
    catch,/cancel
    return
  endif

  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif
  
  existing_tvar = tnames()
  
  info.ctrl = 0
 
  fileName = Dialog_Pickfile(Title='Load SPEDAS netCDF', $
    Filter='*.nc', Dialog_Parent=info.master,file=filestring,path=path,/must_exist,/fix_filter)
  IF(Is_String(fileName)) THEN BEGIN
    init_time=systime(/sec)
    retFromNetcdf2tplot = hash('success', !true)
    iug_netcdf2tplot, fileName, /CaledFromNetCDFMenu, ret=retFromNetcdf2tplot
    if retFromNetcdf2tplot["success"] eq !false then return
    tplotvars = tnames(create_time=create_times)
    new_vars_ind = where(create_times gt init_time, n_new_vars_ind)
    if n_new_vars_ind gt 0 then begin
      tplot_gui, tplotvars[new_vars_ind], /no_draw
      
     ; delete any new tplot variables (but not ones that overwrote existing variables)
     if n_elements(existing_tvar) eq 1 then existing_tvar = [existing_tvar]
     if n_elements(tplotvars) eq 1 then tplotvars = [tplotvars]
     tvar_to_delete = ssl_set_complement(existing_tvar, tplotvars)
     store_data, delete=tvar_to_delete
    endif else begin
      statusmsg = 'Unable to load data from file '+fileName+'. File may not conform to SPEDAS standards.'
      result=dialog_message(statusmsg, $
                            /info,/center, title='Load SPEDAS NetCDF')
      info.statusBar->Update, statusmsg
      info.historywin->Update,statusmsg
    endelse
  ENDIF ELSE BEGIN
    info.statusBar->Update, 'Invalid Filename'
  ENDELSE
  
end
