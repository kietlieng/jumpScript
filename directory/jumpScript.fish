#setopt null_glob
# figure out where you will be putting the jump drive location
#set -gx JUMPSCRIPTDIR `cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
# kl commented out due to compile
#set -gx JUMPSCRIPTDIR `cd "$(dirname "${(%):-%N}")" && pwd`
#set -gx JUMPDIR1 "${(%)}"
#set -gx JUMPDIR2 "${JUMPDIR1:-%N}"
#set -gx JUMPDIR3 "$(dirname $JUMPDIR2)"

#echo "1 |${JUMPSCRIPTDIR1}|"
#echo "2 |${JUMPSCRIPTDIR2}|"
#echo "3 |${JUMPSCRIPTDIR3}|"

#set -gx JUMPDIR4 $(cd "$JUMPDIR3" && pwd)

# I have no idea how this work properly.  It has a bad substitution error
# but it works.  Just prevents my nvimfunction call to pause a little bet
# giving up for now
# kl
# set -gx JUMPSCRIPTDIR $(cd "$(dirname "${(%):-%N}")" && pwd)
set -gx JUMPSCRIPTDIR ~/

# jump drive directory name file
set -gx JUMP_DIRNAME ".jumpDir"
set -gx JUMP_FILE ".jumpscript"
set -gx JUMP_FZF ''
set -gx JUMP_LAST ""
set -gx JUMP_DELIMITER "^"
set -gx JUMP_DELIMITER_GREP "\^"

# main jump command if no arguements are present list the jump commands
function j

  set -gx JUMP_FZF ''
#    set start `date +%s`
  set modeOpen ''

  # check to see if directory exists
  if [ $argv[1] ]

    if [ "$argv[1]" = "list" ]
      jlist
    else if [ "$argv[1]" = "help" ]
      cat "$JUMPSCRIPTDIR/jumpScriptHelp.txt"
      echo "\n"
    else

      jumpDirectoryExists
      # quit if directory doesn not exists
      if [ ! -f ~/$JUMP_FILE ]
        echo "doesn't exists"
        return
      end

      #DIRRESULT=$(ls -d $JUMPSCRIPTDIR/$JUMP_FILE/$1* 2> /dev/null | head -n 1)
      #echo $DIRRESULT
      #return

      set -e JUMPPATH
      #cd $(ls -d ~/$JUMP_FILE/$1* | head -n 1)
      #echo "grep -i \"^$1$JUMP_DELIMITER_GREP\" ~/$JUMP_FILE"
      set -gx JUMPPATH "$(grep -i "^$1$JUMP_DELIMITER_GREP" ~/$JUMP_FILE | head -n 1 | awk -F'^' '{print $NF}' )"

      if [ -z $JUMPPATH ]
#                echo "no such path $1"
        set -gx JUMPPATH "$(grep -i "^$argv[1].*$JUMP_DELIMITER_GREP" ~/$JUMP_FILE | head -n 1 | awk -F'^' '{print $NF}' )"
      end
      #if [[ "$JUMPPATH" = "./" ]]
      if [ -z $JUMPPATH ]
        # echo "no such path $1"
        return

      else

        echo "jumping to path $JUMPPATH"
        cd $JUMPPATH

      end

      # echo "where $(pwd) $(pwd -P)"
      # cleaner pwd without the relative path softlink issue.  The trade off is two change directory commands instead of 1.
      cd "$(pwd -P)"
    end

    set argv $argv[2..-1]

    # echo "blah $(PWD)"

    # this will keep iterating through the arguements and diving into the next directory
    # example j xx a b c
    # this above with use symbol link xx then try to change directory into a* then b* then c*
    set modeOpen ''

    while [ $argv ]
        
      set key $argv[1]
      set argv $argv[2..-1]

      if [ "$key" = "\/" ]

        echo "forward slash"
        set -gx JUMP_FZF 'true'

      else if [ "$key" = "-o" ] 

        set modeOpen "t"

      else

        set -gx JUMPPATH "$(find . -maxdepth 1 -iname "$key*" | sort | head -n 1)"

        if [ "$JUMPPATH" = "./" ]
          echo "no such path $key"
          return
        else
          # find . -maxdepth 1 -iname "$key*"
          # echo "jump to |$JUMPPATH|"
          if [ $JUMPPATH ]
            cd $JUMPPATH
          else 
            echo "failed directory $key"
          end
        end
      end

    end

    if [ $JUMP_FZF ]

      set -gx JUMP_OBJECT_RAW $(__fsel)
      # trim trailing white spaces
      set -gx JUMP_OBJECT (string trim --right $JUMP_OBJECT_RAW)
      #echo "jumpobject |$JUMP_OBJECT|"
      set -gx JUMPPATH $(pwd)
      #echo "full path is $JUMPPATH/$JUMP_OBJECT"

      # check to see if it is a file
      if [ -d "$JUMPPATH/$JUMP_OBJECT" ] then
        #echo "object is directory $JUMPPATH/$JUMP_OBJECT"
        cd $JUMP_OBJECT
      else if [ -f "$JUMPPATH/$JUMP_OBJECT" ] then
        #echo "object is file $JUMPPATH/$JUMP_OBJECT"
        nvim $JUMP_OBJECT
      else
        echo "full path is $JUMPPATH/$JUMP_OBJECT is nether file or directory"
      end

    end

    pwd;

    if [ "$argv[1]" != "list" ]

      ls -ltr
      #ls

    end


    if [ $modeOpen ]
      open .
    end

    set endTime `date +%s`

  else

    jlist
    ls -ltra

  end

