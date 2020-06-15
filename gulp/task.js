const pkg = require("../package.json");
const _ = require("underscore");
const { src, dest, series }  = require("gulp");
const modifyFile = require('gulp-modify-file')


function createTask(destFolder, ...cbs) {

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
			return _.template(content)({ version: pkg.version });
		}))
		.pipe(dest(destFolder + "/"));
	};
	return series(libs, sources, toc, ...cbs);
}


module.exports = createTask;

