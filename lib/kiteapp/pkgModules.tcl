#-----------------------------------------------------------------------
# TITLE:
#    pkgModules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Kite: utility code used by kite.kit.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Package Definition

# -kite-provide-start  DO NOT EDIT THIS BLOCK BY HAND
package provide kiteapp 0.1.4a0
# -kite-provide-end

#-----------------------------------------------------------------------
# Required Packages

# -kite-require-start ADD EXTERNAL DEPENDENCIES
package require snit 2.3
package require platform 1.0
package require zipfile::encode 0.3
package require -exact kiteutils 0.1.4a0
package require -exact kitedocs 0.1.4a0
# -kite-require-end


#-----------------------------------------------------------------------
# Namespace definition

namespace eval ::kiteapp:: {
    variable library [file dirname [info script]]
}

namespace import kiteutils::*


#-----------------------------------------------------------------------
# Submodules
#
# Note: modules are listed in order of dependencies; be careful if you
# change the order!

source [file join $::kiteapp::library main.tcl            ]
source [file join $::kiteapp::library misc.tcl            ]
source [file join $::kiteapp::library plat.tcl            ]
source [file join $::kiteapp::library project.tcl         ]
source [file join $::kiteapp::library subtree.tcl         ]
source [file join $::kiteapp::library subtree_kiteinfo.tcl]
source [file join $::kiteapp::library subtree_proj.tcl    ]
source [file join $::kiteapp::library subtree_app.tcl     ]
source [file join $::kiteapp::library subtree_pkg.tcl     ]
source [file join $::kiteapp::library trees.tcl           ]
source [file join $::kiteapp::library teacup.tcl          ]
source [file join $::kiteapp::library teapot.tcl          ]
source [file join $::kiteapp::library docs.tcl            ]
source [file join $::kiteapp::library addtool.tcl         ]
source [file join $::kiteapp::library buildtool.tcl       ]
source [file join $::kiteapp::library cleantool.tcl       ]
source [file join $::kiteapp::library compiletool.tcl     ]
source [file join $::kiteapp::library depstool.tcl        ]
source [file join $::kiteapp::library disttool.tcl        ]
source [file join $::kiteapp::library docstool.tcl        ]
source [file join $::kiteapp::library helptool.tcl        ]
source [file join $::kiteapp::library infotool.tcl        ]
source [file join $::kiteapp::library installtool.tcl     ]
source [file join $::kiteapp::library newtool.tcl         ]
source [file join $::kiteapp::library runtool.tcl         ]
source [file join $::kiteapp::library shelltool.tcl       ]
source [file join $::kiteapp::library replacetool.tcl     ]
source [file join $::kiteapp::library teapottool.tcl      ]
source [file join $::kiteapp::library testtool.tcl        ]
source [file join $::kiteapp::library versiontool.tcl     ]




