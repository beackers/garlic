using Toybox.WatchUi as WatchUi;
using Toybox.Graphics as Graphics;

module Garlic {
    class CalculatorView extends WatchUi.View {
        var navigation;
        var expression;
        var cursor;
        var expressions;
        var dc;

        function initialize() {
            View.initialize();
            navigation = new CalculatorNavigation();
            expression = "";
            cursor = 0;
            expressions = [""];
        }

        function onLayout(dc) {
            self.dc = dc;
            loadKeyboardLayout(dc);
            refreshText();
        }

        function loadKeyboardLayout(dc) {
            if (navigation.keyboardPage == KeyboardPage.NUMBERS) {
                setLayout(Rez.Layouts.NumbersLayout(dc));
            } else if (navigation.keyboardPage == KeyboardPage.LETTERS) {
                setLayout(Rez.Layouts.LettersLayout(dc));
            } else if (navigation.keyboardPage == KeyboardPage.OPERATORS) {
                setLayout(Rez.Layouts.OperatorsLayout(dc));
            } else if (navigation.keyboardPage == KeyboardPage.FUNCTIONS) {
                setLayout(Rez.Layouts.FunctionsLayout(dc));
            } else {
                setLayout(Rez.Layouts.SpecialLayout(dc));
            }
        }

        function insert(text) {
            expression = expression.substring(0, cursor) + text +
                         expression.substring(cursor, expression.length());
            cursor += text.length();
            expressions[navigation.expressionIndex] = expression;
            refreshText();
        }

        function backspace() {
            if (cursor <= 0) {
                return;
            }
            expression = expression.substring(0, cursor - 1) +
                         expression.substring(cursor, expression.length());
            cursor -= 1;
            expressions[navigation.expressionIndex] = expression;
            refreshText();
        }

        function clearExpression() {
            expression = "";
            cursor = 0;
            expressions[navigation.expressionIndex] = expression;
            refreshText();
        }

        function newExpression() {
            var newIndex = navigation.expressionIndex + 1;
            expressions.add("");
            navigation.expressionIndex = newIndex;
            expression = "";
            cursor = 0;
            navigation.screen = CalculatorScreen.EDITOR;
            refreshText();
        }

        function refreshText() {
            var label = findDrawableById("ExpressionLabel") as WatchUi.Text?;
            if (label != null) {
                label.setText(expression == "" ? "_" : expression);
            }

            var cursorLabel = findDrawableById("CursorLabel") as WatchUi.Text?;
            if (cursorLabel != null) {
                cursorLabel.setText("|");
            }

            var history = findDrawableById("HistoryLabel") as WatchUi.Text?;
            if (history != null) {
                if (navigation.expressionIndex > 0) {
                    history.setText(expressions[navigation.expressionIndex - 1]);
                } else {
                    history.setText("");
                }
            }

            var mode = findDrawableById("ModeLabel") as WatchUi.Text?;
            if (mode != null) {
                mode.setText(modeText());
            }

            var page = findDrawableById("PageHint") as WatchUi.Text?;
            if (page != null) {
                page.setText(pageText());
            }

            WatchUi.requestUpdate();
        }

        function modeText() {
            if (navigation.screen == CalculatorScreen.EXPRESSIONS) {
                return "Expressions";
            }
            if (navigation.screen == CalculatorScreen.GRAPH) {
                return "Graph";
            }
            if (navigation.keyboardPage == KeyboardPage.NUMBERS) {
                return "Numbers";
            }
            if (navigation.keyboardPage == KeyboardPage.LETTERS) {
                return "Letters";
            }
            if (navigation.keyboardPage == KeyboardPage.OPERATORS) {
                return "Operators";
            }
            if (navigation.keyboardPage == KeyboardPage.FUNCTIONS) {
                return "Functions";
            }
            return "Special";
        }

        function pageText() {
            if (navigation.keyboardPage == KeyboardPage.NUMBERS) {
                return "← 1/5 →";
            }
            if (navigation.keyboardPage == KeyboardPage.LETTERS) {
                return "← 2/5 →";
            }
            if (navigation.keyboardPage == KeyboardPage.OPERATORS) {
                return "← 3/5 →";
            }
            if (navigation.keyboardPage == KeyboardPage.FUNCTIONS) {
                return "← 4/5 →";
            }
            return "← 5/5 →";
        }

