#!/usr/bin/wish
#########################################################
# alarm.tcl v 1.0	2002/07/21   BurgerMan
#########################################################



namespace eval ::alarms {
	proc isEnabled { user } {
		return [getAlarmItem $user enabled]
	}

	proc getAlarmItem { user item } {
	
		#We convert the stored data (a list) into an array
		array set alarms [::abook::getContactData $user alarms]
		
		if { [info exists alarms($item)] } {
			return $alarms($item)
		} else {
			return ""
		}
	}
	
	#Function that displays the Alarm configuration for the given user
	proc configDialog { user } {
		global my_alarms
	
		if { [ winfo exists .alarm_cfg ] } {
			return
		}
	
		set my_alarms(${user}_enabled) [getAlarmItem $user enabled]
		set my_alarms(${user}_sound) [getAlarmItem $user sound]
		set my_alarms(${user}_sound_st) [getAlarmItem $user sound_st]
		set my_alarms(${user}_pic) [getAlarmItem $user pic]
		set my_alarms(${user}_pic_st) [getAlarmItem $user pic_st]
		set my_alarms(${user}_loop) [getAlarmItem $user loop]
		set my_alarms(${user}_onconnect) [getAlarmItem $user onconnect]
		set my_alarms(${user}_onmsg) [getAlarmItem $user onmsg]
		set my_alarms(${user}_onstatus) [getAlarmItem $user onstatus]
		set my_alarms(${user}_ondisconnect) [getAlarmItem $user ondisconnect]
		set my_alarms(${user}_command) [getAlarmItem $user command]
		set my_alarms(${user}_oncommand) [getAlarmItem $user oncommand]
	
		toplevel .alarm_cfg
		wm title .alarm_cfg "[trans alarmpref] $user"
		wm iconname .alarm_cfg [trans alarmpref]
	
		label .alarm_cfg.title -text "[trans alarmpref]: $user" -font bboldf
		pack .alarm_cfg.title -side top -padx 15 -pady 15
	
		frame .alarm_cfg.sound1
		LabelEntry .alarm_cfg.sound1.entry "[trans soundfile]" my_alarms(${user}_sound) 30
		button .alarm_cfg.sound1.browse -text [trans browse] -command {fileDialog2 .alarm_cfg .alarm_cfg.sound1.entry.ent open "" } -font sboldf
		pack .alarm_cfg.sound1.entry -side left -expand true -fill x
		pack .alarm_cfg.sound1.browse -side left
		pack .alarm_cfg.sound1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton .alarm_cfg.button -text "[trans soundstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_sound_st) -font splainf
		checkbutton .alarm_cfg.button2 -text "[trans soundloop]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_loop) -font splainf
		pack .alarm_cfg.button -side top -anchor w -expand true -padx 30
		pack .alarm_cfg.button2 -side top -anchor w -expand true -padx 30
	
		frame .alarm_cfg.command1
		LabelEntry .alarm_cfg.command1.entry "[trans command]" my_alarms(${user}_command) 30
		pack .alarm_cfg.command1.entry -side left -expand true -fill x
		pack .alarm_cfg.command1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton .alarm_cfg.buttoncomm -text "[trans commandstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_oncommand) -font splainf
		pack .alarm_cfg.buttoncomm -side top -anchor w -expand true -padx 30
	
		frame .alarm_cfg.pic1
		LabelEntry .alarm_cfg.pic1.entry "[trans picfile]" my_alarms(${user}_pic) 30
		button .alarm_cfg.pic1.browse -text [trans browse] -command {fileDialog2 .alarm_cfg .alarm_cfg.pic1.entry.ent open "" } -font sboldf
		pack .alarm_cfg.pic1.entry -side left -expand true -fill x
		pack .alarm_cfg.pic1.browse -side left
		pack .alarm_cfg.pic1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton .alarm_cfg.buttonpic -text "[trans picstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_pic_st) -font splainf
		pack .alarm_cfg.buttonpic -side top -anchor w -expand true -padx 30
	
		checkbutton .alarm_cfg.alarm -text "[trans alarmstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_enabled) -font splainf
		checkbutton .alarm_cfg.alarmonconnect -text "[trans alarmonconnect]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onconnect) -font splainf
		checkbutton .alarm_cfg.alarmonmsg -text "[trans alarmonmsg]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onmsg) -font splainf
		checkbutton .alarm_cfg.alarmonstatus -text "[trans alarmonstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onstatus) -font splainf
		checkbutton .alarm_cfg.alarmondisconnect -text "[trans alarmondisconnect]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_ondisconnect) -font splainf
	
		pack .alarm_cfg.alarm -side top -anchor w -expand true -padx 30
		pack .alarm_cfg.alarmonconnect -side top -anchor w -expand true -padx 30
		pack .alarm_cfg.alarmonmsg -side top -anchor w -expand true -padx 30
		pack .alarm_cfg.alarmonstatus -side top -anchor w -expand true -padx 30
		pack .alarm_cfg.alarmondisconnect -side top -anchor w -expand true -padx 30
	
		frame .alarm_cfg.b -class Degt
		button .alarm_cfg.b.save -text [trans ok] -command "::alarms::SaveAlarm $user" -font sboldf
		button .alarm_cfg.b.cancel -text [trans close] -command "destroy .alarm_cfg; unset my_alarms" -font sboldf
		button .alarm_cfg.b.delete -text [trans delete] -command "; destroy .alarm_cfg; ::alarms::DeleteAlarm $user" -font sboldf
		pack .alarm_cfg.b.save .alarm_cfg.b.cancel .alarm_cfg.b.delete -side right -padx 10
		pack .alarm_cfg.b -side top -padx 0 -pady 4 -anchor e -expand true -fill both
	}
	
