/* --- Made by justgoscha and licensed under MIT license --- */

var app = angular.module('autocomplete', []);

app.directive('autocomplete', function(){
  var index = -1;

  return {
    restrict: 'E',
    scope: {
      suggestions: '=data',
      onType: '=onType',
      onSelect: '=onSelect',
      onSubmit: '=onSubmit',
      initial: '=initial'
    },
    controller: function($scope, $element, $attrs){

      $scope.searchParam;

      // with the searchFilter the suggestions get filtered
      $scope.searchFilter;

      // the index of the suggestions that's currently selected
      $scope.selectedIndex = -1;

      // set new index
      $scope.setIndex = function(i){
        $scope.selectedIndex = parseInt(i);
      }

      this.setIndex = function(i){
        $scope.setIndex(i);
        $scope.$apply();
      }

      $scope.getIndex = function(i){
        return $scope.selectedIndex;
      }

      // watches if the parameter filter should be changed
      var watching = true;

      // autocompleting drop down on/off
      $scope.completing = false;

      // starts autocompleting on typing in something
      $scope.$watch('searchParam', function(){
        if(watching && $scope.searchParam) {
          $scope.completing = true;
          $scope.searchFilter = $scope.searchParam;
          $scope.selectedIndex = -1;
        }

        // function thats passed to on-type attribute gets executed
        if ($scope.onType)
          $scope.onType($scope.searchParam);
      });

      // for hovering over suggestions
      this.preSelect = function(suggestion){

        watching = false;

        // this line determines if it is shown 
        // in the input field before it's selected:
        //$scope.searchParam = suggestion;

        $scope.$apply();
        watching = true;

      }

      $scope.preSelect = this.preSelect;

      this.preSelectOff = function(){
        watching = true;
      }

      $scope.preSelectOff = this.preSelectOff;

      // selecting a suggestion with RIGHT ARROW or ENTER
      $scope.select = function(suggestion){
        if(suggestion){
          $scope.searchParam = suggestion.spelling;
          $scope.searchFilter = suggestion.spelling;
          $scope.onSelect(suggestion);
        }
        watching = false;
        $scope.completing = false;
        setTimeout(function(){watching = true;},1000);
        $scope.setIndex(-1);
      }

      // submitting text with RIGHT ARROW or ENTER
      $scope.submit = function() {
        $scope.onSubmit($scope.searchParam);
        watching = false;
        $scope.completing = false;
        setTimeout(function(){watching = true;},1000);
        $scope.setIndex(-1);
        document.activeElement.blur();
      }

      $scope.searchParam = $scope.initial;
      $scope.onType($scope.searchParam);
      $scope.submit();

    },
    link: function(scope, element, attrs){


      scope.placeholder=attrs["placeholder"];
      if(scope.placeholder===null||scope.placeholder===undefined)
        scope.placeholder = "start typing..."
      if(attrs["clickActivation"]=="true"){
        element[0].onclick = function(e){
          if(!scope.searchParam){
            scope.completing = true;
            scope.$apply();
          }
        };
      }

      var key = {left: 37, up: 38, right: 39, down: 40 , enter: 13, esc: 27, tab: 9};

      document.addEventListener("keydown", function(e){
        var keycode = e.keyCode || e.which;

        switch (keycode){
          case key.esc:
            // disable suggestions on escape
            scope.select();
            scope.setIndex(-1);
            scope.$apply();
            e.preventDefault();
        }
      }, true);

      element[0].onkeydown = function (e){
        var keycode = e.keyCode || e.which;

        var l = angular.element(this).find('li').length;

        // implementation of the up and down movement in the list of suggestions
        switch (keycode){
          case key.up:    
 
            index = scope.getIndex()-1;
            if(index<-1){
              index = l-1;
            } else if (index >= l ){
              index = -1;
              scope.setIndex(index);
              scope.preSelectOff();
              break;
            }
            scope.setIndex(index);

            if(index!==-1) {
              scope.preSelect(scope.suggestions[index]);
            }
              
            scope.$apply();

            break;
          case key.down:
            index = scope.getIndex()+1;
            if(index<-1){
              index = l-1;
            } else if (index >= l ){
              index = -1;
              scope.setIndex(index);
              scope.preSelectOff();
              scope.$apply();
              break;
            }
            scope.setIndex(index);
            
            if (index!==-1) {
              scope.preSelect(scope.suggestions[index]);
            } 

            break;
          case key.left:    
            break;
          case key.right: 
          case key.tab:  
          case key.enter:  

            index = scope.getIndex();
            // scope.preSelectOff();
            if (index!==-1) {
              scope.select(scope.suggestions[index]);
            } else {
              scope.submit();
            }
            
            scope.setIndex(-1);     
            scope.$apply();

            break;
          case key.esc:
            // disable suggestions on escape
            scope.select();
            scope.setIndex(-1);
            scope.$apply();
            e.preventDefault();
            break;
          default:
            return;
        }

        if(scope.getIndex()!==-1 || keycode == key.enter)
          e.preventDefault();
      };
    },
    template: '<div class="autocomplete">'+
                '<input type="text" ng-model="searchParam" placeholder="{{placeholder}}" />' +
                '<ul ng-show="completing">' +
                  '<li suggestion ng-repeat="suggestion in suggestions | filter:{spelling:searchFilter} | orderBy:\'toString()\'" '+
                  'index="{{$index}}" ng-class="{active: '+
                  '($index == selectedIndex)}" ng-click="select(suggestion)">'+
                    '{{suggestion.spelling}} ({{suggestion.pronunciation}})'+
                  '</li>'+
                '</ul>'+
              '</div>'
    // templateUrl: 'script/ac_template.html'
  }
});

app.directive('suggestion', function(){
  return {
    restrict: 'A',
    require: '^autocomplete', // ^look for controller on parents element
    link: function(scope, element, attrs, autoCtrl){
      element.bind('mouseenter', function() {
        autoCtrl.preSelect(attrs['val']);
        autoCtrl.setIndex(attrs['index']);
      });

      element.bind('mouseleave', function() {
        autoCtrl.preSelectOff();
      });
    }
  }
});
