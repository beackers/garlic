module Garlic {
    // The calculator has one editor/workspace with orthogonal navigation:
    //   horizontal swipe = keyboard page
    //   vertical swipe   = expression/workspace navigation
    //   Start            = graph current workspace
    //   Back             = delete, then navigate back when the cursor is empty
    enum CalculatorScreen {
        SCREEN_EDITOR,
        SCREEN_EXPRESSIONS,
        SCREEN_GRAPH
    }

    class CalculatorNavigation {
        var screen;
        var keyboardPage;
        var expressionIndex;

        function initialize() {
            self.screen = SCREEN_EDITOR;
            self.keyboardPage = PAGE_NUMBERS;
            self.expressionIndex = 0;
        }

        function swipeLeft() {
            if (screen != SCREEN_EDITOR) {
                return;
            }
            keyboardPage = KeyboardPages.previous(keyboardPage);
        }

        function swipeRight() {
            if (screen != SCREEN_EDITOR) {
                return;
            }
            keyboardPage = KeyboardPages.next(keyboardPage);
        }

        function swipeUp() {
            if (screen == SCREEN_EDITOR) {
                screen = SCREEN_EXPRESSIONS;
            }
        }

        function swipeDown() {
            if (screen == SCREEN_EXPRESSIONS) {
                screen = SCREEN_EDITOR;
                return "new_expression";
            }

            if (screen == SCREEN_EDITOR) {
                return "new_expression";
            }

            return null;
        }

        function pressStart() {
            if (screen == SCREEN_EDITOR) {
                screen = SCREEN_EXPRESSIONS;
                return "expressions";
            }

            if (screen == SCREEN_EXPRESSIONS) {
                screen = SCREEN_GRAPH;
                return "graph";
            }

            return null;
        }

        function pressBack(cursorAtStart) {
            if (screen == SCREEN_GRAPH) {
                screen = SCREEN_EDITOR;
                return "back_to_editor";
            }

            if (screen == SCREEN_EXPRESSIONS) {
                screen = SCREEN_EDITOR;
                return "back_to_editor";
            }

            if (!cursorAtStart) {
                return "backspace";
            }

            return "back_to_expressions";
        }
    }
}