	#Deletes variable settings for current user.
	proc DeleteAlarm { user } {
		global my_alarms

		::abook::setContactData $user alarms ""
		::abook::saveToDisk
		unset my_alarms
		
		cmsn_draw_online
	}

	#Saves alarm settings for current user on OK press.
	proc SaveAlarm { user } {
		global my_alarms 
	
		if { ($my_alarms(${user}_sound_st) == 1) && ([file exists "$my_alarms(${user}_sound)"] == 0) } {
			msg_box [trans invalidsound]
			return
		}
	
		if { ($my_alarms(${user}_pic_st) == 1) } {
			if { ([file exists "$my_alarms(${user}_pic)"] == 0) } {
				msg_box [trans invalidpic]
				return
			} else {
				image create photo joanna -file $my_alarms(${user}_pic)
				if { ([image width joanna] > 1024) && ([image height joanna] > 768) } {
					image delete joanna
					msg_box [trans invalidpicsize]
					return
				}
				image delete joanna
			}
		}
	
		set alarms(enabled) $my_alarms(${user}_enabled)
		set alarms(loop) $my_alarms(${user}_loop)
		set alarms(sound_st) $my_alarms(${user}_sound_st)
		set alarms(pic_st) $my_alarms(${user}_pic_st)
		set alarms(sound) $my_alarms(${user}_sound)
		set alarms(pic) $my_alarms(${user}_pic)
		set alarms(onconnect) $my_alarms(${user}_onconnect)
		set alarms(onmsg) $my_alarms(${user}_onmsg)
		set alarms(onstatus) $my_alarms(${user}_onstatus)
		set alarms(ondisconnect) $my_alarms(${user}_ondisconnect)
		set alarms(command) $my_alarms(${user}_command)
		set alarms(oncommand) $my_alarms(${user}_oncommand)
		
		status_log "alarms: saving alarm for $user\n" blue	
		::abook::setContactData $user alarms [array get alarms]
		::abook::saveToDisk
		
		destroy .alarm_cfg
		cmsn_draw_online
		unset my_alarms
	}
}



# Function that loads all alarm settings (usernames, paths and status) from a
# config file called alarms
#TODO: REMOVE THIS IN FUTURE VERSIONS. Only kept for compatibility!!!
proc load_alarms {} {
	global HOME


	if {([file readable "[file join ${HOME} alarms]"] == 0) ||
	       ([file isfile "[file join ${HOME} alarms]"] == 0)} {
		return 1
	}
	set file_id [open "[file join ${HOME} alarms]" r]

	gets $file_id tmp_data
	if {$tmp_data != "amsn_alarm_version 1"} {	;# config version not supported!
		return 1
	}
	while {[gets $file_id tmp_data] != "-1"} {
		set var_data [split $tmp_data]
		set var_attribute [lindex $var_data 0]
		set var_value [join [lrange $var_data 1 end]]
		set alarms($var_attribute) $var_value			
	}
	close $file_id
	
	#REMOVE OLD VERSION alarms file.Not used anymore
	file delete [file join ${HOME} alarms]
}



