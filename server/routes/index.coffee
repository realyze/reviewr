path = require 'path'

exports.index = (req, res) ->
  console.log 'index'
  res.sendfile path.join(__dirname, '..', '..', 'client', 'build', 'index.html')
