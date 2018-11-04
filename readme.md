Add to `~/.textadept/init.lua` like this:

```lua
_M.metaleap_zentient = require 'metaleap_zentient'

-- _M.metaleap_zentient.langProgs['go'] = 'zentient-go'
-- _M.metaleap_zentient.langProgs['hs'] = 'zentient-hs'
-- etc..

_M.metaleap_zentient.favDirs['~/mycode/go'] = '.go'
_M.metaleap_zentient.favDirs['~/mycode/web'] = ''
-- etc..

_M.metaleap_zentient.favCmds = {
    'echo "$(messageToEcho)"',
    'fortune | figlet | cowsay',
    'neofetch',
}   -- etc..

events.connect(events.INITIALIZED, _M.metaleap_zentient.startUp)
```

but tweaked to _your_ needs of course.
