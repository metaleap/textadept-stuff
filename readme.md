Add to your `~/.textadept/init.lua` like this:

```lua
_M.metaleap_zentient = require 'metaleap_zentient'

-- _M.metaleap_zentient.langProgs['go'] = 'zentient-go'
-- _M.metaleap_zentient.langProgs['hs'] = 'zentient-hs'
-- etc..

_M.metaleap_zentient.favDirs = {
    { '~/mycode/go', '.go' },
    { '~/mycode/web', '' },
    { '~/mycode/haskell', 'src .hs' },
}   -- etc..

_M.metaleap_zentient.favCmds = {
        -- use `cmd` for one-command-plus-args, or `sh` for pipes / env-vars / multiple-commands etc.
        -- if optional `stdin` field is `true`, then the current buffer's selection (or if none, full content) is written to the command's own stdin
        -- optionally add `stdout`, an object with optional bool fields:
        --   - `openBuf` (if new buffer-tab should open automatically where all output is written to)
        --   - `lnNotify` (if every output line should be added to the notifications menu)
        -- optionally add `stderr` with the same notation, or `true` to reuse `stdout` settings
        { sh = 'fortune | cowsay' },
        { cmd = 'cowsay', stdin = true },
        { cmd = 'figlet', stdin = true },
        { cmd = 'cat', stdin = true },
        { sh = 'rev | rev | cowsay', stdin = true },
        { cmd = 'echo "Foo: §(foo) Name:§(_fileName) Bar:§(bar) Dir:§(_fileDir) Baz:§(baz) Full:§(_filePath) Full:§(foo)§(bar)§(baz)"' },
        { sh = 'git add -A && git commit -m "§(commitMsg)" && git push' },
}   -- etc..

    _M.metaleap_zentient.init()
```

but tweaked to _your_ needs of course.
