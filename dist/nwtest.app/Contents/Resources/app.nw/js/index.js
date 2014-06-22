/* global angular */
'use strict';

(function(){

	/*
	 * Set up Anglular
	 */

	var app = angular.module('Laytech', ['ui.ace']);

	app.controller('AppController', [ '$scope', function($scope) {
		
		$scope.aceLoaded = function(_editor) {
			console.log('SUP' + _editor);
		};

		$scope.aceChanged = function(e) {
			console.log('SUP');
			console.dir(e);
		};

	}]);



	var latex = require("latex");
	var fs    = require("fs");

	var outfile = fs.createWriteStream('./tmp/document.pdf');

	var ld = [
		"\\documentclass{article}",
		"\\begin{document}",
		"hello world",
		"\\end{document}" ]

	latex(ld.join()).pipe(outfile); //.pipe(process.stdout)

	//$("#preview").

	// fs.writeFile("./himom.txt", "Hi mom!", function(err) {
	//     if(err) {
	//         alert("error");
	//         console.log(err)
	//     }
	// });


})(); 