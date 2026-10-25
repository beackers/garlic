using Toybox.Application as App;
using Toybox.WatchUi as WatchUi;

module Garlic {
    class GarlicApp extends App.AppBase {
        function initialize() {
            AppBase.initialize();
        }

        function getInitialView() {
            var view = new CalculatorView();
            return [view, new CalculatorDelegate(view)];
        }
    }
}