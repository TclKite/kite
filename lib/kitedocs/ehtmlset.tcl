#-----------------------------------------------------------------------
# TITLE:
#    ehtmlset.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    kitedocs(n) Package: ehtml(5) macro set
#
#    This module implements a macroset(i) extension for use with
#    macro(n).
#
#    TODO: Move more formatting into CSS.
#
#-----------------------------------------------------------------------

namespace eval ::kitedocs:: {
    namespace export ehtml
}

#-----------------------------------------------------------------------
# ehtml ensemble

snit::type ::kitedocs::ehtmlset {
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Configuration Type Variables

    typevariable manroots -array {}
    
    #-------------------------------------------------------------------
    # Public Methods

    # install macro
    #
    # macro   - The macro(n) instance
    #
    # Installs macros into the the macro(n) instance, and resets 
    # transient data.

    typemethod install {macro} {
        # FIRST, save the manroots
        $macro eval [list array set ::manroots [array get manroots]]

        # NEXT, define HTML equivalents.
        StyleMacro $macro b
        StyleMacro $macro i
        StyleMacro $macro code
        StyleMacro $macro tt
        StyleMacro $macro em
        StyleMacro $macro strong
        StyleMacro $macro sup
        StyleMacro $macro sub
        StyleMacro $macro pre

        HtmlTag $macro ol /ol
        HtmlTag $macro ul /ul
        HtmlTag $macro li /li
        HtmlTag $macro p /p
        HtmlTag $macro table /table
        HtmlTag $macro tr /tr
        HtmlTag $macro th /th
        HtmlTag $macro td /td

        $macro proc img {attrs} { return "<img $attrs>" }

        # NEXT, define basic macros.
        $macro proc hrule {} { return "<p><hr><p>" }
        $macro proc lb    {} { return "&lt;"       }
        $macro proc rb    {} { return "&gt;"       }


        $macro template link {url {anchor ""}} {
            if {$anchor eq ""} {
                set anchor $url
            }
        } {<a href="$url">$anchor</a>}

        $macro proc nbsp {text} {
            set text [string trim $text]
            regsub {\s\s+} $text " " text
            return [string map {" " &nbsp;} $text]
        }

        $macro proc quote {text} {
            string map {& &amp; < &lt; > &gt;} $text
        }


        $macro proc textToID {text} {
            # First, trim any white space and convert to lower case
            set text [string trim [string tolower $text]]
            
            # Next, substitute "_" for internal whitespace, and delete any
            # non-alphanumeric characters (other than "_", of course)
            regsub -all {[ ]+} $text "_" text
            regsub -all {[^a-z0-9_/]} $text "" text
            
            return $text
        }


        # NEXT, cross-references        
        $macro proc xrefset {id anchor url} {
            variable xreflinks

            set xreflinks($id) [dict create id $id anchor $anchor url $url]
            
            # Return the link.
            return [xref $id]
        }

        $macro proc xref {id {anchor ""}} {
            variable xreflinks
            variable manroots

            if {[pass] == 1} {
                return
            }

            set url ""

            # FIRST, is it an explicit xrefset.
            if {[info exists xreflinks($id)]} {
                set url [dict get $xreflinks($id) url]
                set defaultAnchor [dict get $xreflinks($id) anchor]
            } 

            # NEXT, is it a man page?
            if {$url eq "" &&
                [regexp {^([^:]+:)?([^()]+)\(([1-9a-z]+)\)$} $id \
                     dummy root name section]
            } {
                set root [string trim $root ":"]

                set pattern ""

                if {[info exists manroots($root:$section)]} {
                    set pattern $manroots($root:$section)
                } elseif {[info exists manroots($root:)]} {
                    set pattern $manroots($root:)
                } 

                if {$pattern ne ""} {
                    set url [string map [list %s $section %n $name] $pattern]

                    if {$anchor ne ""} {
                        append url "#[textToID $anchor]"
                    }

                    set defaultAnchor "${name}($section)"
                }
            }

            if {$url eq ""} {
                # TBD: This is ugly; need a mechanism for this kind
                # of reporting.
                puts "Warning: xref: unknown id '$id'"
                return "[lb]xref $id[rb]"
            }
            
            if {$anchor eq ""} {
                set anchor $defaultAnchor
            }

            return "<a href=\"$url\">$anchor</a>"
        }

        # NEXT, define changelog macros
        $macro template changelog {} {
            variable changeCounter
            set changeCounter 0
        } {
            |<--
            <table class="pretty" width="100%" cellpadding="5" cellspacing="0">
            <tr class="header">
            <th align="left" width="10%">Status</th>
            <th align="left" width="70%">Nature of Change</th>
            <th align="left" width="10%">Date</th>
            <th align="left" width="10%">Initiator</th>
            </tr>
        }

        $macro proc /changelog {} { return "</table><p>" }

        $macro proc change {date status initiator} {
            macro cpush change
            macro cset date      [nbsp $date]
            macro cset status    [nbsp $status]
            macro cset initiator [nbsp $initiator]
        }

        $macro template /change {} {
            variable changeCounter

            if {[incr changeCounter] % 2 == 0} {
                set rowclass evenrow
            } else {
                set rowclass oddrow
            }

            set date        [macro cget date]
            set status      [macro cget status]
            set initiator   [macro cget initiator]

            set description [macro cpop change]
        } {
            |<--
            <tr class="$rowclass" valign=top>
            <td>$status</td>
            <td>$description</td>
            <td>$date</td>
            <td>$initiator</td>
            </tr>
        }

        # NEXT,  Define Procedure Macros

        $macro template procedure {} {
            variable procedureCounter
            set procedureCounter 0
        } {
            |<--
            <table border="1" cellspacing="0" cellpadding="2">
        }

        $macro template step {} {
            variable procedureCounter
            incr procedureCounter
        } {
            |<--
            <tr valign="top">
            <td><b>$procedureCounter.</b></td>
            <td>
        }

        $macro proc /step/     {} { return "</td><td>"  }
        $macro proc /step      {} { return "</td></tr>" }
        $macro proc /procedure {} { return "</table>"   }
    }

    #-------------------------------------------------------------------
    # Man Page Access
    #
    # Man pages are accessed as "[<root>:]<name>(<section>)"
    # If no <root> is specified, then the default root, "", is used.
    # If no manroot command is called, then man page references are
    # not looked up.

    # manroots roots
    #
    # roots    A list of man page root names and URL patterns.
    #
    # Adds the roots to the set of manpage roots.  Each root is
    # specified as follows:
    #
    #    [<root>]:[<section>] <pattern>
    #
    # The pattern is a URL into which the following substitutions 
    # can be made:
    #
    #    %s   The section, e.g., "n"
    #    %n   The man page name, e.g., "ehtml".
    #
    # If <root> is omitted, then the patternUrl is for the default root,
    # i.e., for man page references in which no root is specified.
    #
    # If <section> is omitted, then the pattern is for any section.
    #
    # TODO: Make this an option

    typemethod manroots {roots} {
        foreach {spec pattern} $roots {
            if {![string match "*:*" $spec]} {
                error "Invalid root specification: \"$spec\""
            }

            lassign [split $spec :] root section

            set manroots($root:$section) $pattern
        }
    }

    #-------------------------------------------------------------------
    # Macro Definition Helpers
    

    # HtmlTag macro tag
    #
    # macro     - The macro processor
    # tag       - An html tag name, e.g,. "p"
    # closetag  - The matching close tag, or ""
    #
    # Translates the tag macro back to the equivalent HTMl tag.

    proc HtmlTag {macro tag {closetag ""}} {
        $macro proc $tag {} [format { 
            return "<%s>" 
        } $tag]

        if {$closetag ne ""} {
            $macro proc $closetag {} [format { 
                return "<%s>" 
            } $closetag]
        }
    }

    # StyleMacro macro tag
    #
    # macro - The macro processor
    # tag   - A tag: i, b, pre, etc.
    #
    # Defines a style macro, e.g., <i>...</i> or <i ...>.

    proc StyleMacro {macro tag} {
        $macro proc $tag {args} [format {
            if {[llength $args] == 0} {
                return "<%s>"
            } else {
                return "<%s>$args</%s>"
            }
        } $tag $tag $tag]

        $macro proc /$tag {} [format { 
            return "</%s>" 
        } $tag]
    }

}
