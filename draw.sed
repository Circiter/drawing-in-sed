#!/bin/sed -Enf

# A simple drawing application in sed. Implements
# a somewhat restricted variant of turtle graphics.

# Now with partial support for Lindenmayer systems (L-systems).

# Usage: cat two-squares.script | ./draw.sed | display
# or: cat triangle.script | ./draw.sed > image.pgm
# N.B., the `display' is from ImageMagick;
# see netpbm.sourceforge.net for other pgm-supporting software.

# Repository: https://github.com/Circiter/drawing-in-sed

# (c) Written by Circiter (mailto:xcirciter@gmail.com)
# License: MIT.

# Supported syntax:
# size w=<width>; h=<height>;
# goto x=<x>; y=<y>;
# line dx=<dx>; dy=<dy>; length=<length>;
# lsys depth=<recursion_depth>; axiom=<first_generation>; rule=<var>::<substitution>; ... rule=...;
# fill

:read $!{N; bread;}; G

# Illegal characters in the input stream: ^,_@$><

# Backup the canvas size.
s/^/@/
:search_size
    /@size/ {
        s/(@size[^\n]*w=)([0-9]*;)([^\n]*h=)([0-9]*;)(.*)$/\1\2\3\4\5out w=+\2 h=+\4\n/
        bend_search_size
    }
    s/@([^\n]*\n)/\1@/
    /@$/! bsearch_size
:end_search_size
s/@//

# Convert all the numbers from decimal to unary notation.
:preprocess_decimals
    x; s/^.*$//; x
    /=-*[0-9]*;/! bend_preprocess_decimals
    s/(=-*)([0-9]*);/\1^\2^;/
    :decrement
        /=-*\^0\^;/ bend_decrement
        :replace_zero s/0(_*\^)/_\1/; treplace_zero
        s/\^(.*)\^/^9876543210,\1^/
        :decrement_digit
            s/(.)(.)(,.*)\1(_*\^)/\1\3\2\4/
            tmatched; s/.,/,/; :matched
            /[^\^][^\^],/ bdecrement_digit
        s/\^.*,/^/
        s/_/9/g
        s/\^0([^\^])/\^\1/
        x; s/$/1/; x
        bdecrement
    :end_decrement
    G; x; s/^.*$//; x
    s/\^(.*)\^(.*)\n(1*)$/@\3@\2/
    bpreprocess_decimals
:end_preprocess_decimals

s/\@//g; s/^/@/

:execute_command
    /@size/ {
        s/$/$/
        :create_row
            s/$/x/
            s/(@[^\n]*w=)1/\1/
            /@[^\n]*w=;/! bcreate_row
        s/$/\n/
        :copy_row
            s/\$(x*\n)/$\1\1/
            s/(@[^\n]*h=)1/\1/
            /@[^\n]*h=;/! bcopy_row
        s/^.*(@.*)\$(.*)$/\2\1/
        bnext
    }

    /@lsys/ {
        s/$/$/
        s/(@[^\n]*axiom=)([^\n;]*)(;.*\$)/\1\2\3\2/
        # First, we need to perform all the productions of
        # the L-system.
        :next_generation
            s/(@[^\n]*depth=)1/\1/ # Decrement the recursion depth.
            s/\$/$./
            :apply_rules
                # Find an appropriate rule and make corresponding substitution.
                s/(@[^\n]*rule=)(.)::([^\n;]*)(;.*\$.*)\.\2/\1\2::\3\4\3./
                tfound
                s/\.(.)/\1./ # Identity production for a constant.
                :found
                /\.$/! bapply_rules
            s/\.$//
            /@[^\n]*depth=;/! bnext_generation

        # Second, we need to transform the generated configuration
        # into a stream of drawing commands.
        s/$/\^dx=; dy=1;\n/
        :draw
            /\$F/ {s/\^([^\n]*)(\n.*)$/\^\1\2line \1 length=1;\n/}

            /\$\+/ { # Turn left (counter-clockwise) 90 degrees.
                /\^dx=;/ {s/\^dx=; dy=([^;]*);/\^dx=\1; dy=;/; blsys_next}
                s/\^dx=([^;]*); dy=;/\^dx=; dy=-\1;/; s/dy=--/dy=/
            }

            /\$-/ { # Turn right 90 degrees.
                /\^dx=;/ {s/\^dx=; dy=([^;]*);/\^dx=-\1; dy=;/; s/dx=--/dx=/; blsys_next}
                s/\^dx=([^;]*); dy=;/\^dx=; dy=\1;/
            }

            :lsys_next
            s/\$[^\^]/$/
            /\$\^/! bdraw

        s/\$\^[^\n]*\n/\$/
        s/@[^\n]*\n(.*)\$(.*)$/@\2\1/

        bnext
    }

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
    # and/or dy are/is greater [by its absolute value] than 1).
    /@line/ {
        :draw_line
            s/(@[^\n]*dx=-*)([^-])/\1,\2/
            s/(@[^\n]*dy=-*)([^-])/\1,\2/
            s/>[xy]/>y/

            :begin_next_column
                /@[^\n]*dx=-*1*,;/ bend_next_column

                /@[^\n]*dx=-/ s/([xy])>/>\1/
                /@[^\n]*dx=[^-]/ s/>([xy])/\1>/

                s/(@[^\n]*dx=-*1*),1/\11,/
                bbegin_next_column
            :end_next_column

            #p

            :begin_next_row
                /@[^\n]*dy=-*1*,;/ bend_next_row
                s/\n([^\n]*)(\n@.*$)/\n\1\2|\1/
                s/(\|.*)>/\1/
                :up_or_down
                    /@[^\n]*dy=-/ s/([^\n])([\n]*)>/>\1\2/
                    /@[^\n]*dy=[^-]/ s/>([\n]*)([^\n@])/\1\2>/
                    s/\|[xy]/|/
                    /\|[xy]/ {/>\n@/! bup_or_down}
                s/\|.*$//
                s/(@[^\n]*dy=-*1*),1/\11,/
                bbegin_next_row
            :end_next_row

            s/,//g
            s/(@[^\n]*length=)1/\1/
            /@[^\n]*length=;/! bdraw_line

        bnext
    }

    /@fill/ {
        h; x; s/^.*@//; x; s/@.*$/@/ # Backup the script.

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

            # Compare this number with the previous one.
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
            G; s/@\n/@/ # Restore the script.
            bnext
    }

    /@out/ {
        # FIXME: The line is too long.
        s/^(.*\@out[^\n]*w=\+)([0-9]*)(;[^\n]*h=\+)([0-9]*);/P2\n\2 \4\n10\n\1\2\3\4;/
        s/\@.*$//; s/>//
        s/[xy]/& /g; y/xy/09/
        p; q
    }

    :next
        s/@[^\n]*\n/@/
        /@$/! bexecute_command
