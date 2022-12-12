#!/usr/bin/env bash
# Usage: save custom startup as below
# exec /home/site/wwwroot/init.sh
#
# With this startup script, SIGTERM will be handled and proxied to the application process,
# The application process could be stopped gracefully
# Logs will be written to /home/LogFiles/<COMPUTERNAME>-lifecycle.log
#
# Options:
# USE_PM2: true/false, default is true
# SHUTDOWN_HOOK_URL: url to post shutdown event, default is empty

CURRENT_PATH=`cd $(dirname ${0}) && pwd`
CURRENT_FILE="${CURRENT_PATH}/init.sh"
LOGFILE_PATH="/home/LogFiles"
LOGFILE="${LOGFILE_PATH}/${COMPUTERNAME}-lifecycle.log"

RUNNER="node"
if [ "$USE_PM2" != false ]; then
  RUNNER="pm2"
fi

# https://gist.github.com/georgeOsdDev/706886b4818071d8980ef7141aa2ec8a
CONTAINER_ID=$(cat /proc/self/cgroup | grep docker | grep $WEBSITE_SITE_NAME | head -1| rev | cut -d "/" -f 1 | rev)

logevent() {
  echo `date "+%Y-%m-%dT%H:%M:%S.%3N%z"` "[StartScript] Message: $1, Event: $2, COMPUTERNAME: ${COMPUTERNAME}, CONTAINER_ID: ${CONTAINER_ID}" >> ${LOGFILE}
}
hookevent() {
  timestamp=`date "+%Y-%m-%dT%H:%M:%S.%3N%z"`
  postdata="message=$1&event=$2&computername=${COMPUTERNAME}&container_id=${CONTAINER_ID}&timestamp=${timestamp}"
  # echo $postdata
  if [ -n "$SHUTDOWN_HOOK_URL" ]; then
    curl -s -X POST "${SHUTDOWN_HOOK_URL}" -d "$postdata" -H "Content-Type: application/x-www-form-urlencoded"
  fi
}


handler0() {
  logevent "'Handling SIGEXIT, init.sh stopped'" "SIGEXIT"
  hookevent "'Handling SIGEXIT, init.sh stopped'" "SIGEXIT"
}
handler15() {
  logevent "'Handling SIGTERM, stopping process PID: ${pid}'" "SIGTERM"
  hookevent "'Handling SIGTERM, stopping process PID: ${pid}'" "SIGTERM"

  # For pm2
  if [[ "$RUNNER" == "pm2" ]]; then
    pm2 stop all
  fi

  # For node
  if [[ "$RUNNER" == "node" ]]; then
    kill -s TERM $pid
  fi
}
trap handler0 0 # SIGEXIT
trap handler15 15 # SIGTERM

# Startup
# for pm2
START_MSG="Process started"
if [[ "$RUNNER" == "pm2" ]]; then
  pm2 start index.js --name "app" -i max --no-daemon --kill-timeout 1000 &
  pid=$!
  START_MSG="${START_MSG} with pm2, PID: ${pid}"
fi

if [[ "$RUNNER" == "node" ]]; then
  node index.js &
  pid=$!
  START_MSG="${START_MSG} with node, PID: ${pid}"
fi

logevent "${START_MSG}" "startup"
hookevent "${START_MSG}" "startup"

wait $pid
