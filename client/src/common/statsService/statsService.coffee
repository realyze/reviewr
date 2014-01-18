angular.module('reviewr.statsService', [])


.service 'statsService', ->

  orderStatsByYearAndMonth = (data, field) ->

    byYear = _.groupBy data.review_requests, (req) ->
      console.log 'req field', req[field]
      moment(req[field]).year()

    byYearAndMonth = {}

    for year, reviews of byYear
      byYearAndMonth[year] = _.groupBy reviews, (data) ->
        moment(data[field]).month()
      # Fill in missing months.
      for i in [0..11]
        byYearAndMonth[year][i] or = []

    return byYearAndMonth

