;+
;
;NAME:
; gaia_cpl_keogram
;
;PURPOSE:
;  Create a keogram (time-altitude plot) of GAIA cpl data at specified geographic latitude and longitude 
;  and and loads data into tplot format.
;
;SYNTAX:
; gaia_cpl_keogram,  parameter = parameter, glat = glat, glon = glon
;
;INPUT:
;  vname1 = tplot variable name
;
;KEYWOARDS:
;  glat = specify the geographic latitude of a GAIA cpl keogram.
;              The default is 0.0.
;  glon = specify the geographic longitude of a GAIA cpl keogram.
;              The default is 0.0.
;  altitude = specify the altitude of a GAIA cpl keogram.
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

pro gaia_cpl_keogram, vname1, altitude = altitude, glat = glat, glong = glon

  ;**********************
  ;***Chek keyword***
  ;**********************
   if not keyword_set(vname1) then vname1 = ''
   if not keyword_set(glat) then glat = 0
   if not keyword_set(glon) then glon = 2.5
   if not keyword_set(altitude) then altitude = 300.0

 ;---Get data from two tplot variables:
   if strlen(tnames(vname1)) eq 0 then begin
      print, 'Cannot find the tplot var in argument!'
      return
   endif

  ;---Get data from input tplot variable:
   get_data, vname1, data = gaia_cpl, ALIMITS = ALIMITS
   gaia_cpl_time = gaia_cpl.x
   gaia_cpl_data = gaia_cpl.y
   dum_glat = gaia_cpl.glat
   dum_glon = gaia_cpl.glon
   dum_altitude = gaia_cpl.alt

  ;------------------------------------------------------------------------------------------------------------------------------------------
  ;======================================================================================
  ;------------------------------------------------ Create the keogram data------------------------------------------------------------

  ;---dum_glat and dum_glon array numbers corresponding to st_time:  
   idx_altitude = where(abs(dum_altitude - altitude) eq min(abs(dum_altitude - altitude)), cnt)
   idx_glat = where(abs(dum_glat - glat) eq min(abs(dum_glat - glat)), cnt)
   idx_glon = where(abs(dum_glon - glon) eq min(abs(dum_glon - glon)), cnt)
   heighttime_data = reform(gaia_cpl_data[*, idx_glon[0], idx_glat[0], *])
   glongtime_data = reform(gaia_cpl_data[*, *, idx_glat[0], idx_altitude[0]])
   glattime_data = reform(gaia_cpl_data[*, idx_glon[0], *, idx_altitude[0]])

 ;----Store tplot variable of the specified geographic longitude:  
  store_data, vname1+'_height_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), data = {x:gaia_cpl_time, y:heighttime_data, v:dum_altitude}, dlimits = ALIMITS
  options, vname1+'_height_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), ytitle = 'ALT [km]', ztitle = ALIMITS.ztitle+'!C(GLAT: ' $
               +strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2)+' [deg], GLON: '+strtrim(string(dum_glon[idx_glon[0]], format='(f5.1)'),2)+' [deg]', spec = 1

  store_data, vname1+'_glong_time_'+strtrim(string(dum_glon(idx_glon[0]), format='(f5.1)' ),2), data = {x:gaia_cpl_time, y:glongtime_data, v:dum_glon}, dlimits = ALIMITS
  options, vname1+'_glong_time_'+strtrim(string(dum_glon(idx_glon[0]), format='(f5.1)' ),2), ytitle = 'GLON [deg]', ztitle = ALIMITS.ztitle+'!C(GLON: ' $
               +strtrim(string(dum_glon(idx_glon[0]), format='(f5.1)' ),2)+' [deg], ALT: '+strtrim(string(dum_altitude[idx_altitude[0]], format='(f5.1)'),2)+' [km]', spec = 1

  store_data, vname1+'_glat_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), data = {x:gaia_cpl_time, y:glattime_data, v:dum_glat}, dlimits = ALIMITS
  options, vname1+'_glat_time_'+strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2), ytitle = 'GLAT [deg]', ztitle = ALIMITS.ztitle+'!C(GLAT: ' $
               +strtrim(string(dum_glat(idx_glat[0]), format='(f5.1)' ),2)+' [deg], ALT: '+strtrim(string(dum_altitude[idx_altitude[0]], format='(f5.1)'),2)+' [km]', spec = 1

  tplot_options, 'region', [0.03, 0, 0.97,1.0]
;-----------------------------
 ;--------------------------------------------Create the keogram data END------------------------------------------------------

end