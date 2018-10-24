'use strict';

var gulp = require('gulp');
var config = require("config");

var watch = require("gulp-watch");
var browserSync = require('browser-sync');
var nodemon = require('gulp-nodemon');

var riot = require('gulp-riot');
var pug = require("gulp-pug");
var scss = require('node-sass');

var browserify = require('browserify');
var riotify = require('riotify');
var bubleify = require("bubleify");
var envity = require("envify/custom");
var gulp_obf = require("gulp-javascript-obfuscator");
var vsource = require('vinyl-source-stream');
var sourcemap = require("gulp-sourcemaps");

var listen_port = config.serverSetup.listen_port;
var proxy_port = config.serverSetup.proxy_port;
var is_debug = config.gulpfile.is_debug;
var obfuscator = config.gulpfile.obfuscator;

// --------------------------------------------
// for envity
var Envs = {
	BITLY_ACCESS_TOKEN: config.bitly.acc_token
};


// --------------------------------------------
// browserSync
gulp.task('browser-sync', () => {
	browserSync.init(null, {
		proxy: `http://localhost:${listen_port}`,
		port: proxy_port,
		open: false
	});
	gulp.watch("./public/**/*").on("change", browserSync.reload);
});

// for nodemon function
function nodemonfunc(is_inspect) {
	nodemon({
		exec: `node ${is_inspect?"--inspect":""}`,
		script: 'server/index.js',
		ext: 'js json yaml',
		ignore: [  // nodemon で監視しないディレクトリ
			'node_modules',
			'client',
			'public',
			'docs',
			'test'
		],
		env: {
			'PORT': listen_port,
			'NODE_ENV': 'development'
		},
		stdout: false  // Express の再起動時のログを監視するため
	})
	.on('readable', function() {
		this.stdout.on('data', function(chunk) {
			if (/^Express server listening/.test(chunk)) {
				// Express の再起動が完了したら、reload() でBrowserSync に通知。
				// ※Express で出力する起動時のメッセージに合わせて比較文字列は修正
				browserSync.reload({ stream: false });
			}
			process.stdout.write(chunk);
		});
		this.stderr.on('data', function(chunk) {
			process.stderr.write(chunk);
		});
	});
}
// nodemon
gulp.task('nodemon', () => nodemonfunc(false) );
// nodemon-debug
gulp.task('nodemon-debug', () => nodemonfunc(true) );


// --------------------------------------------
// Riot browserfy
gulp.task('riot-browserfy', () =>{
	return browserify({
		debug: is_debug,
		entries: [
			'./client/main.js'
		]
	}).transform(bubleify, {
	}).transform(riotify, {
		template: "pug",
		compact: true,    // HTML圧縮
		_flag: {
			debug: is_debug
		},
		//style: 'scssmin', // CSS圧縮関数を指定↓
		parsers: {
			css: {
				// node-sassを使って圧縮する関数
				scss: function (tag, css) {
					var result = scss.renderSync({
						data: css,
						outputStyle: is_minify ? 'compressed' : undefined,
					});
					return result.css.toString();
				}
			}
		}
	}).transform(envity(Envs)).bundle()
		.pipe(vsource('bundle.js'))
		//.pipe(sourcemap.init())
		//.pipe(sourcemap.write())
		.pipe(gulp.dest('./docs/'));
});

// obfuscator
gulp.task('obfuscator', ["riot-browserfy"], () => {
	var s = gulp.src('./docs/bundle.js');
	if(!is_debug && obfuscator){
		s.pipe(gulp_obf({
			sourceMap: false
		})).pipe(gulp.dest('./docs/'));
	}
	return s;
});

// obfuscator(pre-commit)
gulp.task('obfuscator-must', ["riot-browserfy"], () => {
	return gulp.src('./docs/bundle.js')
		.pipe(gulp_obf({
			sourceMap: false
		}))
		.pipe(gulp.dest('./docs/'));
});

// watching
gulp.task("watchResource", () => {
	gulp.watch(['./client/**/*'],
	[
		'compile',
	]);
});

// --------------------------------------------
// compile
gulp.task("compile", ["riot-browserfy", "obfuscator"], () => {
	
});

// compile
gulp.task("compile-precommit", ["riot-browserfy", "obfuscator-must"], () => {
	
});

// serve
gulp.task('serve', ['compile', 'nodemon', 'browser-sync', 'watchResource'], function () {
	
});

// serve
gulp.task('serve-debug', ['compile', 'nodemon-debug', 'browser-sync', 'watchResource'], function () {
	
});

