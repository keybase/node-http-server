
{hasBody} = require 'type-is'
getBody = require 'raw-body'
{decode,decode_json_obj} = require 'kbjo'

#===============================================================

parse_msgpack_body = ({req, res, opts }, cb) ->
  params = 
    limit    : opts.limit || '1000kb'
    length   : req.headers['content-length']
    encoding : if opts.base64 then 'base64' else 'binary'
  await getBody req, params, defer err, buf
  unless err?
    try
      req.body = decode { buf, mpack : true } 
    catch e
      err = e
  cb err

#===============================================================

exports.msgpack_parser = (opts = {}) -> (req, res, next) ->
  err = null

  stem = "application/x-msgpack"
  ct = req.headers['content-type']

  if not hasBody(req) then # noop
  else if ct is stem then go = true
  else if ct is "#{stem}-64" then opts.base64 = go = true
  
  if go
    await parse_msgpack_body {req, res, opts}, defer err

  next err

#===============================================================

exports.json_bufferizer = json_bufferizer = (opts = {}) -> (req, res, next) ->

  # These are the conditions that the json() parse of 
  # body-parser middleware sets
  if req._body and req.body and typeof(req.body) is 'object'
    req.body = decode_json_obj req.body 
  next()

#===============================================================
