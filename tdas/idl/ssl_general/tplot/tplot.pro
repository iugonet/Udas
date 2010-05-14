;+
;PROCEDURE:   tplot  [,datanames]
;PURPOSE:
;   Creates a time series plot of user defined quantities.
;INPUT:
;   datanames: A string of space separated datanames.
;             wildcard expansion is supported.
;             if datanames is not supplied then the last values are used.
;             Each name should be associated with a data quantity.
;             (see the "STORE_DATA" and "GET_DATA" routines.)
;             Alternatively datanames can be an array of integers or strings.
;             run "TPLOT_NAMES" to show the current numbering.
;
;KEYWORDS:
;   TITLE:    A string to be used for the title. Remembered for future plots.
;   ADD_VAR:  Set this variable to add datanames to the previous plot.  If set
;         to 1, the new panels will appear at the top (position 1) of the
;         plot.  If set to 2, they will be inserted directly after the
;         first panel and so on.  Set this to a value greater than the
;         existing number of panels in your tplot window to add panels to
;             the bottom of the plot.
;   LASTVAR:  Set this variable to plot the previous variables plotted in a
;         TPLOT window.
;   PICK:     Set this keyword to choose new order of plot panels
;             using the mouse.
;   WINDOW:   Window to be used for all time plots.  If set to -1, then the
;             current window is used.
;   VAR_LABEL:  String [array]; Variable(s) used for putting labels along
;     the bottom. This allows quantities such as altitude to be labeled.
;   VERSION:  Must be 1,2,3, or 4 (3 is default)  Uses a different labeling
;   scheme.  Version 4 is for rocket-type time scales.
;   OVERPLOT: Will not erase the previous screen if set.
;   NAMES:    The names of the tplot variables that are plotted.
;   NOCOLOR:  Set this to produce plot without color.
;   TRANGE:   Time range for tplot.
;   NEW_TVARS:  Returns the tplot_vars structure for the plot created. Set
;         aside the structure so that it may be restored using the
;             OLD_TVARS keyword later. This structure includes information
;             about various TPLOT options and settings and can be used to
;             recreates a plot.
;   OLD_TVARS:  Use this to pass an existing tplot_vars structure to
;     override the one in the tplot_com common block.
;   HELP:     Set this to print the contents of the tplot_vars.options
;         (user-defined options) structure.
;
;RESTRICTIONS:
;   Some data must be loaded prior to trying to plot it.  Try running
;   "_GET_EXAMPLE_DAT" for a test.
;
;EXAMPLES:  (assumes "_GET_EXAMPLE_DAT" has been run)
;   tplot,'amp slp flx2' ;Plots the named quantities
;   tplot,'flx1',/ADD          ;Add the quantity 'flx1'.
;   tplot                      ;Re-plot the last variables.
;   tplot,var_label=['alt']   ;Put Distance labels at the bottom.
;       For a long list of examples see "_TPLOT_EXAMPLE"
;
;OTHER RELATED ROUTINES:
;   Examples of most usages of TPLOT and related routines are in
;      the crib sheet: "_TPLOT_EXAMPLE"
;   Use "TNAMES" function to return an array of current names.
;   Use "TPLOT_NAMES" to print a list of acceptable names to plot.
;   Use "TPLOT_OPTIONS" for setting various global options.
;   Plot limits can be set with the "YLIM" procedure.
;   Spectrogram limits can be set with the "ZLIM" procedure.
;   Time limits can be set with the "TLIMIT" procedure.
;   The "OPTIONS" procedure can be used to set all IDL
;      plotting keyword parameters (i.e. psym, color, linestyle, etc) as well
;      as some keywords that are specific to tplot (i.e. panel_size, labels,
;      etc.)  For example, to change the relative panel width for the quantity
;      'slp', run the following:
;            OPTIONS,'slp','panel_size',1.5
;   TPLOT calls the routine "SPECPLOT" to make spectrograms and
;      calls "MPLOT" to make the line plots. See these routines to determine
;      what other options are available.
;   Use "GET_DATA" to retrieve the data structure (or
;      limit structure) associated with a TPLOT quantity.
;   Use "STORE_DATA" to create new TPLOT quantities to plot.
;   The routine "DATA_CUT" can be used to extract interpolated data.
;   The routine "TSAMPLE" can also be used to extract data.
;   Time stamping is performed with the routine "TIME_STAMP".
;   Use "CTIME" or "GETTIME" to obtain time values.
;   tplot variables can be stored in files using "TPLOT_SAVE" and loaded
;      again using "TPLOT_RESTORE"
;
;CREATED BY:    Davin Larson  June 1995
;
;QUESTIONS?
;   See the archives at:  http://lists.ssl.berkeley.edu/mailman/listinfo/tplot
;Still have questions:
;   Send e-mail to:  tplot@ssl.berkeley.edu    someone might answer!
;
;FILE:  tplot.pro
;VERSION:  1.97
;LAST MODIFICATION:  02/11/01
; $LastChangedBy: davin-win $
; $LastChangedDate: 2009-09-03 16:28:21 -0700 (Thu, 03 Sep 2009) $
; $LastChangedRevision: 6683 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/tags/tdas_5_21/tplot/tplot.pro $
;-

