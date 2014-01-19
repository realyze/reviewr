Q = require 'q'
_ = require 'underscore'
moment = require 'moment'
request = require 'request'
sa = require 'superagent'


exports.setup = (app) ->

  app.get '/api/stats/:user', (req, res, next) ->
    if req.params['user'] == 'all'
      qData = getReviewRequestsForUser()
    else
      qData = getReviewRequestsForUser(req.params['user'])

    qData
      .then (data) ->
        if _.isString(data)
          data = JSON.parse data
        console.log 'data', data.review_requests.length, data
        res.json data
      .fail (err) ->
        console.error err


  app.get '/api/review/:rid', (req, res, next) ->
    Q.all([
      getReviewRequestDetails(req.params['rid'], 'reviews')
      getReviewRequestDetails(req.params['rid'], 'changes')
    ])
      .then ([{reviews}, {changes}]) ->
        #console.log 'review details r', reviews
        #console.log 'review details c', changes

        revs = ({timestamp, ship_it} for {timestamp, ship_it} in reviews)
        shipItRev = _.findWhere revs, ship_it: true
        revs = _.without revs, shipItRev

        if shipItRev
          revsTillShipIt = _.reject revs, ({timestamp}) ->
            moment(timestamp).isAfter(moment(shipItRev.timestamp))

        chngs = ({timestamp, fields_changed} for {timestamp, fields_changed} in changes)
        submitted = _.find chngs, ({fields_changed}) ->
          return _.isEqual fields_changed.status, { new: 'S', old: 'P' }

        res.json {
          id: req.params['rid']
          created: null
          reviews: revs
          ship_it: shipItRev
          submitted: submitted
        }

      .fail (err) ->
        console.error err

###
created
[review]
ship_it
submitted
###


UNAME = 'statistics.daemon'
PWD = 'paWApu2E'


getReviewRequestDetails = (rid, resource) ->
  deferred = Q.defer()

  request.get "https://#{UNAME}:#{PWD}@review.salsitasoft.com/api/review-requests/#{rid}/#{resource}/",
    {json: true},
    (e, r, data) ->
      if e then return deferred.reject(e)
      deferred.resolve data

  return deferred.promise


getReviewRequestsForUser = (user) ->
  deferred = Q.defer()

  qs = {
    'status': 'all'
    'max-results': '200'
    'time-added-to': '2014-01-01T12:00:00+01:00' #moment().subtract('weeks', 5).format()
  }
  if user?
    qs['from-user'] = user

  qs = _.reduce qs, (res, val, key) ->
    "#{res}&#{key}=#{val}"
  , ""

  console.log 'qs', qs

  request.get "https://#{UNAME}:#{PWD}@review.salsitasoft.com/api/review-requests/?#{qs}",
    (e, r, data) ->
      if e then return deferred.reject(e)
      deferred.resolve data

  return deferred.promise
