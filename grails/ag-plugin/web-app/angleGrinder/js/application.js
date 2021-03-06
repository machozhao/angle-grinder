// The main scaffolding module
var app = angular.module("angleGrinder", [
    "ngResource",
    "ngRoute",
    "ui.select2",

    "angleGrinder.common",
    "angleGrinder.gridz",
    "angleGrinder.forms",
    "angleGrinder.alerts",
    "angleGrinder.spinner",
    "angleGrinder.resources"
]);

app.config([
  "$httpProvider", "pathWithContextProvider", function($httpProvider, pathWithContextProvider) {

    // Intercept all http errors
    $httpProvider.interceptors.push("httpErrorsInterceptor");

    // Configure the context path
    var contextPath = $("body").data("context-path");
    if (contextPath != null) {
      pathWithContextProvider.setContextPath(contextPath);
    }
  }
]);

// Intercepts all HTTP errors and displays a flash message
app.factory("httpErrorsInterceptor", [
  "$injector", "$q", "alerts", function($injector, $q, alerts) {
    return {
      response: function(response) {
        return response;
      },
      responseError: function(response) {
          var errorMessage, _ref;
          var genericErrorMessage = (response.statusText ? response.statusText : "Unexpected HTTP error") + " " + response.status + " : " + response.config.url
          errorMessage = ((_ref = response.data) != null ? _ref.error : void 0) ||  genericErrorMessage;

          // ..skip validation and auth errors
          if (response.status !== 422 && response.status !== 401) {
            alerts.error(errorMessage);

          return response;
        }
        return $q.reject(response);
      }
    };
  }
]);

// Catch all jquery xhr errors
app.run([
  "$log", "alerts", function($log, alerts) {
    return $(document).ajaxError(function(event, jqxhr, settings, exception) {
      $log.error("Network error:", event, jqxhr, settings, exception);
      return alerts.error(exception);
    });
  }
]);
