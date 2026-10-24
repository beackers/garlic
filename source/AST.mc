module Garlic {
    enum NodeType {
        NUMBER,
        VARIABLE,
        CONSTANT,
        UNARY,
        BINARY,
        FUNCTION_CALL
    }

    enum UnaryOperator {
        NEGATE,
        POSITIVE
    }

    enum BinaryOperator {
        ADD,
        SUBTRACT,
        MULTIPLY,
        DIVIDE,
        POWER
    }

    class Node {
        var type;

        function initialize(type) {
            self.type = type;
        }
    }

    class NumberNode extends Node {
        var value;

        function initialize(value) {
            Node.initialize(NodeType.NUMBER);
            self.value = value;
        }
    }

    class VariableNode extends Node {
        var name;

        function initialize(name) {
            Node.initialize(NodeType.VARIABLE);
            self.name = name;
        }
    }

    class ConstantNode extends Node {
        var name;

        function initialize(name) {
            Node.initialize(NodeType.CONSTANT);
            self.name = name;
        }
    }

    class UnaryNode extends Node {
        var operator;
        var operand;

        function initialize(operator, operand) {
            Node.initialize(NodeType.UNARY);
            self.operator = operator;
            self.operand = operand;
        }
    }

    class BinaryNode extends Node {
        var operator;
        var left;
        var right;

        function initialize(operator, left, right) {
            Node.initialize(NodeType.BINARY);
            self.operator = operator;
            self.left = left;
            self.right = right;
        }
    }

    class FunctionCallNode extends Node {
        var name;
        var arguments;

        function initialize(name, arguments) {
            Node.initialize(NodeType.FUNCTION_CALL);
            self.name = name;
            self.arguments = arguments;
        }
    }

    class ParserError {
        var message;
        var position;

        function initialize(message, position) {
            self.message = message;
            self.position = position;
        }
    }
}
