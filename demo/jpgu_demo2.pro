;+
; NAME:
;       20100510_yoshida_crib.pro
;
; MODIFICATION HISTORY:
;       last update: 2010-05-12 14:24:24 daiki
;-
;timespan, '2006-12-01', 31, /days
;
;kyoto_load_ae, datatype=['au','al']
;tplot_names
;tplot, ['kyoto_au', 'kyoto_al']
;
;
; ��������

while 1 do begin
   print, '=================================================='
   print, '  left click: select time for fmt data'
   print, ' right click: exit procedure'
   print, '=================================================='

   ctime, t, minutes = 1, npoints = 1
   ;print,'Time (Click) =',t
   ;��1������å���t�˳�Ǽ��1ʬ���������Ť������ǡ������ˤ�äƤϼ�ưĴ��)

   if t eq 0 then break

   current_window = !d.window
   t_str = time_string(t, format = 6)
   fmt_tvscl, t_str, t2
   ; (call hida fmt data, t2 format is YYYY-MM-DD/hh:mm:ss)
   ;print,'Time (Image) =',time_double(t2)


   wset,current_window
   ; (wset�Ͼ�꤯�����ʤ��äݤ�)
   ; (������ɥ�0������衢���ν�����0�˼¹Ԥ�������Ǥ⤢��)
   tlimit, /full, window = 0
   timebar, t, color = 0
   timebar, time_double(t2), color = 0, linestyle=2
endwhile

; �����ޤ�

end



