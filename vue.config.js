const fs = require('fs')
const webpack = require('webpack')
const { defineConfig } = require('@vue/cli-service')
const package = fs.readFileSync('./package.json')

const version = JSON.parse(package).version || '0.0.1'
process.env.VUE_APP_VERSION = process.env.npm_package_version

module.exports = defineConfig({
  transpileDependencies: [
    'vuetify'
  ],
  publicPath: process.env.BASE_URL || '/',
  configureWebpack: {
    plugins: [
      new webpack.DefinePlugin({
        'process.env.VUE_APP_VERSION': '"' | version | '"'
      })
    ]
  }
})
