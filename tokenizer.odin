package basic

import "core:fmt"
import "core:strings"

Lex :: struct {
    data: []u8,
    offset: int,
    tokens: [dynamic]Token,
}

Token :: struct {
    offset: int,
    type: Token_type,
    text: string,
}

Token_type :: enum {
	EOF, 
	NEWLINE,
	NUMBER,
	IDENT,
	STRING,
	// Keywords.
	LABEL,
	GOTO,
	PRINT,
	INPUT,
	LET,
	IF,
    ELSEIF,
    ELSE,
	FOR,
    TO,
    END,
	// Operators.
	EQ,  
	PLUS,
	MINUS,
	ASTERISK,
	SLASH,
	EQEQ,
	NOTEQ,
	LT,
	LTEQ,
	GT,
	GTEQ,
}

main :: proc() {
    input := "a=69420\nmyIdentifier1\nif a != 69420 print \"rofl\"\nelse goto \"myIdentifier1\"/"
    lex := lexer_init(input)
    scan_tokens(&lex)
    for tk in lex.tokens {
        fmt.println(tk)
    }
}

lexer_init :: proc(input: string) -> Lex {
    lex := Lex{
        data = transmute([]u8)input,
        tokens = make([dynamic]Token),
    }
    return lex
}

next :: proc(lx: ^Lex) -> u8 #no_bounds_check {
    next: u8
    if lx.offset < len(lx.data) {
        next = lx.data[lx.offset]
        lx.offset += 1
    }
    return next
}

peek :: proc(lx: ^Lex) -> u8 #no_bounds_check {
    if lx.offset + 1 > len(lx.data) {
        return 0
    } else {
    return lx.data[lx.offset]
    }
}

scan_tokens :: proc(lx: ^Lex) {
    for !is_at_end(lx) { get_token(lx) }
    append(&lx.tokens, Token{offset = lx.offset, type = .EOF})
}

get_token :: proc(lx: ^Lex) {
    char := next(lx)
    seen_dot: bool = false

    if is_whitespace(char) {return} // do nothing it's not a token
    start := lx.offset - 1
    switch char {
        case '+':  append(&lx.tokens, Token{start, .PLUS, "+"})
        case '-':  append(&lx.tokens, Token{start, .MINUS, "-"})
        case '*':  append(&lx.tokens, Token{start, .ASTERISK, "*"})
        case '/':  append(&lx.tokens, Token{start, .SLASH, "/"})
        case '=':
            if peek(lx) == '=' {
                append(&lx.tokens, Token{start, .EQEQ, "=="})
                next(lx)
            } else {
                append(&lx.tokens, Token{start, .EQ, "="})
            }
        case '>':
            if peek(lx) == '=' {
                append(&lx.tokens, Token{start, .GTEQ, ">="})
                next(lx)
            } else {
                append(&lx.tokens, Token{start, .GT, ">"})
            }
        case '<':
            if peek(lx) == '=' {
                append(&lx.tokens, Token{start, .LTEQ, "<="})
                next(lx)
            } else {
                append(&lx.tokens, Token{start, .LT, "<"})
            }
        case '!':
            if peek(lx) == '=' {
                append(&lx.tokens, Token{start, .NOTEQ, "!="})
                next(lx)
            } else {
                abort(fmt.tprintf("Expected !=, got %c", char))
            }
        case '#':
            for peek(lx) != '\n' {
                next(lx)
            }
        case '"':
            for peek(lx) != '"' {
                next(lx)
                if is_at_end(lx) {
                    next(lx)
                    break
                }
            }
            append(&lx.tokens, Token{start, .STRING, cast(string)lx.data[start+1:lx.offset]})
            next(lx)
        case '0'..='9':
            for is_digit(peek(lx)) || is_dot(peek(lx)) {
                if is_dot(peek(lx)) == true && seen_dot == true { 
                    abort(fmt.tprintf("Expected ., got .."))
                }
                if is_dot(peek(lx)) == true && seen_dot != true {
                    seen_dot = true
                }
                next(lx)
                if is_at_end(lx) {
                    next(lx)
                    break
                }
            }
            append(&lx.tokens, Token{start, .NUMBER, cast(string)lx.data[start:lx.offset]})
            next(lx)
        case '.':
            seen_dot = true
            if !(is_dot(peek(lx))) {
                if is_digit(next(lx)) {
                    for is_digit(peek(lx)) {
                        next(lx)
                        if is_at_end(lx) {
                            next(lx)
                            break
                        }
                    }
                }
                if start != lx.offset {
                    append(&lx.tokens, Token{start, .NUMBER, cast(string)lx.data[start:lx.offset]})
                } else {
                    append(&lx.tokens, Token{start, .IDENT, "."})
                }
            }
            if is_dot(peek(lx)) && seen_dot == true {
                abort(fmt.tprintf("Expected ., got .."))
            }
            next(lx)
        case 'a'..='z', 'A'..='Z':
            for is_alphanumeric(peek(lx)) {
                next(lx)
                if is_at_end(lx) {
                    next(lx)
                    break
                }
            }
            append(&lx.tokens, Token{start, tokenize(cast(string)lx.data[start:lx.offset]), cast(string)lx.data[start:lx.offset]})
        // default case
        case: abort(fmt.tprintf("Unknown token: %c", char))
    }
}

abort :: proc(s: string) {
    assert(false, fmt.tprintf("\nLexer error!\t%s", s))
}

// reverse the case check, it's returning a token_type not a string !!!
tokenize :: proc(s: string) -> Token_type {
    switch s {
        case "goto": return .GOTO
        case "print": return .PRINT
        case "input": return .INPUT
        case "let": return .LET
        case "if": return .IF
        case "elseif": return .ELSEIF
        case "else": return .ELSE
        case "for": return .FOR
        case "to": return .TO
        case "end": return .END
        case: return .IDENT
    }
}

is_alpha :: proc(c: u8) -> bool {
    r: bool
    switch c {
        case 'a'..='z', 'A'..='Z': return true
        case: return false
    }
}

is_alphanumeric :: proc(c: u8) -> bool {
    if is_digit(c) {return true} else if is_alpha(c) {return true} else {return false}
}

is_whitespace :: proc(c: u8) -> bool {
    return c == ' ' || c == '\n' || c == '\r' || c == '\t'
}

is_digit :: proc(c: u8) -> bool {
    r: bool
    for i in '0'..='9' { if cast(rune)c == i {return true} }
    return false
}

is_dot :: proc(c: u8) -> bool {
    r: bool
    if cast(rune)c == '.' {return true} else {return false}
}

is_at_end :: proc(lx: ^Lex) -> bool {
    return lx.offset >= len(lx.data)
}
