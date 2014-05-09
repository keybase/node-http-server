
{Enum} = require './enum'

#==========================================================================

module.exports = new Enum
  OK                          : 0
  IN_PROGRESS                 : 10
  GENERIC_ERROR               : 100
  INPUT_ERROR                 : 101
  SCT_CORRUPT                 : 301
  SCT_EXPIRED                 : 302
  SCT_BAD_MAC                 : 303
  SCT_REPLAY                  : 304

#==========================================================================

