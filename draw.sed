#!/bin/sed -Enf

# A simple drawing application in sed.
# Usage: cat two-squares.script | ./draw.sed | display
# or: cat triangle.script | ./draw.sed > image.pgm
# N.B., the `display' is from ImageMagick;
# see netpbm.sourceforge.net for other pgm-supporting software.

# Repository: https://github.com/Circiter/drawing-in-sed

# (c) Written by Circiter (mailto:xcirciter@gmail.com)
# License: MIT.

# TODO: Try to implement a Lindenmayer systems (lsystem).

# Supported syntax:
# goto x=<x>; y=<y>;
# line dx=<dx>; dy=<dy>; length=<length>;
# fill

# TODO: Implement the `size' command to specify canvas dimensions:
# size w=<width>; h=<height>;

:read $!{N; bread;}; G

# Fixed canvas size (22x22); just for a testing purposes.
s/$/@xxxxxxxxxxxxxxxxxxxxxx\n/
s/@/@>/
:copy_row
    s/@([>x]*\n)/@\1\1/
    s/>x/x>/
    />\n/! bcopy_row

s/>//g;
s/^(.*)@(.*)$/\2@\1/

# TODO: Try add support for decimal numbers.
# N.B., currently all numbers are in base 1.

:execute_command
    /@goto/ {
        s/>//; s/^/>/
        :row
            s/>([xy]*\n)/\1>/
            s/(@[^\n]*y=)1/\1/
            /@[^\n]*y=;/! brow

        :column
            s/>([xy])/\1>/
            s/(@[^\n]*x=)1/\1/
            /@[^\n]*x=;/! bcolumn

        bnext
    }

    # FIXME: Draw a solid slanted lines (fill a gaps when dx
    # and/or dy are/is greater [by absolute value] than 1).
    /@line/ {
        :draw_line
            s/@[^\n]*dx=-*/&,/
            s/@[^\n]*dy=-*/&,/
            s/>[xy]/>y/

            :begin_next_column
                /@[^\n]*dx=-*1*,;/ bend_next_column

                /@[^\n]*dx=-/ s/([xy])>/>\1/
                /@[^\n]*dx=[^-]/ s/>([xy])/\1>/

                s/(@[^\n]*dx=-*1*),1/\11,/
                bbegin_next_column
            :end_next_column

            :begin_next_row
                /@[^\n]*dy=-*1*,;/ bend_next_row
                s/\n([^\n]*)(\n@.*$)/\n\1\2|\1/
                s/(\|.*)>/\1/
                :up_or_down
                    /@[^\n]*dy=-/ s/(.)([\n]*)>/>\1\2/
                    /@[^\n]*dy=[^-]/ s/>([\n]*)(.)/\1\2>/
                    s/\|[xy]/|/
                    /\|x/ bup_or_down
                s/\|//
                s/(@[^\n]*dy=-*1*),1/\11,/
                bbegin_next_row
            :end_next_row

            s/,//g
            s/(@[^\n]*length=)1/\1/
            /@[^\n]*length=;/! bdraw_line

        bnext
    }

    /@fill/ {
        s/>[xy]/z/ # N.B., Invalidates the last goto.
        s/$/|\n\n/

        :fill_neighborhood
            s/zx/zz/; s/xz/zz/;

            # Mark the beginning of each line.
            s/^/>/;
            :mark s/\n([^>\n]*\n)(.*@)/\n>\1\2/; tmark
            :scan # Select each column in turn.
                s/>x([^>]*>z)/>z\1/g
                s/(>z[^>]*>)x/\1z/g
                s/>([^\n])/\1>/g
                />\n/! bscan
            s/>//g

            # Count all the z's.
            :count_z s/\|1*/&1/; s/z/w/; /z/ bcount_z

            # Compare this number with the previous.
            s/\|/&,/; s/\|[^\n]*\n/&$/
            :compare
                s/,([^\n])/\1,/; s/\$([^\n])/\1$/
                /,\n/ {/\$\n/ bfilled; bnot_equal}
                /\$\n/ bnot_equal
                bcompare

            :not_equal
                s/,//; s/\$//
                s/w/z/g
                # Save current result for later comparisons.
                s/\|([^\n]*\n).*$/|\n\1/
                bfill_neighborhood

        :filled # OK, a fixed point found.
            s/\|.*$//; s/w/y/g
            bnext
    }

    :next
        s/@[^\n]*\n/@/
        /@$/! bexecute_command

s/>//; s/@//

s/^/P2\n22 22\n10\n/
s/[xy]/& /g; y/xy/09/

p

# TODO: Try to include the rule 30 automaton here (for random numbers generation).
