const pkg = require("../package.json");
const _ = require("underscore");
const { src, dest, series }  = require("gulp");
const modifyFile = require('gulp-modify-file');
const del = require("del");

const flagsEnum = {
	clean: 1,
	libs: 2,
	sources: 4,
	toc: 8,
}

const libsToCopy = [
	{
		base: '../../Tabu',
		paths: [
			"../GetSpellCountFix/**/*", 
			"../Tabu/**/*"			
		]
	},
	{
		base: '../../Ace',
		paths: [
			"../../Ace/LibStub/**/*",
			"../../Ace/CallbackHandler-1.0/**/*",
			"../../Ace/LibSharedMedia-3.0/**/*"		
		]
	},
]


flagsEnum.all = flagsEnum.clean | flagsEnum.libs | flagsEnum.sources | flagsEnum.toc;

function createTask(destFolder, flags, ...cbs) {

	flags = flags | 255;

	const clean = () => {
		return del([destFolder + '/**/*']);
	}

	const libs = () => {

		let tasks = _.map(libsToCopy, cntx => {
			return () => {
				return src(cntx.paths, { base: cntx.base })
				.pipe(dest(destFolder + "/Libs"));
			}
		});
		return tasks;

		// return src(libsToCopy, { base: "../../Tabu"})
		// .pipe(dest(destFolder + "/Libs"));
	};

	const sources = () => {
		return src("src/**/*")
		.pipe(dest(destFolder + "/"));
	};

	const toc = () => {
		return src("src/Tabu-Bars.toc")
		.pipe(modifyFile((content, path, file) => {
			return _.template(content)({ 
				version: pkg.version,
				name: pkg.addonName,
				nametrunc: pkg.addonName.replace(/\W/gm, '')
			});
		}))
		.pipe(dest(destFolder + "/"));
	};

	let arr = [];

	if ((flags & flagsEnum.clean) == flagsEnum.clean) {
		arr.push(clean);
	}

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

	return series(...arr);
}


module.exports.create = createTask;
module.exports.enums = flagsEnum;

