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

    // Structural parser tests. These do not merely check that input is
    // accepted; they check that the resulting AST has the exact shape
    // required by precedence, associativity, and implicit multiplication.
    class AstTest {
        function run() {
            // Binary operators and precedence.
            assertTree("2 + 3",
                statement(binary(ADD, number(2), number(3))));

            assertTree("5 - 2",
                statement(binary(SUBTRACT, number(5), number(2))));

            assertTree("2 * 3",
                statement(binary(MULTIPLY, number(2), number(3))));

            assertTree("8 / 4",
                statement(binary(DIVIDE, number(8), number(4))));

            assertTree("x^2",
                statement(binary(POWER, variable("x"), number(2))));

            // Addition/subtraction must be lower precedence than multiplication.
            assertTree("2 + 3 * x",
                statement(binary(ADD,
                    number(2),
                    binary(MULTIPLY, number(3), variable("x")))));

            // Multiplication must be lower precedence than powers.
            assertTree("2 * x^2",
                statement(binary(MULTIPLY,
                    number(2),
                    binary(POWER, variable("x"), number(2)))));

            // Powers must be right-associative.
            assertTree("2^3^2",
                statement(binary(POWER,
                    number(2),
                    binary(POWER, number(3), number(2)))));

            // Unary minus must sit below exponentiation.
            assertTree("-x^2",
                statement(unary(NEGATE,
                    binary(POWER, variable("x"), number(2)))));

            assertTree("(-x)^2",
                statement(binary(POWER,
                    unary(NEGATE, variable("x")),
                    number(2))));

            assertTree("+x",
                statement(unary(POSITIVE, variable("x"))));

            // Implicit multiplication must be explicit in the AST.
            assertTree("2x^2",
                statement(binary(MULTIPLY,
                    number(2),
                    binary(POWER, variable("x"), number(2)))));

            assertTree("2(x + 1)",
                statement(binary(MULTIPLY,
                    number(2),
                    binary(ADD, variable("x"), number(1)))));

            assertTree("(x + 1)(x - 1)",
                statement(binary(MULTIPLY,
                    binary(ADD, variable("x"), number(1)),
                    binary(SUBTRACT, variable("x"), number(1)))));

            // Function calls must bind as primary expressions.
            assertTree("sin(x)",
                statement(call("sin", [variable("x")])));

            assertTree("sqrt(x + 1)",
                statement(call("sqrt", [
                    binary(ADD, variable("x"), number(1))
                ])));

            assertTree("f(x, y)",
                statement(call("f", [variable("x"), variable("y")])));

            assertTree("2sin(x)",
                statement(binary(MULTIPLY,
                    number(2),
                    call("sin", [variable("x")]))));

            assertTree("sin(x)^2",
                statement(binary(POWER,
                    call("sin", [variable("x")]),
                    number(2))));

            // Constants and variables.
            assertTree("pi",
                statement(constant("pi")));

            assertTree("e",
                statement(constant("e")));

            assertTree("tau",
                statement(constant("tau")));

            assertTree("2pi",
                statement(binary(MULTIPLY,
                    number(2),
                    constant("pi"))));

            // Relations.
            assertTree("x = 3",
                statement(relation(EQUALS,
                    variable("x"), number(3))));

            assertTree("x < 3",
                statement(relation(LESS,
                    variable("x"), number(3))));

            assertTree("x <= 3",
                statement(relation(LESS_EQUAL,
                    variable("x"), number(3))));

            assertTree("x > 3",
                statement(relation(GREATER,
                    variable("x"), number(3))));

            assertTree("x >= 3",
                statement(relation(GREATER_EQUAL,
                    variable("x"), number(3))));

            // Chained inequalities become adjacent comparisons joined by AND.
            assertTree("0 < x < 3",
                statement(logical(AND,
                    relation(LESS, number(0), variable("x")),
                    relation(LESS, variable("x"), number(3)))));

            // Logical operators.
            assertTree("x > 0 and x < 10",
                statement(logical(AND,
                    relation(GREATER, variable("x"), number(0)),
                    relation(LESS, variable("x"), number(10)))));

            assertTree("x < 0 or x > 1",
                statement(logical(OR,
                    relation(LESS, variable("x"), number(0)),
                    relation(GREATER, variable("x"), number(1)))));

            // Restrictions belong to the statement, not to the arithmetic AST.
            assertTree("y = x^2 {0 < x < 3}",
                statementWithRestriction(
                    relation(EQUALS,
                        variable("y"),
                        binary(POWER, variable("x"), number(2))),
                    logical(AND,
                        relation(LESS, number(0), variable("x")),
                        relation(LESS, variable("x"), number(3)))));

            // Function definitions.
            assertTree("f(x) = x^2",
                statement(functionDefinition("f", ["x"],
                    binary(POWER, variable("x"), number(2)))));

            assertTree("g(x, y) = x^2 + y^2",
                statement(functionDefinition("g", ["x", "y"],
                    binary(ADD,
                        binary(POWER, variable("x"), number(2)),
                        binary(POWER, variable("y"), number(2))))));

            // A deliberately mixed expression: precedence, implicit
            // multiplication, a function call, and a power all at once.
            assertTree("2x + sin(x)^2",
                statement(binary(ADD,
                    binary(MULTIPLY, number(2), variable("x")),
                    binary(POWER,
                        call("sin", [variable("x")]),
                        number(2)))));

            return true;
        }

        function parse(source) {
            var lexer = new Lexer(source);
            var parser = new Parser(lexer.tokenize());
            return parser.parse();
        }

        function assertTree(source, expected) {
            var actual = parse(source);

            if (!astEqual(actual, expected)) {
                throw new ParserError("AST mismatch for: " + source, 0);
            }
        }

        function astEqual(left, right) {
            if (left == null || right == null) {
                return left == right;
            }

            if (left.type != right.type) {
                return false;
            }

            switch (left.type) {
                case NUMBER:
                    return left.value == right.value;

                case VARIABLE:
                    return left.name == right.name;

                case CONSTANT:
                    return left.name == right.name;

                case UNARY:
                    return left.operator == right.operator
                        && astEqual(left.operand, right.operand);

                case BINARY:
                    return left.operator == right.operator
                        && astEqual(left.left, right.left)
                        && astEqual(left.right, right.right);

                case FUNCTION_CALL:
                    if (left.name != right.name
                        || left.arguments.size() != right.arguments.size()) {
                        return false;
                    }

                    for (var i = 0; i < left.arguments.size(); i++) {
                        if (!astEqual(left.arguments[i], right.arguments[i])) {
                            return false;
                        }
                    }

                    return true;

                case RELATION:
                    return left.operator == right.operator
                        && astEqual(left.left, right.left)
                        && astEqual(left.right, right.right);

                case LOGICAL:
                    return left.operator == right.operator
                        && astEqual(left.left, right.left)
                        && astEqual(left.right, right.right);

                case FUNCTION_DEFINITION:
                    if (left.name != right.name
                        || left.parameters.size() != right.parameters.size()) {
                        return false;
                    }

                    for (var j = 0; j < left.parameters.size(); j++) {
                        if (left.parameters[j] != right.parameters[j]) {
                            return false;
                        }
                    }

                    return astEqual(left.body, right.body);

                case STATEMENT:
                    if (left.restrictions.size() != right.restrictions.size()) {
                        return false;
                    }

                    if (!astEqual(left.expression, right.expression)) {
                        return false;
                    }

                    for (var k = 0; k < left.restrictions.size(); k++) {
                        if (!astEqual(left.restrictions[k], right.restrictions[k])) {
                            return false;
                        }
                    }

                    return true;
            }

            return false;
        }

        function statement(expression) {
            return new StatementNode(expression, []);
        }

        function statementWithRestriction(expression, restriction) {
            return new StatementNode(expression, [restriction]);
        }

        function number(value) {
            return new NumberNode(value);
        }

        function variable(name) {
            return new VariableNode(name);
        }

        function constant(name) {
            return new ConstantNode(name);
        }

        function unary(operator, operand) {
            return new UnaryNode(operator, operand);
        }

        function binary(operator, left, right) {
            return new BinaryNode(operator, left, right);
        }

        function call(name, arguments) {
            return new FunctionCallNode(name, arguments);
        }

        function relation(operator, left, right) {
            return new RelationNode(operator, left, right);
        }

        function logical(operator, left, right) {
            return new LogicalNode(operator, left, right);
        }

        function functionDefinition(name, parameters, body) {
            return new FunctionDefinitionNode(name, parameters, body);
        }
    }
}
