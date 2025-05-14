#!/bin/bash

# Get CPU usage
cpu_usage=$(top -l 1 -n 0 | awk '/CPU usage/ {
  sub(/%/, "", $3); print $3
}')

# Get memory usage
mem_stats=$(vm_stat)
pages_used=$(echo "$mem_stats" | awk '/Pages active/ {gsub("\\.",""); print $3}')
pages_wired=$(echo "$mem_stats" | awk '/Pages wired down/ {gsub("\\.",""); print $4}')
page_size=$(vm_stat | head -n 1 | awk '{print $8}')
page_size=${page_size%*B}

total_used_pages=$((pages_used + pages_wired))
used_mem_gb=$(echo "$total_used_pages * $page_size / 1024 / 1024 / 1024" | bc -l)
used_mem_gb=$(printf "%.1f" "$used_mem_gb")
total_mem_gb=$(sysctl -n hw.memsize)
total_mem_gb=$(echo "$total_mem_gb / 1024 / 1024 / 1024" | bc)

# Get network usage (since boot)
rx_bytes=$(netstat -ib | awk 'NR>1 && $1 != "lo0" {rx[$1]+=$7} END {total=0; for (i in rx) total+=rx[i]; print total}')
tx_bytes=$(netstat -ib | awk 'NR>1 && $1 != "lo0" {tx[$1]+=$10} END {total=0; for (i in tx) total+=tx[i]; print total}')

# To simulate instantaneous usage, you could add a small delay and compare values
sleep 1
rx_bytes2=$(netstat -ib | awk 'NR>1 && $1 != "lo0" {rx[$1]+=$7} END {total=0; for (i in rx) total+=rx[i]; print total}')
tx_bytes2=$(netstat -ib | awk 'NR>1 && $1 != "lo0" {tx[$1]+=$10} END {total=0; for (i in tx) total+=tx[i]; print total}')

rx_rate=$(( (rx_bytes2 - rx_bytes) / 1024 )) # in KB
tx_rate=$(( (tx_bytes2 - tx_bytes) / 1024 )) # in KB

summary="CPU: ${cpu_usage}%; Mem: ${used_mem_gb}/${total_mem_gb}G; Net: ${rx_rate}k↓/${tx_rate}k↑"
echo '
{
  "text": "'$summary'"
}'

