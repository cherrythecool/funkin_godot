# gdanimate-rewrite

WIP rewrite of the [gdanimate](https://github.com/cherrythecool/gdanimate) repo!!!

will be merged into the main repo once 1.0 is finished but until then this repo is
public for testing, issues, feedback, pull requests, whatever
(contributions very welcome)!

## current state

mid-way through a refactoring right now, things are going well and performance and
code readability seem to be improving i think

going to try and get more feedback on the UX of it eventually and maybe naming or
other things, but once i've done that *AND* animate atlases are back to being supported
again, then i think i can publish all these changes, do bug testing, and finally make
a release, merge, and then *fix up my stuff that relied on the old version*

## migration warning

when moving over from the previous version of gdanimate, note that some positions
of symbols may change if you were using the default stage or "blank" symbol

to fix this you usually just need to switch the symbol to whatever symbol was the
main one exported, which should result in the same behavior as before the rewrite
