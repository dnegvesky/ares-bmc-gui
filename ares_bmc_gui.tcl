# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# File        : ares_bmc_gui.tcl
# Author      : Dan Negvesky
# Created     : 2025/04/05
# Last update : 2025/05/05
# Version     : 1.0
# Dependency  : rxc-bmc-ares
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description : Ares BMC GUI for monitor and control fuctions using rxc-bmc-ares package
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------

package require Tk

# Global variables
set devicePath "/dev/rxc-bmc-ares-0"
set refreshTime 5
set refreshId [list]
set tooltipId [list]
set showThresholds 0
set monitoringActive 1
array set voltWidgets {}
array set currWidgets {}
array set tempWidgets {}
array set tachyWidgets {}
array set freqWidgets {}
array set stateWidgets {}
array set eventWidgets {}
set lastErrorTime 0
set fanPwmValue 50
set i2cAddr "0x50"
set i2cData "0xDEADBEEF"
set i2cNbyte 4
set fanMode "Auto"
set powerMode "Auto"
set pllConfigItem "SoM PLL"
set pllConfigFile ""

# Label mappings
set idLabelMap {
    "sw-bmc" "librxc-bmc package version"
    "fw-bmc" "MAX 10 BMC firmware version"
    "fw-bob" "Carrier Board USB to JTAG version"
    "fw-ltc3888" "SoM PMBus LTC3888 firmware version"
    "fw-ltc7132" "SoM PMBus LTC7132 firmware version"
    "som-name" "SoM name"
    "som-serial" "SoM serial number"
    "som-partn" "SoM part number"
    "som-date" "SoM manufacturing date"
    "som-manual" "SoM power mode"
    "som-rev" "SoM hardware revision"
    "cb-name" "Carrier Board name"
    "cb-serial" "Carrier Board serial number"
    "cb-partn" "Carrier Board part number"
    "cb-date" "Carrier Board manufacturing date"
    "cb-rev" "Carrier Board hardware revision"
}
set voltLabelMap {
    "12V" "12V input"
    "0V8_VCC" "+0.8V core"
    "0V8_VCC_HSSI" "+0.8V VCC_HSSI"
    "0V8_VCCH_SDM" "+0.8V VCCH_SDM"
    "1V0_VCCERT_FGT" "+1.0V VCCERT_FGT"
    "1V2_VCCIO" "+1.2V VCCIO"
}
set currLabelMap {
    "12V" "+12V input current"
    "0V8_VCC" "+0.8V core current"
}
set tempLabelMap {
    "M10_Core" "MAX 10 BMC core"
    "AGI_SDM" "Agilex SDM bank"
    "AGI_Core" "Agilex core"
    "AGI_XCVR_12A" "Agilex XCVR bank 12A"
    "AGI_XCVR_13A" "Agilex XCVR bank 13A"
    "Local_Top" "SoM Q22 sensing diode"
    "Local_Bot" "SoM Q23 sensing diode"
}
set tachyLabelMap { "fan-rpm" "SoM Fan PWM speed" }
set freqLabelMap { "clk_25MHz" "SoM 25MHz oscillator" }
set stateLabelMap {
    "pll-som-reconf" "SoM PLL reconfig request status"
    "pll-som-reset" "SoM PLL reset status"
    "pll-som-input" "SoM PLL input clock select status"
    "pll-som-ok" "SoM PLL configuration status"
    "pll-som-busy" "SoM PLL busy status"
    "pll-som-error" "SoM PLL error status"
    "pll-cb-reconf" "Carrier PLL reconfig request status"
    "pll-cb-reset" "Carrier PLL reset status"
    "pll-cb-input" "Carrier PLL input clock select status"
    "pll-cb-ok" "Carrier PLL config status"
    "pll-cb-busy" "Carrier PLL busy status"
    "pll-cb-error" "Carrier PLL error status"
    "pwr-psg1-pg" "SoM power group #1 status"
    "pwr-psg2-pg" "SoM power group #2 status"
    "pwr-psg3-pg" "SoM power group #3 status"
    "fan-cmd" "SoM fan PWM signal duty cycle value"
    "pwr-on" "SoM power-on request status"
    "pwr-off" "SoM power-off request status"
    "fpga_confdone" "Agilex CONF_DONE pin status"
    "fpga_initdone" "Agilex INIT_DONE pin status"
    "fpga_nstatus" "Agilex nSTATUS pin status"
    "fpga_nconfig" "Agilex nCONFIG pin status"
    "reconf_ram_hrm" "SoM EEPROM BMC reloading status"
    "reset_hps_periph" "Agilex HPS peripherals reset status"
    "eth_phy_cb_coma" "Carrier Ethernet PHY Com A status"
    "hps_clk_off" "SoM HPS_OSC_CLK osc enable status"
    "sdm_clk_off" "SoM SDM_OSC_CLK osc enable status"
    "btn-user" "Carrier SW3 push button"
}
set eventLabelMap { "event" "Event Log" }

####################################################################
# GUI WINDOW SETUP
####################################################################

wm title . "ARES BMC Monitor & Control"
grid [frame .left -width 200 -relief ridge -borderwidth 2] -row 0 -column 0 -sticky ns -pady 5 -padx 5
grid [frame .right -relief ridge -borderwidth 2] -row 0 -column 1 -sticky nsew -pady 5 -padx 5
grid columnconfigure . 1 -weight 1
grid rowconfigure . 0 -weight 1

# Left GUI control panel
ttk::label .left.title -text "GUI Controls" -font {Helvetica 12 bold}
ttk::label .left.detected -text "Detected board:"
ttk::entry .left.device -textvariable ::devicePath
ttk::label .left.refreshLabel -text "Refresh Time (1-60s):"
ttk::entry .left.refreshTime -textvariable ::refreshTime -width 5
ttk::button .left.monitorToggle -text "Stop Monitoring" -command toggleMonitoring
ttk::button .left.toggleThresh -text "Show Thresholds" -command toggleThresholds
grid .left.title -row 0 -column 0 -pady 5 -padx 5
grid .left.detected -row 1 -column 0 -pady 2 -padx 5 -sticky w
grid .left.device -row 2 -column 0 -pady 5 -padx 5 -sticky ew
grid .left.refreshLabel -row 3 -column 0 -pady 5 -padx 5 -sticky w
grid .left.refreshTime -row 4 -column 0 -pady 5 -padx 5 -sticky w
grid .left.monitorToggle -row 5 -column 0 -pady 5 -padx 5 -sticky ew
grid .left.toggleThresh -row 6 -column 0 -pady 5 -padx 5 -sticky ew

# Right panel: 3x4 grid
# Columns 1-2: Monitoring panes
frame .right.id -relief sunken -borderwidth 1
ttk::label .right.id.title -text "Board Identification" -font {Helvetica 12 bold} -justify center
grid .right.id -row 0 -column 0 -sticky nsew -pady 5 -padx 5
grid .right.id.title -row 0 -column 0 -columnspan 2 -pady 2
grid columnconfigure .right.id {0 1} -weight 1

