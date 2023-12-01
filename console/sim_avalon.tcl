#!/sw/bin/wish
# -------------------------------------------------------
#
# Nom          : sim_avalon.tcl
#
# Fonction     : Simulateur du bus avalon
#                
# Remarque     : fonctionne avec QuestaSim
#
# Auteur       : Sébastien Masle (basé sur le simulateur MU0 de Bernard Perrin & Jean-Pierre Miceli)
#
# Date         : 13.07.2022
#
# Version      : 1.0
# -------------------------------------------------------

global ProgramName
global ModesEnum Version InstallDir InstallDir_USB
set full 0
set Version 1.0

set redsToolsPath /opt/tools_reds
set Env linux
set debugMode FALSE; # Display debug info

set nbrOfLeds 10
set nbrOfSwitches 10
set nbrOfKeys 4

set period 20

# Load resources
if { [catch {source $redsToolsPath/TCL_TK/Graphical_Elements.tcl} msg1] } {
  puts "Set path for Windows environment"
  set redsToolsPath c:/EDA/tools_reds
  set Env windows
  if { [catch {source $redsToolsPath/TCL_TK/Graphical_Elements.tcl} msg2] } {   
    puts "Cannot load Graphical Elements!"
    }
}

source $redsToolsPath/TCL_TK/StdProc.tcl

# --| dec2bin |---------------------------------------------------------------------------
# --  Transform a decimal value to a binary string. (Max 32-bits)
# --    - value:   The value to be converted
# --    - NbrBits: Number of bit of "value"
# ----------------------------------------------------------------------------------------
proc dec2bin {value {NbrBits 16}} {
    binary scan [binary format I $value] B32 str
    return [string range $str [expr 32-$NbrBits] 31]
}

# # --| bin2dec |---------------------------------------------------------------------------
# # --  Tranform a binary string to an integer
# # --    - NbrBits: Number of bits in the binary string
# # ----------------------------------------------------------------------------------------
proc bin2dec {binString {NbrBits 16}} {
  set result 0
  set max [string length $binString]
  set min [expr $max - $NbrBits]
  for {set j $min} {$j < $max} {incr j} {
    set bit [string range $binString $j $j]
    if {$bit != "0" && $bit != "1"} {
      set bit 0
    }
    set result [expr $result << 1]
    set result [expr $result | $bit]
  }
  return $result
}

if {$tcl_platform(platform) == "windows"} {
    font create fnt1 -family {MS Sans Serif} -size 8
    font create fnt2 -family Courier -size 8
#   font create fnt3 -family Helvetica -weight bold -size 8
    font create fnt3 -family {MS Sans Serif} -size 8
    set InstallDir     "C:/EDA/Tools_REDS/MU0"
    set InstallDir_USB "C:/EDA/Tools_REDS/USB"
    catch {restart} err1
    if {$err1 != "invalid command name \"restart\""} {
        set full 0
    } else {
        catch {load "$InstallDir_USB/GestionUSB.dll"} err2
    if {$err2 != "" } {
      catch {load GestionUSB.dll} err2
      if {$err2 != "" } {
        set full 0
      } else {
        set full 1
        set InstallDir_USB .
        set InstallDir .
      }
    } else {
      set full 1
    }
    }
} elseif {$tcl_platform(platform) == "unix"} {
    font create fnt1 -family {MS Sans Serif} -size 12
    font create fnt2 -family Courier -size 12
    font create fnt3 -family Helvetica -weight bold -size 12
    font create big -family Courier -weight bold -size 18
	set InstallDir /Users/bpe/Prive/Eivd/2005-2006/eval_mu0/Tools_MU0_Actuels
    set full 0
} else {
    font create fnt1 -family {MS Sans Serif} -size 12
    font create fnt2 -family Courier -size 12
    #set InstallDir "C:/EDA/Tools_MiS/USB"
    set full 0
}

if {$full} {
    load $InstallDir_USB/GestionUSB.dll
    if {[Configuration_PS $InstallDir/sysmu0.rbf] == 0} {
        set ModesEnum {Target}
        Ecrire_HighZ 3
        Ecrire_ModeMU0 0 0
        Ecrire_ModeClk 0 0
        Ecrire_ValClk 15 0
    } else {
        set ModesEnum {}
    }
} else {
    set ModesEnum {}
}

proc init {argc argv} {
    global CmdsEnum CmdsVar
    global ModesEnum ModesVar
    global MemEnumH MemVarH MemEnumM MemVarM MemEnumm MemVarm MemEnumL MemVarL
    global Addr_to_Access Data_to_Write
    global ProgramName Program
    global PC Mem PcValue MemValue MemPtr
    global Io IoValue IoPtr
    global StartStop Acc
    global LabelsEnum LabelsUsage LabelsVar Opcode opc_txt
    global mem_io_lbl EditInsertRun CmdPos
    global MemMapping IoMapping
    global BreakpointList ResetMem ResetIo
    global NotSaved

    set ResetMem 0
    set ResetIo 0
    set NotSaved 0

    #option readfile options.def
    option add *background gray90
    option add *foreground navy
    option add *activeBackground navy
    option add *activeForeground yellow
    

    set EditInsertRun None
    set CmdPos 0
    set PC 0

    set CmdsEnum {Read Write}
    set CmdsVar [lindex $CmdsEnum 0] 

    catch {restart} err1
    if {$err1 != "invalid command name \"restart\""} {
        set ModesEnum [concat $ModesEnum ModelSim Internal Tutorial]
    } else {
        set ModesEnum [concat $ModesEnum Internal Tutorial]
    }
        
    set ModesVar [lindex $ModesEnum 0]

    set ProgramName "Program: NoName"
    set Program {}
}

