
{Enum} = require('iced-utils').enum

#==========================================================================

module.exports = new Enum
  OK                          : 0
  IN_PROGRESS                 : 10
  GENERIC_ERROR               : 100
  INPUT_ERROR                 : 101
  NOT_FOUND                   : 102
  CORRUPTION                  : 103
  SCT_CORRUPT                 : 301
  SCT_EXPIRED                 : 302
  SCT_BAD_MAC                 : 303
  SCT_REPLAY                  : 304
  SCT_BAD_SOLUTION            : 305
  SESSION_EXPIRED             : 401
  DB_SELECT_ERROR             : 501
  DB_INSERT_ERROR             : 502
  DB_ASSERT_ERROR             : 503

#==========================================================================

