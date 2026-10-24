module Garlic {
    class ParserTest {
        function run() {
            assertParses("2 + 3");
            assertParses("2x");
            assertParses("2(x + 1)");
            assertParses("(x + 1)(x - 1)");
            assertParses("2sin(x)");
            assertParses("sin(x)^2 + cos(x)^2");
            assertParses("-x^2");
            assertParses("2^3^2");

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
