const pkg = require("../package.json");
const buildConfig = require('./config');
const path = require('path');
const clientsKeys = Object.keys(buildConfig.clients);

module.exports = function(mergeWith) {
    const context = {
        realm: 'classic'
    };
    
    Object.assign(context, mergeWith);

    process.argv.forEach(v => {
        if (v == 'test-folder') {
            context.useTestPath = true;
            return;
        }
        if (clientsKeys.indexOf(v) > -1) {
            context.realm = v;
            return;
        }
    });
    
    context.client = buildConfig.clients[context.realm];

    //context.destination = buildConfig.wowPaths[context.client] + pkg.addonName
    
    let clientPath = context.client.path + pkg.addonName;
    let testPath = path.resolve(buildConfig.testPath);
    if (!context.destination) {
        context.destination = context.useTestPath ? testPath : clientPath;
    }

    return context;
}
