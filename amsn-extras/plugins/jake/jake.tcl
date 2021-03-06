namespace eval ::jake {

global mydir

proc jakeStart { dir } {

	global mydir
	set mydir $dir

	::plugins::RegisterPlugin jake
	::plugins::RegisterEvent jake chat_msg_received answer
	::plugins::RegisterEvent jake ChangeMyState online

	set langdir [file join $mydir "lang"]       
	set lang [::config::getGlobalKey language]    
	load_lang en $langdir                       
	load_lang $lang $langdir                    

	array set ::jake::config {
		botname {jake}                      
		mystate {1}                          
		helptxt {I'm $botname, an AI bot.}  
		nresults {5}                         
	}

	set ::jake::configlist [list \
		[list bool "[trans state]" mystate] \
		[list str "[trans name]" botname] \
		[list str "[trans helptext]" helptxt] \
		[list str "[trans nresults]" nresults] \
	]
}

proc stringDistance {a b} {
	set n [string length $a]
	set m [string length $b]
	for {set i 0} {$i<=$n} {incr i} {set c($i,0) $i}
	for {set j 0} {$j<=$m} {incr j} {set c(0,$j) $j}
	for {set i 1} {$i<=$n} {incr i} {
		for {set j 1} {$j<=$m} {incr j} {
			set x [expr {$c([- $i 1],$j)+1}]
			set y [expr {$c($i,[- $j 1])+1}]
			set z $c([- $i 1],[- $j 1])
			if {[string index $a [- $i 1]]!=[string index $b [- $j 1]]} {
				incr z
			}
			set c($i,$j) [min $x $y $z]
		}
	}
	set c($n,$m)
}

if {[catch {
	package require Tcl 8.5
	namespace path {tcl::mathfunc tcl::mathop}
	}]} then {
	proc min args {lindex [lsort -real $args] 0}
	proc max args {lindex [lsort -real $args] end}
	proc - {p q} {expr {$p-$q}}
}

proc stringSimilarity {a b} {
	set totalLength [string length $a$b]
	max [expr {double($totalLength-2*[stringDistance $a $b])/$totalLength}] 0.0
}

proc rand {m {n 0}} {
	expr {int(($m-$n)*rand()+$n)}
}

proc getPage {url} {
  package require http
  ::http::config -useragent "Monkey cmdline tool (OpenBSD; en)"
  if {[catch {set token [::http::geturl $url]} msg]} {
     return "Error: $msg"
  } else {
     set data [::http::data $token]
  }
  return $data
}

proc answer {event epvar} {
	
	global mydir
	upvar 2 $epvar args
	upvar 2 $args(msg) msg                           
	upvar 2 $args(chatid) chatid                      
	upvar 2 $args(user) user                         
	set me [::abook::getPersonal login]               
	set window [::ChatWindow::For $chatid]            
	set botname $::jake::config(botname)
	set mystate $::jake::config(mystate)
	set nresults $::jake::config(nresults)
	set language [::config::getGlobalKey language]

	if { $user==$me && $msg == "![trans cmdon]" } {   
		set ::jake::config(mystate) 1
		plugins_log jake "Plugin Jake activado!"
		#set first 1
		::amsn::MessageSend $window 0 "$botname: [trans msgon]"
	} elseif { $user==$me && $msg == "![trans cmdoff]" } {
		set ::jake::config(mystate) 0
		plugins_log jake "Plugin Jake desactivado"
		::amsn::MessageSend $window 0 "$botname: [trans msgoff]"
	} elseif { $user!=$me && ($msg == "![trans cmdoff]" || $msg == "![trans cmdon]") } {
		::amsn::MessageSend $window 0 "$botname: [trans msgonoff]"
	} elseif { $msg == "![trans cmdstate]" } {
		if { $mystate == 0 } {
			::amsn::MessageSend $window 0 "$botname: [trans msgoff]"
		} else {
			::amsn::MessageSend $window 0 "$botname: [trans msgon]"
		}
	} elseif { $msg == "![trans cmdhelp]" } {
		::amsn::MessageSend $window 0 "$botname: $::jake::config(helptxt)\n\
		[trans txtcommands]\n\n\
		![trans cmdhelp] - [trans txthelp]\n\
		![trans cmdon] - [trans txtconveron]\n\
		![trans cmdoff] - [trans txtconveroff]\n\
		![trans cmdgoogle] [trans cmdargsgoogle] - [trans txtgoogle]\n\
		![trans cmddefine] [trans cmdargsdefine] - [trans txtdefine]\n\
		![trans cmdhour] - [trans txthour]\n\
		![trans cmddate] - [trans txtdate]\n\
		![trans cmdstate] - [trans txtstate]\n\
		![trans cmdlearn] [trans cmdargslearn] - [trans txtlearn] $botname\n\
		![trans cmdforget] [trans cmdargsforget] - [trans txtforget] $botname\n\
		![trans cmdyoutube] [trans cmdargsyoutube] - [trans txtyoutube]\n\
		![trans cmdexpr] [trans cmdargsexpr] - [trans txtexpr]"
	} elseif { $msg == "![trans cmdhour]" } {
		::amsn::MessageSend $window 0 "$botname: [trans rsphour] [clock format [clock seconds] -format {%H:%M:%S}]"
	} elseif { $msg == "![trans cmddate]" } {
		::amsn::MessageSend $window 0 "$botname: [trans rspdate] [clock format [clock seconds] -format {%d/%m/%Y}]"
	} elseif { [string first "![trans cmdgoogle] " $msg] == 0 } {   
		regsub -all { +} [string range $msg [expr [string length [trans cmdgoogle]] + 2] end] "+" msg     
		set link "http://www.google.com/search?hl="
		append link $language&num=$nresults&q=$msg
		set salida [ getPage $link ]
		if { [string first "Error: " $salida] != 0 } {
			set matches [regexp -all -inline {(<li class=g>.*<a [^>]*>.*</a>)+?} $salida]
			set count 0
			set bool 0
			foreach m $matches {
				regexp {href="([^"]*)[^>]*>(.*)</a>} $m => url title
				regsub -all {/url\?q=} $url "" url
				regsub -all {<em>} $title "" title
				regsub -all {</em>} $title "" title
				regsub -all {<b>} $title "" title
				regsub -all {</b>} $title "" title
				regsub -all {&quot;} $title "" title
				regsub -all {&gt;} $title "" title
				if { $bool == 0 && $count < $nresults } {
					incr count
					append final $count.\ $title " - " $url \n\n
					set bool 1
				} else {
					set bool 0
				}
			}
			::amsn::MessageSend $window 0 "$botname: \n\n$final"
		} else {
			::amns::MessageSend $window 0 "$botname: Error: $salida"
		}
	} elseif { [string first "![trans cmdyoutube] " $msg] == 0 } {   
		regsub -all { +} [string range $msg [expr [string length [trans cmdyoutube]] + 2] end] "+" msg       
		set link "http://www.youtube.com/results?search_type=&search_query="
		append link $msg
		set salida [ getPage $link ]
		if { [string first "Error: " $salida] != 0 } {
			set matches [regexp -all -inline {(<div class="v120WrapperInner">.* src)+?} $salida]
			set count 0
			set bool 0
			foreach m $matches {
				regexp {href="([^"]*).*title="([^"]*)} $m => url title
				regsub -all {/url\?q=} $url "" url
				regsub -all {<em>} $title "" title
				regsub -all {</em>} $title "" title
				regsub -all {<b>} $title "" title
				regsub -all {</b>} $title "" title
				regsub -all {&quot;} $title "" title
				regsub -all {&gt;} $title "" title
				if { $bool == 0 && $count < $nresults } {
					incr count
					append final $count.\ $title " - www.youtube.com" $url \n\n
					set bool 1
				} else {
					set bool 0
				}
			}
			::amsn::MessageSend $window 0 "$botname: \n\n$final"
		} else {
			::amns::MessageSend $window 0 "$botname: Error: $salida"
		}
	} elseif { [string first "![trans cmddefine] " $msg] == 0 } {  
		regsub -all { +} [string range $msg [expr [string length [trans cmddefine]] + 2] end] "+" msg       
		set link "http://www.google.com/search?hl="
		append link $language&q=define:$msg
		set salida [ getPage $link ]
		if { [string first "Error: " $salida] != 0 } {
			set matches [regexp -all -inline {(<li>.*<br><a href=.*><font)+?} $salida]
			set count 0
			set bool 0
			foreach m $matches {
				regexp {<li>([^<]*)(.*)><font} $m => title url
				regsub -all {<br>.*q=} $url "" url
				regsub -all {\"} $url "" url
				regsub -all {<em>} $title "" title
				regsub -all {</em>} $title "" title
				regsub -all {<b>} $title "" title
				regsub -all {</b>} $title "" title
				regsub -all {&quot;} $title "" title
				if { $bool == 0 && $count < $nresults } {
					incr count
					append final $count.\ $title " - " $url \n\n
					set bool 1
				} else {
					set bool 0
				}
			}
			::amsn::MessageSend $window 0 "$botname: \n\n$final"
		} else {
			::amns::MessageSend $window 0 "$botname: Error: $salida"
		}
	} elseif { [string first "![trans cmdlearn] " $msg] == 0 } {   
		set msg [string range $msg [expr [string length [trans cmdlearn]] + 2] end]      
		if { [regexp -- {^"[^"]*" "[^"]*"$} $msg] } {
			set msg [string range $msg 1 end]
			regsub -all {\" \"} $msg ")\" \"" msg
			set fileId [open [file join $::HOME  "diccionario.dic"] "a+"]
			puts $fileId "set \"diccionario($msg"
			close $fileId
			source [file join $::HOME diccionario.dic]
			::amsn::MessageSend $window 0 "$botname: [trans txtregadd] [array size diccionario] [trans txtreg]"
		} else {
			::amsn::MessageSend $window 0 "$botname: [trans cmderror]\n\
				[trans txthelplearn] ![trans cmdlearn] [trans cmdargslearn]"
		}
	} elseif { [string first "![trans cmdforget] " $msg] == 0 } {   
		set msg [string range $msg [expr [string length [trans cmdforget]] + 2] end]      
		if { [regexp -- {^".*"$} $msg] } {
			if { [array exists diccionario] == 0 } {
				source [file join $::HOME diccionario.dic]
			}
			regsub -all {\"} $msg "" msg
			set in [open [file join $::HOME diccionario.dic] r]
			set out [open [file join $::HOME diccionario.dic.tmp] w]
			set i 0
			while { [gets $in line] >= 0 } {
				incr i
				if { [string match "set \"diccionario($msg)\"*" $line] == 0 } {
					puts $out $line
				}
			}
			close $in
			close $out
			file delete -force [file join $::HOME diccionario.dic]
			file rename -force [file join $::HOME diccionario.dic.tmp] [file join $::HOME diccionario.dic]
			array unset diccionario
			source [file join $::HOME diccionario.dic]
			set in [open [file join $::HOME diccionario.dic] r]
			set j 0
			while { [gets $in line] >= 0 } {
				incr j
			}
			::amsn::MessageSend $window 0 "$botname: [trans txtregdel] [expr $i - $j] [trans txtdic]"
		} else {
			::amsn::MessageSend $window 0 "$botname: [trans cmderror]\n\
				[trans txthelpforget] ![cmdforget] [trans cmdargsforget]"
		}
	} elseif { [string first "![trans cmdexpr ]" $msg] == 0 } {
		set msg [string range $msg [expr [string length [trans cmdexpr]] + 2] end]
		if { [string first "[trans cmdhelp]" $msg] == 0 } {
			::amsn::MessageSend $window 0 "$botname: \n\n\
			[trans txtexprhelp]"
		} else {
		::amsn::MessageSend $window 0 "$botname: [trans txtsolution] [expr $msg]"
		}
	} elseif { $mystate == 1 } {
		if { $user != $me } {
			if { [array exists diccionario] == 0 } {
				source [file join $::HOME diccionario.dic]
			}
			set i 1
			foreach index [array names diccionario] {
				if { [expr ([stringSimilarity $msg $index ]) > 0.6] } {
					set respuesta($i) $diccionario($index)
					incr i
				}
			}
			if { $i > 1 } {
				::amsn::MessageSend $window 0 "$botname: $respuesta([rand [array size respuesta] 1])"
			} else {
				if { [rand 5 1] == 1 } {
					::amsn::MessageSend $window 0 "$botname: [trans txtneedhelp]"
				}
			}
		}
	}
}

proc online {event epvar} {
	upvar 2 $epvar args
	set status $args(idx)
	plugins_log "jake" "[trans txtchangestate] $status"
	if { $status == "AWY" } {
		plugins_log "jake" "Plugin Jake [trans txtlogactivated]"
		set ::jake::config(mystate) 1
	}
	if { $status == "NLN" } {
		plugins_log "jake" "Plugin Jake [trans txtlogdesactivated]"
		set ::jake::config(mystate) 0
	}
}

}


