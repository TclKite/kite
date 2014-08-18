#-----------------------------------------------------------------------
# TITLE:
#   runtool.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Kite "run" tool.  By default, this invokes the app/appkit's 
#   loader script.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Registration

set ::ktools(run) {
    usage       {0 - "?<arg>...?"}
    ensemble    runtool
    description "Run application"
    intree      yes
}

set ::khelp(run) {
    If the project defines one or more applications, the 'kite run' tool
    invokes the project's primary application, i.e., it invokes
    the ./bin/myapp.tcl file and passes it any command line
    arguments.

    To execute an arbitrary script in the context of the project's code
    base, pass the script name to Kite as the first argument on the
    command line:

        $ kite myscript.tcl arg1 arg2 arg3

    'kite run' is thus a convenient shorthand for 

        $ cd <root>
        $ kite ./bin/myapp.tcl ...
}

#-----------------------------------------------------------------------
# runtool ensemble

snit::type runtool {
    # Make it a singleton
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Execution 

    # execute argv
    #
    # Executes the tool given the command line arguments, which are
    # passed along to the user's application.

    typemethod execute {argv} {
        # FIRST, is there an app/appkit?
        if {![project hasapp]} {
            throw FATAL "The project.kite file doesn't define an application."
        }

        # NEXT, set up the library path.
        set ::env(TCLLIBPATH) [project libpath]

        # NEXT, set up the rest of command.
        lappend command \
            tclsh [project app loader [project app primary]] \
                {*}$argv >@ stdout 2>@ stderr

        # NEXT, execute it in the project root, in the background,
        # and exit.
        vputs "Executing <$command>"
        
        cd [project root]
        eval exec $command
    }    
}






