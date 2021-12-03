;+
;
;NAME:
;gaia_gcm_2dmap
;
;PURPOSE:
;  Create a two-dimensional world map of the GAIA gcm data at a specified time.
;
;SYNTAX:
; gaia_cpl_2dmap, vname1, press = press, st_time = st_time,
;                           contour_min = contour_min, contour_max = contour_max
;
;INPUT:
;  vname1 = tplot variable name
;
;KEYWOARDS:
;  press = iuput pressure to create a world map of the GAIA gcm data.
;                The default is 300.
;
;  P0lat = center latitude of a world map
;             The default is 0.
;
;  P0lon = center longitude of a world map
;             The default is 160.
;
;  plot_min_lat = minimum value of plot latitude range
;                        The default is -90.0.
;
;  plot_max_lat = maximum value of plot latitude range
;                        The default is 90.0.
;
;  plot_min_lon = minimum value of plot longitude range
;                        The default is -180.0.
;
;  plot_max_lon = maximum value of plot longitude range
;                        The default is 180.0.
;
;  st_time = start time to create a world map of the GAIA gcm data
;
;  contour_min = plot the minimum range of each GAIA gcm value.
;                     The default is the minimum range corresponding to the minimum gcm values.
;
;  contour_max = plot the maximum range of each GAIA gcm value.
;                     The default is the maximum range corresponding to the maximum gcm values.
;
;CODE:
; A. Shinbori, 05/11/2021.
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

pro gaia_gcm_2dmap, vname1, press = press, st_time = st_time, P0lat = P0lat, P0lon = P0lon, $
  plot_min_lat = plot_min_lat, plot_max_lat = plot_max_lat, plot_min_lon = plot_min_lon, $
  plot_max_lon = plot_max_lon, contour_min = contour_min, contour_max = contour_max, local_noon=local_noon

  ;**************************
  ;****Keyword check****
  ;**************************
  if not keyword_set(press) then press = 300.0
  if not keyword_set(st_time) then st_time = '2017-09-07/23:00'
  if not keyword_set(P0lat) then P0lat = 0
  if not keyword_set(P0lon) then P0lon = 160
  if not keyword_set(plot_min_lat) then plot_min_lat = -90.0
  if not keyword_set(plot_max_lat) then plot_max_lat = 90.0
  if not keyword_set(plot_min_lon) then plot_min_lon = -180.0
  if not keyword_set(plot_max_lon) then plot_max_lon = 180.0

  ;---Get data from two tplot variables:
  if strlen(tnames(vname1)) eq 0 then begin
    print, 'Cannot find the tplot var in argument!'
    return
  endif

  ;---Get data from input tplot variable:
  get_data, vname1, data = gaia_gcm, ALIMITS = ALIMITS
  gaia_gcm_time = gaia_gcm.x
  gaia_gcm_data = gaia_gcm.y
  Lat = gaia_gcm.glat
  idx_glat = where(Lat eq 90.0)
  Lat[idx_glat] =89.9
  idx_glat = where(Lat eq -90.0)
  Lat[idx_glat] =-89.9
  Lon = gaia_gcm.glon
  dum_press = gaia_gcm.press

  ;---Search for the time corresponding to the input start time and altitude:
  idx_time = where(abs(gaia_gcm_time - time_double(st_time)) eq min(abs(gaia_gcm_time - time_double(st_time))), cnt)
  st_time = time_string(gaia_gcm_time[idx_time[0]])
  idx_press = where(abs(dum_press - press) eq min(abs(dum_press - press)), cnt)
  press = dum_press[idx_press[0]]

  gaia_gcm_data = reform(gaia_gcm_data[*,*,*,idx_press[0]])

  ;---Contour Level ...
  if not keyword_set(contour_min) then begin
    min_cont= min(gaia_gcm_data)
    max_cont= max(gaia_gcm_data)
  endif else begin
    min_cont = double(contour_min)
    max_cont = double(contour_max)
  endelse
  range =[min_cont, max_cont]

  ;--------------- Preparation for Plotting ----------------
  nclv = 255.
  cont_level = float(indgen(nclv))*(max_cont-min_cont)/(nclv-1)+min_cont

  ;----Get start time (year, month, day, hour, minute).----
  yyyy = strmid(st_time,0,4)
  mm = strmid(st_time, 5,2)
  dd = strmid(st_time, 8,2)
  hour = strmid(st_time, 11,2)
  minute = strmid(st_time, 14,2)

  ;------------------------------------------------ Draw a two-dimensional map of GAIA cpl data------------------------------------------------------
  ;----Set up the plot window----
  y = findgen(255)*(max_cont-min_cont)/(255-1) + min_cont
  y = bytescale(y,bottom=7,top=254,range=range)
  WINDOW, 0, xsize = 1200, ysize = 600, COLORS=2
  white=!D.N_COLORS-1
  PLOT, FINDGEN(20), COLOR=white

  ;----Map set----
  map_set, P0lat , P0lon , 0, /cylindrical, limit = [plot_min_lat , plot_min_lon, plot_max_lat, plot_Max_lon], /NoErase, $
    charsize = 1.5, latdel = 15, londel = 15, POSITION = [0.1, 0.13, 0.85, 0.87]
  xyouts, 0.5, 0.95, time_string(gaia_gcm_time[idx_time[0]])+', P = '+strtrim(string(press, format ='(f7.2)'), 2)+' [hPa]', $
    alignment = 0.5, orientation = 0., charsize = 1.5, color = 0, /NORMAL

  ;----Prepare the SPEDAS color scale----
  dum_gaia_gcm_data = reform(gaia_gcm_data[idx_time[0],*,*])
  idx = where(dum_gaia_gcm_data lt min_cont)
  dum_gaia_gcm_data[idx] = min_cont
  contour, dum_gaia_gcm_data, Lon, Lat, levels = cont_level, /overplot, charsize=1., /Cell_Fill, C_COLORS=y

  ;----Plot the vertical red line indicating 12 LT----
  hh = float(strmid(time_string(gaia_gcm_time[idx_time[0]]),11,2))
  mm = float(strmid(time_string(gaia_gcm_time[idx_time[0]]),14,2))
  ss = float(strmid(time_string(gaia_gcm_time[idx_time[0]]),17,2))
  LT12 = -(hh + mm/60. + ss/60./60. -12.0)*15.
  if LT12 lt 0.0 then LT12 = LT12 + 360.0
  idx_lat = where(Lat ge Plot_Min_Lat and Lat le Plot_Max_Lat)
  LT12_lat = Lat[idx_lat]
  LT12_lon = fltarr(n_elements( LT12_lat))
  LT12_lon[*] = LT12
  if keyword_set(local_noon) then plots, LT12_lon, LT12_lat, color = 240, thick= 1, psym = 1, symsize = 0.2
  ;----------------------------------------------------------

  ;-----Plot the high resokution CONTINENTS----
  map_continents, /coasts,/CONTINENTS;,/hires
  map_Grid, /Box_Axes, Charsize = 1.25, GLinestyle = 1

  ;-----Draw the colar bar------
  P = [0.9, 0.13, 0.925, 0.87]

  draw_color_scale,range=[min_cont, max_cont],log=zlog,charsize=1.0,position=p,title=ztitle,yticks=zticks,brange=[7,254],$
    offset=zoffset,ygridstyle=zgridstyle,yminor=zminor,ythick=zthick,ytickformat=ztickformat,ytickinternal=ztickinterval,$
    yticklayout=zticklayout,yticklen=zticklen,ytickname=ztickname,ytickunits=ztickunits,ytickv=ztickv,ytitle=ALIMITS.ztitle

end