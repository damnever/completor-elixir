## Elixir code completion for Vim

Based on [completor.vim](https://github.com/maralla/completor.vim).


### Install

Here, I am using [vim-plug](https://github.com/junegunn/vim-plug):
```
Plug 'maralla/completor.vim'
Plug 'damnever/completor-elixir'
```

Resolve deps:
```
cd /path/to/plugin/completor-elixir
make
```

### Short Keys

Add the following lines to your `.vimrc`:
```
" jump to definition
noremap <leader>jd :call completor#do('definition')<CR>
" show document
noremap <s-k> :call completor#do('doc')<CR>
```
