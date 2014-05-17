http     = require 'http'
path     = require 'path'
env      = require './env'
mm       = require('./mod').mgr
log      = require './log'

# Express middleware
express        = require 'express'
methodOverride = require 'method-override'
morgan         = require 'morgan'
errorHandler   = require 'errorhandler'

{bjson_parser} = require 'keybase-bjson-express'


##-----------------------------------------------------------------------

exports.App = class App

  #-----------------------------------------

  set_port : () ->
    @port = env.get().get_port { dflt : 3000, config : mm.config.host.internal } 
    @bind_addr = env.get().get_bind_addr { dflt : null, config : mm.config.host.internal }

  #-----------------------------------------
  
  constructor : () ->

  #-----------------------------------------
  
  configure_express : () ->
    @app = app = express()
    port = @port

    log.info "In app.configure: set port to #{port}"
    app.set 'port', port
    app.enable 'trust proxy'
    app.use methodOverride()

    # These are middlewares specific to our JSON/Msgpack systems.
    #  1. JSON decode as normal.
    #  2. Turn {__b : "aEbe4==" } into the appropriate buffer object
    #  3. Decode msgpack if necessary
    app.use bjson_parser()

    # For devel
    app.use morgan 'dev'
    app.use errorHandler()

  #-----------------------------------------
  
  make_routes : () ->
    top = env.get().get_top_dir()
    cfg = mm.config.handlers
    dir = cfg.dir
    for f in cfg.files
      require(path.join(top,dir,f)).bind_to_app @app

  #-----------------------------------------

  run : () ->
    modules = [ 'config', 'db' ]

    mm.create modules
    @set_port()
    @configure_express()
    @make_routes()

    # Now we're safe to set up connections, etc...
    await mm.init defer ok
    log.error "Module initialization failure" unless ok

    if ok
      await http.createServer(@app).listen @port, @bind_addr, defer()
      log.info "Express server listening on #{@bind_addr}:#{@port}"
    if not ok
      process.exit -1

##-----------------------------------------------------------------------

exports.main = () ->
  iced.catchExceptions()
  env.make (m) -> m.usage 'Usage: $0 [-ld] [-m <devel|prod>] [-p <port>]'
  (new App).run()

##-----------------------------------------------------------------------

