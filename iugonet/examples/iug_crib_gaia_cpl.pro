;+
; PROGRAM: iug_crib_gaia_cpl
;   This is an example crib sheet that will load GAIA cpl data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run iug_crib_gaia_cpl
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
iug_load_gaia_cpl_nc, parameter ='xoi', uname = 'realion', passwd ='DataDL01'

; Create three different tplot variables for keogram plot at the geographical latitude and longitude and altitude 
; of 35.0 [deg], 135 [deg], and 300 [km].
; If the glong is not set, this procedure will create a keogram data along the geographical latitude and longitude 
; and altitude of 0.0 [deg], 2.5 [deg], and 300 [km].
gaia_cpl_keogram, 'iug_gaia_cpl_xoi', altitude = 300.0, glat = 35.0, glong = 135.0

; View the loaded data names
tplot_names

; Create a latitude-time plot (keogram) at a specific longitude:
tplot, ['gaia_cpl_xoi_height_time_36.0', 'gaia_cpl_xoi_glong_time_135.0','gaia_cpl_xoi_glat_time_36.0']
stop

; Create a two-dimensional map at a specific time:
gaia_cpl_2dmap, 'gaia_cpl_xoi', st_time = '2017-09-07/01:00:00', altitude = 300.0

end
