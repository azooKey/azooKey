public enum OperatorType: Sendable {
    case equal
    case notEqual
    case and
    case or
    case xor

    init?(_ value: String) {
        switch value {
        case "and":
            self = .and
        case "or":
            self = .or
        case "xor":
            self = .xor
        case "==":
            self = .equal
        case "!=":
            self = .notEqual
        default:
            return nil
        }
    }
}

public enum FunctionType: Sendable {
    case not

    init?(_ value: String) {
        switch value {
        case "not":
            self = .not
        default:
            return nil
        }
    }
}

public enum Token: Sendable, Equatable {
    case stringLiteral(String)
    case boolLiteral(Bool)
    case variable(String)
    case leftParen
    case rightParen
    case `operator`(OperatorType)
    case function(FunctionType)
}

public struct CustardExpressionTokenizer: Sendable {
    public init() {}

    public func tokenize(expression: String) -> [Token] {
        // 演算子の左右には空白を必須にするルールにする
        var stringTokens: [String] = []
        var escape = false
        var inStringLiteral = false
        var currentToken = ""
        for character in expression {
            if character == "\\" {
                if escape {
                    currentToken.append(character)
                    escape = false
                } else {
                    escape = true
                }
                continue
            }
            if character == "'" {
                currentToken.append(character)
                if escape {
                    escape = false
                } else {
                    inStringLiteral.toggle()
                }
                continue
            }
            if escape {
                escape = false
                currentToken.append("\\")
            }
            if !inStringLiteral, character == "(" || character == ")" {
                if !currentToken.isEmpty {
                    stringTokens.append(currentToken)
                    currentToken.removeAll()
                }
                stringTokens.append(String(character))
                continue
            }
            if !inStringLiteral, character == " " {
                if !currentToken.isEmpty {
                    stringTokens.append(currentToken)
                    currentToken.removeAll()
                }
                continue
            }
            currentToken.append(character)
        }
        if !currentToken.isEmpty {
            stringTokens.append(currentToken)
        }
        var tokens: [Token] = []

        for stringToken in stringTokens {
            if let operatorTyoe = OperatorType(stringToken) {
                tokens.append(.operator(operatorTyoe))
            } else if let functionType = FunctionType(stringToken) {
                tokens.append(.function(functionType))
            } else if stringToken.first == "'" && stringToken.last == "'" {
                print(expression, stringToken)
                tokens.append(.stringLiteral(String(stringToken.dropFirst().dropLast())))
            } else if stringToken == "true" {
                tokens.append(.boolLiteral(true))
            } else if stringToken == "false" {
                tokens.append(.boolLiteral(false))
            } else if stringToken == "(" {
                tokens.append(.leftParen)
            } else if stringToken == ")" {
                tokens.append(.rightParen)
            } else {
                tokens.append(.variable(stringToken))
            }
        }

        return tokens
    }
}

public indirect enum CompiledExpression: Sendable, Equatable {
    case stringLiteral(String)
    case boolLiteral(Bool)
    case variable(String)
    case `operator`(OperatorType, CompiledExpression, CompiledExpression)
    case function(FunctionType, CompiledExpression)
}

public struct CustardExpressionCompiler: Sendable {
    public init() {}

    public enum ParenToken: Sendable {
        case tokens([ParenToken])
        case rawToken(Token)
        case unmatchParen([ParenToken])

        mutating func append(_ token: Token) throws {
            switch self {
            case .tokens(var parenTokens):
                switch parenTokens.last {
                case .none, .tokens, .rawToken:
                    // 何もない場合、tokensの場合、rawTokenの場合は追加する
                    switch token {
                    case .leftParen:
                        parenTokens.append(.unmatchParen([]))
                        self = .tokens(parenTokens)
                    case .rightParen:
                        throw CompileError.unmatchedParen
                    default:
                        parenTokens.append(.rawToken(token))
                        self = .tokens(parenTokens)
                    }
                case .unmatchParen:
                    // unmatchParenの場合はunmatchParenの中の最後の要素に追加する
                    try parenTokens[parenTokens.endIndex - 1].append(token)
                    self = .tokens(parenTokens)
                }
            case .rawToken:
                // rawTokenに対してappendを呼んではならない
                throw CompileError.unknown
            case .unmatchParen(var parenTokens):
                switch parenTokens.last {
                case .none, .tokens, .rawToken:
                    // 何もない場合、tokensの場合、rawTokenの場合は追加する
                    // rightParenの場合は完成させる
                    switch token {
                    case .leftParen:
                        parenTokens.append(.unmatchParen([]))
                        self = .unmatchParen(parenTokens)
                    case .rightParen:
                        // 完成
                        self = .tokens(parenTokens)
                    default:
                        parenTokens.append(.rawToken(token))
                        self = .unmatchParen(parenTokens)
                    }
                case .unmatchParen:
                    try parenTokens[parenTokens.endIndex - 1].append(token)
                    self = .unmatchParen(parenTokens)
                }
            }
        }
    }

    public enum CompileError: Sendable, Error {
        case unmatchedParen
        case nonOperator
        case nonFunction
        case misplacedOperator
        case misplacedFunction
        case tooMuchValue([ParenToken])
        case emptyParen
        case unknown
    }

