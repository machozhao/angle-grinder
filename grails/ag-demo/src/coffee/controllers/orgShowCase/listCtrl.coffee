class ListCtrl

  @$inject = ["$scope", "$log", "Resource", "$filter", "dialogCrudCtrlMixin"]
  constructor: ($scope, $log, Resource, @$filter, dialogCrudCtrlMixin) ->

    $scope.gridOptions =
      path: "/orgShowCase/list?format=json"
      colModel: @colModel()
      multiselect: false # turn off multiselect
      shrinkToFit: true # makes columns fit to width
      sortname: "name"
      sortorder: "asc"

    $scope.tzShowCase = angular.copy(Resource)

    $scope.filters = {}

    dialogCrudCtrlMixin $scope,
      Resource: Resource
      gridName: "orgShowCaseGrid"
      templateUrl: "/orgShowCase/formTemplate"
      beforeEdit: (record) ->
        # saves data from server to compare retrieved data and data that will be send to the server
        $scope.tzShowCase = angular.copy(record)
        orgShowCase = angular.copy(record)
        # convert `Contact.type` enum field to the string
        orgShowCase

  colModel: ->
    [
      { name: "id", label: "ID", width: 30, fixed: true }
      { name: "name", label: "Name", width: 100, fixed: true, formatter: "editActionLink" }
      { name: "exampleDate", label: "Example Date", width: 70, formatter: (cellVal) => @$filter("date")(cellVal) }
      { name: "exampleDateTime", label: "Example Date Time", width: 70, formatter: (cellVal) => @$filter("date")(cellVal) }
      { name: "exampleLocalDate", label: "Example Local Date", width: 70, formatter: (cellVal) => @$filter("date")(cellVal) }
    ]

angular.module("angleGrinder").controller("orgShowCase.ListCtrl", ListCtrl)