pro tplot,datanames,      $
   WINDOW = wind,         $
   NOCOLOR = nocolor,     $
   VERSION = ver,         $
   OPLOT = oplot,         $
   OVERPLOT = overplot,   $
   TITLE = title,         $
   LASTVAR = lastvar,     $
   ADD_VAR = add_var,     $
   LOCAL_TIME= local_time,$
   REFDATE = refdate,     $
   VAR_LABEL = var_label, $
   OPTIONS = opts,        $
   T_OFFSET = t_offset,   $
   TRANGE = trng,         $
   NAMES = names,         $
   PICK = pick,           $
   new_tvars = new_tvars, $
   old_tvars = old_tvars, $
   datagap = datagap,     $
   help = help

@tplot_com.pro

if keyword_set(old_tvars) then tplot_vars = old_tvars

if keyword_set(help) then begin
    printdat,tplot_vars.options,varname='tplot_vars.options'
    new_tvars = tplot_vars
    return
endif

; setup tplot_vars....
tplot_options,ver=ver,title=title,var_label=var_label,refdate=refdate, $
   wind=wind, options = opts


if keyword_set(overplot) then oplot=overplot
if n_elements(trng) eq 2 then trange = time_double(trng)

chsize = !p.charsize
if chsize eq 0. then chsize=1.

def_opts= {ymargin:[4.,2.],xmargin:[12.,12.],position:fltarr(4), $
   title:'',ytitle:'',xtitle:'', $
   xrange:dblarr(2),xstyle:1,    $
   version:3, window:-1, wshow:0,  $
   charsize:chsize,noerase:0,overplot:0,spec:0}

extract_tags,def_opts,tplot_vars.options

; Define the variables to be plotted:

;str_element,tplot_vars,'options.varnames',tplot_var
; if n_elements(tplot_var) eq 0 then $
;    str_element,tplot_vars,'options.varnames',['NULL'],/add_replace

if keyword_set(pick) then $
   ctime,prompt='Click on desired panels. (button 3 to quit)',panel=mix,/silent
if n_elements(mix) ne 0 then datanames = tplot_vars.settings.varnames(mix)

if keyword_set(add_var)  then begin
   names = tnames(datanames,/all)
   if add_var eq 1 then datanames = [names,tplot_vars.options.varnames] else $
    if (add_var gt n_elements(tplot_vars.options.varnames)) then $
        datanames = [tplot_vars.options.varnames,names] else $
        datanames = [tplot_vars.options.varnames[0:add_var-2],names,$
           tplot_vars.options.varnames[add_var-1:*]]
endif


dt = size(/type,datanames)
ndim = size(/n_dimen,datanames)

if dt ne 0 then begin
   if dt ne 7 or ndim ge 1 then dnames = strjoin(tnames(datanames,/all),' ') $
   else dnames=datanames
endif else begin
	tpv_opt_tags = tag_names( tplot_vars.options)
	idx = where( tpv_opt_tags eq 'DATANAMES', icnt)
	if icnt gt 0 then begin
		dnames=tplot_vars.options.datanames
	endif else begin
		return
	endelse
endelse

;if dt ne 0 then names= tnames(datanames,/all)

if keyword_set(lastvar) then str_element,tplot_vars,'settings.last_varnames',names

