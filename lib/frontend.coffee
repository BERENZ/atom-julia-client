client = require './connection/client'
selector = require './ui/selector'

module.exports =
  activate: ->
    client.handle 'select', ({items}, resolve) =>
      selector.show items, (item) =>
        resolve item: item

    client.handle 'atompath', (_, resolve) =>
      resolve result: atom.config.resourcePath
