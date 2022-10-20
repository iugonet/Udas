pro sub_legend,lim,unit,min_data,max_data,csize
;*********************************************************************
; legend (scale)
;*********************************************************************
x_poly=fltarr(4)
y_poly=fltarr(4)
for i=0,254 do begin
  y_poly(0)=lim*(2.0*i/255.0-1.0)
  y_poly(1)=lim*(2.0*i/255.0-1.0)
  y_poly(2)=lim*(2.0*(i+1)/255.0-1.0)
  y_poly(3)=lim*(2.0*(i+1)/255.0-1.0)
  x_poly(0)=lim*(1.0+2.0/30.0)
  x_poly(1)=lim*(1.0+4.0/30.0)
  x_poly(2)=lim*(1.0+4.0/30.0)
  x_poly(3)=lim*(1.0+2.0/30.0)
  color_num=i
  polyfill,x_poly,y_poly,color=color_num,/data
endfor
for j=0,8 do begin
  plots,[lim*(1.0+2.0/30.0),lim*(1.0+4.0/30.0)],[lim*(j/4.0-1.0),lim*(j/4.0-1.0)],/data,color=255
endfor
for j=1,2 do begin
  plots,[lim*(1.0+2.0*j/30.0),lim*(1.0+2.0*j/30.0)],[-lim,lim],/data,color=255
endfor
loadct,4
capfile=strcompress(unit)
capfilem=strcompress(string(format='((e8.1))',min_data))
capfilep=strcompress(string(format='((e8.1))',max_data))
xyouts,lim*(1.0+4.0/30.0),-lim,capfilem,/data,charsize=csize
xyouts,lim*(1.0+4.0/30.0),+lim,capfilep,/data,charsize=csize
xyouts,lim*(1.0+4.0/30.0),0.0,capfile,/data,charsize=csize
return
end