;if keyword_set(names) then begin
;   str_element,tplot_vars,'settings.last_varnames',tplot_vars.options.varnames,$
;       /add_replace
;   str_element,tplot_vars,'options.varnames',names,/add_replace ;  array of names
;   str_element,tplot_vars,'settings.varnames',names,/add_replace
;endif else names = tplot_vars.options.varnames

str_element,tplot_vars,'options.lazy_ytitle',lazy_ytitle

varnames = tnames(dnames,nd,ind=ind,/all)

str_element,tplot_vars,'options.datanames',dnames,/add_replace
str_element,tplot_vars,'options.varnames',varnames,/add_replace

if nd eq 0 then begin
   print,'No valid variable names found to tplot! (use TPLOT_NAMES to display)'
   return
endif

;ind = array_union(tplot_vars.options.varnames,data_quants.name)

sizes = fltarr(nd)
for i=0,nd-1 do begin
   dum = 1.
   lim = 0
   get_data,tplot_vars.options.varnames[i],alim=lim
   str_element,lim,'panel_size',value=dum
   sizes[i] = dum
endfor

plt = {x:!x,y:!y,z:!z,p:!p}

if (!d.flags and 256) ne 0  then begin    ; windowing devices
   current_window= !d.window > 0
   if def_opts.window ge 0 then w = def_opts.window $
   else w = current_window
;test to see if this window exists before wset, jmm, 7-may-2008:
;removed upper limit on window number, jmm, 19-mar-2009
   device, window_state = wins
   if(w Eq 0 Or wins[w]) then wset,w else begin
     dprint, 'Window is closed and Unavailable, Returning'
     w = current_window
     def_opts.window = w
     tplot_options, window = w
     return
   endelse
   if def_opts.wshow ne 0 then wshow ;,icon=0   ; The icon=0 option doesn't work with windows
   str_element,def_opts,'wsize',value = wsize
   wi,w,wsize=wsize
endif

str_element,tplot_vars,'settings.y',replicate(!y,nd),/add_replace
str_element,tplot_vars,'settings.clip',lonarr(6,nd),/add_replace
str_element,def_opts,'ygap',value = ygap
str_element,def_opts,'charsize',value = chsize

if keyword_set(nocolor) then str_element,def_opts,'nocolor',nocolor,/add_replace

nvlabs = [0.,0.,0.,1.,0.]
str_element,tplot_vars,'options.var_label',var_label
if keyword_set(var_label) then if size(/type,var_label) eq 7 then $
    if ndimen(var_label) eq 0 then var_label=tnames(var_label) ;,/extrac)
nvl = n_elements(var_label) + nvlabs(def_opts.version)
def_opts.ymargin = def_opts.ymargin + [nvl,0.]

!p.multi = 0
pos = plot_positions(ysizes=sizes,options=def_opts,ygap=ygap)

if  keyword_set(trange) then str_element,tplot_vars,'options.trange',trange,/add_replace $
else  str_element,tplot_vars,'options.trange',trange
if trange[0] eq trange[1] then $
    trg=minmax(reform(data_quants[ind].trange),min_value=0.1) $
else trg = trange

if def_opts.version eq 3 then begin
   str_element,def_opts,'num_lab_min',value=num_lab_min
   str_element,def_opts,'tickinterval',value=tickinterval
   str_element,def_opts,'xtitle',value=xtitle
   if not keyword_set(num_lab_min) then $
      num_lab_min= 2. > (.035*(pos(2,0)-pos(0,0))*!d.x_size/chsize/!d.x_ch_size)
   time_setup = time_ticks(trg,time_offset,num_lab_min=num_lab_min, $
      side=vtitle,xtitle=xtitle,tickinterval=tickinterval,local_time=local_time)
   time_scale = 1.
   if keyword_set(var_label) then begin
      time = time_setup.xtickv+time_offset
      for i=0,n_elements(var_label)-1 do begin
         vtit = strmid(var_label(i),0,3)
         get_data,var_label(i),ptr=pdata,alimits=limits
         if size(/type,pdata) ne 8 then  dprint,var_label(i), ' not valid!'  $
         else begin
            def = {ytitle:vtit, format:'(F6.1)'}
