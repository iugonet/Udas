;+
;
;NAME:
; gaia_gcm_keogram
;
;PURPOSE:
;  Create a keogram (time-altitude plot) of GAIA gcm data at specified geographic latitude and longitude 
;  and loads data into tplot format.
;
;SYNTAX:
; gaia_gcm_keogram,  parameter = parameter, glat = glat, glon = glon
;
;INPUT:
;  vname1 = tplot variable name
;
;KEYWOARDS:
;  glat = specify the geographic latitude of a GAIA gcm keogram.
;              The default is 0.0.
;  glon = specify the geographic longitude of a GAIA gcm keogram.
;              The default is 0.0.
;  press = specify the pressure of a GAIA gcm keogram.
;              The default is 300.0.
;
;CODE:
; A. Shinbori, 17/05/2021.
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

pro gaia_gcm_keogram, vname1, press = press, glat = glat, glong = glon

  ;**********************
  ;***Chek keyword***
  ;**********************
   if not keyword_set(parameter) then parameter = 'gz'
   if not keyword_set(glat) then glat = 0
   if not keyword_set(glon) then glon = 2.5
   if not keyword_set(press) then press = 300.0

 ;---Get data from two tplot variables:
   if strlen(tnames(vname1)) eq 0 then begin
      print, 'Cannot find the tplot var in argument!'
      return
   endif

  ;---Get data from input tplot variable:
   get_data, vname1, data = gaia_gcm, ALIMITS = ALIMITS
   gaia_gcm_time = gaia_gcm.x
   gaia_gcm_data = gaia_gcm.y
   dum_glat = gaia_gcm.glat
   dum_glon = gaia_gcm.glon
   dum_press = gaia_gcm.press

  ;------------------------------------------------------------------------------------------------------------------------------------------
  ;======================================================================================
  ;------------------------------------------------ Create the keogram data------------------------------------------------------------

  ;---dum_glat and dum_glon array numbers corresponding to st_time:  
   idx_press = where(abs(dum_press - press) eq min(abs(dum_press - press)), cnt)
   idx_glat = where(abs(dum_glat - glat) eq min(abs(dum_glat - glat)), cnt)
   idx_glon = where(abs(dum_glon - glon) eq min(abs(dum_glon - glon)), cnt)
   heighttime_data = reform(gaia_gcm_data[*, idx_glon[0], idx_glat[0], *])
   glongtime_data = reform(gaia_gcm_data[*, *, idx_glat[0], idx_press[0]])
   glattime_data = reform(gaia_gcm_data[*, idx_glon[0], *, idx_press[0]])

 ;----Store tplot variable of the specified geographic longitude:  
  store_data, vname1+'_press_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), data = {x:gaia_gcm_time, y:heighttime_data, v:dum_press}, dlimits = ALIMITS
  options, vname1+'_press_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), ytitle = 'Pressure [hPa]', ztitle = ALIMITS.ztitle+'!C(GLAT: ' $
               +strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2)+' [deg], GLON: '+strtrim(string(dum_glon[idx_glon[0]], format='(f5.1)'),2)+' [deg]', spec = 1

  store_data, vname1+'_glong_time_'+strtrim(string(dum_glon(idx_glon[0]), format='(f5.1)' ),2), data = {x:gaia_gcm_time, y:glongtime_data, v:dum_glon}, dlimits = ALIMITS
  options, vname1+'_glong_time_'+strtrim(string(dum_glon(idx_glon[0]), format='(f5.1)' ),2), ytitle = 'GLON [deg]', ztitle = ALIMITS.ztitle+'!C(GLON: ' $
               +strtrim(string(dum_glon(idx_glon[0]), format='(f5.1)' ),2)+' [deg], P: '+strtrim(string(dum_press[idx_press[0]], format='(f5.1)'),2)+' [hPa]', spec = 1

  store_data, vname1+'_glat_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), data = {x:gaia_gcm_time, y:glattime_data, v:dum_glat}, dlimits = ALIMITS
  options, vname1+'_glat_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), ytitle = 'GLAT [deg]', ztitle = ALIMITS.ztitle+'!C(GLAT: ' $
               +strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2)+' [deg], P: '+strtrim(string(dum_press[idx_press[0]], format='(f5.1)'),2)+' [hPa]', spec = 1

  tplot_options, 'region', [0.03, 0, 0.97,1.0]
;-----------------------------
 ;--------------------------------------------Create the keogram data END------------------------------------------------------

end