
{Handler,BOTH}    = require '../src/base'

#=============================================================================

exports.TestHandler = class TestHandler extends Handler

  needed_inputs : () -> []

  _handle : (cb) ->
    @pub { foo : "hi" }
    cb()

#=============================================================================

exports.bind_to_app = (app) ->
  TestHandler.bind app, /\/test\.(json|mpack)/, BOTH
