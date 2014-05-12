#--------------------------------------------------

parse_key = (key) ->
  # First split into dict keys
  tmp = ({ type : 'dict', key : k } for k in key.split /\./)

  out = []

  # Now deal with array indices, like 'foo[3][50][1]'
  for item in tmp
    if (m = item.key.match /^([^[]*)((?:\[\d+\])+)$/)
      if m[1]? and m[1].length
        item.key = m[1]
        out.push item
      indices = m[2][1...-1].split /\]\[/
      for index in indices
        out.push { type : 'array', key : parseInt(index, 10) }
    else
      out.push item

  return out

#--------------------------------------------------

exports.json_checker = json_checker = ({key, template, json}) -> {}

console.log parse_key "[3][4][5].shit.bar[4][5].bizzle[50].shit"

