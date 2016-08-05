pro reorderImage

  ;;; INPUTS ;;;
  base_file = 'R:\users\sarah.shivers\ImagefromSpectra_WV\CropLib_sli_img' ; Image to be reordered
  
  ;;; OUTPUTS ;;;
  out_folder = 'R:\users\sarah.shivers\ImagefromSpectra_WV'
  out_img = base_file+'_box2'

  ;;; SETTING UP ENVI/IDL ENVIRONMENT ;;;
  COMPILE_OPT STRICTARR
  envi, /restore_base_save_files
  ENVI_BATCH_INIT ;Doesn't require having ENVI open - use with stand alone IDL 64 bit
  ;;; DONE SETTING UP ENVI/IDL ENVIRONMENT ;;;
  ;

  envi_open_file, base_file, R_FID = fidBase ;Open the basefile
  envi_file_query, fidBase, $ ;Get information about basefile
    NS = NS, $ ;Number of Samples
    NL = NL, $ ; Number of Lines
    NB = NB, $ ;Number of Bands
    dims = dims, $
    data_type = data_type, $
    interleave = 0, $
    bnames = BNAMES, $
    wl=WL, $
    map_info = map_info

  ;create empty array for DN image
  newS = 30 ;new samples
  newL = 35 ;new lines
  line = make_array(NS,NL,NB)
  box = make_array(newS,newL,NB)  ;for 1050 spectra in a 30 by 35 array
  
  ; populate empty array
  for z=0, NB-1 do begin
    line[*,*,z] = ENVI_GET_DATA(fid = fidBase, dims = dims, pos = z)
  endfor

  BoxL = 7 ;;number of lines for each smaller box
  BoxS = 5 ;;number of samples for each smaller box
  RowPix = 210 ;; number of pixels in the first row of smaller boxes
 
 for b=0, NB-1 do begin 
    i=1 ;; total number of pixels
    l=1 ;; iterator for new number of lines
    s=1 ;; iterator for new number of samples
    while i LT NL do begin
        if (s MOD BoxS NE 0) AND (l MOD BoxL NE 0) THEN BEGIN  ;;case when not at the end of a box column or row
          box[s-1,l-1,b] = line[0,i-1,b]
          i++
          s++
        endif
        if (s MOD BoxS NE 0) AND (l MOD BoxL EQ 0) THEN BEGIN ;;case when at the last row of the small box but not on the final pixel of that box
          box[s-1,l-1,b] = line[0,i-1,b]
          i++
          s++
        endif
        if (s MOD BoxS EQ 0) AND (l MOD BoxL NE 0) THEN BEGIN  ;;case when you hit the end of a small box row but it is not the final row of that box
          box[s-1,l-1,b] = line[0,i-1,b]
          s=s-(BoxS-1)
          i++
          l++
        endif
        if (s MOD BoxS EQ 0) AND (l MOD BoxL EQ 0) AND (i MOD RowPix NE 0) THEN BEGIN ;;case when you are in the last pixel of the small box but you have not reached the end of the larger box row
          box[s-1,l-1,b] = line[0,i-1,b]
          l=l-(BoxL-1)
          i++
          s++
        endif
        if (s MOD BoxS EQ 0) AND (l MOD BoxL EQ 0) AND (i MOD RowPix EQ 0) THEN BEGIN ;;case when you are in the last pixel of the small box and also at the end of the larger row
          box[s-1,l-1,b] = line[0,i-1,b]
          s=s-(newS-1)
          i++
          l++
        endif 
   endwhile
 endfor

print, 'loop done'

  openw,2,out_img
  writeu, 2, box
  close,2

  ENVI_SETUP_HEAD, fname= out_img+'.hdr', $
    NB = NB, NL = newL, NS = newS, data_type= data_type, interleave=0,$
    bnames=BNAMES, wl=WL, map_info = map_info,/write


  print, 'DONE'

END