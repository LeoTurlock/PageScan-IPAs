# PageScan IPAs

Feather / AltStore source for PageScan builds.

Add this URL as a source in Feather:

```
https://raw.githubusercontent.com/LeoTurlock/PageScan-IPAs/main/apps.json
```

The IPAs are unsigned (Feather signs them on install) and are attached to
[Releases](https://github.com/LeoTurlock/PageScan-IPAs/releases), because they're too large for git.

## Publishing a build

```bash
./publish.sh "What changed in this build"
```

This builds an unsigned Release IPA from `~/Documents/Code/PageScan`, uploads it as a release and adds it as the
newest version in `apps.json`. Pass an IPA as the second argument to publish an existing file instead.
