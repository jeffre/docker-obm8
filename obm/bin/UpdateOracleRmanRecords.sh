#################  delete-archive-logs.sh  #################################
# You can use this batch to delete all archived logs entry from RMAN       #
# database. The RMAN script file 'delete-archive-logs.rman' must also be   #
# saved in the same directory of this file for this script to function     #
# correctly. You can add this script as a post-backup command to delete    #
# all archived logs in the recovery catalog correctly to prevent the       #
# "ORA-00257 archiver error".                                              #
############################################################################

#---------------------------  CONNECT_STRING  ------------------------------
# You must provide a valid connect string with system privileges           |
# to the oracle database.                                                  |
# e.g. CONNECT_STRING=sys/sys@orcl                                         |
#---------------------------------------------------------------------------
CONNECT_STRING=

#-------------------------------  CATALOG  ---------------------------------
# The recovery catalog to connect to. Default to nocatalog                 |
# e.g. CATALOG=nocatalog                                                   |
#  or  CATALOG=catalog RMAN/RMAN@OEMREP                                    |
#---------------------------------------------------------------------------
CATALOG=nocatalog

#-------------------------  LOG_RETENTION_DAYS  ----------------------------
# Number of days of logs to retain, older logs will be deleted             |
# e.g. LOG_RETENTION_DAYS=60                                               |
#---------------------------------------------------------------------------
LOG_RETENTION_DAYS=

####################  END: User Defined Section  ###########################
CMDFILE=UpdateOracleRmanRecords.rman

# ############################## Check config ##############################
if [ ! "$1" == "" ]; then CONNECT_STRING=$1
fi
if [ "${CONNECT_STRING}" == "" ]; then CONNECT_STRING=/
fi
if [ ! "$2" == "" ]; then LOG_RETENTION_DAYS=$2
fi
if [ "${LOG_RETENTION_DAYS}" == "" ]; then LOG_RETENTION_DAYS=60
fi

${ORACLE_HOME}/bin/rman target ${CONNECT_STRING} ${CATALOG} cmdfile=${CMDFILE} ${LOG_RETENTION_DAYS}
