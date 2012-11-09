::cisco::eem::event_register_timer cron name crontimer2 cron_entry $_dmvpn_cron maxrun 20
#::cisco::eem::event_register_none
namespace import ::cisco::lib::*
namespace import ::cisco::eem::*

##################
# Check for global definition of environment variables
if {![info exists _dmvpn_hub]} {
	set result /
	“Policy cannot be run: variable _dmvpn_hub is not defined”
	error $result $errorInfo
    }
if {![info exists _dmvpn_cron]} {
	set result /
	“Policy cannot be run: variable _dmvpn_cron is not defined”
	error $result $errorInfo
    }
##################
# Open CLI
if [catch {cli_open} result] {error $result $errorInfo} else {array set cli $result}
# Enable
if [catch {cli_exec $cli(fd) "enable"} result] {error $result $errorInfo}
##################
# Execute CLI command and store in variable
if [catch {cli_exec $cli(fd) "ping $_dmvpn_hub"} result] {error $result $errorInfo} else {set ping_output $result}
# Filter string to IP address
regexp {.*Echos to ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)} $ping_output complete_string resolved_ip
action_syslog msg "resolved_ip is $resolved_ip"
##################
# Get show run int t0
if [catch {cli_exec $cli(fd) "show run interface tunnel0"} result] {error $result $errorInfo} else {set showrun_ouput $result}
# Filter string
regexp {.*ip nhrp map multicast ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)} $showrun_ouput complete_string multicast1
action_syslog msg "multicast1 is $multicast1"
##################
# Change address if it is different. If string compare returns 0, adrresses are the same.
if {[string compare "$resolved_ip" "$multicast1"]==0} {
	action_syslog msg "Addresses are the same. No change."

} else {
	if [catch {cli_exec $cli(fd) "configure terminal"} result] {error $result $errorInfo}
	if [catch {cli_exec $cli(fd) "no ip nhrp map multicast $multicast1"} result] {error $result $errorInfo}
	action_syslog msg "removing address $multicast1"
	if [catch {cli_exec $cli(fd) "interface tunnel0"} result] {error $result $errorInfo}
	if [catch {cli_exec $cli(fd) "ip nhrp map 192.168.55.52 $resolved_ip"} result] {error $result $errorInfo}
	if [catch {cli_exec $cli(fd) "ip nhrp map multicast $resolved_ip"} result] {error $result $errorInfo}
	action_syslog msg "interface tunnel0 dmvpn_hub address updated with ip $resolved_ip"
	if [catch {cli_exec $cli(fd) "end"} result] {error $result $errorInfo}
}
###################


# print confirmation
action_syslog msg "Finished Script. (GOOD!)"

# Close CLI
cli_close $cli(fd) $cli(tty_id)

