const pkg = require("../package.json");
const path = require("path");
const { exec } = require('child_process');
const task = require('./task');
const p1 = path.resolve("publish");


task("publish/test", cb => {
	let command = `tar -cvzf ${p1}\\${pkg.name}-v${pkg.version}.zip ${p1}\\test`;
	exec(command, (e,s,o) => {
		cb();
	});
})();
