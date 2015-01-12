::cisco::eem::event_register_syslog pattern "$_internet_route_established_phrase"
::cisco::eem::description "This policy re-enters NVI PAT statements on command-line after address change on Internet facing interface in order to fix a Cisco bug affecting NVI and the global VRF"

namespace import ::cisco::lib::*
namespace import ::cisco::eem::*



## Please enter similar commands in global configuration mode to enable the script
# event manager environment _internet_route_established_phrase Dialer1 assigned DHCP address
# event manager directory user policy flash:/
# event manager policy fix_nvi.tcl
#



##################
# Check for global definition of environment variables
##################

# Note: _internet_route_established_phrase should be something like: 
#  "Dialer1 assigned DHCP address"
#   or
#  "Line protocol on Interface Virtual-Access1, changed state to up"

if {![info exists _internet_route_established_phrase]} {
	set result /
	“Policy cannot be run: variable _internet_route_established_phrase is not defined”
	error $result $errorInfo
    }
	
##################
# Open CLI
##################

# open cli
if [catch {cli_open} result] {error $result $errorInfo} else {array set cli $result}
# Enable
if [catch {cli_exec $cli(fd) "enable"} result] {error $result $errorInfo}

##################
# Retrieve NVI PAT statements
##################

# Note: "show run | include ip nat source static" should look like: ip nat source static tcp 192.168.33.41 22 interface Dialer1 22

# Execute CLI command and store in variable
if [catch {cli_exec $cli(fd) "show run | include ip nat source static"} result] {error $result $errorInfo} else {set nvi_pat_statements $result}


##################
# Re-enter NVI PAT statements
##################
action_syslog msg "Re-entering following NVI PAT statements:\n$nvi_pat_statements"

if [catch {cli_exec $cli(fd) "configure terminal"} result] {error $result $errorInfo}
if [catch {cli_exec $cli(fd) "$nvi_pat_statements"} result] {error $result $errorInfo}
if [catch {cli_exec $cli(fd) "end"} result] {error $result $errorInfo}

##################
# Close and clean-up
##################
action_syslog msg "Finished updating NVI statements!\n (Cisco should fix this bug, so this workaround can be removed)"
cli_close $cli(fd) $cli(tty_id)