    func parseParenTokens(parenToken: ParenToken) throws -> CompiledExpression {
        switch parenToken {
        case  let .tokens(parenTokens):
            /*
             - 演算子が含まれている場合：演算子の左右を再解析
             - 含まれていない場合：長さ2なら関数として解析、1ならそのまま返却
             */
            let operatorTokenIndices = parenTokens.indices.filter { index in
                if case let .rawToken(parenToken) = parenTokens[index],
                   case .operator = parenToken {
                    return true
                }
                return false
            }
            if operatorTokenIndices.count == 1 {
                // 演算
                let index = operatorTokenIndices[0]
                guard case let .rawToken(parenToken) = parenTokens[index],
                      case let .operator(type) = parenToken else {
                    throw CompileError.unknown
                }
                guard index != 0 || index != parenTokens.endIndex - 1 else {
                    throw CompileError.misplacedOperator
                }
                return .operator(
                    type,
                    try parseParenTokens(parenToken: .tokens(Array(parenTokens[...(index - 1)]))),
                    try parseParenTokens(parenToken: .tokens(Array(parenTokens[(index + 1)...])))
                )
            } else if operatorTokenIndices.count == 0 {
                // 関数またはリテラル、ステート
                // 関数が期待される
                if parenTokens.count == 2 {
                    guard case let .rawToken(token) = parenTokens[0],
                          case let .function(type) = token else {
                        throw CompileError.nonFunction
                    }
                    return .function(type, try parseParenTokens(parenToken: parenTokens[1]))
                }
                // 単なる値と期待される
                if parenTokens.count == 1 {
                    return try parseParenTokens(parenToken: parenTokens[0])
                }
                // 1つもない場合はエラー
                throw CompileError.unknown
            } else {
                throw CompileError.misplacedOperator
            }
        case let .rawToken(token):
            switch token {
            case .stringLiteral(let value):
                return .stringLiteral(value)
            case .boolLiteral(let value):
                return .boolLiteral(value)
            case .variable(let name):
                return .variable(name)
            case .leftParen, .rightParen:
                throw CompileError.unmatchedParen
            case .operator:
                throw CompileError.misplacedOperator
            case .function:
                throw CompileError.misplacedFunction
            }
        case .unmatchParen:
            throw CompileError.unmatchedParen
        }
    }

    public func compile(tokens: [Token]) throws -> CompiledExpression {
        var parenToken = ParenToken.tokens([])
        // まずカッコで区切る
        for token in tokens {
            try parenToken.append(token)
        }
        // パースを実施する
        return try parseParenTokens(parenToken: parenToken)
    }
}

public enum ExpressionValue: Sendable, Equatable {
    case string(String)
    case bool(Bool)
}

public protocol CustardExpressionEvaluatorContext: Sendable {
    func getValue(for key: String) -> ExpressionValue?
}

public struct CustardExpressionEvaluator<Context: CustardExpressionEvaluatorContext>: Sendable {
    public init(context: Context) {
        self.context = context
    }

    public enum EvaluationError: Sendable, Error {
        case typeMismatch
        case uninitializedVariable
    }

    var context: Context

    public func evaluate(compiledExpression: CompiledExpression) throws -> ExpressionValue {
        switch compiledExpression {
        case let .boolLiteral(value):
            return .bool(value)
        case let .stringLiteral(value):
            return .string(value)
        case let .variable(name):
            if let contextValue = context.getValue(for: name) {
                return contextValue
            } else {
                throw EvaluationError.uninitializedVariable
            }
        case let .function(type, expression):
            let argument = try evaluate(compiledExpression: expression)
            switch type {
            case .not:
                guard case let .bool(value) = argument else {
                    throw EvaluationError.typeMismatch
                }
                return .bool(!value)
            }
        case let .operator(type, leftExpression, rightExpression):
            let lhs = try evaluate(compiledExpression: leftExpression)
            let rhs = try evaluate(compiledExpression: rightExpression)
            switch type {
            case .and:
                guard case let .bool(lValue) = lhs,
                      case let .bool(rValue) = rhs else {
                    throw EvaluationError.typeMismatch
                }
                return .bool(lValue && rValue)
            case .or:
                guard case let .bool(lValue) = lhs,
                      case let .bool(rValue) = rhs else {
                    throw EvaluationError.typeMismatch
                }
                return .bool(lValue || rValue)
            case .xor:
                guard case let .bool(lValue) = lhs,
                      case let .bool(rValue) = rhs else {
                    throw EvaluationError.typeMismatch
                }
                return .bool(lValue != rValue)
            case .equal:
                if case let .bool(lValue) = lhs {
                    guard case let .bool(rValue) = rhs else {
                        throw EvaluationError.typeMismatch
                    }
                    return .bool(lValue == rValue)
                }
                if case let .string(lValue) = lhs {
                    guard case let .string(rValue) = rhs else {
                        throw EvaluationError.typeMismatch
                    }
                    return .bool(lValue == rValue)
                }
                throw EvaluationError.typeMismatch
            case .notEqual:
                if case let .bool(lValue) = lhs {
                    guard case let .bool(rValue) = rhs else {
                        throw EvaluationError.typeMismatch
                    }
                    return .bool(lValue != rValue)
                }
                if case let .string(lValue) = lhs {
                    guard case let .string(rValue) = rhs else {
                        throw EvaluationError.typeMismatch
                    }
                    return .bool(lValue != rValue)
                }
                throw EvaluationError.typeMismatch
            }
        }
    }
}