#    set endTime `date +%s`
#    set runtime $(math "$endTime - $start")
#    echo "run time $runtime"

end

# Jump script then go edit
function jx

  if test (count $argv) -lt 1
    return
  end

  j $argv

  e

end

# Jump script then go edit from the root
function jX

  if test (count $argv) -lt 1
    return
  end

  j $argx

  E

end

# list jump commands
function jlist

  jumpDirectoryExists
  echo "~/$JUMP_FILE"

  if [ ! -f ~/$JUMP_FILE ]
    echo "quitting"
    return
  end

  # we only want to print out symbol links.  We should be able to store things like files is here also, although I do not know why
  # only print the last 3 columns
  cat ~/$JUMP_FILE | awk -F'^' '{print $(NF-1) " " $NF}'

end

function jf

  # echo "jlist | grep -i \"^$1.*$JUMP_DELIMITER_GREP\""
  jlist | grep -i "$argv[1]"

end

# add symbol link to jump script
function jadd

  jumpDirectoryExists
  if [ ! -f ~/$JUMP_FILE ]
    echo "jump directory doesn't exists"
    return
  end

  set currentLocation $PWD

  # if have 1 arg
  if [ "$argv[1]" ]
    # if 2 args 
    if [ "$argv[2]" ]
        echo "$argv[2]$JUMP_DELIMITER$currentLocation/$argv[1]" >> ~/$JUMP_FILE
        # sort after adding
    else
        echo "$argv[1]$JUMP_DELIMITER$currentLocation" >> ~/$JUMP_FILE
    end
    pecho "sort -o ~/$JUMP_FILE ~/$JUMP_FILE"
    sort -o ~/$JUMP_FILE ~/$JUMP_FILE
  end
end

# remove symbol link
function jremove
  # echo "grep -q \"^$1$JUMP_DELIMITER_GREP\" ~/$JUMP_FILE"
  if grep -iq "^$1$JUMP_DELIMITER_GREP" ~/$JUMP_FILE
    sed -i '' "/^$1$JUMP_DELIMITER_GREP/d" ~/$JUMP_FILE
  else
    echo "Entry does not exists in ~/$JUMP_FILE"
  end
end

# prompt user if symbol link exists
function jumpDirectoryExists

  if [ ! -f ~/$JUMP_FILE ]

    echo $JUMPSCRIPTDIR
    echo "I see the file doesn't exist would you like to create $JUMP_FILE in location ~/.jumpscript? [y/n]: "
    read response

    if [ $response = "y" ]
      touch ~/$JUMP_FILE
    else
      return 1
    end

  end

end

# fetch ... don't know what I want to do with this 
function jfetch

  set CURRENTDIR $(PWD)
  cd ~/$JUMP_FILE/$argv[1]*
  cp $argv[2] $CURRENTDIR
  cd $CURRENTDIR

end

# jump to last location
function jj

  set jumpTo ""

  if [ $argv ]
    set jumpTo $(cat ~/.jumplast.$argv[1])
  else
    set jumpTo $(cat ~/.jumplast)
  end
  cd "$jumpTo"

end


# mark working location
alias jwl="ls -1 ~/.jumplast*"

# mark working location
function jw

  set lastLocal $(pwd)
  if [ $argv ]
    # clear it
    echo "$lastLocal" > ~/.jumplast.$argv[1]
  else
    echo "$lastLocal" > ~/.jumplast
  end

end

function jc

  for x in `ls -lt1`;
    # if it's a directory
    if [ -d "$x" ]
      echo "directory $x"
      cd $x
      ls -ltr
      date
      break
    end
  end

end
