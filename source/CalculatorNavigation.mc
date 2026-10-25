module Garlic {
    // The calculator has one editor/workspace with orthogonal navigation:
    //   horizontal swipe = keyboard page
    //   vertical swipe   = expression/workspace navigation
    //   Start            = graph current workspace
    //   Back             = delete, then navigate back when the cursor is empty
    enum CalculatorScreen {
        SCREEN_EDITOR,
        SCREEN_EXPRESSIONS,
        GRAPH
    }

    class CalculatorNavigation {
        var screen;
        var keyboardPage;
        var expressionIndex;

        function initialize() {
            self.screen = EDITOR;
            self.keyboardPage = NUMBERS;
            self.expressionIndex = 0;
        }

        function swipeLeft() {
            if (screen != EDITOR) {
                return;
            }
            keyboardPage = KeyboardPages.previous(keyboardPage);
        }

        function swipeRight() {
            if (screen != EDITOR) {
                return;
            }
            keyboardPage = KeyboardPages.next(keyboardPage);
        }

        function swipeUp() {
            if (screen == EDITOR) {
                screen = EXPRESSIONS;
            }
        }

        function swipeDown() {
            if (screen == EXPRESSIONS) {
                screen = EDITOR;
                return "new_expression";
            }

            if (screen == EDITOR) {
                return "new_expression";
            }

            return null;
        }

        function pressStart() {
            if (screen == EDITOR ||
                screen == EXPRESSIONS) {
                screen = GRAPH;
                return "graph";
            }

            return null;
        }

        function pressBack(cursorAtStart) {
            if (screen == GRAPH) {
                screen = EDITOR;
                return "back_to_editor";
            }

            if (screen == EXPRESSIONS) {
                screen = EDITOR;
                return "back_to_editor";
            }

            if (!cursorAtStart) {
                return "backspace";
            }

            return "back_to_expressions";
        }
    }
}
