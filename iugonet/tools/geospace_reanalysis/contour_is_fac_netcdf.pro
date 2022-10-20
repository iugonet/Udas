;***************************************************************************
; A sample program
; draw FAC distirbution in the ionosphere
;***************************************************************************
pro contour_is_fac_netcdf

; set size of arrays
maxlong_is=320
maxlat_is=221
; set upper limit of color contour of FAC intensity
max_data=5.0e-7 ; for fac (A/m^2)
;max_data=3.0e4 for pot (30kV)
;max_data=3.0 for sxx (3mho)
;max_data=6.0 for sxy and Syy (6mho)
pi=3.141593





;***************************************************************************
;***************************************************************************
;***************************************************************************
;array set
col_fig=fltarr(maxlat_is)
lon_fig=fltarr(maxlong_is+1)
pot_fig=fltarr(maxlong_is+1,maxlat_is)
fac_fig=fltarr(maxlong_is+1,maxlat_is)
sxx_fig=fltarr(maxlong_is+1,maxlat_is)
syy_fig=fltarr(maxlong_is+1,maxlat_is)
sxy_fig=fltarr(maxlong_is+1,maxlat_is)

x=fltarr(maxlong_is+1,maxlat_is)
y=fltarr(maxlong_is+1,maxlat_is)
z=fltarr(maxlong_is+1,maxlat_is)




;*********************************************************************
;*********************************************************************
;*********************************************************************
; set graphic parameters
set_plot,'ps'
device,/color
tvlct,[0,255,0,0],[0,0,255,0],[0,0,0,255]

; common for windows output and ps output
contour_lines=60
min_data=-max_data
level_set=(min_data+(max_data-min_data)*findgen(contour_lines)/contour_lines)
color_set=!d.table_size*indgen(contour_lines)/contour_lines

pcontour_lines=21
pmax_data=max_data
pmin_data=min_data
plevel_set=(pmin_data+(pmax_data-pmin_data)*findgen(pcontour_lines)/pcontour_lines)
pcolor_set=!d.table_size*indgen(pcontour_lines)/pcontour_lines

loadct,33





;*********************************************************************
;*********************************************************************
;*********************************************************************
; read netCDF

year_ut=2015
doy_ut=249
hour=0
minute=42.67
print,year_ut,doy_ut,hour,minute

; set the input file
if doy_ut lt 10 then begin
    doy_uts=strcompress('00'+string(doy_ut),/remove_all)
  endif else if doy_ut lt 100 then begin
    doy_uts=strcompress('0'+string(doy_ut),/remove_all)
  endif else begin
    doy_uts=string(doy_ut)
endelse

if hour lt 10 then begin
    hours=strcompress('0'+string(hour),/remove_all)
  endif else begin
    hours=string(hour)
endelse

if minute lt 10 then begin
    minutes=strcompress('0'+string(format='((f5.2))',minute),/remove_all)
  endif else begin
    minutes=string(format='((f5.2))',minute)
endelse

ncname = 'reppu_iono_'+strtrim(year_ut,1)+'_'+strtrim(doy_uts,1)+'_'+strtrim(hours,1)+'_'+strtrim(minutes,1)+'.nc'

; netCDF read
read_netcdf,ncname,data,attributes,status





;*********************************************************************
;*********************************************************************
;*********************************************************************
; set mesh (lat=maxlat_is: north pole, col=0)
for lat=0,maxlat_is-1 do begin
  for long=0,maxlong_is-1 do begin
    x(long,lat)=+180.0*data.col_out(long,lat)/pi*sin(data.lon_out(long,lat))
    y(long,lat)=-180.0*data.col_out(long,lat)/pi*cos(data.lon_out(long,lat))
  endfor
  x(maxlong_is,lat)=+180.0*data.col_out(0,lat)/pi*sin(data.lon_out(0,lat))
  y(maxlong_is,lat)=-180.0*data.col_out(0,lat)/pi*cos(data.lon_out(0,lat))
endfor

; store data into the work data
for lat=0,maxlat_is-1 do begin
for long=0,maxlong_is-1 do begin
  col_fig(lat)=data.col_out(long,lat)
  lon_fig(long)=data.lon_out(long,lat)
  pot_fig(long,lat)=data.pot_out(long,lat)
  fac_fig(long,lat)=data.fac_out(long,lat)
  sxx_fig(long,lat)=data.sxx_out(long,lat)
  sxy_fig(long,lat)=data.sxy_out(long,lat)
  syy_fig(long,lat)=data.syy_out(long,lat)