frame .right.state -relief sunken -borderwidth 1
ttk::label .right.state.title -text "State Monitoring" -font {Helvetica 12 bold} -justify center
frame .right.state.left
frame .right.state.right
grid .right.state -row 0 -column 1 -sticky nsew -pady 5 -padx 5
grid .right.state.title -row 0 -column 0 -columnspan 4 -pady 2
grid .right.state.left -row 1 -column 0 -sticky nsew -padx 5
grid .right.state.right -row 1 -column 2 -sticky nsew -padx 5
grid columnconfigure .right.state {0 2} -weight 1
grid columnconfigure .right.state {1 3} -weight 0
grid rowconfigure .right.state 1 -weight 1

frame .right.volt -relief sunken -borderwidth 1
ttk::label .right.volt.title -text "Voltage Monitoring" -font {Helvetica 12 bold} -justify center
grid .right.volt -row 1 -column 0 -sticky nsew -pady 5 -padx 5
grid .right.volt.title -row 0 -column 0 -columnspan 2 -pady 2
grid columnconfigure .right.volt {0 1} -weight 1

frame .right.temp -relief sunken -borderwidth 1
ttk::label .right.temp.title -text "Temperature Monitoring" -font {Helvetica 12 bold} -justify center
grid .right.temp -row 1 -column 1 -sticky nsew -pady 5 -padx 5
grid .right.temp.title -row 0 -column 0 -columnspan 2 -pady 2
grid columnconfigure .right.temp {0 1} -weight 1

frame .right.curr -relief sunken -borderwidth 1
ttk::label .right.curr.title -text "Current Monitoring" -font {Helvetica 12 bold} -justify center
grid .right.curr -row 2 -column 0 -sticky nsew -pady 5 -padx 5
grid .right.curr.title -row 0 -column 0 -columnspan 2 -pady 2
grid columnconfigure .right.curr {0 1} -weight 1

frame .right.tachy -relief sunken -borderwidth 1
ttk::label .right.tachy.title -text "Tachometer Monitoring" -font {Helvetica 12 bold} -justify center
grid .right.tachy -row 2 -column 1 -sticky nsew -pady 5 -padx 5
grid .right.tachy.title -row 0 -column 0 -columnspan 2 -pady 2
grid columnconfigure .right.tachy {0 1} -weight 1

frame .right.freq -relief sunken -borderwidth 1
ttk::label .right.freq.title -text "Frequency Monitoring" -font {Helvetica 12 bold} -justify center
grid .right.freq -row 3 -column 0 -sticky nsew -pady 5 -padx 5
grid .right.freq.title -row 0 -column 0 -columnspan 2 -pady 2
grid columnconfigure .right.freq {0 1} -weight 1

frame .right.event -relief sunken -borderwidth 1
ttk::label .right.event.title -text "Event Monitoring" -font {Helvetica 12 bold} -justify center
grid .right.event -row 3 -column 1 -sticky nsew -pady 5 -padx 5
grid .right.event.title -row 0 -column 0 -columnspan 2 -pady 2
grid columnconfigure .right.event {0 1} -weight 1

# Column 3: Control panes
frame .right.pll -relief sunken -borderwidth 1
ttk::label .right.pll.title -text "PLL Control" -font {Helvetica 12 bold} -justify center
ttk::label .right.pll.somLabel -text "SoM PLL:"
ttk::button .right.pll.somReconf -text "Reconf: 0" -command setPllSomReconf
ttk::button .right.pll.somReset -text "Reset: 0" -command setPllSomReset
ttk::label .right.pll.somInputLabel -text "SOM PLL Input:"
ttk::combobox .right.pll.somInput -values {0 1 2 3} -state readonly -width 5
ttk::button .right.pll.somUpdate -text "Update" -command setPllSomInput
ttk::label .right.pll.cbLabel -text "Carrier Board PLL:"
ttk::button .right.pll.cbReconf -text "Reconf: 0" -command setPllCbReconf
ttk::button .right.pll.cbReset -text "Reset: 0" -command setPllCbReset
ttk::label .right.pll.cbInputLabel -text "Carrier PLL Input:"
ttk::combobox .right.pll.cbInput -values {0 1 2 3} -state readonly -width 5
ttk::button .right.pll.cbUpdate -text "Update" -command setPllCbInput
ttk::label .right.pll.configTitle -text "PLL Config" -font {Helvetica 12 bold} -justify center
ttk::label .right.pll.configItemLabel -text "PLL:"
ttk::combobox .right.pll.configItem -textvariable ::pllConfigItem -values {"SoM PLL" "Carrier PLL"} -state readonly -width 12
ttk::label .right.pll.configFileLabel -text "Browse for SoM PLL config file:"
frame .right.pll.browseFrame
ttk::entry .right.pll.browseFrame.entry -textvariable ::pllConfigFile -width 30 -state normal
ttk::button .right.pll.browseFrame.browse -text "…" -width 3 -command browsePllConfigFile
ttk::button .right.pll.configUpdate -text "Update Config" -command setPllConfig
grid .right.pll -row 0 -column 2 -sticky nsew -pady 5 -padx 5
grid .right.pll.title -row 0 -column 0 -columnspan 2 -pady 2
grid .right.pll.somLabel -row 1 -column 0 -sticky w -padx 5
grid .right.pll.somReconf -row 2 -column 0 -sticky ew -padx 5 -pady 2
grid .right.pll.somReset -row 2 -column 1 -sticky ew -padx 5 -pady 2
grid .right.pll.somInputLabel -row 3 -column 0 -sticky w -padx 5
grid .right.pll.somInput -row 3 -column 1 -sticky w -padx 5
grid .right.pll.somUpdate -row 4 -column 0 -columnspan 2 -sticky ew -padx 5 -pady 2
grid .right.pll.cbLabel -row 5 -column 0 -sticky w -padx 5
grid .right.pll.cbReconf -row 6 -column 0 -sticky ew -padx 5 -pady 2
grid .right.pll.cbReset -row 6 -column 1 -sticky ew -padx 5 -pady 2
grid .right.pll.cbInputLabel -row 7 -column 0 -sticky w -padx 5
grid .right.pll.cbInput -row 7 -column 1 -sticky w -padx 5
grid .right.pll.cbUpdate -row 8 -column 0 -columnspan 2 -sticky ew -padx 5 -pady 2
grid .right.pll.configTitle -row 9 -column 0 -columnspan 2 -pady 5
grid .right.pll.configItemLabel -row 10 -column 0 -sticky w -padx 5 -pady 2
grid .right.pll.configItem -row 10 -column 1 -sticky w -padx 5 -pady 2
grid .right.pll.configFileLabel -row 12 -column 0 -columnspan 2 -sticky w -padx 5 -pady 2
grid .right.pll.browseFrame -row 13 -column 0 -columnspan 2 -sticky ew -padx 5 -pady 2
grid .right.pll.browseFrame.entry -row 0 -column 0 -sticky ew -padx 5
grid .right.pll.browseFrame.browse -row 0 -column 1 -sticky e -padx 5
grid .right.pll.configUpdate -row 14 -column 0 -sticky ew -padx 5 -pady 2
grid columnconfigure .right.pll {0 1} -weight 1
grid columnconfigure .right.pll.browseFrame 0 -weight 1

