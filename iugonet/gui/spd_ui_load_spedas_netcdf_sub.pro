
;+  
;NAME: 
; spd_ui_load_spedas_netcdf_sub
;
;PURPOSE:
; display a dialog when importing netCDF data
;
;INPUT:
; ev - event structure from the main GUI
;  
;HISTORY:
;
;-----------------------------------------------------------------------------------

; sub routine for HELP dialog
pro spd_ui_load_spedas_netcdf_display_help, ev, msgtext
  COMPILE_OPT idl2, hidden
  
  help_base = WIDGET_BASE(TITLE='HELP', /COLUMN, /ALIGN_CENTER, GROUP_LEADER=ev.top, /MODAL)
  help_text = WIDGET_TEXT(help_base, VALUE=msgtext, XSIZE=60, YSIZE=30, /SCROLL)
  WIDGET_CONTROL, help_base, /REALIZE

end
;
; Event handler
;
pro spd_ui_load_spedas_netcdf_sub_event, ev
  compile_opt idl2, hidden
    
  ; event handling
  WIDGET_CONTROL, ev.top, GET_UVALUE=val
  WIDGET_CONTROL, ev.id, GET_UVALUE=uval
  
  case uval of

    "HELP":begin
      msgtext = (val["help_text"])[uval]
      spd_ui_load_spedas_netcdf_display_help, ev, msgtext
    end
    
    "LIST_TIME_DIMENSION":begin
      val["time_dimension"] = ev.INDEX
    end
    
    "LIST_V_DIMENSION":begin
      val["v_dimension"] = ev.INDEX
    end
    
    "LIST_TIME_VARIABLES":begin
      val["time_variable"] = ev.INDEX
    end
    
    "LIST_V_VARIABLES":begin
      val["v_variable"] = ev.INDEX
    end
    
    "button_Cancel":begin
      val["success"] = !FALSE
      widget_control, ev.top, /DESTROY
    end  
    
    "button_OK" : begin
      val["success"] = !TRUE
      WIDGET_CONTROL, ev.top, /DESTROY
    end

  endcase
  
end

