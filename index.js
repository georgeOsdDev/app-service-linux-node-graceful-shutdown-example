var http = require('http');
var express = require('express')
var app = express()


const fs = require("fs");
const LOGFILE = `/home/LogFiles/${process.env.COMPUTERNAME}-lifecycle.app.log`
const getlogTimeStampAndPrefix = () => `${new Date().toISOString().replace('Z','+0000')} [Application.${process.pid}]`;
const writeLog = (msg) => {
  const text = `${getlogTimeStampAndPrefix()} ${msg}`
  // console.log will not forwarded to AppServiceConsoleLogs or docker_default.log any more, so we need to write log to a file
  console.log(text)
  // write log to a file
  try {
    fs.appendFileSync(LOGFILE, `${text}\n`);
  } catch (err) {}
}


// start log
const START_MSG = `Node process started.`
writeLog(START_MSG);

app.get('/', function (req, res) {
  const wait = req.query.wait || 0
  setTimeout(() => {
    res.send('hello world')
  }, wait*1000)
})
const server = http.createServer(app)


process.on('SIGTERM', () => {
  const SIGTERM_MSG = `SIGTERM received, shutting down.`
  writeLog(SIGTERM_MSG);

  // do something before exit
  // server.close, release connection etc...

  server.close((e) => {
    const SERVER_CLOSED_MSG = `Server closed ${e ? `with error: ${e}` : 'successfully'}`
    writeLog(SERVER_CLOSED_MSG, e);
    // exit
    process.exit(0);
  });
});

// PM2 will send a SIGINT to the process when it restart/reload/stop processes
// https://pm2.keymetrics.io/docs/usage/signals-clean-restart/
process.on('SIGINT', () => {
  const SIGINT_MSG = `SIGINT received, shutting down.`
  writeLog(SIGINT_MSG);

  // do something before exit
  // server.close, release connection etc...

  server.close((e) => {
    const SERVER_CLOSED_MSG = `Server closed ${e ? `with error: ${e}` : 'successfully'}`
    writeLog(SERVER_CLOSED_MSG, e);
    // exit
    process.exit(0);
  });

});
server.listen(process.env.PORT || '3000', () => {
  console.log(`Server running on port ${process.env.PORT || '3000'}`)
})
