using Toybox.Math as Math;

module Garlic {
    class Environment {
        var variables;
        var functions;

        function initialize() {
            variables = {};
            functions = {};
        }

        function setVariable(name, value) {
            variables[name] = value;
        }

        function getVariable(name) {
            return variables[name];
        }

        function hasVariable(name) {
            return variables.hasKey(name);
        }
    }

    class Evaluator {
        var environment;

        function initialize(environment) {
            self.environment = environment;
        }

        function evaluate(node) {
            if (node.type == NUMBER) {
                return node.value;
            }

            if (node.type == CONSTANT) {
                if (node.name == "pi") {
                    return Math.PI;
                }
                if (node.name == "e") {
                    return Math.E;
                }
                throw new ParserError("Unknown constant '" + node.name + "'", 0);
            }

            if (node.type == VARIABLE) {
                if (!environment.hasVariable(node.name)) {
                    throw new ParserError("Undefined variable '" + node.name + "'", 0);
                }
                return environment.getVariable(node.name);
            }

            if (node.type == UNARY) {
                var value = evaluate(node.operand);
                if (node.operator == NEGATE) {
                    return -value;
                }
                return value;
            }

            if (node.type == BINARY) {
                var left = evaluate(node.left);
                var right = evaluate(node.right);

                if (node.operator == ADD) {

                    return left + right;

                }
                if (node.operator == SUBTRACT) {
                    return left - right;
                }
                if (node.operator == MULTIPLY) {
                    return left * right;
                }
                if (node.operator == DIVIDE) {
                    return left / right;
                }
                if (node.operator == POWER) {
                    return Math.pow(left, right);
                }
            }

            if (node.type == FUNCTION_CALL) {
                return evaluateFunction(node.name, node.arguments);
            }

            throw new ParserError("Unknown expression node", 0);
        }

        function evaluateFunction(name, args) {
            if (args.size() != 1) {
                throw new ParserError("Function '" + name + "' expects one argument", 0);
            }

            var x = evaluate(args[0]);

            if (name == "sin") {

                return Math.sin(x);

            }
            if (name == "cos") {
                return Math.cos(x);
            }
            if (name == "tan") {
                return Math.tan(x);
            }
            if (name == "sqrt") {
                return Math.sqrt(x);
            }
            if (name == "ln") {
                return Math.log(x);
            }
            if (name == "abs") {
                return Math.abs(x);
            }

            throw new ParserError("Unknown function '" + name + "'", 0);
        }
    }
}
