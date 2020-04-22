" ~/.vimrc (configuration file for vim only)
" skeletons
function! SKEL_spec()
	0r /usr/share/vim/current/skeletons/skeleton.spec
	language time en_US
	let login = system('whoami')
	if v:shell_error
	   let login = 'unknown'
	else
	   let newline = stridx(login, "\n")
	   if newline != -1
		let login = strpart(login, 0, newline)
	   endif
	endif
	let hostname = system('hostname -f')
	if v:shell_error
	    let hostname = 'localhost'
	else
	    let newline = stridx(hostname, "\n")
	    if newline != -1
		let hostname = strpart(hostname, 0, newline)
	    endif
	endif
	exe "%s/specRPM_CREATION_DATE/" . strftime("%a\ %b\ %d\ %Y") . "/ge"
	exe "%s/specRPM_CREATION_AUTHOR_MAIL/" . login . "@" . hostname . "/ge"
	exe "%s/specRPM_CREATION_NAME/" . expand("%:t:r") . "/ge"
endfunction
autocmd BufNewFile	*.spec	call SKEL_spec()
" basic ~/.vimrc ends here




""""""""""""""""""""""""""""""""""""""
" More things added by Jordan Chipka
""""""""""""""""""""""""""""""""""""""

" Vundle setup
set nocompatible " disable vi compatibility (emulation of old bugs)
filetype off " required for Vundle
set rtp+=~/.vim/bundle/Vundle.vim " set runtime path to include Vundle
call vundle#begin() " initializ Vundle
Plugin 'VundleVim/Vundle.vim' " let Vundle manage Vundle, required

" Put Vundle plugins here
" Nerd tree
Plugin 'scrooloose/nerdtree'
nnoremap \ :NERDTree<enter>
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
" YouCompletMe
Plugin 'valloric/youcompleteme'
" ctrlp (fuzzy finder)
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'

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

" UI Config
set number " show line numbers
set showcmd " show command in bottom bar
set cursorline " highlight current line
filetype indent on " load filetype-specific indent files (turns on filetype detection also)
set wildmenu " visual autocomplete for command menu
set lazyredraw " redraw only when we need to (faster macros)
set showmatch " highlight matching parentheses
set relativenumber " enable relative line numbers

" Searching
set incsearch " search as characters are entered
set hlsearch " highlight matches
" turn off search highlight (leader is comma)
nnoremap <leader><space> :nohlsearch<CR>

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

" Leader shortcuts / other re-mappings
let mapleader="," " leader is comma
" jk is escape (e.g. to exit insert mode)
inoremap jj <esc>

" C++ / Python configuration
set comments=sl:/*,mb:\ *,elx:\ */

" Miscellaneou
set pastetoggle=<F2>
