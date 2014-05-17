
{lookup} = require 'keybase-bjson-core'

#--------------------------------------------------

exports.json_checker = json_checker = ({key, checker, json}) -> 
  val = lookup { key, obj : json }
  [err, res] = checker val
  return [err, res]

#--------------------------------------------------


