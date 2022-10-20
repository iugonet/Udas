;***************************************************************************
; A sample program
; draw pressure distirbution in the magnetosphere
;***************************************************************************
pro contour_mg_pre_netcdf

ipm, /install, 'https://github.com/mankoff/kdm-idl'
; set size of arrays
maxlong=200
maxlat=160
maxalt=240
; set upper limit of color contour of pressure
max_data=2.0e-09
pi=3.141593




;***************************************************************************
;***************************************************************************
;***************************************************************************
; read netCDF data
year_ut=2015
doy_ut=249
hour=0
minute=42.67

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

ncname = 'reppu_mag_'+strtrim(year_ut,1)+'_'+strtrim(doy_uts,1)+'_'+strtrim(hours,1)+'_'+strtrim(minutes,1)+'.nc'
print,ncname

; netCDF read
read_netcdf,ncname,data,attributes,status





;***************************************************************************
;***************************************************************************
;***************************************************************************
;array set
x=fltarr(maxalt,maxlat,maxlong)
y=fltarr(maxalt,maxlat,maxlong)
z=fltarr(maxalt,maxlat,maxlong)

rho=fltarr(maxalt,maxlat,maxlong) ; density
pressure=fltarr(maxalt,maxlat,maxlong) ; pressure
current_x=fltarr(maxalt,maxlat,maxlong) ; current
current_y=fltarr(maxalt,maxlat,maxlong) ; current
current_z=fltarr(maxalt,maxlat,maxlong) ; current
btotal_x=fltarr(maxalt,maxlat,maxlong) ; magnetic field
btotal_y=fltarr(maxalt,maxlat,maxlong) ; magnetic field
btotal_z=fltarr(maxalt,maxlat,maxlong) ; magnetic field
velocity_x=fltarr(maxalt,maxlat,maxlong) ; velocity
velocity_y=fltarr(maxalt,maxlat,maxlong) ; velocity
velocity_z=fltarr(maxalt,maxlat,maxlong) ; velocity





;***************************************************************************
;***************************************************************************
;***************************************************************************
; set output file
outfile='contour_mg_pre_netcdf_sm_'
filename_eq=strcompress(outfile+strtrim(year_ut,1)+'_'+strtrim(doy_uts,1)+'_'+strtrim(hours,1)+'_'+strtrim(minutes,1)+'_eq.ps',/remove_all)
filename_md=strcompress(outfile+strtrim(year_ut,1)+'_'+strtrim(doy_uts,1)+'_'+strtrim(hours,1)+'_'+strtrim(minutes,1)+'_md.ps',/remove_all)

;contour plot in the magnetosphere
lim=30
xmin=-16 & xmax=+34
ymin_eq=-20 & ymax_eq=20
ymin_md=-20 & ymax_md=20
maxpressure_eq0=0.0
maxpressure_md0=0.0

;parameter definition
maxlong1=maxlong+1 & maxlat2=2*maxlat & maxalt1=maxalt-1

x_eq=fltarr(maxlong1,maxalt1)
y_eq=fltarr(maxlong1,maxalt1)
z_eq=fltarr(maxlong1,maxalt1)
rho_eq=fltarr(maxlong1,maxalt1)
pressure_eq=fltarr(maxlong1,maxalt1)
velocityx_eq=fltarr(maxlong1,maxalt1)
velocityy_eq=fltarr(maxlong1,maxalt1)
velocityz_eq=fltarr(maxlong1,maxalt1)
currentx_eq=fltarr(maxlong1,maxalt1)
currenty_eq=fltarr(maxlong1,maxalt1)
currentz_eq=fltarr(maxlong1,maxalt1)
btotalx_eq=fltarr(maxlong1,maxalt1)
btotaly_eq=fltarr(maxlong1,maxalt1)
btotalz_eq=fltarr(maxlong1,maxalt1)

x_md=fltarr(maxlat2,maxalt1)
y_md=fltarr(maxlat2,maxalt1)
z_md=fltarr(maxlat2,maxalt1)
rho_md=fltarr(maxlat2,maxalt1)
pressure_md=fltarr(maxlat2,maxalt1)
velocityx_md=fltarr(maxlat2,maxalt1)
velocityy_md=fltarr(maxlat2,maxalt1)
velocityz_md=fltarr(maxlat2,maxalt1)
currentx_md=fltarr(maxlat2,maxalt1)
currenty_md=fltarr(maxlat2,maxalt1)
currentz_md=fltarr(maxlat2,maxalt1)
btotalx_md=fltarr(maxlat2,maxalt1)
btotaly_md=fltarr(maxlat2,maxalt1)
btotalz_md=fltarr(maxlat2,maxalt1)

