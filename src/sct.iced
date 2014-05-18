{pack,unpack}  = require 'purepack'
utils          = require('iced-utils').util
crypto         = require 'crypto'
constants      = require './constants'
sc             = require('./status').codes
mm             = require('./mod').mgr

##=======================================================================

exports.SelfCertifiedToken = class SelfCertifiedToken

  @VERSION : 1
  VERSION  : SelfCertifiedToken.VERSION

  #-----------------------------------------

  constructor : ({@version, @id, @generated, @lifetime, @mac, @addr, cfg}) ->
    if cfg?
      @key = new Buffer cfg.key, 'base64' # keep the key b64-encoded in the config file
      @lifetime = cfg.lifetime unless @lifetime
      @id = cfg.id unless @id

  #-----------------------------------------

  @check_from_client : (json, cfg, cb) ->
    [err,obj] = SelfCertifiedToken.from_client json, cfg
    await obj.check defer err unless err?
    cb err, obj
 
  #-----------------------------------------

  @from_client : (x, cfg) ->
    err = null
    ret = null
    klass = cfg.klass or SelfCertifiedToken
    if not Array.isArray x
      err = "Expected array, not something else: #{JSON.stringify x}"
    else if (x.length isnt 5) or (x[0] isnt @VERSION)
      err = "Only understand version #{@VERSION}; got something else: #{JSON.stringify x}"
    else
      ret = new klass
        version : x[0]
        id : x[1]
        generated : x[2]
        lifetime : x[3]
        mac : x[4]
        cfg : cfg 
    err = new Error err if err?
    return [ err, ret ]

  #-----------------------------------------

  check_replay : (cb) ->
    cb null

  #-----------------------------------------

  check : (cb) ->

    now = utils.unix_time()
    expires = @generated + @lifetime

    mkerr = (m,code) ->
      err = new Error m
      err.code = code
      return err

    if not expires?
      err = mkerr "Can't compute expiration time", sc.SCT_CORRUPT
    else if @lifetime < 0
      err = mkerr "Lifetime can't be < 0", sc.SCT_CORRUPT
    else if @generated < 0
      err = mkerr "Generated can't be < 0", sc.SCT_CORRUPT
    else if expires < now
      err = mkerr "Expired #{now - expires}s ago", sc.SCT_EXPIRED
    else if not (m = @_make_mac @ENCODING)
      err = mkerr "Failed to generate mac", sc.SCT_CORRUPT
    else if not @mac?
      err = mkerr "No MAC given", sc.SCT_CORRUPT
    else if not utils.bufeq_secure m, @mac
      err = mkerr "MAC mismatch", sc.SCT_BAD_MAC
    else if @sid?
      await @check_replay defer err

    cb err

  #-----------------------------------------

  _make_mac : (enc = null) ->
    msg = pack @_to_array true
    if not @key or @key.length is 0
      throw new Error "Failing to make, since @key is empty"
    hm = crypto.createHmac 'sha512', @key
    hm.update msg
    hm.digest()

  #-----------------------------------------

  _to_array : (null_mac) ->
    mac = if null_mac then null else @mac
    return [ @version, @id, @generated, @lifetime, mac ]
    
  #-----------------------------------------

  generate : (cb) ->
    @version = @VERSION
    @generated = utils.unix_time()
    @lifetime = mm.config.security.sct.lifetime unless @lifetime?
    @mac = @_make_mac()
    ret = @_to_array false
    err = null
    cb err, ret

  #-----------------------------------------

  pack_to_client : () -> @_pack false
    
##=======================================================================

