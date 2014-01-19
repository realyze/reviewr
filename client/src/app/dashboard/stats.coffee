angular.module("reviewr.dashboard.stats", [
])


.service 'statsService', ->

  return {
    calculateExtremes: (data, diffList) ->
      return {
        max: [_.max(diffList), data[_.indexOf diffList, _.max(diffList)]]
        min: [_.min(diffList), data[_.indexOf diffList, _.min(diffList)]]
      }
  }