;read data from files
lat=fix(maxlat/2)
for ialt=0,maxalt1-1 do begin 
  for long=0,maxlong-1 do begin
    x_eq(long,ialt)=data.x(ialt,lat,long)
    y_eq(long,ialt)=data.y(ialt,lat,long)
    z_eq(long,ialt)=data.z(ialt,lat,long)
    rho_eq(long,ialt)=data.rho(ialt,lat,long)
    velocityx_eq(long,ialt)=data.velocity_x(ialt,lat,long)
    velocityy_eq(long,ialt)=data.velocity_y(ialt,lat,long)
    velocityz_eq(long,ialt)=data.velocity_z(ialt,lat,long)
    pressure_eq(long,ialt)=data.pressure(ialt,lat,long)
    currentx_eq(long,ialt)=data.current_x(ialt,lat,long)
    currenty_eq(long,ialt)=data.current_y(ialt,lat,long)
    currentz_eq(long,ialt)=data.current_z(ialt,lat,long)
    btotalx_eq(long,ialt)=data.btotal_x(ialt,lat,long)
    btotaly_eq(long,ialt)=data.btotal_y(ialt,lat,long)
    btotalz_eq(long,ialt)=data.btotal_z(ialt,lat,long)
  endfor
  x_eq(maxlong,ialt)=data.x(ialt,lat,0)
  y_eq(maxlong,ialt)=data.y(ialt,lat,0)
  z_eq(maxlong,ialt)=data.z(ialt,lat,0)
  rho_eq(maxlong,ialt)=data.rho(ialt,lat,0)
  velocityx_eq(maxlong,ialt)=data.velocity_x(ialt,lat,0)
  velocityy_eq(maxlong,ialt)=data.velocity_y(ialt,lat,0)
  velocityz_eq(maxlong,ialt)=data.velocity_z(ialt,lat,0)
  pressure_eq(maxlong,ialt)=data.pressure(ialt,lat,0)
  currentx_eq(maxlong,ialt)=data.current_x(ialt,lat,0)
  currenty_eq(maxlong,ialt)=data.current_y(ialt,lat,0)
  currentz_eq(maxlong,ialt)=data.current_z(ialt,lat,0)
  btotalx_eq(maxlong,ialt)=data.btotal_x(ialt,lat,0)
  btotaly_eq(maxlong,ialt)=data.btotal_y(ialt,lat,0)
  btotalz_eq(maxlong,ialt)=data.btotal_z(ialt,lat,0)
endfor

for ialt=0,maxalt1-1 do begin
  for lat=0,maxlat-1 do begin
    x_md(lat,ialt)=data.x(ialt,lat,0)
    y_md(lat,ialt)=data.y(ialt,lat,0)
    z_md(lat,ialt)=data.z(ialt,lat,0)
    rho_md(lat,ialt)=data.rho(ialt,lat,0)
    velocityx_md(lat,ialt)=data.velocity_x(ialt,lat,0)
    velocityy_md(lat,ialt)=data.velocity_y(ialt,lat,0)
    velocityz_md(lat,ialt)=data.velocity_z(ialt,lat,0)
    pressure_md(lat,ialt)=data.pressure(ialt,lat,0)
    currentx_md(lat,ialt)=data.current_x(ialt,lat,0)
    currenty_md(lat,ialt)=data.current_y(ialt,lat,0)
    currentz_md(lat,ialt)=data.current_z(ialt,lat,0)
    btotalx_md(lat,ialt)=data.btotal_x(ialt,lat,0)
    btotaly_md(lat,ialt)=data.btotal_y(ialt,lat,0)
    btotalz_md(lat,ialt)=data.btotal_z(ialt,lat,0)
    x_md(maxlat2-1-lat,ialt)=data.x(ialt,lat,maxlong/2)
    y_md(maxlat2-1-lat,ialt)=data.y(ialt,lat,maxlong/2)
    z_md(maxlat2-1-lat,ialt)=data.z(ialt,lat,maxlong/2)
    rho_md(maxlat2-1-lat,ialt)=data.rho(ialt,lat,maxlong/2)
    velocityx_md(maxlat2-1-lat,ialt)=data.velocity_x(ialt,lat,maxlong/2)
    velocityy_md(maxlat2-1-lat,ialt)=data.velocity_y(ialt,lat,maxlong/2)
    velocityz_md(maxlat2-1-lat,ialt)=data.velocity_z(ialt,lat,maxlong/2)
    pressure_md(maxlat2-1-lat,ialt)=data.pressure(ialt,lat,maxlong/2)
    currentx_md(maxlat2-1-lat,ialt)=data.current_x(ialt,lat,maxlong/2)
    currenty_md(maxlat2-1-lat,ialt)=data.current_y(ialt,lat,maxlong/2)
    currentz_md(maxlat2-1-lat,ialt)=data.current_z(ialt,lat,maxlong/2)
    btotalx_md(maxlat2-1-lat,ialt)=data.btotal_x(ialt,lat,maxlong/2)
    btotaly_md(maxlat2-1-lat,ialt)=data.btotal_y(ialt,lat,maxlong/2)
    btotalz_md(maxlat2-1-lat,ialt)=data.btotal_z(ialt,lat,maxlong/2)
  endfor
endfor





;***************************************************************************
;'set min and max
;***************************************************************************

; common for windows output and ps output
contour_lines=60
min_data=0.0
level_set=(min_data+(max_data-min_data)*findgen(contour_lines)/contour_lines)
color_set=!d.table_size*indgen(contour_lines)/contour_lines