frame .right.i2c -relief sunken -borderwidth 1
ttk::label .right.i2c.title -text "I2C Access" -font {Helvetica 12 bold} -justify center
ttk::label .right.i2c.addrLabel -text "Address:"
ttk::combobox .right.i2c.addr -textvariable ::i2cAddr -values {"0x50 (Carrier EEPROM)"} -width 20
ttk::label .right.i2c.dataLabel -text "Write Data:"
ttk::entry .right.i2c.data -textvariable ::i2cData -width 12
ttk::label .right.i2c.nbyteLabel -text "Read Bytes:"
ttk::entry .right.i2c.nbyte -textvariable ::i2cNbyte -width 5
ttk::button .right.i2c.read -text "Read" -command setI2cRead
ttk::button .right.i2c.write -text "Write" -command setI2cWrite
ttk::button .right.i2c.xfer -text "Transfer" -command setI2cTransfer
ttk::label .right.i2c.output -text "Output: (none)" -wraplength 200
grid .right.i2c -row 1 -column 2 -sticky nsew -pady 5 -padx 5
grid .right.i2c.title -row 0 -column 0 -columnspan 2 -pady 2
grid .right.i2c.addrLabel -row 1 -column 0 -sticky w -padx 5 -pady 2
grid .right.i2c.addr -row 1 -column 1 -sticky w -padx 5 -pady 2
grid .right.i2c.dataLabel -row 2 -column 0 -sticky w -padx 5 -pady 2
grid .right.i2c.data -row 2 -column 1 -sticky w -padx 5 -pady 2
grid .right.i2c.nbyteLabel -row 3 -column 0 -sticky w -padx 5 -pady 2
grid .right.i2c.nbyte -row 3 -column 1 -sticky w -padx 5 -pady 2
grid .right.i2c.read -row 4 -column 0 -sticky ew -padx 5 -pady 2
grid .right.i2c.write -row 4 -column 1 -sticky ew -padx 5 -pady 2
grid .right.i2c.xfer -row 5 -column 0 -columnspan 2 -sticky ew -padx 5 -pady 2
grid .right.i2c.output -row 6 -column 0 -columnspan 2 -sticky w -padx 5 -pady 2
grid columnconfigure .right.i2c {0 1} -weight 1

frame .right.fan -relief sunken -borderwidth 1
ttk::label .right.fan.title -text "Fan Control" -font {Helvetica 12 bold} -justify center
ttk::label .right.fan.modeLabel -text "Mode:"
ttk::combobox .right.fan.mode -values {"Auto" "Manual"} -state readonly -width 7 -textvariable ::fanMode
ttk::label .right.fan.pwmLabel -text "PWM (0-100%):"
ttk::entry .right.fan.pwm -textvariable ::fanPwmValue -width 5
ttk::button .right.fan.set -text "Set PWM" -command setFanControl -state disabled
grid .right.fan -row 2 -column 2 -sticky nsew -pady 5 -padx 5
grid .right.fan.title -row 0 -column 0 -columnspan 2 -pady 2
grid .right.fan.modeLabel -row 1 -column 0 -sticky w -padx 5 -pady 2
grid .right.fan.mode -row 1 -column 1 -sticky w -padx 5 -pady 2
grid .right.fan.pwmLabel -row 2 -column 0 -sticky w -padx 5 -pady 2
grid .right.fan.pwm -row 2 -column 1 -sticky w -padx 5 -pady 2
grid .right.fan.set -row 3 -column 0 -columnspan 2 -sticky ew -padx 5 -pady 2
grid columnconfigure .right.fan {0 1} -weight 1

frame .right.power -relief sunken -borderwidth 1
ttk::label .right.power.title -text "Power Mode Config" -font {Helvetica 12 bold} -justify center
ttk::label .right.power.modeLabel -text "Mode:"
ttk::combobox .right.power.mode -textvariable ::powerMode -values {"Auto" "Manual"} -state readonly -width 7
ttk::button .right.power.toggle -text "Power On" -command setPowerToggle
grid .right.power -row 3 -column 2 -sticky nsew -pady 5 -padx 5
grid .right.power.title -row 0 -column 0 -columnspan 2 -pady 2
grid .right.power.modeLabel -row 1 -column 0 -sticky w -padx 5 -pady 2
grid .right.power.mode -row 1 -column 1 -sticky w -padx 5 -pady 2
grid .right.power.toggle -row 2 -column 0 -columnspan 2 -sticky ew -padx 5 -pady 2
grid columnconfigure .right.power {0 1} -weight 1

# Configure 3x4 grid weights
grid columnconfigure .right {0 1 2} -weight 1
grid rowconfigure .right {0 1 2 3} -weight 1

# Tooltip procedures
proc showTooltip {widget text} {
    global tooltipId
    if {[llength $tooltipId]} { after cancel [lindex $tooltipId 0] }
    set tooltipId [after 1000 [list showTooltipNow $widget $text]]
}
proc showTooltipNow {widget text} {
    set tip [toplevel .tip -background lightyellow -relief solid -borderwidth 1]
    wm overrideredirect $tip 1
    label $tip.label -text $text -background lightyellow
    pack $tip.label
    set x [expr {[winfo rootx $widget] + 20}]
    set y [expr {[winfo rooty $widget] + 20}]
    wm geometry $tip +$x+$y
}
proc hideTooltip {} {
    global tooltipId
    if {[llength $tooltipId]} { after cancel [lindex $tooltipId 0] }
    set tooltipId [list]
    catch {destroy .tip}
}

# Bind tooltips
bind .left.device <Enter> {showTooltip .left.device "Enter BMC device path (e.g., /dev/rxc-bmc-ares-0)"}
bind .left.device <Leave> {hideTooltip}
bind .left.refreshTime <Enter> {showTooltip .left.refreshTime "Set monitoring refresh interval in seconds (1-60)"}
bind .left.refreshTime <Leave> {hideTooltip}
bind .left.monitorToggle <Enter> {showTooltip .left.monitorToggle "Start or stop monitoring updates"}
bind .left.monitorToggle <Leave> {hideTooltip}
bind .left.toggleThresh <Enter> {showTooltip .left.toggleThresh "Toggle display of min/max thresholds"}
bind .left.toggleThresh <Leave> {hideTooltip}

bind .right.pll.somReconf <Enter> {showTooltip .right.pll.somReconf "Toggle SoM PLL reconfiguration (0=release, 1=assert)"}
bind .right.pll.somReconf <Leave> {hideTooltip}
bind .right.pll.somReset <Enter> {showTooltip .right.pll.somReset "Toggle SoM PLL reset (0=release, 1=assert)"}
bind .right.pll.somReset <Leave> {hideTooltip}
bind .right.pll.somInput <Enter> {showTooltip .right.pll.somInput "Select SoM PLL input clock (0-3)"}
bind .right.pll.somInput <Leave> {hideTooltip}
bind .right.pll.somUpdate <Enter> {showTooltip .right.pll.somUpdate "Apply SoM PLL input selection"}
bind .right.pll.somUpdate <Leave> {hideTooltip}
bind .right.pll.cbReconf <Enter> {showTooltip .right.pll.cbReconf "Toggle Carrier Board PLL reconfiguration (0=release, 1=assert)"}
bind .right.pll.cbReconf <Leave> {hideTooltip}
bind .right.pll.cbReset <Enter> {showTooltip .right.pll.cbReset "Toggle Carrier Board PLL reset (0=release, 1=assert)"}
bind .right.pll.cbReset <Leave> {hideTooltip}
bind .right.pll.cbInput <Enter> {showTooltip .right.pll.cbInput "Select Carrier Board PLL input clock (0-3)"}
bind .right.pll.cbInput <Leave> {hideTooltip}
bind .right.pll.cbUpdate <Enter> {showTooltip .right.pll.cbUpdate "Apply Carrier Board PLL input selection"}
bind .right.pll.cbUpdate <Leave> {hideTooltip}