proc {main} {argc argv} {
    if {$argc != 0} {
        set file [lindex $argv 0]
        if {[file exists $file]} {
            LoadFile $file
        } else {
            tk_messageBox -icon error -type ok -title Error -parent .cmd \
                -message "File $file doesn't exists"
        }
    }
}
#-------------------------------------------------------------------------------

proc CreateMainWindow {} {
    global ProgramName AccValue IrValue RegValue PcValue MemValue MemPtr BeforeAfter SimMode
    global ModesEnum ModesVar Version
    global nbrOfSwitches nbrOfKeys nbrOfLeds

    toplevel .top -class Toplevel 
    wm focusmodel .top passive
    wm geometry .top 576x669
    wm maxsize .top 1030 755
    wm minsize .top 106 2
    wm overrideredirect .top 0
    wm resizable .top 0 0
    wm deiconify .top
    wm title .top "DE1-SoC Avalon simulator $Version"
    label .top.label \
        -borderwidth 1 -relief raised -textvariable ProgramName -anchor center -font fnt1
    frame .top.frame \
        -borderwidth 2 -height 75 -relief groove -width 125
    listbox .top.frame.list  -yscrollcommand {.top.frame.scroll set} \
        -font fnt2
    scrollbar .top.frame.scroll \
        -command {.top.frame.list yview} -orient vert 
    label .top.frame.label1 \
        -borderwidth 1 -relief raised -text "R/W" -anchor center -font fnt1
    label .top.frame.label2 \
        -borderwidth 1 -relief raised -text Address -anchor center -font fnt1
    # bind .top.frame.label2 <Button-1> {InsertLabel}
    label .top.frame.label3 \
        -borderwidth 1 -relief raised -text "Value to write" -anchor center -font fnt1
    label .top.frame.label4 \
        -borderwidth 1 -relief raised -text "Read value" -anchor center -font fnt1
    # bind .top.frame.label4 <Button-1> {InsertComment}
    button .top.frame.delall \
        -text "Delete All" -command DeleteAllCommands -font fnt3
    button .top.frame.delete \
        -text Delete -command DeleteCommand -font fnt3
    button .top.frame.insert \
        -text Insert -command InsertCommand -font fnt3
    button .top.frame.edit \
        -text Edit -command EditCommand -font fnt3
    button .top.frame.append \
        -text Append -command AppendCommand  -font fnt3
    button .top.exit \
        -text Exit -command CleanExit -font fnt3 

#-------------------------------------------------------------------------------
#   create buttons
#-------------------------------------------------------------------------------

    button .top.load \
        -text Load -command LoadProgram -font fnt3
    button .top.step \
        -text Step -command Step -font fnt3
    button .top.restart \
        -text Restart -command Restart -font fnt3
    button .top.init \
        -text Init -command Init_Sim -font fnt3
    button .top.run \
        -text "Run 1 Period" -command Run_Period -font fnt3
    button .top.runMulti \
        -text "Run 10 Period" -command Run_MultiPeriod -font fnt3
    
#-------------------------------------------------------------------------------
#   place labels and buttons for instructions panel
#-------------------------------------------------------------------------------    
    button .top.save \
        -text Save -command SaveProgram -font fnt3
    place .top.label \
        -x 5 -y 5 -width 566 -height 17 -anchor nw -bordermode ignore
    place .top.frame \
        -x 5 -y 30 -width 566 -height 380 -anchor nw -bordermode ignore
    place .top.frame.list \
        -x 10 -y 25 -width 530 -height 321 -anchor nw -bordermode ignore
    place .top.frame.scroll \
        -x 540 -y 26 -width 16 -height 318 -anchor nw -bordermode ignore
    place .top.frame.label1 \
        -x 10 -y 8 -width 90 -height 19 -anchor nw -bordermode ignore
    place .top.frame.label2 \
        -x 100 -y 8 -width 140 -height 19 -anchor nw -bordermode ignore
    place .top.frame.label3 \
        -x 240 -y 8 -width 150 -height 19 -anchor nw -bordermode ignore
    place .top.frame.label4 \
        -x 390 -y 8 -width 150 -height 19 -anchor nw -bordermode ignore
    place .top.frame.delall \
        -x 450 -y 347 -width 90 -height 28 -anchor nw -bordermode ignore
    place .top.frame.delete \
        -x 357 -y 347 -width 90 -height 28 -anchor nw -bordermode ignore
    place .top.frame.insert \
        -x 264 -y 347 -width 90 -height 28 -anchor nw -bordermode ignore
    place .top.frame.append \
        -x 171 -y 347 -width 90 -height 28 -anchor nw -bordermode ignore
    place .top.frame.edit \
        -x 78 -y 347 -width 90 -height 28 -anchor nw -bordermode ignore


#-------------------------------------------------------------------------------    
# place input entries
#-------------------------------------------------------------------------------
    frame .top.inputValFrame -height 190 -width 566
    place .top.inputValFrame -x 5 -y 410

    label .top.inputValFrame.ledsLabel -text "|-------------------------------- LEDR\[9..0\] --------------------------------|"
    place .top.inputValFrame.ledsLabel -x 11 -y 2
    createLed .top.inputValFrame.led 10 24 1 horizontal $nbrOfLeds; # creation des leds

    label .top.inputValFrame.switchLabel -text "|------------------------------------------------ SW\[9..0\] --------------------------------------------------|"
    place .top.inputValFrame.switchLabel -x 8 -y 75
    createButton .top.inputValFrame.switch 10 97 1 "" horizontal $nbrOfSwitches;# creation des switchs

    label .top.inputValFrame.keyLabel -text "|------------- KEY\[3..0\] -------------|"
    place .top.inputValFrame.keyLabel -x 388 -y 75
    createButton .top.inputValFrame.keys 390 97 1 "" horizontal $nbrOfKeys;# creation des keys

#-------------------------------------------------------------------------------    
# place buttons
#-------------------------------------------------------------------------------

    place .top.init \
        -x 5 -y 601 -width 91 -height 28 -anchor nw -bordermode ignore
    place .top.step \
        -x 100 -y 601 -width 91 -height 28 -anchor nw -bordermode ignore
    place .top.run \
        -x 195 -y 601 -width 91 -height 28 -anchor nw -bordermode ignore
    place .top.runMulti \
        -x 290 -y 601 -width 91 -height 28 -anchor nw -bordermode ignore
    place .top.load \
        -x 5 -y 634 -width 91 -height 28 -anchor nw -bordermode ignore
    place .top.save \
        -x 100 -y 634 -width 91 -height 28 -anchor nw -bordermode ignore
    place .top.restart \
        -x 480 -y 601 -width 91 -height 28 -anchor nw -bordermode ignore
    place .top.exit \
        -x 480 -y 634 -width 91 -height 28 -anchor nw -bordermode ignore
}

