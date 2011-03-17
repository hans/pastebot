################################################################################
#                                INITIALIZATION                                #
################################################################################

# Require the Express.js library and create the server object. This object,
# which we'll name `app`, is used in pretty much every statement that follows.
express = require 'express'
app = express.createServer()

# Require the Redis library and connect to the server. The connection
# information is provided to this script via environment variables. (In NodeJS,
# environment variables are available in the hash `process.env`.
redis = require 'redis'
redis_client = redis.createClient process.env.PASTEBOT_REDIS_PORT,
  process.env.PASTEBOT_REDIS_HOST, process.env.PASTEBOT_REDIS_PASSWORD

# Set up a callback for catching Redis errors.
redis_client.on 'error', (err) ->
  console.log err

# We're going to store these pastes as base-64 strings to avoid lots of
# problems. I found a little bit of code for this that will work perfectly,
# and translated it to CoffeeScript.
# 
# See `lib/base64.coffee` for some notes on Node's "exporting" of objects.
# 
# http://farhadi.ir/works/base64
base64 = require './lib/base64'

################################################################################
#                                CONFIGURATION                                 #
################################################################################

# Enable the bodyParser middleware, so Express knows what to do with the request
# body on POST requests. This allows us to use `req.body` to access POST data.
# 
# http://expressjs.com/guide.html#HTTP-Methods
app.use express.bodyParser()

# Set the default view engine for this application to Jade. This allows us
# to omit the extension name when calling render() further on.
# 
# http://expressjs.com/guide.html#View-Rendering
app.set 'view engine', 'jade'

################################################################################
#                                   ROUTING                                    #
#                                                                              #
# Express's routing system is very similar to other common web frameworks (ex. #
# Sinatra). The basic method structure to set up a route is as follows:        #
#                                                                              #
#     app.method path, callback_function                                       #
#                                                                              #
# where `method` is the HTTP method of the request, and `callback_function` is #
# a function which accepts two parameters: a `req` (request) parameter, which  #
# contains the headers, data, body, etc. of the request, and a `res` (response)#
# object, which is used to send responses to the client.                       #
#                                                                              #
# In this application, we'll be using the `req` variable for its `params` and  #
# `body` attributes. `params` contains any URL parameters (see the last route) #
# and `body`, thanks to our bodyParser() setup in Configuration, contains      #
# POST data sent in requests.                                                  #
#                                                                              #
# We will use two methods of the `res` object:                                 #
#   * `redirect(path, http_code)`                                              #
#   * `render(view_name, options)`: Renders a view (stored in the `views`      #
#     directory of this application.                                           #
################################################################################

# Let's set up a basic redirect. I'll code a homepage example when I feel less
# lazy.
app.get '/', (req, res) ->
  # Respond with a 301 Redirect to /pastes/create.
  res.redirect '/pastes/create', 301

# If this is a GET request, the user hasn't input anything yet. Let's render
# the form, then.
app.get '/pastes/create', (req, res) ->
  res.render 'pastes/create',
    locals:
      title: 'create paste'

# This is a POST request, so that means the user has submitted the form. (We
# know this because we set the paste form's method to POST.) Time to save the
# paste to our Redis instance.
app.post '/pastes/create', (req, res) ->
  # Let's build a little JSON container for this paste object, using data
  # provided in the POST parameters.
  paste =
    language: req.body.language
    # Encode the paste content as a base-64 string.
    content: base64.encode req.body.content
  console.log paste
  
  # Get the next available ID for a paste. Emulating a SQL auto_increment
  # feature, sorta. This Redis library accepts a callback function, which
  # will be called once the requested command is completed. It provides an
  # `err` object and the result of the command (in the case of a Redis command
  # like INCR, the new value, post-increment) is set as the second parameter.
  redis_client.incr 'pastes:next_id', (err, id) ->
    # Okay, we got an ID. Store that paste object as a JSON string.
    redis_client.set "pastes:id:#{id}", JSON.stringify(paste), (err, json) ->
      # Woot, it's set. Let's show it to them - we can just pass that `paste`
      # variable we made earlier to the `pastes/show` view.
      res.redirect "/pastes/#{id}", 301

# This is a route with a parameter. If none of the above routes are matched
# to the request, Express will know that this is the only available route left.
# This works just like the routing of a lot of modern web frameworks: Rails,
# Sinatra, etc.
# So, this will match any URL, pretty much.. except for the requests that come
# before it. Express will set the variable `req.params.id` so we can access
# this dynamic value.
app.get '/pastes/:id', (req, res) ->
  # The `id` parameter of the route corresponds to a paste ID. Let's fetch the
  # stored paste.
  redis_client.get "pastes:id:#{req.params.id}", (err, paste_json) ->
    # We have the paste JSON that was stored earlier. Parse that sucker!
    # Remember that we stored the `content` attribute of the paste object as a
    # base-64 string, so we'll have to decode that after parsing.
    paste = JSON.parse paste_json.toString()
    paste.content = base64.decode paste.content
    
    # Render `/views/pastes/show.jade`, displaying the paste we loaded.
    res.render 'pastes/show',
      locals:
        title: 'view paste'
        paste: paste

# Tell Express to listen for requests on port 3000.
app.listen 3000
