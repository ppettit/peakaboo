Template.room_controls.helpers
  thumbnail: ->
    roomId = @_id
    timestamp = @imageTimestamp
    switch Session.get 'view'
      when 'view-screen'
        file = 'screen'
      when 'view-camera'
        file = 'presenter'
      when 'view-galicaster'
        file = 'presentation'
    url = "/image/#{roomId}/#{file}"
    if timestamp then "#{url}?#{timestamp}" else url

Template.room_controls.events
  'click .peakaboo-command': (e) ->
    unsetCommandError()
    Session.set 'modal',
      e.currentTarget.dataset
  'change .audioFaders': (e) ->
    values = {}
    values["audio.#{e.currentTarget.id}.value.left"] = e.currentTarget.value
    values["audio.#{e.currentTarget.id}.value.right"] = e.currentTarget.value
    Rooms.update { '_id': @._id }, {
      $set: values
    }, (err, result) ->
      console.log err if err
      console.log result if result

Template.room_controls.rendered = ->
  @$('[data-toggle="tooltip"]').tooltip()

Template.confirmModal.rendered = ->
  Ladda.bind 'button.ladda-button'

Template.confirmModal.helpers
  modal: ->
    Session.get 'modal'
  commandError: ->
    Session.get 'command-error'

modalCall = (error, result) ->
  # When does error occur?
  if result.error
    Session.set 'command-error', result.error
  else
    $('#mymodal').modal 'hide'
  $('#modalOk').removeAttr 'disabled'
  $('#modalOk').removeAttr 'data-loading'
  $('#modalCancel').show 'slow'

unsetCommandError = ->
  Session.set 'command-error', ''

Template.confirmModal.events
  'click #modalOk': (e) ->
    unsetCommandError()
    $('#modalCancel').hide 'slow'
    switch Session.get('modal').action
      when 'restart'
        Meteor.call 'restartGalicaster', @room._id, modalCall
      when 'reboot'
        Meteor.call 'rebootMachine', @room._id, modalCall

Template.tableRow.helpers
  mcreated: ->
    moment(@created).format("DD-MM-YYYY HH:MM")
  mduration: ->
    moment(@duration * 1000).format("HH:mm:ss")
