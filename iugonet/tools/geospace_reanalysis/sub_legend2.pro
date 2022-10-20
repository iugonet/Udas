pro sub_legend2,limx,limy,unit,min_data,max_data,csize
;*********************************************************************
; legend (scale)
;*********************************************************************
x_poly=fltarr(4)
y_poly=fltarr(4)
for i=0,254 do begin
  y_poly(0)=limy*(2.0*i/255.0-1.0)
  y_poly(1)=limy*(2.0*i/255.0-1.0)
  y_poly(2)=limy*(2.0*(i+1)/255.0-1.0)
  y_poly(3)=limy*(2.0*(i+1)/255.0-1.0)
  x_poly(0)=limx+2.0
  x_poly(1)=limx+4.0
  x_poly(2)=limx+4.0
  x_poly(3)=limx+2.0
  color_num=i
  polyfill,x_poly,y_poly,color=color_num,/data
endfor
for j=0,8 do begin
  plots,[limx+2.0,limx+4.0],[limy*(j/4.0-1.0),limy*(j/4.0-1.0)],/data,color=255
endfor
for j=1,2 do begin
  plots,[limx+2.0*j,limx+2.0*j],[-limy,limy],/data,color=255
endfor
loadct,4
capfile=strcompress(unit)
capfilem=strcompress(string(format='((e8.1))',min_data))
capfilep=strcompress(string(format='((e8.1))',max_data))
xyouts,limx+4.0,-limy,capfilem,/data,charsize=csize
xyouts,limx+4.0,+limy,capfilep,/data,charsize=csize
xyouts,limx+4.0,0.0,capfile,/data,charsize=csize
return
end
