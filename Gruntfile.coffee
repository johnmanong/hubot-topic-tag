module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    watch:
      scripts:
        files: [ 'scripts/**/*.coffee' ]
        tasks: [ 'coffee', 'execute' ]

    coffee:
      glob_to_multiple:
        expand: true
        flatten: false
        cwd: 'scripts/'
        src: ['**/*.coffee']
        dest: 'scripts/build'
        ext: '.js'
        options:
          sourceMap: true

    execute:
      target:
        src: [ 'scripts/build/index.js' ]

  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-execute')

  grunt.registerTask 'default', [
    'coffee:glob_to_multiple'
    'execute'
    'watch'
  ]