bind .right.fan.mode <Enter> {showTooltip .right.fan.mode "Select fan mode: Auto (EEPROM-driven) or Manual (set PWM)"}
bind .right.fan.mode <Leave> {hideTooltip}
bind .right.fan.pwm <Enter> {showTooltip .right.fan.pwm "Set fan PWM duty cycle (0-100%) for Manual mode"}
bind .right.fan.pwm <Leave> {hideTooltip}
bind .right.fan.set <Enter> {showTooltip .right.fan.set "Set fan PWM value (Manual mode only)"}
bind .right.fan.set <Leave> {hideTooltip}
bind .right.fan.mode <<ComboboxSelected>> {setFanMode}

bind .right.pll.configItem <Enter> {showTooltip .right.pll.configItem "Select PLL to configure (SoM or Carrier Board)"}
bind .right.pll.configItem <Leave> {hideTooltip}
bind .right.pll.browseFrame.entry <Enter> {showTooltip .right.pll.browseFrame.entry "Highlight and delete to clear PLL configuration file path (use … to browse)"}
bind .right.pll.browseFrame.entry <Leave> {hideTooltip}
bind .right.pll.browseFrame.browse <Enter> {showTooltip .right.pll.browseFrame.browse "Open file dialog for PLL configuration"}
bind .right.pll.browseFrame.browse <Leave> {hideTooltip}
bind .right.pll.configUpdate <Enter> {showTooltip .right.pll.configUpdate "Update selected PLL with configuration file (writes to dedicated EEPROM)"}
bind .right.pll.configUpdate <Leave> {hideTooltip}
bind .right.pll.configItem <<ComboboxSelected>> {updatePllConfigLabel}
bind .right.pll.browseFrame.entry <Delete> {set pllConfigFile ""; updatePllConfigLabel}

bind .right.i2c.addr <Enter> {showTooltip .right.i2c.addr "Select or enter I2C device address (e.g., 0x50 for Carrier EEPROM)"}
bind .right.i2c.addr <Leave> {hideTooltip}
bind .right.i2c.data <Enter> {showTooltip .right.i2c.data "Enter hex data to write with '0x' prefix (e.g., 0xDEADBEEF)"}
bind .right.i2c.data <Leave> {hideTooltip}
bind .right.i2c.nbyte <Enter> {showTooltip .right.i2c.nbyte "Enter number of bytes to read (1-255)"}
bind .right.i2c.nbyte <Leave> {hideTooltip}
bind .right.i2c.read <Enter> {showTooltip .right.i2c.read "Read specified bytes from I2C device"}
bind .right.i2c.read <Leave> {hideTooltip}
bind .right.i2c.write <Enter> {showTooltip .right.i2c.write "Write data to I2C device"}
bind .right.i2c.write <Leave> {hideTooltip}
bind .right.i2c.xfer <Enter> {showTooltip .right.i2c.xfer "Write data then read specified bytes from I2C device"}
bind .right.i2c.xfer <Leave> {hideTooltip}

bind .right.power.mode <Enter> {showTooltip .right.power.mode "Set power mode: Auto (full boot on +12V) or Manual (BMC only, use Power to boot)"}
bind .right.power.mode <Leave> {hideTooltip}
bind .right.power.toggle <Enter> {showTooltip .right.power.toggle "Toggle power on/off in Manual mode"}
bind .right.power.toggle <Leave> {hideTooltip}
bind .right.power.mode <<ComboboxSelected>> {setPowerMode}

# Centralized error popup
proc showError {msg result} {
    global lastErrorTime devicePath
    set currentTime [clock milliseconds]
    if {$currentTime - $lastErrorTime >= 5000} {
        tk_messageBox -title "Error" -message "$msg at $devicePath. Please check the cable and power.\n$result" -type ok -icon error -parent .
        set lastErrorTime $currentTime
    }
}

# Auto-size, adjust and center window size based on content, assumes 1920x1080 HD monitor
proc autoSizeWindow {} {
    update idletasks
    set width [expr {[winfo reqwidth .left] + [winfo reqwidth .right] + 72}]
    set height [expr {max([winfo reqheight .left], [winfo reqheight .right]) + 72}]
    set width [expr {min($width, 1920)}]
    set height [expr {min($height, 1080)}]
    set screenWidth [winfo screenwidth .]
    set screenHeight [winfo screenheight .]
    set x [expr {($screenWidth - $width) / 2}]
    set y [expr {($screenHeight - $height) / 2}]
    wm geometry . ${width}x${height}+${x}+${y}
}

####################################################################
# GUI CONTROL PROCESSES
####################################################################

# Schedule periodic refresh of monitoring data, user selectable between 1 and 60 seconds
proc scheduleRefresh {} {
    global refreshTime refreshId monitoringActive
    # Skip if monitoring is disabled
    if {!$monitoringActive} { return }
    # Cancel any existing refresh schedule
    if {[llength $refreshId]} { after cancel [lindex $refreshId 0] }
    # Validate and correct refresh time
    if {![string is integer -strict $refreshTime] || $refreshTime < 1 || $refreshTime > 60} {
        set refreshTime 5
        .left.refreshTime delete 0 end
        .left.refreshTime insert 0 $refreshTime
    }
    # Schedule monitoring updates
    set ms [expr {$refreshTime * 1000}]
    set refreshId [after $ms {
        monitorVoltage
        monitorCurrent
        monitorTemp
        monitorTachy
        monitorFreq
        monitorState
        monitorEvent
        if {$monitoringActive} { scheduleRefresh }
    }]
}

# Debounce refresh time updates to prevent rapid scheduling
set refreshDebounceId ""
proc debounceRefresh {} {
    global refreshDebounceId refreshTime
    if {$refreshDebounceId ne ""} { after cancel $refreshDebounceId }
    set refreshDebounceId [after 500 [list scheduleRefresh]]
}

# Toggle monitoring updates on/off
proc toggleMonitoring {} {
    global monitoringActive refreshId
    set monitoringActive [expr {!$monitoringActive}]
    .left.monitorToggle configure -text [expr {$monitoringActive ? "Stop Monitoring" : "Start Monitoring"}]
    if {$monitoringActive} {
        monitorVoltage
        monitorCurrent
        monitorTemp
        monitorTachy
        monitorFreq
        monitorState
        monitorEvent
    } else {
        if {[llength $refreshId]} { after cancel [lindex $refreshId 0] }
        set refreshId [list]
    }
}

