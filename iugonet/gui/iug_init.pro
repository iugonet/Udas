;+
; PROCEDURE iug_init
; 
; :DESCRIPTION:
;    Initialize the environment for loading IUGONET data 
;
; :NOTE:
;    This procedure is called automatically on executing most of 
;    iugonet_*.pro.   
; 
; :Examples:
; 
; iug_init
; 
; if !iugonet.data_policy.ear then iug_load_ear, ..... 
; 
; if ~(iugonet.data_policy.sdfit) then begin
;   print, 'Data is not loaded unless you acknowledge the data policy!'
;   return
; endif 
; 
; :AUTHOR: 
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
; :HISTORY: 
;   2011/12/21: Created
; 
;-
pro iug_init, reset=reset

defsysv,'!iugonet',exists=exists
if (not keyword_set(exists)) or (keyword_set(reset)) then begin

  defsysv,'!iugonet', $
    { $
      init: 0 $
      ,data_policy: { $
                  aws_rish_id:  0b,    $ ;BIK,MND,PON
                  aws_rish_ktb: 0b,    $ ;KTB
                  aws_rish_sgk: 0b,    $ ;SGK
                  blr_rish_ktb: 0b,    $
                  blr_rish_sgk: 0b,    $
                  blr_rish_srp: 0b,    $
                  ionosonde_rish: 0b,  $
                  ltr_rish: 0b,        $
                  wpr_rish_bik: 0b,    $
                  wpr_rish_mnd: 0b,    $
                  wpr_rish_pon: 0b,    $
                  wpr_rish_sgk: 0b,    $
                  mf_rish: 0b,         $
                  meteor_rish: 0b,     $
                  sdfit_hok:  0b,      $    ;HOK
                  sdfit_ksr:  0b,      $    ;KSR
                  sdfit_syo:  0b,      $    ;SYE,SYS
                  gmag_mm210_adl: 0b,     $
                  gmag_mm210_bik: 0b,     $
                  gmag_mm210_bsv: 0b,     $
                  gmag_mm210_can: 0b,     $
                  gmag_mm210_cbi: 0b,     $
                  gmag_mm210_chd: 0b,     $
                  gmag_mm210_dal: 0b,     $
                  gmag_mm210_daw: 0b,     $
                  gmag_mm210_ewa: 0b,     $
                  gmag_mm210_gua: 0b,     $
                  gmag_mm210_kag: 0b,     $
                  gmag_mm210_kat: 0b,     $
                  gmag_mm210_kot: 0b,     $
                  gmag_mm210_ktb: 0b,     $
                  gmag_mm210_ktn: 0b,     $
                  gmag_mm210_lmt: 0b,     $
                  gmag_mm210_lnp: 0b,     $
                  gmag_mm210_mcq: 0b,     $
                  gmag_mm210_mgd: 0b,     $
                  gmag_mm210_msr: 0b,     $
                  gmag_mm210_mut: 0b,     $
                  gmag_mm210_onw: 0b,     $
                  gmag_mm210_ppi: 0b,     $
                  gmag_mm210_ptk: 0b,     $
                  gmag_mm210_ptn: 0b,     $
                  gmag_mm210_rik: 0b,     $
                  gmag_mm210_tik: 0b,     $
                  gmag_mm210_wep: 0b,     $
                  gmag_mm210_wew: 0b,     $
                  gmag_mm210_wtk: 0b,     $
                  gmag_mm210_yap: 0b,     $
                  gmag_mm210_ymk: 0b,     $
                  gmag_mm210_zyk: 0b,     $
                  gmag_nipr_syo:  0b, $    ;Syowa
                  gmag_nipr_ice:  0b, $    ;Iceland
                  gmag_wdc:     0b,   $
                  gmag_wdc_dst: 0b,   $
                  gmag_wdc_ae_asy: 0b,$
                  gmag_magdas: 0b,    $
                  ear:     0b,        $
                  iprt:    0b,        $
                  eiscat:  0b,        $
                  radiosonde_rish: 0b, $
                  mu:    0b           $
                } $
    }
    
endif

if keyword_set(reset) then !iugonet.init=0

if !iugonet.init ne 0 then return


!iugonet.init = 1

return
end
