;+
; Procedure:
;         netcdf3_info_to_tplot, netcdfi
;
; Purpose:
;         Creates TPLOT variables from a netCDF3 structure (obtained from "NETCDF3_LOAD_VAR")
;
; Input:
;         netcdfi: netCDF structure obtained from netcdf_load_vars_g
;
; Keywords:
;         prefix:
;         suffix:
;         verbose: request more verbose output
;
; $LastChangedBy: $
; $LastChangedyyyymmdd: $
; $LastChangedRevision: $
; $URL: $
;-

pro netcdf3_info_to_tplot, netcdfi, varnames, time_dimension=time_dimension, time_variable=time_variable, $
  v_dimension=v_dimension, v_variable=v_variable, $
  prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname,  $
  all = all, $
  verbose=verbose,$
  tplotnames=tplotnames

  ;; initialize
  if size(netcdfi,/type) ne 8 then begin
    dprint,dlevel=1,verbose=verbose,'Must provide a netCDF structure'
    return
  endif

  ;; tplot names
  tplotnames=''

  ;; keywords
  vbs = keyword_set(verbose) ? verbose : 0
  if ~keyword_set(varnames) then varnames=''
  if keyword_set(all) then varnames=tag_names(netcdfi.vars)

  ;; time dimension, variable
  if ~keyword_set(time_dimension) then time_dimension = "time"
  if ~keyword_set(time_variable) then time_variable = "time"
  if keyword_set(time_dimension) AND ~keyword_set(time_variable) then begin
    time_variable = time_dimension
  endif
  if ~keyword_set(time_dimension) AND keyword_set(time_variable) then begin
    time_dimension = time_variable
  endif

  if keyword_set(goes) then begin
    time_dimension = "record"
    time_variable = "time_tag"
  endif

  ;; check time dimension, variable
  t_dim_index = where(strmatch(tag_names(netcdfi.dims), time_dimension, /fold_case))
  t_var_index = where(strmatch(tag_names(netcdfi.vars), time_variable, /fold_case))

  if t_dim_index eq -1 then begin
    dprint, dlevel=1, 'invalid time dimension name.  exiting...'
    return
  endif

  if t_var_index eq -1 then begin
    dprint, dlevel=1, 'invalid time variable name.  exiting...'
    return
  endif

  ;; v dimension and variable
  if keyword_set(v_dimension) AND keyword_set(v_variable) then begin
    v_dim_index = where(strmatch(tag_names(netcdfi.dims), v_dimension, /fold_case))
    v_var_index = where(strmatch(tag_names(netcdfi.vars), v_variable, /fold_case))
    if v_dim_index eq -1 then begin
      dprint, dlevel=1, 'invalid v dimension name.  exiting...'
      return
    endif
    if v_var_index eq -1 then begin
      dprint, dlevel=1, 'invalid v variable name.  exiting...'
      return
    endif
  endif
  if keyword_set(v_dimension) AND ~keyword_set(v_variable) then begin
    v_variable = v_dimension
    v_dim_index = where(strmatch(tag_names(netcdfi.dims), v_dimension, /fold_case))
    v_var_index = where(strmatch(tag_names(netcdfi.vars), v_variable, /fold_case))
    if v_dim_index eq -1 then begin
      dprint, dlevel=1, 'invalid v dimension name.  exiting...'
      return
    endif
    if v_var_index eq -1 then begin
      dprint, dlevel=1, 'invalid v variable name.  exiting...'
      return
    endif
  endif
  if ~keyword_set(v_dimension) AND keyword_set(v_variable) then begin
    v_dimension = v_variable
    v_dim_index = where(strmatch(tag_names(netcdfi.dims), v_dimension, /fold_case))
    v_var_index = where(strmatch(tag_names(netcdfi.vars), v_variable, /fold_case))
    if v_dim_index eq -1 then begin
      dprint, dlevel=1, 'invalid v dimension name.  exiting...'
      return
    endif
    if v_var_index eq -1 then begin
      dprint, dlevel=1, 'invalid v variable name.  exiting...'
      return
    endif
  endif


  ;; convert time
  v =netcdfi.vars.(t_var_index)
  pos1 = strpos(v.units, ' since ')
  tu = strmid(v.units, 0, pos1)
  dd = strmid(v.units, pos1+7, 10)
  ttlt = strmid(v.units, pos1+7+11)

  tt = ttlt
  ll = ''
  sign = ''

  if strpos(ttlt, '+') ne -1 then begin
    tt = strmid(ttlt, 0, strpos(ttlt, '+'))
    ll = strmid(ttlt, strpos(ttlt, '+')+1)
    sign = strmid(ttlt, strpos(ttlt, '+'),1)
  endif
  if strpos(ttlt, '-') ne -1 then begin
    tt = strmid(ttlt, 0, strpos(ttlt, '-'))
    ll = strmid(ttlt, strpos(ttlt, '-')+1)
    sign = strmid(ttlt, strpos(ttlt, '-'),1)
  endif

  ;; calculate unix time
  case tu of
    'milliseconds': unit=0.001D
    'seconds': unit=1.0D
    'minutes': unit=60.0D
    'hours': unit=3600.0D
    'days': unit=86400.0D
    else: dprint, 'No match'
  endcase

  if strpos(sign,'+') eq 0 then offset = time_double(dd) + time_double('1970-01-01/'+tt) - time_double('1970-01-01/'+ll) $
  else offset = time_double(dd) + time_double('1970-01-01/'+tt) + time_double('1970-01-01/'+ll)
  *(v.dataptr)  = ((*v.dataptr) * unit) + offset


  ;; tplot variables
  nv = netcdfi.nv
  for i = 0L,nv-1 do begin
    v = netcdfi.vars.(i)
    if where(strmatch(varnames, v.name, /fold_case)) ne -1 then begin
      ;; create tplot variables
      ;; which has dimension of time, but ignore time itself
      indx_t = where(v.dimids eq t_dim_index[0])
      if (indx_t ne -1) AND (strmatch(time_variable, v.name, /fold_case) ne 1) then begin


        ;; 1-d data
        if n_elements(v.dimids) eq 1 then begin
          ;;data
          data = {x:*(netcdfi.vars.(t_var_index[0]).dataptr), y:v.dataptr}

          ;; attributes
          v_attributes={}
          for l=0,n_tags(v)-2 do begin
            v_attributes = create_struct(v_attributes, (tag_names(v))[l], v.(l))
          endfor
          netcdfstuff = {filename:netcdfi.filename, gatt:netcdfi.g_attributes, vatt:v_attributes}
          spec = 0
          limit = {spec:spec}

          ;;tplot name
          tn = v.name
          if keyword_set(midfix) then begin
            if size(/type,midpos) eq 7 then str_replace,tn,midpos,midfix    $
            else    tn = strmid(tn,0,midpos) + midfix + strmid(tn,midpos)
          endif
          if keyword_set(prefix) then tn = prefix+tn
          if keyword_set(suffix) then tn = tn+suffix

          ;; tplot variable
          store_data, tn, data=data, dlimit=netcdfstuff, limit=limit, verbose=verbose
          tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn
        endif


        ;; 2-d data
        if n_elements(v.dimids) eq 2 then begin
          ;; 2-nd dimension
          indx_z = where(v.dimids ne t_dim_index[0])
          ;; v dimension check
          if ~keyword_set(v_dimension) AND ~keyword_set(v_variable) then begin
            ;; v variable has the same name as v dimension
            v_var_index = where(strmatch(tag_names(netcdfi.vars), (tag_names(netcdfi.dims))[v.dimids[indx_z]], /fold_case))
            if v_var_index[0] eq -1 then begin
              dprint, dlevel=1, 'no v variable name which has the same name as v dimension.  go to next step...'
              continue
            endif

            ;;data
            ;;tranpose, if necessary
            y_new = *(v.dataptr)
            if indx_t eq 1 then begin
              data = {x:*(netcdfi.vars.(t_var_index[0]).dataptr), y:transpose(y_new), v:*(netcdfi.vars.(v_var_index[0]).dataptr)}
            endif else begin
              data = {x:*(netcdfi.vars.(t_var_index[0]).dataptr), y:y_new, v:*(netcdfi.vars.(v_var_index[0]).dataptr)}
            endelse

            ;; attributes
            v_attributes={}
            for l=0,n_tags(v)-2 do begin
              v_attributes = create_struct(v_attributes, (tag_names(v))[l], v.(l))
            endfor
            netcdfstuff = {filename:netcdfi.filename, gatt:netcdfi.g_attributes, vatt:v_attributes}
            spec = 1
            limit = {spec:spec}

            ;;tplot name
            tn = v.name
            if keyword_set(midfix) then begin
              if size(/type,midpos) eq 7 then str_replace,tn,midpos,midfix    $
              else    tn = strmid(tn,0,midpos) + midfix + strmid(tn,midpos)
            endif
            if keyword_set(prefix) then tn = prefix+tn
            if keyword_set(suffix) then tn = tn+suffix

            ;; tplot variable
            store_data, tn, data=data, dlimit=netcdfstuff, limit=limit, verbose=verbose
            tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn

          endif else begin
            ;; v dimension name check
            if where(strmatch((tag_names(netcdfi.dims))[v.dimids[indx_z]], v_dimension, /fold_case)) then begin
              dprint, dlevel=1, 'mismatched v dimension name1.  go to next step...'
              continue
            endif

            ;;data
            ;;tranpose, if necessary
            y_new = *(v.dataptr)
            if indx_t eq 1 then begin
              data = {x:*(netcdfi.vars.(t_var_index[0]).dataptr), y:transpose(y_new), v:*(netcdfi.vars.(v_var_index[0]).dataptr)}
            endif else begin
              data = {x:*(netcdfi.vars.(t_var_index[0]).dataptr), y:y_new, v:*(netcdfi.vars.(v_var_index[0]).dataptr)}
            endelse

            ;; attributes
            v_attributes={}
            for l=0,n_tags(v)-2 do begin
              v_attributes = create_struct(v_attributes, (tag_names(v))[l], v.(l))
            endfor
            netcdfstuff = {filename:netcdfi.filename, gatt:netcdfi.g_attributes, vatt:v_attributes}
            spec = 1
            limit = {spec:spec}

            ;;tplot name
            tn = v.name
            if keyword_set(midfix) then begin
              if size(/type,midpos) eq 7 then str_replace,tn,midpos,midfix    $
              else    tn = strmid(tn,0,midpos) + midfix + strmid(tn,midpos)
            endif
            if keyword_set(prefix) then tn = prefix+tn
            if keyword_set(suffix) then tn = tn+suffix

            ;; tplot variable
            store_data, tn, data=data, dlimit=netcdfstuff, limit=limit, verbose=verbose
            tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn

          endelse
        endif


        ;; 3-d
        if (n_elements(v.dimids) eq 3) then begin
          ;; keywords check
          if ~keyword_set(v_dimension) OR ~keyword_set(v_variable) then begin
            dprint, dlevel=1, 'no v dimension and variable for 3-d data.  skipping...'
            continue
          endif

          ;; v dimension check
          indx_z = where(v.dimids eq v_dim_index[0])
          if (indx_z ne -1) then begin

            for k = 0,n_tags(netcdfi.dims)-1 do begin
              if k eq t_dim_index[0] then continue
              if k eq v_dim_index[0] then continue
              loop = netcdfi.dims.(k)
              s_varname = (tag_names(netcdfi.dims))[k]
            endfor

            for m = 0L,loop-1 do begin
              y_new = *(v.dataptr)

              if ((indx_t eq 0) AND (indx_z eq 1)) or ((indx_t eq 1) AND (indx_z eq 0)) then begin
                y_new = reform(y_new[*,*,m])
              endif
              if ((indx_t eq 0) AND (indx_z eq 2)) or ((indx_t eq 2) AND (indx_z eq 0)) then begin
                y_new = reform(y_new[*,m,*])
              endif
              if ((indx_t eq 1) AND (indx_z eq 2)) or ((indx_t eq 2) AND (indx_z eq 1)) then begin
                y_new = reform(y_new[m,*,*])
              endif

              if (indx_t gt indx_z) then y_new = transpose(y_new)

              data = {x:*(netcdfi.vars.(t_var_index[0]).dataptr), y:y_new, v:*(netcdfi.vars.(v_var_index[0]).dataptr)}

              ;; create tplot variable
              ;; attributes
              v_attributes={}
              for l=0,n_tags(v)-2 do begin
                v_attributes = create_struct(v_attributes, (tag_names(v))[l], v.(l))
              endfor

              netcdfstuff = {filename:netcdfi.filename, gatt:netcdfi.g_attributes, vatt:v_attributes}
              spec = 1
              limit = {spec:spec}

              ;;tplot name
              tn = v.name
              if keyword_set(midfix) then begin
                if size(/type,midpos) eq 7 then str_replace,tn,midpos,midfix    $
                else    tn = strmid(tn,0,midpos) + midfix + strmid(tn,midpos)
              endif
              if keyword_set(prefix) then tn = prefix+tn
              tn = tn + '_' + s_varname + "_" + string(m, FORMAT='(i0)')
              if keyword_set(suffix) then tn = tn+suffix
              store_data, tn, data=data, dlimit=netcdfstuff, limit=limit, verbose=verbose
              tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn
            endfor
          endif
        endif


        ;; 4-d
        if (n_elements(v.dimids) eq 4) then begin
          ;; keywords check
          if ~keyword_set(v_dimension) OR ~keyword_set(v_variable) then begin
            dprint, dlevel=1, 'no v dimension and variable for 3-d data.  skipping...'
            continue
          endif

          ;; v dimension check
          indx_z = where(v.dimids eq v_dim_index[0])
          if (indx_z ne -1) then begin

            loop = []
            s_varname = []
            for k = 0,n_tags(netcdfi.dims)-1 do begin
              if k eq t_dim_index[0] then continue
              if k eq v_dim_index[0] then continue
              loop = [loop, netcdfi.dims.(k)]
              s_varname = [s_varname, (tag_names(netcdfi.dims))[k]]
            endfor

            for m = 0L,loop[0]-1 do begin
              for n = 0L,loop[1]-1 do begin
                y_new = *(v.dataptr)

                if ((indx_t eq 0) AND (indx_z eq 1)) or ((indx_t eq 1) AND (indx_z eq 0)) then begin
                  y_new = reform(y_new[*, *, m, n])
                endif
                if ((indx_t eq 0) AND (indx_z eq 2)) or ((indx_t eq 2) AND (indx_z eq 0)) then begin
                  y_new = reform(y_new[*, m, *, n])
                endif
                if ((indx_t eq 0) AND (indx_z eq 3)) or ((indx_t eq 3) AND (indx_z eq 0)) then begin
                  y_new = reform(y_new[*, m, n, *])
                endif
                if ((indx_t eq 1) AND (indx_z eq 2)) or ((indx_t eq 2) AND (indx_z eq 1)) then begin
                  y_new = reform(y_new[m, *, *, n])
                endif
                if ((indx_t eq 1) AND (indx_z eq 3)) or ((indx_t eq 3) AND (indx_z eq 1)) then begin
                  y_new = reform(y_new[m, *, n, *])
                endif
                if ((indx_t eq 2) AND (indx_z eq 3)) or ((indx_t eq 3) AND (indx_z eq 2)) then begin
                  y_new = reform(y_new[m, n, *, *])
                endif

                if (indx_t gt indx_z) then y_new = transpose(y_new)

                data = {x:*(netcdfi.vars.(t_var_index[0]).dataptr), y:y_new, v:*(netcdfi.vars.(v_var_index[0]).dataptr)}

                ;; create tplot variable
                ;; attributes
                v_attributes={}
                for l=0,n_tags(v)-2 do begin
                  v_attributes = create_struct(v_attributes, (tag_names(v))[l], v.(l))
                endfor

                netcdfstuff = {filename:netcdfi.filename, gatt:netcdfi.g_attributes, vatt:v_attributes}
                spec = 1
                limit = {spec:spec}

                ;;tplot name
                tn = v.name
                if keyword_set(midfix) then begin
                  if size(/type,midpos) eq 7 then str_replace,tn,midpos,midfix    $
                  else    tn = strmid(tn,0,midpos) + midfix + strmid(tn,midpos)
                endif
                if keyword_set(prefix) then tn = prefix+tn
                tn = tn + '_' + s_varname[0] + "_" + string(m, FORMAT='(i0)') + "_" + s_varname[1] + "_" + string(n, FORMAT='(i0)')
                if keyword_set(suffix) then tn = tn+suffix
                store_data, tn, data=data, dlimit=netcdfstuff, limit=limit, verbose=verbose
                tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn
              endfor
            endfor
          endif

          ;; over 5-d
          if (n_elements(v.dimids) ge 5) then begin
            dprint, dlevel=1, 'unsupported high dimension data. skipping...'
            continue
          endif


        endif
      endif
    endif
  endfor
end

