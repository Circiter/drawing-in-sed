# drawing-in-sed

A simple drawing program written in [GNU] sed. Takes a textual stream of commands as input and
produces a *.pgm file as output (N.B, not an ASCII-art, but an actual image!).

Usage:
```bash
cat two-squares.script | ./draw.sed > image.pgm

# Then if you have for example the fbi (by Gerd Hoffmann) you
# can view this image file even without the X11:
fbi image.pgm

# If you have the ImageMagick installed,
# you can pipe a image directly:
cat triangle.script | ./draw.sed | display
```
As an example, the content of `triangle.script`
(note the usage of unary numbers in current early release):
```
goto x=111111111; y=111111;
line dx=1; dy=1; length=1111111;
line dx=-1; dy=; length=11111111111111;
line dx=1; dy=-1; length=1111111;
```

See the source code (`draw.sed`) for details.
