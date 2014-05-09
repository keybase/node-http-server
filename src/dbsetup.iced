mm = require('./mod').mgr
env = require './env'
fs = require 'fs'
mysql = require 'mysql'
read = require 'read'
{make_esc} = require 'iced-error'
{base64u} = require('pgp-utils').util
{prng} = require 'crypto'
path = require 'path'
log = require 'iced-logger'

##-----------------------------------------------------------------------

prune_sql_comments = (all) ->
  (line.split('--')[0] for line in all.split /\n/).join('\n')

##-----------------------------------------------------------------------

class InitDB

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
      params = {
        host : @cfg.host, 
        user,
        multipleStatements : true
      }
      if root
        await @get_root_pw esc defer pw
      else
        pw = @password or mm.config.secrets?.dbpw
        params.database = @cfg.database
      params.password = pw
      conn = mysql.createConnection params
      await conn.connect esc defer()
      @_mysqls[user] = conn
    cb null, conn

  #---------

  parse_args : (cb) ->
    err = null
    if ((v = env.get().get_args()).length is 1) and (cmd = v[0])?
      switch cmd.toLowerCase()
        when 'init' then @cmd = @cmd_init.bind(@)
        when 'nuke' then @cmd = @cmd_delete.bind(@)
    if not @cmd 
      err = new Error 'need a command: either "init" or "nuke"'
    cb err

  #---------

  open_file : (cb) ->
    fn = path.join(env.get().get_top_dir(), "sql", [@cfg.database, "sql"].join("."))
    await fs.readFile fn, defer err, dat
    unless err?
      @_create_tables = prune_sql_comments dat.toString('utf8')
    cb err

  #---------

  test_connect : (cb) ->
    log.info "+ Testing connection to database #{@cfg.database}"
    esc = make_esc cb, "test_conenct"
    await @get_conn { root : false }, esc defer conn
    await conn.query "SELECT 1", esc defer dummy
    log.info "- DB connection succeeded"
    cb null

  #---------

  cmd_init : (cb) ->
    await @test_connect defer err
    if err?
      log.warn "Failed to connect to DB; will try to create a new one"
      await @do_create defer err
    cb err

  #---------

  write_secrets : (cb) ->
    fn = path.join env.get().get_config_dir(), 'secrets.json'
    log.info "| writing password out to #{fn}"
    obj = mm.config.secrets or {}
    obj.dbpw = @password
    json = JSON.stringify obj, null, "    "
    await fs.writeFile fn, json, {mode : 0o640 }, defer err
    cb err
 
  #---------

  fq_user : () -> [@cfg.user, @cfg.host].join('@')

  #---------

  do_create : (cb) ->
    esc = make_esc cb, "do_create"
    log.info "+ creating database: #{@cfg.database}"
    await @open_file esc defer()
    await @get_conn { root : true }, esc defer c
    @password = base64u.encode prng 15
    queries = [
      "CREATE DATABASE #{@cfg.database}"
      "CREATE USER #{@fq_user()}"
      "SET PASSWORD FOR #{@fq_user()} = PASSWORD('#{@password}')"
      "GRANT ALL ON #{@cfg.database}.* TO #{@cfg.user}"
      "FLUSH PRIVILEGES"
    ]
    for q in queries
      await c.query q, esc defer()
    await @get_conn { root : false }, esc defer c2
    await c2.query @_create_tables, esc defer()
    await @write_secrets esc defer()
    log.info "- created database"
    cb null
    
  #---------

  confirm_please : (msg, cb) ->
    await read { prompt : msg }, defer err, val
    if not err? and not (val in ['y', 'Y', 'yes', 'YES' ])
      err = new Error "canceled"
    cb err

  #---------

  cmd_delete : (cb) ->
    esc = make_esc cb, "do_create"
    await @confirm_please "Really nuke your database? [y/N]", esc defer()
    log.info "+ Nuking database #{@cfg.database}"
    await @get_conn { root : true }, esc defer c
    queries = [
      "DROP USER #{@fq_user()}"
      "DROP DATABASE #{@cfg.database}"
      "FLUSH PRIVILEGES"
    ]
    for q in queries
      await c.query q, esc defer()
    log.info "- Nuked!"
    cb null

  #---------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @init esc defer()
    await @parse_args esc defer()
    await @cmd esc defer()
    cb null

##-----------------------------------------------------------------------

exports.main = () ->
  env.make (m) -> m.usage "Usage: $0 [-m <runmode>] [<init|nuke>]"
  eng = new InitDB()
  await eng.run defer err
  rc = 0
  if err?
    console.error err.message
    rc = 2
  process.exit rc

##-----------------------------------------------------------------------
