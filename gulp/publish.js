const pkg = require("../package.json");
const path = require("path");
const { exec } = require('child_process');
const task = require('./task');
const p1 = path.resolve("publish");

const compiled = "publish/compiled"
task(compiled, cb => {
	let command = `tar -caf publish/${pkg.name}-v${pkg.version}.zip -C ${compiled} *`;
	console.log(command);
	exec(command, (e,s,o) => {
		cb();
	});
})();
