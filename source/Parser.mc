using Toybox.Lang as Lang;

module Garlic {
    // Pratt parser for Garlic's Desmos-like expression language.
    //
    // Precedence, from low to high:
    //   LOGICAL_OR
    //   LOGICAL_AND
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
            while (match(TOKEN_LBRACE)) {
                restrictions.add(parseLogicalExpression());
                expect(TOKEN_RBRACE, "Expected '}'");
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
            expect(TOKEN_LPAREN, "Expected '(' after function name");

            var parameters = [];
            if (!check(TOKEN_RPAREN)) {
                parameters.add(expectIdentifier("Expected parameter name"));

                while (match(TOKEN_COMMA)) {
                    parameters.add(expectIdentifier("Expected parameter name"));
                }
            }

            expect(TOKEN_RPAREN, "Expected ')' after parameters");
            expect(TOKEN_EQUALS, "Expected '=' in function definition");

            var body = parseLogicalExpression();
            return new FunctionDefinitionNode(name, parameters, body);
        }

        function parseLogicalExpression() {
            var left = parseRelationExpression();

            while (isIdentifier("or")) {
                advance();
                left = new LogicalNode(LOGICAL_OR, left, parseRelationExpression());
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
            // Represent the chain as LOGICAL_AND of adjacent comparisons.
            while (isRelationOperator(current())) {
                var op = relationOperator(current());
                advance();
                var right = parseArithmeticExpression(0);
                relation = new LogicalNode(
                    LOGICAL_AND,
                    relation,
                    new RelationNode(op, relationRight(relation), right)
                );
            }

            while (isIdentifier("and")) {
                advance();
                relation = new LogicalNode(
                    LOGICAL_AND,
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
            if (node.type == NODE_RELATION) {
                return node.right;
            }

            if (node.type == NODE_LOGICAL && node.operator == LOGICAL_AND) {
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
                    op = BINARY_MULTIPLY;
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
                var nextMin = (op == BINARY_POWER) ? precedence : precedence + 1;
                var right = parseArithmeticExpression(nextMin);
                left = new BinaryNode(op, left, right);
            }

            return left;
        }

        function parsePrefix() {
            if (match(TOKEN_PLUS)) {
                return new UnaryNode(POSITIVE, parseArithmeticExpression(25));
            }

            if (match(TOKEN_MINUS)) {
                return new UnaryNode(UNARY_NEGATE, parseArithmeticExpression(25));
            }

            if (match(TOKEN_NUMBER)) {
                var token = previous();
                return new NumberNode(Lang.toNumber(token.text));
            }

            if (match(TOKEN_LPAREN)) {
                var expression = parseLogicalExpression();
                expect(TOKEN_RPAREN, "Expected ')'");
                return expression;
            }

            if (match(TOKEN_IDENTIFIER)) {
                var name = previous().text;

                if (match(TOKEN_LPAREN)) {
                    var args = [];
                    if (!check(TOKEN_RPAREN)) {
                        args.add(parseLogicalExpression());

                        while (match(TOKEN_COMMA)) {
                            args.add(parseLogicalExpression());
                        }
                    }

                    expect(TOKEN_RPAREN, "Expected ')'");
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
            if (token.type == TOKEN_PLUS) {
                return BINARY_ADD;
            }
            if (token.type == TOKEN_MINUS) {
                return BINARY_SUBTRACT;
            }
            if (token.type == TOKEN_MULTIPLY) {
                return BINARY_MULTIPLY;
            }
            if (token.type == BINARY_DIVIDE) {
                return BINARY_DIVIDE;
            }
            if (token.type == TOKEN_CARET) {
                return BINARY_POWER;
            }
            return null;
        }

        function relationOperator(token) {
            if (token.type == TOKEN_EQUALS) {
                return REL_EQUALS;
            }
            if (token.type == TOKEN_LESS) {
                return REL_LESS;
            }
            if (token.type == TOKEN_GREATER) {
                return REL_GREATER;
            }
            if (token.type == TOKEN_LESS_EQUAL) {
                return REL_LESS_EQUAL;
            }
            if (token.type == TOKEN_GREATER_EQUAL) {
                return REL_GREATER_EQUAL;
            }
            return null;
        }

        function isRelationOperator(token) {
            return relationOperator(token) != null;
        }

        function precedenceOf(operator) {
            if (operator == BINARY_ADD || operator == BINARY_SUBTRACT) {
                return 10;
            }
            if (operator == BINARY_MULTIPLY || operator == BINARY_DIVIDE) {
                return 20;
            }
            if (operator == BINARY_POWER) {
                return 30;
            }
            return -1;
        }

        function startsExpression(token) {
            return token.type == TOKEN_NUMBER ||
                   token.type == TOKEN_IDENTIFIER ||
                   token.type == TOKEN_LPAREN;
        }

        function isFunctionDefinitionStart() {
            if (current().type != TOKEN_IDENTIFIER) {
                return false;
            }
            if (self.index + 1 >= self.tokens.size()) {
                return false;
            }
            if (self.tokens[self.index + 1].type != TOKEN_LPAREN) {
                return false;
            }

            var i = self.index + 2;
            if (self.tokens[i].type == TOKEN_RPAREN) {
                return self.index + 3 < self.tokens.size() &&
                       self.tokens[self.index + 3].type == TOKEN_EQUALS;
            }

            while (i < self.tokens.size()) {
                if (self.tokens[i].type != TOKEN_IDENTIFIER) {
                    return false;
                }
                i += 1;

                if (self.tokens[i].type == TOKEN_RPAREN) {
                    return i + 1 < self.tokens.size() &&
                           self.tokens[i + 1].type == TOKEN_EQUALS;
                }

                if (self.tokens[i].type != TOKEN_COMMA) {

                    return false;

                }
                i += 1;
            }

            return false;
        }

        function expectIdentifier(message) {
            if (!check(TOKEN_IDENTIFIER)) {
                throw new ParserError(message, current().position);
            }

            var token = current();
            advance();
            return token.text;
        }

        function isIdentifier(name) {
            return current().type == TOKEN_IDENTIFIER && current().text == name;
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
