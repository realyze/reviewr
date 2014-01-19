# coffeelint: disable=max_line_length

angular.module("reviewr.dashboard", [
  'ui.router'
  'reviewr.dashboard.stats'
])
  
  
.config ($stateProvider) ->
  $stateProvider.state "userStats",
    url: "/stats/:user"
    views:
      main:
        controller: "DashboardCtrl"
        templateUrl: "dashboard/dashboard.tpl.html"
    data:
      pageTitle: "Dashboard"


.controller "DashboardCtrl", ($scope, $http, $log,
  $stateParams, statsService) ->

  $scope.data = null

  orderStatsByYearAndMonth = (data, field) ->
    byYear = _.groupBy data, (req) ->
      moment(req[field]).year()

    byYearAndMonth = {}

    for year, reviews of byYear
      byYearAndMonth[year] = _.groupBy reviews, (data) ->
        moment(data[field]).month()
      # Fill in missing months.
      for i in [0..11]
        byYearAndMonth[year][i] or = []

    return byYearAndMonth


  getReview = (rid) ->
    #console.log 'getting review for', rid
    dfr = Q.defer()
    $http.get("api/review/#{rid}")
    
    .success (data) ->
      dfr.resolve data

    .error (err) ->
      dfr.reject err

    return dfr.promise


  getAverageTimes = (data) ->
    dfr = Q.defer()
    qReviews = (getReview(review.id) for review in data)
    index = 0
    for r in qReviews
      r.then ->
        dfr.notify(index++ / (qReviews.length - 1))
    Q.all(qReviews).then dfr.resolve, dfr.reject
    return dfr.promise


  SAMPLE_COEF = 4

  $scope.avgProgress = 0

  $http.get("api/stats/#{$stateParams.user}")
    .success (data) ->

      $scope.data = orderStatsByYearAndMonth(data, 'time_added')
      console.log 'data', $scope.data

      $scope.years = ['2013']

      $scope.avg = {}
      $scope.avg.best = {}
      $scope.avg.worst = {}

      $scope.median = {}
      $scope.median.best = {}
      $scope.median.worst = {}

      $scope.steps = {}

      console.log 'data length', data.length
      nSamples = Math.min Math.ceil(data.length/SAMPLE_COEF), 50
      sample = _.shuffle(data)[0..nSamples]
      $scope.nSamples = nSamples

      getStats = (list) ->
        average = _.reduce(list, ((m,n)->m+n), 0) / list.length
        median = (_.sortBy list, (val) -> val)[Math.floor(list.length/2)]
        return {
          average: average
          median: median
        }

      monthLabels = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ]

      $scope.xAxisTickFormatFunction = -> (d) -> monthLabels[d]
      $scope.valueFormatFunction = -> (d) -> d3.round(d)
      $scope.reviewByMonth = {}
      for y in $scope.years
        $scope.reviewByMonth[y] = [{
          key: '#reviews'
          values: _.zip([0..11], (r.length for m, r of $scope.data[y]))
        }]

      qAvg = getAverageTimes(sample)

      $scope.avgProgress = 0
      qAvg.progress (perc) ->
        $scope.avgProgress = Math.ceil(perc * 100)
        $scope.$apply()

      qAvg
      .then (data) ->
        for r, i in sample
          data[i].created or= timestamp: moment(r.time_added)
          data[i].user or= r.links.submitter.title
        data

      # Filter out annotations.
      # TODO: This filters out *all* the submitter's comments.
      .then (data) ->
        for d in data
          d.reviews = _.reject d.reviews, (rev) ->
            rev.user == d.user
        data

      .then (data) ->
        withRev = (d for d in data when d.reviews.length > 0 or d.ship_it?)
        ttRev = (for d in withRev
          created = moment(d.created.timestamp)
          firstRev = moment(d.reviews[0]?.timestamp or d.ship_it.timestamp)
          console.log 'diffing', created.format(), firstRev.format()
          Math.max Math.abs(firstRev.diff created, 'hours'), 1
        )

        $log.debug 'ttRev', ttRev
        $log.debug 'withRev', withRev

        {average, median} = getStats(ttRev)
        $scope.steps.timeToRev = _.zip ttRev, withRev
        $scope.avg.timeToRev = average
        $scope.median.timeToRev = median
        {max, min} = statsService.calculateExtremes(withRev, ttRev)
        $scope.avg.worst.timeToRev = max
        $scope.avg.best.timeToRev = min

        withRev = (d for d in data when d.reviews.length > 0 and d.ship_it?)
        diffRevToShipit = (for d in withRev
          firstRev = moment(d.reviews[0].timestamp)
          shipit = moment(d.ship_it.timestamp)
          Math.max Math.abs(shipit.diff firstRev, 'hours'), 1
        )

        $log.debug 'diffRevToShipit', diffRevToShipit
        $log.debug 'withRev', withRev

        {average, median} = getStats(diffRevToShipit)
        $scope.steps.revToShipit = _.zip diffRevToShipit, withRev
        $scope.avg.revToShipit = average
        $scope.median.revToShipit = median
        {max, min} = statsService.calculateExtremes(withRev, diffRevToShipit)
        $scope.avg.worst.revToShipit = max
        $scope.avg.best.revToShipit = min


        submitted = (d for d in data when d.ship_it? and d.submitted?)
        shipitToSubmit = (for d in submitted
          shipit = moment(d.ship_it.timestamp)
          submit = moment(d.submitted.timestamp)
          Math.max Math.abs(submit.diff shipit, 'hours'), 1
        )

        $log.debug 'shipitToSubmit', shipitToSubmit
        $log.debug 'withRev', submitted

        {average, median} = getStats(shipitToSubmit)
        $scope.steps.shipToSubmit = _.zip shipitToSubmit, submitted
        $scope.avg.shipToSubmit = average or 0
        $scope.median.shipToSubmit = median or 0
        {max, min} = statsService.calculateExtremes(submitted, shipitToSubmit)
        $scope.avg.worst.shipToSubmit = max
        $scope.avg.best.shipToSubmit = min

      .then ->
        fields = ['timeToRev', 'revToShipit', 'shipToSubmit']
        labels = _.object fields, [
          'created to 1st review (or ship it)',
          '1st review to ship it',
          'ship it to submit'
        ]

        $scope.avgData = (for v in fields
          {key: v, y: $scope.avg[v]})
        $scope.medianData = (for v in fields
          {key: v, y: $scope.median[v]})

        $scope.xFunction = -> (d) -> d.key
        $scope.yFunction = -> (d) -> d.y

        colorArray = [
          '#F7464A', '#E2EAE9', '#D4CCC5', '#FF6666',
          '#FF3333', '#FF6666', '#FFE6E6'
        ]
        $scope.colorFunction = -> (d, i) -> colorArray[i]

        $scope.toolTipContentFunction = -> (key, x, y, e, graph) ->
          "#{labels[key]}: #{y.value} h"

      .then ->
        $scope.$apply()


.controller 'stepDetailsCtrl', ($scope) ->
  $scope.fields = ['timeToRev', 'revToShipit', 'shipToSubmit']
  $scope.labels = _.object $scope.fields, [
    'created to 1st review (or ship it)',
    '1st review to ship it',
    'ship it to submit'
  ]

.controller 'StepDetailsCtrl', ($scope) ->
  $scope.isCollapsed = true
