# Hello

tl;dr: Breaking up shell commands into separate files for an easier to read `~/.zshrc`.

## How to use

Clone to whatever makes sense, I use `~/.zsh_functions`, update yours and the below script for whatever makes sense.

```bash
# Add this to ~/.zshrc
for file in ~/.zsh_functions/*.sh; do
    source $file
done
```