# Toggle display of min/max thresholds in monitoring panes
proc toggleThresholds {} {
    global showThresholds
    set showThresholds [expr {!$showThresholds}]
    .left.toggleThresh configure -text [expr {$showThresholds ? "Hide Thresholds" : "Show Thresholds"}]
    monitorVoltage
    monitorCurrent
    monitorTemp
    monitorTachy
    monitorFreq
    monitorState
    monitorEvent
    after idle autoSizeWindow
}

####################################################################
# BMC MONITORING PROCESSES
####################################################################

# Populate the Board Identification pane with device details
proc refreshIdentify {} {
    global devicePath idLabelMap
    catch {set output [exec rxc-bmc-identify $devicePath]} result
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        foreach line [split $result "\n"] {
            if {[regexp {([^=]+)=(.+)} $line -> key value]} {
                if {[dict exists $idLabelMap $key]} {
                    set displayKey [dict get $idLabelMap $key]
                } else {
                    set displayKey $key
                }
                lappend data [list $displayKey $value]
            }
        }
    }
    set row 1
    foreach entry $data {
        lassign $entry key value color
        ttk::label .right.id.l$row -text "$key:" -width 30 -anchor e
        ttk::label .right.id.v$row -text $value -foreground $color
        grid .right.id.l$row -row $row -column 0 -sticky e -padx 5
        grid .right.id.v$row -row $row -column 1 -sticky w -padx 5
        incr row
    }
}

# Update the State Monitoring pane with system state signals and update power toggle button
proc monitorState {} {
    global devicePath stateLabelMap showThresholds stateWidgets monitoringActive
    # Execute rxc-bmc-monitor-state to fetch system state signals
    catch {set output [exec rxc-bmc-monitor-state $devicePath]} result
    # Handle errors
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        set pwrGrp1 -1
        set pwrGrp2 -1
        set pwrGrp3 -1
        # Parse each line of output into key-value pairs
        foreach line [split $result "\n"] {
            if {[regexp {([^=]+)=(.+)} $line -> key value]} {
                set key [string trim $key]
                set value [string trim $value]
                # Map raw keys to display labels if defined in stateLabelMap
                if {[dict exists $stateLabelMap $key]} {
                    set displayKey [dict get $stateLabelMap $key]
                } else {
                    set displayKey $key
                }
                lappend data [list $displayKey $value "black"]
                # Update PLL control buttons and comboboxes
                if {$key eq "pll-som-reconf"} {
                    .right.pll.somReconf configure -text "Reconf: $value"
                } elseif {$key eq "pll-som-reset"} {
                    .right.pll.somReset configure -text "Reset: $value"
                } elseif {$key eq "pll-som-input"} {
                    .right.pll.somInput set $value
                } elseif {$key eq "pll-cb-reconf"} {
                    .right.pll.cbReconf configure -text "Reconf: $value"
                } elseif {$key eq "pll-cb-reset"} {
                    .right.pll.cbReset configure -text "Reset: $value"
                } elseif {$key eq "pll-cb-input"} {
                    .right.pll.cbInput set $value
                } elseif {$key eq "som-manual"} {
                    # Update power mode and toggle button state
                    set mode [expr {$value eq "on" ? "Manual" : "Auto"}]
                    .right.power.mode set $mode
                    set ::powerMode $mode
                    .right.power.toggle configure -state [expr {$mode eq "Manual" ? "normal" : "disabled"}]
                } elseif {$key eq "pwr-psg1-pg"} {
                    set pwrGrp1 $value
                } elseif {$key eq "pwr-psg2-pg"} {
                    set pwrGrp2 $value
                } elseif {$key eq "pwr-psg3-pg"} {
                    set pwrGrp3 $value
                }
            }
        }
        # Set power toggle button text based on power group status
        if {$pwrGrp1 == 1 && $pwrGrp2 == 1 && $pwrGrp3 == 1} {
            .right.power.toggle configure -text "Power Off"
        } elseif {$pwrGrp1 == 0 && $pwrGrp2 == 0 && $pwrGrp3 == 0} {
            .right.power.toggle configure -text "Power On"
        } else {
            .right.power.toggle configure -text "Power Off"
        }
    }
    # Split data into two columns for display in State Monitoring pane
    set total [llength $data]
    set half [expr {($total + 1) / 2}]
    set leftData [lrange $data 0 [expr {$half - 1}]]
    set rightData [lrange $data $half end]
    
    # Update or create left-column labels
    set row 1
    foreach entry $leftData {
        lassign $entry key value color
        if {![info exists stateWidgets(l$row-left)]} {
            ttk::label .right.state.left.l$row -text "$key:" -width 30 -anchor e
            ttk::label .right.state.left.v$row -text $value -foreground $color
            grid .right.state.left.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.state.left.v$row -row $row -column 1 -sticky w -padx 5
            set stateWidgets(l$row-left) .right.state.left.l$row
            set stateWidgets(v$row-left) .right.state.left.v$row
        } else {
            $stateWidgets(v$row-left) configure -text $value -foreground $color
        }
        incr row
    }
    
    # Update or create right-column labels
    set row 1
    foreach entry $rightData {
        lassign $entry key value color
        if {![info exists stateWidgets(l$row-right)]} {
            ttk::label .right.state.right.l$row -text "$key:" -width 30 -anchor e
            ttk::label .right.state.right.v$row -text $value -foreground $color
            grid .right.state.right.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.state.right.v$row -row $row -column 1 -sticky w -padx 5
            set stateWidgets(l$row-right) .right.state.right.l$row
            set stateWidgets(v$row-right) .right.state.right.v$row
        } else {
            $stateWidgets(v$row-right) configure -text $value -foreground $color
        }
        incr row
    }
}

# Update the Voltage Monitoring pane with voltage readings and thresholds
proc monitorVoltage {} {
    global devicePath voltLabelMap showThresholds voltWidgets monitoringActive
    catch {set output [exec rxc-bmc-monitor-volt $devicePath]} result
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        foreach line [split $result "\n"] {
            if {[regexp {([^=]+)=([0-9.]+)V\s+\(min=([0-9.-]+)V,\s+max=([0-9.]+)V\)} $line -> key value min max]} {
                if {[dict exists $voltLabelMap $key]} {
                    set displayKey [dict get $voltLabelMap $key]
                } else {
                    set displayKey $key
                }
                set color [expr {$value >= $min && $value <= $max ? "green" : "red"}]
                set displayValue [expr {$showThresholds ? "$value V (min=$min V, max=$max V)" : "$value V"}]
                lappend data [list $displayKey $displayValue $color]
            }
        }
    }
    set row 1
    foreach entry $data {
        lassign $entry key value color
        if {![info exists voltWidgets(l$row)]} {
            ttk::label .right.volt.l$row -text "$key:" -width 20 -anchor e
            ttk::label .right.volt.v$row -text $value -foreground $color
            grid .right.volt.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.volt.v$row -row $row -column 1 -sticky w -padx 5
            set voltWidgets(l$row) .right.volt.l$row
            set voltWidgets(v$row) .right.volt.v$row
        } else {
            $voltWidgets(v$row) configure -text $value -foreground $color
        }
        incr row
    }
    if {$monitoringActive} { scheduleRefresh }
}

