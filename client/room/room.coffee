Template.room_controls.helpers
  thumbnail: ->
    switch Session.get 'view'
      when 'view-screen'
        @presentationVideo
      when 'view-camera'
        @presenterVideo
      when 'view-galicaster'
        @screen

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
  'click #peakaboo-pause-button': (e, template) ->
    room = template.data.room
    newState = not room.paused
    Rooms.update room._id, {$set: {paused: newState}}
    e.currentTarget.blur()
  'click #peakaboo-stop-button': (e, template) ->
    room = template.data.room
    Rooms.update room._id, {$set: {recording: false}}
    e.currentTarget.blur()

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


userCallback = (err, res) ->
  console.log res
  Session.setTemp 'recUserName', res.user_name
  Session.setTemp 'recUserPic', res.pic_url
  mods = []
  if res.modules.length
    mods = [
      course_code: ''
      module: 'Choose a module...'
    ].concat res.modules
  Session.setTemp 'recModules', mods
  Session.setTemp 'recWaiting', false
  $('.peakaboo-userdetails').show 'slow'

Template.recordModal.events
  'click #recordModalOk': (e, template) ->
    room = template.data.room
    title = $('#rec-title').val()
    $('#rec-title').val('')
    $('.peakaboo-userdetails').hide()
    $('#recordmodal').modal 'hide'

    userId = $('#user-id').val()
    $('#user-id').val('')
    
    userName = $('#user-name').text().trim()

    isPartOf = $('#module-id').val()
    series_title = $('#module-id option:selected').text()

    Session.setTemp 'recUserName', ''
    Session.setTemp 'recUserPic', ''
    Session.setTemp 'recModules', []
    Session.setTemp 'recWaiting', false
    
    currentMediaPackage =
      title: title
      rightsHolder: userId
      creator: userName
      created: Session.get 'serverTime'
      isPartOf: isPartOf
      series_title: series_title
      series_identifier: isPartOf

    update =
      recording: true
      currentMediaPackage: currentMediaPackage
      
    Rooms.update room._id, $set: update
    
  'keyup #user-id': (e, template) ->
    if @userTimeout then Meteor.clearTimeout @userTimeout
    $('.peakaboo-userdetails').hide()
    timeoutFunc = ->
      Session.setTemp 'recWaiting', true
      Meteor.call 'user_ws', e.currentTarget.value, userCallback
    if e.currentTarget.value
      @userTimeout = Meteor.setTimeout timeoutFunc, 1000
    
Template.recordModal.helpers
  userPic: ->
    Session.get 'recUserPic'
  userName: ->
    Session.get 'recUserName'
  modules: ->
    Session.get 'recModules'
  waiting: ->
    Session.get 'recWaiting'