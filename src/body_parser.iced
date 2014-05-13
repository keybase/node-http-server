
{hasBody} = require 'type-is'
getBody = require 'raw-body'

#===============================================================

msgpack_parser = (req, res, next) ->
  err = null
  if not hasBody(req) then # noop
  else if req.headers['content-type'] is 'application/x-msgpack'
    await parse_msgpack_body { req, res}, defer err
  else if req.headers['content-type'] is 'application/x-msgpack-64'
    await parse_msgpack_body {req, res, base64 : true }, defer err
  next err

#===============================================================

exports.msgpackParser = () -> msgpack