# Update the Current Monitoring pane with current readings and thresholds
proc monitorCurrent {} {
    global devicePath currLabelMap showThresholds currWidgets monitoringActive
    catch {set output [exec rxc-bmc-monitor-curr $devicePath]} result
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        foreach line [split $result "\n"] {
            if {[regexp {([^=]+)=([0-9.]+)A\s+\(min=([0-9.-]+)A,\s+max=([0-9.]+)A\)} $line -> key value min max]} {
                if {[dict exists $currLabelMap $key]} {
                    set displayKey [dict get $currLabelMap $key]
                } else {
                    set displayKey $key
                }
                set color [expr {$value >= $min && $value <= $max ? "green" : "red"}]
                set displayValue [expr {$showThresholds ? "$value A (min=$min A, max=$max A)" : "$value A"}]
                lappend data [list $displayKey $displayValue $color]
            }
        }
    }
    set row 1
    foreach entry $data {
        lassign $entry key value color
        if {![info exists currWidgets(l$row)]} {
            ttk::label .right.curr.l$row -text "$key:" -width 20 -anchor e
            ttk::label .right.curr.v$row -text $value -foreground $color
            grid .right.curr.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.curr.v$row -row $row -column 1 -sticky w -padx 5
            set currWidgets(l$row) .right.curr.l$row
            set currWidgets(v$row) .right.curr.v$row
        } else {
            $currWidgets(v$row) configure -text $value -foreground $color
        }
        incr row
    }
}

# Update the Frequency Monitoring pane with clock frequency readings
proc monitorFreq {} {
    global devicePath freqLabelMap showThresholds freqWidgets monitoringActive
    catch {set output [exec rxc-bmc-monitor-freq $devicePath]} result
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        foreach line [split $result "\n"] {
            if {[regexp {([^=]+)=([0-9.]+)MHz} $line -> key value]} {
                if {[dict exists $freqLabelMap $key]} {
                    set displayKey [dict get $freqLabelMap $key]
                } else {
                    set displayKey $key
                }
                lappend data [list $displayKey "$value MHz" "green"]
            }
        }
    }
    set row 1
    foreach entry $data {
        lassign $entry key value color
        if {![info exists freqWidgets(l$row)]} {
            ttk::label .right.freq.l$row -text "$key:" -width 20 -anchor e
            ttk::label .right.freq.v$row -text $value -foreground $color
            grid .right.freq.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.freq.v$row -row $row -column 1 -sticky w -padx 5
            set freqWidgets(l$row) .right.freq.l$row
            set freqWidgets(v$row) .right.freq.v$row
        } else {
            $freqWidgets(v$row) configure -text $value -foreground $color
        }
        incr row
    }
}

# Update the Temperature Monitoring pane with temperature readings and thresholds
proc monitorTemp {} {
    global devicePath tempLabelMap showThresholds tempWidgets monitoringActive
    catch {set output [exec rxc-bmc-monitor-temp $devicePath]} result
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        foreach line [split $result "\n"] {
            if {[regexp {([^=]+)=([0-9.]+)°C\s+\(min=([0-9.-]+)°C,\s+max=([0-9.]+)°C\)} $line -> key value min max]} {
                if {[dict exists $tempLabelMap $key]} {
                    set displayKey [dict get $tempLabelMap $key]
                } else {
                    set displayKey $key
                }
                set color [expr {$value >= $min && $value <= $max ? "green" : "red"}]
                set displayValue [expr {$showThresholds ? "$value °C (min=$min °C, max=$max °C)" : "$value °C"}]
                lappend data [list $displayKey $displayValue $color]
            } elseif {[regexp {([^=]+)=([0-9.]+)°C} $line -> key value]} {
                if {[dict exists $tempLabelMap $key]} {
                    set displayKey [dict get $tempLabelMap $key]
                } else {
                    set displayKey $key
                }
                set displayValue "$value °C"
                lappend data [list $displayKey $displayValue "green"]
            }
        }
    }
    set row 1
    foreach entry $data {
        lassign $entry key value color
        if {![info exists tempWidgets(l$row)]} {
            ttk::label .right.temp.l$row -text "$key:" -width 20 -anchor e
            ttk::label .right.temp.v$row -text $value -foreground $color
            grid .right.temp.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.temp.v$row -row $row -column 1 -sticky w -padx 5
            set tempWidgets(l$row) .right.temp.l$row
            set tempWidgets(v$row) .right.temp.v$row
        } else {
            $tempWidgets(v$row) configure -text $value -foreground $color
        }
        incr row
    }
}

# Update the Tachometer Monitoring pane with fan speed readings
proc monitorTachy {} {
    global devicePath tachyLabelMap showThresholds tachyWidgets monitoringActive
    catch {set output [exec rxc-bmc-monitor-tachy $devicePath]} result
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        foreach line [split $result "\n"] {
            if {[regexp {([^=]+)=([0-9]+)RPM} $line -> key value]} {
                if {[dict exists $tachyLabelMap $key]} {
                    set displayKey [dict get $tachyLabelMap $key]
                } else {
                    set displayKey $key
                }
                lappend data [list $displayKey "$value RPM" "green"]
            }
        }
    }
    set row 1
    foreach entry $data {
        lassign $entry key value color
        if {![info exists tachyWidgets(l$row)]} {
            ttk::label .right.tachy.l$row -text "$key:" -width 20 -anchor e
            ttk::label .right.tachy.v$row -text $value -foreground $color
            grid .right.tachy.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.tachy.v$row -row $row -column 1 -sticky w -padx 5
            set tachyWidgets(l$row) .right.tachy.l$row
            set tachyWidgets(v$row) .right.tachy.v$row
        } else {
            $tachyWidgets(v$row) configure -text $value -foreground $color
        }
        incr row
    }
}

# Update the Event Monitoring pane with event log entries
proc monitorEvent {} {
    global devicePath eventLabelMap showThresholds eventWidgets monitoringActive
    catch {set output [exec rxc-bmc-monitor-event $devicePath]} result
    if {[string match "=> error:*" $result]} {
        showError "Board disconnected or powered off" $result
        set data [list [list "Error" $result "black"]]
    } else {
        set data {}
        if {$result eq ""} {
            set displayKey [dict get $eventLabelMap "event"]
            lappend data [list $displayKey "No events" "black"]
        } else {
            foreach line [split $result "\n"] {
                if {[regexp {([^=]+)=(.+)} $line -> key value]} {
                    if {[dict exists $eventLabelMap $key]} {
                        set displayKey [dict get $eventLabelMap $key]
                    } else {
                        set displayKey $key
                    }
                    lappend data [list $displayKey $value "black"]
                }
            }
        }
    }
    set row 1
    foreach entry $data {
        lassign $entry key value color
        if {![info exists eventWidgets(l$row)]} {
            ttk::label .right.event.l$row -text "$key:" -width 20 -anchor e
            ttk::label .right.event.v$row -text $value -foreground $color
            grid .right.event.l$row -row $row -column 0 -sticky e -padx 5
            grid .right.event.v$row -row $row -column 1 -sticky w -padx 5
            set eventWidgets(l$row) .right.event.l$row
            set eventWidgets(v$row) .right.event.v$row
        } else {
            $eventWidgets(v$row) configure -text $value -foreground $color
        }
        incr row
    }
}

