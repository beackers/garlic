module Garlic {
    // Horizontal keyboard pages.  The editor stays on the same expression;
    // only the available keys change.
    enum KeyboardPage {
        NUMBERS,
        LETTERS,
        OPERATORS,
        FUNCTIONS,
        SPECIAL
    }

    class KeyboardKey {
        var label;
        var insertion;
        var action;

        function initialize(label, insertion, action) {
            self.label = label;
            self.insertion = insertion;
            self.action = action;
        }
    }

    class KeyboardPages {
        static function pageCount() {
            return 5;
        }

        static function next(page) {
            if (page == KeyboardPage.SPECIAL) {
                return KeyboardPage.NUMBERS;
            }
            return page + 1;
        }

        static function previous(page) {
            if (page == KeyboardPage.NUMBERS) {
                return KeyboardPage.SPECIAL;
            }
            return page - 1;
        }

        // These are the semantic key definitions.  Layout XML supplies the
        // touch targets; this table supplies what a key means to the editor.
        static function keys(page) {
            if (page == KeyboardPage.NUMBERS) {
                return [
                    new KeyboardKey("7", "7", "insert"),
                    new KeyboardKey("8", "8", "insert"),
                    new KeyboardKey("9", "9", "insert"),
                    new KeyboardKey("/", "/", "insert"),
                    new KeyboardKey("^", "^", "insert"),
                    new KeyboardKey("4", "4", "insert"),
                    new KeyboardKey("5", "5", "insert"),
                    new KeyboardKey("6", "6", "insert"),
                    new KeyboardKey("*", "*", "insert"),
                    new KeyboardKey("-", "-", "insert"),
                    new KeyboardKey("1", "1", "insert"),
                    new KeyboardKey("2", "2", "insert"),
                    new KeyboardKey("3", "3", "insert"),
                    new KeyboardKey("+", "+", "insert"),
                    new KeyboardKey(",", ",", "insert"),
                    new KeyboardKey("0", "0", "insert"),
                    new KeyboardKey(".", ".", "insert"),
                    new KeyboardKey("(", "(", "insert"),
                    new KeyboardKey(")", ")", "insert"),
                    new KeyboardKey("=", "=", "insert")
                ];
            }

            if (page == KeyboardPage.LETTERS) {
                return [
                    new KeyboardKey("ABC", "", "t9:abc"),
                    new KeyboardKey("DEF", "", "t9:def"),
                    new KeyboardKey("GHI", "", "t9:ghi"),
                    new KeyboardKey("JKL", "", "t9:jkl"),
                    new KeyboardKey("MNO", "", "t9:mno"),
                    new KeyboardKey("PQRS", "", "t9:pqrs"),
                    new KeyboardKey("TUV", "", "t9:tuv"),
                    new KeyboardKey("WXYZ", "", "t9:wxyz"),
                    new KeyboardKey("_", "_", "insert"),
                    new KeyboardKey("x", "x", "insert"),
                    new KeyboardKey("y", "y", "insert"),
                    new KeyboardKey("n", "n", "insert"),
                    new KeyboardKey("f", "f", "insert"),
                    new KeyboardKey("g", "g", "insert"),
                    new KeyboardKey("h", "h", "insert")
                ];
            }

            if (page == KeyboardPage.OPERATORS) {
                return [
                    new KeyboardKey("+", "+", "insert"),
                    new KeyboardKey("-", "-", "insert"),
                    new KeyboardKey("×", "*", "insert"),
                    new KeyboardKey("÷", "/", "insert"),
                    new KeyboardKey("^", "^", "insert"),
                    new KeyboardKey("=", "=", "insert"),
                    new KeyboardKey("<", "<", "insert"),
                    new KeyboardKey(">", ">", "insert"),
                    new KeyboardKey("≤", "<=", "insert"),
                    new KeyboardKey("≥", ">=", "insert"),
                    new KeyboardKey("(", "(", "insert"),
                    new KeyboardKey(")", ")", "insert"),
                    new KeyboardKey("{", "{", "insert"),
                    new KeyboardKey("}", "}", "insert"),
                    new KeyboardKey(",", ",", "insert"),
                    new KeyboardKey("%", "%", "insert"),
                    new KeyboardKey("!", "!", "insert"),
                    new KeyboardKey("and", "and", "insert"),
                    new KeyboardKey("or", "or", "insert"),
                    new KeyboardKey(":", ":", "insert")
                ];
            }

            if (page == KeyboardPage.FUNCTIONS) {
                return [
                    new KeyboardKey("sin", "sin(", "function"),
                    new KeyboardKey("cos", "cos(", "function"),
                    new KeyboardKey("tan", "tan(", "function"),
                    new KeyboardKey("asin", "asin(", "function"),
                    new KeyboardKey("acos", "acos(", "function"),
                    new KeyboardKey("atan", "atan(", "function"),
                    new KeyboardKey("ln", "ln(", "function"),
                    new KeyboardKey("log", "log(", "function"),
                    new KeyboardKey("exp", "exp(", "function"),
                    new KeyboardKey("sqrt", "sqrt(", "function"),
                    new KeyboardKey("abs", "abs(", "function"),
                    new KeyboardKey("floor", "floor(", "function"),
                    new KeyboardKey("ceil", "ceil(", "function"),
                    new KeyboardKey("round", "round(", "function"),
                    new KeyboardKey("min", "min(", "function"),
                    new KeyboardKey("max", "max(", "function"),
                    new KeyboardKey("sum", "sum(", "function"),
                    new KeyboardKey("prod", "prod(", "function"),
                    new KeyboardKey("mod", "mod(", "function"),
                    new KeyboardKey("random", "random(", "function")
                ];
            }

            return [
                new KeyboardKey("π", "pi", "insert"),
                new KeyboardKey("e", "e", "insert"),
                new KeyboardKey("τ", "tau", "insert"),
                new KeyboardKey("∞", "infinity", "insert"),
                new KeyboardKey("°", "degree", "insert"),
                new KeyboardKey(";", ";", "insert"),
                new KeyboardKey("[", "[", "insert"),
                new KeyboardKey("]", "]", "insert"),
                new KeyboardKey("'", "'", "insert"),
                new KeyboardKey("quote", "\"", "insert")
            ];
        }
    }
}
