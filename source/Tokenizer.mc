using Toybox.Lang as Lang;

module Garlic {
    enum TokenType {
        TOKEN_NUMBER,
        TOKEN_IDENTIFIER,
        TOKEN_PLUS,
        TOKEN_MINUS,
        TOKEN_MULTIPLY,
        TOKEN_DIVIDE,
        TOKEN_CARET,
        TOKEN_LPAREN,
        TOKEN_RPAREN,
        TOKEN_COMMA,
        TOKEN_EQUALS,
        TOKEN_LESS,
        TOKEN_GREATER,
        TOKEN_LESS_EQUAL,
        TOKEN_GREATER_EQUAL,
        TOKEN_LBRACE,
        TOKEN_RBRACE,
        EOF
    }

    class Token {
        var type;
        var text;
        var position;

        function initialize(type, text, position) {
            self.type = type;
            self.text = text;
            self.position = position;
        }

        function toString() {
            return self.type.toString() + "(" + self.text + ")";
        }
    }

    class Lexer {
        var input;
        var index;

        function initialize(input) {
            self.input = input;
            self.index = 0;
        }

        function tokenize() {
            var tokens = [];
            while (true) {
                var token = nextToken();
                tokens.add(token);
                if (token.type == EOF) {
                    break;
                }
            }
            return tokens;
        }

        function nextToken() {
            skipWhitespace();

            if (self.index >= self.input.length()) {
                return new Token(TOKEN_EOF, "", self.index);
            }

            var start = self.index;
            var c = self.input[start];

            if (isDigit(c) || c == ".") {
                return readNumber();
            }

            if (isIdentifierStart(c)) {
                return readIdentifier();
            }

            self.index += 1;

            if (c == "+") {

                return new Token(TOKEN_PLUS, "+", start);

            }
            if (c == "-") {
                return new Token(TOKEN_MINUS, "-", start);
            }
            if (c == "*") {
                return new Token(TOKEN_MULTIPLY, "*", start);
            }
            if (c == "/") {
                return new Token(TOKEN_DIVIDE, "/", start);
            }
            if (c == "^") {
                return new Token(TOKEN_CARET, "^", start);
            }
            if (c == "(") {
                return new Token(TOKEN_LPAREN, "(", start);
            }
            if (c == ")") {
                return new Token(TOKEN_RPAREN, ")", start);
            }
            if (c == ",") {
                return new Token(TOKEN_COMMA, ",", start);
            }
            if (c == "=") {
                return new Token(TOKEN_EQUALS, "=", start);
            }

            if (c == "<") {
                if (peek("=")) {
                    self.index += 1;
                    return new Token(TOKEN_LESS_EQUAL, "<=", start);
                }
                return new Token(TOKEN_LESS, "<", start);
            }

            if (c == ">") {
                if (peek("=")) {
                    self.index += 1;
                    return new Token(TOKEN_GREATER_EQUAL, ">=", start);
                }
                return new Token(TOKEN_GREATER, ">", start);
            }

            if (c == "{") {
                return new Token(TOKEN_LBRACE, "{", start);
            }
            if (c == "}") {
                return new Token(TOKEN_RBRACE, "}", start);
            }

            throw new ParserError("Unexpected character '" + c + "'", start);
        }

        function skipWhitespace() {
            while (self.index < self.input.length()) {
                var c = self.input[self.index];
                if (c == " " || c == "\t" || c == "\n" || c == "\r") {
                    self.index += 1;
                } else {
                    break;
                }
            }
        }

        function readNumber() {
            var start = self.index;
            var sawDigit = false;
            var sawDot = false;

            while (self.index < self.input.length()) {
                var c = self.input[self.index];

                if (isDigit(c)) {
                    sawDigit = true;
                    self.index += 1;
                } else if (c == "." && !sawDot) {
                    sawDot = true;
                    self.index += 1;
                } else {
                    break;
                }
            }

            if (!sawDigit) {
                throw new ParserError("Expected a number", start);
            }

            // Desmos accepts scientific notation such as 1e6 and 2.5e-3.
            if (self.index < self.input.length() &&
                (self.input[self.index] == "e" || self.input[self.index] == "E")) {
                var exponentStart = self.index;
                self.index += 1;

                if (self.index < self.input.length() &&
                    (self.input[self.index] == "+" || self.input[self.index] == "-")) {
                    self.index += 1;
                }

                var exponentDigits = self.index;
                while (self.index < self.input.length() && isDigit(self.input[self.index])) {
                    self.index += 1;
                }

                if (self.index == exponentDigits) {
                    throw new ParserError("Expected digits after exponent", exponentStart);
                }
            }

            return new Token(TOKEN_NUMBER, self.input.substring(start, self.index), start);
        }

        function readIdentifier() {
            var start = self.index;
            self.index += 1;

            while (self.index < self.input.length() && isIdentifierPart(self.input[self.index])) {
                self.index += 1;
            }

            return new Token(TOKEN_IDENTIFIER, self.input.substring(start, self.index), start);
        }

        function peek(expected) {
            return self.index < self.input.length() && self.input[self.index] == expected;
        }

        function isDigit(c) {
            return c >= "0" && c <= "9";
        }

        function isIdentifierStart(c) {
            return (c >= "a" && c <= "z") ||
                   (c >= "A" && c <= "Z") ||
                   c == "_";
        }

        function isIdentifierPart(c) {
            return isIdentifierStart(c) || isDigit(c);
        }
    }
}
