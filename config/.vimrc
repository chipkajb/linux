" Vundle setup
set nocompatible " disable vi compatibility (emulation of old bugs)
filetype off " required for Vundle
set rtp+=~/.vim/bundle/Vundle.vim " set runtime path to include Vundle
call vundle#begin() " initializ Vundle
Plugin 'VundleVim/Vundle.vim' " let Vundle manage Vundle, required
" Put Vundle plugins here
" Nerd tree
Plugin 'scrooloose/nerdtree'
nnoremap \\ :NERDTree<enter>
" Nerd commenter
Plugin 'preservim/nerdcommenter'
let g:NERDSpaceDelims = 1
let g:NERDCommentEmptyLines = 1
" Vim rainbow
Plugin 'frazrepo/vim-rainbow'
let g:rainbow_active = 1
" C++ enhanced highlighting
Plugin 'octol/vim-cpp-enhanced-highlight'
" Super tab (completion)
Plugin 'ervandew/supertab'
" ctrlp (fuzzy finder)
Plugin 'kien/ctrlp.vim'
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
" jedi-vim
Plugin 'davidhalter/jedi-vim'
let g:jedi#goto_command = "<leader>d"
let g:jedi#goto_assignments_command = "<leader>g"
let g:jedi#goto_stubs_command = "<leader>s"
let g:jedi#goto_definitions_command = ""
let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<leader>n"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#rename_command = "<leader>r"
let g:jedi#popup_on_dot = 0
let g:jedi#show_call_signatures = "2"
" clang complete
Plugin 'rip-rip/clang_complete'
let g:clang_library_path='/usr/lib/llvm-10/lib/libclang.so' " CHANGE THIS TO CORRECT PATH!
" Ending Vundle
call vundle#end() " required
filetype plugin indent on " required

" Colors
colors molokai " better color scheme
syntax enable " enable syntax processing
set t_Co=256 " turn on syntax highlighting
syntax on " (for previous line)

" Spaces and Tabs
set tabstop=4 " number of visible spaces per tab
set softtabstop=4 " number of spaces in tab when editing
set expandtab " tabs are spaces
set shiftwidth=4 " indent with 4 spaces
set autoindent " use indentation of previous line
set smartindent " use intelligent indentation for C
set textwidth=120 " wrap lines at 120 characters
set colorcolumn=120

" UI Config
set number " show line numbers
set showcmd " show command in bottom bar
set cursorline " highlight current line
filetype indent on " load filetype-specific indent files (turns on filetype detection also)
set wildmenu " visual autocomplete for command menu
set lazyredraw " redraw only when we need to (faster macros)
set showmatch " highlight matching parentheses
set relativenumber " enable relative line numbers
set laststatus=2 " show status line always
set statusline=[%n]\ %<%f%h%m " custom status line

" Searching
set incsearch " search as characters are entered
set hlsearch " highlight matches
" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>
set smartcase " no case-sensitive search unless specified

" Folding 
set foldenable " enable folding (hiding parts of the file)
set foldlevelstart=10 " open most folds by default (only fold very nested blocks of code)
set foldnestmax=10 " 10 nested fold max
" space open/closes folds
nnoremap <space> za
set foldmethod=indent " fold based on indent level

" Movement
"move vertically by visual line (for very long lines that wrap around)
nnoremap j gj
nnoremap k gk
" highlight last inserted text
nnoremap gV `[v`]

" Leader shortcuts / other re-mappings (leader is \ by default)
inoremap <C-c> <esc>

" C++ / Python configuration
set comments=sl:/*,mb:\ *,elx:\ */

" Miscellaneous
set pastetoggle=<F2>
set cmdheight=2 " give more space for displaying messages
set updatetime=50 " shorten update time

" keep cursor still
nnoremap J  mzJ`z
