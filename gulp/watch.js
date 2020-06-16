const { create, enums } = require('./task');

const { watch } = require("gulp");
//provide own configuration file
const buildConfig = require('./config');

const pkg = require("../package.json");
// buildConfig.wowPath - fully qualified path to the wow's interface\addon folder with trailing slash
const dest =  buildConfig.wowPath + pkg.addonName

const buildSrc = create(dest, enums.sources);
const buildLibs = create(dest, enums.libs);



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
