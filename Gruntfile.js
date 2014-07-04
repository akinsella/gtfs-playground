var path = require("path");
var _ = require("underscore")._;
var moment = require("moment");
var util = require("util");
var path = require('path-extra');

module.exports = function(grunt) {

	grunt.initConfig({

		pkg: grunt.file.readJSON('package.json'),

		clean:{
			dev: {
				src: ["build", "dist", "coverage"]
			}
		},
		copy:{
			dev:{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'src/javascript/',
						src: ['**/*.js'],
						dest: 'build/'
					},
					{
						expand: true,
						flatten: false,
						cwd: 'data/',
						src: ['**/*'],
						dest: 'build/data/'
					}
				]
			},
			'public':{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'public/',
						src: ['**/*'],
						dest: 'build/public/'
					}
				]
			},
			'views':{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'views/',
						src: ['**/*'],
						dest: 'build/views/'
					}
				]
			},
			'node_modules':{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'node_modules/',
						src: ['**/*'],
						dest: 'build/node_modules/'
					}
				]
			},
			'package':{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: '',
						src: ['package.json'],
						dest: 'build/'
					}
				]
			},
			'certs':{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'certs/',
						src: ['**/*'],
						dest: 'build/certs/'
					}
				]
			},
			'data':{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'data/',
						src: ['**/*'],
						dest: 'build/data/'
					}
				]
			},
			test:{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'test/data/',
						src: ['**/*'],
						dest: 'build/test/data/'
					}
				]
			}
		},
		coffee: {
			dev:{
				options: {
					sourceMap: false
				},
				expand: true,
				cwd: 'src/coffee/',
				src: ['**/*.coffee'],
				dest: 'build/',
				ext: '.js'
			},
			test:{
				options: {
					sourceMap: false
				},
				expand: true,
				cwd: 'test/coffee/',
				src: ['**/*.coffee'],
				dest: 'build/test/',
				ext: '.js'
			}
		},
		compress: {
			dist: {
				options: {
					archive: 'dist/<%= pkg.name %>-<%= pkg.version %>-dist.tar.gz'
				},
				files: [
					{ src: ['build/**'], dest: '/' }
				]
			}
		},
		sshconfig: {
			recette: {
				host: 'localhost',
				username: 'jdoe',
				privateKey: grunt.file.read(path.homedir() + "/.ssh/id_rsa"),
				agent: process.env.SSH_AUTH_SOCK
			}
		},
		sshexec: {
			server_stop: {
				command: 'sudo stop <%= pkg.name %>',
				options: {
					ignoreErrors: true
				}
			},
			server_start: {
				command: 'sudo start <%= pkg.name %>'
			},
			server_cleanup: {
				command: 'rm -rf /opt/applications/<%= pkg.name %>/build'
			},
			server_extract_dist: {
				command: 'tar xvzf /opt/applications/<%= pkg.name %>/dist/<%= pkg.name %>-<%= pkg.version %>-dist.tar.gz -C /opt/applications/<%= pkg.name %>'
			},
			server_npm_install: {
				command: "cd '/opt/applications/<%= pkg.name %>/build' && npm install"
			}
		},
		sftp: {
			upload_app: {
				files: {
					"./": "dist/<%= pkg.name %>-<%= pkg.version %>-dist.tar.gz"
				},
				options: {
					path: "/opt/applications/<%= pkg.name %>",
					createDirectories: true
				}
			}
		},
		sass: {
			dev: {
				files: [{
					expand: true,
					cwd: 'src/sass',
					src: ['*.scss'],
					dest: 'build/public/styles',
					ext: '.css'
				}]
			}
		},
		livereload: {
			files: [
				"Gruntfile.coffee",
				"public/scripts/*.js",
				"public/styles/*.css",
				"public/errors/*.html",
				"public/partials/**/*.html",
				"public/images/**/*.{png,jpg,jpeg,gif,webp,svg}"],
			options:{
				livereload: true
			}
		},
		coffeelint: {
			dev: {
				files: {
					src: ['src/**/*.coffee']
				},
				options: {
					'no_trailing_whitespace': {
						'level': 'error'
					}
				}
			},
			test: {
				files: {
					src: ['test/**/*.coffee']
				},
				options: {
					'no_trailing_whitespace': {
						'level': 'error'
					}
				}
			}
		},
		simplemocha: {
			dev: {
				src:"build/test/*.js",
				options: {
					reporter: 'spec',
					slow: 200,
					timeout: 1000
				}
			}
		},
		watch: {
			coffee_dev: {
				files: ['src/coffee/**/*.coffee'],
				tasks: ['coffee:dev'],
				options: {
					spawn: false //important so that the task runs in the same context
				}
			},
			coffee_test: {
				files: ['test/coffee/**/*.coffee'],
				tasks: ['coffee:test'],
				options: {
					spawn: false //important so that the task runs in the same context
				}
			},
			copy_dev: {
				files: ['src/javascript/**/*.js', 'data/**/*.*'],
				tasks: ['copy:dev']
			},
			copy_test: {
				files:['test/data/**/*.*'],
				tasks: ['copy:test']
			},
			public_dev: {
				files:[
					'public/errors/**/*.*',
					'public/images/**/*.*',
					'public/partials/**/*.*',
					'public/scripts/libs/**/*.*',
					'public/scripts/*.*',
					'public/*.*'
				],
				options: {
					spawn: false
				},
				tasks: ['copy:public']
			},
			views: {
				files:[
					'views/**/*.*'
				],
				options: {
					spawn: false
				},
				tasks: ['copy:views']
			},
			sass_dev: {
				files:['src/sass/**/*.*'],
				tasks: ['sass:dev']
			}
		},
		shell: {                                // Task
			cover: {                            // Target
				options: {                      // Options
					stdout: true
				},
				command: [
					'mkdir coverage',
					'istanbul instrument -x "public/**" -x "test/**" --output build-cov build -v',
					'cp -r build/test build-cov/test',
					'ISTANBUL_REPORTERS=text-summary,cobertura,lcov ./node_modules/.bin/mocha --reporter mocha-istanbul --timeout 20s --debug build-cov/test',
					'mv lcov.info coverage',
					'mv lcov-report coverage',
					'mv cobertura-coverage.xml coverage',
					'rm -rf build-cov'
				].join('&&')
			},
			coveralls: {
				options: {
					stdout: true
				},
				command: 'cat coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js'
			}
		},
		notify_hooks: {
			options: {
				enabled: false
			}
		}

	});

	var notify = require('./node_modules/grunt-notify/lib/notify-lib');

	grunt.event.on('coffee', function(status, message, arg1, arg2, arg3, arg4) {
		grunt.log.error("Status: " + status + ", message: " + "status: " + status + ", " + arg1 + ", " + arg2 + ", " + arg3  + ", " + arg4);
		notify({
			title: "Coffee compilation: " + status + ", " + arg1 + ", " + arg2 + ", " + arg3  + ", " + arg4,
			message: message + ": " + status + ", " + arg1 + ", " + arg2 + ", " + arg3  + ", " + arg4
		});
	});

	grunt.event.on('watch', function(action, filepath, target) {

		console.log("\n");
		console.log("---------------------------------");
		console.log("--- Watch Event");
		console.log("---------------------------------");
		console.log(" action: " + action);
		console.log(" filepath: " + filepath);
		console.log(" target: " + target);

		var config;
		if (target === 'coffee_dev') {
			config = grunt.config( "coffee" );
			if(config.dev.lastUpdate === undefined || moment().isAfter(moment(config.dev.lastUpdate).add('s', 10))) {
				console.log("[coffee_dev] File list to old - freeing files to process list for");
				config.dev.src = [];
			}
			config.dev.lastUpdate = moment();

			var relativeFilePath = path.relative(config.dev.cwd, filepath);
			if (!_(config.dev.src).contains(relativeFilePath)) {
				console.log("[coffee_dev] Adding file: '" + relativeFilePath + "' for processing");
				config.dev.src.push(relativeFilePath);
			}

			grunt.config("coffee", config);
		}
		else if (target === 'coffee_test') {
			config = grunt.config( "coffee" );
			if(config.test.lastUpdate === undefined || moment().isAfter(moment(config.test.lastUpdate).add('s', 10))) {
				console.log("[coffee_test] File list to old - freeing files to process list for");
				config.test.src = [];
			}
			config.test.lastUpdate = moment();

			var relativeFilePath = path.relative(config.test.cwd, filepath);
			if (!_(config.test.src).contains(relativeFilePath)) {
				console.log("[coffee_test] Adding file: '" + relativeFilePath + "' for processing");
				config.test.src.push(relativeFilePath);
			}

			grunt.config("coffee", config);
		}
		else if (target === 'public_dev') {
			config = grunt.config( "copy" );
			if(config.dev.lastUpdate === undefined || moment().isAfter(moment(config.dev.lastUpdate).add('s', 10))) {
				console.log("[public_dev] File list to old - freeing files to process list for");
				config.dev.src = [];
			}
			config.dev.lastUpdate = moment();

			var relativeFilePath = path.relative(config['public'].files[0].cwd, filepath);
			if (!_(config['public'].files[0].src).contains(relativeFilePath)) {
				console.log("[public_dev] Adding file: '" + relativeFilePath + "' for processing");
				config['public'].files[0].src.push(relativeFilePath);
			}

			grunt.config("copy", config);
		}
	} );

	grunt.loadNpmTasks('grunt-ssh');
	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-simple-mocha');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-coffeelint');
	grunt.loadNpmTasks('grunt-shell');
	grunt.loadNpmTasks('grunt-contrib-sass');
	grunt.loadNpmTasks('grunt-contrib-compress');
