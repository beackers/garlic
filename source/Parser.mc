module Garlic {
    // Pratt-style expression parser.
    //
    // Important design choice:
    // implicit multiplication is inserted here, not in the evaluator.
    // Thus 2x, 2(x+1), (x+1)(x-1), and 2sin(x) all become MULTIPLY nodes.

    class Parser {
        var tokens;
        var index;

        function initialize(tokens) {
            self.tokens = tokens;
            self.index = 0;
        }

        function parse() {
            var result = parseExpression(0);

            if (!check(TokenType.EOF)) {
                throw new ParserError("Unexpected token '" + current().text + "'", current().position);
            }

            return result;
        }

        function parseExpression(minPrecedence) {
            var left = parsePrefix();

            while (true) {
                var op = infixOperator(current());

                // Explicit or implicit multiplication.
                if (op == BinaryOperator.MULTIPLY && startsExpression(current())) {
                    var right = parseExpression(20 + 1);
                    left = new BinaryNode(op, left, right);
                    continue;
                }

                if (op == null) {
                    break;
                }

                var precedence = precedenceOf(op);
                if (precedence < minPrecedence) {
                    break;
                }

                advance();

                // Power is right-associative.
                var nextMin = (op == BinaryOperator.POWER) ? precedence : precedence + 1;
                var right = parseExpression(nextMin);
                left = new BinaryNode(op, left, right);
            }

            return left;
        }

        function parsePrefix() {
            if (match(TokenType.PLUS)) {
                return new UnaryNode(UnaryOperator.POSITIVE, parseExpression(25));
            }

            if (match(TokenType.MINUS)) {
                return new UnaryNode(UnaryOperator.NEGATE, parseExpression(25));
            }

            if (match(TokenType.NUMBER)) {
                var token = previous();
                var value = Lang.toNumber(token.text);
                return new NumberNode(value);
            }

            if (match(TokenType.LPAREN)) {
                var expression = parseExpression(0);
                expect(TokenType.RPAREN, "Expected ')'");
                return expression;
            }

            if (match(TokenType.IDENTIFIER)) {
                var name = previous().text;

                if (match(TokenType.LPAREN)) {
                    var args = [];
                    if (!check(TokenType.RPAREN)) {
                        args.add(parseExpression(0));
                        while (match(TokenType.COMMA)) {
                            args.add(parseExpression(0));
                        }
                    }
                    expect(TokenType.RPAREN, "Expected ')'");
                    return new FunctionCallNode(name, args);
                }

                if (name == "pi" || name == "e") {
                    return new ConstantNode(name);
                }

                return new VariableNode(name);
            }

            throw new ParserError("Expected an expression", current().position);
        }

        function infixOperator(token) {
            if (token.type == TokenType.PLUS) return BinaryOperator.ADD;
            if (token.type == TokenType.MINUS) return BinaryOperator.SUBTRACT;
            if (token.type == TokenType.MULTIPLY) return BinaryOperator.MULTIPLY;
            if (token.type == TokenType.DIVIDE) return BinaryOperator.DIVIDE;
            if (token.type == TokenType.CARET) return BinaryOperator.POWER;

            // A token that can begin an expression immediately following
            // another expression represents implicit multiplication.
            if (startsExpression(token)) {
                return BinaryOperator.MULTIPLY;
            }

            return null;
        }

        function startsExpression(token) {
            return token.type == TokenType.NUMBER ||
                   token.type == TokenType.IDENTIFIER ||
                   token.type == TokenType.LPAREN;
        }

        function precedenceOf(operator) {
            if (operator == BinaryOperator.ADD || operator == BinaryOperator.SUBTRACT) return 10;
            if (operator == BinaryOperator.MULTIPLY || operator == BinaryOperator.DIVIDE) return 20;
            if (operator == BinaryOperator.POWER) return 30;
            return -1;
        }

        function current() {
            return self.tokens[self.index];
        }

        function previous() {
            return self.tokens[self.index - 1];
        }

        function advance() {
            var token = current();
            if (!check(TokenType.EOF)) {
                self.index += 1;
            }
            return token;
        }

        function check(type) {
            return current().type == type;
        }

        function match(type) {
            if (!check(type)) {
                return false;
            }
            advance();
            return true;
        }

        function expect(type, message) {
            if (!match(type)) {
                throw new ParserError(message, current().position);
            }
        }
    }
}
