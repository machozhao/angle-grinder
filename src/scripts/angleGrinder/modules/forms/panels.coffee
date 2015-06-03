forms = angular.module("angleGrinder.forms")

forms.value "getRealPanelHeight", (el) ->
  bodyEl = el.find(".panel-body:visible")
  oldHeight = bodyEl.height()

  bodyEl.css("min-height", "auto")
  height = el.height()
  # Do not equalize if element collapsed
  if angular.element(bodyEl).attr("collapsed")
    bodyEl.css("min-height", 0)
  else
    bodyEl.css("min-height", oldHeight)

  # Remove padding between grid header and body
  if el.find("[ag-grid]").length > 0
    el.find(".panel-heading").css("padding-bottom", "0px")
    bodyEl.css("padding-top", "0px")

  return height

forms.directive "agPanelsRow", [
  "getRealPanelHeight", (getHeight) ->
    restrict: "C"
    controller: ->
      @panels = []

      @registerPanel = (el) ->
        @panels.push($(el))

      @maxHeight = ->
        highest = _.max(@panels, (el) -> getHeight(el))
        getHeight(highest)

      # returns true when all panels are equalized
      @allEqual = ->
        heights = _.chain(@panels).map((el) -> getHeight(el)).value()
        _.all(heights, (height) -> height is heights[0])

      @equalize = ->
        return if @allEqual()

        maxHeight = @maxHeight()

        angular.forEach @panels, (el) ->
          bodyEl = el.find(".panel-body")

          # default padding
          paddings = parseInt(bodyEl.css("padding-top")) + parseInt(bodyEl.css("padding-bottom"))

          # add heading and footer
          paddings += el.find(".panel-heading").outerHeight()
          paddings += el.find(".panel-footer").outerHeight()

          bodyEl.css("min-height", maxHeight - paddings)

      return this
]

forms.directive "agPanel", [
  "getRealPanelHeight", (getHeight) ->
    restrict: "C"
    require: "^agPanelsRow"

    link: (scope, element, attrs, ctrl) ->

      # add the current panel to the stack
      ctrl.registerPanel(element)

      elementHeight = -> getHeight(element)
      scope.$watch elementHeight, -> ctrl.equalize()
]

