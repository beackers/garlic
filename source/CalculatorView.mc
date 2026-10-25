using Toybox.WatchUi as WatchUi;
using Toybox.Graphics as Graphics;

module Garlic {
    class CalculatorView extends WatchUi.View {
        var navigation;
        var expression;
        var cursor;
        var expressions;
        var dc;
        var touchActive;
        var touchX;
        var touchY;
        var touchLabel;
        var evaluator;

        function initialize() {
            View.initialize();
            navigation = new CalculatorNavigation();
            expression = "";
            cursor = 0;
            expressions = [""];
            touchActive = false;
            touchX = 0;
            touchY = 0;
            touchLabel = null;
            evaluator = new Evaluator(new Environment());
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

            dc.drawText(center, 8, Graphics.FONT_XTINY, modeText(),
                Graphics.TEXT_JUSTIFY_CENTER);

            if (navigation.expressionIndex > 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
                dc.drawText(18, 24, Graphics.FONT_XTINY,
                    expressions[navigation.expressionIndex - 1],
                    Graphics.TEXT_JUSTIFY_LEFT);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            }

            // Compact expression field.
            dc.drawRoundedRectangle(10, 40, width - 20, 42, 7);
            var shown = expression == "" ? "_" : expression;
            dc.drawText(18, 50, Graphics.FONT_LARGE, shown,
                Graphics.TEXT_JUSTIFY_LEFT);

            if (cursor <= expression.length()) {
                var prefix = expression.substring(0, cursor);
                var cursorX = 18 + dc.getTextWidthInPixels(prefix, Graphics.FONT_LARGE);
                dc.drawLine(cursorX, 49, cursorX, 77);
            }

            // Compact command row.
            drawKey(dc, 10, 88, 68, 28, "CLR");
            drawKey(dc, 86, 88, 68, 28, "DEL");
            drawKey(dc, 162, 88, 68, 28, "(");
            drawKey(dc, 238, 88, 68, 28, ")");
            drawKey(dc, 314, 88, 66, 28, "=");

            if (navigation.keyboardPage == PAGE_NUMBERS) {
                drawGrid(dc, [
                    ["7","8","9","/","^"],
                    ["4","5","6","*","-"],
                    ["1","2","3","+",","],
                    ["0",".","x","y","pi"]
                ]);
            } else {
                drawKeyboardPage(dc);
            }

            // Touch magnifier is drawn last so it is always visible above
            // the key currently under the finger.
            if (touchActive && touchLabel != null) {
                drawTouchMagnifier(dc);
            }

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.drawText(center, 374, Graphics.FONT_XTINY,
                pageText() + "   swipe pages   START graph",
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        function drawKey(dc, x, y, w, h, label) {
            dc.drawRoundedRectangle(x, y, w, h, 6);
            dc.drawText(x + (w / 2).toNumber(), y + 7,
                Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        }

        function drawTouchMagnifier(dc) {
            var width = dc.getWidth();
            var bubbleX = touchX;
            var bubbleY = touchY - 62;

            if (bubbleY < 48) {
                bubbleY = 48;
            }
            if (bubbleX < 48) {
                bubbleX = 48;
            }
            if (bubbleX > width - 48) {
                bubbleX = width - 48;
            }

            // Highlight the key underneath the finger.
            var hit = keyRect(touchX, touchY);
            if (hit != null) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
                dc.fillRoundedRectangle(hit[0], hit[1], hit[2], hit[3], 6);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawText(hit[0] + (hit[2] / 2).toNumber(),
                    hit[1] + 12, Graphics.FONT_SMALL, hit[4],
                    Graphics.TEXT_JUSTIFY_CENTER);
            }

            // Magnified bubble, deliberately offset above the finger.
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.fillCircle(bubbleX, bubbleY, 42);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.drawCircle(bubbleX, bubbleY, 42);
            dc.drawText(bubbleX, bubbleY - 19, Graphics.FONT_LARGE,
                touchLabel, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(bubbleX, bubbleY + 17, Graphics.FONT_XTINY,
                "release",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }

        function keyRect(x, y) {
            // Returns [x, y, width, height, label] for the compact editor grid.
            if (y >= 88 && y < 116 && x >= 10 && x < 380) {
                if (x < 78) {
                    return [10, 88, 68, 28, "CLR"];
                }
                if (x < 154) {
                    return [86, 88, 68, 28, "DEL"];
                }
                if (x < 230) {
                    return [162, 88, 68, 28, "("];
                }
                if (x < 306) {
                    return [238, 88, 68, 28, ")"];
                }
                return [314, 88, 66, 28, "="];
            }

            if (y < 122 || y >= 340 || x < 10 || x >= 380) {
                return null;
            }

            var col = ((x - 10) / 74).toNumber();
            var row = ((y - 122) / 54).toNumber();
            if (col < 0 || col >= 5 || row < 0 || row >= 4) {
                return null;
            }

            var index = row * 5 + col;
            var keys = KeyboardPages.keys(navigation.keyboardPage);
            if (navigation.keyboardPage == PAGE_NUMBERS) {
                var numberKeys = [["7","8","9","/","^"],
                                  ["4","5","6","*","-"],
                                  ["1","2","3","+",","],
                                  ["0",".","x","y","pi"]];
                return [10 + col * 74, 122 + row * 54, 68, 48,
                    numberKeys[row][col]];
            }

            if (index < keys.size()) {
                return [10 + col * 74, 122 + row * 54, 68, 48,
                    keys[index].label];
            }

            return null;
        }

        function drawGrid(dc, rows) {
            var x0 = 10;
            var y0 = 122;
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

            dc.drawText(center, 12, Graphics.FONT_SMALL, "Expressions",
                Graphics.TEXT_JUSTIFY_CENTER);

            var y = 38;
            var i = 0;

            while (i < expressions.size()) {
                var isCurrent = i == navigation.expressionIndex;
                var boxY = y;

                // Each expression gets its own card. The selected expression
                // gets the same card, but with a small pointer on the left.
                dc.drawRoundedRectangle(10, boxY, width - 20, 58, 8);

                if (isCurrent) {
                    dc.drawText(18, boxY + 9, Graphics.FONT_XTINY, ">",
                        Graphics.TEXT_JUSTIFY_LEFT);
                }

                var expressionText = expressions[i] == "" ? "_" : expressions[i];
                var textX = isCurrent ? 32 : 20;
                dc.drawText(textX, boxY + 7, Graphics.FONT_SMALL,
                    expressionText, Graphics.TEXT_JUSTIFY_LEFT);

                var result = expressionResult(expressions[i]);
                if (result != null) {
                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
                    dc.drawText(textX, boxY + 34, Graphics.FONT_XTINY,
                        result, Graphics.TEXT_JUSTIFY_LEFT);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                }

                y += 66;
                i += 1;
            }

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.drawText(center, 350, Graphics.FONT_XTINY,
                "UP edit   DOWN new   START graph   BACK edit",
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Return a compact numeric result for a plain expression.
        // Relations/equations and function definitions intentionally return
        // null because they belong to the graphing/function workspace.
        function expressionResult(text) {
            if (text == null || text == "") {
                return null;
            }

            try {
                var tokenizer = new Tokenizer(text);
                var parser = new Parser(tokenizer.tokenize());
                var statement = parser.parse();
                var node = statement.expression;

                if (node.type != NODE_NUMBER &&
                    node.type != NODE_CONSTANT &&
                    node.type != NODE_UNARY &&
                    node.type != NODE_BINARY &&
                    node.type != NODE_FUNCTION_CALL) {
                    return null;
                }

                var value = evaluator.evaluate(node);
                return formatNumber(value);
            } catch (e) {
                return null;
            }
        }

        function formatNumber(value) {
            // Garmin's default number-to-string conversion is compact enough
            // for the expression list, and avoids adding a full formatter yet.
            return value.toString();
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

            var hit = keyRect(x, y);
            if (hit == null) {
                return;
            }

            activateKey(hit[4]);
        }

        function activateKey(label) {
            if (label == "CLR") {
                clearExpression();
            } else if (label == "DEL") {
                backspace();
            } else if (label == "(") {
                insert("(");
            } else if (label == ")") {
                insert(")");
            } else if (label == "=") {
                insert("=");
            } else {
                insert(label);
            }
        }

        function beginTouch(x, y) {
            if (navigation.screen != SCREEN_EDITOR) {
                return;
            }

            touchX = x;
            touchY = y;
            touchLabel = null;

            var hit = keyRect(x, y);
            if (hit != null) {
                touchLabel = hit[4];
            }

            touchActive = true;
            WatchUi.requestUpdate();
        }

        function moveTouch(x, y) {
            if (!touchActive) {
                return;
            }

            touchX = x;
            touchY = y;

            var hit = keyRect(x, y);
            touchLabel = hit == null ? null : hit[4];
            WatchUi.requestUpdate();
        }

        function endTouch(x, y) {
            if (!touchActive) {
                return;
            }

            touchX = x;
            touchY = y;

            var hit = keyRect(x, y);
            touchActive = false;

            if (hit != null) {
                activateKey(hit[4]);
            }

            touchLabel = null;
            WatchUi.requestUpdate();
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