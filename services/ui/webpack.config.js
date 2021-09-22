const ESLintPlugin = require('eslint-webpack-plugin');
const HtmlWebPackPlugin = require("html-webpack-plugin");
const path = require('path');
const webpack = require('webpack')


const htmlPlugin = new HtmlWebPackPlugin({
 template: "./src/index.html",
 filename: "./index.html"
});

module.exports = {
  mode: "development",
  module: {
    rules: [{
      test: /\.js$/,
      exclude: /node_modules/,
      use: {
        loader: "babel-loader"
      }
    },
    {
      test: /\.css$/,
      use: ["style-loader", "css-loader"]
    },
    {
      test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
      use: [
        {
          loader: 'file-loader',
          options: {
            name: '[name].[ext]',
            outputPath: 'fonts/'
          }
        }
      ]
    },
    {
      test: /\.png$/,
      use: [
        {
          loader: 'file-loader',
          options: {
            name: '[name].[ext]',
            outputPath: 'images/'
          }
        }
      ]
    }
    ]
  },
  output: {
    path: path.resolve(__dirname, 'dist')
  },
  plugins: [
    htmlPlugin,
    new ESLintPlugin(),
    new webpack.DefinePlugin({
      URL_FORTUNES: JSON.stringify(
        process.env.URL_FORTUNES ? process.env.URL_FORTUNES : 'https://api.pluribuslab.com/v1/fortunes/'
      ),
      URL_NAMES: JSON.stringify(
        process.env.URL_NAMES ? process.env.URL_NAMES : 'https://api.pluribuslab.com/v1/names/'
      )
    })
  ]
};