;            extract_tags,def,data,tags = ['ytitle','format']
            extract_tags,def,limits,tags = ['ytitle','format']
            v = data_cut(var_label(i),time)
            vlab = strcompress( string(v,format=def.format) ,/remove_all)
            w = where(finite(v) eq 0,nw)
            if nw gt 0 then vlab(w) = ''
            vtitle = def.ytitle + '!C' +vtitle
            time_setup.xtickname = vlab +'!C'+time_setup.xtickname
            time_setup.xtitle = '!C'+time_setup.xtitle
         endelse
      endfor
   endif
   extract_tags,def_opts,time_setup
endif

if def_opts.version eq 2 then begin
   time_setup = timetick(trg(0),trg(1),0,time_offset,xtitle)
   time_scale = 1.
   if keyword_set(var_label) then begin
      time = time_setup.xtickv+time_offset
      vtitle = 'UT'
      for i=0,n_elements(var_label)-1 do begin
         vtit = strmid(var_label(i),0,3)
         get_data,var_label(i),ptr=pdata,alimits=limits
         if size(/type,pdata) ne 8 then  dprint,var_label(i), ' not valid!' $
         else begin
            def = {ytitle:vtit, format:'(F6.1)'}
;            extract_tags,def,data,tags = ['ytitle','format']
            extract_tags,def,limits,tags = ['ytitle','format']
            v = data_cut(var_label(i),time)
            vlab = strcompress( string(v,format=def.format) ,/remove_all)
            vtitle = vtitle + '!C' +def.ytitle
            time_setup.xtickname = time_setup.xtickname +'!C'+vlab
            xtitle = '!C'+xtitle
         endelse
      endfor
      def_opts.xtitle = xtitle
   endif else def_opts.xtitle = 'Time (UT) '+xtitle
   extract_tags,def_opts,time_setup
endif

if def_opts.version eq 1 then begin
   deltat = trg(1) - trg(0)
   case 1 of
      deltat lt 60. : begin & time_scale=1.    & tu='Seconds' & p=16 & end
      deltat lt 3600. : begin & time_scale=60.   & tu='Minutes' & p=13 & end
      deltat le 86400. : begin & time_scale=3600. & tu='Hours'   & p=10 & end
      deltat le 31557600. : begin & time_scale=86400. & tu='Days' & p=7 & end
      else            : begin & time_scale=31557600. & tu='Years' & p = 5 & end
   endcase
   ref = strmid(time_string(trg(0)),0,p)
   time_offset = time_double(ref)
;   print,ref+' '+tu,p,time_offset-trg(0)
   def_opts.xtitle = 'Time (UT)  '+tu+' after '+ref
   str_element,def_opts,'xtickname',replicate('',22),/add_replace
endif

if def_opts.version eq 4 then begin
  deltat = trg(1) - trg(0)
  time_scale=1.
  tu='Seconds'
  p=16
   ref = strmid(time_string(trg(0)),0,p)
   time_offset = 0
   dprint,ref+' '+tu,p,time_offset-trg(0)
   def_opts.xtitle = tu+' after launch'
   str_element,def_opts,'xtickname',replicate('',22),/add_replace
endif

t_offset = time_offset

def_opts.xrange = (trg-time_offset)/time_scale

if keyword_set(oplot) then def_opts.noerase = 1

;for i=0,nd-1 do begin
;  polyfill,(pos[*,i])([[0,1],[2,1],[2,3],[0,3]]),color=5,/norm
;endfor

;stop

init_opts = def_opts
init_opts.xstyle = 5
;if init_opts.noerase eq 0 then erase_region,_extra=init_opts
if  init_opts.noerase eq 0 then erase
init_opts.noerase = 1
str_element,init_opts,'ystyle',5,/add
box,init_opts

def_opts.noerase = 1
str_element,tplot_vars,'options.timebar',tbnames
if keyword_set(tbnames) then begin
   tbnames = tnames(tbnames)
   ntb = n_elements(tbnames)
   for i=0,ntb-1 do begin
      t = 0
      get_data,tbnames[i],data=d
      str_element,d,'x',t
      str_element,d,'time',t
      for j=0,n_elements(t)-1 do $
         oplot,(t[j]-time_offset)/time_scale*[1,1],[0,1],linestyle=1
   endfor
endif


str_element,/add,tplot_vars,'settings.y', replicate(!y,nd)
str_element,/add,tplot_vars,'settings.clip',lonarr(6,nd)



