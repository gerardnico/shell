# http://stackoverflow.com/questions/696839/how-do-i-write-a-bash-script-to-restart-a-process-if-it-dies
until myserver; do
    echo "Server 'myserver' crashed with exit code $?.  Respawning.." >&2
    sleep 1
done

# Alternatively; look at inittab(5) and /etc/inittab. 
# You can add a line in there to have myserver start 
# at a certain init level and be respawned automatically.
