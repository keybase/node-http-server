
mm = require('./mod').mgr
env = require './env'
fs = require 'fs'
mysql = require 'mysql'
read = require 'read'
{make_esc} = require 'iced-error'

##-----------------------------------------------------------------------

class InitDb

  #---------

  constructor : () ->
    @_mysqls = {}
    @_cmd = null

  #---------

  init : (cb) ->
    await mm.start [ 'config' ], defer ok
    if not ok
      err = new Error 'failed to configure module manager'
    else
      @cfg = mm.config.db
    cb err

  #---------

  get_root_pw : (cb) ->
    err = null
    p = env.get().get_root_db_pw()
    unless p?
      await read { prompt : 'mysql root db pw> ', silent : true }, defer err, p
    cb err, p

  #---------

  get_conn : ({root}, cb) ->
    esc = make_esc cb, "InitDB::get_conn"
    user = if root then "root" else @cfg.user
    unless (conn = @_mysqls[user])?
      params = {host : @cfg.host, user }
      if root?
        await @get_root_pw esc defer pw
      else
        pw = @cfg.password
        params.database = @cfg.database
      params.password = pw
      conn = mysql.createConnection params
      await conn.connect esc defer()
      @_mysqls[user] = conn
    cb null, conn

  #---------

  parse_args : (cb) ->
    err = null
    if not (@_sqlfile = env.get().get_argv().q)?
      err = new Error 'needed a SQL file to run on'
    else 
      if ((v = env.get().get_args().length) is 1) and (cmd = v[0])?
        switch v.toLowerCase()
          when 'init' then @_cmd = @cmd_init.bind(@)
          when 'delete' then @_cmd = @cmd_delete.bind(@)
      if not @_cmd 
        err = new Error 'need a command: either "init" or "delete"'
    cb err

  #---------

  open_file : (cb) ->
    await fs.readFile @_sqlfile, defer err, @_sql
    cb err

  #---------

  test_connect : (cb) ->
    esc = make_esc cb, "test_conenct"
    await @get_conn { root : false } esc defer conn
    await conn.query "SELECT 1", esc defer dummy
    cb null

  #---------

  cmd_init : (cb) ->
    await @test_connect defer err
    if err?
      await @do_create defer err
    cb err

  #---------

  do_create : (cb) ->
    esc = make_esc cb, "do_create"
    await @get_conn { root : true }, esc defer conn
    await conn.query "CREATE DATABASE #{@cfg.database}", esc defer()
    await conn.query "CREATE USE #{@cfg.user}", esc defer()
    await conn.query "SET PASSWORD FOR #@{cfg.user} = PASSWORD('#{@cfg.password}')", esc defer()
    cb null
    
  #---------

  cmd_delete : (cb) ->

  #---------



##-----------------------------------------------------------------------

exports.main = () ->
  env.make (m) -> m.usage "Usage: $0 [-m <runmode>] -q <sql-file> [<init|delete>]"




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
