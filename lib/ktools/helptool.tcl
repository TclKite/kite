#-----------------------------------------------------------------------
# TITLE:
#   helptool.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Kite: "help" tool
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Registration

set ::ktools(help) {
    arglist     {}
    package     ktools
    ensemble    ::ktools::helptool
    description "Display this help, or help for a given tool."
}

#-----------------------------------------------------------------------
# tool::help ensemble

snit::type ::ktools::helptool {
    # Make it a singleton
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Type variables

    # TBD

    #-------------------------------------------------------------------
    # Execution

    # execute ?args?
    #
    # Displays the Kite help.
    #
    # TODO: provide help for individual tools.

    typemethod execute {argv} {
        puts "Kite is a tool for working with Tcl projects.\n"

        puts "Several tools are available:\n"

        foreach tool [lsort [array names ::ktools]] {
            array set tdata $::ktools($tool)

            puts [format "%-10s - %s" $tool $tdata(description)]
        }
        puts ""
    }    
}



