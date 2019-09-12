etch = require 'etch'

commands = require './package/commands'
config = require './package/config'
menu = require './package/menu'
settings = require './package/settings'
toolbar = require './package/toolbar'
semver = require 'semver'

# IMPORTANT: Update this when a new ink version is required:
INK_VERSION_COMPAT = "^0.11"

module.exports = JuliaClient =
  misc:       require './misc'
  ui:         require './ui'
  connection: require './connection'
  runtime:    require './runtime'

  activate: (state) ->
    etch.setScheduler(atom.views)
    process.env['TERM'] = 'xterm-256color'
    commands.activate @
    x.activate() for x in [menu, @connection, @runtime]
    @ui.activate @connection.client

    @requireDeps =>
      settings.updateSettings()

      if atom.config.get('julia-client.firstBoot')
        @ui.layout.queryDefaultLayout()
      else
        if atom.config.get('julia-client.uiOptions.layouts.openDefaultPanesOnStartUp')
          setTimeout (=> @ui.layout.restoreDefaultLayout()), 150

  requireDeps: (fn) ->
    isLoaded = atom.packages.isPackageLoaded("ink") and atom.packages.isPackageLoaded("language-julia")

    if isLoaded
      fn()
    else
      require('atom-package-deps').install('julia-client')
        .then  => @enableDeps fn
        .catch (err) ->
          console.error err
          atom.notifications.addError 'Installing Juno\'s dependencies failed.',
            detail: 'Juno requires the packages `ink` and `language-julia` to run.
                     Please install them manually from the settings view.'
            dismissable: true

  enableDeps: (fn) ->
    isEnabled = atom.packages.isPackageLoaded("ink") and atom.packages.isPackageLoaded("language-julia")

    if isEnabled
      fn()
    else
      atom.packages.enablePackage('ink')
      atom.packages.enablePackage('language-julia')

      if atom.packages.isPackageLoaded("ink") and atom.packages.isPackageLoaded("language-julia")
        atom.notifications.addSuccess "Automatically enabled Juno's dependencies.",
          description:
            """
            Juno requires the `ink` and `language-julia` packages. We've automatically enabled them
            for you.
            """
          dismissable: true

        inkVersion = atom.packages.loadedPackages["ink"].metadata.version
        if not atom.devMode and not semver.satisfies(inkVersion, INK_VERSION_COMPAT)
          atom.notifications.addWarning "Potentially incompatible `ink` version detected.",
            description:
              """
              Please make sure to upgrade `ink` to a version compatible with `#{INK_VERSION_COMPAT}`.
              The currently installed version is `#{inkVersion}`.

              If you cannot install an appropriate version through the `Packages` menu, open a terminal
              and type in `apm install ink@x.y.z`, where `x.y.z` is satisfies `#{INK_VERSION_COMPAT}`.
              """
            dismissable: true

        fn()
      else
        atom.notifications.addError "Failed to enable Juno's dependencies.",
          description:
            """
            Juno requires the `ink` and `language-julia` packages. Please install and enable them
            and restart Atom.
            """
          dismissable: true

  config: config

  deactivate: ->
    x.deactivate() for x in [commands, menu, toolbar, @connection, @runtime, @ui]

  consumeInk: (ink) ->
    commands.ink = ink
    x.consumeInk ink for x in [@connection, @runtime, @ui]

  consumeStatusBar: (bar) -> @runtime.consumeStatusBar bar

  consumeToolBar: (bar) -> toolbar.consumeToolBar bar

  consumeGetServerConfig: (conf) -> @connection.consumeGetServerConfig(conf)

  consumeGetServerName: (name) -> @connection.consumeGetServerName(name)

  consumeDatatip: (datatipService) -> @runtime.consumeDatatip datatipService

  provideClient: -> @connection.client

  provideAutoComplete: -> @runtime.provideAutoComplete()

  provideHyperclick: -> @runtime.provideHyperclick()

  handleURI: (parsedURI) -> @runtime.handleURI parsedURI
