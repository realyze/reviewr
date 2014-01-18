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
      sample = _.shuffle(data.review_requests)[0..10]

      getAverageTimes(sample)
      .then (data) ->
        for r, i in sample
          data[i].created or= timestamp: moment(r.time_added)
        data


      .then (data) ->
        calcStep = (f1, f2, f3) ->
        createdToShipited = (for d in data when d.ship_it?
          created = moment(d.created.timestamp)
          ship_ited = moment(d.ship_it.timestamp)
          ship_ited.diff created, 'hours'
        )

        sum = _.reduce(createdToShipited, ((m,n)->m+n), 0)
        average = sum / createdToShipited.length

        $scope.avg.timeToShipIt =average

      .then ->
        $scope.$apply()


