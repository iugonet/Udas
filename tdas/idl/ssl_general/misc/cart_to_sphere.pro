;+
;PROCEDURE:  cart_to_sphere, x, y, z,  r, theta, phi
;PURPOSE:
;            transform from cartesian to spherical coordinates
;INPUTS:     x, y, z          (array or scalar)
;OUTPUTS:    r, theta, phi    (same as x,y,z)
;KEYWORDS:   ph_0_360:   if positive, 0<=phi<=360, if zero, -180<=phi<=180,
;                        ***if negative, best guess phi range returned***
;            ph_hist:   a two element array of max and min values for phi.
;                        eg: if ph_0_360 is not set, and ph_hist=[-220,220]
;                            then if d(phi)/dt is positive near 180, then
;                            phi => phi+360 when phi passes the 180/-180
;                            discontinuity until phi reaches 220.
;            CO_LATITUDE:  If set theta will be in co-latitude. (0<=theta<=180)
;            MIN_VALUE:
;            MAX_VALUE:
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)cart_to_sphere.pro	1.13 02/04/17
;
;NOTES:
;   -90 < theta < 90   (latitude not co-lat)
;-
pro cart_to_sphere,x,y,z,r,theta,phi, $
   ph_0_360=ph_0_360,ph_hist=ph_hist,  $
   co_latitude=co_lat,  $
   min_value=min_value,   max_value=max_value
rho = x*x + y*y
r = sqrt(rho + z*z)
phi = 180./!dpi*atan(y,x)
theta = 180./!dpi*atan(z/sqrt(rho))
if keyword_set(co_lat) then theta = 90.-theta

ph_mid = 0                      ; middle value of phi
if not keyword_set(ph_0_360) then ph_0_360 = 0
if ph_0_360 ne 0 then begin
  tmp_phi = phi
  a = where((phi ge -180) and (phi lt 0),acount)
  if acount ne 0 then tmp_phi(a) = tmp_phi(a)+360 ;make 0<=tmp_phi<=360
  if ((ph_0_360 lt 0) and (n_elements(phi) gt 1)) then begin   ;auto range phi
    subt = [[-1],[1]]           ; [a,b]##subt = b-a
    mmp  = (ceil(minmax(phi,    min=-360,max=360)##subt))(0) ;phi range
    mmtp = (ceil(minmax(tmp_phi,min=-360,max=360)##subt))(0) ;tmp range
    if mmp eq mmtp then begin   ;if ranges are equal, choose one with fewer
      a = where(abs(ts_diff(phi,    1)) gt 300,bcount)         ;branch cuts
      a = where(abs(ts_diff(tmp_phi,1)) gt 300,ccount)
      if bcount gt ccount then ph_mid = 180
    endif else if mmp gt mmtp then ph_mid = 180
  endif else ph_mid = 180       ;if ph_0_360 positive
  if ph_mid eq 180 then phi = tmp_phi
  tmp_phi = 0                   ;deallocate memory
endif

if keyword_set(ph_hist) then begin
  if (dimen1(ph_hist) ne 2) or (size(/type,ph_hist) ge 6) then begin
    print,'PH_HIST should be a two element array of numbers'
    print,'Ignoring request.'
  endif else begin
    for i=1l,n_elements(phi)-1 do begin
      if ((phi(i-1) gt ph_mid)              and $
          (phi( i ) lt ph_mid)              and $
          (phi( i ) lt ph_hist(1)-360))     $
        then phi(i) = phi(i)+360
      if ((phi(i-1) lt ph_mid)              and $
          (phi( i ) gt ph_mid)              and $
          (phi( i ) gt ph_hist(0)+360))     $
        then phi(i) = phi(i)-360
    endfor
  endelse
endif

if n_elements(min_value) ne 0 then begin
   bad = where(x le min_value,count)
   min = min(x)
   if count ne 0 then begin
      r(bad) = min
      theta(bad) = min
      phi(bad) = min
   endif
endif

if n_elements(max_value) ne 0 then begin
   bad = where(x ge max_value,count)
   min = max(x)
   if count ne 0 then begin
      r(bad) = max
      theta(bad) = max
      phi(bad) = max
   endif
endif

if size(/type,x(0)) eq 4 then begin ;if x input is float, make angles floats
  theta = float(theta)
  phi = float(phi)
endif

return
end