; main program
function spd_ui_load_spedas_netcdf_sub, netCDFi_DIMS, netCDFi_VARS
  
  COMPILE_OPT idl2, hidden

  help_text = hash()  
  help_text['HELP'] = ['Select Parameters:', $
	'This window opens when you select a netCDF file including ', $
    'variables which are more than three dimension.', $
    ' ', $
    '(1) Name of time dimension', $
    'Please select the name of time dimension, which was defined ', $
	'in the NetCDF format. This is used for time of tplot variables ', $
    '(element of "x" in SPEDAS data model). All dimensions in a ', $
    'netCDF file are listed in this box. The default value is "time"' , $
    'if a netCDF file has a dimension named as "time".', $
    ' ', $
    '(2) Variable name for the time dimension', $
    'Please select the variable name for the time dimension, which ', $
	'was defined in the NetCDF format. All variables in a netCDF file ', $
    'are listed in this box. The default value is "time" if a netCDF ', $
    'file has a variable named as "time".', $
    ' ', $
    '(3) 2nd dimension for 3D data', $
    'Please select the name of the 2nd dimension for 3D data other than ', $
    'the time dimension (for exmaple, range, height, frequency, etc.), ', $
    'which was defined in the NetCDF format. This is used for v of ', $
    'tplot variables (element of "v" in SPEDAS data model). ', $
	'The default value is "None".', $
    ' ', $
    '(4) Variable name for the 2nd dimension', $
    'Please select the variable name for the 2nd dimension (e.g., range, ', $
	'height, frequency, etc.), which was defined in the NetCDF format.', $
    'The default value is "None".']  

  ; Widget master :: topbase
  ;if KEYWORD_SET(debug) then begin
    topbase = WIDGET_BASE(TITLE='Load SPEDAS netCDF')
  ;endif else begin
  ;  topbase = WIDGET_BASE(TITLE='Load SPEDAS ASCII', GROUP_LEADER=ev.top, /MODAL)
  ;endelse
  
  base = WIDGET_BASE(topbase, /COLUMN)
  ;size of labels
  w_xs = 600
  
  ; title 
  base_title = WIDGET_BASE(base, /ROW)
  dummy = WIDGET_LABEL(base_title, VALUE='', XSIZE=5)
  label_title = WIDGET_LABEL(base_title, VALUE='Select the following parameters: ', XSIZE=300)
  
  ; help
  base_help = WIDGET_BASE(base, /ROW)
  dummy = WIDGET_LABEL(base_help, VALUE='', XSIZE=w_xs-45)
  help_FormatType = WIDGET_BUTTON(base_help, VALUE='? ', UVALUE='HELP', /ALIGN_RIGHT)
  
  ; upper
  netCDFi_DIMS_WithNone = ["(none)", netCDFi_DIMS]
  base_up = WIDGET_BASE(base, /ROW)
  base_up_timeDim = WIDGET_BASE(base_up, /COLUMN, XSIZE=w_xs/2-10)
  label_timeDim = WIDGET_LABEL(base_up_timeDim, VALUE='(1) Name of time dimension: ', /ALIGN_LEFT)
  list_timeDim = WIDGET_LIST(base_up_timeDim, SCR_YSIZE=120, $
    VALUE=netCDFi_DIMS, UVALUE='LIST_TIME_DIMENSION', UNAME='LIST_TIME_DIMENSION')
  base_up_vDim = WIDGET_BASE(base_up, /COLUMN, XSIZE=w_xs/2-10)
  label_vDim = WIDGET_LABEL(base_up_vDim, VALUE='(3) 2nd dimension for 3D data: ', /ALIGN_LEFT)
  list_vDim = WIDGET_LIST(base_up_vDim, SCR_YSIZE=120, $
    VALUE=netCDFi_DIMS_WithNone, UVALUE='LIST_V_DIMENSION', UNAME='LIST_V_DIMENSION')

  ; lower
  netCDFi_VARS_WithNone = ["(none)", netCDFi_VARS]
  base_low = WIDGET_BASE(base, /ROW)
  base_low_timeVar = WIDGET_BASE(base_low, /COLUMN, XSIZE=w_xs/2-10)
  label_timeVar = WIDGET_LABEL(base_low_timeVar, VALUE='(2) Variable name for the time dimension: ', /ALIGN_LEFT)
  list_timeVar = WIDGET_LIST(base_low_timeVar, SCR_YSIZE=120, $
    VALUE=netCDFi_VARS, UVALUE='LIST_TIME_VARIABLES', UNAME='LIST_TIME_VARIABLES')
  base_low_vVar = WIDGET_BASE(base_low, /COLUMN, XSIZE=w_xs/2-10)
  label_vVar = WIDGET_LABEL(base_low_vVar, VALUE='(4) Variable name for the 2nd dimension: ', /ALIGN_LEFT)
  list_vVar = WIDGET_LIST(base_low_vVar, SCR_YSIZE=120, $
    VALUE=netCDFi_VARS_WithNone, UVALUE='LIST_V_VARIABLES', UNAME='LIST_V_VARIABLES')
  
  ; OK Button *****
  base_OK = WIDGET_BASE(base, /ROW, /ALIGN_RIGHT)
  button_OK = WIDGET_BUTTON(base_OK, UVALUE='button_OK', VALUE='  OK  ')
  button_Cancel = WIDGET_BUTTON(base_OK, UVALUE='button_Cancel', VALUE='Cancel')
  
  posTimeDims = where(netCDFi_DIMS eq "TIME", cntTimeDims)
  if cntTimeDims gt 0 then begin
    WIDGET_CONTROL, list_timeDim, SET_LIST_SELECT=posTimeDims
  endif else begin
    WIDGET_CONTROL, list_timeDim, SET_LIST_SELECT=0
  endelse
  WIDGET_CONTROL, list_vDim, SET_LIST_SELECT=0
  posTimeVars = where(netCDFi_VARS eq "TIME", cntTimeVars)
  if cntTimeVars gt 0 then begin
    WIDGET_CONTROL, list_timeVar, SET_LIST_SELECT=posTimeVars
  endif else begin
    WIDGET_CONTROL, list_timeVar, SET_LIST_SELECT=0
  endelse
  WIDGET_CONTROL, list_vVar, SET_LIST_SELECT=0
  
  ; widget status setting
  status = hash()
  status['help_text'] = help_text

  ; return values
  status['success'] = !true
  if cntTimeDims gt 0 then begin
    status['time_dimension'] = posTimeDims
  endif else begin
    status['time_dimension'] = 0
  endelse
  status['v_dimension'] = 0
  
  if cntTimeVars gt 0 then begin
    status['time_variable'] = posTimeVars
  endif else begin
    status['time_variable'] = 0
  endelse
  status['v_variable'] = 0
    
  WIDGET_CONTROL, topbase, SET_UVALUE=status
    
  ; exec Load ASCII File 
  WIDGET_CONTROL, topbase, /REALIZE
  XMANAGER, 'spd_ui_load_spedas_netcdf_sub', topbase
  
  ; make return hash
  ret_hash = hash()
  ret_hash['success'] = status['success']
  if ret_hash['success'] then begin
    ret_hash['time_dimension'] = netCDFi_DIMS[status['time_dimension']]
    ret_hash['v_dimension'] = netCDFi_DIMS_WithNone[status['v_dimension']]
    if ret_hash['v_dimension'] eq "(none)" then ret_hash['v_dimension'] = ""
    ret_hash['time_variable'] = netCDFi_VARS[status['time_variable']]
    ret_hash['v_variable'] = netCDFi_VARS_WithNone[status['v_variable']]
    if ret_hash['v_variable'] eq "(none)" then ret_hash['v_variable'] = ""
  endif else begin
    ret_hash['time_dimension'] = !null
    ret_hash['time_variable'] = !null
    ret_hash['v_dimension'] = !null
    ret_hash['v_variable'] = !null
  endelse
  
  return, ret_hash
  
end

; for testing dialog
pro test_spd_ui_load_spedas_netcdf_sub
  COMPILE_OPT idl2, hidden
  
  netCDFi_DIMS = ["BEAM", "RANGE", "TIME"]
  netCDFi_VARS = [ $
    "LAT", "LON", "SEALVL", "BMWDH", "FREQ", "IPP", "NDATA", $
    "NFFT", "NCOH", "NICOH", "BEAM", "RANGE", "AZ", "ZE", "DATE", $
    "TIME", "HEIGHT", "PWR", "WIDTH", "DPL", "PNOISE"]
  
  ret = spd_ui_load_spedas_netcdf_sub(netCDFi_DIMS, netCDFi_VARS)
  print, "time_dimension: ", ret["time_dimension"]
  print, "v_dimension: ", ret["v_dimension"]
  print, "time_variable: ", ret["time_variable"]
  print, "v_variable: ", ret["v_variable"]

end
