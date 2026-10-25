module Garlic {
    enum NodeType {
        NODE_NUMBER,
        NODE_VARIABLE,
        NODE_CONSTANT,
        NODE_UNARY,
        NODE_BINARY,
        NODE_FUNCTION_CALL,
        NODE_RELATION,
        NODE_LOGICAL,
        NODE_FUNCTION_DEFINITION,
        NODE_STATEMENT
    }

    enum UnaryOperator {
        UNARY_NEGATE,
        UNARY_POSITIVE
    }

    enum BinaryOperator {
        BINARY_ADD,
        BINARY_SUBTRACT,
        BINARY_MULTIPLY,
        BINARY_DIVIDE,
        BINARY_POWER
    }

    enum RelationOperator {
        REL_EQUALS,
        REL_LESS,
        REL_GREATER,
        REL_LESS_EQUAL,
        REL_GREATER_EQUAL
    }

    enum LogicalOperator {
        LOGICAL_AND,
        LOGICAL_OR
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
            Node.initialize(NODE_NUMBER);
            self.value = value;
        }
    }

    class VariableNode extends Node {
        var name;

        function initialize(name) {
            Node.initialize(NODE_VARIABLE);
            self.name = name;
        }
    }

    class ConstantNode extends Node {
        var name;

        function initialize(name) {
            Node.initialize(NODE_CONSTANT);
            self.name = name;
        }
    }

    class UnaryNode extends Node {
        var operator;
        var operand;

        function initialize(operator, operand) {
            Node.initialize(NODE_UNARY);
            self.operator = operator;
            self.operand = operand;
        }
    }

    class BinaryNode extends Node {
        var operator;
        var left;
        var right;

        function initialize(operator, left, right) {
            Node.initialize(NODE_BINARY);
            self.operator = operator;
            self.left = left;
            self.right = right;
        }
    }

    class FunctionCallNode extends Node {
        var name;
        var arguments;

        function initialize(name, arguments) {
            Node.initialize(NODE_FUNCTION_CALL);
            self.name = name;
            self.arguments = arguments;
        }
    }

    class RelationNode extends Node {
        var operator;
        var left;
        var right;

        function initialize(operator, left, right) {
            Node.initialize(NODE_RELATION);
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
            Node.initialize(NODE_LOGICAL);
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
            Node.initialize(NODE_FUNCTION_DEFINITION);
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
            Node.initialize(NODE_STATEMENT);
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
