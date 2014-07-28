#-----------------------------------------------------------------------
# TITLE:
#   buildtool.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Kite "build" tool.  By default, this builds all of the build 
#   targets: The app or appkit (if any), teapot packages, docs, and
#   other build targets specified in project.kite.
#
#   TODO: When we actually have more than one kind of build product,
#   add arguments so that the user can selectively build just one thing.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Registration

set ::ktools(build) {
    arglist     {}
    package     kiteapp
    ensemble    ::kiteapp::buildtool
    description "Build the entire project."
    intree      yes
}

set ::khelp(build) {
    The "build" tool builds all build targets specified in the
    project's project.kite file.  In particular:

    * Libs will be built as .kite/libzips/package-<name>*.zip.
    * Apps will be built as bin/<name>[.exe]
    * Appkits will be built as bin/<name>.kit

    Build also builds the man pages and documentation.
}

#-----------------------------------------------------------------------
# buildtool ensemble

snit::type ::kiteapp::buildtool {
    # Make it a singleton
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Execution 

    # execute argv
    #
    # Executes the tool given the command line arguments.

    typemethod execute {argv} {
        checkargs build 0 0 {} $argv

        # FIRST, check for dependencies.
        if {![includer uptodate] || ![teacup uptodate]} {
            puts "WARNING: Some dependencies are not up-to-date."
            puts "Run \"kite deps\" for details."
            puts ""
        }

        # TODO: Build make targets

        # NEXT, Build teapot packages.
        foreach lib [project lib names] {
            BuildTeapotZip $lib
        }

        # NEXT, build the app

        if {[project app name] ne ""} {
            set exe [project app get exe]

            switch -exact $exe {
                pack    { BuildAppPack [project app name] }
                kit     { BuildAppKit  [project app name] }
                default { error "Unknown application type: \"$exe\"" }
            }
        }

        # NEXT, build documentation
        docs manpages
        docs kitedocs
    }
    

    #-------------------------------------------------------------------
    # Building Apps

    # BuildAppKit name
    #
    # name   - The name of an appkit
    #
    # Builds the appkit if possible.  An appkit is a starkit that
    # includes $root/bin/$name.tcl (the main script) and the entire
    # lib/ tree (if any).
    #
    # It is assumed that TclDevKit is installed and accessible, and
    # that kite.kit is using the same tclsh as is being used in 
    # development.

    proc BuildAppKit {name} {
        # FIRST, do we have the main script
        set main [project app loader]

        if {![file exists $main]} {
            throw fatal \
                "Cannot build appkit '$name'; the 'bin/$name.tcl script is missing."
        }

        # NEXT, erase the existing kit, if any
        set kit [project root bin $name.kit]

        if {[file exists $kit]} {
            vputs "Deleting old $name.kit"
            catch {file delete -force $kit}
        }

        # NEXT, begin to build up the command.
        set command [TclAppCommand $kit]

        # NEXT, prepare to write logfile.
        set logfile [project root .kite build_$name.log]
        file mkdir [file dirname $logfile]

        lappend command \
            >&  $logfile

        # NEXT, Build the appkit

        puts "Building $name.kit as '$kit'"
        puts "See $logfile for details.\n"

        try {
            eval exec $command
        } on error {result} {
            throw FATAL "Error building $name.kit; see $logfile:\n$result"
        }
    }

    # BuildAppPack name
    #
    # name   - The name of an app
    #
    # Builds the app if possible.  An app is a starpack that
    # includes $root/bin/$name.tcl (the main script) and the entire
    # lib/ tree (if any), plus includes and requires.
    #
    # It is assumed that TclDevKit is installed and accessible, and
    # that kite.kit is using the same tclsh as is being used in 
    # development.

    proc BuildAppPack {name} {
        # FIRST, do we have the main script
        set main [project app loader]

        if {![file exists $main]} {
            throw fatal \
                "Cannot build app '$name'; the 'bin/$name.tcl script is missing."
        }

        # NEXT, get the executable name.
        set exefile [project app name]

        if {$::tcl_platform(platform) eq "windows"} {
            append exefile .exe
        } 
        set exe [project root bin $exefile]

        # NEXT, get the basekit name.
        set basekit [FindBaseKit [project app get gui]]

        # NEXT, begin to build up the command.
        set command [TclAppCommand $exe $basekit]

        # NEXT, prepare to write logfile.
        set logfile [project root .kite build_$name.log]
        file mkdir [file dirname $logfile]

        lappend command \
            >&  $logfile

        # NEXT, erase the existing exe file, if any

        if {[file exists $exe]} {
            vputs "Deleting old $exefile"
            catch {file delete -force $exe}
        }

        # NEXT, Build the app

        puts "Building $exefile as '$exe'"
        puts "See $logfile for details.\n"

        try {
            eval exec $command
        } on error {result} {
            throw FATAL "Error building $exefile; see $logfile:\n$result"
        }
    }

    # TclAppCommand target ?basekit?
    #
    # target   - The name of the output file.
    # basekit  - The name of the basekit, or ""
    #
    # Returns the base tclapp command for building apps and app kits.

    proc TclAppCommand {target {basekit ""}} {
        lappend command                 \
            -ignorestderr --            \
            tclapp [project app loader] \
            [project root lib * *]

        # NEXT, include library subdirectories, if any.
        if {[llength [glob -nocomplain [project root lib * * *]]] > 0} {
            lappend command [project root lib * * *]
        }

        # NEXT, do we have any includes?
        foreach iname [project include names] {
            set ilib [project root includes $iname lib]

            if {[llength [glob -nocomplain [file join $ilib *]]] > 0} {
                lappend command [file join $ilib * *]
            }

            # NEXT, include library subdirectories, if any.
            if {[llength [glob -nocomplain [file join $ilib * * *]]] > 0} {
                lappend command [file join $ilib * * *]
            }
        }

        # NEXT, add the basekit, if any.
        if {$basekit ne ""} {
            lappend command \
                -basekit $basekit
        }

        # NEXT, other standard arguments.
        lappend command \
            -out     $target          \
            -archive [project teapot]

        # NEXT, add "require" dependencies
        foreach rqmt [project require names] {
            set pkgref "$rqmt [project require version $rqmt]"
            lappend command \
                -pkgref $pkgref
        }

        return $command
    }

    #-------------------------------------------------------------------
    # Building Teapot .zip files

    # BuildTeapotZip lib
    #
    # lib   - A "lib" from project.kite
    #
    # Builds a .zip package for the lib.
    #
    # TODO: This supports only pure-Tcl libs at the moment.

    proc BuildTeapotZip {lib} {
        # FIRST, make sure the library package exists.
        puts "Building teapot package: $lib [project version]"
        set libdir [project root lib $lib]
        if {![file isdirectory $libdir]} {
            puts [outdent "
                WARNING: Kite could not build a teapot .zip file for
                library \"$lib\", because the library package was not
                not found at $libdir.
            "]
            return
        }

        # NEXT, create its teapot.txt file
        set contents "Package $lib [project version]\n"                         \

        append contents \
            "Meta description [project name]: [project description]\n" \
            "Meta entrykeep\n"                                         \
            "Meta included *\n"                                        \
            "Meta platform tcl\n"

        set reqs [project lib get $lib requires]
        if {$reqs eq "*"} {
            set reqs [project require names]
        }

        foreach req $reqs {
            set ver [project require version $req]
            append contents "Meta require {$req $ver}\n"
        }

        writefile [project root lib $lib teapot.txt] $contents

        # NEXT, prepare the build command.
        set zipdir [project zippath]
        lappend command \
            teapot-pkg generate -t zip -o $zipdir $libdir \

        # NEXT, prepare to write logfile.
        set logfile [project root .kite build_lib_$lib.log]
        file mkdir [file dirname $logfile]

        lappend command \
            >&  $logfile

        puts "Building lib $lib"
        puts "See $logfile for details.\n"

        try {
            eval exec $command
        } on error {result} {
            throw FATAL "Error building lib $lib; see $logfile:\n$result"
        }
    }
    

    #-------------------------------------------------------------------
    # Helpers

    # GetTeapotDir
    #
    # For ActiveTcl, the default teapot is in $TCL_HOME/lib/teapot.
    #
    # TODO: Kite should have its own local teapot on the machine.
    # TODO: This routine assumes the default teapot location for
    # Windows only.

    proc GetTeapotDir {} {
        set shell [info nameofexecutable]
        set tclhome [file dirname [file dirname $shell]]
        set teacup [file join $tclhome bin teacup]

        # Assume the default teacup repository
        set result [exec $teacup default]
        return [string trim $result]
    }

    # FindBaseKit gflag
    #
    # gflag  - If 1, we need a Tk base-kit.
    #
    # Finds the basekit executable, based on the platform.

    proc FindBaseKit {gflag} {
        # FIRST, determine the base-kit pattern.
        set tv [info tclversion]

        if {$gflag} {
            set prefix "base-tk${tv}-thread*"
        } else {
            set prefix "base-tcl${tv}-thread*"
        }

        if {$::tcl_platform(platform) eq "windows"} {
            set basedir [file dirname [info nameofexecutable]]
            set pattern [file join $basedir $prefix].exe
        } elseif {$::tcl_platform(os) eq "Darwin"} {
            # OS X
            set basedir "/Library/Tcl/basekits"
            set pattern [file join $basedir $prefix]
        } else {
            # Linux -- Tentative!
            set basedir [file dirname [info nameofexecutable]]
            set pattern [file join $basedir $prefix]
        }

        set allfiles [glob -nocomplain $pattern]

        # NEXT, strip out library files
        foreach file $allfiles {
            if {[file extension $file] in {.dll .dylib .so}} {
                continue
            }

            return $file
        }

        throw FATAL "Could not find basekit."
    }
    
}




