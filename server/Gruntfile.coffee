path = require 'path'

module.exports = (grunt) ->

  grunt.initConfig
    express:
      options:
        cmd: 'coffee'
        delay: 50
      dev:
        options:
          script: path.join(__dirname, 'server.coffee')

    watch:
      express:
        options:
          nospawn: true
        files: ['**/*.coffee']
        tasks: ['express:dev']
      test:
        options:
          nospawn: false
        files: ['**/*.coffee']
        tasks: ['mochaTest:test']

    mochaTest:
      options:
        compilers: 'coffee-script'

      test:
        options:
          reporter: 'dot'
        src: ['!node_modules/**', '**/*.spec.coffee']

      jenkins:
        options:
          reporter: 'xunit-file'
        src: ['!node_modules/**', '**/*.spec.coffee']

    env:
      jenkins:
        XUNIT_FILE: 'test-results-server.xml'

  grunt.loadNpmTasks 'grunt-express-server'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-env'

  grunt.registerTask 'default', ['dev']

  grunt.registerTask 'test', ['mochaTest:test']
  grunt.registerTask 'dev', ['test:test', 'express:dev', 'watch']

  grunt.registerTask 'test:jenkins', ['env:jenkins', 'mochaTest:jenkins']
