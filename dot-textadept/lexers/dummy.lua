local lexer = require('lexer')

local lex = lexer.new('dummy')
local style = lexer.styles.default .. { italics = true, fore = lexer.colors.dark_grey }

lex:add_rule('my_any', lexer.token('my_any', lexer.any^1))
lex:add_style('my_any', style)

return lex
