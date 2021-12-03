;+
; PROGRAM: iug_crib_gaia_gcm
;   This is an example crib sheet that will load GAIA gcm data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run iug_crib_gaia_gcm
;
; NOTE: See the rules of the road.
;       For more information, see https://gaia-web.nict.go.jp/data_e.html
;
; Written by: A. Shinbori, Oct 27, 2021
;             DIMR, ISEE, Nagoya Univ.
;
;   $LastChangedBy: $
;   $LastChangedDate:  $
;   $LastChangedRevision:  $
;   $URL:  $
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2017-09-07'

; Load the data
iug_load_gaia_gcm_nc, parameter ='gu', uname = 'realion', passwd ='DataDL01'

; Create three different tplot variables for keogram plot at the geographical latitude and longitude and pressure
; of 35.0 [deg], 135 [deg], and 300 [hPa].
; If the glong is not set, this procedure will create a keogram data along the geographical latitude and longitude
; and pressure of 0.0 [deg], 2.5 [deg], and 300 [hPa].
gaia_gcm_keogram, 'gaia_gcm_gu', press = 300.0, glat = 35.0, glong = 135.0

; View the loaded data names
tplot_names

; Create a latitude-time plot (keogram) at a specific longitude:
tplot, ['gaia_gcm_gu_press_time_34.9', 'gaia_gcm_gu_glong_time_135.0','gaia_gcm_gu_glat_time_34.9']
stop

; Create a two-dimensional map at a specific time:
gaia_gcm_2dmap, 'gaia_gcm_gu', st_time = '2017-09-07/01:00:00', press = 300.0

end
