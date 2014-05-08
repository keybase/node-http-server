
mm = require('./mod').mgr
env = require './env'

##-----------------------------------------------------------------------

env.make (m) -> m.usage "Usage: $0 [-m <runmode>]"

##-----------------------------------------------------------------------

exports.main = () ->

  await mm.start [ 'config' ], defer ok

  if not ok
    console.log "Failed to initialize modules"
    rc = -1
  else
    obj = mm.config
    for i in process.argv[2..] when obj?
      obj = obj[i]
    console.log obj if obj?
    rc = 0

  process.exit rc

##-----------------------------------------------------------------------