        function onUpdate(dc) {
            if (navigation.screen == CalculatorScreen.EDITOR) {
                return;
            }

            dc.clear();
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

            if (navigation.screen == CalculatorScreen.EXPRESSIONS) {
                dc.drawText(195, 24, Graphics.FONT_LARGE, "Expressions",
                    Graphics.TEXT_JUSTIFY_CENTER);

                var i = 0;
                while (i < expressions.size()) {
                    var prefix = (i == navigation.expressionIndex) ? "> " : "  ";
                    var text = prefix + (expressions[i] == "" ? "_" : expressions[i]);
                    dc.drawText(28, 72 + (i * 34), Graphics.FONT_SMALL, text,
                        Graphics.TEXT_JUSTIFY_LEFT);
                    i += 1;
                }

                dc.drawText(195, 350, Graphics.FONT_XTINY,
                    "↑ edit   ↓ new   START graph   BACK edit",
                    Graphics.TEXT_JUSTIFY_CENTER);
                return;
            }

            // Rudimentary graph screen: draw axes and a harmless preview curve.
            // Real expression evaluation/plotting will replace this later.
            dc.drawText(195, 20, Graphics.FONT_SMALL, "GRAPH",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(195, 48, Graphics.FONT_SMALL,
                expression == "" ? "No expression" : expression,
                Graphics.TEXT_JUSTIFY_CENTER);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.drawLine(195, 82, 195, 330);
            dc.drawLine(42, 206, 348, 206);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            var x = 45;
            var lastY = 206;
            while (x <= 345) {
                var dx = (x - 195).toFloat() / 55.0;
                var y = 206 - (dx * dx * 22.0);
                if (x > 45) {
                    dc.drawLine(x - 1, lastY, x, y.toNumber());
                }
                lastY = y.toNumber();
                x += 3;
            }

            dc.drawText(195, 350, Graphics.FONT_XTINY,
                "BACK edit   START/SELECT",
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        function handleTap(x, y) {
            if (navigation.screen != CalculatorScreen.EDITOR) {
                return;
            }

            if (navigation.keyboardPage == KeyboardPage.NUMBERS) {
                if (y >= 128 && y < 166 && x >= 36 && x < 294) {
                    var col = ((x - 36) / 52).toNumber();
                    if (col == 0) {
                        clearExpression();
                    } else if (col == 1) {
                        backspace();
                    } else if (col == 2) {
                        insert("(");
                    } else if (col == 3) {
                        insert(")");
                    } else if (col == 4) {
                        insert("=");
                    }
                    return;
                }

                if (y >= 170 && y < 334 && x >= 36 && x < 294) {
                    var c = ((x - 36) / 52).toNumber();
                    var row = ((y - 170) / 42).toNumber();
                    var keys = [["7","8","9","/","^"],
                                ["4","5","6","*","-"],
                                ["1","2","3","+",","],
                                ["0",".","x","y","pi"]];
                    if (row >= 0 && row < 4 && c >= 0 && c < 5) {
                        insert(keys[row][c]);
                    }
                    return;
                }
            }

            var keys2 = KeyboardPages.keys(navigation.keyboardPage);
            var key = keyAtPoint(keys2, x, y);
            if (key != null && key.insertion != "") {
                insert(key.insertion);
            }
        }

        function keyAtPoint(keys, x, y) {
            var row;
            var col;

            if (navigation.keyboardPage == KeyboardPage.LETTERS) {
                if (y < 128 || y >= 334 || x < 36 || x >= 294) {
                    return null;
                }
                row = ((y - 128) / 42).toNumber();
                col = ((x - 36) / 86).toNumber();
                var index = row * 3 + col;
                if (row >= 0 && row < 3 && col >= 0 && col < 3 &&
                    index < keys.size()) {
                    return keys[index];
                }
                return null;
            }

            if (y < 128 || y >= 334 || x < 36 || x >= 294) {

                return null;

            }
            row = ((y - 128) / 42).toNumber();
            col = ((x - 36) / 52).toNumber();
            var index2 = row * 5 + col;
            if (index2 >= 0 && index2 < keys.size()) {
                return keys[index2];
            }
            return null;
        }

        function handleSwipe(direction) {
            if (direction == WatchUi.SWIPE_LEFT) {
                navigation.swipeRight();
                loadKeyboardLayout(dc);
            } else if (direction == WatchUi.SWIPE_RIGHT) {
                navigation.swipeLeft();
                loadKeyboardLayout(self.dc);
            } else if (direction == WatchUi.SWIPE_UP) {
                navigation.swipeUp();
            } else if (direction == WatchUi.SWIPE_DOWN) {
                navigation.swipeDown();
                newExpression();
            }
            refreshText();
        }

        function handleStart() {
            navigation.pressStart();
            refreshText();
        }

        function handleBack() {
            if (navigation.screen == CalculatorScreen.EDITOR) {
                if (cursor > 0) {
                    backspace();
                } else if (navigation.expressionIndex > 0) {
                    navigation.expressionIndex -= 1;
                    expression = expressions[navigation.expressionIndex];
                    cursor = expression.length();
                    refreshText();
                }
            } else {
                navigation.pressBack(true);
                refreshText();
            }
        }
    }
}