# process_check.sh
# get_pid plagiarised from OBIEE common.sh
# RNM 2009-04-03
# RNM 2009-04-30 Exclude root processes (getting false positive from OpenView polling with process name)
# http://rnm1978.wordpress.com/2009/08/14/unix-script-to-report-on-obiee-and-obia-processes-state/

get_pid() {
  # the second grep excludes the grep process from matching itself, the third one is a hacky way to avoid root processes
  pgrep "$1" | grep -v grep | grep -v "    root " | awk '{print $1}'
}

is_process_running() {
  process=$1
  #echo $process
  process-id="$(get_pid "$process")"
  if test "$process-id"; then
    echo "yes"
  else
    echo "no"
  fi
}