//	grunt.loadNpmTasks('grunt-notify');

	grunt.registerTask('cover', ['shell:cover']);
	grunt.registerTask('coveralls', ['cover', 'shell:coveralls']);
	grunt.registerTask('test', 'simplemocha:dev');
	grunt.registerTask('buildDev', ['copy:dev', 'copy:public', 'copy:views', 'copy:package', 'copy:certs', 'copy:data', 'coffee:dev'/*, 'coffeelint:dev'*/, 'sass:dev']);
	grunt.registerTask('buildTest', ['copy:test', 'coffee:test'/*, 'coffeelint:test'*/]);
	grunt.registerTask('build', ['buildDev', 'buildTest']);
	grunt.registerTask('default', ['build', 'watch']);
	grunt.registerTask('default', ['clean', 'build', 'watch']);

	grunt.registerTask('buildAndWatch', ['clean', 'build', 'watch']);

	grunt.registerTask('release', ['clean', 'build', 'compress:dist']);
	grunt.registerTask('compress_release', ['compress:dist']);
	grunt.registerTask('deploy', ['release', 'sshexec:server_stop', 'sshexec:server_cleanup', 'sftp:upload_app', 'sshexec:server_extract_dist', 'sshexec:server_npm_install', 'sshexec:server_start']);
	grunt.registerTask('deploy_only', ['sshexec:server_stop', 'sshexec:server_cleanup', 'sftp:upload_app', 'sshexec:server_extract_dist', 'sshexec:server_start']);

//	grunt.task.run('notify_hooks');
};