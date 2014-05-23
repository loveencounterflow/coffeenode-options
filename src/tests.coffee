
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
OPTIONS                   = require './main'

TRM.dir OPTIONS


# info OPTIONS._app_home_from_routes()
# info OPTIONS._app_name_from_home()
# info OPTIONS._cndid_from_app_name()
# info OPTIONS._get_schema()
# info OPTIONS._load()
# info OPTIONS._module_name_from_options_filename()
info OPTIONS.get_app_info()
info OPTIONS.get_app_options()

