-- dbgbuf LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('dbgbuf')
local style = lexer.styles.default .. { italic = true, back = 0x686868 }

lex:add_rule('myany1', token(lexer.DEFAULT, lexer.any^1))
lex:add_style(lexer.DEFAULT, style)

lex:add_rule('myany2', token(lexer.DEFAULT, lexer.any))
lex:add_style(lexer.DEFAULT, style)

lex:add_rule('myany3', token(lexer.DEFAULT, lexer.any^1))
lex:add_style('myany3', style)

lex:add_rule('myany4', token(lexer.DEFAULT, lexer.any))
lex:add_style('myany4', style)

lex:add_rule('myany5', token('myany5', lexer.any^1))
lex:add_style('myany5', style)

lex:add_rule('myany6', token('myany6', lexer.any))
lex:add_style('myany6', style)

lex:add_rule('custom_whitespace', token('custom_whitespace', lexer.space^1))
lex:add_style('custom_whitespace', style)

 --Whitespace.
--lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

 --Keywords.
--lex:add_rule('keyword', token(lexer.KEYWORD, word_match{
--  'keyword1', 'keyword2', 'keyword3'
--}))

 --Identifiers.
--lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

 --Strings.
--local sq_str = lexer.range("'")
--local dq_str = lexer.range('"')
--lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

 --Comments.
--lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('#')))

 --Numbers.
--lex:add_rule('number', token(lexer.NUMBER, lexer.number))

 --Operators.
--lex:add_rule('operator', token(lexer.OPERATOR, S('+-*/%^=<>,.{}[]()')))

 --Fold points.
--lex:add_fold_point(lexer.KEYWORD, 'start', 'end')
--lex:add_fold_point(lexer.OPERATOR, '{', '}')
--lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('#'))

return lex