proc CleanExit {} {
    global NotSaved
    if {$NotSaved == 1} {
        set answer [tk_messageBox -icon warning -type yesnocancel -title Warning -parent .cmd \
            -message "Program has not been saved\nDo you want to save it?"]
        switch -- $answer {
            yes {
                SaveProgram
                if {$NotSaved == 0} {
                    exit
                }
            }
            no exit
            cancel {}
        }
    } else {
        exit
    }
}

proc Init_Sim {} {
    global ModesVar PC Program period

    # reset PC
    set PC 0

    set index 0
    foreach p $Program {
        set opc [lindex $p 0]
        if {$opc == "Read"} {
            if {[llength $p] > 2} {
                set p [lreplace $p end end]
                set Program [lreplace $Program $index $index $p]
            }
        }
        incr index

    }
    UpdateList

    if {$ModesVar == "ModelSim"} {
        force -freeze /avalon_console_sim/reset_sti 1
        force -freeze /avalon_console_sim/address_sti 0
        force -freeze /avalon_console_sim/byteenable_sti 1111
        force -freeze /avalon_console_sim/read_sti 0
        force -freeze /avalon_console_sim/write_sti 0
        force -freeze /avalon_console_sim/write_data_sti 0
        force -freeze /avalon_console_sim/button_sti 0
        force -freeze /avalon_console_sim/switch_sti 0
        force -freeze /avalon_console_sim/lp36_status_sti 0
        run [expr 2 * $period]
        force -freeze /avalon_console_sim/reset_sti 0
        run [expr 2 * $period]
        UpdateLeds
    }
}

proc Run_Period {} {
    global period

    run $period
}

proc Run_MultiPeriod {} {
    global period

    run [expr 10 * $period]
}

proc Restart {} {
    global ModesVar PC Program

    # reset PC
    set PC 0

    set index 0
    foreach p $Program {
        set opc [lindex $p 0]
        if {$opc == "Read"} {
            if {[llength $p] > 2} {
                set p [lreplace $p end end]
                set Program [lreplace $Program $index $index $p]
            }
        }
        incr index

    }
    UpdateList
    if {$ModesVar == "ModelSim"} {
        restart
        UpdateList
        UpdateLeds
    }
}
#-------------------------------------------------------------------------------

