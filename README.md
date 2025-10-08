# Message for evaluator
I used the Kimi thinking model because that's the only agent I can buy credits for in Hong kong.
Don't forget to export the `MOONSHOT_AI_API_KEY` if you want to use AI hints 

Files of interest:
- lib/twenty_48/app.rb -- entry point
- lib/twenty_48/controller.rb -- game controller
- lib/twenty_48/ai_engine.rb -- engine for generating AI hints
- lib/twenty_48/view/board_view.rb -- renders the game board

# Simple setup using docker
```
  docker build -t yakubu-lamay-2048 .
  docker run --rm -it -e MOONSHOT_AI_API_KEY yakubu-lamay-2048
```

# Simple native setup
- Install rbenv (https://github.com/rbenv) and ruby build plugin (https://github.com/rbenv/ruby-build#readme)
- Install ruby `rbenv install`
- Install gems `bundle install`
- run app `bundle exec bin/twenty_48 --ncurses`

# Advance Options
2048 can be run with 2 different display "drivers"
* `bundle exec bin/twenty_48 --ncurses` * default
* `bundle exec bin/twenty_48 --tty-cursor`
* `bundle exec bin/twenty_48 

## 1. twenty_48 --ncurses  
#### Interactive terminal application using curses gem / libncursesw5-dev. 
Utilizes the `curses` gem for managing the terminal alternate screen. 
The gem is a wrapper around the ubiquitous ncurses library available on several nix platforms and on windows with mingw
There are two versions of this library: ncurses and ncursesw.
The gem needs to be compiled with the `ncursesw` package otherwise unicode characters will not render properly.
You can install ncursesw on ubuntu by running `sudo apt install libncursesw5-dev`
Using
Windows users can install MinGW. This should have already been installed along with a ruby MRI windows installation  

## 2. twenty_48 --tty-cursor 
#### Simple REPL 
Provided as a fallback if facing compatibility issues using libncurses

# Common Requirements
* MRI ruby 3.4.6 (other versions might work, but this version has been tested)
* linux based os. Tested on native Ubuntu and Windows Subsystem for Linux Ubuntu. ANSI compatible terminal 
* Win console / Powershell support is limited.   

# Installation
* cd to project directory and run `gem build twenty_48`. This will create a gem file `twenty_48-0.0.1.gem`
* run `gem install twenty_48-0.0.1.gem`

### Using the ncurses driver (only available with MRI Ruby)
#### Installation on ubuntu
  * make sure libncursesw is installed `sudo apt install libnursesw-dev`
  * install ruby 
  * cd to project directory and run `gem build twenty_48`. This will create a gem file `twenty_48-0.0.1.gem`
  * run `gem install twenty_48-0.0.1.gem` 
#### Common Issues
  * If you built the `curses` gem before ncursesw was installed, it's possible that the native extension linked to the older ncurses library instead of ncursesw. To fix this uninstall and reinstall the curses gem. 
#### Installation on Windows
  * Install Ruby with MSYS2 development tool chain option. I prefer to use [ruby installer](https://rubyinstaller.org/)
  If you're not sure whether you installed MSYS2 along with your existing ruby, you can either re-run the ruby installer or install MINGW separately

# Known Issues
* dynamic resizing is broken for users on windows consoles https://github.com/PowerShell/PowerShell/issues/8975.
avoid resizing console window or use terminal_paint --basic 
* dynamic resizing is partially broken using the --tty-cursor display driver. Users can hit any key after resizing their terminal window to fix a corrupt display.
The issue is caused by the way ruby delivers signal interrupts. There is no simple fix for the issue outside of making the application multi-threaded. I've forgone that for this release.
