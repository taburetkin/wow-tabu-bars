const pkg = require("../package.json");
const _ = require("underscore");
const { src, dest, series }  = require("gulp");
const modifyFile = require('gulp-modify-file');
//const cleanDest = require("gulp-clean-dest");
const del = require("del");

function createTask(destFolder, ...cbs) {

	const clean = () => {
		return del([destFolder + '/**/*']);
	}

	const libs = () => {
		return src(["../GetSpellCountFix/**/*", "../Tabu/**/*"], { base: "../../Tabu"})
		.pipe(dest(destFolder + "/Libs"));
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
	return series(clean, libs, sources, toc, ...cbs);
}


module.exports = createTask;

