;+
;
;Name:
;iug_load_crib_ear.pro
;
;Purpose:
;Demonstrate the RISH EAR data loader.
;
;Code:
;A. Shinbori, 02/01/2011.
;
;Modifications:
; 
;
;-


;Specify timespan:
;=================
timespan,'2005-08-24',3,/day

;Load field aligned irregularity (FAI) observation data taken by EAR in timespan:
;Details of the parameter1 and parameter2 are described in the EAR-FAI homepage
;(http://www.rish.kyoto-u.ac.jp/ear/data-fai/index.html#param):
;E-region ----> datatype = 'e_region'
;E/F-region ----> datatype = 'ef_region'
;V-region ----> datatype = 'v_region'
;F-region ----> datatype = 'F_region'
;===============================================================================
iug_load_ear, datatype = 'e_region',  parameter1 = 'eb3p4b', parameter2 = ['dpl1','pwr1','wdt1','pn1']


;Plot time-height distribution of radial Doppler velocity and echo intensity for beam 1:
;=======================================================================================
tplot,['iug_ear_faieb3p4b_dpl1','iug_ear_faieb3p4b_pwr1','iug_ear_faieb3p4b_wdt1','iug_ear_faieb3p4b_pn1']

stop

;Substract the average data of radial Doppler velocity, echo intensity, spectral width and noise level for beam 1:
;=================================================================================================================
tsub_average,'iug_ear_faieb3p4b_dpl1'
tsub_average,'iug_ear_faieb3p4b_pwr1'
tsub_average,'iug_ear_faieb3p4b_wdt1'
tsub_average,'iug_ear_faieb3p4b_pn1'
tplot,['iug_ear_faieb3p4b_dpl1-d','iug_ear_faieb3p4b_pwr1-d','iug_ear_faieb3p4b_wdt1-d','iug_ear_faieb3p4b_pn1-d']

stop

;1-hour running average  of radial Doppler velocity, echo intensity, spectral width and noise level for beam 1:
;==============================================================================================================
tsmooth_in_time, 'iug_ear_faieb3p4b_dpl1', 600
tsmooth_in_time, 'iug_ear_faieb3p4b_pwr1', 600
tsmooth_in_time, 'iug_ear_faieb3p4b_wdt1', 600
tsmooth_in_time, 'iug_ear_faieb3p4b_pn1', 600

tplot, ['iug_ear_faieb3p4b_dpl1_smoothed','iug_ear_faieb3p4b_pwr1_smoothed','iug_ear_faieb3p4b_wdt1_smoothed','iug_ear_faieb3p4b_pn1_smoothed']

stop

;Load all the standard observation data of the troposphere and stratosphere 
;taken by the EAR in timespan:
;Tplot variables are 'iug_mu_uwnd', 'iug_mu_vwnd', 'iug_mu_wwnd', 'iug_ear_pwr1', 
;'iug_ear_pwr2', 'iug_ear_pwr3', 'iug_ear_pwr4', 'iug_ear_pwr5', 'iug_ear_wdt1',
;'iug_ear_wdt2', 'iug_ear_wdt3', 'iug_ear_wdt4', 'iug_ear_wdt5', 'iug_ear_dpl1',
;'iug_ear_dpl2', 'iug_ear_dpl3', 'iug_ear_dpl4', 'iug_ear_dpl5', 'iug_ear_pn1',
;'iug_ear_pn2', 'iug_ear_pn3, 'iug_ear_pn4', 'iug_ear_pn5':
;  uwnd = zonal wind:
;  vwnd = meridional wind
;  wwnd = vertical wind
;  pwr = echo intensity, wdt = spectral width, dpl = radial Doppler velocity,
;  pn = noise level
;===============================================================================
iug_load_ear, datatype = 'troposphere'


;Plot time-height distribution of zonal, meridional and vertical winds in the troposphere:
;========================================================================================
tplot,['iug_ear_uwnd','iug_ear_vwnd','iug_ear_wwnd']

stop

; Set up the plot time range of EAR data in the ionosphere and troposphere:
;==========================================================================
tlimit, '2005-08-24 11:00:00', '2005-08-25 00:00:00'
tplot

end

