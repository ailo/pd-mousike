
####### scrollboxwindow -- scrollbox window with default bindings #########
## This is the base dialog behind the Path and Startup dialogs
## This namespace specifies everything the two dialogs have in common,
## with arguments specifying the differences
##
## By default, this creates a dialog centered on the viewing area of the screen
## with cancel, apply, and OK buttons
## which contains a scrollbox widget populated with the given data

package provide scrollboxwindow 0.1

package require scrollbox

namespace eval scrollboxwindow {
}


proc ::scrollboxwindow::get_listdata {mytoplevel} {
    return [$mytoplevel.listbox.box get 0 end]
}

proc ::scrollboxwindow::do_apply {mytoplevel commit_method listdata} {
    $commit_method [pdtk_encode $listdata]
    pdsend "pd save-preferences"
}

# Cancel button action
proc ::scrollboxwindow::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

# Apply button action
proc ::scrollboxwindow::apply {mytoplevel commit_method } {
    do_apply $mytoplevel $commit_method [get_listdata $mytoplevel]
}

# OK button action
# The "commit" action can take a second or more,
# long enough to be noticeable, so we only write
# the changes after closing the dialog
proc ::scrollboxwindow::ok {mytoplevel commit_method } {
    set listdata [get_listdata $mytoplevel]
    cancel $mytoplevel
    do_apply $mytoplevel $commit_method $listdata
}

proc ::scrollboxwindow::reset_to_defaults {mytoplevel} {
    switch -- $::windowingsystem {
        "x11" {
            set preffile "$::env(HOME)/.pdextended"
            if {[file exists $preffile]} {
                pdwindow::debug "Deleting preferences file: $preffile\n"
                file delete -- $preffile
            }
        }
        "aqua" {
            set preffile "$::env(HOME)/Library/Preferences/org.puredata.pdextended.plist"
            if {[file exists $preffile]} {
                pdwindow::debug "Deleting preferences file: $preffile\n"
                file delete -- $preffile
            }
        }
        "win32" {
            pdwindow::debug "Deleting preferences in HKEY_CURRENT_USER\\Software\\Pd-extended\n"
            registry delete "HKEY_CURRENT_USER\\Software\\Pd-extended"
        }
    }
    set ::startup_flags ""
    pdsend "pd startup-flags [pdtk_encodedialog $::startup_flags]"
    pdsend "pd path-dialog 1 0"
    pdsend "pd load-preferences"
    ::scrollboxwindow::cancel $mytoplevel
    destroy $mytoplevel
}

# "Constructor" function for building the window
# id -- the window id to use
# listdata -- the data used to populate the scrollbox
# add_method -- a reference to a proc to be called when the user adds a new item
# edit_method -- same as above, for editing and existing item
# commit_method -- same as above, to commit during the "apply" action
# title -- top-level title for the dialog
# width, height -- initial width and height dimensions for the window, also minimum size
proc ::scrollboxwindow::make {mytoplevel listdata add_method edit_method commit_method title width height } {
    wm deiconify .pdwindow
    raise .pdwindow
    toplevel $mytoplevel -class DialogWindow
    wm title $mytoplevel $title
    wm group $mytoplevel .
    wm transient $mytoplevel .pdwindow
    wm protocol $mytoplevel WM_DELETE_WINDOW "::scrollboxwindow::cancel $mytoplevel"

    # Enforce a minimum size for the window
    wm minsize $mytoplevel $width $height

    # Set the current dimensions of the window
    wm geometry $mytoplevel "${width}x${height}"

    # Add the scrollbox widget
    ::scrollbox::make $mytoplevel $listdata $add_method $edit_method

    # Use two frames for the buttons, since we want them both
    # bottom and right
    frame $mytoplevel.nb
    pack $mytoplevel.nb -side bottom -fill x -pady 2m

    button $mytoplevel.nb.saveall -text [_ "Reset to Defaults"] \
        -command "::scrollboxwindow::reset_to_defaults $mytoplevel"
    pack $mytoplevel.nb.saveall -side left -padx 2m

    frame $mytoplevel.nb.buttonframe
    pack $mytoplevel.nb.buttonframe -side right -padx 2m

    button $mytoplevel.nb.buttonframe.cancel -text [_ "Cancel"]\
        -command "::scrollboxwindow::cancel $mytoplevel"
    button $mytoplevel.nb.buttonframe.apply -text [_ "Apply"]\
        -command "::scrollboxwindow::apply $mytoplevel $commit_method"
    button $mytoplevel.nb.buttonframe.ok -text [_ "OK"]\
        -command "::scrollboxwindow::ok $mytoplevel $commit_method"

    pack $mytoplevel.nb.buttonframe.cancel -side left -expand 1 -padx 2m
    pack $mytoplevel.nb.buttonframe.apply -side left -expand 1 -padx 2m
    pack $mytoplevel.nb.buttonframe.ok -side left -expand 1 -padx 2m
}


