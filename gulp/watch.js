const { create, enums } = require('./task');

const { watch } = require("gulp");
//provide own configuration file
const buildConfig = require('./config');

const pkg = require("../package.json");
// buildConfig.wowPath - fully qualified path to the wow's interface\addon folder with trailing slash
const dest =  buildConfig.wowPath + pkg.addonName

const done = cb => {
	let a = new Date();	
	console.log("done", a.toLocaleTimeString());
	cb();
}

const buildSrc = create(dest, enums.sources, done);
const buildLibs = create(dest, enums.libs, done);



watch(['src/**/*'], (cb) => {
	console.log("changes detected")
	buildSrc();
	cb();
});
//
watch(['../Tabu/**/*'], (cb) => {
	console.log("Tabu changes detected");
	buildLibs();
	cb();
});
