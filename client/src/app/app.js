angular.module( 'reviewr', [
  'templates-app',
  'templates-common',
  'reviewr.dashboard',
  'ui.router',
  'ui.route',

  'ui.bootstrap',

  'nvd3ChartDirectives'
])

.config( function myAppConfig ( $stateProvider, $urlRouterProvider ) {
  $urlRouterProvider.otherwise( '/stats/' );
})

.run( function run () {
})

.controller( 'AppCtrl', function AppCtrl ( $scope, $location ) {
  $scope.$on('$stateChangeSuccess', function(event, toState, toParams, fromState, fromParams){
    if ( angular.isDefined( toState.data.pageTitle ) ) {
      $scope.pageTitle = toState.data.pageTitle + ' | reviewr' ;
    }
  });
})

;