#Runs the alarm (sound and pic)
proc run_alarm {user msg} {
	global program_dir config tcl_platform alarm_win_number
	
	if { ![info exists alarm_win_number] } {
		set alarm_win_number 0
	}

	incr alarm_win_number
	set wind_name alarm_${alarm_win_number}

	set command $config(soundcommand)
	set command [string map { "$sound" "" } $command]

	toplevel .${wind_name}
	wm title .${wind_name} "[trans alarm] $user"
	label .${wind_name}.txt -text "$msg"
	pack .${wind_name}.txt
	if { [getAlarmItem ${user} pic_st] == 1 } {
		image create photo joanna -file [getAlarmItem ${user} pic]
		if { ([image width joanna] < 1024) && ([image height joanna] < 768) } {
			label .${wind_name}.jojo -image joanna
			pack .${wind_name}.jojo
		}
	}

	if { [getAlarmItem ${user} oncommand] == 1 } {
		string map [list "\$msg" "$msg" "\\" "\\\\" "\$" "\\\$" "\[" "\\\[" "\]" "\\\]" "\(" "\\\(" "\)" "\\\)" "\{" "\\\}" "\"" "\\\"" "\'" "\\\'" ] [getAlarmItem ${user} command]
		catch { eval exec [getAlarmItem ${user} command] & } res 
	}

	status_log "${wind_name}"
	if { [getAlarmItem ${user} sound_st] == 1 } {
		#need different commands for windows as no kill or bash etc
		if { $tcl_platform(platform) == "windows" } {
			#Some verions of tk don't support this
			catch { wm attributes .${wind_name} -topmost 1 }
			if { [getAlarmItem ${user} loop] == 1 } {
				global stoploopsound
				set stoploopsound 0
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}; set stoploopsound 1"
				pack .${wind_name}.stopmusic -padx 2
				while { $stoploopsound == 0 } {
					update
					after 100
					catch { eval exec "[regsub -all {\\} $command {\\\\}] [regsub -all {/} [getAlarmItem ${user} sound] {\\\\}]" & } res 
					update
				}
			} else {
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}"
				pack .${wind_name}.stopmusic -padx 2
				update
				catch { eval exec "[regsub -all {\\} $command {\\\\}] [regsub -all {/} [getAlarmItem ${user} sound] {\\\\}]" & } res 
			}			
		} else {
			if { [getAlarmItem ${user} loop] == 1 } {
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}; catch { eval exec killall jwakeup } ; catch { eval exec killall -TERM $command }"
				pack .${wind_name}.stopmusic -padx 2
				catch { eval exec ${program_dir}/jwakeup $command [getAlarmItem ${user} sound] & } res
			} else {
				catch { eval exec $command [getAlarmItem ${user} sound] & } res 
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "catch { eval exec killall -TERM $command } res ; destroy .${wind_name}"
				pack .${wind_name}.stopmusic -padx 2
			}
		}
	} else {
		button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}"
		pack .${wind_name}.stopmusic -padx 2
	}
}

# Switches alarm setting from ON/OFF
proc switch_alarm { user icon} {
	#We get the alarms configuration. It's stored as a list, but it's converted to an array
	array set alarms [::abook::getContactData $user alarms]

	if { [info exists alarms(enabled)] && $alarms(enabled) == 1 } {
		set alarms(enabled) 0
	} else {
		set alarms(enabled) 1
	}
	
	#We set the alarms configuration. We can't store an array, so we convert it to a list
	::abook::setContactData $user alarms [array get alarms]
	redraw_alarm_icon $user $icon
}

# Redraws the alarm icon for current user ONLY without redrawing full list of contacts
proc redraw_alarm_icon { user icon } {

	if { [getAlarmItem $user enabled] == 1 } {
		$icon configure -image bell
	} else {
		$icon configure -image belloff
	}
}
