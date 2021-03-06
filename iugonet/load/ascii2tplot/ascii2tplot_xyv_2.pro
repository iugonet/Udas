;+
; PROCEDURE: ascii2tplot_xyv_2
;   ascii2tplot_xyv_2, files, files=files2, tformat=tformat, $
;        tvarnames=tvarnames, vvec=vvec, $
;        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
;        time_column=time_column, input_time=input_time
;
; PURPOSE:
;   Loads data from ascii format files.
;
; KEYWORDS:
;   files : Ascii data files which you want to load.
;   tformat : Format string for date&time such as "YYYY-MM-DD/hh:mm:ss"
;   tvarnames : A string for output tplot variable names.
;       (e.g., tvarnames='tvar0')
;   vvec : A vector for vdata, where vdata[1:nv] is used to create tplot variations 
;       by the command as follows;
;       store_data, tvarnames, data={x:xdata, y:ydata, v:vdata}.
;       xdata[1:nx] is made from date&time and ydada[1:nx,1:nv] is identified 
;       by tvar_column.
;   delimiter : A scalar string that identifies the end of a field. 
;       One or more single characters are allowed. (e.g., deliminator=', ;')
;   data_start : Number of header lines you want to skip.
;       (e.g., data_start=10)
;   comment_symbol : A string that identifies the character used to delineate 
;       comments.
;   time_column : Optional. If this keyword is set, "tformat" is not used.
;       A vector of 6 melements that shows the existence of date&time data,
;       (year, month, day, hour, minute, second) in the ascii file. For example, 
;       if the data file includes the columns for [hour minute second] only, 
;       then time_column = [0, 0, 0, 1, 1, 1].
;   input_time : Need to set this keyword when the time_column is set.
;       For example, if the data file includes the columns for [hour minute second] 
;       only, then you need to set [year, month day] as follows; 
;       input_time = [2017, 3, 1, 0, 0, 0].       
;
; EXAMPLE:
;   ascii2tplot_xyv_2, files='stn20120301.txt', tformat='YYYY-MM-DD hh:mm:ss.fff', $
;        tvarnames='Ne', vvec=[0, 0.1, 0.2, 0.5, 1.0, 2.0, 4.0, 8.0], 
;        delimiter=',', comment_symbol=';'
;
; Written by Y.-M. Tanaka, April 25, 2018 (ytanaka at nipr.ac.jp)
;-

pro ascii2tplot_xyv_2, files, files=files2, tformat=tformat, $
        tvarnames=tvarnames, vvec=vvec, $
        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
        time_column=time_column, input_time=input_time

;===== Keyword check =====
;----- default -----;
if keyword_set(files2) then files=files2
if ~keyword_set(tformat) then tformat='YYYY MM DD hh mm ss'
if ~keyword_set(delimiter) then delimiter=','
if ~keyword_set(data_start) then data_start=0
if ~keyword_set(comment_symbol) then comment_symbol=''
if ~keyword_set(tvarnames) then tvarnames='tplotvar1'

;----- Check input argument -----;
if size(tvarnames, /n_elements) ne 1 then begin
    print, '"tvarnames" must be a scalar string.'
    return
endif

no_use_tformat=0
if keyword_set(time_column) then begin
    if n_elements(time_column) ne 6 then begin
        print, 'Number of elements of time_column must be 6.'
        return
    endif
    if time_column[0]*time_column[1]*time_column[2]*time_column[3]*time_column[4]*time_column[5] eq 0 then begin
        if ~keyword_set(input_time) then begin
            print, 'input_time is needed if any elements of time_column are zero.'
            return
        endif
    endif
    no_use_tformat=1
    ntimecol=fix(total(time_column gt 0))
endif

tdiff=0

xvec=''
yvec=''
for fi=0,n_elements(files)-1 do begin
    if file_test(files[fi]) eq 0 then begin
        dprint,dlevel=1,verbose=verbose,'File not found: "'+files[fi]+'"'
        continue
    endif

    xvectmp=''
    yvectmp=''
    vvectmp=''
    ;----- Read each file -----;
    openr, lun, files[fi], /get_lun
    ;----- Skip Header -----;
    if data_start gt 0 then begin
        for i=0, data_start-1 do begin
            line=''
            readf, lun, line
            print, line
        endfor
    endif

    while ~eof(lun) do begin
        line=''
        readf, lun, line
        if (strlen(comment_symbol) gt 0) and $
           (strmid(line, 0, strlen(comment_symbol)) eq comment_symbol) then begin
            print, line
            continue
        endif
        if no_use_tformat eq 1 then begin
            dat=double(strsplit(line, delimiter, /extract))
            tim=time_struct('')
            itnow=0
            if time_column[0] eq 0 then begin
                yyyy=input_time[0]
            endif else begin
                yyyy=dat[0]
                itnow++
            endelse
            if yyyy lt 100 then begin
                if yyyy lt 70 then yyyy=yyyy+2000 else yyyy=yyyy+1900
            endif
            if time_column[1] eq 0 then begin
                mo=input_time[1]
            endif else begin
                mo=dat[1]
                itnow++
            endelse
            if time_column[2] eq 0 then begin
                dd=input_time[2]
            endif else begin
                dd=dat[2]
                itnow++
            endelse
            if time_column[3] eq 0 then begin
                hh=input_time[3]
            endif else begin 
                hh=dat[3]
                itnow++
            endelse
            if time_column[4] eq 0 then begin
                mn=input_time[4]
            endif else begin
                mn=dat[4]
                itnow++
            endelse
            if time_column[5] eq 0 then begin
                ss=input_time[5]
            endif else begin
                ss=dat[5]
                itnow++
            endelse
            tim.year=yyyy & tim.month=mo & tim.date=dd
            tim.hour=hh & tim.min=mn & tim.sec=ss
            append_array, xvectmp, time_double(tim)
            append_array, yvectmp, transpose(dat[ntimecol:n_elements(dat)-1])
        endif else begin
            tline=strmid(line, 0, strlen(tformat))
            tim=time_parse(tline, tformat=tformat, tdiff=tdiff)
            dline=strmid(line, strlen(tformat), strlen(line)-strlen(tformat))
            dat=double(strsplit(dline, delimiter, /extract))
            append_array, xvectmp, time_double(tim)
            append_array, yvectmp, transpose(dat)
        endelse
    endwhile

    free_lun, lun

    append_array, xvec, xvectmp
    append_array, yvec, yvectmp
endfor

if xvec[0] eq '' then return

if ~keyword_set(vvec) then begin
     vvec=indgen(n_elements(yvec[0,*]))
endif

store_data, tvarnames, data={x:xvec, y:yvec, v:vvec}
options, tvarnames, spec=1

end
