using Toybox.Lang as Lang;

module Garlic {
    // Pratt parser for Garlic's Desmos-like expression language.
    //
    // Precedence, from low to high:
    //   OR
    //   AND
    //   relations
    //   + -
    //   * / and implicit multiplication
    //   unary + -
    //   ^
    //
    // The exact precedence of unary minus relative to exponentiation is
    // intentional: -x^2 is parsed as -(x^2), matching normal mathematical
    // notation and Desmos behavior.

    class Parser {
        var tokens;
        var index;

        function initialize(tokens) {
            self.tokens = tokens;
            self.index = 0;
        }

        function parse() {
            var expression = parseStatementExpression();

            var restrictions = [];
            while (match(LBRACE)) {
                restrictions.add(parseLogicalExpression());
                expect(RBRACE, "Expected '}'");
            }

            if (!check(EOF)) {
                throw new ParserError("Unexpected token '" + current().text + "'", current().position);
            }

            return new StatementNode(expression, restrictions);
        }

        function parseStatementExpression() {
            // Detect f(x,y)=... without confusing ordinary f(x) calls.
            if (isFunctionDefinitionStart()) {
                return parseFunctionDefinition();
            }

            return parseLogicalExpression();
        }

        function parseFunctionDefinition() {
            var name = expectIdentifier("Expected function name");
            expect(LPAREN, "Expected '(' after function name");

            var parameters = [];
            if (!check(RPAREN)) {
                parameters.add(expectIdentifier("Expected parameter name"));

                while (match(COMMA)) {
                    parameters.add(expectIdentifier("Expected parameter name"));
                }
            }

            expect(RPAREN, "Expected ')' after parameters");
            expect(EQUALS, "Expected '=' in function definition");

            var body = parseLogicalExpression();
            return new FunctionDefinitionNode(name, parameters, body);
        }

        function parseLogicalExpression() {
            var left = parseRelationExpression();

            while (isIdentifier("or")) {
                advance();
                left = new LogicalNode(OR, left, parseRelationExpression());
            }

            return left;
        }

        function parseRelationExpression() {
            var left = parseArithmeticExpression(0);

            if (!isRelationOperator(current())) {
                // "and" is only meaningful between conditions.
                if (isIdentifier("and")) {
                    throw new ParserError("Expected a relation before 'and'", current().position);
                }
                return left;
            }

            var relation = new RelationNode(relationOperator(current()), left, parseArithmeticExpression(0));
            advance();

            // Desmos accepts chained inequalities such as 0 < x < 3.
            // Represent the chain as AND of adjacent comparisons.
            while (isRelationOperator(current())) {
                var op = relationOperator(current());
                advance();
                var right = parseArithmeticExpression(0);
                relation = new LogicalNode(
                    AND,
                    relation,
                    new RelationNode(op, relationRight(relation), right)
                );
            }

            while (isIdentifier("and")) {
                advance();
                relation = new LogicalNode(
                    AND,
                    relation,
                    parseRelationExpression()
                );
            }

            return relation;
        }

        // Pull the right-hand operand out of a relation chain. For ordinary
        // relations this is simply relation.right; for an existing chain it
        // is the rightmost operand.
        function relationRight(node) {
            if (node.type == RELATION) {
                return node.right;
            }

            if (node.type == LOGICAL && node.operator == AND) {
                return relationRight(node.right);
            }

            return node;
        }

        function parseArithmeticExpression(minPrecedence) {
            var left = parsePrefix();

            while (true) {
                var token = current();
                var op = explicitBinaryOperator(token);

                if (op == null && startsExpression(token)) {
                    op = MULTIPLY;
                }

                if (op == null) {
                    break;
                }

                var precedence = precedenceOf(op);
                if (precedence < minPrecedence) {
                    break;
                }

                var explicit = explicitBinaryOperator(token) != null;
                if (explicit) {
                    advance();
                }

                // Implicit multiplication has ordinary multiplicative
                // precedence. The right side is parsed tightly enough that
                // 2x^2 becomes 2*(x^2), while 2xy becomes (2*x)*y.
                var nextMin = (op == POWER) ? precedence : precedence + 1;
                var right = parseArithmeticExpression(nextMin);
                left = new BinaryNode(op, left, right);
            }

            return left;
        }

