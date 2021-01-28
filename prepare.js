var sys = require('sys');
var exec = require('child_process').exec;
var os = require('os');

function puts(error, stdout, stderr) { sys.puts(stdout) }

if (os.type() === 'Darwin')
	exec("npm run build", puts);
else
	throw new Error("Unsupported OS found: " + os.type());
