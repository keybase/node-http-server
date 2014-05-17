
{Handler,BOTH}    = require '../src/base'
{prng} = require 'crypto'

#=============================================================================

exports.TestHandler = class TestHandler extends Handler

  needed_inputs : () -> []

  _handle : (cb) ->
    @pub { 
      hello : "world"
      data : {
        i     : prng(4).readUInt32LE(0)
        id    : prng(12)
        bytes : prng(32)
        chars : prng(40).toString('base64')
      }
    }
    cb()

#=============================================================================

exports.bind_to_app = (app) ->
  TestHandler.bind app, /\/test\.(json|msgpack|msgpack64)/, BOTH