####################################################################
# BMC CONTROL PROCESSES
####################################################################
####################################################################
# PLL Control & Config
####################################################################

# Toggle SoM PLL reconfiguration signal
proc setPllSomReconf {} {
    global devicePath
    set current [expr {[string match "Reconf: 1" [.right.pll.somReconf cget -text]] ? 1 : 0}]
    set value [expr {$current ? 0 : 1}]
    catch {exec rxc-bmc-control $devicePath pll-som-reconf $value} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set SoM PLL Reconf" $result
        return
    }
    .right.pll.somReconf configure -text "Reconf: $value"
    monitorState
}

# Toggle SoM PLL reset signal
proc setPllSomReset {} {
    global devicePath
    set current [expr {[string match "Reset: 1" [.right.pll.somReset cget -text]] ? 1 : 0}]
    set value [expr {$current ? 0 : 1}]
    catch {exec rxc-bmc-control $devicePath pll-som-reset $value} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set SoM PLL Reset" $result
        return
    }
    .right.pll.somReset configure -text "Reset: $value"
    monitorState
}

# Set SoM PLL input clock selection
proc setPllSomInput {} {
    global devicePath
    set value [.right.pll.somInput get]
    if {![string is integer -strict $value] || $value < 0 || $value > 3} {
        tk_messageBox -title "Invalid Input" -message "SoM PLL Input must be 0-3." -type ok -icon error -parent .
        return
    }
    catch {exec rxc-bmc-control $devicePath pll-som-input $value} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set SoM PLL Input" $result
        return
    }
    monitorState
}

# Toggle Carrier Board PLL reconfiguration signal
proc setPllCbReconf {} {
    global devicePath
    set current [expr {[string match "Reconf: 1" [.right.pll.cbReconf cget -text]] ? 1 : 0}]
    set value [expr {$current ? 0 : 1}]
    catch {exec rxc-bmc-control $devicePath pll-cb-reconf $value} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set Carrier Board PLL Reconf" $result
        return
    }
    .right.pll.cbReconf configure -text "Reconf: $value"
    monitorState
}

# Toggle Carrier Board PLL reset signal
proc setPllCbReset {} {
    global devicePath
    set current [expr {[string match "Reset: 1" [.right.pll.cbReset cget -text]] ? 1 : 0}]
    set value [expr {$current ? 0 : 1}]
    catch {exec rxc-bmc-control $devicePath pll-cb-reset $value} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set Carrier Board PLL Reset" $result
        return
    }
    .right.pll.cbReset configure -text "Reset: $value"
    monitorState
}

# Set Carrier Board PLL input clock selection
proc setPllCbInput {} {
    global devicePath
    set value [.right.pll.cbInput get]
    if {![string is integer -strict $value] || $value < 0 || $value > 3} {
        tk_messageBox -title "Invalid Input" -message "Carrier Board PLL Input must be 0-3." -type ok -icon error -parent .
        return
    }
    catch {exec rxc-bmc-control $devicePath pll-cb-input $value} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set Carrier Board PLL Input" $result
        return
    }
    monitorState
}

# Open a file dialog to select a PLL configuration file
proc browsePllConfigFile {} {
    global pllConfigFile
    set file [tk_getOpenFile -filetypes {{"All Files" *}} -title "Select PLL Config File"]
    if {$file ne ""} {
        set pllConfigFile $file
    }
}

# Update the selected PLL configuration with the chosen file
proc setPllConfig {} {
    global devicePath pllConfigItem pllConfigFile
    if {$pllConfigFile eq ""} {
        tk_messageBox -title "Error" -message "No file selected for PLL configuration" -type ok -icon error -parent .
        return
    }
    if {![file exists $pllConfigFile] || ![file readable $pllConfigFile]} {
        tk_messageBox -title "Error" -message "Invalid or inaccessible file: $pllConfigFile" -type ok -icon error -parent .
        return
    }
    set item [expr {$pllConfigItem eq "SoM PLL" ? "pll-som" : "pll-cb"}]
    set itemName [expr {$pllConfigItem eq "SoM PLL" ? "SoM" : "Carrier"}]
    if {![tk_messageBox -title "Confirm" -message "Update $itemName PLL configuration? This may affect clock settings." -type yesno -icon warning -parent .]} {
        return
    }
    catch {exec rxc-bmc-update $devicePath $item $pllConfigFile} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to update $itemName PLL configuration" $result
        return
    }
    set ::pllConfigFileLabelText "$itemName PLL updated"
}

# Update the PLL configuration file label based on the selected PLL
proc updatePllConfigLabel {} {
    global pllConfigItem
    set item [expr {$pllConfigItem eq "SoM PLL" ? "SoM" : "Carrier"}]
    set ::pllConfigFileLabelText "Browse for $item PLL config file:"
}

####################################################################
# I2C Access
####################################################################

# Read specified bytes from I2C device
proc setI2cRead {} {
    global devicePath i2cAddr i2cNbyte
    # Extract hex address (e.g., "50" from "0x50 (Carrier EEPROM)" or "0x51" from manual entry)
    set addr [lindex [split $i2cAddr] 0]
    set addr [string trimleft $addr "0x"]
    if {![string is xdigit -strict $addr] || [string length $addr] > 2} {
        tk_messageBox -title "Invalid Input" -message "I2C address must be a valid hex value (e.g., 0x50)." -type ok -icon error -parent .
        return
    }
    if {![string is integer -strict $i2cNbyte] || $i2cNbyte < 1 || $i2cNbyte > 255} {
        tk_messageBox -title "Invalid Input" -message "Number of bytes must be an integer between 1 and 255." -type ok -icon error -parent .
        set i2cNbyte 4
        .right.i2c.nbyte delete 0 end
        .right.i2c.nbyte insert 0 $i2cNbyte
        return
    }
    catch {exec rxc-bmc-i2c-read $devicePath $addr $i2cNbyte} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to read from I2C device" $result
        .right.i2c.output configure -text "Output: (error)"
        return
    }
    .right.i2c.output configure -text "Output: $result"
}

# Write data to I2C device
proc setI2cWrite {} {
    global devicePath i2cAddr i2cData
    set addr [lindex [split $i2cAddr] 0]
    set addr [string trimleft $addr "0x"]
    if {![string is xdigit -strict $addr] || [string length $addr] > 2} {
        tk_messageBox -title "Invalid Input" -message "I2C address must be a valid hex value (e.g., 0x50)." -type ok -icon error -parent .
        return
    }
    # Validate data: must start with "0x" and be hex
    if {![regexp {^0x[0-9A-Fa-f]+$} $i2cData]} {
        tk_messageBox -title "Invalid Input" -message "Write data must be hex with '0x' prefix (e.g., 0xDEADBEEF)." -type ok -icon error -parent .
        set i2cData "0xDEADBEEF"
        .right.i2c.data delete 0 end
        .right.i2c.data insert 0 $i2cData
        return
    }
    catch {exec rxc-bmc-i2c-write $devicePath $addr $i2cData} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to write to I2C device" $result
        .right.i2c.output configure -text "Output: (error)"
        return
    }
    .right.i2c.output configure -text "Output: Write successful"
}

