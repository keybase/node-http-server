status_enum           = require './status'
sc                    = status_enum.codes
sc_lookup             = status_enum.lookup
log                   = require './log'
mm                    = require('./mod').mgr
url                   = require 'url'
env                   = require './env'
{json_checker}        = require './json_checker'
{respond}             = require 'keybase-bjson-express'
core                  = require 'keybase-bjson-core'

util = require 'util'

##-----------------------------------------------------------------------

make_status_obj = (code, desc, fields) ->
  out = { code }
  out.desc = desc if desc?
  out.fields = fields if fields?
  out.name = sc_lookup[code]
  return out
  
##-----------------------------------------------------------------------

exports.Handler = class Handler

  constructor : (@req, @res) ->
    log.make_logs @,  { remote : @req.ip, prefix : @req.protocol }
    @_error_in_field    = {}
    @oo                 = { status : {}, body : {} }
    @user               = null
    @response_sent_yet  = false
    @http_out_code      = 200
    @out_encoding       = 'json'
   
  #-----------------------------------------

  input_template : -> {}

  #-----------------------------------------

  is_input_ok : () -> Object.keys(@_error_in_field).length is 0
   
  #-----------------------------------------

  allow_cross_site_get_requests : () -> false

  #-----------------------------------------

  pub : (dict) -> @oo.body[k] = v for k,v of dict
  clear_pub : () -> @oo = { status : {}, body : {}}

  #-----------------------------------------

  set_error : (code, desc = null, fields = null) ->
    @oo.status = make_status_obj code, desc, fields
    log.warn "set_error #{code} #{desc}" unless code is sc.OK
    new Error code

  #-----------------------------------------

  set_ok : () -> @set_error sc.OK
   
  #-----------------------------------------

  is_ok : () -> 
    (not @oo?.status?.code?) or (@oo.status.code is sc.OK)

  #-----------------------------------------

  status_code : () -> @oo?.status?.code or sc.OK
  status_name : () -> 
    code = @status_code()
    sc_lookup[code] or "code-#{code}"
  handler_name : () -> @constructor.name

  #-----------------------------------------

  get_iparam : (f) -> parseInt(@req.param(f), 10)
  
  #-----------------------------------------
  
  send_res_json : (cb) ->
    @format_res()
    respond { obj : @oo, code : @http_out_code, encoding : @out_encoding, @res }
    @response_sent_yet = true
    cb()

  #-----------------------------------------

  format_res : ->
    if @oo.status?.code
      # noop
    else if not @is_input_ok()
      @set_error sc.INPUT_ERROR, "Error in JSON input", @_error_in_field
    else
      @set_ok()
   
  #==============================================
  
  handle : (cb) ->
    await @__handle_universal_headers defer()
    await @__set_cross_site_get_headers defer()
    await @__handle_input  defer err
    unless err?
      await @__handle_custom defer()
    await @__handle_output defer()
    cb()

  #------

  __set_cross_site_get_headers: (cb) ->
    if @allow_cross_site_get_requests()
      @res.set 'Access-Control-Allow-Origin' :     '*'
      @res.set 'Access-Control-Allow-Methods':     'GET'
      @res.set 'Access-Control-Allow-Headers':     'Content-Type, Authorization, Content-Length, X-Requested-With'
      # I believe this is the default anyway, but let's play it safe
      @res.set 'Access-Control-Allow-Credentials': 'false'
    cb()

  #------

  __handle_universal_headers : (cb) ->
    if env.get().get_run_mode().is_prod()
      @res.set "Strict-Transport-Security", "max-age=31536000"
    cb()

  #------

  __check_inputs : () ->
    err = core.check_template @input_template(), @input, "HTTP"
    return err 

  #------

  __set_out_encoding : () ->
    if (m = @req.path.match /\.(json|msgpack|msgpack64)$/)
      @out_encoding = m[1]

  #------
  
  __handle_input : (cb) ->
    @input = @req.body
    @__set_out_encoding()
    if (err = @__check_inputs())? then @set_error sc.INPUT_ERROR, err.message
    else @set_ok()
    cb err

  #------

  _handle_err : (cb) -> cb()

  #------
  
  __handle_custom : (cb) ->
    if @is_ok()
      await @_handle defer err
      if err?
        code = err.sc or sc.GENERIC_ERROR
        @set_error code, err.message 
        @http_out_code = c if (c = err.http_code)?
    else
      await @_handle_err defer()
    cb()

  #------
  
  __handle_output : (cb) ->
    unless @response_sent_yet
      await @send_res_json defer()
    cb()
   
  #==============================================

  _handle_err : (cb) -> @_handle cb

  #-----------------------------------------
    
  @make_endpoint : (opts) ->
    (req, res) =>
      handler = new @ req, res, opts
      await handler.handle defer()

  #-----------------------------------------
    
  @bind : (app, path, methods, opts = {}) ->
    ep = @make_endpoint opts
    for m in methods
      app[m.toLowerCase()](path, ep)

#==============================================

exports.BOTH = [ "GET" , "POST" ] 
exports.GET = [ "GET" ]
exports.POST = [ "POST" ]
exports.DELETE = [ "DELETE" ]
