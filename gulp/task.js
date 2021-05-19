const pkg = require("../package.json");
const _ = require("underscore");
const { src, dest, series }  = require("gulp");
const modifyFile = require('gulp-modify-file');
const rename = require('gulp-rename');
const del = require("del");
const gulpClean = require('gulp-clean');
const buildConfig = require('./config');

const flagsEnum = {
	clean: 1,
	libs: 2,
	sources: 4,
	toc: 8,
}

const libsToCopy = buildConfig.libsToCopy;
// [
// 	// {
// 	// 	base: '../../Tabu',
// 	// 	paths: [
// 	// 		"../GetSpellCountFix/**/*", 
// 	// 		"../Tabu/**/*"			
// 	// 	]
// 	// },
// 	{
// 		base: '../../Ace',
// 		paths: [
// 			"../../Ace/LibStub/**/*",
// 			"../../Ace/CallbackHandler-1.0/**/*",
// 			"../../Ace/LibSharedMedia-3.0/**/*"		
// 		]
// 	},
// 	{
// 		base: '../../Tabu',
// 		paths: [
// 			"../Tabu-Lib-FrameBuilder/**/*",
// 		]
// 	},	
// ]


flagsEnum.all = flagsEnum.clean | flagsEnum.libs | flagsEnum.sources | flagsEnum.toc;

function createTask(context, ...cbs) {

	let date = new Date();
	let buildTime = date.toLocaleDateString() + " " + date.toLocaleTimeString();

	let destFolder = context.destination;
	let flags = context.buildFlags;
	let interfaceVersion = context.client.version;
		//pkg.interfaces[context.client];
	flags = flags | 255;

	const clean = () => {
		console.log('cleaning:', destFolder);
		return src(destFolder, { read: false })
				.pipe(gulpClean({ force: true }))
		//return del.sync([destFolder + '/**']);
	}

	const libs = () => {

		let tasks = _.map(libsToCopy, cntx => {
			return () => {
				return src(cntx.paths, { base: cntx.base })
				.pipe(dest(destFolder + "/Libs"));
			}
		});
		return tasks;
	};

	const sources = () => {
		return src("src/**/*")
		.pipe(dest(destFolder + "/"));
	};

	const toc = () => {
		return src("src/" + pkg.addonName + ".toc")
		.pipe(modifyFile((content, path, file) => {
			return _.template(content)({ 
				interfaceVersion,
				version: pkg.version,
				name: pkg.addonName,
				nametrunc: pkg.addonName.replace(/\W/gm, ''),
				description: pkg.description
			});
		}))
		.pipe(dest(destFolder + "/"));
	};


	const buildinfo = () => {
		return src("gulp/build-info.lua.template")
		.pipe(modifyFile((content, path, file) => {
			console.log('modifiyng build info')
			return _.template(content)({
				buildTime: buildTime,
				realm: context.realm,
				version: context.client.version,
				maxVersion: context.client.maxVersion | 'nil',
				nightly: context.client.nightly == true
			});
		}))
		.pipe(rename('build-info.lua'))
		.pipe(dest(destFolder + '/'))
	}

	let arr = [];
	
	
	let decline = false;
	if (((flags & flagsEnum.clean) == flagsEnum.clean) || context.useTestPath) {
		arr.push(clean);
	}

	arr.push(buildinfo);

	if ((flags & flagsEnum.libs) == flagsEnum.libs) {
		arr.push(...libs());
	}

	if ((flags & flagsEnum.sources) == flagsEnum.sources) {
		arr.push(sources);
	}

	if ((flags & flagsEnum.toc) == flagsEnum.toc) {
		arr.push(toc);
	}
	arr.push(...cbs);

	if (arr.length) {
		console.log('running series');
		return series(...arr);
	} else {
		return (...args) => console.log(...args);
	}

}


module.exports.create = createTask;
module.exports.enums = flagsEnum;

