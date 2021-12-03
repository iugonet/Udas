;+
; PROCEDURE: IUG_CRIB_ELF_HOKUDAI
;    A sample crib sheet that explains how to use the  
;    "iug_load_gmag_nipr_induction" procedure. You can run this crib sheet 
;    by copying & pasting each command below (except for stop and end)
;    into the IDL command line. Or alternatively compile and run using
;    the command:
;        .run iug_crib_elf_hokudai
;
; NOTE: See the rules of the road.
;       For more information, see:
;       http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=103
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=115
; Written by: Y.-M. Tanaka, May 2, 2011
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Set the date and duration (in hour)
timespan, '2010-04-01', 1, /hour

; Load NIPR data
iug_load_elf_hokudai, site='syo'

; View the loaded data names
tplot_names

; Plot the loaded data
tplot, 'hokudai_elf_syo'

; Stop
print,'Enter ".c" to continue.'
stop

; Split vector
split_vec, 'hokudai_elf_syo'

; Calculate power spectrum
tdpwrspc, 'hokudai_elf_syo_0', nboxpoints=8192

; Plot
tplot, 'hokudai_elf_syo_0_dpwrspc'

; Change ylim
ylim, 'hokudai_elf_syo_0_dpwrspc', 0, 100, 0
options, 'hokudai_elf_syo_0_dpwrspc', 'ytitle', 'H-comp.!CFrequency'
options, 'hokudai_elf_syo_0_dpwrspc', 'ysubtitle', '[Hz]'

; Plot
tplot

end
