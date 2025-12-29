# vim-smart-shift

Moves and duplicates text intelligently based on your current mode.

- **Normal / Visual Line**: Indents, dedents, moves lines up/down (with infinite scroll), or duplicates lines.
- **Visual / Visual Block**: Destructively shifts text left/right/up/down (overwriting the target area), or creates duplicate stacks of blocks.

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'your-username/vim-smart-shift'
```

## Mappings

| Key | Normal / Line Mode | Visual / Block Mode |
| --- | --- | --- |
| `<C-h>` | Dedent | Shift Left (Destructive) |
| `<C-l>` | Indent | Shift Right (Destructive) |
| `<C-S-l>` | Indent | Shift Right (Push / Non-Destructive) |
| `<C-j>` | Move Line Down | Move Block Down (Destructive) |
| `<C-k>` | Move Line Up | Move Block Up (Destructive) |
| `<C-S-j>` | Duplicate Line Down | Duplicate Block Down (Infinite Scroll) |
| `<C-S-k>` | Duplicate Line Up | Duplicate Block Up (Infinite Scroll) |

*Note: All commands support counts (e.g., `5<C-j>`).*
