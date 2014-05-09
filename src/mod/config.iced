
env = require "../env"
path = require 'path'

#=======================================================================

class Module

  # other modules access config in their constructors, so we can't
  # source files in init(), we need to do it synchronously here.
  # if we need await for constructors, we need to rethink the module
  # creation scheme.
  constructor: () ->
    @_mode = env.get().get_run_mode()
    @_config_dir = env.get().get_config_dir()
    top = require(path.join(@_config_dir, "top"))
    @_rfiles = top.required
    @_ofiles = top.optional
    @_obj = {}
    @_paths = {}
    @source_modules @_rfiles, true
    @source_modules @_ofiles, false

  #-----------------------------------------

  find_path : (m) ->
    paths = [ (path.join @_config_dir, @_mode.config_dir(), m),
              (path.join @_config_dir, m) ]
    for p in paths
      try
        require.resolve p
        return p
      catch e
        continue
    return null

  #-----------------------------------------

  source_module : (p) ->
    m = require p
    if m.config?         then m.config
    else if m.generator? then m.generator @
    else if m?           then m
    else null

  #-----------------------------------------

  source_modules : (list, required) ->
    @_loaded = true
    for f in list
      p = @find_path f
      if p
        c = @source_module p
        @_paths[f] = p
        @_obj[f] = c
        @[f] = c
      else if required
        @_loaded = false
        console.log "Cannot find config file '#{f}'"

  #-----------------------------------------

  obj: () -> @_obj
  mode : () -> @_mode
  init : (cb) -> cb @_loaded

  #-----------------------------------------

  # Call this to watch to see if a config file changes!
  watch : (m, multi_cb) ->
    fm = @_paths[m]
    fp = require.resolve fm
    fs = require 'fs'
    watchOpts = { interval : 100, persistent : true }
    if fp
      fs.watchFile fp, watchOpts, (curr, prev) =>
        if curr.mtime > prev.mtime
          console.log "config module update for #{m}"
          delete require.cache[fp]
          newConfig = (require fm).config
          @_obj[m] = @[m] = newConfig
          multi_cb newConfig if multi_cb
    else
      console.log "config watch error: cannot find module #{fm}"

#=======================================================================

exports.Module = Module
