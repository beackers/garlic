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
            // The editor is drawn directly in onUpdate().
            // Keeping the resource layout out of the editor avoids
            // fighting the custom renderer for dynamic keyboard pages.
            setLayout(null);
        }

        function loadKeyboardLayout() {
            // Editor rendering is handled directly by onUpdate().
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
            navigation.screen = SCREEN_EDITOR;
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
            if (navigation.screen == SCREEN_EXPRESSIONS) {
                return "Expressions";
            }
            if (navigation.screen == SCREEN_GRAPH) {
                return "Graph";
            }
            if (navigation.keyboardPage == PAGE_NUMBERS) {
                return "Numbers";
            }
            if (navigation.keyboardPage == PAGE_LETTERS) {
                return "Letters";
            }
            if (navigation.keyboardPage == PAGE_OPERATORS) {
                return "Operators";
            }
            if (navigation.keyboardPage == PAGE_FUNCTIONS) {
                return "Functions";
            }
            return "Special";
        }

        function pageText() {
            if (navigation.keyboardPage == PAGE_NUMBERS) {
                return "← 1/5 →";
            }
            if (navigation.keyboardPage == PAGE_LETTERS) {
                return "← 2/5 →";
            }
            if (navigation.keyboardPage == PAGE_OPERATORS) {
                return "← 3/5 →";
            }
            if (navigation.keyboardPage == PAGE_FUNCTIONS) {
                return "← 4/5 →";
            }
            return "← 5/5 →";
        }

        function onUpdate(dc) {
            dc.clear();
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

            if (navigation.screen == SCREEN_EDITOR) {
                drawEditor(dc);
                return;
            }

            if (navigation.screen == SCREEN_EXPRESSIONS) {
                drawExpressions(dc);
                return;
            }

            drawGraph(dc);
        }

        function drawEditor(dc) {
            var width = dc.getWidth();
            var center = (width / 2).toNumber();

            dc.drawText(center, 12, Graphics.FONT_XTINY, modeText(),
                Graphics.TEXT_JUSTIFY_CENTER);

            if (navigation.expressionIndex > 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
                dc.drawText(18, 30, Graphics.FONT_XTINY,
                    expressions[navigation.expressionIndex - 1],
                    Graphics.TEXT_JUSTIFY_LEFT);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            }

            // Expression field.
            dc.drawRoundedRectangle(12, 48, width - 24, 48, 7);
            var shown = expression == "" ? "_" : expression;
            dc.drawText(22, 61, Graphics.FONT_LARGE, shown,
                Graphics.TEXT_JUSTIFY_LEFT);

            // Cursor is intentionally simple for now. A proper text cursor
            // will come with horizontal scrolling/editing.
            var cursorText = shown;
            if (cursor <= expression.length()) {
                var prefix = expression.substring(0, cursor);
                var cursorX = 22 + dc.getTextWidthInPixels(prefix, Graphics.FONT_LARGE);
                dc.drawLine(cursorX, 58, cursorX, 89);
            }

            // Top command row.
            drawKey(dc, 12, 104, 68, 30, "CLR");
            drawKey(dc, 86, 104, 68, 30, "DEL");
            drawKey(dc, 160, 104, 68, 30, "(");
            drawKey(dc, 234, 104, 68, 30, ")");
            drawKey(dc, 308, 104, 68, 30, "=");

            if (navigation.keyboardPage == PAGE_NUMBERS) {
                drawGrid(dc, [
                    ["7","8","9","/","^"],
                    ["4","5","6","*","-"],
                    ["1","2","3","+"," ,"],
                    ["0",".","x","y","pi"]
                ]);
            } else {
                drawKeyboardPage(dc);
            }

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.drawText(center, 360, Graphics.FONT_XTINY,
                pageText() + "   swipe pages   START graph",
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        function drawKey(dc, x, y, w, h, label) {
            dc.drawRoundedRectangle(x, y, w, h, 6);
            dc.drawText(x + (w / 2).toNumber(), y + 7,
                Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        }

        function drawGrid(dc, rows) {
            var x0 = 12;
            var y0 = 140;
            var w = 68;
            var h = 48;
            var gap = 6;
            var row = 0;

            while (row < rows.size()) {
                var col = 0;
                while (col < rows[row].size()) {
                    drawKey(dc, x0 + col * (w + gap),
                        y0 + row * (h + gap), w, h, rows[row][col]);
                    col += 1;
                }
                row += 1;
            }
        }

        function drawKeyboardPage(dc) {
            var keys = KeyboardPages.keys(navigation.keyboardPage);
            var rows = [];
            var row = [];
            var i = 0;

            while (i < keys.size()) {
                row.add(keys[i].label);
                if (row.size() == 5) {
                    rows.add(row);
                    row = [];
                }
                i += 1;
            }

            if (row.size() > 0) {
                while (row.size() < 5) {
                    row.add("");
                }
                rows.add(row);
            }

            drawGrid(dc, rows);
        }

        function drawExpressions(dc) {
            var width = dc.getWidth();
            var center = (width / 2).toNumber();

            dc.drawText(center, 24, Graphics.FONT_LARGE, "Expressions",
                Graphics.TEXT_JUSTIFY_CENTER);

            var i = 0;
            while (i < expressions.size()) {
                var prefix = (i == navigation.expressionIndex) ? "> " : "  ";
                var text = prefix + (expressions[i] == "" ? "_" : expressions[i]);
                dc.drawText(18, 72 + (i * 34), Graphics.FONT_SMALL, text,
                    Graphics.TEXT_JUSTIFY_LEFT);
                i += 1;
            }

            dc.drawText(center, 350, Graphics.FONT_XTINY,
                "UP edit   DOWN new   START graph   BACK edit",
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        function drawGraph(dc) {
            var width = dc.getWidth();
            var center = (width / 2).toNumber();

            dc.drawText(center, 20, Graphics.FONT_SMALL, "Graph",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(center, 48, Graphics.FONT_SMALL,
                expression == "" ? "No expression" : expression,
                Graphics.TEXT_JUSTIFY_CENTER);

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.drawLine(center, 82, center, 330);
            dc.drawLine(42, 206, width - 42, 206);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            var x = 45;
            var lastY = 206;
            while (x <= width - 45) {
                var dx = (x - center).toFloat() / 55.0;
                var y = 206 - (dx * dx * 22.0);
                if (x > 45) {
                    dc.drawLine(x - 1, lastY, x, y.toNumber());
                }
                lastY = y.toNumber();
                x += 3;
            }

            dc.drawText(center, 350, Graphics.FONT_XTINY,
                "BACK edit   START/SELECT",
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        function handleTap(x, y) {
            if (navigation.screen != SCREEN_EDITOR) {
                return;
            }

            if (navigation.keyboardPage == PAGE_NUMBERS) {
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

            if (navigation.keyboardPage == PAGE_LETTERS) {
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
                loadKeyboardLayout();
            } else if (direction == WatchUi.SWIPE_RIGHT) {
                navigation.swipeLeft();
                loadKeyboardLayout();
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
            if (navigation.screen == SCREEN_EDITOR) {
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