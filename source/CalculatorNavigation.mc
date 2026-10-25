module Garlic {
    // The calculator has one editor/workspace with orthogonal navigation:
    //   horizontal swipe = keyboard page
    //   vertical swipe   = expression/workspace navigation
    //   Start            = graph current workspace
    //   Back             = delete, then navigate back when the cursor is empty
    enum CalculatorScreen {
        EDITOR,
        EXPRESSIONS,
        GRAPH
    }

    class CalculatorNavigation {
        var screen;
        var keyboardPage;
        var expressionIndex;

        function initialize() {
            self.screen = CalculatorScreen.EDITOR;
            self.keyboardPage = KeyboardPage.NUMBERS;
            self.expressionIndex = 0;
        }

        function swipeLeft() {
            if (screen != CalculatorScreen.EDITOR) return;
            keyboardPage = KeyboardPages.previous(keyboardPage);
        }

        function swipeRight() {
            if (screen != CalculatorScreen.EDITOR) return;
            keyboardPage = KeyboardPages.next(keyboardPage);
        }

        function swipeUp() {
            if (screen == CalculatorScreen.EDITOR) {
                screen = CalculatorScreen.EXPRESSIONS;
            }
        }

        function swipeDown() {
            if (screen == CalculatorScreen.EXPRESSIONS) {
                screen = CalculatorScreen.EDITOR;
                return "new_expression";
            }

            if (screen == CalculatorScreen.EDITOR) {
                return "new_expression";
            }

            return null;
        }

        function pressStart() {
            if (screen == CalculatorScreen.EDITOR ||
                screen == CalculatorScreen.EXPRESSIONS) {
                screen = CalculatorScreen.GRAPH;
                return "graph";
            }

            return null;
        }

        function pressBack(cursorAtStart) {
            if (screen == CalculatorScreen.GRAPH) {
                screen = CalculatorScreen.EDITOR;
                return "back_to_editor";
            }

            if (screen == CalculatorScreen.EXPRESSIONS) {
                screen = CalculatorScreen.EDITOR;
                return "back_to_editor";
            }

            if (!cursorAtStart) {
                return "backspace";
            }

            return "back_to_expressions";
        }
    }
}