# Perform an I2C write followed by a read (transfer)
proc setI2cTransfer {} {
    global devicePath i2cAddr i2cData i2cNbyte
    set addr [lindex [split $i2cAddr] 0]
    set addr [string trimleft $addr "0x"]
    if {![string is xdigit -strict $addr] || [string length $addr] > 2} {
        tk_messageBox -title "Invalid Input" -message "I2C address must be a valid hex value (e.g., 0x50)." -type ok -icon error -parent .
        return
    }
    if {![regexp {^0x[0-9A-Fa-f]+$} $i2cData]} {
        tk_messageBox -title "Invalid Input" -message "Write data must be hex with '0x' prefix (e.g., 0xDEADBEEF)." -type ok -icon error -parent .
        set i2cData "0xDEADBEEF"
        .right.i2c.data delete 0 end
        .right.i2c.data insert 0 $i2cData
        return
    }
    if {![string is integer -strict $i2cNbyte] || $i2cNbyte < 1 || $i2cNbyte > 255} {
        tk_messageBox -title "Invalid Input" -message "Number of bytes must be an integer between 1 and 255." -type ok -icon error -parent .
        set i2cNbyte 4
        .right.i2c.nbyte delete 0 end
        .right.i2c.nbyte insert 0 $i2cNbyte
        return
    }
    catch {exec rxc-bmc-i2c-xfer $devicePath $addr $i2cData $i2cNbyte} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to transfer with I2C device" $result
        .right.i2c.output configure -text "Output: (error)"
        return
    }
    .right.i2c.output configure -text "Output: $result"
}

####################################################################
# Fan Control
####################################################################

# Configure fan mode (Auto/Manual) and enable/disable PWM control
proc setFanMode {} {
    global devicePath fanMode
    set mode [.right.fan.mode get]
    # Force lowercase for command argument
    set cmdMode [string tolower $mode]
    catch {exec rxc-bmc-control $devicePath fan-cmd $cmdMode} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set fan to $mode" $result
        set fanMode "Auto"
        .right.fan.mode set "Auto"
        .right.fan.set configure -state disabled
        return
    }
    .right.fan.set configure -state [expr {$mode eq "Manual" ? "normal" : "disabled"}]
    monitorTachy
}

# Set the fan PWM value in Manual mode and update tachometer monitoring
proc setFanControl {} {
    global devicePath fanPwmValue
    set mode [.right.fan.mode get]
    if {$mode ne "Manual"} {
        tk_messageBox -title "Error" -message "Switch to Manual mode to set PWM." -type ok -icon error -parent .
        return
    }
    if {![string is integer -strict $fanPwmValue] || $fanPwmValue < 0 || $fanPwmValue > 100} {
        tk_messageBox -title "Invalid Input" -message "PWM value must be an integer between 0 and 100." -type ok -icon error -parent .
        set fanPwmValue 50
        .right.fan.pwm delete 0 end
        .right.fan.pwm insert 0 $fanPwmValue
        return
    }
    catch {exec rxc-bmc-control $devicePath fan-cmd $fanPwmValue} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set fan PWM" $result
    }
    monitorTachy
}

####################################################################
# Power Mode Config
####################################################################

# Configure power mode (Auto/Manual) and enable/disable power toggle
proc setPowerMode {} {
    global devicePath powerMode
    set mode [.right.power.mode get]
    set cmdMode [expr {$mode eq "Manual" ? "on" : "off"}]
    catch {exec rxc-bmc-update $devicePath som-manual $cmdMode} result
    if {[string match "=> error:*" $result]} {
        showError "Failed to set power mode to $mode: $result" $result
        set powerMode "Auto"
        .right.power.mode set "Auto"
        .right.power.toggle configure -state disabled
        return
    }
    .right.power.toggle configure -state [expr {$mode eq "Manual" ? "normal" : "disabled"}]
    monitorState
}

# Toggle power on/off in Manual mode
proc setPowerToggle {} {
    global devicePath powerMode
    # Ensure Manual mode is active
    if {$powerMode ne "Manual"} {
        tk_messageBox -title "Error" -message "Power toggle is only available in Manual mode." -type ok -icon error -parent .
        return
    }
    set currentState [.right.power.toggle cget -text]
    set cmd [expr {$currentState eq "Power On" ? "pwr-on" : "pwr-off"}]
    set oppositeCmd [expr {$cmd eq "pwr-on" ? "pwr-off" : "pwr-on"}]
    # Retry commands up to twice to handle random BMC errors (observed when testing at command line)
    foreach attempt {1 2} {
        # Clear opposite command to prevent conflicts
        catch {exec rxc-bmc-control $devicePath $oppositeCmd 0} result
        if {[string match "=> error:*" $result] && $attempt == 1} {
            after 100
            continue
        } elseif {[string match "=> error:*" $result]} {
            showError "Failed to clear $oppositeCmd: $result" $result
            return
        }
        # Set desired command
        catch {exec rxc-bmc-control $devicePath $cmd 1} result
        if {[string match "=> error:*" $result] && $attempt == 1} {
            after 100
            continue
        } elseif {[string match "=> error:*" $result]} {
            showError "Failed to toggle $cmd: $result" $result
            return
        }
        # Delay to stabilize
        after 100
        # Reset command to 0
        catch {exec rxc-bmc-control $devicePath $cmd 0} result
        if {[string match "=> error:*" $result] && $attempt == 1} {
            after 100
            continue
        } elseif {[string match "=> error:*" $result]} {
            showError "Failed to reset $cmd: $result" $result
            return
        }
        break
    }
    monitorState
}

####################################################################
# MAIN
####################################################################

# Check for BMC software and board presence, initialize GUI settings
proc checkPrerequisites {} {
    global devicePath
    if {![file exists "/usr/share/rxc-bmc-tools"]} {
        tk_messageBox -title "Error" -message "BMC Software Package not found at /usr/share/rxc-bmc-tools. Please install it following the Ares BMC User Guide." -type ok -icon error -parent .
        exit
    }
    if {![file exists $devicePath]} {
        tk_messageBox -title "Error" -message "No board detected at $devicePath. Ensure the board is connected and powered on." -type ok -icon error -parent .
        after 5000 checkPrerequisites
        return
    }
    .right.fan.mode set "Auto"
    .right.i2c.addr set "0x50 (Carrier EEPROM)"
    .right.pll.configItem set "SoM PLL"
    .right.power.mode set "Auto"
    .right.power.toggle configure -state disabled -text "Power Off"
    refreshIdentify
    monitorVoltage
    monitorCurrent
    monitorTemp
    monitorTachy
    monitorFreq
    monitorState
    monitorEvent
    after idle autoSizeWindow
}

# Bind refresh time update with debounce
bind .left.refreshTime <KeyRelease> {debounceRefresh}

# Initial setup
autoSizeWindow
update idletasks
checkPrerequisites
