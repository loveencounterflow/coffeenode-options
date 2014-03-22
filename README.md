





# CoffeeNode Options

* Uses [Mozilla's convict](https://github.com/mozilla/node-convict) to load, merge and validate settings

* Currently only `*.json` files are accepted; later versions may feature `*.cjson`, `*.js`, `*.coffee` or
  others

* Read application options: `app/options-schema.json` and `app/options.json`

* Read modules options: `app/node_modules/xxx/options-schema.json` and `app/xxx-options.json`

* Currently no 'meta-configuration', i.e. there are no options for CoffeeNode Options—conceivably, those
  would have to go into `app/options-options.json`


Layout schema:

    #............................................................................................
    app/                          # application home folder
      main.js                     # application code (might be in lib/ or src/ or wherever)
      options.json                # app options
      options-schema.json         # app options schema
      xxx-options.json            # module xxx application-wide options
      yyy-options.json            # module yyy application-wide options (not recommended)
      #..........................................................................................
      node_modules/
        #........................................................................................
        xxx/
          main.js                     # module code
          options.json                # module general options (do not edit)
          options-schema.json         # module general options schema
          node_modules/
          #......................................................................................
          yyy/
            options.json                # sub-module general options (do not edit)
            options-schema.json         # sub-module general options schema



There is certainly a degree of fragmentation caused by keeping a separate options file for each configurable
module of an app, and it is conceivable that you end up with a fair number of option files in your
application folder, which may be difficult to keep in a consistent state. However, the good thing about this
layout is that you can default-configure the modules of your app simply by copying a module's `option.json`
file into your application folder (and properly naming it)—you do not have to adjust the structure of your
*own* application. That said, it might still be a good idea to manage all your settings in a single
`options.json` file and then go and configure your dependencies based on those key/value pairs.

An important thing to keep in mind is (1) the usage of global vs. local modules, and (2) the usage of apps
and modules as scripts vs. libraries: The typical NodeJS / npm layout prescribes local modules; if you keep
to this, you can merrily configure a dependent module without affecting other software running on the
machine. If, however, you choose to install modules *globally* (and maybe `npm link` them for developement),
then any configuration of such a globalized sub-module may affect other consumers (within the same process)
of that sub-module, too, so you have to proceed with caution. The effects of such a 'settings leakage' may
also differ between modules that are kept within the main process for the entire process lifetime (a
library) and modules whose code is executed as a process in a child process, be it from the app or by the
user from the command line.

Configuration stages (stages further down the list win over earlier ones):

* environment variables
* option file in module home
* user's configuration file location (e.g. `/Users/$username/Library/Application Support/$appname` on OSX)
* option file in application home
* application command line arguments