pcontour_lines=21
pmax_data=max_data
pmin_data=min_data
plevel_set=(pmin_data+(pmax_data-pmin_data)*findgen(pcontour_lines)/pcontour_lines)
pcolor_set=!d.table_size*indgen(pcontour_lines)/pcontour_lines


if hour gt 24 then begin
  hour=hour-24
  doy_ut=doy_ut+1
endif
print,year_ut,doy_ut,hour,minute





;***************************************************************************
;***************************************************************************
;***************************************************************************
; imbed unphysical value in data outside of drawn region
minpressure_eq=min(pressure_eq)
maxpressure_eq=max(pressure_eq)
if maxpressure_eq gt maxpressure_eq0 then begin
  maxpressure_eq0=maxpressure_eq
endif
print,filename_eq,' maxpeq, ',maxpressure_eq/max_data,maxpressure_eq0/max_data
for ialt=0,maxalt1-1 do begin
for long=0,maxlong do begin
  if pressure_eq(long,ialt) gt max_data then begin
    pressure_eq(long,ialt)=max_data
  endif
  if pressure_eq(long,ialt) lt min_data then begin
    pressure_eq(long,ialt)=min_data
  endif
endfor
endfor
for ialt=0,maxalt1-1 do begin
for long=0,maxlong do begin
  if sqrt(x_eq(long,ialt)^2+y_eq(long,ialt)^2+z_eq(long,ialt)^2)  gt 1.5*lim then begin
    pressure_eq(long,ialt)=-10000
  endif
endfor
endfor

;set data 
maxpressure_md=max(pressure_md)
minpressure_md=min(pressure_md)
if maxpressure_md gt maxpressure_md0 then begin
  maxpressure_md0=maxpressure_md
endif
print,filename_md,' maxpmd, ',maxpressure_md/max_data,maxpressure_md0/max_data
for ialt=0,maxalt1-1 do begin
for lat=0,maxlat2-1 do begin
  if pressure_md(lat,ialt) gt max_data then begin
    pressure_md(lat,ialt)=max_data
  endif
  if pressure_md(lat,ialt) lt min_data then begin
    pressure_md(lat,ialt)=min_data
  endif
endfor
endfor
for ialt=0,maxalt1-1 do begin
for lat=0,maxlat2-1 do begin
  if abs(x_md(lat,ialt)) ge lim*1.5 then begin
    pressure_md(lat,ialt)=-100000
  endif
  if abs(z_md(lat,ialt)) ge lim*1.5 then begin
    pressure_md(lat,ialt)=-100000
  endif
endfor
endfor





;***************************************************************************
;'draw figures'
;***************************************************************************
; set graphic parameters
set_plot,'ps'
device,/color
tvlct,[0,255,0,0],[0,0,255,0],[0,0,0,255]

; equatorial plane
device,filename=filename_eq
titlefile=strcompress('pressure (equatorial plane in SM coord.), '$
+string(format='((i4))',year_ut)+' '$
+string(format='((i3))',doy_ut)+' '$
+string(format='((i2))',hour)+'h'$
+string(format='((f4.1))',minute)+'min')

loadct,20
contour,pressure_eq,-x_eq,y_eq,nlevels=contour_lines,/fill $
,title=titlefile $
,xrange=[xmin,xmax],yrange=[ymin_eq,ymax_eq],xstyle=1,ystyle=1 $
,levels=level_set,c_colors=color_set $
,/data,/isotropic,charsize=1.0,color=255

loadct,2
contour,pressure_eq,-x_eq,y_eq,nlevels=pcontour_lines $
,xrange=[xmin,xmax],yrange=[ymin_eq,ymax_eq] $
,levels=plevel_set,/isotropic,/overplot,thick=0.2

; legend (scale)
unit=' (Pa)'
csize=0.7
limx=xmax
limy=ymax_eq
loadct,20
sub_legend2,limx,limy,unit,min_data,max_data,csize

device,/close

;meridional plane
device,filename=filename_md
titlefile=strcompress('pressure (meridian plane in SM coord.), '$
+string(format='((i4))',year_ut)+' '$
+string(format='((i3))',doy_ut)+' '$
+string(format='((i2))',hour)+'h'$
+string(format='((f4.1))',minute)+'min')

loadct,20
contour,pressure_md,-x_md,z_md,nlevels=pcontour_lines,/fill $
,title=titlefile $
,xrange=[xmin,xmax],yrange=[ymin_md,ymax_md] $
,xstyle=1,ystyle=1,levels=level_set,c_colors=color_set $
,/data,/isotropic,charsize=1.0,color=255

loadct,2
contour,pressure_md,-x_md,z_md,nlevels=pcontour_lines $
,xrange=[xmin,xmax],yrange=[ymin_md,ymax_md] $
,levels=plevel_set,/overplot,/isotropic $
,C_LINESTYLE=(plevel_set LT 0.0)

; legend (scale)
unit=' (Pa)'
csize=0.7
limx=xmax
limy=ymax_md
loadct,20
sub_legend2,limx,limy,unit,min_data,max_data,csize

device,/close

end
