'use babel'

import { get as weaveGet,
         moveNext as weaveMoveNext,
         movePrev as weaveMovePrev } from './weave.js'

function getRange (ed) {
  // Cell range is:
  //  Start of line below top delimiter (and/or start of top row of file) to
  //  End of line before end delimiter
  var buffer = ed.getBuffer()
  var start = buffer.getFirstPosition()
  var end = buffer.getEndPosition()
  var regexString = '^(' + atom.config.get('julia-client.uiOptions.cellDelimiter').join('|') + ')'
  var regex = new RegExp(regexString)
  var cursor = ed.getCursorBufferPosition()
  cursor.column = 0 // cursor on delimiter line means eval cell above
  var foundStartDelim = false
  if (cursor.row > 0) {
    buffer.backwardsScanInRange(regex, [start, cursor], arg => {
      start = arg.range.start
      foundStartDelim = true
    })
  }
  if (foundStartDelim) {
    // cell range starts at the beginning of the row after the top delimiter
    start.row += 1
  }
  var foundEndDelim = false
  buffer.scanInRange(regex, [cursor, end], arg => {
    end = arg.range.start
    foundEndDelim = true
  })
  if (foundEndDelim) {
    // cell range ends at the end of the row before the end delimiter
    end.row -= 1
    if (end.row < 0) end.row = 0
    end.column = Infinity
  }

  return [start, end]
}

export function get (ed) {
  if (ed.getGrammar().scopeName.indexOf('source.weave') > -1) {
    return weaveGet(ed)
  } else {
    return jlGet(ed)
  }
}

function jlGet (ed) {
  var range = getRange(ed)
  var text = ed.getTextInBufferRange(range)
  if (text.trim() === '') text = ' '
  var res = {
    range: [[range[0].row, range[0].column], [range[1].row, range[1].column]],
    selection: ed.getSelections()[0],
    line: range[0].row,
    text: text
  }
  return [res]
}

export function moveNext (ed) {
  if (ed == null) {
    ed = atom.workspace.getActiveTextEditor()
  }
  if (ed.getGrammar().scopeName.indexOf('source.weave') > -1) {
    return weaveMoveNext(ed)
  } else {
    return jlMoveNext(ed)
  }
}

function jlMoveNext (ed) {
  var range = getRange(ed)
  var sel = ed.getSelections()[0]
  var nextRow = range[1].row + 2 // 2 = 1 to get to delimiter line + 1 more to go past it
  return sel.setBufferRange([[nextRow, 0], [nextRow, 0]])
}

export function movePrev (ed) {
  if (ed == null) {
    ed = atom.workspace.getActiveTextEditor()
  }
  if (ed.getGrammar().scopeName.indexOf('source.weave') > -1) {
    return weaveMovePrev(ed)
  } else {
    return jlMovePrev(ed)
  }
}

function jlMovePrev (ed) {
  var range = getRange(ed)
  var prevRow = range[0].row - 2 // 2 = 1 to get to delimiter line + 1 more to go past it
  var sel = ed.getSelections()[0]
  return sel.setBufferRange([[prevRow, 0], [prevRow, 0]])
}
