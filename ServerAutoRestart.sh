#!/bin/bash
# This Shell Used to Clear Memory and restart palworld server

# cron tool path
# or other tool for palworld
# address: https://github.com/zaigie/palworld-server-tool
TOOL_PATH="/root/PalWorldServerMgr/pst-cli"
CONF_PATH="/root/PalWorldServerMgr/config.yaml"

# restart in seconds
AUTO_RESTART_TIME=60

# broadcast message, If you use raw rcon, please remove space in message!
MESSAGE_BROADCAST="Server Memery Exceeds Threshold!"
MESSAGE_SHUTTING_DOWN_PRE="Server Shutting Down in"
MESSAGE_SHUTTING_DOWN_POST="Seconds!"

# Full tool command
EXECUTE_COMMAND="$TOOL_PATH --config $CONF_PATH"

# Define Threshold for restart palworld service
SWAP_THRESHOLD=90
MEMORY_THRESHOLD=90

# Get Current Swap Usage
SwapUsed=$(free -m | awk '/^Swap:/{print $3}')
# Get Current Memory Usage
MemoryUsed=$(free -m | awk '/^Mem:/{print $3}')

# Get Buff/Cache Size
BuffCache=$(free -m | awk '/^Mem:/{print $6}')
# Get Total Swap 
SwapTotle=$(free -m | awk '/^Swap:/{print $2}')
# Get Total Memory 
MemoryTotle=$(free -m | awk '/^Mem:/{print $2}')

# Calculate Usage
SwapUsage=$(echo "scale=2; $SwapUsed / $SwapTotle * 100" | bc)
MemoryUsage=$(echo "scale=2; $MemoryUsed / $MemoryTotle * 100" | bc)

# Print Memory Usage
echo "Current Swqp Usage $SwapUsage %"
echo "Current Memory Usage $MemoryUsage %"

# Clear Memory Cache
if [ "$BuffCache" -ge "500" ]; then
    echo 3 > /proc/sys/vm/drop_caches
    echo "Current Buff/Cache $BuffCache MB, Clean Buff/Cache..."
fi

# If current usage reached threshold
SwapOverThreshold=$(echo "$SwapUsage > $SWAP_THRESHOLD" | bc -l)
MemoryOverThreshold=$(echo "$MemoryUsage > $MEMORY_THRESHOLD" | bc -l)

# Check threshold And Restart Server
if (( SwapOverThreshold )) && (( MemoryOverThreshold )); then
    # restarting...
    echo "PalWorld Memory Over threshold! Restarting..."
    MESSAGE_SHUTTING_DOWN="$MESSAGE_SHUTTING_DOWN_PRE $AUTO_RESTART_TIME $MESSAGE_SHUTTING_DOWN_POST"

    # Execute command through palworld server cron
    $EXECUTE_COMMAND broadcast -m "$MESSAGE_BROADCAST"
    $EXECUTE_COMMAND server shutdown -s "$AUTO_RESTART_TIME" -m "$MESSAGE_SHUTTING_DOWN"

    # sleep 1
    # broalcast message per seconds
    for ((CountDown = $AUTO_RESTART_TIME - 1; CountDown > 0; CountDown--))
    do
        MESSAGE_SHUTTING_DOWN="$MESSAGE_SHUTTING_DOWN_PRE $CountDown $MESSAGE_SHUTTING_DOWN_POST"
        $EXECUTE_COMMAND broadcast -m "$MESSAGE_SHUTTING_DOWN"
        sleep 1
    done

    # restart using systemd
    systemctl restart palserver.service
fi