proc Step {} {
    global IR PC PcValue Mem MemValue Program StartStop Reg Acc
    global SP Stack PcState EditInsertRun ModesVar Time BreakpointList ioPos now
    global Continue
    global PCv ACCv ALUv IRv ADDRv DATAv OPCv BSELv ASELv ACCCEv PCCEv IRCEv ACCOEv ALUFSv CYCLEv CYCLEOv RESETv ResetCount
	global value nbrcycle
    global Addr_to_Access Data_to_Write
    global nbrOfSwitches nbrOfKeys nbrOfLeds period

    update

    set EditInsertRun Run
    if {$ModesVar == "ModelSim"} {
        # set Time [expr $now/1000]
        set cmd [lindex $Program $PC]
        set addr [lindex $cmd 1]

        set keysStates [format %d 0x00]
            for {set i 0} {$i < $nbrOfKeys} {incr i} {
                    set singleKeyState($i) [readButton .top.inputValFrame.keys $i]
                    if {$singleKeyState($i) == 1} {
                    set keysStates [expr int($keysStates + pow(2,$i))]
                }
        }
        force -freeze /avalon_console_sim/button_sti [dec2bin $keysStates 4]

        set switchesStates [format %d 0x00]
            for {set i 0} {$i < $nbrOfSwitches} {incr i} {
                    set singleSwitchState($i) [readButton .top.inputValFrame.switch $i]
                    if {$singleSwitchState($i) == 1} {
                    set switchesStates [expr int($switchesStates + pow(2,$i))]
                }
        }
        force -freeze /avalon_console_sim/switch_sti [dec2bin $switchesStates 10]

        force -freeze /avalon_console_sim/address_sti [dec2bin [expr $addr / 4] 14]
        set access [lindex $cmd 0]
        if {$access == "Write"} {
            set data [lindex $cmd 2]
            force -freeze /avalon_console_sim/write_data_sti [dec2bin $data 32]
            force -freeze /avalon_console_sim/write_sti 1
            run $period
            force -freeze /avalon_console_sim/write_sti 0
        } elseif {$access == "Read"} {
            # set data [lindex $cmd 2]
            force -freeze /avalon_console_sim/read_sti 1
            run $period
            force -freeze /avalon_console_sim/read_sti 0
            set data_read [bin2dec [examine /avalon_console_sim/read_data_obs] 32]

            lappend cmd $data_read
            set Program [lreplace $Program $PC $PC $cmd]

        }
        run [expr 2 * $period]
        incr PC

        UpdateLeds
        
        UpdateList
    }
}

proc DeleteCommand {} {
    global CmdPos Program

    set CmdPos [.top.frame.list curselection]
    if {$CmdPos < 0} {
        tk_messageBox -icon error -type ok -title Error -parent .cmd \
            -message "Select a command first"
        return
    } 
    set Program [lreplace $Program $CmdPos $CmdPos]
    UpdateList
}

proc DeleteAllCommands {} {
    global Program

    set Program {}
    UpdateList
}

proc AppendCommand {} {
    global CmdPos EditInsertRun

    set EditInsertRun Insert
    set CmdPos -2
    wm deiconify .cmd
}

proc InsertCommand {} {
    global CmdPos EditInsertRun

    set CmdPos [.top.frame.list curselection]
    if {$CmdPos < 0} {
        tk_messageBox -icon error -type ok -title Error -parent .cmd \
            -message "Select a command first"
        return
    } 
    set EditInsertRun Insert
    wm deiconify .cmd
}

proc EditCommand {} {
    global CmdPos EditInsertRun Program CmdsVar MemVar LabelsVar
    global MemEnumH MemVarH MemEnumM MemVarM MemEnumm MemVarm MemEnumL MemVarL

    set CmdPos [.top.frame.list curselection]
    if {$CmdPos < 0} {
        tk_messageBox -icon error -type ok -title Error -parent .cmd \
            -message "Select a command first"
        return
    } 
    set p [lindex $Program $CmdPos]
    if {[lindex $p 1] == ":"} {
        set CmdsVar [lindex $p 2]
        set par [lindex $p 3]
    } else {
        set CmdsVar [lindex $p 0]
        set par [lindex $p 1]
    }
    if {$CmdsVar == "LDA_A" || $CmdsVar == "LDR_A" || $CmdsVar == "LDA#" || $CmdsVar == "STO" || \
        $CmdsVar == "ADD_A" || $CmdsVar == "SUB_A"} {
        set MemVar $par
        set mh [format %03x $par]
        set MemVarH [string index $mh 0]
        set MemVarM [string index $mh 1]
        set MemVarL [string index $mh 2]
    } elseif {$CmdsVar == ".DATA"} {
        set mh [format %04x $par]
        set MemVarH [string index $mh 0]
        set MemVarM [string index $mh 1]
        set MemVarm [string index $mh 2]
        set MemVarL [string index $mh 3]
    } elseif {$CmdsVar == "JMP" || $CmdsVar == "JGE" || $CmdsVar == "JNE" || $CmdsVar == "CALL" || \
               $CmdsVar == "LDA_L" || $CmdsVar == "LDR_L" || $CmdsVar == "ADD_L" || $CmdsVar == "SUB_L"} {
        set LabelsVar $par
    }
    set EditInsertRun Edit
    wm deiconify .cmd
}

proc CreateCommandWindow {} {
    global CmdsEnum CmdsVar

    toplevel .cmd -class Toplevel
    wm focusmodel .cmd passive
    wm geometry .cmd 227x145+193+306
    wm maxsize .cmd 1030 755
    wm minsize .cmd 106 2
    wm overrideredirect .cmd 0
    wm resizable .cmd 0 0
    wm deiconify .cmd
    wm title .cmd "Enter access type"
    frame .cmd.frame \
        -borderwidth 2 -height 75 -relief groove -width 125 
    menubutton .cmd.frame.opt \
        -direction flush -highlightthickness 2 -indicatoron 1 \
        -menu .cmd.frame.opt.menu -padx 5 -pady 4 -relief raised \
        -textvariable CmdsVar
    menu .cmd.frame.opt.menu \
        -activeborderwidth 1 -borderwidth 1 -cursor {} -tearoff 0 
    foreach i $CmdsEnum {
        .cmd.frame.opt.menu add radiobutton -variable CmdsVar -label $i 
    }
    button .cmd.next -text Next -command "NextCommandParam 1"
    button .cmd.cancel -text Cancel -command "wm withdraw .cmd"

    place .cmd.frame \
        -x 5 -y 5 -width 215 -height 85 -anchor nw -bordermode ignore 
    place .cmd.frame.opt \
        -x 30 -y 10 -width 175 -height 29 -anchor nw -bordermode ignore 
    place .cmd.next \
        -x 85 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    place .cmd.cancel \
            -x 155 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    wm withdraw .cmd
}
#-------------------------------------------------------------------------------