        function parsePrefix() {
            if (match(PLUS)) {
                return new UnaryNode(POSITIVE, parseArithmeticExpression(25));
            }

            if (match(MINUS)) {
                return new UnaryNode(NEGATE, parseArithmeticExpression(25));
            }

            if (match(NUMBER)) {
                var token = previous();
                return new NumberNode(Lang.toNumber(token.text));
            }

            if (match(LPAREN)) {
                var expression = parseLogicalExpression();
                expect(RPAREN, "Expected ')'");
                return expression;
            }

            if (match(IDENTIFIER)) {
                var name = previous().text;

                if (match(LPAREN)) {
                    var args = [];
                    if (!check(RPAREN)) {
                        args.add(parseLogicalExpression());

                        while (match(COMMA)) {
                            args.add(parseLogicalExpression());
                        }
                    }

                    expect(RPAREN, "Expected ')'");
                    return new FunctionCallNode(name, args);
                }

                if (name == "pi" || name == "e" || name == "tau") {
                    return new ConstantNode(name);
                }

                return new VariableNode(name);
            }

            throw new ParserError("Expected an expression", current().position);
        }

        function explicitBinaryOperator(token) {
            if (token.type == PLUS) {
                return ADD;
            }
            if (token.type == MINUS) {
                return SUBTRACT;
            }
            if (token.type == MULTIPLY) {
                return MULTIPLY;
            }
            if (token.type == DIVIDE) {
                return DIVIDE;
            }
            if (token.type == CARET) {
                return POWER;
            }
            return null;
        }

        function relationOperator(token) {
            if (token.type == EQUALS) {
                return EQUALS;
            }
            if (token.type == LESS) {
                return LESS;
            }
            if (token.type == GREATER) {
                return GREATER;
            }
            if (token.type == LESS_EQUAL) {
                return LESS_EQUAL;
            }
            if (token.type == GREATER_EQUAL) {
                return GREATER_EQUAL;
            }
            return null;
        }

        function isRelationOperator(token) {
            return relationOperator(token) != null;
        }

        function precedenceOf(operator) {
            if (operator == ADD || operator == SUBTRACT) {
                return 10;
            }
            if (operator == MULTIPLY || operator == DIVIDE) {
                return 20;
            }
            if (operator == POWER) {
                return 30;
            }
            return -1;
        }

        function startsExpression(token) {
            return token.type == NUMBER ||
                   token.type == IDENTIFIER ||
                   token.type == LPAREN;
        }

        function isFunctionDefinitionStart() {
            if (current().type != IDENTIFIER) {
                return false;
            }
            if (self.index + 1 >= self.tokens.size()) {
                return false;
            }
            if (self.tokens[self.index + 1].type != LPAREN) {
                return false;
            }

            var i = self.index + 2;
            if (self.tokens[i].type == RPAREN) {
                return self.index + 3 < self.tokens.size() &&
                       self.tokens[self.index + 3].type == EQUALS;
            }

            while (i < self.tokens.size()) {
                if (self.tokens[i].type != IDENTIFIER) {
                    return false;
                }
                i += 1;

                if (self.tokens[i].type == RPAREN) {
                    return i + 1 < self.tokens.size() &&
                           self.tokens[i + 1].type == EQUALS;
                }

                if (self.tokens[i].type != COMMA) {

                    return false;

                }
                i += 1;
            }

            return false;
        }

        function expectIdentifier(message) {
            if (!check(IDENTIFIER)) {
                throw new ParserError(message, current().position);
            }

            var token = current();
            advance();
            return token.text;
        }

        function isIdentifier(name) {
            return current().type == IDENTIFIER && current().text == name;
        }

        function current() {
            return self.tokens[self.index];
        }

        function previous() {
            return self.tokens[self.index - 1];
        }

        function advance() {
            var token = current();
            if (!check(EOF)) {
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
