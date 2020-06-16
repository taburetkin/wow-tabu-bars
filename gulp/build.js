const { create, enums } = require('./task');

//provide own configuration file
const buildConfig = require('./config');

const pkg = require("../package.json");
// buildConfig.wowPath - fully qualified path to the wow's interface\addon folder with trailing slash
const dest =  buildConfig.wowPath + pkg.addonName
const build = create(dest, enums.all);
build();