proc readValue {Name} {

    set Var_Name [string replace $Name 0 0 _]

    catch {format %d $Value_Array($Var_Name)} err

    puts $err

    set Value "Not Integer"

    if {[string is integer $err]} {
        # set Value [format %d $Value_Array($Var_Name)]
        set Value [format %d $Value_Array($Var_Name)]
    }
    return $Value
}

proc NextCommandParam {step} {
    global CmdsEnum CmdsVar CmdPos NotSaved Program
    global Addr_to_Access Data_to_Write
    global MemEnumH MemVarH MemEnumM MemVarM MemEnumm MemVarm MemEnumL MemVarL
    global LabelsEnum LabelsVar EditInsertRun
    global MemEnumH MemEnumL D_P LabelsUsage

    wm withdraw .cmd
    set last 0
    if {$CmdsVar == "Read"} {
        if {$step == 2} {
            wm withdraw .parRead
            set last 1
            set cmd "$CmdsVar [format %d $Addr_to_Access]"
        } else {
            wm deiconify .parRead
        }
    } elseif {$CmdsVar == "Write"} {
        if {$step == 2} {
            wm withdraw .parWrite
            set last 1
            set cmd "$CmdsVar [format %d $Addr_to_Access] [format %d $Data_to_Write]"
        } else {
            wm deiconify .parWrite
        }
    }
    if {$last == 1} {
        if {$EditInsertRun == "Insert"} {
            if {$CmdPos >= -1} {
                set Program [linsert $Program [expr $CmdPos+1] $cmd]
            } else {
                lappend Program $cmd
            }
        } else {
            set p [lindex $Program $CmdPos]
            if {[lindex $p 1] == ":"} {
                set cmd "[lindex $p 0] : $cmd"
            }
            # restore comment if it exist
            set sc [lsearch -exact $p ";"]
            if {$sc > 0} {
                lappend cmd ";"
                lappend cmd [lindex $p [expr $sc+1]]
            } 
            set Program [lreplace $Program $CmdPos $CmdPos $cmd]
        }
        UpdateList
        set NotSaved 1
    }
}

proc UpdateList {} {
    global Program PC
    global EditInsertRun CmdPos ModesVar opc_txt

    .top.frame.list delete 0 end
    set i 0
    foreach p $Program {
        set opc [lindex $p 0]
        if {$opc == "Read"} {
            if {[lindex $p 2] != ""} {
                set pp "  $opc_txt($opc)    0x[format %08x [lindex $p 1]]                   0x[format %08x [lindex $p 2]]"
            } else {
                set pp "  $opc_txt($opc)    0x[format %08x [lindex $p 1]]"
            }
        } elseif {$opc == "Write"} {
            set pp "  $opc_txt($opc)    0x[format %08x [lindex $p 1]]     0x[format %08x [lindex $p 2]]"
        } else {
            
            set pp "           $opc_txt($opc) [lindex $p 1]"
        }
        set sc [lsearch -exact $p ";"]
        if {$sc < 0} {
            set cmt ""
        } else {
            set cmt [lindex $p [expr $sc+1]]
        }
        if {$PC == 0} {
            set cmp $i
        } else {
            set cmp [expr $i+1]
        }
        set j 0
        
        if {$PC == $cmp} {
            .top.frame.list insert end "--> [format %-28s $pp]$cmt"
        } else {
            .top.frame.list insert end "    [format %-28s $pp]$cmt"
        }
        incr i
    }


    
    if {$EditInsertRun != "Run"} {
        if {$CmdPos >= -1} {
            set ptr [expr $CmdPos+1]
        } else {
            set ptr [expr [llength $Program]-1]
        }
    }
    
    # activate the cursor
    if {$EditInsertRun == "Edit"} {
        .top.frame.list selection set $CmdPos
    } elseif {$EditInsertRun == "Insert"} {
        if {$CmdPos >= -1} {
            .top.frame.list selection set [expr $CmdPos+1]
        } else {
            .top.frame.list selection set end
        }
    }
}

proc UpdateLeds {} {
    global nbrOfLeds

        set ledsState [bin2dec [examine /avalon_console_sim/led_obs] 10]
        for {set i 0} {$i < $nbrOfLeds} {incr i} {
            if {[expr $ledsState % 2] == 0} {
                setLed .top.inputValFrame.led $i OFF
            } else {
                setLed .top.inputValFrame.led $i ON
            }
            set ledsState [expr $ledsState / 2]
        }
}

