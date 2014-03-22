
############################################################################################################
njs_fs                    = require 'fs'
njs_path                  = require 'path-extra'
#...........................................................................................................
TYPES                     = require 'coffeenode-types'
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'OPTIONS'
log                       = TRM.get_logger 'plain',   badge
info                      = TRM.get_logger 'info',    badge
whisper                   = TRM.get_logger 'whisper', badge
alert                     = TRM.get_logger 'alert',   badge
debug                     = TRM.get_logger 'debug',   badge
warn                      = TRM.get_logger 'warn',    badge
help                      = TRM.get_logger 'help',    badge
echo                      = TRM.echo.bind TRM
BITSNPIECES               = require 'coffeenode-bitsnpieces'
# #...........................................................................................................
# suspend                   = require 'coffeenode-suspend'
# step                      = suspend.step
# after                     = suspend.after
# eventually                = suspend.eventually
# every                     = suspend.every
#...........................................................................................................
### https://github.com/mozilla/node-convict ###
convict                   = require 'convict'
#...........................................................................................................
### https://github.com/kof/node-cjson ###
# CJSON                     = require 'cjson'

njs_cp = require 'child_process'
@_get_cwd = ( handler ) ->
  # njs_cp.exec '../echo-cwd', ( error, stdout, stderr ) ->
  njs_cp.exec 'pwd', ( error, stdout, stderr ) ->
    throw error if error?
    throw new Error stderr if stderr? and stderr.length isnt 0
    info 'stdout:', rpr stdout
    info '...', require.resolve njs_path.join __dirname, 'main'


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_app_home_from_routes = ( routes ) ->
  ### Return the file system route to the current (likely) application folder. This works by traversing all
  the routes in `require[ 'main' ][ 'paths' ]` and checking whether one of the `node_modules` folders
  listed there exists and is a folder; the first match is accepted and returned. If no matching existing
  route is found, an error is thrown.

  NB that the algorithm works even if the CoffeeNode Options module has been symlinked from another location
  (rather than 'physically' installed) and even if the application main file has been executed from outside
  the application folder (i.e. this obviates the need to `cd ~/route/to/my/app` before doing `node ./start`
  or whatever—you can simply do `node ~/route/to/my/app/start`), but it does presuppose that (1) there *is*
  a `node_modules` folder in your app folder; (2) there is *no* `node_modules` folder in the subfolder or
  any of the intervening levels (if any) that contains your startup file. Most modules that follow the
  established NodeJS / npm way of structuring modules should naturally comply with these assumptions. ###
  #.........................................................................................................
  for route in routes
    try
      return njs_path.dirname route if ( njs_fs.statSync route ).isDirectory()
    #.......................................................................................................
    catch error
      ### silently ignore missing routes: ###
      continue if error[ 'code' ] is 'ENOENT'
      throw error
  #.........................................................................................................
  throw new Error "unable to determine application home; tested routes: \n\n  #{routes.join '\n  '}\n"

#-----------------------------------------------------------------------------------------------------------
@_app_name_from_home = ( app_home ) ->
  return njs_path.basename app_home

#-----------------------------------------------------------------------------------------------------------
@_cndid_from_app_name = ( app_name ) ->
  return R unless /^coffeenode-.+$/.test ( R = app_name )
  R = R.replace /^coffeenode-/, ''
  R = R.replace /-/g, '/'
  return R.toUpperCase()

#-----------------------------------------------------------------------------------------------------------
@get_app_info = ( app_home = null, options_filename = null ) ->
  app_home     ?= @_app_home_from_routes require[ 'main' ][ 'paths' ]
  app_name      = @_app_name_from_home app_home
  cndid         = @_cndid_from_app_name app_name
  options_route = njs_path.join app_home, ( options_filename ? 'options.json' )
  schema_route  = njs_path.join app_home, (  schema_filename ? 'options-schema.json' )
  #.........................................................................................................
  R =
    '~isa':             'OPTIONS/app-info'
    'user-home':        njs_path.homedir()
    'home':             app_home
    'name':             app_name
    'cndid':            cndid
    'options-route':    options_route
    'schema-route':     schema_route
  #.........................................................................................................
  return R

# #-----------------------------------------------------------------------------------------------------------
# @get_module_info = ( module_home = null, options_filename = null ) ->
#   module_home  ?= @_app_home_from_routes require[ 'main' ][ 'paths' ]
#   module_name   = @_app_name_from_home module_home
#   cndid         = @_cndid_from_app_name module_name
#   options_route = njs_path.join module_home, ( options_filename ? 'options.json' )
#   schema_route  = njs_path.join module_home, (  schema_filename ? 'options-schema.json' )
#   #.........................................................................................................
#   R =
#     '~isa':             'OPTIONS/module-info'
#     'home':             app_home
#     'name':             module_name
#     'cndid':            cndid
#     'options-route':    options_route
#     'schema-route':     schema_route
#   #.........................................................................................................
#   return R

#-----------------------------------------------------------------------------------------------------------
@_load = ( name, route ) ->
  try
    # return CJSON.load route
    source = njs_fs.readFileSync route, encoding: 'utf-8'
  catch error
    switch code = error[ 'code' ]
      when 'ENOENT' then  alert "\nunable to load #{name} from \n  #{route}\n"
      when 'EACCES' then  alert "\ninsufficient rights to load #{name} from \n  #{route}\n"
      else                alert "\nan error occurred when trying to load #{name} from \n  #{route}\n"
    throw error
  #.........................................................................................................
  try
    return JSON.parse source
  catch error
    alert "\nan error occurred when trying to parse #{name} from file \n  #{route}\n"
    throw error

#-----------------------------------------------------------------------------------------------------------
@_get_schema = ( app_info = null ) ->
  app_info       ?= @get_app_info()
  schema_route    = app_info[ 'schema-route'  ]
  #.........................................................................................................
  return @_load 'options schema', schema_route

#-----------------------------------------------------------------------------------------------------------
@_module_name_from_options_filename = ( options_filename ) ->
  matcher = /^([^\/]+)-options.json$/
  unless matcher.test options_filename
    throw new Error "this does not look like a valid module options filename: #{rpr options_filename}"
  return options_filename.replace matcher, '$1'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@get_app_options = ->
  #.........................................................................................................
  app_info        = @get_app_info()
  schema          = @_get_schema app_info
  cfg             = convict schema
  options_route   = app_info[ 'options-route' ]
  raw_options     = @_load 'options', options_route
  # sorting         = []
  #.........................................................................................................
  cfg.load raw_options
  #.........................................................................................................
  R =
    '~isa':         'OPTIONS/options'
    # '%schema':      schema
    # '%cfg':         cfg
    # '%sorting':     sorting
    'app-info':     app_info
  #.........................................................................................................
  for key of schema
    throw new Error "illegal options key: #{rpr key}" if key is 'app-info'
    # sorting.push key
    R[ key ] = cfg.get key
  #.........................................................................................................
  return R

# #-----------------------------------------------------------------------------------------------------------
# @get_module_options = ( app_options, module_name ) ->





