
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

#===========================================================================================================
# HELPERS
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
  app_home     ?= BITSNPIECES.get_app_home()
  app_name      = @_app_name_from_home app_home
  cndid         = @_cndid_from_app_name app_name
  options_route = njs_path.join app_home, ( options_filename ? 'options.json' )
  #.........................................................................................................
  R =
    '~isa':             'OPTIONS/app-info'
    'user-home':        njs_path.homedir()
    'home':             app_home
    'name':             app_name
    'cndid':            cndid
    'options-route':    options_route
  #.........................................................................................................
  return R

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
  options_route   = app_info[ 'options-route' ]
  raw_options     = @_load 'options', options_route
  # sorting         = []
  #.........................................................................................................
  R =
    '~isa':         'OPTIONS/options'
    # '%schema':      schema
    # '%cfg':         cfg
    # '%sorting':     sorting
    'app-info':     app_info
  #.........................................................................................................
  return R



#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@compile = ( source, options ) ->
  change_count  = 0
  #---------------------------------------------------------------------------------------------------------
  BITSNPIECES.walk_containers_crumbs_and_values d, ( error, container, crumbs, value ) =>
    throw error if error?
    #.......................................................................................................
    if crumbs is null
      return
    #.......................................................................................................
    [ head..., key, ] = crumbs
    log "#{locator}:", rpr value
    # debug rpr key
    if key is 'box'
      container[ 'addition' ] = 'yes!'
      debug container

#-----------------------------------------------------------------------------------------------------------
@compile_options = ( options ) ->
  TYPES                 = require 'coffeenode-types'
  count_key             = @compile_options.count_key
  options[ count_key ] ?= 0
  #.........................................................................................................
  for name, value of options
    switch type = TYPES.type_of value
      when 'text'
        @compile_options.resolve_name.call @, options, null, name, value
      when 'pod'
        null
      when 'list'
        null
        # for sub_value, idx in list
  #.........................................................................................................
  return options

#-----------------------------------------------------------------------------------------------------------
@compile_options.count_key   = '%BITSNPIECES/compile-options/change-count'
@compile_options.no_name_re  = /^\\\$/
@compile_options.name_re     = /^\$([-_a-zA-Z0-9]+)$/

#-----------------------------------------------------------------------------------------------------------
@compile_options.resolve_name = ( options, container, key, value ) ->
  rpr         = ( require 'util' ).inspect
  count_key   = @compile_options.count_key
  container  ?= options
  #.........................................................................................................
  if ( match = value.match @compile_options.name_re )?
    new_name  = match[ 1 ]
    new_value = options[ new_name ]
    if new_value is undefined
      throw new Error "member #{rpr key} references undefined key as #{rpr value}"
    container[ key ]      = new_value
    options[ count_key ] += 1
    debug "replaced #{rpr key}: #{rpr value} with #{rpr new_name}: #{rpr new_value}"
  #.........................................................................................................
  else
    new_value             = value.replace @compile_options.no_name_re, '$'
    container[ key ]      = new_value
    if value isnt new_value
      options[ count_key ] += 1
      debug "replaced #{rpr value} with #{rpr new_value}"
  #.........................................................................................................
  return options


