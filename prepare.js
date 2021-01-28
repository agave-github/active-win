var { exec } = require('child_process');
var os = require('os');

function puts(error, stdout, stderr) { console.log(stdout) }

if (os.type() === 'Darwin')
	exec("swift build --configuration=release && mv .build/release/active-win main", puts);
