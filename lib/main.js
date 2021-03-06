// Generated by CoffeeScript 1.7.1
(function() {
  var BITSNPIECES, TRM, TYPES, alert, badge, convict, debug, echo, help, info, log, njs_cp, njs_fs, njs_path, rpr, warn, whisper;

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


  /* https://github.com/mozilla/node-convict */

  convict = require('convict');


  /* https://github.com/kof/node-cjson */

  njs_cp = require('child_process');

  this._get_cwd = function(handler) {
    return njs_cp.exec('pwd', function(error, stdout, stderr) {
      if (error != null) {
        throw error;
      }
      if ((stderr != null) && stderr.length !== 0) {
        throw new Error(stderr);
      }
      info('stdout:', rpr(stdout));
      return info('...', require.resolve(njs_path.join(__dirname, 'main')));
    });
  };

  this._app_home_from_routes = function(routes) {

    /* Return the file system route to the current (likely) application folder. This works by traversing all
    the routes in `require[ 'main' ][ 'paths' ]` and checking whether one of the `node_modules` folders
    listed there exists and is a folder; the first match is accepted and returned. If no matching existing
    route is found, an error is thrown.
    
    NB that the algorithm works even if the CoffeeNode Options module has been symlinked from another location
    (rather than 'physically' installed) and even if the application main file has been executed from outside
    the application folder (i.e. this obviates the need to `cd ~/route/to/my/app` before doing `node ./start`
    or whatever—you can simply do `node ~/route/to/my/app/start`), but it does presuppose that (1) there *is*
    a `node_modules` folder in your app folder; (2) there is *no* `node_modules` folder in the subfolder or
    any of the intervening levels (if any) that contains your startup file. Most modules that follow the
    established NodeJS / npm way of structuring modules should naturally comply with these assumptions.
     */
    var error, route, _i, _len;
    for (_i = 0, _len = routes.length; _i < _len; _i++) {
      route = routes[_i];
      try {
        if ((njs_fs.statSync(route)).isDirectory()) {
          return njs_path.dirname(route);
        }
      } catch (_error) {
        error = _error;

        /* silently ignore missing routes: */
        if (error['code'] === 'ENOENT') {
          continue;
        }
        throw error;
      }
    }
    throw new Error("unable to determine application home; tested routes: \n\n  " + (routes.join('\n  ')) + "\n");
  };

  this._app_name_from_home = function(app_home) {
    return njs_path.basename(app_home);
  };

  this._cndid_from_app_name = function(app_name) {
    var R;
    if (!/^coffeenode-.+$/.test((R = app_name))) {
      return R;
    }
    R = R.replace(/^coffeenode-/, '');
    R = R.replace(/-/g, '/');
    return R.toUpperCase();
  };

  this.get_app_info = function(app_home, options_filename) {
    var R, app_name, cndid, options_route, schema_route;
    if (app_home == null) {
      app_home = null;
    }
    if (options_filename == null) {
      options_filename = null;
    }
    if (app_home == null) {
      app_home = this._app_home_from_routes(require['main']['paths']);
    }
    app_name = this._app_name_from_home(app_home);
    cndid = this._cndid_from_app_name(app_name);
    options_route = njs_path.join(app_home, options_filename != null ? options_filename : 'options.json');
    schema_route = njs_path.join(app_home, typeof schema_filename !== "undefined" && schema_filename !== null ? schema_filename : 'options-schema.json');
    R = {
      '~isa': 'OPTIONS/app-info',
      'user-home': njs_path.homedir(),
      'home': app_home,
      'name': app_name,
      'cndid': cndid,
      'options-route': options_route,
      'schema-route': schema_route
    };
    return R;
  };

  this._load = function(name, route) {
    var code, error, source;
    try {
      source = njs_fs.readFileSync(route, {
        encoding: 'utf-8'
      });
    } catch (_error) {
      error = _error;
      switch (code = error['code']) {
        case 'ENOENT':
          alert("\nunable to load " + name + " from \n  " + route + "\n");
          break;
        case 'EACCES':
          alert("\ninsufficient rights to load " + name + " from \n  " + route + "\n");
          break;
        default:
          alert("\nan error occurred when trying to load " + name + " from \n  " + route + "\n");
      }
      throw error;
    }
    try {
      return JSON.parse(source);
    } catch (_error) {
      error = _error;
      alert("\nan error occurred when trying to parse " + name + " from file \n  " + route + "\n");
      throw error;
    }
  };

  this._get_schema = function(app_info) {
    var schema_route;
    if (app_info == null) {
      app_info = null;
    }
    if (app_info == null) {
      app_info = this.get_app_info();
    }
    schema_route = app_info['schema-route'];
    return this._load('options schema', schema_route);
  };

  this._module_name_from_options_filename = function(options_filename) {
    var matcher;
    matcher = /^([^\/]+)-options.json$/;
    if (!matcher.test(options_filename)) {
      throw new Error("this does not look like a valid module options filename: " + (rpr(options_filename)));
    }
    return options_filename.replace(matcher, '$1');
  };

  this.get_app_options = function() {
    var R, app_info, cfg, key, options_route, raw_options, schema;
    app_info = this.get_app_info();
    schema = this._get_schema(app_info);
    cfg = convict(schema);
    options_route = app_info['options-route'];
    raw_options = this._load('options', options_route);
    cfg.load(raw_options);
    R = {
      '~isa': 'OPTIONS/options',
      'app-info': app_info
    };
    for (key in schema) {
      if (key === 'app-info') {
        throw new Error("illegal options key: " + (rpr(key)));
      }
      R[key] = cfg.get(key);
    }
    return R;
  };

}).call(this);