for i=0,nd-1 do begin
   name = tplot_vars.options.varnames(i)
   def_opts.position = pos(*,i)         ;  get the correct plot position
   get_data,name,alimits=limits,ptr=pdata,data=data,index=index,dtype=dtype

   if not keyword_set(pdata) and dtype ne 3 then  dprint,'Undefined variable data: ',name $
   else dprint,index,name,format='(i3," ",a)'
   if keyword_set(pdata) then  nd2 = n_elements(pdata) else nd2 = 1
   if dtype eq 3 then begin
    datastr = data
    yrange = [0.,0.]
    str_element,limits,'yrange',yrange
    if ndimen(datastr) eq 0 then datastr = strsplit(datastr,/extract)
    nd2 = n_elements(datastr)
    if yrange[0] eq yrange[1] then get_ylimits,datastr,limits,trg
   endif else datastr=0
   for d=0,nd2-1 do begin
     newlim = def_opts
     newlim.ytitle = keyword_set(lazy_ytitle) ? strjoin(strsplit(name,'_',/extract),'!c')  : name
     if keyword_set(datastr) then begin
        name = datastr[d]
        get_data,name,index=index,data=data,ptr=pdata,alimits=limits2,dtype=dtype
;help,limits2,/st
;stop
        if not keyword_set(pdata)  then  dprint,'Unknown variable: ',name $
        else dprint,index,name,format='(i3,"   ",a)'
     endif else limits2 = 0
     if size(/type,data) eq 8 then begin
        tshift = 0.d
        str_element,data,'tshift',value = tshift
;  printdat,name,tshift,limits2,dtype
        data.x = (*pdata.x - (time_offset-tshift))/time_scale
     endif  else data={x:dindgen(2),y:findgen(2)}
     extract_tags,newlim,data,      except = ['x','y','dy','v']
     extract_tags,newlim,limits2
     extract_tags,newlim,ylimits
     extract_tags,newlim,limits
;     extract_tags,newlim,def_opts
     newlim.overplot = d ne 0
     if keyword_set(overplot) then newlim.overplot = 1   ;<- *** LINE ADDED **
     if i ne (nd-1) then newlim.xtitle=''
     if i ne (nd-1) then newlim.xtickname = ' '
     ysubtitle = struct_value(newlim,'ysubtitle',def='')
     if keyword_set(ysubtitle) then newlim.ytitle += '!c'+ysubtitle
     if newlim.spec ne 0 then routine='specplot' else routine='mplot'
     str_element,newlim,'tplot_routine',value=routine
     color_table= struct_value(newlim,'color_table',default=-1) & pct=-1
     if color_table ge 0 then loadct2,color_table,previous_ct=pct
;if debug() then stop
     call_procedure,routine,data=data,limits=newlim
     if color_table ne pct then loadct2,pct
   endfor
   def_opts.noerase = 1
   def_opts.title  = ''
   tplot_vars.settings.y[i]=!y
   tplot_vars.settings.clip[*,i] = !p.clip
endfor
str_element,tplot_vars,'settings.varnames',varnames,/add_replace
str_element,tplot_vars,'settings.d',!d,/add_replace
str_element,tplot_vars,'settings.p',!p,/add_replace
str_element,tplot_vars,'settings.x',!x,/add_replace
str_element,tplot_vars,'settings.trange_cur',(!x.range * time_scale) + time_offset

if keyword_set(vtitle) then begin                 ; finish var_labels
  xspace = chsize * !d.x_ch_size / !d.x_size
  yspace = chsize * !d.y_ch_size / !d.y_size
  xpos = pos(0,nd-1) - (def_opts.xmargin(0)-1) * xspace
  ypos = pos(1,nd-1) - 1.5 * yspace
  xyouts,xpos,ypos,vtitle,/norm,charsize=chsize
endif


time_stamp,charsize = chsize*.5

if (!d.flags and 256) ne 0  then begin    ; windowing devices
  str_element,tplot_vars,'settings.window',!d.window,/add_replace
  if def_opts.window ge 0 then wset,current_window
endif
!x = plt.x
!y = plt.y
!z = plt.z
!p = plt.p


str_element,tplot_vars,'settings.time_scale',time_scale,/add_replace
str_element,tplot_vars,'settings.time_offset',time_offset,/add_replace
new_tvars = tplot_vars
return
end

