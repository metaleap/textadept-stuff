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
    { 'fortune | cowsay', false },
    { 'cat', true }, -- `true` to pipe current-buffer's content (or selection) to this command

    -- named-vars via §(myName) -- will prompt user unless predefined autos (like the _file* names below)
    { 'echo "Foo: §(foo) Name:§(_fileName) Bar:§(bar) Dir:§(_fileDir) Baz:§(baz) Full:§(_filePath)"',
        false },
}   -- etc..

events.connect(events.INITIALIZED, _M.metaleap_zentient.startUp)
```

but tweaked to _your_ needs of course.