#
# To mark element(s) in panel that needs to be displayed when panel collapsing
# just add 'stay-on-collapse' attribute. Example:
#
# <form>
#   <div stay-on-collapse>...</div> <!-- this 'div' will be displayed when panel collapsed top -->
#   <div>...</div>
# </form>
#
forms.directive "agPanelStates",  [
  "$compile", ($compile) ->
    restrict: "C"

    controller: [
      "$scope", ($scope) ->

        $scope.normalState = (event) ->
          if $scope.state is "collapsed"
            $scope.state = "normal"
            element = getAgPanel event
            if isGrid element then collapseGrid element else collapseForm element
          true

        $scope.collapsedState = (event) ->
          if not $scope.state? or $scope.state is "normal"
            $scope.state = "collapsed"
            element = getAgPanel event
            if isGrid element then collapseGrid element else collapseForm element
          true

        $scope.fullscreenState = (event) ->
          panelModal = "<panel-modal></panel-modal>"
          angular.element(getAgPanel event).wrap(panelModal)
          $compile(panelModal)($scope)
          true

        # Gets the closest ag-panel
        getAgPanel = (event) ->
          angular.element(event.target).closest(".ag-panel")

        # Finds out if element is a grid
        isGrid = (element) ->
          angular.element(element).find("table.gridz").length > 0

        # Method for collapsing a grid
        collapseGrid = (element) ->
          gridEl = angular.element(element).find("table.gridz")
          if $scope.state is "collapsed"
            for row in angular.element(gridEl).find("tbody").children()
              if not angular.element(row).hasClass("ui-state-highlight") and not angular.element(row).hasClass("jqgfirstrow")
                angular.element(row).addClass("ng-hide")
            angular.element(element).find(".gridz-pager").addClass("ng-hide")
          if $scope.state is "normal"
            for row in angular.element(gridEl).find("tbody").children()
              if angular.element(row).hasClass("ng-hide")
                angular.element(row).removeClass("ng-hide")
            angular.element(element).find(".gridz-pager").removeClass("ng-hide")
          return

        # Method for collapsing form
        collapseForm = (element) ->
          panelBody = angular.element(element).find(".panel-body")
          if $scope.state is "collapsed"
            clone = angular.element(panelBody).clone()
            angular.element(panelBody).addClass("ng-hide")
            angular.element(panelBody).after(clone)
            removeElements clone
            if angular.element(clone).children().length is 0 then angular.element(clone).remove()
            angular.element(clone).attr("collapsed", "true")
          if $scope.state is "normal"
            for el in panelBody
              if angular.element(el).hasClass "ng-hide" then angular.element(el).removeClass("ng-hide")
              else angular.element(el).remove()
          return

        # Goes through the DOM element and hides all nodes without 'stay-on-collapse' attribute
        # Saves origin element structure
        removeElements = (panelBody) ->
          children = angular.element(panelBody).children()
          hasElementToStay = false
          for child in children
            if angular.element(child).is("[stay-on-collapse]")
              hasElementToStay = true
            else if angular.element(child).children().length > 0
              if not removeElements child then angular.element(child).remove() else hasElementToStay = true
            else
              angular.element(child).remove()
          hasElementToStay

    ]

    link: (scope, element, attrs, ctrl, $transcludeFn) ->
      stateButtons = angular.element($compile("""
        <span name="agPanelStates" class="pull-left" style="margin-right: 5px">
          <span name="normal" ng-click="normalState($event)" tooltip="Normal state"><i class="icon-chevron-down"></i></span>
          <span name="collapsed" ng-click="collapsedState($event)" tooltip="Collapsed state"><i class="icon-chevron-up"></i></span>
          <span name="fullscreen" ng-click="fullscreenState($event)" tooltip="Fullscreen state"><i class="icon-resize-full"></i></span>
        </span>
      """)(scope))
      element.prepend(stateButtons)

]

# Directive for opening modal window
forms.directive "panelModal", [
  "$compile", "$modal", "$document", ($compile, $modal, $document) ->
    restrict: "E"
    template: """
      <div id="modal-fullscreen" class="modal">
          <div class="modal-header">
              <button type="button" class="close" ng-click="close()">×</button>
          </div>
          <div class="modal-body"></div>
      </div>
    """
    controller: [
      "$scope", ($scope) ->

        $scope.open = ->
          $scope.showModal = true

        $scope.close = ->
          $scope.showModal = false

        # Close modal window (if it is open) when back button clicked
        $scope.$on "$locationChangeStart", (event) ->
          if $scope.showModal
            event.preventDefault()
            $scope.close()

        # Trigger for grid resizing
        $scope.shrinkGridIfExists = (element) ->
          gridEl = angular.element(element).find("table.gridz")
          if angular.element(gridEl).length > 0 then gridEl.jqGrid().trigger("resize")

    ]

    link: (scope, element) ->
      scope.open()

      scope.$watch(
        ->
          scope.showModal
        (newVal) ->
          if newVal and element.scope()
            modalEl = angular.element($document).find('panel-modal')
            angular.element(modalEl).find('[name="agPanelStates"]').addClass("ng-hide")
            element.insertBefore(modalEl)
            modalBody = element.find(".modal-body").append(angular.element(modalEl).children())
            angular.element(modalEl).remove()
            scope.shrinkGridIfExists modalBody
          else if not newVal and element.scope()
            element.find('[name="agPanelStates"]').removeClass("ng-hide")
            modalBody = element.find(".modal-body").children().insertBefore(element)
            scope.shrinkGridIfExists modalBody
            element.remove()
      )

]
