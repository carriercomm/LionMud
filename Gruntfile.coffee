#jshint camelcase: false
module.exports = (grunt) ->
  "use strict"
  
  # load all grunt tasks
  require("matchdep").filterDev("grunt-*").forEach grunt.loadNpmTasks
  
  # configurable paths
  config =
    app: "app"
    dist: "dist"
    tmp: "tmp"
    resources: "resources"

  grunt.initConfig
    config: config

    shell:
      runnw:
        options:
          stdout: true
        command: [
          '<%= config.dist %>/nwtest.app/Contents/MacOS/node-webkit . --debug'
        ,
          '.\\build\\cache\\win\\0.9.2\\nw.exe . --debug'
        ].join('&')
      lol:
        options:
          stdout: true
        command : 'echo lol'
    
    # Clean dist & temp directories
    clean:
      dist:
        files: [
          dot: true
          src: [
            "<%= config.dist %>/*"
            "<%= config.tmp %>/*"
          ]
        ]

    # Lint JavaScript
    jshint:
      options:
        jshintrc: ".jshintrc"

      files: "<%= config.app %>/js/*.js"

    copy:
      appLinux:
        files: [
          expand: true
          cwd: "<%= config.app %>"
          dest: "<%= config.dist %>/app.nw"
          src: "**"
        ]

      appMacos:
        files: [
          {
            expand: true
            cwd: "<%= config.app %>"
            dest: "<%= config.dist %>/node-webkit.app/Contents/Resources/app.nw"
            src: "**"
          }
          {
            expand: true
            cwd: "<%= config.resources %>/mac/"
            dest: "<%= config.dist %>/node-webkit.app/Contents/"
            filter: "isFile"
            src: "*.plist"
          }
          {
            expand: true
            cwd: "<%= config.resources %>/mac/"
            dest: "<%= config.dist %>/node-webkit.app/Contents/Resources/"
            filter: "isFile"
            src: "*.icns"
          }
          {
            expand: true
            cwd: "/../node_modules/"
            dest: "/node-webkit.app/Contents/Resources/app.nw/node_modules/"
            src: "**"
          }
        ]

      webkit:
        files: [
          expand: true
          cwd: "<%=config.resources %>/node-webkit/MacOS"
          dest: "<%= config.dist %>/"
          src: "**"
        ]

      copyWinToTmp:
        files: [
          expand: true
          cwd: "<%= config.resources %>/node-webkit/Windows/"
          dest: "<%= config.tmp %>/"
          src: "**"
        ]

    compress:
      appToTmp:
        options:
          archive: "<%= config.tmp %>/app.zip"

        files: [
          expand: true
          cwd: "<%= config.app %>"
          src: ["**"]
        ]

      finalWindowsApp:
        options:
          archive: "<%= config.dist %>/nwtest.zip"

        files: [
          expand: true
          cwd: "<%= config.tmp %>"
          src: ["**"]
        ]

    rename:
      app:
        files: [
          src: "<%= config.dist %>/node-webkit.app"
          dest: "<%= config.dist %>/nwtest.app"
        ]

      zipToApp:
        files: [
          src: "<%= config.tmp %>/app.zip"
          dest: "<%= config.tmp %>/app.nw"
        ]

    

  grunt.registerTask "chmod", "Add lost Permissions.", ->
    fs = require("fs")
    fs.chmodSync "dist/nwtest.app/Contents/Frameworks/node-webkit Helper EH.app/Contents/MacOS/node-webkit Helper EH", "555"
    fs.chmodSync "dist/nwtest.app/Contents/Frameworks/node-webkit Helper NP.app/Contents/MacOS/node-webkit Helper NP", "555"
    fs.chmodSync "dist/nwtest.app/Contents/Frameworks/node-webkit Helper.app/Contents/MacOS/node-webkit Helper", "555"
    fs.chmodSync "dist/nwtest.app/Contents/MacOS/node-webkit", "555"
    return

  grunt.registerTask "createLinuxApp", "Create linux distribution.", ->
    done = @async()
    childProcess = require("child_process")
    exec = childProcess.exec
    exec "mkdir -p ./dist; cp resources/node-webkit/Linux64/nw.pak dist/ && cp resources/node-webkit/Linux64/nw dist/node-webkit", (error, stdout, stderr) ->
      result = true
      grunt.log.write stdout  if stdout
      grunt.log.write stderr  if stderr
      if error isnt null
        grunt.log.error error
        result = false
      done result
      return

    return

  grunt.registerTask "createWindowsApp", "Create windows distribution.", ->
    done = @async()
    concat = require("concat-files")
    concat [
      "tmp/nw.exe"
      "tmp/app.nw"
    ], "tmp/nwtest.exe", ->
      fs = require("fs")
      fs.unlink "tmp/app.nw", (error, stdout, stderr) ->
        grunt.log.write stdout  if stdout
        grunt.log.write stderr  if stderr
        if error isnt null
          grunt.log.error error
          done false
        else
          fs.unlink "tmp/nw.exe", (error, stdout, stderr) ->
            result = true
            grunt.log.write stdout  if stdout
            grunt.log.write stderr  if stderr
            if error isnt null
              grunt.log.error error
              result = false
            done result
            return

        return

      return

    return

  grunt.registerTask "setVersion", "Set version to all needed files", (version) ->
    config = grunt.config.get(["config"])
    appPath = config.app
    resourcesPath = config.resources
    mainPackageJSON = grunt.file.readJSON("package.json")
    appPackageJSON = grunt.file.readJSON(appPath + "/package.json")
    infoPlistTmp = grunt.file.read(resourcesPath + "/mac/Info.plist.tmp",
      encoding: "UTF8"
    )
    infoPlist = grunt.template.process(infoPlistTmp,
      data:
        version: version
    )
    mainPackageJSON.version = version
    appPackageJSON.version = version
    grunt.file.write "package.json", JSON.stringify(mainPackageJSON, null, 2),
      encoding: "UTF8"

    grunt.file.write appPath + "/package.json", JSON.stringify(appPackageJSON, null, 2),
      encoding: "UTF8"

    grunt.file.write resourcesPath + "/mac/Info.plist", infoPlist,
      encoding: "UTF8"

    return

  # Distribution
  grunt.registerTask "dist-linux", [
    "jshint"
    "clean:dist"
    "copy:appLinux"
    "createLinuxApp"
  ]
  grunt.registerTask "dist-win", [
    "jshint"
    "clean:dist"
    "copy:copyWinToTmp"
    "compress:appToTmp"
    "rename:zipToApp"
    "createWindowsApp"
    "compress:finalWindowsApp"
  ]
  grunt.registerTask "dist-mac", [
    "jshint"
    "clean:dist"
    "copy:webkit"
    "copy:appMacos"
    "rename:app"
    "chmod"
  ]

  grunt.registerTask 'default', ['dist-mac', 'run'] #['compass', 'coffee'] # TODO: Change based on platform
  grunt.registerTask 'run',     ['shell:runnw']#['default', 'shell:runnw']

  grunt.registerTask "check",   ["jshint"]


  # Utilities

  grunt.registerTask "dmg", "Create dmg from previously created app folder in dist.", ->
    done = @async()
    createDmgCommand = "resources/mac/package.sh \"nwtest\""
    require("child_process").exec createDmgCommand, (error, stdout, stderr) ->
      result = true
      grunt.log.write stdout  if stdout
      grunt.log.write stderr  if stderr
      if error isnt null
        grunt.log.error error
        result = false
      done result
      return

    return

  return