endfor
endfor
for lat=0,maxlat_is-1 do begin
  lon_fig(maxlong_is)=data.lon_out(0,lat)
  pot_fig(maxlong_is,lat)=data.pot_out(0,lat)
  fac_fig(maxlong_is,lat)=data.fac_out(0,lat)
  sxx_fig(maxlong_is,lat)=data.sxx_out(0,lat)
  sxy_fig(maxlong_is,lat)=data.sxy_out(0,lat)
  syy_fig(maxlong_is,lat)=data.syy_out(0,lat)
endfor

; cut the extreme data
lim=30
max_dataf=max(fac_fig)
min_dataf=min(fac_fig)
print,max_dataf/max_data,min_dataf/max_data
for lat=0,maxlat_is-1 do begin
for long=0,maxlong_is do begin
  if sqrt(x(long,lat)^2+y(long,lat)^2) le lim then begin
    if fac_fig(long,lat) gt max_data then begin
      fac_fig(long,lat)=max_data
    endif
    if fac_fig(long,lat) lt min_data then begin
      fac_fig(long,lat)=min_data
    endif
  endif
endfor
endfor
max_datap=-1000*max_data
min_datap=-max_datap
for lat=0,maxlat_is-1 do begin
for long=0,maxlong_is do begin
  if sqrt(x(long,lat)^2+y(long,lat)^2) le lim then begin
    if pot_fig(long,lat) gt max_datap then begin
      max_datap=pot_fig(long,lat)
    endif
    if pot_fig(long,lat) lt min_datap then begin
      min_datap=pot_fig(long,lat)
    endif
  endif
endfor
endfor

; set abnormal data in the region outside the drawing area
for lat=0,maxlat_is-1 do begin
for long=0,maxlong_is do begin
  if sqrt(x(long,lat)^2+y(long,lat)^2) gt lim then begin
    fac_fig(long,lat)=-10000*max_data
    pot_fig(long,lat)=-10000*max_data
  endif
endfor
endfor





;***************************************************************************
; draw pictures

; define a name of the output file
outfile='contour_is_fac_netcdf_'
filename0=strcompress(outfile+strtrim(year_ut,1)+'_'+strtrim(doy_uts,1)+'_'+strtrim(hours,1)+'_'+strtrim(minutes,1)+'.ps',/remove_all)
device,filename=filename0

titlefile=strcompress('FAC (N), '$
+string(format='((i4))',year_ut)+':'$
+string(format='((i3))',doy_ut)+':'$
+string(format='((i2))',hour)+':'$
+string(format='((f4.1))',minute)+'min')

; draw a contours of fac
contour,fac_fig,x,y,nlevels=contour_lines,/fill,$
title=titlefile, $
xrange=[-lim,lim],xstyle=1,yrange=[-lim,lim],ystyle=1, $
levels=level_set,/isotropic,charsize=1.0,ticklen=0,color=0

contour,fac_fig,x,y,nlevels=pcontour_lines, $
xrange=[-lim,lim],yrange=[-lim,lim],$
levels=plevel_set,C_LINESTYLE=(plevel_set LT 0.0),$
/isotropic,/overplot,thick=0.1,ticklen=0

; draw a frame
for j=0,lim/10 do begin
  cir=findgen(360)*(!pi*2/360)
  for i=0,358 do begin
    plots,[10*j*cos(cir(i)),10*j*cos(cir(i+1))],[10*j*sin(cir(i)),10*j*sin(cir(i+1))],line=2,/data,thick=0.1
  endfor
  plots,[10*j*cos(cir(359)),10*j*cos(cir(359))],[10*j*sin(cir(0)),10*j*sin(cir(0))],line=2,/data,thick=0.1
endfor

plots,[0,0],[-lim,lim],line=2,/data,thick=0.1
plots,[-lim,lim],[0,0],line=2,/data,thick=0.1
plots,[-lim/sqrt(2),lim/sqrt(2)],[-lim/sqrt(2),lim/sqrt(2)],line=2,/data,thick=0.1
plots,[-lim/sqrt(2),lim/sqrt(2)],[lim/sqrt(2),-lim/sqrt(2)],line=2,/data,thick=0.1

xyouts,0,-14,'80',/data,charsize=1.0
xyouts,0,-24,'70',/data,charsize=1.0

; legend (scale)
unit=' (A/m^2)' ; for fac
;unit=' (V)' ; for pot
;unit=' (mho)' ; for ionospheric conductivity
csize=0.7
sub_legend,lim,unit,min_data,max_data,csize





;*********************************************************************
;*********************************************************************
;*********************************************************************
; end
device,/close
end
