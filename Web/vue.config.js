module.exports = {
    css: {
        loaderOptions: {
            sass: {
                // use dart-sass (sass) thay cho node-sass tren Node hien dai
                implementation: require('sass')
            }
        }
    },
    devServer: {
        disableHostCheck: true
    }
};
