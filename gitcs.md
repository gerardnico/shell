# Gitcs

## Installation

### Windows WSL

```bash
git config --global credential.helper "/mnt/c/Git/mingw64/libexec/git-core/git-credential-wincred.exe"
```

* in `~/.bash_profile`
```bash
export GITCS_CONF=/mnt/d/code/shell-gh/gitcs.csv
```

### Server

* in `~/.bash_profile`
```bash
export GITCS_HOME=/opt/www/git
```
