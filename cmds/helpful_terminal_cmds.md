# Helpful Information to know

## Reducing video file size (higher crf = lower quality)
- `ffmpeg -i testVideo.mp4 -c:v libx264 -preset slow -crf 33 -c:a copy testVideo_lowquality.mp4`

## Splitting/Merging pdf
- `pdftk full-pdf.pdf cat 12-15 output outfile_p12-15.pdf`
- `pdftk file1.pdf file2.pdf cat output mergedfile.pdf`
