local lexer = require('lexer')

local lex = lexer.new('dbgbuf')
local style = lexer.styles.default .. { italics = true, bold = true, fore = lexer.colors.grey }

lex:add_rule('myany1', lexer.token('myany1', lexer.any^1))
lex:add_style('myany1', style)

return lex
