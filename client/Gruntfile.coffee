module.exports = (grunt) ->

  ###
  A utility function to get all app JavaScript sources.
  ###
  filterForJS = (files) ->
    files.filter (file) ->
      file.match /\.js$/

  
  ###
  A utility function to get all app CSS sources.
  ###
  filterForCSS = (files) ->
    files.filter (file) ->
      file.match /\.css$/

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-jshint"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-conventional-changelog"
  grunt.loadNpmTasks "grunt-bump"
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-karma"
  grunt.loadNpmTasks "grunt-ngmin"
  grunt.loadNpmTasks "grunt-html2js"
  grunt.loadNpmTasks "grunt-contrib-jade"


  userConfig = require("./build.config.js")
  path = require("path")


  taskConfig =
    pkg: grunt.file.readJSON("package.json")
    meta:
      banner: "/**\n" + " * <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today(\"yyyy-mm-dd\") %>\n" + " * <%= pkg.homepage %>\n" + " *\n" + " * Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= pkg.author %>\n" + " * Licensed <%= pkg.licenses.type %> <<%= pkg.licenses.url %>>\n" + " */\n"

    changelog:
      options:
        dest: "CHANGELOG.md"
        template: "changelog.tpl"

    bump:
      options:
        files: ["package.json", "bower.json"]
        commit: false
        commitMessage: "chore(release): v%VERSION%"
        commitFiles: ["package.json", "client/bower.json"]
        createTag: false
        tagName: "v%VERSION%"
        tagMessage: "Version %VERSION%"
        push: false
        pushTo: "origin"

    clean: ["<%= build_dir %>", "<%= compile_dir %>"]
    copy:
      build_assets:
        files: [
          src: ["**"]
          dest: "<%= build_dir %>/assets/"
          cwd: "src/assets"
          expand: true
        ]

      build_appjs:
        files: [
          src: ["<%= app_files.js %>"]
          dest: "<%= build_dir %>/"
          cwd: "."
          expand: true
        ]

      build_vendorjs:
        files: [
          src: ["<%= vendor_files.js %>"]
          dest: "<%= build_dir %>/"
          cwd: "."
          expand: true
        ]

      compile_assets:
        files: [
          src: ["**"]
          dest: "<%= compile_dir %>/assets"
          cwd: "<%= build_dir %>/assets"
          expand: true
        ]

    concat:
      compile_js:
        options:
          banner: "<%= meta.banner %>"

        src: ["module.prefix", "<%= build_dir %>/src/**/*.js", "<%= html2js.app.dest %>", "<%= html2js.common.dest %>", "<%= html2js.jade_app.dest %>", "<%= html2js.jade_common.dest %>", "<%= vendor_files.js_compile %>", "module.suffix"]
        dest: "<%= compile_dir %>/assets/<%= pkg.name %>.js"

    jade:
      compile:
        options:
          data: (dest, src) ->
            base = path.basename(src, ".jade")
            if base isnt "index"
              template_id: base
            else
              template_id: path.basename(path.dirname(src))

        files: [
          src: ["<%= app_files.jade %>"]
          cwd: "."
          dest: "<%= build_dir %>"
          expand: true
          ext: ".html"
        ]

    coffee:
      source:
        options:
          bare: false

        expand: true
        cwd: "."
        src: ["<%= app_files.coffee %>"]
        dest: "<%= build_dir %>"
        ext: ".js"

    ngmin:
      compile:
        files: [
          src: ["<%= app_files.js %>"]
          cwd: "<%= build_dir %>"
          dest: "<%= build_dir %>"
          expand: true
        ]

    uglify:
      compile:
        options:
          banner: "<%= meta.banner %>"
          mangle: false

        files:
          "<%= concat.compile_js.dest %>": "<%= concat.compile_js.dest %>"

    less:
      build:
        files:
          "<%= build_dir %>/assets/<%= pkg.name %>.css": "<%= app_files.less %>"

        _dest: "<%= build_dir %>/assets/<%= pkg.name %>.css"

      compile:
        options:
          compress: true

        files:
          "<%= build_dir %>/assets/<%= pkg.name %>.css": "<%= app_files.less %>"

        _dest: "<%= less.build._dest %>"

    jshint:
      src: ["<%= app_files.js %>", "!src/assets/js/*.js"]
      test: ["<%= app_files.jsunit %>"]
      gruntfile: ["Gruntfile.js"]
      options:
        curly: true
        immed: true
        newcap: true
        noarg: true
        sub: true
        boss: true
        eqnull: true

      globals: {}

    coffeelint:
      src:
        files:
          src: ["<%= app_files.coffee %>"]

      test:
        files:
          src: ["<%= app_files.coffeeunit %>"]

    html2js:
      app:
        options:
          base: "src/app"

        src: ["<%= app_files.atpl %>"]
        dest: "<%= build_dir %>/templates-app.js"

      common:
        options:
          base: "src/common"

        src: ["<%= app_files.ctpl %>"]
        dest: "<%= build_dir %>/templates-common.js"

      jade_app:
        options:
          base: "build/src/app"

        src: ["build/src/app/**/*.html"]
        dest: "<%= build_dir %>/templates-jade-app.js"

      jade_common:
        options:
          base: "build/src/common"

        src: ["build/src/common/**/*.html"]
        dest: "<%= build_dir %>/templates-jade-common.js"

    karma:
      options:
        configFile: "<%= build_dir %>/karma-unit.js"

      unit:
        runnerPort: 9101
        background: true
        port: 9877

      continuous:
        singleRun: true


    index:
      build:
        dir: "<%= build_dir %>"
        src: ["<%= vendor_files.js %>", "<%= build_dir %>/src/**/*.js", "<%= html2js.common.dest %>", "<%= html2js.app.dest %>", "<%= html2js.jade_app.dest %>", "<%= html2js.jade_common.dest %>", "<%= vendor_files.css %>", "<%= less.build._dest %>"]

      compile:
        dir: "<%= compile_dir %>"
        src: ["<%= concat.compile_js.dest %>", "<%= vendor_files.css %>", "<%= less.compile._dest %>"]
        cdn: "<%= vendor_files.cdn %>"

    karmaconfig:
      unit:
        dir: "<%= build_dir %>"
        src: ["<%= vendor_files.js %>", "<%= html2js.app.dest %>", "<%= html2js.common.dest %>", "<%= html2js.jade_app.dest %>", "<%= html2js.jade_common.dest %>", "vendor/chai/chai.js", "vendor/angular-mocks/angular-mocks.js", "vendor/sinon/index.js", "vendor/sinon-chai/lib/sinon-chai.js", "karma/init.js"]

    delta:
      options:
        livereload: true

      gruntfile:
        files: "Gruntfile.coffee"
        tasks: ["jshint:gruntfile"]
        options:
          livereload: false

      jssrc:
        files: ["<%= app_files.js %>"]
        tasks: ["jshint:src", "karma:unit:run", "copy:build_appjs"]

      coffeesrc:
        files: ["<%= app_files.coffee %>"]
        tasks: ["coffeelint:src", "coffee:source", "karma:unit:run", "copy:build_appjs"]

      assets:
        files: ["src/assets/**/*", "!src/assets/blog/**/*"]
        tasks: ["copy:build_assets"]

      html:
        files: ["<%= app_files.html %>"]
        tasks: ["index:build"]

      tpls:
        files: ["<%= app_files.atpl %>", "<%= app_files.ctpl %>"]
        tasks: ["html2js"]

      jadesrc:
        files: ["<%= app_files.jade %>"]
        tasks: ["jade", "html2js"]

      less:
        files: ["src/**/*.less"]
        tasks: ["less:build"]

      jsunit:
        files: ["<%= app_files.jsunit %>"]
        tasks: ["jshint:test", "karma:unit:run"]
        options:
          livereload: false

      coffeeunit:
        files: ["<%= app_files.coffeeunit %>"]
        tasks: ["coffeelint:test", "karma:unit:run"]
        options:
          livereload: false

  grunt.initConfig grunt.util._.extend(taskConfig, userConfig)
  grunt.renameTask "watch", "delta"
  grunt.registerTask "watch", ["build", "test", "karma:unit", "delta"]
  grunt.registerTask "default", ["build", "compile"]
  grunt.registerTask "test", ["build", "karmaconfig", "karma:continuous"]
  grunt.registerTask "build", ["clean", "jade", "html2js", "jshint", "coffeelint", "coffee", "less:build", "copy:build_assets", "copy:build_appjs", "copy:build_vendorjs", "index:build"]
  grunt.registerTask "compile", ["less:compile", "copy:compile_assets", "ngmin", "concat", "uglify", "index:compile"]
  
  ###
  The index.html template includes the stylesheet and javascript sources
  based on dynamic names calculated in this Gruntfile. This task assembles
  the list into variables for the template to use and then runs the
  compilation.
  ###
  grunt.registerMultiTask "index", "Process index.html template", ->
    dirRE = new RegExp("^(" + grunt.config("build_dir") + "|" + grunt.config("compile_dir") + ")/", "g")
    jsFiles = filterForJS(@filesSrc).map((file) ->
      file.replace dirRE, ""
    )
    cssFiles = filterForCSS(@filesSrc).map((file) ->
      file.replace dirRE, ""
    )
    scriptsCDN = @data.cdn or []
    grunt.file.copy "src/index.html", @data.dir + "/index.html",
      process: (contents, path) ->
        grunt.template.process contents,
          data: grunt.util._.extend(
            scripts: jsFiles
            scriptsCDN: scriptsCDN
            styles: cssFiles
            version: grunt.config("pkg.version")
          , {})



  
  ###
  In order to avoid having to specify manually the files needed for karma to
  run, we use grunt to manage the list for us. The `karma/*` files are
  compiled as grunt templates for use by Karma. Yay!
  ###
  grunt.registerMultiTask "karmaconfig", "Process karma config templates", ->
    jsFiles = filterForJS(@filesSrc)
    grunt.file.copy "karma/karma-unit.tpl.js", grunt.config("build_dir") + "/karma-unit.js",
      process: (contents, path) ->
        grunt.template.process contents,
          data:
            scripts: jsFiles



