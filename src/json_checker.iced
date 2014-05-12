
#--------------------------------------------------

parse = (key) ->
  # First split into dict keys
  tmp = ({ type : 'dict', key : k } for k in key.split /\./)

  split_array_indices = (out, item) ->
    console.log item.key
    if (m = item.key.match /^([^[]+)((?:\[\d+\])+)$/)
      console.log m
      item.key = m[1]
      out.push item
      indices = m[2][1...-1].split /\]\[/
      for index in indices
        out.push { type : 'array', key : parseInt(index, 10) }
    else
      out.push item

  out = []
  for item in tmp
    split_array_indices out, item
  return out

#--------------------------------------------------

exports.json_checker = json_checker = ({key, template, json}) -> {}

console.log parse "shit.bar[4][5].bizzle[50].shit"

