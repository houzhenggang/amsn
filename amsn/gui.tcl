#Default look


set bgcolor #0050C0
set bgcolor2 #D0D0F0


namespace eval ::amsn {

   namespace export fileTransferRecv fileTransferProgress \
   errorMsg notifyAdd initLook messageFrom chatChange userJoins\
   userLeaves updateTypers ackMessage nackMessage closeWindow \
   chatStatus chatUser

   ##PUBLIC

   proc initLook { family size bgcolor} {

      font create menufont -family $family -size $size -weight normal
      font create sboldf -family $family -size $size -weight bold
      font create splainf -family $family -size $size -weight normal
      font create bboldf -family $family -size [expr {$size+1}] -weight bold
      font create bplainf -family $family -size [expr {$size+1}] -weight normal
      font create bigfont -family $family -size [expr {$size+2}] -weight bold
      font create examplef -family $family -size [expr {$size-2}] -weight normal

      tk_setPalette $bgcolor
      option add *Menu.font menufont
      option add *background $bgcolor
      option add *selectColor #DD0000

      set Entry {-bg #FFFFFF -foreground #0000FF}
      set Label {-bg #FFFFFF -foreground #000000}
      ::themes::AddClass Amsn Entry $Entry 90
      ::themes::AddClass Amsn Label $Label 90
      ::abookGui::Init
   }


   #///////////////////////////////////////////////////////////////////////////////
   # Draws the about window
   proc aboutWindow {} {

      global program_dir

      toplevel .about
      wm title .about "[trans about] [trans title]"
      wm transient .about .
      wm state .about withdrawn
      grab .about

      set developers "\nDidimo Grimaldo\nAlvaro J. Iradier\nKhalaf Philippe\nDave Mifsud"
      frame .about.top -class Amsn
      label .about.top.i -image msndroid
      label .about.top.l -font splainf -text "[trans broughtby]:$developers"
      pack .about.top.i .about.top.l -side left
      pack .about.top

      text .about.info -background white -width 60 -height 30 -wrap word \
         -yscrollcommand ".about.ys set" -font   examplef
      scrollbar .about.ys -command ".about.info yview"
      pack .about.ys -side right -fill y
      pack .about.info -expand true -fill both

      frame .about.bottom -class Amsn
      button .about.bottom.close -text "[trans close]" -font splainf -command "destroy .about"
      pack .about.bottom.close
      pack .about.bottom -expand 1

      set id [open "[file join $program_dir README]" r]
      .about.info insert 1.0 [read $id]

      close $id

      .about.info configure -state disabled
      update idletasks
      wm state .about normal
      set x [expr {([winfo vrootwidth .about] - [winfo width .about]) / 2}]
      set y [expr {([winfo vrootheight .about] - [winfo height .about]) / 2}]
      wm geometry .about +${x}+${y}

   }
   #///////////////////////////////////////////////////////////////////////////////

   #///////////////////////////////////////////////////////////////////////////////
   # showHelpFile(filename,windowsTitle)
   proc showHelpFile {file title} {
      global program_dir
      toplevel .show
      wm title .show "$title"
      wm transient .show .

      text .show.info -background white -width 60 -height 30 -wrap word \
         -yscrollcommand ".show.ys set" -font   examplef
      scrollbar .show.ys -command ".show.info yview"
      pack .show.ys -side right -fill y
      pack .show.info -expand true -fill both
      set id [open "[file join $program_dir $file]" r]
      .show.info insert 1.0 [read $id]
      close $id
      .show.info configure -state disabled
      update idletasks
      set x [expr {([winfo vrootwidth .show] - [winfo width .show]) / 2}]
      set y [expr {([winfo vrootheight .show] - [winfo height .show]) / 2}]
      wm geometry .show +${x}+${y}

      frame .show.bottom -class Amsn
      button .show.bottom.close -text "[trans close]" -font splainf -command "destroy .show"
      pack .show.bottom.close
      pack .show.bottom -expand 1

      grab .show
   }
   #///////////////////////////////////////////////////////////////////////////////

   #///////////////////////////////////////////////////////////////////////////////
   # Shows the error message specified by "msg"
   proc errorMsg { msg } {
      tk_messageBox -type ok -icon error -message $msg -title "[trans title] Error"
   }
   #///////////////////////////////////////////////////////////////////////////////

   #///////////////////////////////////////////////////////////////////////////////
   # Shows the error message specified by "msg"
   proc infoMsg { msg } {
      tk_messageBox -type ok -icon info -message $msg -title "[trans title]"
   }
   #///////////////////////////////////////////////////////////////////////////////

   #///////////////////////////////////////////////////////////////////////////////
   proc blockUnblockUser { user_login } {
      global list_bl
      if { [::MSN::userIsBlocked $user_login] } {
         unblockUser $user_login
      } else {
         blockUser $user_login
      }
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   proc blockUser {user_login} {

       set answer [tk_messageBox -message "[trans confirm]" -type yesno -icon question -title [trans block] -parent [focus]]
       if {$answer == "yes"} {
          set name [::abook::getName ${user_login}]
          ::MSN::blockUser ${user_login} [urlencode $name]
       }
   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   proc deleteUser { user_login } {

      global alarms
      set answer [tk_messageBox -message "[trans confirmdelete ${user_login}]" -type yesno -icon question]

      if {$answer == "yes"} {

         ::MSN::deleteUser ${user_login}
         if { [info exists alarms($user_login)] } {
            unset alarms($user_login) alarms(${user_login}_sound) alarms(${user_login}_pic) \
               alarms(${user_login}_sound_st) alarms(${user_login}_pic_st) alarms(${user_login}_loop)
         }
      }
   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   proc unblockUser {user_login} {
      set name [::abook::getName ${user_login}]
      ::MSN::unblockUser ${user_login} [urlencode $name]
   }
   #///////////////////////////////////////////////////////////////////////////////

   #///////////////////////////////////////////////////////////////////////////////
   # FileTransferSend (chatid)
   # Shows the file transfer window, for window win_name
   proc FileTransferSend { win_name } {
      global config

      set ipaddr "[::MSN::getMyIP]"

      set w ${win_name}_sendfile
      toplevel $w
      wm group $w .
      wm title $w "[trans sendfile]"
      label $w.msg -justify center -text "[trans enterfilename]"
      pack $w.msg -side top -pady 5

      frame $w.buttons
      pack $w.buttons -side bottom -fill x -pady 2m
      button $w.buttons.dismiss -text [trans cancel] -command "destroy $w"
      button $w.buttons.save -text "[trans ok]" \
        -command "::amsn::FileTransferSendOk $w $win_name"
      pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

      frame $w.top

      frame $w.top.labels
      label $w.top.labels.file -text "[trans filename]:"
      label $w.top.labels.ip -text "[trans ipaddress]:"

      frame $w.top.fields
      entry $w.top.fields.file -width 40 -bg #FFFFFF
      entry $w.top.fields.ip -width 15 -bg #FFFFFF
      checkbutton $w.top.fields.autoip -text "[trans autoip]" -variable config(autoftip)

      pack $w.top.fields.file -side top -anchor w
      pack $w.top.fields.ip $w.top.fields.autoip -side left -anchor w -pady 5
      pack $w.top.labels.file $w.top.labels.ip -side top -anchor e
      pack $w.top.fields -side right -padx 5
      pack $w.top.labels -side left -padx 5
      pack $w.top -side top

      if {$config(autoftip)} {
        $w.top.fields.ip insert 0 "$ipaddr"
      } else {
        $w.top.fields.ip insert 0 "$config(myip)"
      }

      focus $w.top.fields.file

      fileDialog2 $w $w.top.fields.file open ""
   }

   #PRIVATE: called by the FileTransferSend Dialog
   proc FileTransferSendOk { w win_name } {
      global config

      set filename [ $w.top.fields.file get ]

      if {$config(autoftip) == 0 } {
        set config(myip) [ $w.top.fields.ip get ]
        set ipaddr [ $w.top.fields.ip get ]
      } else {
        set ipaddr [ ::MSN::getMyIP ]
      }


      destroy $w

      #Calculate a random cookie
      set cookie [expr {[clock clicks]  % (65536 * 8)}]

      status_log "Random generated cookie: $cookie\n"
      
      ::amsn::SendWin [file tail $filename] $cookie
      #TODO: We should get the chatid just at the beginning, and then go passing it as an argument,
      # so the file transfer won't give an error if the window is closed before clicking OK
      status_log "sending FT invitation to chatid [ChatFor $win_name] (win_name is $win_name)\n"
      ::MSN::inviteFT [ChatFor $win_name] $filename $cookie $ipaddr

      return 0
   }

   #Dialog shown when receiving a file
   proc fileTransferRecv {filename filesize cookie chatid fromlogin fromname} {
      global files_dir

      #Newer version

      set win_name [WindowFor $chatid]

      if { $win_name == 0 } {

         set win_name [OpenChatWindow]
	  SetWindowFor $chatid $win_name
         status_log "NEW - Window doesn't exists in fileTransferRecv, created window named [WindowFor $chatid]\n"
	  WinTopUpdate $chatid

      }

     ${win_name}.f.out.text configure -state normal -font bplainf -foreground black


     ${win_name}.f.out.text tag configure ftyes$cookie \
       -foreground #000080 -background white -font bboldf -underline false
     ${win_name}.f.out.text tag bind ftyes$cookie <Enter> \
       "${win_name}.f.out.text tag conf ftyes$cookie -underline true;\
       ${win_name}.f.out.text conf -cursor hand2"
     ${win_name}.f.out.text tag bind ftyes$cookie <Leave> \
       "${win_name}.f.out.text tag conf ftyes$cookie -underline false;\
       ${win_name}.f.out.text conf -cursor left_ptr"
     ${win_name}.f.out.text tag bind ftyes$cookie <Button1-ButtonRelease> \
       "::amsn::AcceptedFT $chatid $cookie; ::amsn::RecvWin {$filename} $cookie; ::MSN::acceptFT $chatid {$filename} $filesize $cookie"

     ${win_name}.f.out.text tag configure ftno$cookie \
       -foreground #000080 -background white -font bboldf -underline false
     ${win_name}.f.out.text tag bind ftno$cookie <Enter> \
       "${win_name}.f.out.text tag conf ftno$cookie -underline true;\
       ${win_name}.f.out.text conf -cursor hand2"
     ${win_name}.f.out.text tag bind ftno$cookie <Leave> \
       "${win_name}.f.out.text tag conf ftno$cookie -underline false;\
       ${win_name}.f.out.text conf -cursor left_ptr"
     ${win_name}.f.out.text tag bind ftno$cookie <Button1-ButtonRelease> \
       "::amsn::RejectedFT $chatid $cookie; ::MSN::rejectFT $chatid $cookie"

     set txt [trans acceptfile '$filename' $filesize $files_dir]

     #TODO: Use Winwrite, os similar, instead of doing it directly
     ${win_name}.f.out.text insert end "----------\n" gray
     ${win_name}.f.out.text image create end -image fticon -pady 2 -padx 3
     ${win_name}.f.out.text insert end "[timestamp] $fromname: $txt" gray
     ${win_name}.f.out.text insert end " - (" gray
     ${win_name}.f.out.text insert end "[trans accept]" ftyes$cookie
     ${win_name}.f.out.text insert end " / " gray
     ${win_name}.f.out.text insert end "[trans reject]" ftno$cookie
     ${win_name}.f.out.text insert end " )\n" gray
     ${win_name}.f.out.text insert end "----------\n" gray
     ${win_name}.f.out.text yview moveto 1.0
     ${win_name}.f.out.text configure -state disabled
     WinFlicker $chatid

      if { "[wm state ${win_name}]" == "withdrawn" } {
        wm state ${win_name} iconic
	::amsn::notifyAdd "[trans says $fromname]:\n$txt" \
	   "::amsn::chatUser $chatid"
	   #"wm state ${win_name} normal"
      }

      if { [string first ${win_name} [focus]] != 0 } {
        sonido type
      }


   }



   #///////////////////////////////////////////////////////////////////////////////
   # ChatFor (win_name)
   # Returns the name of the chat assigned to window 'win_name'
   proc ChatFor { win_name } {
         variable chat_ids
	  if { [info exists chat_ids($win_name)]} {
	     return $chat_ids($win_name)
	  }
	  return 0
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WindowFor (chatid)
   # Returns the name of the window that should show the messages and information
   # related to the chat 'chatid'
   proc WindowFor { chatid } {
         variable msg_windows
	  if { [info exists msg_windows($chatid)]} {
	     return $msg_windows($chatid)
	  }
	  return 0
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # SetWindowFor (chatid)
   # Sets the specified window 'win_name' to be the one which will show messages
   # and information for the chat names 'chatid'
   proc SetWindowFor { chatid win_name } {
      variable msg_windows
      variable chat_ids
      set msg_windows($chatid) $win_name
      set chat_ids($win_name) $chatid
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # UnserWindowFor (chatid,win_name)
   # Tells the GUI system that window 'win_name' is no longer available for 'chatid'
   proc UnsetWindowFor {chatid win_name} {
      variable msg_windows
      variable chat_ids
      if {[info exists msg_windows($chatid)]} {
         unset msg_windows($chatid)
         unset chat_ids($win_name)
      }
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # PUBLIC messageFrom(chatid,user,msg,type,[fontformat])
   # Called by the protocol layer when a message 'msg' arrives from the chat
   # 'chatid'.'user' is the login of the message sender, and 'user' can be "msg" to
   # send special messages not prefixed by "XXX says:". 'type' can be a style tag as
   # defined in the OpenChatWindow proc, or just "user". If the tpye is "user",
   # the 'fontformat' parameter will be used as font format.
   # The procedure will open a window if it does not exists, add a notifyWindow and
   # play a sound if it's necessary
   proc messageFrom { chatid user msg type {fontformat ""} } {

      set win_name [WindowFor $chatid]

      if { $win_name == 0 } {

         set win_name [OpenChatWindow]
	  SetWindowFor $chatid $win_name
	  WinTopUpdate $chatid

      }

      PutMessage $chatid $user $msg $type $fontformat

      #If window is withdran (Created but not visible) show notify, and change
      #the window state
      if { "[wm state $win_name]" == "withdrawn" } {

	 wm state ${win_name} normal
	 wm iconify ${win_name}

         notifyAdd "[trans says [lindex [::MSN::getUserInfo $user] 1]]:\n$msg" \
           "::amsn::chatUser $chatid"

      }

      #If window not focused, play "type" sound
      if { [string first ${win_name} [focus]] != 0 } {
         sonido type
      }

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WinTopUpdate { chatid }
   # Gets the users in 'chatid' from the protocol layer, and updates the top of the
   # window with the user names and states.
   proc WinTopUpdate { chatid } {

      if { [WindowFor $chatid] == 0 } {
         return 0
      }

      variable window_titles
      global list_states

      set topmsg ""
      set title ""

      set user_list [::MSN::usersInChat $chatid]

      if {[llength $user_list] == 0} {
         return 0
      }

      foreach user_login $user_list {

         #set user_name [lindex $user_info 1]
	 set user_name [lindex [::MSN::getUserInfo $user_login] 1]
	 set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]

	  if { "$user_state_no" == "" } {
	     set user_state_no 0
	  }

	  set user_state [lindex [lindex $list_states $user_state_no] 1]


	  set title "${title}${user_name}, "

 	  set topmsg "${topmsg}${user_name} <${user_login}> "

	  if { "$user_state" != "" && "$user_state" != "online" } {
            set topmsg "${topmsg} \([trans $user_state]\) "
	  }
	  set topmsg "${topmsg}\n"

      }

      set title [string replace $title end-1 end " - [trans chat]"]
      set topmsg [string replace $topmsg end-1 end]

      set win_name [WindowFor $chatid]

      ${win_name}.f.top.text configure -state normal -font sboldf -height 1 -wrap none
      ${win_name}.f.top.text delete 0.0 end
      ${win_name}.f.top.text insert end $topmsg
      
      #Calculate number of lines, and set top text size
      set size [${win_name}.f.top.text index end]
      set posyx [split $size "."]
      set lines [expr {[lindex $posyx 0] - 1}]
      ${win_name}.f.top.text configure -state normal -font sboldf -height $lines -wrap none

      ${win_name}.f.top.text configure -state disabled

      set window_titles(${win_name}) ${title}
      wm title ${win_name} ${title}


      after cancel "::amsn::WinTopUpdate $chatid"
      after 3000 "::amsn::WinTopUpdate $chatid"

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # chatChange (chatid, newchatid)
   # this is called from the protocol layer when a private chat changes into a
   # conference, right after a JOI command comes from the SB. It mean that the window
   # assigned to $chatid should now be related to $newchatid. chatChange will return
   # the new chatid if the change is OK (no other window for that name exists), or the
   # old chatid if the change is not right
   # - 'chatid' is the name of the chat that was a single private before
   # - 'newchatid' is the new id of the chat for the conference
   proc chatChange { chatid newchatid } {

      set win_name [WindowFor $chatid]

      if { $win_name == 0 } {

          #Old window window does not exists, so just accept the change, no worries
	  status_log "chatChange: Window doesn't exist (probably invited to a conference)\n"
	  return $newchatid

      }

      if { [WindowFor $newchatid] != 0} {
         #Old window existed, probably a conference, but new one exists too, so we can't
	 #just allow that messages shown in old window now are shown in a different window,
	 #that wouldn't be nice, so don't allow change
         status_log "conference wants to become private, but there's already a window\n"
	 return $chatid
      }
      
      #So, we had an old window for chatid, but no window for newchatid, so the window will
      #change it's assigned chat

      UnsetWindowFor $chatid $win_name
      SetWindowFor $newchatid $win_name

      status_log "chatChange: changing $chatid into $newchatid\n"

      return $newchatid

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # userJoins (charid, user_name)
   # called from the protocol layer when a user JOINS a chat
   # It should be called after a JOI in the switchboard.
   # If a window exists, it will show "user joins conversation" in the status bar
   # - 'chatid' is the chat name
   # - 'usr_name' is the user email to show in the status message
   proc userJoins { chatid usr_name } {

	global config

      if {[WindowFor $chatid] == 0} {
         return 0
      }

      set statusmsg "[timestamp] [trans joins $usr_name]\n"
      WinStatus [ WindowFor $chatid ] $statusmsg
      WinTopUpdate $chatid

	if { $config(keep_logs) } {
		::log::JoinsConf $chatid $usr_name
	}

   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   # userLeaves (chatid, user_name)
   # called from the protocol layer when a user LEAVES a chat.
   # It will show the status message. No need to show it if the window is already
   # closed, right?
   # - 'chatid' is the chat name
   # - 'usr_name' is the user email to show in the status message
   proc userLeaves { chatid usr_name } {

      global config

      if {[WindowFor $chatid] == 0} {
         return 0
      }

      set statusmsg "[timestamp] [trans leaves $usr_name]\n"
      WinStatus [ WindowFor $chatid ] $statusmsg
      WinTopUpdate $chatid

	if { $config(keep_logs) } {
		::log::LeavesConf $chatid $usr_name
	}

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # updateTypers (chatid)
   # Called from the protocol.
   # Asks the protocol layer to get a list of typing users in the chat, and shows
   # a message in the status bar.
   # - 'chatid' is the name of the chat
   proc updateTypers { chatid } {


      if {[WindowFor $chatid] == 0} {
         return 0
      }

      set typers_list [::MSN::typersInChat $chatid]

      set typingusers ""

      foreach login $typers_list {
         set user_name [lindex [::MSN::getUserInfo $login] 1]
         set typingusers "${typingusers}${user_name}, "
      }

      set typingusers [string replace $typingusers end-1 end ""]

      set statusmsg ""
      set icon ""

      if {[llength $typers_list] == 0} {

         set lasttime [::MSN::lastMessageTime $chatid]
         if { $lasttime != 0 } {
	     set statusmsg "[trans lastmsgtime $lasttime]"
         }

      } elseif {[llength $typers_list] == 1} {

         set statusmsg " [trans istyping $typingusers]."
	 set icon typingimg

      } else {

         set statusmsg " [trans aretyping $typingusers]."
	 set icon typingimg

      }

      WinStatus [WindowFor $chatid] $statusmsg $icon

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # Auto incremented variable to name the windows
   variable winid 0
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # OpenChatWindow ()
   # Opens a new hidden chat window and returns its name.
   proc OpenChatWindow {} {

      variable winid
      variable window_titles
      global images_folder config HOME files_dir bgcolor bgcolor2

      set win_name "msg_$winid"
      incr winid

      toplevel .${win_name}
      
      wm geometry .${win_name} 350x320
      wm state .${win_name} withdrawn
      wm title .${win_name} "[trans chat]"
      wm group .${win_name} .
      wm iconbitmap . @${images_folder}/amsn.xbm
      wm iconmask . @${images_folder}/amsnmask.xbm

      menu .${win_name}.menu -tearoff 0 -type menubar  \
         -borderwidth 0 -activeborderwidth -0
      .${win_name}.menu add cascade -label "[trans msn]" -menu .${win_name}.menu.msn
      .${win_name}.menu add cascade -label "[trans edit]" -menu .${win_name}.menu.edit
      .${win_name}.menu add cascade -label "[trans view]" -menu .${win_name}.menu.view
      .${win_name}.menu add cascade -label "[trans actions]" -menu .${win_name}.menu.actions

      menu .${win_name}.menu.msn -tearoff 0 -type normal
      .${win_name}.menu.msn add command -label "[trans save]" \
         -command " ChooseFilename .${win_name}.f.out.text ${win_name} "
      .${win_name}.menu.msn add command -label "[trans saveas]..." \
         -command " ChooseFilename .${win_name}.f.out.text ${win_name} "
      .${win_name}.menu.msn add separator
      .${win_name}.menu.msn add command -label "[trans sendfile]..." \
         -command "::amsn::FileTransferSend .${win_name}" -state disabled
      .${win_name}.menu.msn add command -label "[trans openreceived]..." \
         -command "launch_filemanager \"$files_dir\""
      .${win_name}.menu.msn add separator
      .${win_name}.menu.msn add command -label "[trans close]" \
         -command "destroy .${win_name}"

      menu .${win_name}.menu.edit -tearoff 0 -type normal
      .${win_name}.menu.edit add command -label "[trans cut]" -command "copy 1 ${win_name}" -accelerator "Ctrl+X"
      .${win_name}.menu.edit add command -label "[trans copy]" -command "copy 0 ${win_name}" -accelerator "Ctrl+C"
      .${win_name}.menu.edit add command -label "[trans paste]" -command "paste ${win_name}" -accelerator "Ctrl+V"

      menu .${win_name}.menutextsize -tearoff 0 -type normal
      .${win_name}.menutextsize add command -label "+8" -command "change_myfontsize 8 ${win_name}"
      .${win_name}.menutextsize add command -label "+6" -command "change_myfontsize 6 ${win_name}"
      .${win_name}.menutextsize add command -label "+4" -command "change_myfontsize 4 ${win_name}"
      .${win_name}.menutextsize add command -label "+2" -command "change_myfontsize 2 ${win_name}"
      .${win_name}.menutextsize add command -label "+1" -command "change_myfontsize 1 ${win_name}"
      .${win_name}.menutextsize add command -label "+0" -command "change_myfontsize 0 ${win_name}"
      .${win_name}.menutextsize add command -label "-1" -command "change_myfontsize -1 ${win_name}"
      .${win_name}.menutextsize add command -label "-2" -command "change_myfontsize -2 ${win_name}"

      menu .${win_name}.menu.view -tearoff 0 -type normal
      .${win_name}.menu.view add cascade -label "[trans textsize]" \
         -menu .${win_name}.menutextsize
      .${win_name}.menu.view add separator
      .${win_name}.menu.view add checkbutton -label "[trans chatsmileys]" \
        -onvalue 1 -offvalue 0 -variable config(chatsmileys)
      .${win_name}.menu.view add separator
      .${win_name}.menu.view add command -label "[trans history]" -command "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin" -accelerator "Ctrl+H"

      menu .${win_name}.menu.actions -tearoff 0 -type normal
      .${win_name}.menu.actions add command -label "[trans addtocontacts]" \
         -command "::amsn::ShowAddList \"[trans addtocontacts]\" .${win_name} ::MSN::addUser"
      .${win_name}.menu.actions add command -label "[trans block]/[trans unblock]" \
         -command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} ::amsn::blockUnblockUser"
      .${win_name}.menu.actions add command -label "[trans viewprofile]" \
         -command "::amsn::ShowChatList \"[trans viewprofile]\" .${win_name} ::hotmail::viewProfile"
      .${win_name}.menu.actions add command -label "[trans properties]" \
         -command "::amsn::ShowChatList \"[trans properties]\" .${win_name} ::abookGui::showEntry"
      .${win_name}.menu.actions add separator
      .${win_name}.menu.actions add command -label "[trans invite]..." -command "::amsn::ShowInviteList \"[trans invite]\" .${win_name}"
      .${win_name}.menu.actions add command -label "[trans sendfile]..." \
      -command "::amsn::FileTransferSend .${win_name}"  -state disabled
      .${win_name}.menu.actions add separator
      .${win_name}.menu.actions add command -label [trans sendmail] \
          -command "::amsn::ShowChatList \"[trans sendmail]\" .${win_name} launch_mailer"
      .${win_name} conf -menu .${win_name}.menu

      menu .${win_name}.copypaste -tearoff 0 -type normal
      .${win_name}.copypaste add command -label [trans cut] -command "status_log cut\n;copy 1 ${win_name}"
      .${win_name}.copypaste add command -label [trans copy] -command "status_log copy\n;copy 0 ${win_name}"
      .${win_name}.copypaste add command -label [trans paste] -command "status_log paste\n;paste ${win_name}"

      menu .${win_name}.copy -tearoff 0 -type normal
      .${win_name}.copy add command -label [trans copy] -command "status_log copy\n;copy 0 ${win_name}"

      frame .${win_name}.f -class amsnChatFrame -background $bgcolor -borderwidth 0 -relief flat

      frame .${win_name}.f.out -class Amsn -background white -borderwidth 0 -relief flat

      text .${win_name}.f.out.text -borderwidth 0 -background white -width 45 -height 15 -wrap word \
         -yscrollcommand ".${win_name}.f.out.ys set" -exportselection 1  -relief solid -highlightthickness 0 \
	  -selectborderwidth 1


      frame .${win_name}.f.top -class Amsn -relief flat -borderwidth 0 -background $bgcolor


      text .${win_name}.f.top.textto  -borderwidth 0 -width [string length "[trans to]:"] -relief solid \
         -height 1 -wrap none -background $bgcolor -foreground $bgcolor2 -highlightthickness 0 \
	  -selectbackground $bgcolor -selectforeground $bgcolor2 -selectborderwidth 0 -exportselection 0
      .${win_name}.f.top.textto configure -state normal -font bplainf
      .${win_name}.f.top.textto insert end "[trans to]:"
      .${win_name}.f.top.textto configure -state disabled

      text .${win_name}.f.top.text  -borderwidth 0 -width 45 -relief flat \
         -height 1 -wrap none -background $bgcolor -foreground $bgcolor2 -highlightthickness 0 \
	  -selectbackground $bgcolor -selectborderwidth 0 -selectforeground $bgcolor2 -exportselection 0

#-yscrollcommand ".${win_name}.f.top.ys set"



      frame .${win_name}.f.buttons -class Amsn -borderwidth 0 -relief solid -background $bgcolor2

      frame .${win_name}.f.in -class Amsn -background white -relief solid -borderwidth 0

      text .${win_name}.f.in.input -background white -width 15 -height 3 -wrap word\
         -font bboldf -borderwidth 0 -relief solid -highlightthickness 0

      frame .${win_name}.f.in.f -class Amsn -borderwidth 0 -relief solid -background white
      button .${win_name}.f.in.f.send  -text [trans send] -width 5 -borderwidth 1 -relief solid \
         -command "::amsn::MessageSend .${win_name} .${win_name}.f.in.input" -font bplainf -highlightthickness 0


      #scrollbar .${win_name}.f.top.ys -command ".${win_name}.f.top.text yview"

      scrollbar .${win_name}.f.out.ys -command ".${win_name}.f.out.text yview" \
         -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
      
      text .${win_name}.status  -width 30 -height 1 -wrap none\
         -font bplainf -borderwidth 1



      button .${win_name}.f.buttons.smileys  -image butsmile -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
      button .${win_name}.f.buttons.fontsel -image butfont -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
      button .${win_name}.f.buttons.block -image butblock -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
      pack .${win_name}.f.buttons.block .${win_name}.f.buttons.fontsel .${win_name}.f.buttons.smileys -side left

      pack .${win_name}.f.top -side top -fill x -padx 3 -pady 0
      pack .${win_name}.status -side bottom -fill x
      pack .${win_name}.f.in -side bottom -fill x -pady 3 -padx 3
      pack .${win_name}.f.buttons -side bottom -fill x -padx 3 -pady 0
      pack .${win_name}.f.out.ys -side right -fill y -padx 0
      pack .${win_name}.f.out -expand true -fill both -padx 3 -pady 0
      pack .${win_name}.f.out.text -side right -expand true -fill both -padx 2 -pady 2

      pack .${win_name}.f.top.textto -side left -fill y -anchor nw -padx 0 -pady 3
      pack .${win_name}.f.top.text -side left -expand true -fill x -padx 4 -pady 3

      pack .${win_name}.f.in.f -side right -fill y -padx 3 -pady 4
      pack .${win_name}.f.in.f.send -fill both -expand true
      pack .${win_name}.f.in.input -side left -expand true -fill x -padx 1

      pack .${win_name}.f -expand true -fill both -padx 0 -pady 0

      .${win_name}.f.top.text configure -state disabled
      .${win_name}.f.out.text configure -state disabled
      .${win_name}.status configure -state disabled
      .${win_name}.f.in.f.send configure -state disabled
      .${win_name}.f.in.input configure -state normal


      .${win_name}.f.out.text tag configure green -foreground darkgreen -background white -font bboldf
      .${win_name}.f.out.text tag configure red -foreground red -background white -font bboldf
      .${win_name}.f.out.text tag configure blue -foreground blue -background white -font bboldf
      .${win_name}.f.out.text tag configure gray -foreground #808080 -background white
      .${win_name}.f.out.text tag configure white -foreground white -background black
      .${win_name}.f.out.text tag configure url -foreground #000080 -background white -font bboldf -underline true
      .${win_name}.f.out.text tag configure url -foreground #000080 -background white -font bboldf -underline true


      bind .${win_name}.f.in.input <Tab> "focus .${win_name}.f.in.f.send; break"

      bind  .${win_name}.f.buttons.smileys  <Button1-ButtonRelease> "smile_menu %X %Y .${win_name}.f.in.input"
      bind  .${win_name}.f.buttons.fontsel  <Button1-ButtonRelease> "change_myfont ${win_name}"
      bind  .${win_name}.f.buttons.block  <Button1-ButtonRelease> "::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} ::amsn::blockUnblockUser"

      bind .${win_name}.f.in.f.send <Return> \
         "::amsn::MessageSend .${win_name} .${win_name}.f.in.input; break"
      bind .${win_name}.f.in.input <Control-Return> {%W insert end "\n"; break}
      bind .${win_name}.f.in.input <Shift-Return> {%W insert end "\n"; break}

      bind .${win_name}.f.in.input <Button3-ButtonRelease> "tk_popup .${win_name}.copypaste %X %Y"
      bind .${win_name}.f.out.text <Button3-ButtonRelease> "tk_popup .${win_name}.copy %X %Y"
      
      bind .${win_name} <Control-x> "status_log cut\n;copy 1 ${win_name}"
      bind .${win_name} <Control-c> "status_log copy\n;copy 0 ${win_name}"
      bind .${win_name} <Control-v> "status_log paste\n;paste ${win_name}"

      bind .${win_name} <Control-h> "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin"
      
      bind .${win_name} <Destroy> "::amsn::closeWindow .${win_name} %W"

      focus .${win_name}.f.in.input

      change_myfontsize $config(textsize) ${win_name}


      #TODO: We always want these menus and bindings enabled? Think it!!
      .${win_name}.f.in.input configure -state normal
      .${win_name}.f.in.f.send configure -state normal

      .${win_name}.menu.msn entryconfigure 3 -state normal
      .${win_name}.menu.actions entryconfigure 5 -state normal

      bind .${win_name}.f.in.input <Key> "::amsn::TypingNotification .${win_name}"
      bind .${win_name}.f.in.input <Return> "::amsn::MessageSend .${win_name} %W; break"
      bind .${win_name}.f.in.input <Key-KP_Enter> "::amsn::MessageSend .${win_name} %W; break"
      bind .${win_name}.f.in.input <Alt-s> "::amsn::MessageSend .${win_name} %W; break"


      set window_titles(.${win_name}) ""

      
      wm state .${win_name} withdrawn      
      return ".${win_name}"

   }
   #///////////////////////////////////////////////////////////////////////////////


   proc ShowAddList {title win_name command} {
      global list_users

      set userlist [list]
      set chatusers [::MSN::usersInChat [ChatFor $win_name]]

      foreach user_login $chatusers {
         set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]

	 if {([lsearch $list_users "$user_login *"] == -1)} {
	     set user_name [lindex [::MSN::getUserInfo $user_login] 1]
	     lappend userlist [list $user_login $user_name $user_state_no]
         }
      }

      if { [llength $userlist] > 0 } {
   	   ChooseList $title both $command 1 1 $userlist
      } else {
   	   msg_box "[trans useralreadyonlist]"
      }
   }


   proc ShowInviteList { title win_name } {
	global list_users


	if {![::MSN::chatReady [ChatFor $win_name]]} {
	   return 0
	}

	set userlist [list]
	set chatusers [::MSN::usersInChat [ChatFor $win_name]]

	foreach user_info $list_users {
	        set user_login [lindex $user_info 0]
		set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]
      		if {($user_state_no < 7) && ([lsearch $chatusers "$user_login"] == -1)} {
          		set user_name [lindex [::MSN::getUserInfo $user_login] 1]
	  		lappend userlist [list $user_login $user_name $user_state_no]
      		}
   	}

	if { [llength $userlist] > 0 } {
		#TODO: Should queue invitation until chat is ready, to fix some problems when
		# inviting a user while the first one hasn't joined yet
   		ChooseList $title both "::MSN::inviteUser [ChatFor $win_name]" 1 0 $userlist
  	} else {
		cmsn_draw_otherwindow $title "::MSN::inviteUser [ChatFor $win_name]"
	}
   }

   proc ShowChatList {title win_name command} {
      global list_users

      set userlist [list]
      set chatusers [::MSN::usersInChat [ChatFor $win_name]]

      foreach user_login $chatusers {
         set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]

         if { $user_state_no < 7 } {
      	     set user_name [lindex [::MSN::getUserInfo $user_login] 1]
      	     lappend userlist [list $user_login $user_name $user_state_no]
         }
      }

      if { [llength $userlist] > 0 } {
   	   ChooseList $title both $command 0 1 $userlist
      }

   }



   #///////////////////////////////////////////////////////////////////////////////
   proc ChooseList {title online command other skip {userslist ""}} {
      global list_users list_bl list_states userchoose_req bgcolor

      if { $userslist == "" } {
         set userslist $list_users
      }

      set usercount 0

      #Count users. Ignore offline ones if $online=="online"
      foreach user $userslist {
         set user_login [lindex $user 0]
         set user_state_no [lindex $user 2]
	 if { "$user_state_no" == "" } {
	    set user_state_no 0
	 }
         set state [lindex $list_states $user_state_no]
         set state_code [lindex $state 0]

         if {($online != "online") || ($state_code != "FLN")} {
      	     set usercount [expr {$usercount + 1}]
         }

      }

      #If just 1 user, and $skip flag set to one, just run command on that user
      if { $usercount == 1 && $skip == 1} {
         eval $command $user_login
         return 0
      }

      set wname "[focus]_userchoose"

      if { [catch {toplevel $wname -width 400 -height 300 -borderwidth 0 -highlightthickness 0 } res ] } {
         raise $wname
         focus $wname
         return 0
      }

      wm group $wname .

      wm title $wname $title
      wm transient $wname .
      wm geometry $wname 280x300

      frame $wname.blueframe -background $bgcolor

      frame $wname.blueframe.list -class Amsn -borderwidth 0
      frame $wname.buttons -class Amsn


      listbox $wname.blueframe.list.userlist -yscrollcommand "$wname.blueframe.list.ys set" -font splainf \
         -background white -relief flat -highlightthickness 0 -height 1
      scrollbar $wname.blueframe.list.ys -command "$wname.blueframe.list.userlist yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2

      button  $wname.buttons.ok -text "[trans ok]" -command "$command \[string range \[lindex \[$wname.blueframe.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname" -font sboldf
      button  $wname.buttons.cancel -text "[trans cancel]" -command "destroy $wname" -font sboldf


      pack $wname.blueframe.list.ys -side right -fill y
      pack $wname.blueframe.list.userlist -side left -expand true -fill both
      pack $wname.blueframe.list -side top -expand true -fill both -padx 4 -pady 4
      pack $wname.blueframe -side top -expand true -fill both

      if { $other == 1 } {
         button  $wname.buttons.other -text "[trans other]..." -command "cmsn_draw_otherwindow \"$title\" \"$command\"; destroy $wname" -font sboldf
         #pack $wname.buttons.other $wname.buttons.cancel $wname.buttons.ok -padx 10 -side right
         pack $wname.buttons.ok -padx 0 -side left
	  pack $wname.buttons.cancel -padx 0 -side right
         pack $wname.buttons.other -padx 10 -side left

      } else {
         pack $wname.buttons.ok -padx 0 -side left
	  pack $wname.buttons.cancel -padx 0 -side right

      }

      pack $wname.buttons -side bottom -fill x -pady 3


      foreach user $userslist {
         set user_login [lindex $user 0]
         set user_name [lindex $user 1]
         set user_state_no [lindex $user 2]
	 if { "$user_state_no" == "" } {
	    set user_state_no 0
	 }
	 set state [lindex $list_states $user_state_no]
         set state_code [lindex $state 0]

         if {($online != "online") || ($state_code != "FLN")} {
            if {[lsearch $list_bl "$user_login *"] != -1} {
               $wname.blueframe.list.userlist insert end "BLOCKED -> $user_name <$user_login>"
            } else {
               $wname.blueframe.list.userlist insert end "$user_name <$user_login>"
            }
         }

      }

      bind $wname.blueframe.list.userlist <Double-Button-1> "$command \[string range \[lindex \[$wname.blueframe.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname"
      focus $wname.buttons.ok
      bind $wname <Escape> "destroy $wname"
      bind $wname <Return> "$command \[string range \[lindex \[$wname.blueframe.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname"

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # TypingNotification (win_name)
   # Called by a window when the user types something into the text box. It tells
   # the protocol layer to send a typing notificacion to the chat that the window
   # 'win_name' is connected to
   proc TypingNotification { win_name } {

      set chatid [ChatFor $win_name]

      #Don't queue unless chat is ready, but try to reconnect
      if { [::MSN::chatReady $chatid] } {
         sb_change $chatid
      } else {
         ::MSN::chatTo $chatid
      }

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # MessageSend (win_name,input)
   # Called from a window the the user enters a message to send to the chat. It will
   # just queue the message to send in the chat associated with 'win_name', and set
   # a timeout for the message
   proc MessageSend { win_name input } {

      global user_info config

      set chatid [ChatFor $win_name]

      set msg [$input get 0.0 end-1c]

      #Blank message
      if {[string length $msg] < 1} { return 0 }

      $input delete 0.0 end
      focus ${input}

      if { [string length $msg] > 400 } {
      	set first 0
	while { [expr $first + 400] <= [string length $msg] } {
		set msgchunk [string range $msg $first [expr $first + 399]]
		set ackid [after 50000 ::amsn::DeliveryFailed $chatid [list $msgchunk]]
		::MSN::messageTo $chatid "$msgchunk" $ackid
		incr first 400
	}
	set msgchunk [string range $msg $first end]
	set ackid [after 50000 ::amsn::DeliveryFailed $chatid [list $msgchunk]]
	::MSN::messageTo $chatid "$msgchunk" $ackid
      } else {
      	set ackid [after 50000 ::amsn::DeliveryFailed $chatid [list $msg]]
      	#::MSN::chatQueue $chatid [list ::MSN::messageTo $chatid "$msg" $ackid]
      	::MSN::messageTo $chatid "$msg" $ackid
      }

      set fontfamily [lindex $config(mychatfont) 0]
      set fontstyle [lindex $config(mychatfont) 1]
      set fontcolor [lindex $config(mychatfont) 2]

      #Draw our own message
      messageFrom $chatid [lindex $user_info 3] "$msg" user [list $fontfamily $fontstyle $fontcolor]

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # ackMessage (ackid)
   # Called from the protocol layer when ACK for a message is received. It Cancels
   # the timer for timeouting the message 'ackid'.
   proc ackMessage { ackid } {
     after cancel $ackid
   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   # nackMessage (ackid)
   # Called from the protocol layer when NACK for a message is received. It just
   # writes the delivery error message without waiting for the message to timeout,
   # and cancels the timer.
   proc nackMessage { ackid } {
     set command [lindex [after info $ackid] 0]
     after cancel $ackid
     eval $command
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # DeliveryFailed (chatid,msg)
   # Writes the delivery error message along with the timeouted 'msg' into the
   # window related to 'chatid'
   proc DeliveryFailed { chatid msg } {

      WinWrite $chatid "[timestamp] [trans deliverfail]: " red
      WinWrite $chatid "$msg\n" gray

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # closeWindow (win_name,path)
   # Called when a window and its children are destroyed. When the main window is
   # detroyed ('win_name'=='path') then it tells the protocol layer to leave the
   # chat related to 'win_name', and unsets variables used for that window
   proc closeWindow { win_name path } {

      #Only run when the parent window close event comes
      if { "$win_name" != "$path" } {
        return 0
      }


      global config
      variable window_titles


      set chatid [ChatFor $win_name]

      if {$config(keep_logs)} {
		set user_list [::MSN::usersInChat $chatid]
		foreach user_login $user_list {
			::log::StopLog $user_login
		}
      }

      UnsetWindowFor $chatid $win_name
      unset window_titles(${win_name})

      ::MSN::leaveChat $chatid

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # PutMessage (chatid,user,msg,type,fontformat)
   # Writes a message into the window related to 'chatid'
   # - 'user' is the user login. If 'user'=="msg" then the message is taken as a
   #   system or information message, and "XXXX says:" won't be added at the beginning.
   # - 'msg' is the message itself to be displayed.
   # - 'type' can be red, gray... or any tag defined for the textbox when the windo
   #   was created, or just "user" to use the fontformat parameter
   # - 'fontformat' is a list containing font style and color
   proc PutMessage { chatid user msg type fontformat } {

	global config
	if { "$user" != "msg" } {
		WinWrite $chatid "[timestamp] [trans says [lindex [::MSN::getUserInfo $user] 1]]:\n" gray
	}


	WinWrite $chatid "$msg\n" $type [lindex $fontformat 0] [lindex $fontformat 1] [lindex $fontformat 2]
	WinFlicker $chatid

	if {$config(keep_logs)} {
		::log::PutLog $chatid $user $msg
	}

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # chatStatus (chatid,msg,[icon])
   # Called by the protocol layer to show some information about the chat, that
   # should be shown in the status bar. It will only show it if the chat is not
   # ready, as most information is about connections/reconnections, and we don't
   # mind in case we have a "chat ready to chat".
   proc chatStatus {chatid msg {icon ""}} {

      if { [WindowFor $chatid] == 0} {
         return 0
      } else {
           WinStatus [ WindowFor $chatid ] $msg $icon
      }

   }
   #///////////////////////////////////////////////////////////////////////////////


   proc chatDisabled {chatid} {
   	chatStatus $chatid ""
   }

   #///////////////////////////////////////////////////////////////////////////////
   # WinStatus (win_name,msg,[icon])
   # Writes the message 'msg' in the window 'win_name' status bar. It will add the
   # icon 'icon' at the beginning of the message, if specified.
   proc WinStatus { win_name msg {icon ""}} {

      ${win_name}.status configure -state normal
      ${win_name}.status delete 0.0 end
      if { "$icon"!=""} {
	  ${win_name}.status image create end -image $icon -pady 0 -padx 1
      }
      ${win_name}.status insert end $msg
      ${win_name}.status configure -state disabled

      #TODO: Should change the size of the top text to fit the users names
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WinFlicker (chatid,[count])
   # Called when a window must flicker, and called by itself to produce the flickering
   # effect. It will flicker the window until it gots the focus.
   # - 'chatid' is the name of the chat to flicker.
   # - 'count' can be any number, it's just used in self calls
   proc WinFlicker {chatid {count 0}} {

      variable window_titles

      if { [WindowFor $chatid] != 0} {
         set win_name [WindowFor $chatid]
      } else {
         return 0
      }

      after cancel ::amsn::WinFlicker $chatid 0
      after cancel ::amsn::WinFlicker $chatid 1

      if { [string first $win_name [focus]] != 0 } {

      set count  [expr {( $count +1 ) % 2}]
      
      if {![catch {
	     if { $count == 1 } {
  	        wm title ${win_name} "[trans newmsg]"
  	     } else {
	        wm title ${win_name} "$window_titles($win_name)"
	     }
	  } res]} {
 	     after 300 ::amsn::WinFlicker $chatid $count
      }
      } else {

	  catch {wm title ${win_name} "$window_titles($win_name)"} res
      }

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # chatUser (user)
   # Opens a chat for user 'user'. If a window for that user already exists, it will
   # use it and reconnect if necessary (will call to the protocol function chatUser),
   # and raise and focus that window. If the window doesn't exist it will open a new
   # one. 'user' is the mail address of the user to chat with.
   proc chatUser { user } {

      set win_name [WindowFor $user]

      if { $win_name == 0 } {

	  set win_name [OpenChatWindow]
         SetWindowFor $user $win_name

      }

      set chatid [::MSN::chatTo $user]

      if { "$chatid" != "$user"} {
         status_log "Error, expected same chatid as user, but was different\n" red
         return 0
      }

      wm state $win_name normal
      wm deiconify ${win_name}

      WinTopUpdate $chatid

      #We have a window for that chatid, raise it
      raise ${win_name}
      focus -force ${win_name}.f.in.input


   }
   #///////////////////////////////////////////////////////////////////////////////


   variable urlcount 0
   set urlstarts { "http://" "https://" "ftp://" "www." }

   #///////////////////////////////////////////////////////////////////////////////
   # WinWrite (chatid,txt,[colour],[fontname,fontstyle,fontcolor])
   # Writes 'txt' into the window related to 'chatid'
   # It will use 'colour' as style tag, unles 'colour'=="user", where it will use
   # 'fontname', 'fontstyle' and 'fontcolor' as text parameters.
   proc WinWrite {chatid txt {colour ""} {fontname ""} {fontstyle ""} {fontcolor ""}} {
      global emotions config

      variable urlcount
      variable urlstarts

      set win_name [WindowFor $chatid]

      if { [WindowFor $chatid] == 0} {
         return 0
      }

      ${win_name}.f.out.text configure -state normal -font bplainf -foreground black


      set text_start [${win_name}.f.out.text index end]
      set posyx [split $text_start "."]
      set text_start "[expr {[lindex $posyx 0]-1}].[lindex $posyx 1]"

      set tagid $colour

      if { $colour == "user" || $colour == "yours" } {
         set size [expr {[lindex $config(basefont) 1]+$config(textsize)}]
         set font "\"$fontname\" $size $fontstyle"

         set tagid [::md5::md5 "$font$fontcolor"]

         if {[catch {${win_name}.f.out.text tag configure $tagid -foreground #$fontcolor -font $font} res] || [string length $fontname] <3} {
            status_log "Font $font or color $fontcolor wrong. Using default\n" red
            ${win_name}.f.out.text tag configure $tagid -foreground black -font bplainf
         }
      }

      ${win_name}.f.out.text insert end "$txt" $tagid

      set endpos $text_start

      foreach url $urlstarts {

         while { $endpos != [${win_name}.f.out.text index end] && [set pos [${win_name}.f.out.text search -forward -exact -nocase \
                                 $url $endpos end]] != "" } {


	   set urltext [${win_name}.f.out.text get $pos end]

	   set final 0
	   set caracter [string range $urltext $final $final]
	   while { $caracter != " " && $caracter != "\n" } {
		set final [expr {$final+1}]
		set caracter [string range $urltext $final $final]
	   }

	   set urltext [string range $urltext 0 [expr {$final-1}]]

           set posyx [split $pos "."]
           set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $final}]"

	   set urlcount "[expr {$urlcount+1}]"
	   set urlname "url_$urlcount"

	   ${win_name}.f.out.text tag configure $urlname \
	      -foreground #000080 -background white -font bboldf -underline true
	      ${win_name}.f.out.text tag bind $urlname <Enter> \
	      "${win_name}.f.out.text tag conf $urlname -underline false;\
	      ${win_name}.f.out.text conf -cursor hand2"
	   ${win_name}.f.out.text tag bind $urlname <Leave> \
	      "${win_name}.f.out.text tag conf $urlname -underline true;\
	      ${win_name}.f.out.text conf -cursor left_ptr"
	   ${win_name}.f.out.text tag bind $urlname <Button1-ButtonRelease> \
	      "launch_browser \"$urltext\""

  	   ${win_name}.f.out.text delete $pos $endpos
	   ${win_name}.f.out.text insert $pos "$urltext" $urlname

         }
      }

      if {$config(chatsmileys)} {
         smile_subst ${win_name}.f.out.text $text_start
      }


      ${win_name}.f.out.text yview moveto 1.0
      ${win_name}.f.out.text configure -state disabled

   }
   #///////////////////////////////////////////////////////////////////////////////



   proc AcceptedFT { chatid cookie } {
   

      set win_name [WindowFor $chatid]

     ${win_name}.f.out.text configure -state normal -font bplainf -foreground black


     ${win_name}.f.out.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftyes$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Button1-ButtonRelease> ""


     ${win_name}.f.out.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftno$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.out.text conf -cursor left_ptr

     set txt [trans ftaccepted]

     #TODO: Use WinWrite or similar
     ${win_name}.f.out.text insert end "----------\n" gray
     ${win_name}.f.out.text image create end -image fticon -pady 2 -padx 3
     ${win_name}.f.out.text insert end " $txt\n" gray
     ${win_name}.f.out.text insert end "----------\n" gray

     ${win_name}.f.out.text yview moveto 1.0
     ${win_name}.f.out.text configure -state disabled
   }

   proc RejectedFT {chatid cookie} {

      set win_name [WindowFor $chatid]

     #TODO: Use WinWrite or similar (when possible)
     # Improve WinWrite to support tags, clickable text, and so on
     ${win_name}.f.out.text configure -state normal -font bplainf -foreground black


     ${win_name}.f.out.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftyes$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.out.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftno$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.out.text conf -cursor left_ptr

     set txt [trans ftrejected]

     ${win_name}.f.out.text insert end "----------\n" gray
     ${win_name}.f.out.text image create end -image ftreject -pady 2 -padx 3
     ${win_name}.f.out.text insert end "$txt\n" gray
     ${win_name}.f.out.text insert end "----------\n" gray

     ${win_name}.f.out.text yview moveto 1.0
     ${win_name}.f.out.text configure -state disabled
   }

   #PRIVATE: Opens Sending Window
   proc SendWin {filename cookie} {
      status_log "Creating send progress window\n"
      set w .ft$cookie
      toplevel $w
      wm group $w .
      wm title $w "[trans sendfile] $filename"
      wm geometry $w 300x100

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelSending $cookie"
      pack $w.close -side bottom
      
      pack [::dkfprogress::Progress $w.prbar] -fill x -expand 1 -padx 5 -pady 5


      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelSending $cookie"
   }

   #PRIVATE: Opens Receiving Window
   proc RecvWin {filename cookie} {
     status_log "Creating receive progress window\n"
      set w .ft$cookie
      toplevel $w
      wm group $w .      
      wm title $w "[trans receivefile] $filename"
      wm geometry $w 300x100

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelReceiving $cookie"
      pack $w.close -side bottom

      pack [::dkfprogress::Progress $w.prbar] -fill x -expand 1 -padx 5 -pady 5
      
      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelReceiving $cookie"
   }


   #Updates filetransfer progress window/baar
   #fileTransferProgress mode cookie bytes filesize
   # mode: c=Cancel
   #       s=Sending
   #       r=Receiving
   # cookie: ID for the filetransfer
   # bytes: bytes sent/received (-1 if cancelling)
   # filesize: total bytes in the file
   proc fileTransferProgress {mode cookie bytes filesize} {
      # -1 in bytes to transfer cancelled
      # bytes >= filesize for connection finished
      set w .ft$cookie

      if { [winfo exists $w] == 0} {
        return
      }

      if { $mode == "p" } {
	 $w.progress configure -text "[trans listeningon $bytes]"
	 return
      } 

      
      if { $bytes <0 } {
	 $w.progress configure -text "[trans filetransfercancelled]"
      } elseif { $bytes >= $filesize } {
	 ::dkfprogress::SetProgress $w.prbar 100
	 $w.progress configure -text "[trans filetransfercomplete]"
      }

      set bytes2 [expr {$bytes/1024}]
      set filesize2 [expr {$filesize/1024}]
      if { $filesize2 != 0 } {
        set percent [expr {($bytes2*100)/$filesize2}]
      } else {
        set percent 100
      }

      if { ($bytes >= $filesize) || ($bytes<0)} {
	 $w.close configure -text "[trans close]" -command "destroy $w"
         wm protocol $w WM_DELETE_WINDOW "destroy $w"
      } elseif { $mode == "r" } {
	 $w.progress configure -text "[trans receivedbytes $bytes2 [list $filesize2 Kb]]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      } else {
	 $w.progress configure -text "[trans sentbytes $bytes2 [list $filesize2 Kb]]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      }
   }

   variable NotifID 0
   variable NotifPos [list]
   variable im [image create photo -width 180 -height 110]

   
   #TODO: We will make amsn skinnable, so this should be used only if there not exists
   # a background bitmap for the notifyWindow
   for {set i 0} {$i < 110} {incr i} {
      set rg [expr {35+$i*2}]
      set col [format "%2.2X%2.2XFF" $rg $rg]
      $im put "#$col" -to 0 $i 180 [expr {$i + 1}]
   }

   proc closeAmsn {} {
      set answer [tk_messageBox -message "[trans exitamsn]" -type yesno -icon question -title [trans title]]
      if {$answer == "yes"} {
         close_cleanup
         exit
      }
   }

   proc closeOrDock { closingdocks } {
     if {$closingdocks} {
        wm iconify .
     } else {
        ::amsn::closeAmsn
     }
   }


   #Adds a message to the notify, that executes "command" when clicked, and
   #plays "sound"
   proc notifyAdd { msg command {sound ""}} {

      global config

      if { $config(notifywin) == 0 } {
        return;
      }
      variable NotifID
      variable NotifPos
      variable im
      global images_folder

      set w .notif$NotifID
      incr NotifID

      toplevel $w -width 1 -height 1
      wm group $w .
      wm state $w withdrawn

      set xpos $config(notifyXoffset)
      set ypos $config(notifyYoffset)

      while { [lsearch -exact $NotifPos $ypos] >=0 } {
        set ypos [expr {$ypos+105}]
      }
      lappend NotifPos $ypos


      if { $xpos < 0 } { set xpos 0 }
      if { $ypos < 0 } { set ypos 0 }

      wm geometry $w -$xpos-$ypos

      canvas $w.c -bg #EEEEFF -width 150 -height 100 \
         -relief ridge -borderwidth 2
      pack $w.c


      $w.c create image 75 50 -image $im
      $w.c create image 17 22 -image notifico
      $w.c create image 80 97 -image notifybar

      if {[string length $msg] >100} {
         set msg "[string range $msg 0 100]..."
      }

      set notify_id [$w.c create text 78 40 -font splainf \
         -justify center -width 148 -anchor n -text "$msg"]

      set after_id [after 8000 "::amsn::KillNotify $w $ypos"]

      bind $w.c <Enter> "$w.c configure -cursor hand2"
      bind $w.c <Leave> "$w.c configure -cursor left_ptr"
      bind $w <ButtonRelease-1> "after cancel $after_id; ::amsn::KillNotify $w $ypos; $command"
      bind $w <ButtonRelease-3> "after cancel $after_id; ::amsn::KillNotify $w $ypos"


      wm title $w "[trans msn] [trans notify]"
      wm overrideredirect $w 1
      #wm transient $w
      wm state $w normal

      raise $w

      if { $sound != ""} {
         sonido $sound
      }


   }

   proc KillNotify { w ypos} {
      variable NotifPos

      wm state $w withdrawn
      #Delay the destroying, to avoid a bug in tk 8.3
      after 5000 destroy $w
      set lpos [lsearch -exact $NotifPos $ypos]
      set NotifPos [lreplace $NotifPos $lpos $lpos]
   }
   
}



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_main {} {
   global images_folder program_dir emotion_files version date weburl lang_list \
     password config HOME files_dir pgBuddy pgNews bgcolor bgcolor2 argv0 argv

   #User status menu
   menu .my_menu -tearoff 0 -type normal
   .my_menu add command -label [trans online] -command "::MSN::changeStatus NLN"
   .my_menu add command -label [trans noactivity] -command "::MSN::changeStatus IDL"
   .my_menu add command -label [trans busy] -command "::MSN::changeStatus BSY"
   .my_menu add command -label [trans rightback] -command "::MSN::changeStatus BRB"
   .my_menu add command -label [trans away] -command "::MSN::changeStatus AWY"
   .my_menu add command -label [trans onphone] -command "::MSN::changeStatus PHN"
   .my_menu add command -label [trans gonelunch] -command "::MSN::changeStatus LUN"
   .my_menu add command -label [trans appearoff] -command "::MSN::changeStatus HDN"
   .my_menu add separator
   .my_menu add command -label "[trans changenick]..." -command cmsn_change_name

   #Preferences dialog/menu
   menu .pref_menu -tearoff 0 -type normal
   PreferencesMenu .pref_menu

   menu .user_menu -tearoff 0 -type normal
   menu .move_group_menu -tearoff 0 -type normal
   menu .copy_group_menu -tearoff 0 -type normal

   #Main menu
   menu .main_menu -tearoff 0 -type menubar  -borderwidth 0 -activeborderwidth -0
   .main_menu add cascade -label "[trans msn]" -menu .main_menu.file
   .main_menu add cascade -label "[trans actions]" -menu .main_menu.actions
   .main_menu add cascade -label "[trans tools]" -menu .main_menu.tools
   .main_menu add cascade -label "[trans help]" -menu .main_menu.help


   #File menu
   menu .main_menu.file -tearoff 0 -type normal 
   if { [string length $config(login)] > 0 } {
     if {$password != ""} {
        .main_menu.file add command -label "[trans login] $config(login)" \
          -command "::MSN::connect [list $config(login)] [list $password]" -state normal
     } else {
     	.main_menu.file add command -label "[trans login] $config(login)" \
          -command cmsn_draw_login -state normal
     }
   } else {
     .main_menu.file add command -label "[trans login]" \
       -command "::MSN::connect $config(login) $password" -state disabled
   }
   .main_menu.file add command -label "[trans login]..." -command \
     cmsn_draw_login
   .main_menu.file add command -label "[trans logout]" -command "::MSN::logout; save_alarms"
   .main_menu.file add cascade -label "[trans mystatus]" \
     -menu .my_menu -state disabled
   .main_menu.file add separator
   .main_menu.file add command -label "[trans inbox]" -command \
     "hotmail_login $config(login) $password"
   .main_menu.file add separator
   .main_menu.file add command -label "[trans savecontacts]..." \
   	-command "debug_cmd_lists -export contactlist" -state disabled
   .main_menu.file add command -label "[trans loadcontacts]..." -state disabled
   .main_menu.file add separator
   .main_menu.file add command -label "[trans sendfile]..." -state disabled
   .main_menu.file add command -label "[trans openreceived]" \
      -command "launch_filemanager \"$files_dir\""
   .main_menu.file add separator
   .main_menu.file add command -label "[trans close]" -command "close_cleanup;exit"

   #Actions menu
   set dummy_user "recipient@somewhere.com"
   menu .main_menu.actions -tearoff 0 -type normal 
   .main_menu.actions add command -label "[trans sendmsg]..." -command \
     "::amsn::ChooseList \"[trans sendmsg]\" online ::amsn::chatUser 1 0"
   .main_menu.actions add command -label "[trans sendmail]..." -command \
     "::amsn::ChooseList \"[trans sendmail]\" both \"launch_mailer\" 1 0"
   .main_menu.actions add command -label "[trans changenick]..." -command cmsn_change_name
   .main_menu.actions add separator
   .main_menu.actions add command -label "[trans checkver]..." -command "check_version"
   

   #Order Contacts By submenu
   menu .order_by -tearoff 0 -type normal 
   .order_by add radio -label "[trans status]" -value 0 \
   	-variable config(orderbygroup) -command "cmsn_draw_online"
   .order_by add radio -label "[trans group]" -value 1 \
   	-variable config(orderbygroup) -command "cmsn_draw_online"

   #Order Groups By submenu
   #Added by Trevor Feeney
   menu .ordergroups_by -tearoff 0 -type normal
   .ordergroups_by add radio -label "[trans reversed]" -value 0 \
   	-variable config(ordergroupsbynormal) -command "cmsn_draw_online"
   .ordergroups_by add radio -label "[trans normal]" -value 1 \
   	-variable config(ordergroupsbynormal) -command "cmsn_draw_online"



   #Tools menu
   menu .main_menu.tools -tearoff 0 -type normal
   .main_menu.tools add command -label "[trans addacontact]..." -command cmsn_draw_addcontact
   .main_menu.tools add cascade -label "[trans admincontacts]" -menu .admin_contacts_menu

   menu .admin_contacts_menu -tearoff 0 -type normal
   .admin_contacts_menu add command -label "[trans delete]..." \
      -command  "::amsn::ChooseList \"[trans delete]\" both ::amsn::deleteUser 0 0"
   .admin_contacts_menu add command -label "[trans properties]..." \
      -command "::amsn::ChooseList \"[trans properties]\" both ::abookGui::showEntry 0 1"

   ::groups::Init .main_menu.tools
   set ::groups::bShowing(online) $config(showonline)
   set ::groups::bShowing(offline) $config(showoffline)

   .main_menu.tools add separator
   .main_menu.tools add cascade -label "[trans ordercontactsby]" \
     -menu .order_by
     
   #Added by Trevor Feeney
   #User to reverese group lists
   .main_menu.tools add cascade -label "[trans ordergroupsby]" \
     -menu .ordergroups_by

   .main_menu.tools add separator
   .main_menu.tools add cascade -label "[trans options]" -menu .options

   #Options menu
   menu .options -tearoff 0 -type normal
   .options add command -label "[trans changenick]..." -state disabled \
      -command cmsn_change_name -state disabled
#   .options add command -label "[trans publishphones]..." -state disabled \
      -command "::abookGui::showEntry $config(login) -edit"
   .options add separator
   .options add cascade -label "[trans preferences]..." -menu .pref_menu
#   .options add command -label "[trans language]..." -command "show_languagechoose"
#   .options add command -label "[trans encoding]..." -command "show_encodingchoose"
#   .options add command -label "[trans choosebasefont]..." -command "choose_basefont"
#   .options add command -label "[trans choosebgcolor]..." -command "choose_theme"
 
   .options add cascade -label "[trans docking]" -menu .dock_menu
   menu .dock_menu -tearoff 0 -type normal
   .dock_menu add radio -label "[trans dockingoff]" -value 0 -variable config(dock) -command "init_dock"
   .dock_menu add radio -label "[trans dockgtk]" -value 1 -variable config(dock) -command "init_dock"
   #.dock_menu add radio -label "[trans dockkde]" -value 2 -variable config(dock) -command "init_dock"

   .options add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable config(sound)
   #Let's disable adverts until it works, it's only problems for know
   set config(adverts) 0
   #.options add checkbutton -label "[trans adverts]" -onvalue 1 -offvalue 0 -variable config(adverts) \
   #-command "msg_box \"[trans mustrestart]\""
#   .options add checkbutton -label "[trans autohotmaillog]" -onvalue 1 -offvalue 0 -variable config(autohotlogin)
#   .options add checkbutton -label "[trans autoidle]" -onvalue 1 -offvalue 0 -variable config(autoidle)
#   .options add checkbutton -label "[trans notifywin]" -onvalue 1 -offvalue 0 -variable config(notifywin)
#   .options add checkbutton -label "[trans startoffline]" -onvalue 1 -offvalue 0 -variable config(startoffline) 
#   .options add checkbutton -label "[trans autoconnect]" -onvalue 1 -offvalue 0 -variable config(autoconnect) 
#   .options add checkbutton -label "[trans chatsmileys]" -onvalue 1 -offvalue 0 -variable config(chatsmileys)
#   .options add checkbutton -label "[trans listsmileys]" -onvalue 1 -offvalue 0 -variable config(listsmileys)
#   .options add checkbutton -label "[trans keepalive]" -onvalue 1 -offvalue 0 -variable config(keepalive) -command "::MSN::TogglePolling"
#   .options add checkbutton -label "[trans keeplog]" -onvalue 1 -offvalue 0 -variable config(keep_logs)
#   .options add checkbutton -label "[trans natip]" -onvalue 1 -offvalue 0 -variable config(natip)
   .options add checkbutton -label "[trans closingdocks]" -onvalue 1 -offvalue 0 -variable config(closingdocks) 

   #Help menu
   menu .main_menu.help -tearoff 0 -type normal

   .main_menu.help add command -label "[trans helpcontents]..." \
      -command "::amsn::showHelpFile HELP [list [trans helpcontents]]"
   .main_menu.help add command -label "FAQ" \
      -command "::amsn::showHelpFile FAQ [list [trans faq]]"
   .main_menu.help add separator
   .main_menu.help add command -label "[trans about]..." -command ::amsn::aboutWindow
   .main_menu.help add command -label "[trans version]..." -command \
     "msg_box \"[trans version]: $version - [trans date]: $date\n$weburl\""


   #image create photo mainback -file [file join ${images_folder} back.gif]

   wm title . "[trans title] - [trans offline]"
   wm command . [concat $argv0 $argv]
   wm group . .
   wm geometry . $config(wingeometry)
   wm iconname . "[trans title]"
   wm iconbitmap . @[file join ${images_folder} amsn.xbm]
   wm iconmask . @[file join ${images_folder} amsnmask.xbm]
   . conf -menu .main_menu

   frame .main -class Amsn -relief flat -background $bgcolor
   frame .main.f -class Amsn -relief flat -background white
   #pack .main -expand true -fill both
   #pack .main.f -expand true  -fill both  -padx 4 -pady 4 -side top

   # Create the Notebook and initialize the page paths. These
   # page paths must be used for adding new widgets to the
   # notebook tabs.
   if {$config(withnotebook)} {
   	notebook:create .main.nb -bgcolor #AABBCC -font sboldf \
		-pappend "Buddies" -pappend "News"
       set pgBuddy [notebook:getpage .main.nb 0]
       set pgNews  [notebook:getpage .main.nb 1]
       pack .main.nb -fill both -expand 1
   } else {
       set pgBuddy .main.f
       set pgNews  ""
       pack .main -fill both -expand true
   	pack .main.f -expand true -fill both -padx 4 -pady 4 -side top
   }
   # End of Notebook Creation/Initialization

   image create photo msndroid -file [file join ${images_folder} msnbot.gif]
   image create photo online -file [file join ${images_folder} online.gif]
   image create photo offline -file [file join ${images_folder} offline.gif]
   image create photo away -file [file join ${images_folder} away.gif]
   image create photo busy -file [file join ${images_folder} busy.gif]

   image create photo bonline -file [file join ${images_folder} bonline.gif]
   image create photo boffline -file [file join ${images_folder} boffline.gif]
   image create photo baway -file [file join ${images_folder} baway.gif]
   image create photo bbusy -file [file join ${images_folder} bbusy.gif]

   image create photo mailbox -file [file join ${images_folder} unread.gif]

   image create photo contract -file [file join ${images_folder} contract.gif]
   image create photo expand -file [file join ${images_folder} expand.gif]

   image create photo globe -file [file join ${images_folder} globe.gif]

   image create photo typingimg -file [file join ${images_folder} typing.gif]
   image create photo miniinfo -file [file join ${images_folder} miniinfo.gif]
   image create photo miniwarning -file [file join ${images_folder} miniwarn.gif]


   image create photo butsmile -file [file join ${images_folder} butsmile.gif]
   image create photo butfont -file [file join ${images_folder} butfont.gif]
   image create photo butblock -file [file join ${images_folder} butblock.gif]

   image create photo fticon -file [file join ${images_folder} fticon.gif]
   image create photo ftreject -file [file join ${images_folder} ftreject.gif]

   image create photo notifico -file [file join ${images_folder} notifico.gif]

   image create photo blocked -file [file join ${images_folder} blocked.gif]

   image create photo colorbar -file [file join ${images_folder} colorbar.gif]

   set barwidth [image width colorbar]
   set barheight [image height colorbar]

   image create photo mainbar -width 1280 -height $barheight
   image create photo notifybar -width 140 -height $barheight

   notifybar copy colorbar -from 0 0 5 $barheight
   notifybar copy colorbar -from 5 0 15 $barheight -to 5 0 64 $barheight
   notifybar copy colorbar -from [expr {$barwidth-125}] 0 $barwidth $barheight -to 64 0 139 $barheight

   image create photo mailbox -file [file join ${images_folder} unread.gif]

   image create photo contract -file [file join ${images_folder} contract.gif]
   image create photo expand -file [file join ${images_folder} expand.gif]

   image create photo bell -file [file join ${images_folder} bell.gif]
   image create photo belloff -file [file join ${images_folder} belloff.gif]


   text $pgBuddy.text -background white -width 30 -height 0 -wrap none \
      -yscrollcommand "$pgBuddy.ys set" -cursor left_ptr -font splainf \
      -selectbackground white -selectborderwidth 0 -exportselection 0 \
      -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0
   scrollbar $pgBuddy.ys -command "$pgBuddy.text yview" -highlightthickness 0 \
      -borderwidth 1 -elementborderwidth 2

   #This shouldn't go here
   if {$config(withproxy)} {

     ::Proxy::Init $config(proxy) "http"
     #::Proxy::Init $config(proxy) $config(proxytype)
     ::Proxy::LoginData $config(proxyauthenticate) $config(proxyuser) $config(proxypass)
   }

   adv_initialize .main

   # This one is not a banner but a branding. When adverts are enabled
   # they share this space with the branding image. The branding image
   # is cycled in between adverts.
   adv_show_banner  file ${images_folder}/logolinmsn.gif

   pack $pgBuddy.ys -side right -fill y -padx 0 -pady 0
   pack $pgBuddy.text -expand true -fill both -padx 0 -pady 0

   bind . <Control-s> toggle_status

   wm protocol . WM_DELETE_WINDOW {::amsn::closeOrDock $config(closingdocks)}

   cmsn_draw_status
   cmsn_draw_offline

   status_log "Proxy is : $config(proxy)\n"

}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc change_myfont {win_name} {
  global config

  set fontsize [expr {[lindex $config(basefont) end-1] + $config(textsize)}]
  set fontcolor [lindex $config(mychatfont) 2]

  set selfont [tk_chooseFont -title [trans choosefont] -initialfont "\{[lindex $config(mychatfont) 0]\} $fontsize \{[lindex $config(mychatfont) 1]\}"]

  if { [string length $selfont] <1} {
    return
  }

  set config(textsize) [expr {[lindex $selfont 1]- [lindex $config(basefont) 1]}]
  set config(mychatfont) "\{[lindex $selfont 0]\} \{[lindex $selfont 2]\} $fontcolor"

  set color [tk_chooseColor -title "[trans choosefontcolor]" -parent .${win_name} \
    -initialcolor #$fontcolor]

  if { [string length $color] <1} {
    set color $fontcolor
  } else {
    set color [string range $color 1 end]
  }

  set config(mychatfont) [lreplace $config(mychatfont) 2 2 $color]

  status_log "color selected: $color\n"

  change_myfontsize $config(textsize) ${win_name}

}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc change_myfontsize {size name} {
  global config

  set config(textsize) $size

  set fontfamily \{[lindex $config(mychatfont) 0]\}
  set fontstyle \{[lindex $config(mychatfont) 1]\}
  set fontsize [expr {[lindex $config(basefont) end-1]+$config(textsize)}]

  catch {.${name}.f.out.text tag configure yours -font "$fontfamily $fontsize $fontstyle"} res
  catch {.${name}.f.in.input configure -font "$fontfamily $fontsize $fontstyle"} res
  catch {.${name}.f.in.input configure -foreground #[lindex $config(mychatfont) end]} res

  #Get old user font and replace its size
  catch {
     set font [lreplace [.${name}.f.out.text tag cget user -font] 1 1 $fontsize]
     .${name}.f.out.text tag configure user -font $font
  } res
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_msgwin_sendmail {name} {
   upvar #0 [sb name $name users] users_list
   set win_name "msg_[string tolower ${name}]"

   if {[llength $users_list]} {
      set recipient ""
      foreach usrinfo $users_list {
         if { $recipient != "" } {
            set recipient "${recipient}, "
	 }
         set user_login [lindex $usrinfo 0]
         set recipient "${recipient}${user_login}"
      }
   } else {
      set recipient "recipient@somewhere.com"
   }

   launch_mailer $recipient
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc sonido {sound} {
  global config sounds_folder config
  if { $config(sound) == 1 } {
    set archivo [file join $sounds_folder $sound.wav]
    catch {eval exec $config(soundcommand) $archivo &} res
  }
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc choose_basefont { } {
   global config

   set font "[tk_chooseFont -title [trans choosefont] -initialfont $config(basefont)]"

   if { [llength $font] < 2 } {
     return 0
   }

   set family [lindex $font 0]
   set size [lindex $font 1]

   set newfont "\"$family\" $size normal"

   if { $newfont != $config(basefont)} {
      set config(basefont) $newfont
      msg_box [trans mustrestart]
   }

}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc show_languagechoose {} {
   global lang_list

   set languages [list]

   for {set i 0} {$i < [llength $lang_list]} {incr i} {
     set langelem [lindex $lang_list $i]
     set langshort [lindex $langelem 0]
     set langlong [lindex $langelem 1]
     lappend languages [list $langshort "$langlong"]
     #-command "set config(language) $langshort; load_lang;msg_box \"\[trans mustrestart\]\""
   }

  ::amsn::ChooseList "[trans language]" both "set_language" 0 1 $languages
}
#///////////////////////////////////////////////////////////////////////


proc set_language { langname } {
   global config
   set config(language) $langname
   load_lang
   msg_box [trans mustrestart]
}


#///////////////////////////////////////////////////////////////////////
proc show_encodingchoose {} {
  set encodings [encoding names]
  set encodings [lsort $encodings]
  set enclist [list]
  foreach enc $encodings {
	 lappend enclist [list $enc "" 0]
  }
  set enclist [linsert $enclist 0 [list auto "Automatic" 0]]
  ::amsn::ChooseList "[trans encoding]" both set_encoding 0 1 $enclist
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc set_encoding {enc} {
  global config
  if {[catch {encoding system $enc} res]} {
     msg_box "Selected encoding not available, selecting auto"
     set config(encoding) auto
  } else {
     set config(encoding) $enc
  }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_status {} {
   toplevel .status
   wm group .status .
   wm state .status withdrawn
   wm title .status "status log - [trans title]"

   text .status.info -background white -width 60 -height 30 -wrap word \
      -yscrollcommand ".status.ys set" -font splainf
   scrollbar .status.ys -command ".status.info yview"
   entry .status.enter -background white

   pack .status.enter -side bottom -fill x
   pack .status.ys -side right -fill y
   pack .status.info -expand true -fill both

   .status.info tag configure green -foreground darkgreen -background white
   .status.info tag configure red -foreground red -background white
   .status.info tag configure white -foreground white -background black
   .status.info tag configure blue -foreground blue -background white

   bind .status.enter <Return> ns_enter
   wm protocol .status WM_DELETE_WINDOW { toggle_status }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_offline {} {

   global sboldf config password pgBuddy

   bind $pgBuddy.text <Configure>  ""

   wm title . "[trans title] - [trans offline]"

   $pgBuddy.text configure -state normal
   $pgBuddy.text delete 0.0 end

   #Iniciar sesion

   $pgBuddy.text tag conf check_ver -fore #777777 -underline true \
   -font splainf -justify left
   $pgBuddy.text tag bind check_ver <Enter> \
	    "$pgBuddy.text tag conf check_ver -fore #0000A0 -underline false;\
	    $pgBuddy.text conf -cursor hand2"
   $pgBuddy.text tag bind check_ver <Leave> \
	    "$pgBuddy.text tag conf check_ver -fore #000000 -underline true;\
	    $pgBuddy.text conf -cursor left_ptr"
   $pgBuddy.text tag bind check_ver <Button1-ButtonRelease> \
	    "check_version"

   $pgBuddy.text tag conf lang_sel -fore #777777 -underline true \
   -font splainf -justify left
   $pgBuddy.text tag bind lang_sel <Enter> \
	    "$pgBuddy.text tag conf lang_sel -fore #0000A0 -underline false;\
	    $pgBuddy.text conf -cursor hand2"
   $pgBuddy.text tag bind lang_sel <Leave> \
	    "$pgBuddy.text tag conf lang_sel -fore #000000 -underline true;\
	    $pgBuddy.text conf -cursor left_ptr"
   $pgBuddy.text tag bind lang_sel <Button1-ButtonRelease> \
	    "show_languagechoose"


   $pgBuddy.text tag conf start_login -fore #000000 -underline true \
      -font sboldf -justify center
   $pgBuddy.text tag bind start_login <Enter> \
	    "$pgBuddy.text tag conf start_login -fore #0000A0 -underline false;\
	    $pgBuddy.text conf -cursor hand2"
   $pgBuddy.text tag bind start_login <Leave> \
	    "$pgBuddy.text tag conf start_login -fore #000000 -underline true;\
	    $pgBuddy.text conf -cursor left_ptr"
    $pgBuddy.text tag bind start_login <Button1-ButtonRelease> \
        "::MSN::connect [list $config(login)] [list $password]"


   $pgBuddy.text tag conf start_loginas -fore #000000 -underline true \
   -font sboldf -justify center
   $pgBuddy.text tag bind start_loginas <Enter> \
	    "$pgBuddy.text tag conf start_loginas -fore #0000A0 -underline false;\
	    $pgBuddy.text conf -cursor hand2"
   $pgBuddy.text tag bind start_loginas <Leave> \
	    "$pgBuddy.text tag conf start_loginas -fore #000000 -underline true;\
	    $pgBuddy.text conf -cursor left_ptr"
    $pgBuddy.text tag bind start_loginas <Button1-ButtonRelease> \
        "cmsn_draw_login"

   $pgBuddy.text image create end -image globe -pady 5 -padx 5
   $pgBuddy.text insert end "[trans language]\n" lang_sel



   $pgBuddy.text insert end "\n\n\n\n"

   if { $config(login) != ""} {
     if { $password != "" } {
        $pgBuddy.text insert end "$config(login)\n" start_login
        $pgBuddy.text insert end "[trans clicktologin]" start_login
     } else {
     	$pgBuddy.text insert end "$config(login)\n" start_loginas
        $pgBuddy.text insert end "[trans clicktologin]" start_loginas
     }

     #$pgBuddy.text tag bind start_login <Button1-ButtonRelease> \
	#"::MSN::connect $config(login) $password"

     $pgBuddy.text insert end "\n\n\n\n\n"

     $pgBuddy.text insert end "[trans loginas]...\n" start_loginas
     $pgBuddy.text insert end "\n\n\n\n\n\n\n\n\n"

   } else {
     $pgBuddy.text insert end "[trans clicktologin]..." start_loginas

     $pgBuddy.text insert end "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

   }


   $pgBuddy.text insert end "   "
   $pgBuddy.text insert end "[trans checkver]...\n" check_ver
   
   $pgBuddy.text configure -state disabled


   #Log in
   .main_menu.file entryconfigure 0 -state normal
   .main_menu.file entryconfigure 1 -state normal
   #Log out
   .main_menu.file entryconfigure 2 -state disabled
   #My status
   .main_menu.file entryconfigure 3 -state disabled
   #Add a contact
   .main_menu.tools entryconfigure 0 -state disabled
   .main_menu.tools entryconfigure 1 -state disabled
   .main_menu.tools entryconfigure 4 -state disabled
   #Added by Trevor Feeney
   #Disables Group Order menu
   .main_menu.tools entryconfigure 5 -state disabled
   

   #Change nick
   configureMenuEntry .main_menu.actions "[trans changenick]..." disabled
   configureMenuEntry .options "[trans changenick]..." disabled

   configureMenuEntry .main_menu.actions "[trans sendmail]..." disabled
   configureMenuEntry .main_menu.actions "[trans sendmsg]..." disabled

   configureMenuEntry .main_menu.file "[trans savecontacts]..." disabled

   #Publish Phone Numbers
#   configureMenuEntry .options "[trans publishphones]..." disabled

   #Initialise Preferences if window is open
   if { [winfo exists .cfg] } {
   	InitPref
   }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
# TODO: Animate login
proc cmsn_draw_signin {} {
    global config pgBuddy

   wm title . "[trans title] - $config(login)"

   $pgBuddy.text configure -state normal -font splainf
   $pgBuddy.text delete 0.0 end
   $pgBuddy.text tag conf signin -fore #000000 \
   -font sboldf -justify center
   $pgBuddy.text insert end "\n\n\n\n\n\n\n"
   $pgBuddy.text insert end "[trans loggingin]..." signin
   $pgBuddy.text insert end "\n"
   $pgBuddy.text configure -state disabled
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc login_ok {} {
   global config password proftrig

   set config(login) [.login.c.signin get]
   set password [.login.c.password get]
   grab release .login
   destroy .login

   if { $proftrig == 1 } {
   	NewProfileAsk $config(login)
	vwait proftrig
   }
   
   SaveLoginList
  if { $password != "" && $config(login) != "" } {
	::MSN::connect [list $config(login)] [list $password]
  } else {
  	cmsn_draw_login
  }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_login {} {
   global config password proftrig

   set proftrig 0

   if {[winfo exists .login]} {
      raise .login
      return 0
   }

   LoadLoginList 1

   set oldlogin $config(login)
   toplevel .login
   wm group .login .
   
   wm geometry .login
   wm title .login "[trans login] - [trans title]"
   wm transient .login .
   frame .login.c -relief flat -highlightthickness 0
   pack .login.c -expand true -fill both -padx 10 -pady 10

   label .login.c.user -text "[trans user]: " -font sboldf
   combobox::combobox .login.c.signin \
	    -editable true \
	    -highlightthickness 0 \
	    -width 25 \
	    -bg #FFFFFF \
	    -font splainf \
	    -command ConfigChange
   label .login.c.example -text "[trans examples] :\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com" -font examplef

   grid .login.c.user -row 2 -column 2 -sticky w
   grid .login.c.signin -row 2 -column 3 -sticky w
   grid .login.c.example -rowspan 3 -row 2 -column 4 -sticky n
   # Lets fill our combobox
   .login.c.signin insert 0 $config(login)
   set idx 0
   set tmp_list ""
   while { [LoginList get $idx] != 0 } {
	lappend tmp_list [LoginList get $idx]
	incr idx
   }
   eval .login.c.signin list insert end $tmp_list
   unset idx
   unset tmp_list

   label .login.c.lpass -text "[trans pass]: " -font sboldf
   entry .login.c.password -width 25 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -show "*"
   checkbutton .login.c.remember -variable config(save_password) \
      -text "[trans rememberpass]" -font splainf -highlightthickness 0 -pady 5
   checkbutton .login.c.offline -variable config(startoffline) \
      -text "[trans startoffline]" -font splainf -highlightthickness 0 -pady 5
   
   grid .login.c.lpass -row 3 -column 2 -sticky w
   grid .login.c.password -row 3 -column 3 -sticky w
   grid .login.c.remember -row 4 -column 3 -sticky ws
   grid .login.c.offline -row 4 -column 2 -sticky wn
   .login.c.password insert 0 $password	

   button .login.c.ok -text [trans ok] -command login_ok  -font sboldf
   button .login.c.cancel -text [trans cancel] -command "grab release .login; ConfigChange .login $oldlogin; destroy .login" -font sboldf

   
   grid .login.c.ok -row 5 -column 3 -sticky e -padx 5
   grid .login.c.cancel -row 5 -column 4 -sticky w -padx 5
   
   if { [info exists config(login)] == 0 } {
	focus .login.c.signin
   } else {
	if { $config(save_password) == 0 } {
	   focus .login.c.password
        } else {
           focus .login.c.ok
        }
   }

   bind .login.c.password <Return> "login_ok; break"
   bind .login <Escape> "grab release .login;ConfigChange .login $oldlogin; destroy .login"
   bind .login <Return> "login_ok; break"
   bind .login <Destroy> "if \{ \[grab status .login\] == \"local\" \} \{ConfigChange .login $oldlogin\}"

   tkwait visibility .login
   grab set .login
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////////////
# NewProfileAsk ()
# Asks user if he would like to create a new profile when he enters in a new
# email during login.

proc NewProfileAsk { email } {
	toplevel .loginask
	wm group .loginask .
	wm title .loginask "[trans login]"
   	frame .loginask.c -relief flat -highlightthickness 0
   	pack .loginask.c -expand true -fill both -padx 10 -pady 0

	label .loginask.c.txt -text "[trans askprofile $email]"
	grid .loginask.c.txt -row 1 -column 1 -sticky w -pady 10

	button .loginask.c.ok -text [trans cprofile] -command "grab release .loginask; destroy .loginask; CreateProfile $email 1"
	button .loginask.c.cancel -text [trans dcprofile] -command "grab release .loginask; destroy .loginask; CreateProfile $email 0"
   
   	grid .loginask.c.ok -row 2 -column 1 -pady 10
  	grid .loginask.c.cancel -row 2 -column 1 -pady 5 -sticky e

	bind .loginask <Destroy> "if \{ \[grab status .loginask\] == \"local\" \} \{ CreateProfile $email 0\}"
	tkwait visibility .loginask
	grab set .loginask
}


#///////////////////////////////////////////////////////////////////////
proc toggleGroup {tw name image id {padx 0} {pady 0}} {
   label $tw.$name -image $image
   $tw.$name configure -cursor hand2 -borderwidth 0
   bind $tw.$name <Button1-ButtonRelease> "::groups::ToggleStatus $id; cmsn_draw_online"
   $tw window create end -window $tw.$name -padx $padx -pady $pady
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
proc clickableImage {tw name image command {padx 0} {pady 0}} {
   label $tw.$name -image $image -background white
   $tw.$name configure -cursor hand2 -borderwidth 0
   bind $tw.$name <Button1-ButtonRelease> $command
   $tw window create end -window $tw.$name -padx $padx -pady $pady -align center -stretch true
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# TODO: move into ::amsn namespace, and maybe improve it
proc cmsn_draw_online {} {
   global emotions user_stat login list_users list_states user_info list_bl\
    config showonline password pgBuddy bgcolor

   set my_name [urldecode [lindex $user_info 4]]
   set my_state_no [lsearch $list_states "$user_stat *"]
   set my_state [lindex $list_states $my_state_no]
   set my_state_desc [trans [lindex $my_state 1]]
   set my_colour [lindex $my_state 2]
   set my_image_type [lindex $my_state 5]

   # Decide which grouping we are going to use
   if {$config(orderbygroup)} {
       #Reverse group lists to match true MSN
       #Added by Trevor Feeney
       if {$config(ordergroupsbynormal)} {
           set glist [lsort [::groups::GetList]]
       } else {
           set glist [lsort -decreasing [::groups::GetList]]
       }
       
       #set glist [lsort [::groups::GetList]]
       
       set gcnt [llength $glist]
       # Now setup each of the group's defaults
       for {set i 0} {$i < $gcnt} {incr i} {
	   set gid [lindex $glist $i]
	   ::groups::UpdateCount $gid clear
	   #set ::groups::uMemberCnt($gid) 0
	   #set ::groups::uMemberCnt_online($gid) 0
       }
   } else {	# Order by Online/Offline
       # Defaults already set in setup_groups
       set glist [list online offline]
       set gcnt 2
   }

   $pgBuddy.text configure -state normal -font splainf
   $pgBuddy.text delete 0.0 end


   $pgBuddy.text tag conf mail -fore black -underline true -font splainf
   $pgBuddy.text tag bind mail <Button1-ButtonRelease> "hotmail_login $config(login) $password"
   $pgBuddy.text tag bind mail <Enter> \
   	"$pgBuddy.text tag conf mail -under false;$pgBuddy.text conf -cursor hand2"
   $pgBuddy.text tag bind mail <Leave> \
   	"$pgBuddy.text tag conf mail -under true;$pgBuddy.text conf -cursor left_ptr"

   # Configure bindings/tags for each named group in our scheme
   for {set gidx 0} {$gidx < $gcnt} {incr gidx} {
       set gname [lindex $glist $gidx]
       if {$gname != "online" && $gname != "offline"} {
           set gtag  "tg$gname"
       } else {
           set gtag $gname
       }
       $pgBuddy.text tag conf $gtag -fore #000080 -font sboldf
       $pgBuddy.text tag bind $gtag <Button1-ButtonRelease> \
	 "::groups::ToggleStatus $gname;cmsn_draw_online"
       $pgBuddy.text tag bind $gtag <Enter> \
	    "$pgBuddy.text tag conf $gtag -under true;$pgBuddy.text conf -cursor hand2"
       $pgBuddy.text tag bind $gtag <Leave> \
	    "$pgBuddy.text tag conf $gtag -under false;$pgBuddy.text conf -cursor left_ptr"

   }

   $pgBuddy.text insert end "\n"

   # Display MSN logo with user's handle. Make it clickable so
   # that the user can change his/her status that way
   clickableImage $pgBuddy.text bigstate $my_image_type {tk_popup .my_menu %X %Y}
   bind $pgBuddy.text.bigstate <Button3-ButtonRelease> {tk_popup .my_menu %X %Y}


   text $pgBuddy.text.mystatus -font bboldf -height 2 -width 100 -background white -borderwidth 0 \
      -relief flat -highlightthickness 0 -selectbackground white -selectborderwidth 0 \
       -exportselection 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0

   $pgBuddy.text.mystatus configure -state normal

   $pgBuddy.text.mystatus tag conf mystatuslabel -fore gray -underline false \
     -font splainf

   $pgBuddy.text.mystatus tag conf mystatus -fore $my_colour -underline false \
     -font bboldf

    $pgBuddy.text.mystatus tag bind mystatus <Enter> \
      "$pgBuddy.text.mystatus tag conf mystatus -under true;$pgBuddy.text.mystatus conf -cursor hand2"

    $pgBuddy.text.mystatus tag bind mystatus <Leave> \
      "$pgBuddy.text.mystatus tag conf mystatus -under false;$pgBuddy.text.mystatus conf -cursor left_ptr"

   $pgBuddy.text.mystatus tag bind mystatus <Button1-ButtonRelease> "tk_popup .my_menu %X %Y"
   $pgBuddy.text.mystatus tag bind mystatus <Button3-ButtonRelease> "tk_popup .my_menu %X %Y"


   $pgBuddy.text.mystatus insert end "[trans mystatus]:\n" mystatuslabel
   $pgBuddy.text.mystatus insert end "$my_name " mystatus
   $pgBuddy.text.mystatus insert end "($my_state_desc)" mystatus


   $pgBuddy.text.mystatus configure -state disabled
   $pgBuddy.text window create end -window $pgBuddy.text.mystatus -padx 6 -pady 0 -align bottom -stretch false

   $pgBuddy.text insert end "\n"

   #set width [expr {[winfo width $pgBuddy.text] - 10} ]
   set width [expr {[winfo width $pgBuddy.text]} -1 ]

   if { $width < 160 } {
       set width 160
   }

   set barheight [image height colorbar]
   set barwidth [image width colorbar]

   mainbar blank
   mainbar copy colorbar -from 0 0 5 $barheight
   mainbar copy colorbar -from 5 0 15 $barheight -to 5 0 [expr {$width - 150}] $barheight
   mainbar copy colorbar -from [expr {$barwidth - 150}] 0 $barwidth $barheight -to [expr {$width - 150}] 0 $width $barheight

   $pgBuddy.text image create end -image mainbar
   $pgBuddy.text insert end "\n"

   # Show Mail Notification status
   clickableImage $pgBuddy.text mailbox mailbox {hotmail_login $config(login) $password} 5 0

   set unread [::hotmail::unreadMessages]

   if { $unread == 0 } {
      $pgBuddy.text insert end "[trans nonewmail]\n" mail
   } elseif {$unread == 1} {
      $pgBuddy.text insert end "[trans onenewmail]\n" mail
   } else {
      $pgBuddy.text insert end "[trans newmail $unread]\n" mail
   }

#end AIM

   $pgBuddy.text insert end "\n"
   # For each named group setup its heading where >><< image
   # appears together with the group name and total nr. of handles
   # [<<] My Group Name (n)
   for {set gidx 0} {$gidx < $gcnt} {incr gidx} {

       set gname [lindex $glist $gidx]
       set gtag  "tg$gname"
       if { [::groups::IsExpanded $gname] } {
	   toggleGroup $pgBuddy.text contract$gname contract $gname 5 0
       } else {
	   toggleGroup $pgBuddy.text expand$gname expand $gname 5 0
       }

       # Show the group's name/title
       if {$config(orderbygroup)} {

           # For user defined groups we don't have/need translations
	   set gtitle [::groups::GetName $gname]
           $pgBuddy.text insert end $gtitle $gtag

       } else {

	    if {$gname == "online"} {
	        $pgBuddy.text insert end "[trans uonline]" online
	    } else {
	        $pgBuddy.text insert end "[trans uoffline]" offline
	    }

       }
       $pgBuddy.text insert end "\n"

   }

   ::groups::UpdateCount online clear
   ::groups::UpdateCount offline clear

   foreach user $list_users {
      set user_login [lindex $user 0]
      set user_name [lindex $user 1]
      set user_state_no [lindex $user 2]
      set state [lindex $list_states $user_state_no]
      set state_code [lindex $state 0]

      set colour [lindex $state 2]
      set section [lindex $state 3]; # Used in online/offline grouping

      if { $section == "online"} {
	   ::groups::UpdateCount online +1
      } elseif {$section == "offline"} {
	   ::groups::UpdateCount offline +1
      }


      # Rename the section if we order by group
      set user_group [::abook::getGroup $user_login -id]
      if {$config(orderbygroup)} {


          set section $user_group
	  set section "tg$section"
	  #::groups::UpdateCount $user_group +1
	  ::groups::UpdateCount $user_group +1 [lindex $state 3]

      }

      # Check if the group/section is expanded, display accordingly
      if {$config(orderbygroup)} {
	  set myGroupExpanded [::groups::IsExpanded $user_group]
      } else {
	  set myGroupExpanded [::groups::IsExpanded $section]
      }

      if {$myGroupExpanded} {
	  ShowUser $user_name $user_login $state $state_code $colour $section
      }
   }

   if {$config(listsmileys)} {
     smile_subst $pgBuddy.text
   }

   if {$config(orderbygroup)} {
        for {set gidx 0} {$gidx < $gcnt} {incr gidx} {
	    set gname [lindex $glist $gidx]
	    set gtag  "tg$gname"
	   #$pgBuddy.text insert $gtag.last " ($::groups::uMemberCnt($gname))\n" $gtag
	   $pgBuddy.text insert $gtag.last \
	      " ($::groups::uMemberCnt_online(${gname})/$::groups::uMemberCnt($gname))\n" $gtag
 	}
   } else {
       $pgBuddy.text insert online.last " ($::groups::uMemberCnt(online))\n" online
       $pgBuddy.text insert offline.last " ($::groups::uMemberCnt(offline))\n" offline
   }

   $pgBuddy.text configure -state disabled

   bind $pgBuddy.text <Configure>  "after cancel cmsn_draw_online; after 100 cmsn_draw_online"

   #Init Preferences if window is open
   if { [winfo exists .cfg] } {
   	InitPref
   }

}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc ShowUser {user_name user_login state state_code colour section} {
    global list_bl list_rl pgBuddy alarms

         if {($state_code != "NLN") && ($state_code !="FLN")} {
            set state_desc " ([trans [lindex $state 1]])"
	 } else {
            set state_desc ""
         }

	 # If user is not in the Reverse List it means (s)he has not
	 # yet added/approved us. Show their name in yellow. A way
	 # of knowing how has a) not approved you yet, or b) has
	 # removed you from their contact list even if you still
	 # have them...
         if {[lsearch $list_rl "$user_login *"] == -1} {
	     set colour #FF00FF
	 }

         set image_type [lindex $state 4]
         if {[lsearch $list_bl "$user_login *"] != -1} {
            set image_type "blocked"
      	    if {$state_desc == ""} {set state_desc " ([trans blocked])"}
         }
           $pgBuddy.text tag conf $user_login -fore $colour


         $pgBuddy.text mark set new_text_start end
         $pgBuddy.text insert $section.last " $user_name$state_desc \n" $user_login

	 set imgname "img[expr {$::groups::uMemberCnt(online)+$::groups::uMemberCnt(offline)}]"
         label $pgBuddy.text.$imgname -image $image_type
         $pgBuddy.text.$imgname configure -cursor hand2 -borderwidth 0
         $pgBuddy.text window create $section.last -window $pgBuddy.text.$imgname -padx 3 -pady 1

#	Draw alarm icon if alarm is set
	if { [info exists alarms(${user_login})] } {
	    set imagee [string range [string tolower $user_login] 0 end-8] ;#trying to make it non repetitive without the . in it

	    if { $alarms(${user_login}) == 1 } {
  	 	label $pgBuddy.text.$imagee -image bell
 	    } else {
		label $pgBuddy.text.$imagee -image belloff
            }

	    $pgBuddy.text.$imagee configure -cursor hand2 -borderwidth 0 
            $pgBuddy.text window create $section.last -window $pgBuddy.text.$imagee  -padx 1 -pady 1
	    bind $pgBuddy.text.$imagee <Button1-ButtonRelease> "switch_alarm $user_login $pgBuddy.text.$imagee"
	    bind $pgBuddy.text.$imagee <Button3-ButtonRelease> "alarm_cfg $user_login"
	
	} else {
	    $pgBuddy.text insert $section.last "      "
	}
		

         $pgBuddy.text tag bind $user_login <Enter> \
             "$pgBuddy.text tag conf $user_login -under true;$pgBuddy.text conf -cursor hand2"
         $pgBuddy.text tag bind $user_login <Leave> \
            "$pgBuddy.text tag conf $user_login -under false;$pgBuddy.text conf -cursor left_ptr"

         $pgBuddy.text tag bind $user_login <Button3-ButtonRelease> "show_umenu $user_login %X %Y"
          bind $pgBuddy.text.$imgname <Button3-ButtonRelease> "show_umenu $user_login %X %Y"

         if { $state_code !="FLN" } {
            bind $pgBuddy.text.$imgname <Double-Button-1> "::amsn::chatUser $user_login"
            $pgBuddy.text tag bind $user_login <Double-Button-1> \
	        "::amsn::chatUser $user_login"
         }
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc copy { cut window } {
	clipboard clear
	catch { clipboard append [selection get] }
	if { $cut == "1" } { catch { .$window.f.in.input delete sel.first sel.last } }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc paste { window } {
	catch { set contents [ selection get -selection CLIPBOARD ] }
    	catch { set point [ .$window.f.in.input index insert ] }
    	catch { .$window.f.in.input insert $point $contents }
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_addcontact {} {
   global addcontact_request lang

   if {[info exists addcontact_request]} {
      raise .addcontact
      return 0
   }

   set addcontact_request true
   toplevel .addcontact -width 400 -height 150
   wm group .addcontact .
   bind .addcontact <Destroy> {
      if {"%W" == ".addcontact"} {
         unset addcontact_request
      }
   }

#   wm geometry .addcontact -0+100
   wm title .addcontact "[trans addacontact] - [trans title]"
#   wm transient .addcontact .
   canvas .addcontact.c -width 320 -height 160
   pack .addcontact.c -expand true -fill both

   entry .addcontact.c.email -width 30 -bg #FFFFFF -bd 1 \
      -font splainf
   button .addcontact.c.next -text "[trans next]->" \
     -command addcontact_next -font sboldf
   button .addcontact.c.cancel -text [trans cancel]  \
      -command "grab release .addcontact;destroy .addcontact" -font sboldf

   .addcontact.c create text 5 10 -font sboldf -anchor nw \
	-text "[trans entercontactemail]:"
   .addcontact.c create text 80 60 -font examplef -anchor ne \
         -text "[trans examples]: "
   .addcontact.c create text 80 60 -font examplef -anchor nw \
         -text "copypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com"
   .addcontact.c create window 5 35 -window .addcontact.c.email -anchor nw
   .addcontact.c create window 195 120 -window .addcontact.c.next -anchor ne
   .addcontact.c create window 205 120 -window .addcontact.c.cancel -anchor nw

   bind .addcontact.c.email <Return> "addcontact_next"
   focus .addcontact.c.email

#   tkwait visibility .addcontact
#   grab set .addcontact
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc addcontact_next {} {
   set tmp_email [.addcontact.c.email get]
   if { $tmp_email != ""} {
      ::MSN::addUser "$tmp_email"
      grab release .addcontact
      destroy .addcontact
   }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_otherwindow { title command } {

##hehe, here it's, nearly done ;)

   global lang

   toplevel .otherwindow -width 300 -height 100
   wm group .otherwindow .

   wm title .otherwindow "$title"
   canvas .otherwindow.c -width 270 -height 100
   pack .otherwindow.c -expand true -fill both

   entry .otherwindow.c.email -width 30 -bg #FFFFFF -bd 1 \
      -font splainf
   button .otherwindow.c.next -text "[trans ok]" \
     -command "run_command_otherwindow \"$command\"" -font sboldf
   button .otherwindow.c.cancel -text [trans cancel]  \
      -command "grab release .otherwindow;destroy .otherwindow" -font sboldf

   .otherwindow.c create text 5 10 -font sboldf -anchor nw \
	-text "[trans entercontactemail]:"
   .otherwindow.c create window 5 35 -window .otherwindow.c.email -anchor nw
   .otherwindow.c create window 163 65 -window .otherwindow.c.next -anchor ne
   .otherwindow.c create window 173 65 -window .otherwindow.c.cancel -anchor nw

   bind .otherwindow.c.email <Return> "run_command_otherwindow \"$command\""
   focus .otherwindow.c.email

   tkwait visibility .otherwindow
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_proxy {} {
   global configuring_proxy config

   if {[info exists configuring_proxy]} {
      raise .proxy_conf
      return 0
   }

   set configuring_proxy true
   toplevel .proxy_conf -width 400 -height 150
   wm group .proxy_conf .
   bind .proxy_conf <Destroy> {
      if {"%W" == ".proxy_conf"} {
         unset configuring_proxy
      }
   }

   wm geometry .proxy_conf -0+100
   wm title .proxy_conf "[trans proxyconf] - [trans title]"
   wm transient .proxy_conf .
   canvas .proxy_conf.c -width 400 -height 150 
   pack .proxy_conf.c -expand true -fill both

   checkbutton .proxy_conf.c.enable -relief flat -text [trans enableproxy] \
   	-variable config(withproxy)
   entry .proxy_conf.c.server -width 20 -bg #FFFFFF -bd 1 \
      -font splainf
   entry .proxy_conf.c.port -width 5 -bg #FFFFFF -bd 1 \
      -font splainf
   button .proxy_conf.c.ok -text [trans ok] -command proxy_conf_ok
   button .proxy_conf.c.cancel -text [trans cancel] \
      -command "grab release .proxy_conf;destroy .proxy_conf"

   .proxy_conf.c create text 200 15 -font bigfont -anchor center \
	-text "[trans proxyconfhttp]"
   .proxy_conf.c create text 133 35 -font sboldf -anchor ne \
	-text "[trans server]: "
   .proxy_conf.c create text 133 60 -font sboldf -anchor ne \
	-text "[trans port]: "
   .proxy_conf.c create text 133 105 -font splainf -anchor nw \
	-text "[trans blankdirect]"
   .proxy_conf.c create window 133 35 -window .proxy_conf.c.server -anchor nw
   .proxy_conf.c create window 133 60 -window .proxy_conf.c.port -anchor nw
   .proxy_conf.c create window 133 80 -window .proxy_conf.c.enable -anchor nw
   .proxy_conf.c create window 195 120 -window .proxy_conf.c.ok -anchor ne
   .proxy_conf.c create window 205 120 -window .proxy_conf.c.cancel -anchor nw

   set proxy_data [split $config(proxy) ":"]
   .proxy_conf.c.server insert 0 [lindex $proxy_data 0]
   .proxy_conf.c.port insert 0 [lindex $proxy_data 1]

   tkwait visibility .proxy_conf
   grab set .proxy_conf
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc newcontact {new_login new_name} {
   global newc_allow_block newc_add_to_list newc_exit list_fl

   set newc_allow_block "allow"
   set newc_exit ""

   if {[lsearch $list_fl "$new_login *"] != -1} {
      set add_stat "disabled"
      set newc_add_to_list 0
   } else {
      set add_stat "normal"
      set newc_add_to_list 1
   }
   toplevel .newc
   wm group .newc .

   wm geometry .newc -0+100
   wm title .newc "$new_name - [trans title]"
   wm transient .newc .
   canvas .newc.c -width 500 -height 150
   pack .newc.c -expand true -fill both

   button .newc.c.ok -text [trans ok]  \
      -command "set newc_exit OK;grab release .newc;destroy .newc"
   button .newc.c.cancel -text [trans cancel]  \
      -command "grab release .newc;destroy .newc"

  radiobutton .newc.c.allow -variable newc_allow_block \
     -text [trans allowseen] \
      -highlightthickness 0 \
     -activeforeground #FFFFFF -selectcolor #FFFFFF -value allow
  radiobutton .newc.c.block -variable newc_allow_block \
     -text [trans avoidseen] \
      -highlightthickness 0 \
     -activeforeground #FFFFFF -selectcolor #FFFFFF -value block
   checkbutton .newc.c.add -var newc_add_to_list -state $add_stat \
      -text [trans addtoo] \
      -highlightthickness 0 -activeforeground #FFFFFF -selectcolor #FFFFFF


   .newc.c create text 30 5 -font splainf -anchor nw -justify left \
        -text "$new_name ($new_login) [trans addedyou]." \
        -width 460
   .newc.c create text 30 40 -font splainf -anchor nw \
        -text "[trans youwant]:"
   .newc.c create window 40 58 -window .newc.c.allow -anchor nw
   .newc.c create window 40 76 -window .newc.c.block -anchor nw
   .newc.c create window 30 94 -window .newc.c.add -anchor nw
   .newc.c create window 245 120 -window .newc.c.ok -anchor ne
   .newc.c create window 255 120 -window .newc.c.cancel -anchor nw

#   tkwait visibility .newc
#   grab set .newc
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_change_name {} {
   global change_name user_info

   if {[info exists change_name]} {
      raise .change_name
      return 0
   }

   set change_name true
   toplevel .change_name -width 400 -height 150
   wm group .change_name .
   bind .change_name <Destroy> {
      if {"%W" == ".change_name"} {
         unset change_name
      }
   }
   wm geometry .change_name -0+100
   wm title .change_name "[trans changenick] - [trans title]"
   wm transient .change_name .
   canvas .change_name.c -width 300 -height 100
   pack .change_name.c -expand true -fill both

   entry .change_name.c.name -width 40 -bg #FFFFFF -bd 1 \
      -font splainf
   button .change_name.c.ok -text [trans ok] -command change_name_ok
   button .change_name.c.cancel -text [trans cancel] \
      -command "destroy .change_name"

   .change_name.c create text 5 10 -font sboldf -anchor nw \
	-text "[trans enternick]:"
   .change_name.c create window 5 35 -window .change_name.c.name -anchor nw
   .change_name.c create window 195 65 -window .change_name.c.ok -anchor ne
   .change_name.c create window 205 65 -window .change_name.c.cancel -anchor nw

   bind .change_name.c.name <Return> "change_name_ok"

   .change_name.c.name insert 0 [urldecode [lindex $user_info 4]]

   tkwait visibility .change_name
   grab set .change_name
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc change_name_ok {} {
   global config

   set new_name [.change_name.c.name get]
   if {$new_name != ""} {
      ::MSN::changeName $config(login) $new_name
   }
   destroy .change_name
}
#///////////////////////////////////////////////////////////////////////

