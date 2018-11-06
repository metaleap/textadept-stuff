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
        -- if `pipeBufText`, then the current buffer's selection (or if none, full content) is written to the command's own stdin
        { sh = 'fortune | cowsay' },
        { cmd = 'cowsay', pipeBufText = true },
        { cmd = 'figlet', pipeBufText = true },
        { cmd = 'cat', pipeBufText = true },
        { sh = 'rev | rev | cowsay', pipeBufText = true },
        { cmd = 'echo "Foo: §(foo) Name:§(_fileName) Bar:§(bar) Dir:§(_fileDir) Baz:§(baz) Full:§(_filePath) Full:§(foo)§(bar)§(baz)"' },
        { sh = 'git add -A && git commit -m "§(commitMsg)" && git push' },
}   -- etc..

events.connect(events.INITIALIZED, _M.metaleap_zentient.startUp)
```

but tweaked to _your_ needs of course.
