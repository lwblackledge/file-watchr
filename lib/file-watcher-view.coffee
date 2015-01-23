path = require 'path'
{$, $$, View} = require 'atom-space-pen-views'
{CompositeDisposable, Emitter} = require 'atom'
{log, warn} = require './utils'

module.exports =
class FileWatcherView extends View

  hasConflict: false

  @content: ->
    @div class: 'file-watcher', =>
      @div outlet: 'fileChangedLabel', class: 'message', 'The file has changed on disk.'
      @div class: 'options', =>
        @button outlet: 'okButton', class: 'btn btn-warning', 'Reload'
        @button outlet: 'cancelButton', class: 'btn btn-default', 'Ignore'

  initialize: (@editor) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    unless @editor?
      warn "No editor instance on this editor"

    @handleEvents()
    @handleEditorEvents()
    @handleConfigChanges()

  handleEditorEvents: ->
    @subscriptions.add @editor.onDidConflict =>
      @hasConflict = true
      log "File has conflict"
      log "show prompt: " + @showPrompt
      log "show active: " + @showActiveOnly
      @showReloadPrompt() if @showPrompt

    @subscriptions.add @editor.onDidSave =>
      @hasConflict = false

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @subscriptions.add atom.workspace.observeActivePaneItem =>
      log "selected editor: " + @editor.id
      if @editor.id is atom.workspace.getActiveTextEditor()?.id && @hasConflict
        log "File on disk has changed: " + @editor.getPath()
        log "show prompt: " + @showPrompt
        @showReloadPrompt() if @showPrompt

  handleConfigChanges: ->
    @subscriptions.add atom.config.observe 'file-watcher.promptWhenFileHasChangedOnDisk',
      (promptWhenFileHasChangedOnDisk) => @showPrompt = promptWhenFileHasChangedOnDisk

    @subscriptions.add atom.config.observe 'file-watcher.promptForActiveFilesOnly',
      (promptForActiveFilesOnly) => @showActiveOnly = promptForActiveFilesOnly

  showReloadPrompt: ->
    fileName = path.basename @editor.getPath()
    log fileName

    @fileChangedLabel.text(fileName + ' has changed on disk.')

    log @content

    # modalOptions = {
    #   item: fileName + ' has changed on disk.'
    #   visible: true
    # }

    #@modal = atom.workspace.addModalPanel(modalOptions)

    #log @modal

  handleEvents: ->
    @okButton.on 'click', '.ok', =>
      @hasConflict = false
      @editor.getBuffer.reload()
      @modal.dispose()

    @cancelButton.on 'click', '.cancel', =>
      @hasConflict = false
      @modal.dispose()

  destroy: ->
    @modal?.dispose()
    @content?.dispose()
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