proc CreateParam1Window {} {
    global MemEnumH MemVarH MemEnumM MemVarM MemEnumm MemVarm MemEnumL MemVarL

    toplevel .val -class Toplevel
    wm focusmodel .val passive
    wm geometry .val 267x145+193+306
    wm maxsize .val 1030 755
    wm minsize .val 106 2
    wm overrideredirect .val 0
    wm resizable .val 0 0
    wm deiconify .val
    wm title .val "Enter Value"
    frame .val.frame \
        -borderwidth 2 -height 75 -relief groove -width 125 
    label .val.frame.label -text "Value" -anchor center -font fnt1
    menubutton .val.frame.opth \
        -direction flush -highlightthickness 2 -indicatoron 1 \
        -menu .val.frame.opth.menu -padx 5 -pady 4 -relief raised \
        -textvariable MemVarH
    menu .val.frame.opth.menu \
        -activeborderwidth 1 -borderwidth 1 -cursor {} -tearoff 0 
    foreach i $MemEnumH {
        .val.frame.opth.menu add radiobutton -variable MemVarH -label $i 
    }
    menubutton .val.frame.optM \
        -direction flush -highlightthickness 2 -indicatoron 1 \
        -menu .val.frame.optM.menu -padx 5 -pady 4 -relief raised \
        -textvariable MemVarM
    menu .val.frame.optM.menu \
        -activeborderwidth 1 -borderwidth 1 -cursor {} -tearoff 0 
    foreach i $MemEnumM {
        .val.frame.optM.menu add radiobutton -variable MemVarM -label $i 
    }
    menubutton .val.frame.optm \
        -direction flush -highlightthickness 2 -indicatoron 1 \
        -menu .val.frame.optm.menu -padx 5 -pady 4 -relief raised \
        -textvariable MemVarm
    menu .val.frame.optm.menu \
        -activeborderwidth 1 -borderwidth 1 -cursor {} -tearoff 0 
    foreach i $MemEnumm {
        .val.frame.optm.menu add radiobutton -variable MemVarm -label $i 
    }
    menubutton .val.frame.optl \
        -direction flush -highlightthickness 2 -indicatoron 1 \
        -menu .val.frame.optl.menu -padx 5 -pady 4 -relief raised \
        -textvariable MemVarL
    menu .val.frame.optl.menu \
        -activeborderwidth 1 -borderwidth 1 -cursor {} -tearoff 0 
    foreach i $MemEnumL {
        .val.frame.optl.menu add radiobutton -variable MemVarL -label $i 
    }
    button .val.next -text Accept -command "SetMem" -font fnt3
    button .val.cancel -text Cancel -command "wm withdraw .val" -font fnt3

    place .val.frame \
        -x 5 -y 5 -width 255 -height 85 -anchor nw -bordermode ignore 
    place .val.frame.label -x 5 -y 40
    place .val.frame.opth \
        -x 55 -y 12 -width 51 -height 29 -anchor nw -bordermode ignore 
    place .val.frame.optM \
        -x 102 -y 10 -width 51 -height 29 -anchor nw -bordermode ignore 
    place .val.frame.optm \
        -x 149 -y 10 -width 51 -height 29 -anchor nw -bordermode ignore 
    place .val.frame.optl \
        -x 196 -y 10 -width 51 -height 29 -anchor nw -bordermode ignore 
    place .val.next \
        -x 125 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    place .val.cancel \
        -x 195 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    wm withdraw .val
}

proc CreateParamWriteWindow {} {
    global Addr_to_Access Data_to_Write

    toplevel .parWrite -class Toplevel
    wm focusmodel .parWrite passive
    wm geometry .parWrite 267x145+193+306
    wm maxsize .parWrite 1030 755
    wm minsize .parWrite 106 2
    wm overrideredirect .parWrite 0
    wm resizable .parWrite 0 0
    wm deiconify .parWrite
    wm title .parWrite "Enter Address / Value"
    frame .parWrite.frame \
        -borderwidth 2 -height 75 -relief groove -width 125 
    label .parWrite.frame.labelAddress -text "Address" -anchor center -font fnt1
    entry .parWrite.frame.address -textvariable Addr_to_Access
    label .parWrite.frame.labelValue -text "Value" -anchor center -font fnt1
    entry .parWrite.frame.write_data -textvariable Data_to_Write
    menubutton .parWrite.frame.opth \
        -direction flush -highlightthickness 2 -indicatoron 1 \
        -menu .parWrite.frame.opth.menu -padx 5 -pady 4 -relief raised \
        -textvariable MemVarH
    menu .parWrite.frame.opth.menu \
        -activeborderwidth 1 -borderwidth 1 -cursor {} -tearoff 0 
    button .parWrite.next -text Accept -command "NextCommandParam 2" -font fnt3
    button .parWrite.cancel -text Cancel -command "wm withdraw .parWrite" -font fnt3

    place .parWrite.frame \
        -x 5 -y 5 -width 255 -height 85 -anchor nw -bordermode ignore 
    place .parWrite.frame.labelAddress -x 5 -y 12
    place .parWrite.frame.address \
        -x 145 -y 10 -width 70 -height 22 -anchor nw
    place .parWrite.frame.labelValue -x 5 -y 42
    place .parWrite.frame.write_data \
        -x 145 -y 40 -width 70 -height 22 -anchor nw
    place .parWrite.next \
        -x 125 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    place .parWrite.cancel \
        -x 195 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    wm withdraw .parWrite
}

