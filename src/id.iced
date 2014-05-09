
crypto = require 'crypto'

#=======================================================================

exports.generate = (cfg, source) ->
  l = cfg.byte_length
  source or= crypto.prng(l)
  source.toString('hex')[0...(2*l-2)] + cfg.lsb

#=======================================================================

exports.match = (id, cfg) ->
  (id.length is cfg.byte_length*2) and (id[(id.length - 2)...] is cfg.lsb)

#=======================================================================

exports.xor = (ids, cfg) ->
  l = cfg.byte_length
  out = new Buffer l
  ids = (new Buffer(id, 'hex') for id in ids)
  for i in [0...l]
    val = 0
    for id in ids
      j = 2*i
      val = val ^ id[i]
    out[i] = val
  out.toString('hex')[0...(2*l-2)] + cfg.lsb

#=======================================================================
