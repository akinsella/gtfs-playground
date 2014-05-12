var path = require("path");

module.exports = function(grunt) {

	grunt.initConfig({
		clean:{
			dev: {
				src: ["build", "coverage"]
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
			'certs':{
				files: [
					{
						expand: true,
						flatten: false,
						cwd: 'certs/',
						src: ['**/*.*'],
						dest: 'build/certs/'
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
					sourceMap: true
				},
				expand: true,
				cwd: 'src/coffee/',
				src: ['**/*.coffee'],
				dest: 'build/',
				ext: '.js'
			},
			test:{
				options: {
					sourceMap: true
				},
				expand: true,
				cwd: 'test/coffee/',
				src: ['**/*.coffee'],
				dest: 'build/test/',
				ext: '.js'
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

			// Update the files.src to be the path to the modified file (relative to srcDir).
			config.dev.src = path.relative(config.dev.cwd, filepath);
			grunt.config("coffee", config);
		}
		else if (target === 'coffee_test') {
			config = grunt.config( "coffee" );

			// Update the files.src to be the path to the modified file (relative to srcDir).
			config.test.src = path.relative(config.test.cwd, filepath);
			grunt.config("coffee", config);
		}
		else if (target === 'public_dev') {
			config = grunt.config( "copy" );

			// Update the files.src to be the path to the modified file (relative to srcDir).
			config['public'].files[0].src = [path.relative(config['public'].files[0].cwd, filepath)];
			grunt.log.writeln("Config copy: " + JSON.stringify(config['public']));
			grunt.config("copy", config);
		}
	} );

	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-simple-mocha');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-coffeelint');
	grunt.loadNpmTasks('grunt-shell');
	grunt.loadNpmTasks('grunt-contrib-sass');
//	grunt.loadNpmTasks('grunt-notify');

	grunt.registerTask('cover', ['shell:cover']);
	grunt.registerTask('coveralls', ['cover', 'shell:coveralls']);
	grunt.registerTask('test', 'simplemocha:dev');
	grunt.registerTask('buildDev', ['copy:dev', 'copy:public', 'copy:certs', 'coffee:dev'/*, 'coffeelint:dev'*/, 'sass:dev']);
	grunt.registerTask('buildTest', ['copy:test', 'coffee:test'/*, 'coffeelint:test'*/]);
	grunt.registerTask('build', ['buildDev', 'buildTest']);
	grunt.registerTask('default', ['build', 'watch']);
	grunt.registerTask('default', ['clean', 'build', 'watch']);

//	grunt.task.run('notify_hooks');
};