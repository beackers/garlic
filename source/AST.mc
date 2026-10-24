module Garlic {
    enum NodeType {
        NUMBER,
        VARIABLE,
        CONSTANT,
        UNARY,
        BINARY,
        FUNCTION_CALL,
        RELATION,
        LOGICAL,
        FUNCTION_DEFINITION,
        STATEMENT
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

    enum RelationOperator {
        EQUALS,
        LESS,
        GREATER,
        LESS_EQUAL,
        GREATER_EQUAL
    }

    enum LogicalOperator {
        AND,
        OR
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

    class RelationNode extends Node {
        var operator;
        var left;
        var right;

        function initialize(operator, left, right) {
            Node.initialize(NodeType.RELATION);
            self.operator = operator;
            self.left = left;
            self.right = right;
        }
    }

    class LogicalNode extends Node {
        var operator;
        var left;
        var right;

        function initialize(operator, left, right) {
            Node.initialize(NodeType.LOGICAL);
            self.operator = operator;
            self.left = left;
            self.right = right;
        }
    }

    class FunctionDefinitionNode extends Node {
        var name;
        var parameters;
        var body;

        function initialize(name, parameters, body) {
            Node.initialize(NodeType.FUNCTION_DEFINITION);
            self.name = name;
            self.parameters = parameters;
            self.body = body;
        }
    }

    // A statement is the unit represented by one expression line.
    // It may contain an ordinary expression, relation, or function definition.
    // Restrictions are kept on the statement so graph/display semantics do not
    // leak into ordinary arithmetic expressions.
    class StatementNode extends Node {
        var expression;
        var restrictions;

        function initialize(expression, restrictions) {
            Node.initialize(NodeType.STATEMENT);
            self.expression = expression;
            self.restrictions = restrictions;
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
