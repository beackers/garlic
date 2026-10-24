# garlic

A powerful calculator built for Garmin devices.

## Bootstrap

Garlic currently starts with the expression engine rather than the watch UI.

    source text
        -> Lexer
        -> Token stream
        -> Pratt parser
        -> AST
        -> Evaluator

The parser is deliberately separated from Garmin UI code so the same expression
tree can later power graphing, symbolic differentiation, numerical methods,
function definitions, and restrictions.

### Current syntax target

Desmos-like mathematical input:

- `+ - * /`
- `^`
- parentheses
- implicit multiplication: `2x`, `2(x+1)`, `(x+1)(x-1)`, `2sin(x)`
- constants: `pi`, `e`
- variables
- function calls: `sin`, `cos`, `tan`, `sqrt`, `ln`, `abs`

Restrictions, piecewise expressions, user-defined functions, graphing, and
symbolic differentiation are intentionally next-layer work.

The immediate goal is to make expressions such as

    2sin(x)^2 + 3(x - 1)

parse into the correct tree reliably.

## Source

- `source/Tokenizer.mc` — lexical analysis
- `source/AST.mc` — expression-tree nodes
- `source/Parser.mc` — Pratt parser and implicit multiplication
- `source/Evaluator.mc` — numeric evaluation
- `source/GarlicTest.mc` — initial parser smoke tests
