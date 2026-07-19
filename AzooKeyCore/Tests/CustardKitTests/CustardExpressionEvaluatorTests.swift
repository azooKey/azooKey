import XCTest
@testable import CustardKit

final class CustardExpressionEvaluatorTests: XCTestCase {
    func testTokenizer() throws {
        let tokenizer = CustardExpressionTokenizer()
        do {
            let result = tokenizer.tokenize(expression: "not((state_a == 'normal') and state_b)")
            XCTAssertEqual(result, [.function(.not), .leftParen, .leftParen, .variable("state_a"), .operator(.equal), .stringLiteral("normal"), .rightParen, .operator(.and), .variable("state_b"), .rightParen])
        }
        do {
            // エスケープ
            let result = tokenizer.tokenize(expression: "'\\\\'")
            XCTAssertEqual(result, [.stringLiteral("\\")])
        }
        do {
            // 空白・カッコ
            let result = tokenizer.tokenize(expression: "'aa a(bbb)a'")
            XCTAssertEqual(result, [.stringLiteral("aa a(bbb)a")])
        }
        do {
            // 複雑なエスケープ
            let result = tokenizer.tokenize(expression: #"'\\aa\'a'"#)
            XCTAssertEqual(result, [.stringLiteral(#"\aa'a"#)])
        }
        do {
            let result = tokenizer.tokenize(expression: "true")
            XCTAssertEqual(result, [.boolLiteral(true)])
        }
        do {
            let result = tokenizer.tokenize(expression: "((state_a and 'normal' != state_c) xor state_b)")
            XCTAssertEqual(result, [.leftParen, .leftParen, .variable("state_a"), .operator(.and), .stringLiteral("normal"), .operator(.notEqual), .variable("state_c"), .rightParen, .operator(.xor), .variable("state_b"), .rightParen])
        }
        do {
            let tokens = tokenizer.tokenize(expression: "(not(toggle1) and toggle2) or (toggle1 and not(toggle2))")
            XCTAssertEqual(tokens, [.leftParen, .function(.not), .leftParen, .variable("toggle1"), .rightParen, .operator(.and), .variable("toggle2"), .rightParen, .operator(.or), .leftParen, .variable("toggle1"), .operator(.and), .function(.not), .leftParen, .variable("toggle2"), .rightParen, .rightParen])

        }
    }

    func testCompiler() throws {
        let tokenizer = CustardExpressionTokenizer()
        let compiler = CustardExpressionCompiler()
        do {
            let tokens = tokenizer.tokenize(expression: "true")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .boolLiteral(true))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "''value''")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .stringLiteral("'value'"))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "state_a")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .variable("state_a"))
        }
        do {
            let tokens = tokenizer.tokenize(expression: " true ")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .boolLiteral(true))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "((((state_a))))")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .variable("state_a"))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "not(state_a and true)")
            XCTAssertEqual(try compiler.compile(tokens: tokens), .function(.not, .operator(.and, .variable("state_a"), .boolLiteral(true))))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "not((state_a == 'normal') and state_b)")
            let result = try compiler.compile(tokens: tokens)
            XCTAssertEqual(result, .function(.not, .operator(.and, .operator(.equal, .variable("state_a"), .stringLiteral("normal")), .variable("state_b"))))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "state_a and 'normal' != state_c")
            XCTAssertThrowsError(try compiler.compile(tokens: tokens))
        }
        do {
            let tokens = tokenizer.tokenize(expression: "(not(toggle1) and toggle2) or (toggle1 and not(toggle2))")
            let compiledExpression = try compiler.compile(tokens: tokens)
            XCTAssertEqual(compiledExpression, .operator(.or, .operator(.and, .function(.not, .variable("toggle1")), .variable("toggle2")), .operator(.and, .variable("toggle1"), .function(.not, .variable("toggle2")))))
        }
    }

    struct EvaluatorContext: CustardExpressionEvaluatorContext {
        var initialValues: [String: ExpressionValue]
        func getValue(for key: String) -> ExpressionValue? {
            return initialValues[key]
        }
    }

    func testEvaluator() throws {
        let tokenizer = CustardExpressionTokenizer()
        let compiler = CustardExpressionCompiler()
        do {
            let evaluator = CustardExpressionEvaluator(context: EvaluatorContext(initialValues: [:]))
            let tokens = tokenizer.tokenize(expression: "true")
            let compiledExpression = try compiler.compile(tokens: tokens)
            XCTAssertEqual(try evaluator.evaluate(compiledExpression: compiledExpression), .bool(true))
        }
        do {
            let evaluator = CustardExpressionEvaluator(context: EvaluatorContext(initialValues: ["state_a": .string("normal"), "state_b": .bool(true)]))
            let tokens = tokenizer.tokenize(expression: "not((state_a == 'normal') and state_b)")
            let compiledExpression = try compiler.compile(tokens: tokens)
            XCTAssertEqual(try evaluator.evaluate(compiledExpression: compiledExpression), .bool(false))
        }
        do {
            let evaluator = CustardExpressionEvaluator(context: EvaluatorContext(initialValues: ["toggle1": .bool(true), "toggle2": .bool(false)]))
            let tokens = tokenizer.tokenize(expression: "(not(toggle1) and toggle2) or (toggle1 and not(toggle2))")
            let compiledExpression = try compiler.compile(tokens: tokens)
            XCTAssertEqual(try evaluator.evaluate(compiledExpression: compiledExpression), .bool(true))
        }
    }
}
