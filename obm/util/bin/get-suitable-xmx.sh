#!/bin/sh

# User defined java heap max in unit of MB
JAVA_HEAP_MAX_IN_MB=1024
JAVA_HEAP_MIN_IN_MB=64
SYSTEM_MEM_RESERVED_IN_MB=512

get_column_value() {
  local STRING_PATTERN="$1"
  local COL_NUM=$2
  echo $STRING_PATTERN | awk -F " " '{print $'"${COL_NUM}"'}'
}

linux_get_ram_info_in_kb() {
  # Check the value by "cat /proc/meminfo"
  MEMORY_INFO=`cat /proc/meminfo | grep MemTotal:`
  TOTAL_MEMORY_IN_KB=`get_column_value "$MEMORY_INFO" 2`
  echo "$TOTAL_MEMORY_IN_KB"
}

get_physical_memory_in_kb() {
  linux_get_ram_info_in_kb
}

SYSTEM_PHYSICAL_MEMORY_IN_KB=`get_physical_memory_in_kb`
SYSTEM_PHYSICAL_MEMORY_IN_MB=`expr $SYSTEM_PHYSICAL_MEMORY_IN_KB / 1024`

if [ $SYSTEM_PHYSICAL_MEMORY_IN_MB -le 1024 ];then
  if [ $SYSTEM_PHYSICAL_MEMORY_IN_MB -le 512 ];then
    if [ $SYSTEM_PHYSICAL_MEMORY_IN_MB -le 256 ];then
      # 1) MEM <= 256MB
      SYSTEM_MEM_RESERVED_IN_MB=96
    else 
      # 2) 256MB < MEM <= 512MB
      SYSTEM_MEM_RESERVED_IN_MB=128
    fi
  else 
    # 3) 512MB < MEM <= 1GB
    SYSTEM_MEM_RESERVED_IN_MB=256
  fi
else
  # 4) MEM > 1GB
  SYSTEM_MEM_RESERVED_IN_MB=512
fi

# Note: DON'T specify MAX_MEMORY with a value greater than the physical memory size
JAVA_XMX_VALUE=""

SYSTEM_AVAILABLE_MEMORY=`expr $SYSTEM_PHYSICAL_MEMORY_IN_MB - $SYSTEM_MEM_RESERVED_IN_MB`
if [ $JAVA_HEAP_MAX_IN_MB -ge $SYSTEM_AVAILABLE_MEMORY ]; then
  JAVA_XMX_VALUE="$SYSTEM_AVAILABLE_MEMORY"
else
  JAVA_XMX_VALUE="$JAVA_HEAP_MAX_IN_MB"
fi

# Use the minimum supported value for Xmx if it is too small
[ $JAVA_HEAP_MIN_IN_MB -ge $JAVA_XMX_VALUE ] && JAVA_XMX_VALUE="$JAVA_HEAP_MIN_IN_MB"

echo $JAVA_XMX_VALUE
