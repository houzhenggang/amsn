###
###
################################################################
###                                              ###############
###        Alvaro's Messenger - amsn             ###############
###                                              ###############
###       http://amsn.sourceforge.net            ###############
###     amsn-users@lists.sourceforge.net         ###############
###                                              ###############
################################################################
### airadier at users.sourceforge.net (airadier) ###############
### Universidad de Zaragoza                      ###############
### http://aim.homelinux.com                     ###############
################################################################
### grimaldo@panama.iaehv.nl (LordOfScripts)     ###############
### http://www.coralys.com/linux/                ###############
################################################################
### Original ccmsn                               ###############
### http://msn.CompuCreations.com/               ###############
### Dave Mifsud <dave at CompuCreations dot com> ###############
################################################################
###
###
### This program is free software; you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation; version 2 of the License
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###
### You should have received a copy of the GNU General Public License
### along with this program; if not, write to the Free Software
### Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
###
###

############################################################
### Some global variables
############################################################
set version "0.81pre1"
set date "29/6/2003"
set weburl "http://amsn.sourceforge.net"
set program_dir ""
set HOME ""
set files_dir ""
set skin "default"

#=======================================================================


############################################################
### Look if we are launched from a link
### and set the correct working dir
############################################################

if {[catch {file readlink [info script]} res]!=0} {

   #Error in readlink, so it's not a symbolic link
   set program_dir [file dirname [info script]]

} else {

   #Recursively update $resdir until it's not a link
   set program_dir [file dirname $res]

   while {[catch {file readlink $res} res2]==0} {
      set res $res2

      #Update $program_dir, depending on absolute or relative path
      if { [string range $res2 0 0]=="/" } {
         set program_dir [file dirname $res2]
      } else {
         set program_dir [file join $resdir [file dirname $res2]]
      }

   }
}


############################################################
### And setup where to find optional packages
############################################################

lappend auto_path "[file join $program_dir plugins]"
lappend auto_path "[file join ${HOME} plugins]"


############################################################
### Configure images and sounds folder
############################################################

set images_folder "[file join $program_dir skins $skin pixmaps]"
set smileys_folder "[file join $program_dir skins $skin smileys]"
set sounds_folder "[file join $program_dir skins $skin sounds]"


############################################################
### Setup other important directory paths
### depending on the platform
############################################################

if {$tcl_platform(platform) == "unix"} {
   set HOME "[file join $env(HOME) .amsn]"
   set files_dir "[file join $env(HOME) amsn_received]"
} elseif {$tcl_platform(platform) == "windows"} {
  if {[info exists env(USERPROFILE)]} {
     set HOME "[file join $env(USERPROFILE) amsn]"
     set files_dir "[file join $env(USERPROFILE) amsn_received]"
  } else {
   set HOME "[file join ${program_dir} amsn_config]"
   set files_dir "[file join ${program_dir} amsn_received]"
  }
} else {
   set HOME "[file join ${program_dir} amsn_config]"
   set files_dir "[file join ${program_dir} amsn_received]"
}


#TODO: Move this from here ??
#///////////////////////////////////////////////////////////////////////
#Notebook Pages (Buddies,News,Calendar,etc.)
set pgBuddy ""
set pgNews  ""
#///////////////////////////////////////////////////////////////////////


set initialize_amsn 1
set directory $program_dir

############################################################
#### Load program modules
############################################################
source [file join $directory ctthemes.tcl]
source [file join $directory notebook.tcl]	;# Notebook Megawidget
#source [file join $directory notebook1.tcl]	;# Notebook Megawidget
source [file join $directory rnotebook.tcl]	;# Notebook Megawidget
source [file join $directory progressbar.tcl]	;# Progressbar Megawidget
source [file join $directory dkffont.tcl]	;# Font selection megawidget
source [file join $directory migmd5.tcl]
source [file join $directory des.tcl]		;# DES encryption
source [file join $directory sxml.tcl]   	;# Simple XML parser
source [file join $directory config.tcl]
source [file join $directory proxy.tcl]
source [file join $directory protocol.tcl]
source [file join $directory ctadverts.tcl]
source [file join $directory lang.tcl]
source [file join $directory ctdegt.tcl]
source [file join $directory hotmail.tcl]
source [file join $directory smileys.tcl]
source [file join $directory groups.tcl]	;# Handle buddy groups
source [file join $directory abook.tcl]	;# Handle buddy address book
source [file join $directory anigif.tcl]	;# Animated GIFS
source [file join $directory gui.tcl]
source [file join $directory alarm.tcl]	;# Alarms code (Burger)
source [file join $directory dock.tcl]	;# Docking routines
source [file join $directory trayicon.tcl]	;# Docking routines for freedesktop system tray compliant docks
source [file join $directory loging.tcl]	;# Euh yeh it's for loging :P
source [file join $directory combobox.tcl]	;# The all mighty combobox is here! (B. Oakley)
source [file join $directory blocking.tcl]    ;# The blocking users feature
source [file join $directory remote.tcl  ]    ;# The remote control procedures
source [file join $directory automsg.tcl]
source [file join $directory plugins.tcl]	;# Plugins system
source [file join $directory balloon.tcl]       ;# For the balloons tooltip



#///////////////////////////////////////////////////////////////////////

###############################################################
create_dir $HOME
create_dir $HOME/plugins
#create_dir $log_dir
#create_dir $files_dir
ConfigDefaults

set config(language) en  ;#Load english as default language to fill trans array
load_lang

;# Load of logins/profiles in combobox
;# Also sets the newest login as config(login)
;# and modifies HOME with the newest user
if { [LoadLoginList]==-1 } {
   exit
}

#create_dir $HOME
set log_dir "[file join ${HOME} logs]"
#create_dir $log_dir

load_config		;# So this loads the config of this newest dude
scan_languages
load_lang

sb set ns name ns
sb set ns sock ""
sb set ns data [list]
sb set ns serv [split $config(start_ns_server) ":"]
sb set ns stat "d"

set family [lindex $config(basefont) 0]
set size [lindex $config(basefont) 1]

::themes::Init
degt_Init
::amsn::initLook $family $size $config(backgroundcolor)


if { $config(encoding) != "auto" } {
  set_encoding $config(encoding)
}

if { $config(receiveddir) != "" } {
   set res [create_dir $config(receiveddir)]
   if { $res >= 0} {
      set files_dir $config(receiveddir)
   } else {
      create_dir $files_dir
   }
}

cmsn_draw_main

bind all <KeyPress> "set idletime 0"

idleCheck

degt_protocol_win
degt_ns_command_win

after 500 proc_ns
after 750 proc_sb

if {$version != $config(last_client_version)} {
   ::amsn::aboutWindow

}

if { $config(autoconnect) == 1 } {
  ::MSN::connect $config(login) password
}

# BeginVerifyBlocked
init_remote_DS
init_dock
