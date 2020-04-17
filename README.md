# drawing-in-sed

A simple drawing program written in [GNU] sed. Takes a textual stream of commands as input and
produces a *.pgm file as output (N.B., not an ASCII-art, but an actual image!).

Has a rudimentary (and very slow) support for simple Lindenmayer systems.

Usage:
```bash
cat two-squares.script | ./draw.sed > image.pgm

# Then you can view this file with any convenient method, e.g.,
# eog image.pgm
# preview image.pgm (works on MacOS)
 display image.pgm

# If you have for example the fbi (by Gerd Hoffmann) you
# can view this image file even without the X11:
fbi image.pgm

# If you have the ImageMagick installed,
# you can pipe a image directly:
cat triangle.script | ./draw.sed | display
```
As an example, the content of `triangle.script`
(note the usage of unary numbers in current early release):
```
size w=22; h=22;
goto x=9; y=6;
line dx=1; dy=1; length=7;
line dx=-1; dy=0; length=14;
line dx=1; dy=-1; length=7;
```

See the source code (`draw.sed`) and example scripts (`triangle.script`,
`two-squares.script`, `koch-curve.script`, `dragon-curve.script`) for details.

Author: Circiter (mailto:xcirciter@gmail.com).
