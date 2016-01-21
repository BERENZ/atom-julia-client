fs = require 'fs'
readline = require 'readline'

paths = require './paths'

module.exports =
  path: paths.home '.julia_history'

  read: ->
    new Promise (resolve) =>
      lineReader = readline.createInterface
        input: fs.createReadStream @path

      entries = []
      readingMeta = false

      lineReader.on 'line', (line) =>
        if line.startsWith '#'
          if !readingMeta
            entries.push {}
            readingMeta = true
          [_, key, val] = line.match /# (.+?): (.*)/
          entries[entries.length-1][key] = val
        else
          readingMeta = false
          entry = entries[entries.length-1]
          if entry.hasOwnProperty 'code'
            entry.code += '\n' + line.slice(1)
          else
            entry.code = line.slice(1)

      lineReader.on 'close', ->
        resolve entries

  write: (entries) ->
    out = fs.createWriteStream @path, flags: 'w'
    for entry in entries
      for k, v of entry
        if k isnt 'code'
          out.write "# #{k}: #{v}\n"
      for line in entry.code.split '\n'
        out.write "\t#{line}\n"
    return