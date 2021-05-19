const { create, enums } = require('./task');
//const pkg = require("../package.json");
//const buildConfig = require('./config');
const buildContext = require('./buildContext');

const context = buildContext({ buildFlags: enums.all });
console.log('# build', context);

//const dest =  buildConfig.wowPath + pkg.addonName
const build = create(context);
    //create(dest, enums.all);
build();

