# ORIGINAL LICENSE AND AUTHOR:
#   Copyright (c) 2006 by Ali Farhadi.
#   released under the terms of the Gnu Public License.
#   see the GPL for details.
# 
#   Email: ali[at]farhadi[dot]ir
#   Website: http://farhadi.ir/
#
# Translated to CoffeeScript by Hans Engel <spam.me@engel.uk.to> 

# This file was not created to be used in an environment like Node.js. We need
# to add a little code at the end to make it usable for our purposes.
# 
# Jump to the bottom of the file to see the good stuff.

encode = (data) ->
  b64_map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
  result = []
  i = 0
  j = 0
  
  while i < data.length
    byte1 = data.charCodeAt i
    byte2 = data.charCodeAt i + 1
    byte3 = data.charCodeAt i + 2
    ch1 = byte1 >> 2
    ch2 = ( ( byte1 & 3 ) << 4 ) | ( byte2 >> 4 )
    ch3 = ( ( byte2 & 15 ) << 2 ) | ( byte3 >> 6 )
    ch4 = byte3 & 63
    
    if !byte2?
      ch3 = ch4 = 64
    else if !byte2?
      ch4 = 64
    
    result[j++] = b64_map.charAt(ch1) + b64_map.charAt(ch2) +
      b64_map.charAt(ch3) + b64_map.charAt(ch4)
    
    i += 3
  
  result.join ''

decode = (data) ->
  # strip non-base64 characters
  data = data.replace /[^a-z0-9\+\/=]/ig, ''
  
  b64_map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
  result = []
  i = 0
  j = 0

  until ( data.length % 4 ) is 0
    data += '='
  
  while i < data.length
    ch1 = b64_map.indexOf data.charAt(i)
    ch2 = b64_map.indexOf data.charAt(i + 1)
    ch3 = b64_map.indexOf data.charAt(i + 2)
    ch4 = b64_map.indexOf data.charAt(i + 3)
    byte1 = ( ch1 << 2 ) | ( ch2 >> 4 )
    byte2 = ( ( ch2 & 15 ) << 4 ) | ( ch3 >> 2 )
    byte3 = ( ( ch3 & 3 ) << 6 ) | ch4
    result[j++] = String.fromCharCode byte1

    result[j++] = String.fromCharCode byte2 unless ch3 is 64
    result[j++] = String.fromCharCode byte3 unless ch4 is 64
    
    i += 4
  
  result.join ''

# When we require this file in Node, we need to "export" this library. That
# way, it can be accessed by scripts which require it. Functions and objects
# can be exported by modifying the `export` variable. In this file, if we write
# 
#     exports.foo = 'bar'
# 
# This can be expected in a different file that requires this one:
# 
#     library = require 'path/to/the/library.js'
#     library.foo                                       # => 'bar'
# 
# So, knowing this, let's export some of these methods written above.
exports.encode = encode;
exports.decode = decode;
