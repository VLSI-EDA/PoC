


# PoC Tools

This folder contains several tools and addons to ease the work with the
PoC-Library and VHDL.

## Emacs


## Git

 -  [`git-alias.setup.ps1`][git_git-alias] registers 2 new global aliasses in
    git, which prints the colored commit tree into the console:
    
    `git tree`:
    
        git config --global alias.tree 'log --decorate --pretty=oneline --abbrev-commit --date-order --graph'
    
    `git treea`:
    
        git config --global alias.tree 'log --decorate --pretty=oneline --abbrev-commit --date-order --graph --all'
    
		
## Notepad++

This folder contains syntax highlighting rules for Notepad++. The following file types are supported:

 -  Xilinx user constraint files (*.ucf): [`Syntax Highlighting - Xilinx UCF`][npp_ucf]

 [git_git-alias]:		git/git-alias.setup.ps1
 [npp_ucf]:					Notepad%2B%2B%2FSyntax%20Highlighting%20-%20Xilinx%20UCF.xml
 