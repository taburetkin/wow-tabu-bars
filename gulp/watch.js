const task = require('./task');
const { watch } = require("gulp");
//provide own configuration file
const buildConfig = require('./config');

const pkg = require("../package.json");
// buildConfig.wowPath - fully qualified path to the wow's interface\addon folder with trailing slash
const dest =  buildConfig.wowPath + pkg.addonName
const build = task(dest);

watch(['src/**/*'], (cb) => {
	console.log("changes detected")
	build();
	cb();
})
