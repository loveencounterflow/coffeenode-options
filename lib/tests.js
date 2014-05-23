// Generated by CoffeeScript 1.7.1
(function() {
  var BITSNPIECES, OPTIONS, TRM, TYPES, alert, badge, debug, echo, help, info, log, njs_fs, njs_path, rpr, warn, whisper;

  njs_fs = require('fs');

  njs_path = require('path-extra');

  TYPES = require('coffeenode-types');

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  badge = 'OPTIONS';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  whisper = TRM.get_logger('whisper', badge);

  alert = TRM.get_logger('alert', badge);

  debug = TRM.get_logger('debug', badge);

  warn = TRM.get_logger('warn', badge);

  help = TRM.get_logger('help', badge);

  echo = TRM.echo.bind(TRM);

  BITSNPIECES = require('coffeenode-bitsnpieces');

  OPTIONS = require('./main');

  TRM.dir(OPTIONS);

  info(OPTIONS.get_app_info());

  info(OPTIONS.get_app_options());

}).call(this);