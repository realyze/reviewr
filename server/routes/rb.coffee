Q = require 'q'
_ = require 'underscore'
moment = require 'moment'
request = require 'request'
sa = require 'superagent'


exports.setup = (app) ->

  app.get '/api/stats/:user', (req, res, next) ->
    params = {
      'time-added-to': '2014-01-01T12:00:00+01:00'
      'time-added-from': '2013-01-01T12:00:00+01:00'
    }
    if req.params['user'] != 'all'
      params['from-user'] = req.params['user']

    qData = getReviewRequests(params)

    qData
      .then (data) ->
        console.log 'RB data received'
        console.log 'data', data.length, data
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

        revs = ({timestamp, ship_it, user: links.user.title} for {timestamp, ship_it, links} in reviews)
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


UNAME = process.env['RB_USER']
PWD = process.env['RB_PWD']


getReviewRequestDetails = (rid, resource) ->
  deferred = Q.defer()

  request.get "https://#{UNAME}:#{PWD}@review.salsitasoft.com/api/review-requests/#{rid}/#{resource}/",
    {json: true},
    (e, r, data) ->
      if e then return deferred.reject(e)
      deferred.resolve data

  return deferred.promise


qGet = (url) ->
  dfr = Q.defer()
  request.get url, {json:true},
    (e, r, data) ->
      if e then return dfr.reject(e)
      dfr.resolve data
  dfr.promise


getReviewRequests = (params) ->
  qsDefs = {
    'status': 'all'
    'max-results': '200'
  }
  qDict = _.defaults params, qsDefs

  dictToQS = (dict) -> _.reduce dict, (res, val, key) ->
    "#{res}&#{key}=#{val}"
  , ""

  console.log 'qs', dictToQS(qDict)

  qGet("https://#{UNAME}:#{PWD}@review.salsitasoft.com/api/review-requests/?#{dictToQS(qDict)}")

    .then (data) ->
      console.log 'total res', data.total_results
      qReqs = (for i in [0..Math.floor(data.total_results/200)] #when i % 2 == 0
        qDict.start = i * 200
        console.log 'GET, start', qDict.start
        do (i) ->
          qGet("https://#{UNAME}:#{PWD}@review.salsitasoft.com/api/review-requests/?#{dictToQS(qDict)}")
            .then (data) ->
              console.log 'finished request', i
              data
      )
      Q.all(qReqs)

    .then (reqs) ->
      res = []
      for req in reqs
        res = res.concat req.review_requests
      return res
