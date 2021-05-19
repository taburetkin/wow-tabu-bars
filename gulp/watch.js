const { create, enums } = require('./task');

const { watch } = require("gulp");
//provide own configuration file
const buildConfig = require('./config');

const buildContext = require('./buildContext');

const srcContext = buildContext({ buildFlags: enums.sources });
const libContext = buildContext({ buildFlags: enums.libs });


//const pkg = require("../package.json");
// buildConfig.wowPath - fully qualified path to the wow's interface\addon folder with trailing slash
//const dest =  buildConfig.wowPath + pkg.addonName

const done = cb => {
	let a = new Date();	
	console.log("done", a.toLocaleTimeString());
	cb();
}

const buildSrc = create(srcContext, done);
const buildLibs = create(libContext, done);



watch(['src/**/*'], (cb) => {
	let moment = new Date();
	console.log("changes detected: ", moment.toLocaleTimeString())
	buildSrc();
	cb();
});


let libsPaths = buildConfig.libsToCopy.reduce((memo, lib) => {
	if(!lib.watchChanges) return memo;
	memo.push(...lib.paths);
	return memo;
}, []);


watch(libsPaths, (cb) => {
	let moment = new Date();
	
	console.log("Tabu changes detected: ", moment.toLocaleTimeString());
	buildLibs();
	cb();
});
