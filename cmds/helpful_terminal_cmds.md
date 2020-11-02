# Helpful Information to know

## Reducing video file size (higher crf = lower quality)
- `ffmpeg -i testVideo.mp4 -c:v libx264 -preset slow -crf 33 -c:a copy testVideo_lowquality.mp4`

## Splitting/Merging pdf
- `pdftk full-pdf.pdf cat 12-15 output outfile_p12-15.pdf`
- `pdftk file1.pdf file2.pdf cat output mergedfile.pdf`

## Making GIFs
- ffmpeg -i eye_tracker.mp4 -r 5 -vf "scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -ss 00:00:00 -to 00:00:15 eye_tracker.gif
