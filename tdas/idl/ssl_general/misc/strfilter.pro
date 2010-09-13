;+
;FUNCTION:
;  res =  strfilter(stringarray,searchstring)
;PURPOSE:
;  Returns the subset of stringarray that matchs searchstring
;  '*' will match all (non-null) strings
;  ''  will match only the null string
;  Output can be modified with keywords
;  NOTE: this routine is very similar to the STRMATCH routine introduced in IDL 5.3
;     it has some enhancements that make it useful.
;     (i.e.: filterstring can also be an array)
;INPUT:
;  stringarray:  An array of strings to be filtered
;  searchstring: A string that may contain wildcard characters ("*")
;           (If searchstring is an array then results are OR'd together)
;RETURN VALUE:
;  Either:
;     Array of matching strings.
;  or:
;     Array of string indices.
;  or:
;     Byte array with same dimension as input string.
;  Depends upon keyword setting (See below)
;
;KEYWORDS:
;  FOLD_CASE: if set then CASE is ignored.   (only IDL 5.3 and later)
;  STRING: if set then the matching strings are returned.  (default)
;  INDEX:  if set then the indices are returned.
;  BYTES:  if set then a byte array is returned with same dimension as input string array (similar to STRMATCH).
;  NEGATE: pass only strings that do NOT match.
;  COUNT:  A named variable that will contain the number of matched strings.
;Limitations:
;  This function still needs modification to accept the '?' character
;  July 2000;  modified to use the IDL strmatch function so that '?' is accepted for versions > 5.4
;EXAMPLE:
;  Print,strfilter(findfile('*'),'*.pro',/negate) ; print all files that do NOT end in .pro
;AUTHOR:
;  Davin Larson,  Space Sciences Lab, Berkeley; Feb, 1999
;VERSION:  01/10/08
;-
function strfilter,str,matchs,count=count,  $
     wildcard=wildcard,fold_case=fold_case,  $
     delimiter=delimiter, $
     index=index,string=retstr,byte=bt,negate=negate


if !version.release ge '5.3' then begin
   matcharray = keyword_set(matchs) ? matchs : ''
   if keyword_set(delimiter) and size(/dimen,matcharray) eq 0 then $
        matcharray = strsplit(matcharray,delimiter,/extract)
   if keyword_set(wildcard) then message,/info,'Wildcard "'+wildcard+'" ignored'
   ret = 0b
   for k=0,n_elements(matcharray)-1 do $
     ret = strmatch(str,matcharray[k],fold_case=fold_case) or ret

endif else begin   ; Old version follows:

ns = strlen(str)
ret = ns eq -1   ; set to 0

if not keyword_set(wildcard) then wildcard='*'

for k=0,n_elements(matchs)-1 do begin
match = matchs[k]

;mss=str_sep(match,wildcard)
mss=strsplit(match,wildcard,/extract)
nmss= keyword_set(match) ? n_elements(mss) : 0

;quick test to improve speed,  required to find a null string
if match eq wildcard then begin
    ret[*] = 1
    goto,skip   ; pass all strings
endif

;quick test to improve speed, but not required
if nmss eq 1 then begin        ;no wildcards to match do the simple thing
    ret = (str eq match) or ret
    goto,skip
endif


lms = strlen(mss)

for i=0,n_elements(str)-1 do begin    ; Unfortunately strmid and strpos don't allow pos to be vectors
  temp = str[i]                     ; so an extra loop is required here
  p = 0
  for j=0,nmss-1 do begin
    p2 = (j lt nmss-1) ? strpos(temp,mss[j],p) : rstrpos(temp,mss[j])
    if j eq 0 then r = (p2 eq 0) else r = (p2 ge p)
    p = p2 + lms[j]
    if r eq 0 then goto,break
  endfor
  r = p eq ns[i]
  break:
  ret[i]= ret[i] or r
endfor
skip:

endfor
endelse    ; end of old version


if keyword_set(negate) then ret = (ret eq 0)
ind = where(ret,count)
nstr = count eq 0 ?  '' : str[ind]
if keyword_set(retstr) then return, nstr
if keyword_set(index)  then return, ind
if keyword_set(bt)     then return, ret
;message,/info,'Please use KEYWORD, default will change to STRING'
return,nstr   ; this default may change!
end

