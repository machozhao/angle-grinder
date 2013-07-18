describe "module: angleGrinder.forms", ->
  beforeEach module("angleGrinder.templates")
  beforeEach module("angleGrinder.forms")

  describe "directive: match", ->
    element = null
    $scope = null
    form = null

    beforeEach inject ($rootScope, $compile) ->
      $scope = $rootScope.$new()
      element = angular.element """
        <form name="form">
          <input name="password" type="password"
                 ng-model="user.password" />
          <input name="passwordConfirmation" type="password"
                 ng-model="user.passwordConfirmation" match="user.password" />
        </form>
      """

      $compile(element)($scope)
      $scope.$digest()
      form = $scope.form

    describe "when the fields are equal", ->
      beforeEach ->
        form.password.$setViewValue "password"
        form.passwordConfirmation.$setViewValue "password"
        $scope.$digest()

      it "marks the form as valid", ->
        expect(form.$valid).toBeTruthy()
        expect(form.$invalid).toBeFalsy()

      it "does not set errors on the input", ->
        expect(form.passwordConfirmation.$valid).toBeTruthy()
        expect(form.passwordConfirmation.$invalid).toBeFalsy()

    describe "when the fields are not equal", ->
      beforeEach ->
        form.password.$setViewValue "password"
        form.passwordConfirmation.$setViewValue "other password"
        $scope.$digest()

      it "marks the form as invalid", ->
        expect(form.$valid).toBeFalsy()
        expect(form.$invalid).toBeTruthy()

      it "sets the valid form errors", ->
        expect(form.$error).toBeDefined()
        expect(form.$error.mismatch[0].$name).toEqual "passwordConfirmation"

      it "sets erorrs on the field", ->
        expect(form.passwordConfirmation.$valid).toBeFalsy()
        expect(form.passwordConfirmation.$invalid).toBeTruthy()
        expect(form.passwordConfirmation.$error.mismatch).toBeTruthy()

        $input = element.find("input[name=passwordConfirmation]")
        expect($input.hasClass("ng-invalid")).toBeTruthy()
        expect($input.hasClass("ng-invalid-mismatch")).toBeTruthy()

  describe "directive: fieldGroup", ->
    element = null
    $scope = null
    form = null

    beforeEach inject ($rootScope, $compile) ->
      $scope = $rootScope.$new()

      element = angular.element """
        <form name="form" novalidate>
          <div class="control-group"
               field-group for="email,password">
            <input type="text" name="email"
                   ng-model="user.email" required />
            <input type="password" name="password"
                   ng-model="user.password" required />
          </div>
        </form>
      """

      $compile(element)($scope)
      $scope.$digest()
      form = $scope.form

    describe "when one of the field is invalid", ->
      beforeEach ->
        form.email.$setViewValue "luke@rebel.com"
        form.password.$setViewValue ""
        $scope.$digest()

      it "marks the whole group as invalid", ->
        expect(form.$valid).toBeFalsy()
        $group = element.find(".control-group")
        expect($group).toHaveClass "error"

    describe "when all fields are valid", ->
      beforeEach ->
        form.email.$setViewValue "luke@rebel.com"
        form.password.$setViewValue "password"
        $scope.$digest()

      it "does not mark the group as invalid", ->
        expect(form.$valid).toBeTruthy()
        $group = element.find(".control-group")
        expect($group).not.toHaveClass "erro"

  describe "directive: validationMessage", ->
    element = null
    $scope = null
    form = null

    comlileTemplate = (template) ->
      beforeEach inject ($rootScope, $compile) ->
        $scope = $rootScope.$new()

        element = angular.element(template)

        $compile(element)($scope)
        $scope.$digest()
        form = $scope.form

    describe "when the validation message is provided", ->
      comlileTemplate """
        <form name="form" novalidate>
          <input type="password" name="password"
                 ng-model="user.password" required />
          <validation-error for="password"
                            required="Please fill this field" />
      """

      describe "when the field is invalid", ->
        beforeEach ->
          form.password.$setViewValue ""
          $scope.$digest()

        it "displays validation errors for the given field", ->
          expect(element.find("validation-error[for=password] span").text())
            .toEqual "Please fill this field"

      describe "when the field is valid", ->
        beforeEach ->
          form.password.$setViewValue "password"
          $scope.$digest()

        it "hides validation errors", ->
          expect(element.find("validation-error[for=password] span").text())
            .toEqual ""

    describe "when the validation messages is not provided", ->
      comlileTemplate """
        <form name="form" novalidate>
          <input type="password" name="password"
                 ng-model="user.password" required />
          <validation-error for="password" />
      """

      beforeEach ->
        form.password.$setViewValue ""
        $scope.$digest()

      it "uses the default validation message", ->
        expect(element.find("validation-error[for=password] span").text())
          .toEqual "This field is required"

  describe "service: validationMessages", ->
    it "is defined", inject (validationMessages) ->
      expect(validationMessages).toBeDefined()

    hasDefaultMessageFor = (key, message) ->
      it "has a default message for `#{key}` validation", inject (validationMessages) ->
        expect(validationMessages[key]).toEqual message

    hasDefaultMessageFor "required",  "This field is required"
    hasDefaultMessageFor "mismatch",  "Does not match the confirmation"
    hasDefaultMessageFor "minlength", "This field is too short"
    hasDefaultMessageFor "maxlength", "This field is too long"
    hasDefaultMessageFor "email",     "Invalid email address"

  describe "directive: deleteButton", ->
    element = null
    $rootScope = null
    $scope = null

    beforeEach inject (_$rootScope_, $compile) ->
      $rootScope = _$rootScope_
      $scope = $rootScope.$new()

      element = angular.element """
        <delete-button when-confirmed="delete(123)" deleting="deleting"></delete-button>
      """

      $compile(element)($scope)
      $rootScope.$digest()

    it "is visible", ->
      expect(element.css("display")).not.toBe "none"

    it "is not disabled", ->
      expect(element).not.toHaveClass "disabled"

    it "has a valid label", ->
      expect(element).toHaveText /Delete/

    describe "when the button is clicked", ->
      beforeEach -> element.click()

      it "displays the confirmation", ->
        expect(element).toHaveText(/Are you sure?/)

      it "changes button class", ->
        expect(element).toHaveClass "btn-warning"

    describe "when the button is double clicked", ->
      beforeEach ->
        element.click()
        $scope.delete = ->
        spyOn($scope, "delete")

      it "performs delete action", ->
        element.click()
        expect($scope.delete).toHaveBeenCalledWith(123)

    describe "when the DELETE request is in progress", ->
      beforeEach ->
        $scope.deleting = true
        $rootScope.$digest()

      it "disables the button", ->
        expect(element).toHaveClass "disabled"

      it "changes the button label", ->
        expect(element).toHaveText "Delete..."

  describe "directive: cancelButton", ->
    element = null
    $scope = null

    beforeEach inject ($rootScope, $compile) ->
      $scope = $rootScope.$new()

      element = angular.element """
        <cancel-button></cancel-button>
      """

      $compile(element)($scope)
      $scope.$digest()

    it "create a cancel button", ->
      expect(element).toHaveText "Cancel"
      expect(element).toHaveClass "btn"

  describe "directive: submitButton", ->
    element = null
    $scope = null

    beforeEach inject ($rootScope, $compile) ->
      $scope = $rootScope.$new()

      element = angular.element """
        <submit-button></submit-button>
      """

      $compile(element)($scope)
      $scope.$digest()

    it "has valid label", ->
      expect(element).toHaveText /Save/

    describe "when the form is valid", ->
      beforeEach ->
        $scope.editForm = $invalid: false
        $scope.$digest()

      it "is enabled", ->
        expect(element).not.toHaveClass "disabled"

    describe "when the request is in progress", ->
      beforeEach ->
        $scope.saving = true
        $scope.$digest()

      it "is disabled", ->
        expect(element).toHaveClass "disabled"

      it "changes the button label", ->
        expect(element).toHaveText "Save..."

    describe "when the form is invalid", ->
      beforeEach ->
        $scope.editForm = $invalid: true
        $scope.$digest()

      it "is disabled", ->
        expect(element).toHaveClass "disabled"

  describe "directive: serverValidationErrors", ->
    element = null
    $scope = null

    beforeEach inject ($rootScope, $compile) ->
      $scope = $rootScope.$new()

      element = angular.element """
        <server-validation-errors></server-validation-errors>
      """

      $compile(element)($scope)
      $scope.$digest()

    it "renders errors", ->
      $scope.serverValidationErrors =
        user:
          login: "should be unique"
          email: "is taken"
        contact:
          email: "is invalid"
      $scope.$digest()

      expect(element.find(".alert-error").length).toEqual 3

      $userErrors = element.find("[x-errors-for=user]")
      expect($userErrors.find(".alert-error:nth-child(1)")).toHaveText "is taken"
      expect($userErrors.find(".alert-error:nth-child(2)")).toHaveText "should be unique"

      $contactErrors = element.find("[x-errors-for=contact]")
      expect($contactErrors.find(".alert-error:nth-child(1)")).toHaveText "is invalid"

    describe "when no errors", ->
      it "renders nothing", ->
        expect(element.find(".alert-error").length).toEqual 0

  describe "service: confirmationDialog", ->
    it "displays the confirmation", inject ($dialog, confirmationDialog) ->
      spyOn($dialog, "dialog").andCallThrough()
      confirmationDialog.open()
      expect($dialog.dialog).toHaveBeenCalled()
