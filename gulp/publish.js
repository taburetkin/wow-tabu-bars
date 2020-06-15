const pkg = require("../package.json");
const path = require("path");
const { exec } = require('child_process');
const task = require('./task');
const p1 = path.resolve("publish");


task("publish/test", cb => {
	let archive = `${p1}\\${pkg.name}-v${pkg.version}.zip`;
	let folder = p1 + '\\test';
	let command = `tar -cvzf ${p1}\\${pkg.name}-v${pkg.version}.zip ${p1}\\test`;
	command = `tar -a -c -f ${archive} ${folder}`
	exec(command, (e,s,o) => {
		cb();
	});
})();