proc CreateParamReadWindow {} {
    global Addr_to_Access Data_to_Write

    toplevel .parRead -class Toplevel
    wm focusmodel .parRead passive
    wm geometry .parRead 267x145+193+306
    wm maxsize .parRead 1030 755
    wm minsize .parRead 106 2
    wm overrideredirect .parRead 0
    wm resizable .parRead 0 0
    wm deiconify .parRead
    wm title .parRead "Enter Address"
    frame .parRead.frame \
        -borderwidth 2 -height 75 -relief groove -width 125 
    label .parRead.frame.label1 -text "Address" -anchor center -font fnt1
    entry .parRead.frame.address -textvariable Addr_to_Access
    menubutton .parRead.frame.opth \
        -direction flush -highlightthickness 2 -indicatoron 1 \
        -menu .parRead.frame.opth.menu -padx 5 -pady 4 -relief raised \
        -textvariable MemVarH
    menu .parRead.frame.opth.menu \
        -activeborderwidth 1 -borderwidth 1 -cursor {} -tearoff 0 
    button .parRead.next -text Accept -command "NextCommandParam 2" -font fnt3
    button .parRead.cancel -text Cancel -command "wm withdraw .parRead" -font fnt3

    place .parRead.frame \
        -x 5 -y 5 -width 255 -height 85 -anchor nw -bordermode ignore 
    place .parRead.frame.label1 -x 5 -y 12
    place .parRead.frame.address \
        -x 145 -y 10 -width 70 -height 22 -anchor nw
    place .parRead.next \
        -x 125 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    place .parRead.cancel \
        -x 195 -y 105 -width 65 -height 28 -anchor nw -bordermode ignore 
    wm withdraw .parRead
}

#-------------------------------------------------------------------------------
proc resetOpcode {} {
	global instrucName nbrcycle Opcode opc_txt CmdsVarE ValsVarE Mnemon

	# initialisation des codes
	array unset Opcode
	array unset Opcode
	 
	# creation des codes par defaut
	set Opcode(Read) 0
	set Opcode(Write) 1
    
	#creation des noms relatifs aux codes
	set opc_txt(Write) W
	set opc_txt(Read) R
}

#-------------------------------------------------------------------------------
proc setNewOpode {} {
	global instrucName Opcode opc_txt nbrcycle CmdsVarE ValsVarE Mnemon
  
	# destruction des anciens opcodes
	array unset Opcode
	array unset Mnemon
    
	# valeur des instructions de base
	set Opcode(Read) 0
	set Opcode(Write) 1
	set Opcode(LDA_A) 0
	set Opcode(LDA_L) 0
	set Opcode(STO) 1
	set Opcode(ADD_A) 2
	set Opcode(ADD_L) 2
	set Opcode(SUB_A) 3
	set Opcode(SUB_L) 3
	set Opcode(JMP) 4
	set Opcode(JGE) 5
	set Opcode(JNE) 6
	set Opcode(STP) 7
    
	# Nouveaux opcodes
	for {set i 8} {$i < 16} {incr i} {
		set Opcode($CmdsVarE($i)) [format %x $i]
		set nbrcycle([format %x $i]) $ValsVarE($i)
	}
	for {set i 0} {$i < 16} {incr i} {
		set Mnemon([format %x $i]) $CmdsVarE($i)
	}
    
	# cache la fenetre Opcode
	wm withdraw .opcode
}

#-------------------------------------------------------------------------------

proc Cmd_In {} {
  global outactive valin 
  
  set j 0
  if {$outactive == 1} {
    EcrireUSB [format %d 0x201E] 1
    
    for {set i 15} {$i >= 0} {incr i -1} {
      destroy .io.ifr.in($i)
      destroy .io.ifr.labin($i)
    }
    for {set i 15} {$i >= 0} {incr i -1} {
          checkbutton .io.ifr.in($i) -variable valin($i) -command {UpdateIn; UpdateList} -state disable
          label .io.ifr.labin($i) -relief flat -anchor center -text $i
          # mise en place
          place .io.ifr.in($i) -x [expr 5+((15-$i)%8)*20] -y [expr 45+$j*45]
          place .io.ifr.labin($i) -x [expr 10+((15-$i)%8)*20]  -y [expr 30+$j*45]
          if {$i == 8} { 
              incr j
          }
        }
    UpdateIn
  } else {
    EcrireUSB [format %d 0x201E] 0
        for {set i 15} {$i >= 0} {incr i -1} {
      destroy .io.ifr.in($i)
      destroy .io.ifr.labin($i)
    }
    for {set i 15} {$i >= 0} {incr i -1} {
          checkbutton .io.ifr.in($i) -variable valin($i) -command {UpdateIn; UpdateList} -state normal
          label .io.ifr.labin($i) -relief flat -anchor center -text $i
          # mise en place
          place .io.ifr.in($i) -x [expr 5+((15-$i)%8)*20] -y [expr 45+$j*45]
          place .io.ifr.labin($i) -x [expr 10+((15-$i)%8)*20]  -y [expr 30+$j*45]
          if {$i == 8} { 
              incr j
          }
        }
    for {set i 0} {$i < 16} {incr i} {
      set valin($i) 0
    }
  }
}

