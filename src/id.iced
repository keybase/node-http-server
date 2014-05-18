
crypto = require 'crypto'

#=======================================================================

exports.generate = (cfg, source) ->
  l = cfg.byte_length
  source or= crypto.prng(l-1)
  Buffer.concat [ source, (new Buffer cfg.lsb, 'hex') ]

#=======================================================================

exports.match = (id, cfg) ->
  (id.length is cfg.byte_length*2) and (id[(id.length - 2)...] is parseInt(cfg.lsb, 16))

#=======================================================================
