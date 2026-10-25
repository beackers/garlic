using Toybox.WatchUi as WatchUi;

module Garlic {
    class CalculatorDelegate extends WatchUi.BehaviorDelegate {
        var view;

        function initialize(view) {
            BehaviorDelegate.initialize();
            self.view = view;
        }

        function onSwipe(evt) {
            view.handleSwipe(evt.getDirection());
            return true;
        }

        function onTap(evt) {
            var point = evt.getCoordinates();
            view.handleTap(point[0], point[1]);
            return true;
        }

        function onSelect() {
            view.handleStart();
            return true;
        }

        function onBack() {
            view.handleBack();
            return true;
        }

        function onKey(evt) {
            var key = evt.getKey();

            if (key == WatchUi.KEY_START || key == WatchUi.KEY_ENTER) {
                view.handleStart();
                return true;
            }

            if (key == WatchUi.KEY_ESC) {
                view.handleBack();
                return true;
            }

            if (key == WatchUi.KEY_LEFT) {
                view.navigation.swipeLeft();
                view.loadKeyboardLayout();
                view.refreshText();
                return true;
            }

            if (key == WatchUi.KEY_RIGHT) {
                view.navigation.swipeRight();
                view.loadKeyboardLayout();
                view.refreshText();
                return true;
            }

            if (key == WatchUi.KEY_UP) {
                view.navigation.swipeUp();
                view.refreshText();
                return true;
            }

            if (key == WatchUi.KEY_DOWN) {
                view.navigation.swipeDown();
                view.newExpression();
                return true;
            }

            return false;
        }
    }
}