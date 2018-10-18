/*
	Server Setup
 */
var express = require("express");
var http = require("http");
var path = require("path");
var bodyParser = require("body-parser");
var config = require("config");
//var socketMng = require("./socketManage");

var app = express();

// Timezone changed
process.env.TZ = 'Asia/Tokyo';

// SERVER SETUP -----------------------------------
// port setting
var port = process.env.PORT || process.env.app_port || config.serverSetup.listen_port;
app.set('port', port);

// view engine
app.set('views', './client/render');
app.set('view engine', 'jade');

// body parser
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

// default resource place
app.use('/', express.static('docs'));

// ROUTING ----------------------------------------
//var routes = require("./routeManage.js")(app);

// SERVER BUILD -----------------------------------
// listen on PORT
var server = http.createServer(app);
server.listen(port);
//socketMng.toListen(server);

console.log("Express server listening...");

module.exports = server;
