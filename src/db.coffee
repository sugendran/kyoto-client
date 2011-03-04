http   = require 'http'
util   = require 'util'

Cursor = require './cursor'
RestClient = require './rest_client'
RpcClient = require './rpc_client'

class DB

  # constructor: (x) ->
  #   # not sure we need to do anything here

  open: (@host = 'localhost', @port = 1978) ->
    @client = http.createClient(@port, @host)
    @restClient = new RestClient(@port, @host)
    this

  close: (callback) ->
    # Make a dummy request with connection close specified
    request = @client.request 'GET', '/rpc/echo',
      'Connection': 'close'
    request.end()

    request.on 'end', ->
      callback()

  echo: (input, callback) ->
    RpcClient.call @client, 'echo', input, (error, status, output) ->
      if error?
        callback error, output
      else if status != 200
        error = new Error("Unexpected response from server: #{status}")
        callback error, output
      else
        callback undefined, output

  report: (callback) ->
    RpcClient.call @client, 'report', {}, (error, status, output) ->
      if error?
        callback error, output
      else if status != 200
        error = new Error("Unexpected response from server: #{status}")
        callback error, output
      else
        callback undefined, output

  status: (args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to status");

    rpc_args = {}
    rpc_args.DB = database if database?
    RpcClient.call @client, 'status', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status != 200
        error = new Error("Unexpected response from server: #{status}")
        callback error, output
      else
        callback undefined, output

  # Remove all values
  clear: (args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to clear");

    rpc_args = {}
    rpc_args.DB = database if database?
    RpcClient.call @client, 'clear', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status != 200
        error = new Error("Unexpected response from server: #{status}")
        callback error, output
      else
        callback undefined, output

  # Note: value can be a string or Buffer for utf-8 strings it should be a Buffer
  set: (key, value, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to set");

    @restClient.put key, value, (error) ->
      callback error

  # Add a record if it doesn't already exist
  add: (key, value, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to add");

    rpc_args =
      key: key
      value: value
    rpc_args.DB = database if database?
    RpcClient.call @client, 'add', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status == 200
        callback undefined, output
      else if status == 450
        callback (new Error("Record exists")), output
      else
        callback new Error("Unexpected response from server: #{status}"), output

  # Replace an existsing record
  replace: (key, value, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to replace");

    rpc_args =
      key: key
      value: value
    rpc_args.DB = database if database?
    RpcClient.call @client, 'replace', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status == 200
        callback undefined, output
      else if status == 450
        callback (new Error("Record does not exist")), output
      else
        callback new Error("Unexpected response from server: #{status}"), output

  append: (key, value, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to append");

    rpc_args =
      key: key
      value: value
    rpc_args.DB = database if database?
    RpcClient.call @client, 'append', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status != 200
        error = new Error("Unexpected response from server: #{status}")
        callback error, output
      else
        callback undefined, output

  increment: (key, num, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to increment");

    rpc_args =
      key: key
      num: num
    rpc_args.DB = database if database?
    RpcClient.call @client, 'increment', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status == 200
        callback undefined, output
      else if status == 450
        callback (new Error("The existing record was not compatible")), output
      else
        callback new Error("Unexpected response from server: #{status}"), output

  incrementDouble: (key, num, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to incrementDouble");

    rpc_args =
      key: key
      num: num
    rpc_args.DB = database if database?
    RpcClient.call @client, 'increment_double', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status == 200
        callback undefined, output
      else if status == 450
        callback (new Error("The existing record was not compatible")), output
      else
        callback new Error("Unexpected response from server: #{status}"), output

  cas: (key, oval, nval, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to cas");

    rpc_args =
      key: key
      oval: oval
    rpc_args.nval = nval if nval?
    rpc_args.DB = database if database?
    RpcClient.call @client, 'cas', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status == 200
        callback undefined, output
      else if status == 450
        callback (new Error("Record has changed")), output
      else
        callback new Error("Unexpected response from server: #{status}"), output

  remove: (key, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to remove");

    @restClient.delete @client, key, (error) ->
      callback error

  # key, [database], callback
  get: (key, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to get");

    @restClient.get key, (error, value) ->
      callback error, value

  setBulk: (records, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to setBulk");

    rpc_args = {}
    rpc_args.DB = database if database?
    rpc_args["_#{key}"] = value for key, value of records

    RpcClient.call @client, 'set_bulk', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status == 200
        callback undefined, output
      else
        callback new Error("Unexpected response from server: #{status}"), output

  removeBulk: (records, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to removeBulk");

    rpc_args = {}
    rpc_args.DB = database if database?
    rpc_args["_#{key}"] = '' for key, value of records

    RpcClient.call @client, 'remove_bulk', rpc_args, (error, status, output) ->
      if error?
        callback error, output
      else if status == 200
        callback undefined, output
      else
        callback new Error("Unexpected response from server: #{status}"), output

  getBulk: (keys, args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        database = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to getBulk");

    rpc_args = {}
    rpc_args.DB = database if database?
    rpc_args["_#{key}"] = '' for key in keys

    RpcClient.call @client, 'get_bulk', rpc_args, (error, status, output) ->
      if error?
        return callback error, output
      else if status != 200
        error = new Error("Unexpected response from server: #{status}")
        return callback error, output

      results = {}
      for key, value of output
        results[key[1...key.length]] = value if key.length > 0 and key[0] == '_'
      callback undefined, results

  _matchUsing: (procedure, pattern, args) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        max      = args[0]
        callback = args[1]
      when 3
        max      = args[0]
        database = args[2]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to #{procedure}");

    rpc_args = {}
    if procedure == 'match_prefix'
      rpc_args.prefix = pattern
    else
      rpc_args.regex = pattern
    rpc_args.DB = database if database?
    rpc_args.max = max if max?

    RpcClient.call @client, procedure, rpc_args, (error, status, output) ->
      if error?
        return callback error, output
      else if status != 200
        error = new Error("Unexpected response from server: #{status}")
        return callback error, output

      results = []
      for key, value of output
        results.push(key[1...key.length]) if key.length > 0 and key[0] == '_'
      callback undefined, results

  # prefix, [max], [database], callback
  matchPrefix: (prefix, args...) ->
    this._matchUsing 'match_prefix', prefix, args

  # regex, [max], [database], callback
  matchRegex: (regex, args...) ->
    this._matchUsing 'match_regex', regex, args

  # [key], callback
  getCursor: (args...) ->
    switch args.length
      when 1 then callback = args[0]
      when 2
        key = args[0]
        callback = args[1]
      else
        throw new Error("Invalid number of arguments (#{args.length}) to getCursor");

    cursor = new Cursor(this)
    cursor.jump key, (error) ->
      callback error, cursor

module.exports = DB
