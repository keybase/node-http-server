
kbjo = require 'kbjo'

#--------------------------------------------------

exports.json_checker = json_checker = ({key, checker, json}) -> 
  val = kbjo.lookup { key, obj : json }
  [err, res] = checker val
  return [err, res]

#--------------------------------------------------


