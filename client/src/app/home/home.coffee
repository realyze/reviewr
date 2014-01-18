angular.module("ngBoilerplate.home", [
  'ui.router'
])
  
  
.config ($stateProvider) ->
  $stateProvider.state "userStats",
    url: "/stats/:user"
    views:
      main:
        controller: "UserStatsCtrl"
        templateUrl: "home/home.tpl.html"

    data:
      pageTitle: "User Stats"


.controller "UserStatsCtrl", ($scope, $http, $log, $stateParams) ->
  $log.debug 'home ctrl'
  $scope.data = 'waiting'


  orderStatsByYearAndMonth = (data, field) ->
    byYear = _.groupBy data.review_requests, (req) ->
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
    console.log 'getting review for', rid
    dfr = Q.defer()
    $http.get("api/review/#{rid}")
    
    .success (data) ->
      dfr.resolve data

    .error (err) ->
      dfr.reject err

    return dfr.promise


  getAverageTimes = (data) ->
    Q.all((getReview(review.id) for review in data))


  $http.get("api/stats/#{$stateParams.user}")
    .success (data) ->

      $scope.data = orderStatsByYearAndMonth(data, 'time_added')
      console.log 'data', $scope.data

      graphData =
        labels : [
          "January","February","March",
          "April","May","June",
          "July", "August", "September",
          "October", "November", "December"
        ],
        datasets : [
          fillColor : "rgba(220,220,220,0.5)",
          strokeColor : "rgba(220,220,220,1)",
          data : (r.length for m, r of $scope.data['2013'])
        ]
      $scope.graphData = graphData
      console.log graphData

      ctx = angular.element("#myChart").get(0).getContext("2d")
      new Chart(ctx).Bar(graphData, {
        scaleOverride: true
        scaleSteps: 8
        scaleStepWidth: 5
        scaleStartValue: 0
      })

      $scope.avg = {}
      $scope.median = {}

      sample = _.shuffle(data.review_requests)[0..30]

      getStats = (list) ->
        average = _.reduce(list, ((m,n)->m+n), 0) / list.length
        median = (_.sortBy list, (val) -> val)[Math.floor(list.length/2)]
        return {
          average: average
          median: median
        }

      getAverageTimes(sample)

      .then (data) ->
        for r, i in sample
          data[i].created or= timestamp: moment(r.time_added)
        data

      .then (data) ->
        withRev = (d for d in data when d.reviews.length > 0 or d.ship_it?)
        ttRev = (for d in withRev
          created = moment(d.created.timestamp)
          firstRev = moment(d.reviews[0]?.timestamp or d.ship_it.timestamp)
          Math.abs firstRev.diff created, 'hours'
        )

        {average, median} = getStats(ttRev)
        $scope.avg.timeToRev = average
        $scope.median.timeToRev = median


        withRev = (d for d in data when d.reviews.length > 0 and d.ship_it?)
        diffRevToShipit = (for d in withRev
          firstRev = moment(d.reviews[0].timestamp)
          shipit = moment(d.ship_it.timestamp)
          Math.abs shipit.diff firstRev, 'hours'
        )

        {average, median} = getStats(diffRevToShipit)
        $scope.avg.revToShipit = average
        $scope.median.revToShipit = median


        submitted = (d for d in data when d.ship_it? and d.submitted?)
        shipitToSubmit = (for d in submitted
          shipit = moment(d.ship_it.timestamp)
          submit = moment(d.submitted.timestamp)
          Math.abs submit.diff shipit, 'hours'
        )

        {average, median} = getStats(shipitToSubmit)
        $scope.avg.shipToSubmit = average
        $scope.median.shipToSubmit = median

        console.log 'graph data ready'

      .then ->
        console.log 'doughnut graphs'
        fields = ['timeToRev', 'revToShipit', 'shipToSubmit']
        colors = ['#F7464A', '#E2EAE9', '#D4CCC5']

        $scope.avgData = (for [v,c] in _.zip(fields, colors)
          {key: v, y: $scope.avg[v]})

        $scope.xFunction = -> (d) -> d.key
        $scope.yFunction = -> (d) -> d.y

        colorArray = [
          '#F7464A', '#E2EAE9', '#D4CCC5', '#FF6666',
          '#FF3333', '#FF6666', '#FFE6E6'
        ]
        $scope.colorFunction = -> (d, i) -> colorArray[i]

        $scope.toolTipContentFunction = -> (key, x, y, e, graph) ->
          "#{key}: #{y}"

        console.log 'dougnnut', data


      .then ->
        $scope.$apply()


