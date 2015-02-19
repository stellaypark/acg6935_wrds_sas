<!doctype html>
<html ng-app>
<head>
	<title>ACG6935 - Example SAS code generation</title>
	<script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.2.0/angular.min.js"></script>
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap-theme.min.css">
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>    
	<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
	<script src="js/controller.js"></script>
	<!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
      <![endif]-->
  </head>
  <body>
  	<nav class="navbar navbar-default navbar-static-top">
  		<div class="container">
 			<a class="navbar-brand" href="#">ACG6935</a>
  			<div id="navbar" class="navbar-collapse collapse">
  				<ul class="nav navbar-nav">
  					<li class="active"><a href="#">Home</a></li>
  				</ul>
   			</div><!--/.nav-collapse -->
  		</div>
  	</nav>
  	<div class="container" ng-controller="MyCtrl">
  		<div class="jumbotron">
  			<h1>Generate some SAS</h1>
  			<p style="margin-top:40px">Fill out the form to get some SAS code.</p>
			<hr/>  			
  			<form class="form-horizontal" id="TheForm" method="post" action="form.php" target="TheWindow">
  				<h4>Fundamental Annual</h4>
  				<div class="form-group">
  					<label for="input1" class="col-sm-2 control-label">Variables</label>
  					<div class="col-sm-6">
  						<input ng-model="input.funda" class="form-control" id="input1" placeholder="Variables Fundamental Annual">
  					</div>
  				</div>
  				<div class="form-group">
  					<label for="input1" class="col-sm-2 control-label">Start year</label>
  					<div class="col-sm-6">
  						<input ng-model="input.year1" class="form-control" id="input1" placeholder="Starting fiscal year">
  					</div>
  				</div>
  				<div class="form-group">
  					<label for="input1" class="col-sm-2 control-label">End year</label>
  					<div class="col-sm-6">
  						<input ng-model="input.year2" class="form-control" id="input1" placeholder="Ending fiscal year">
  					</div>
  				</div>  				
  				<h4>Fundamental Quarterly</h4>
  				<div class="form-group">
  					<label for="input2" class="col-sm-2 control-label">Variables</label>
  					<div class="col-sm-6">
  						<input ng-model="input.fundq"  class="form-control" id="input2" placeholder="Variables Fundamental Quarterly">
  					</div>
  				</div>
  				<h4 >Firm identifiers</h4>
  				<div class="form-group">
  					<div class="col-sm-offset-2 col-sm-6">
  						<div class="checkbox">
  							<label>
  								<input type="checkbox" ng-model="input.permno"> PERMNO
  							</label>
  						</div>
  					</div>
  					<div class="col-sm-offset-2 col-sm-6">
  						<div class="checkbox">
  							<label>
  								<input type="checkbox" ng-model="input.cusip"> CUSIP
  							</label>
  						</div>
  					</div>
  					<div class="col-sm-offset-2 col-sm-6">
  						<div class="checkbox">
  							<label>
  								<input type="checkbox" ng-model="input.ibesticker"> IBES Ticker
  							</label>
  						</div>
  					</div>
  				</div>	
  				<h4 >General</h4>
  				<div class="form-group">
  					<div class="col-sm-offset-2 col-sm-6">
  						<div class="checkbox">
  							<label>
  								<input type="checkbox" ng-model="input.rsubmit"> Wrap code in RSUBMIT code block
  							</label>
  						</div>
  					</div>
  				</div>
  				<h4>Output dataset</h4>
  				<div class="form-group">
  					<label for="input2" class="col-sm-2 control-label">Dataset name</label>
  					<div class="col-sm-6">
  						<input ng-model="input.dsout"  class="form-control" id="input2" placeholder="Name of dataset to create (e.g. work.a_funda)">
  					</div>
  				</div>
  				<div class="form-group">
  					<div class="col-sm-offset-2 col-sm-6">
  						<button type="submit" ng-click="doSubmit()" class="btn btn-lg btn-primary">Generate &raquo;</button>
  					</div>
  				</div>  				
  			</form>	
  		</div>
  	</div> <!-- /container -->
    
    <script src="js/ie10.hack.js"></script>
</body>
</html>