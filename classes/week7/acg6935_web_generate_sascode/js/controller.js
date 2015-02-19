var myApp = angular.module('myApp',[]);

function MyCtrl($scope) {
    
    $scope.input = {
    	funda : "gvkey fyear conm sich",
    	fundq : "atq saleq ceqq",
    	permno : true,
    	cusip : true,
    	ibesticker: false,
    	rsubmit: true,
    	dsout: "work.a_funda",
    	year1: 2010,
    	year2: 2013
    };
    $scope.doSubmit = function(){
    	var f = document.getElementById('TheForm');
		var obj = $scope.input;
		for (var prop in obj) {
      		if(obj.hasOwnProperty(prop)){
      			var hiddenField = document.createElement("input"); 
				hiddenField.setAttribute("type", "hidden");
				hiddenField.setAttribute("name", prop);
				hiddenField.setAttribute("value", obj[prop]);
				f.appendChild(hiddenField);
      		}
   		}
  		window.open('', 'TheWindow');
		f.submit();
    };
}