module Garlic {
    class ParserTest {
        function run() {
            // Basic arithmetic.
            assertParses("2 + 3");
            assertParses("2 * 3");
            assertParses("2 / 3");

            // Implicit multiplication.
            assertParses("2x");
            assertParses("2(x + 1)");
            assertParses("(x + 1)(x - 1)");
            assertParses("2sin(x)");
            assertParses("2xy");

            // Powers and unary operators.
            assertParses("x^2");
            assertParses("2^3^2");
            assertParses("-x^2");
            assertParses("(-x)^2");
            assertParses("2x^2");
            assertParses("sin(x)^2");

            // Functions and multiple arguments.
            assertParses("sin(x)");
            assertParses("sqrt(x + 1)");
            assertParses("f(x, y)");
            assertParses("2sin(x + 1)");

            // Scientific notation and constants.
            assertParses("1e6");
            assertParses("2.5e-3");
            assertParses("pi");
            assertParses("tau");
            assertParses("2pi");

            // Relations and restrictions.
            assertParses("x = 3");
            assertParses("x < 3");
            assertParses("x <= 3");
            assertParses("x > 3");
            assertParses("x >= 3");
            assertParses("0 < x < 3");
            assertParses("y = x^2 {0 < x < 3}");
            assertParses("x > 0 and x < 10");

            // User-defined functions.
            assertParses("f(x) = x^2");
            assertParses("g(x, y) = x^2 + y^2");
            assertParses("h() = 42");

            // A more realistic expression.
            var lexer = new Lexer("2x + sin(x)^2");
            var parser = new Parser(lexer.tokenize());
            var tree = parser.parse();

            return tree != null;
        }

        function assertParses(source) {
            var lexer = new Lexer(source);
            var parser = new Parser(lexer.tokenize());
            parser.parse();
        }
    }
}
