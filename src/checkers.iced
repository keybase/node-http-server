mm                = require('./mod').mgr
kbpgp             = require('kbpgp')
MT                = kbpgp.const.openpgp.message_types

##-----------------------------------------------------------------------

strip = (input) -> 
  if not input? then null
  else if (m = input.match /^\S*(.*?)\S*$/)? then m[1]
  else ''
      
##-----------------------------------------------------------------------

in_range = (x, config) -> (x >= config.min) and (x <= config.max)

E = (s) -> new Error s

##-----------------------------------------------------------------------

checkers = {}

##-----------------------------------------------------------------------

checkers.check_bool = check_bool = (b) ->
  if b      in [0,"0","false",false] then return [null, false]
  else if b in [1,"1","true", true]  then return [null, true ]
  else return [ E('bad boolean value'), null ]

##-----------------------------------------------------------------------

is_empty = (m) -> not(m?) or not(m.length) or m.match(/^\s+$/)

##-----------------------------------------------------------------------

checkers.check_pgp_message = check_pgp_message = (text, type) ->
  [err, msg] = kbpgp.armor.decode text
  if err? then [ new Error("Error parsing PGP data: #{err.message}"), null ]
  else if not is_empty(msg.post) then [ E("found bogus trailing data"), null ]
  else if not is_empty(msg.pre)  then [ E("found bogus prefix data"), null ]
  else if msg.type isnt type then     [ E("wrong PGP message type"), null ]
  else [ null, msg.raw() ]

##-----------------------------------------------------------------------

checkers.check_base64u = check_base64u = (s) ->
  x = /^[0-9a-z-_]+$/i 
  if not s? then [ E("unspecified"), null ]
  else if s.match x then [ null, s ]
  else [ E("not a Base64u encoded string"), null ]

##-----------------------------------------------------------------------

checkers.check_hex = check_hex = (s, len) ->
  x = /^[0-9a-f]+$/i
  if not (s = strip s)? then [ E('unspecified'), null ]
  else if not s.match x then [ E('need an id'), null]
  else if len? and s.length isnt len then [ E("needed a hex string of length #{len}"), null ]
  else [ null, s.toLowerCase() ]

##-----------------------------------------------------------------------

checkers.check_base64 = check_base64 = (s) ->
  if not s?
    return [ E('unspecified'), null ]
  else
    x = /^[0-9a-z\/\+]+[=]{0,2}$/i
    s = s.replace /\s/g, ''
    if not s.match x
      return [ E('not base64'), null ]
    else
      return [ null, s ]

##-----------------------------------------------------------------------

checkers.check_string = check_string = (s, min, max) ->
  if not (s = strip s)? then [ E("unspecified"), null ]
  else if (min? and s.length < min) then [ E("Must be at least #{min} long"), null]
  else if (max? and s.length > max) then [ E("Must be at least #{max} long"), null]
  else [ null, s]

##-----------------------------------------------------------------------

checkers.check_int = check_int = (s, min, max) ->
  x = /^-?[0-9]+$/
  if not (s = strip s)? then [ E("Unspecified"), null ]
  else if not s.match x then [ E("need an integer"), null ]
  else if isNaN(i = parseInt s) then [ E("Could not parse integer #{s}"), null ]
  else if (min? and i < min) or (max? and i > max) then [ E("Must be in range #{min}-#{max}"), null]
  else [ null, i ]

##-----------------------------------------------------------------------

checkers.check_id = check_id = (x, config, required = true) ->
  empty = not x? or x.length is 0
  if empty and required then [ E("no ID specified"), null ]
  else if empty and not required then [ null, null ]
  else if x.length is 2*config.byte_length then [ null, x ]
  else [ E("ID has wrong length"), null]

##-----------------------------------------------------------------------

checkers.check_multi = check_multi = (x,fn) ->
  if not x? or x.length is 0 then [err,out] = [ E("no keys given"), null ]
  else
    v = x.split /,/
    err = null
    out = []
    for e in v when not err?
      [err, val] = fn e
      out.push val
    out = null if err?
  return [ err, out ] 

##-----------------------------------------------------------------------

checkers.check_array = check_array = (x, min = null, max = null) ->
  if typeof(x) isnt 'object' or not Array.isArray(x) then E("expected an array")
  else if min? and x.length < min then E("Array must have > #{min} elements")
  else if max? and x.length > max then E("Array must have < #{max} elements")
  else null

##-----------------------------------------------------------------------

checkers.check_buffer = check_buffer = (x, min = null, max = null) ->
  if typeof(x) isnt 'object' or not Buffer.isBuffer(x) then E("expected a buffer")
  else if min? and x.length < min then E("Buffer must have > #{min} bytes")
  else if max? and x.length > max then E("Buffer must have < #{max} bytes")
  else null

##-----------------------------------------------------------------------

exports.raw = checkers
exports.curried = curried = {}

for k,v in checkers
  ((name, fn) ->
    curried[name] = (args...) -> (s) -> fn s, args...
  )(k,v)

##-----------------------------------------------------------------------

