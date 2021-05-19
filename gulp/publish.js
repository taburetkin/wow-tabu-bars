const pkg = require("../package.json");
const path = require("path");
const { exec } = require('child_process');
const { create, enums } = require('./task');
const p1 = path.resolve("publish");
const buildContext = require('./buildContext');
const pubRoot = "publish";
const compiled = pubRoot + "/" + pkg.addonName;

const context = buildContext({ buildFlags: enums.all, destination: compiled });

let task = create(context, cb => {
	let command = `tar -caf publish/${pkg.name}-v${pkg.version}.zip -C ${pubRoot} ${pkg.addonName}`;
	console.log(command);
	exec(command, (e,s,o) => {
		cb();
	});
});

task();