#-------------------------------------------------------------------------------

proc LoadProgram {} {
    set types {
        {"Tcl files"    {.tcl}}
        {"All files"        *}
    }

    set file [tk_getOpenFile -filetypes $types]

    # puts "LoadProgram"

    if {[string length $file] != 0} {
        LoadFile $file
    }
}
#-------------------------------------------------------------------------------

proc LoadFile {file} {
    global Program ProgramName NotSaved

    set ff [split $file "."]
    set ext [lindex $ff end]
    if {$ext == "tcl"} {
        source $file
        UpdateList
        set ProgramName "Program Name: $file"
	}
    set NotSaved 0
}
#-------------------------------------------------------------------------------

proc SaveProgram {} {
    global Program NotSaved

    set types {
        {"Tcl files"    {.tcl}  }
        {"All files"        *}
    }

    set file [tk_getSaveFile -filetypes $types]

    if {[string length $file] != 0} {
        set ff [split $file "."]
        set ext [lindex $ff end]
        set ProgramCopy $Program
        set index 0
        foreach p $ProgramCopy {
            set opc [lindex $p 0]
            if {$opc == "Read"} {
                if {[llength $p] > 2} {
                    set p [lreplace $p end end]
                    set ProgramCopy [lreplace $ProgramCopy $index $index $p]
                }
            }
            incr index
        }


        set fres [open $file w]
        regsub -all {} $ProgramCopy {} pp
        puts $fres "set Program {$pp}"
        close $fres
        set NotSaved 0
    }
}
#-------------------------------------------------------------------------------

proc GetCode {p addr} {
    global Opcode Mem

    if {$opc == "Write"} {
        set waddr [lindex $p 1]
        set wdata [lindex $p 2]
    }
    if {$opc == "Write"} {
        return "$Opcode($opc) [format %08x $waddr] [format %08x $wdata]"
    } else {
        return "$Opcode($opc) [format %08x $par]"
    }
}
#-------------------------------------------------------------------------------

proc WriteIntelHexFile {file} {
    global Program Mem

    if {$file == "pipe"} {
        set fres [open "� Load_Mu0 -pipe" w]
    } else {
        set fres [open $file w]
    }
    set code ""
    set addr 0
    foreach p $Program {
        lappend code [GetCode $p $addr]
        incr addr
    }
    set crc 0
    set addr 0
    set first 1
    set len [llength $code]
    set last [expr $len / 16]
    set lastlen [expr $len % 16]
    set i 0
    foreach c $code {
        if {[expr $addr % 16] == 0} {
            if {$first == 1} {
                set first 0
            } else {
                set crc [expr 256-($crc%256)]
                puts $fres [format %04X $crc]
            }
            if {$i == $last} {
                set crc [expr $lastlen*2]
                puts -nonewline $fres ":[format %04X $crc][format %04X $addr]00"
            } else {
                puts -nonewline $fres ":20[format %04X $addr]00"
                set crc 32
            }
            set crc [expr $crc + ($addr/256) + ($addr%256)]
            incr i
        }
        set c1 [string range $c 0 1]
        set c2 [string range $c 2 3]
        scan $c1 %04x c1i
        scan $c2 %04x c2i
        # swap high / low bytes for Intel
        puts -nonewline $fres $c2$c1
        set crc [expr $crc + $c1i + $c2i]
        incr addr
    }
    set crc [expr 256-($crc%256)]
    puts $fres [format %04X $crc]
    puts $fres ":00000001FF"
    close $fres
}

proc DownloadProgram {} {
    global Program Mnemon nbrcycle 

    set fres [open TmPFiLe.FsH w]
    set addr 0
    foreach p $Program {
        puts $fres "[GetCode $p $addr]"
        incr addr
    }
    close $fres
    Ecrire_HighZ 3
    Download TmPFiLe.FsH
    Ecrire_HighZ 0
    Restart
    file delete TmPFiLe.FsH
}
#-------------------------------------------------------------------------------

proc ExportProgram {} {
    global Program Mem

    set types {
        {"Hex files"    {.hex}  }
        {"Intel Hex files"  {.int}  }
    }

    set file [tk_getSaveFile -filetypes $types]
    if {[string length $file] != 0} {
        set ff [split $file "."]
        set ext [lindex $ff end]
        if {$ext == "hex"} {
        	set fres [open $file w]
        	set addr 0
        	foreach p $Program {
            	puts $fres "[format %03x $addr] [GetCode $p $addr]"
            	incr addr
        	}
        	close $fres
    	} elseif {$ext == "int"} {
        	WriteIntelHexFile $file
    	}
    }
}
#-------------------------------------------------------------------------------

proc viewOpcode {} { 
    wm deiconify .opcode
    wm focusmodel .opcode active
}
#-------------------------------------------------------------------------------

init $argc $argv
CreateCommandWindow
# CreateParam1Window
CreateParamWriteWindow
CreateParamReadWindow
resetOpcode
CreateMainWindow
if {([llength $ModesEnum] == 2) ||((([llength $ModesEnum] == 3) && !([lindex $ModesEnum 0] == "ModelSim")))} {
    wm withdraw .
}
UpdateList
main $argc $argv