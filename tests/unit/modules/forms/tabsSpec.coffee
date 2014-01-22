describe "module: angleGrinder.forms tabs", ->

  beforeEach module "angleGrinder.forms"

  describe "directive: agTabset", ->

    $scope = null
    isolateScope = null
    element = null

    beforeEach inject ($injector) ->
      {element, $scope} = compileTemplate """
        <ag-tabset></ag-tabset>
      """, $injector

      isolateScope = element.isolateScope()

    it "renders tabs container", ->
      expect(element.hasClass("container")).to.be.true
      expect(element.find(".nav.nav-tabs")).to.have.length 1
      expect(element.find(".container")).to.have.length 1

    describe "$scope", ->

      it "by default it has no tabs", ->
        expect(isolateScope.tabs).to.be.instanceof Array
        expect(isolateScope.tabs).to.be.empty

    describe "controller", ->
      ctrl = null
      beforeEach -> ctrl = element.controller("agTabset")

      it "is defined", ->
        expect(ctrl).to.not.be.undefined

      describe "#addTab", ->
        newTab = null
        beforeEach inject ($rootScope) ->
          newTab = $rootScope.$new()

        it "add a new tab to the stack", ->
          ctrl.addTab(newTab)
          expect(isolateScope.tabs.length).to.eq 1
          expect(_.last(isolateScope.tabs)).to.eq

        context "when the tab stack is empty", ->

          it "selects the first tab", ->
            spy = sinon.spy(ctrl, "selectTab")
            ctrl.addTab(newTab)
            expect(spy.calledWith(newTab)).to.be.true
            expect(isolateScope.tabs[0].selected).to.be.true

        context "when the tab stack is not empty", ->
          beforeEach inject ($rootScope) ->
            ctrl.addTab($rootScope.$new())

          it "does not select the new tab", ->
            spy = sinon.spy(ctrl, "selectTab")
            ctrl.addTab(newTab)
            expect(spy.called).to.be.false

      describe "#selectTab", ->
        tabOne = null
        tabTwo = null

        beforeEach inject ($rootScope) ->
          tabOne = $rootScope.$new()
          ctrl.addTab(tabOne)
          tabTwo = $rootScope.$new()
          ctrl.addTab(tabTwo)

        it "marks the tab as selected", ->
          ctrl.selectTab(tabOne)

          expect(tabOne.selected).to.be.true
          expect(tabTwo.selected).to.be.false

  describe "directive: agTab", ->
    $scope = null
    element = null

    findTabByTitle = (title) ->
      for tab in element.find(".nav.nav-tabs li")
        return $(tab) if $(tab).find("a").text() is title

    describe "basics", ->

      # mock templates for the tab panel
      beforeEach inject ($httpBackend) ->
        $httpBackend.whenGET("/tabs/first").respond "First"

      beforeEach inject ($httpBackend, $injector) ->
        {element, $scope} = compileTemplate """
          <ag-tabset>
            <ag-tab template-url="/tabs/first">First</ag-tab>
            <ag-tab template-url="/tabs/second">Second</ag-tab>
            <ag-tab template-url="/tabs/third">Third</ag-tab>
          </ag-tabset>
        """, $injector

        $httpBackend.flush()

      it "renders the tabs", ->
        firstTab = findTabByTitle("First")
        expect(firstTab.isolateScope().selected).to.be.true
        expect(firstTab.hasClass("active")).to.be.true

        secondTab = findTabByTitle("Second")
        expect(secondTab.isolateScope().selected).to.be.false
        expect(secondTab.hasClass("active")).to.be.false

      it "creates clickable titles", ->
        titles = element.find(".nav.nav-tabs li")
        expect(titles).to.have.length(3)

        expect(titles.find("a").eq(0).text()).to.eq "First"
        expect(titles.find("a").eq(1).text()).to.eq "Second"
        expect(titles.find("a").eq(2).text()).to.eq "Third"

      it "by default displays the first tab content", ->
        expect(element.find(".tab.container").text()).to.eq "First"

      describe "on click on the nav tab", ->
        tab = null

        beforeEach inject ($httpBackend) ->
          $httpBackend.whenGET("/tabs/second").respond "Second"

          tab = findTabByTitle("Second")
          tab.find("a").click()

          $httpBackend.flush()

        it "changes the active tab", ->
          expect(tab.isolateScope().selected).to.be.true
          expect(tab.hasClass("active")).to.be.true

        it "loads the content for the activated tab", ->
          expect(element.find(".tab.container").text()).to.eq "Second"

    describe "with initial active tab", ->

      beforeEach inject ($httpBackend, $injector) ->
        $httpBackend.whenGET("/tabs/second").respond "Second"

        {element, $scope} = compileTemplate """
          <ag-tabset>
            <ag-tab template-url="/tabs/first">First</ag-tab>
            <ag-tab active="true" template-url="/tabs/second">Second</ag-tab>
            <ag-tab template-url="/tabs/third">Third</ag-tab>
          </ag-tabset>
        """, $injector

        $httpBackend.flush()

      it "sets the tab as active", ->
        tab = findTabByTitle("Second")
        expect(tab.isolateScope().selected).to.be.true
        expect(tab.hasClass("active")).to.be.true

      it "loads the content for the activated tab", ->
        expect(element.find(".tab.container").text()).to.eq "Second"
