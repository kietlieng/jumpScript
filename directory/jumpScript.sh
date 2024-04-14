#setopt null_glob
# figure out where you will be putting the jump drive location
#export JUMPSCRIPTDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
# kl commented out due to compile
#export JUMPSCRIPTDIR=`cd "$(dirname "${(%):-%N}")" && pwd`
#export JUMPDIR1="${(%)}"
#export JUMPDIR2="${JUMPDIR1:-%N}"
#export JUMPDIR3="$(dirname $JUMPDIR2)"

#echo "1 |${JUMPSCRIPTDIR1}|"
#echo "2 |${JUMPSCRIPTDIR2}|"
#echo "3 |${JUMPSCRIPTDIR3}|"

#export JUMPDIR4=$(cd "$JUMPDIR3" && pwd)

# I have no idea how this work properly.  It has a bad substitution error
# but it works.  Just prevents my nvimfunction call to pause a little bet
# giving up for now
export JUMPSCRIPTDIR=$(cd "$(dirname "${(%):-%N}")" && pwd)

# jump drive directory name file
export JUMP_DIRNAME=".jumpDir"
export JUMP_FILE=".jumpscript"
export JUMP_FZF="false"
export JUMP_LAST=""
export JUMP_DELIMITER="^"
export JUMP_DELIMITER_GREP="\^"

# main jump command if no arguements are present list the jump commands
function j() {
    export JUMP_FZF='false'
    start=`date +%s`
    # check to see if directory exists
    if [[ "$1" ]]; then
        if [ "$1" = "list" ]
        then
            jlist
        elif [ "$1" = "help" ]
        then
            cat "$JUMPSCRIPTDIR/jumpScriptHelp.txt"
            echo "\n"
        else
            jumpDirectoryExists
            # quit if directory doesn not exists
            if [ ! -f ~/$JUMP_FILE ]
            then
                echo "doesn't exists"
                return
            fi

            #DIRRESULT=$(ls -d $JUMPSCRIPTDIR/$JUMP_FILE/$1* 2> /dev/null | head -n 1)
            #echo $DIRRESULT
            #return

            #cd $(ls -d ~/$JUMP_FILE/$1* | head -n 1)
            JUMPPATH="$(grep -i "^$1.*\^" ~/$JUMP_FILE | head -n 1 | awk -F'^' '{print $NF}' )"
            #if [[ "$JUMPPATH" = "./" ]]
            if [[ -z $JUMPPATH ]]; then
                echo "no such path $1"
                return
            else
                echo "jumping to path $JUMPPATH"
                cd $JUMPPATH
            fi

            # cleaner pwd without the relative path softlink issue.  The trade off is two change directory commands instead of 1.
            cd "$(pwd -P)"
        fi
        shift
        # this will keep iterating through the arguements and diving into the next directory
        # example j xx a b c
        # this above with use symbol link xx then try to change directory into a* then b* then c*
        openMode="f"
        while [ "$1" ]
        do
            if [ "$1" = "/" ]
            then
                export JUMP_FZF="true"
            elif [ "$1" = "-o" ]
            then
                openMode="t"
            else
                export JUMPPATH="$(find . -maxdepth 1 -iname "$1*" | sort | head -n 1)"
                if [ "$JUMPPATH" = "./" ]
                then
                    echo "no such path $1"
                    return
                else
                    find . -maxdepth 1 -iname "$1*"
                    #echo "jump to $JUMPPATH"
                    cd $JUMPPATH
                fi
            fi
            shift
        done

        if [ "$JUMP_FZF" = "true" ]
        then
            export JUMP_OBJECT_RAW=$(__fsel)
            # trim trailing white spaces
            export JUMP_OBJECT=${JUMP_OBJECT_RAW%?}
            #echo "jumpobject |$JUMP_OBJECT|"
            export JUMPPATH=$(pwd)
            #echo "full path is $JUMPPATH/$JUMP_OBJECT"
            # check to see if it is a file
            if [[ -d "${JUMPPATH}/${JUMP_OBJECT}" ]]; then
                #echo "object is directory $JUMPPATH/$JUMP_OBJECT"
                cd $JUMP_OBJECT
            elif [[ -f "${JUMPPATH}/${JUMP_OBJECT}" ]]; then
                #echo "object is file $JUMPPATH/$JUMP_OBJECT"
                nvim$JUMP_OBJECT
            else
                echo "full path is $JUMPPATH/$JUMP_OBJECT is nether file or directory"
            fi
        fi
        pwd;
        if [ "$1" != "list" ]
        then
            ls -ltr;
            #ls
        fi


        if [ "$openMode" = "t" ]
        then
            open .
        fi

        end=`date +%s`
    else
        jlist
        ls -ltr;
    fi

    end=`date +%s`
    runtime=$((end-start))
    #echo "run time $runtime"

}

# Jump script then go edit
function jx() {

  if [[ $# -lt 1 ]]; then
    return
  fi

  jOutcome=$(j $@)

  if [[ $jOutcome == *"no such path"* ]]; then
    return
  fi
  echo "jOutcome $jOutcome"
  x

}

# Jump script then go edit from the root
function jX() {

  if [[ $# -lt 1 ]]; then
    return
  fi

  jOutcome=$(j $@)

  if [[ $jOutcome == *"no such path"* ]]; then
    return
  fi
  echo "jOutcome $jOutcome"
  X

}

# list jump commands
function jlist() {
    jumpDirectoryExists
    echo "~/$JUMP_FILE"
    if [ ! -f ~/$JUMP_FILE ]; then
      echo "quitting"
      return
    fi
    # we only want to print out symbol links.  We should be able to store things like files is here also, although I do not know why
    # only print the last 3 columns
    cat ~/$JUMP_FILE | awk -F'^' '{print $(NF-1) " " $NF}'
}

function jf() {
#    echo "jlist | grep -i \"^$1.*$JUMP_DELIMITER_GREP\""
    jlist | grep -i "$1"
}

# add symbol link to jump script
function jadd() {
  jumpDirectoryExists
  if [ ! -f ~/$JUMP_FILE ]
  then
      echo "jump directory doesn't exists"
      return
  fi
  currentLocation=`pwd`

  # if have 1 arg
  if [ "$1" ]
  then
    # if 2 args 
    if [ "$2" ]; then
        echo "$2${JUMP_DELIMITER}${currentLocation}/$1" >> ~/$JUMP_FILE
        # sort after adding
    else
        echo "$1${JUMP_DELIMITER}${currentLocation}" >> ~/$JUMP_FILE
    fi
    echo "sort -o ~/$JUMP_FILE ~/$JUMP_FILE"
    sort -o ~/$JUMP_FILE ~/$JUMP_FILE
  fi
}

# remove symbol link
function jremove() {
#    echo "grep -q \"^$1$JUMP_DELIMITER_GREP\" ~/$JUMP_FILE"
    if grep -iq "^$1$JUMP_DELIMITER_GREP" ~/$JUMP_FILE; then
      sed -i '' "/^$1$JUMP_DELIMITER_GREP/d" ~/$JUMP_FILE
    else
        echo "Entry does not exists in ~/$JUMP_FILE"
    fi
}

# prompt user if symbol link exists
function jumpDirectoryExists() {
    if [ ! -f ~/$JUMP_FILE ]
    then
        echo $JUMPSCRIPTDIR
        echo "I see the file doesn't exist would you like to create $JUMP_FILE in location ~/.jumpscript? [y/n]: "
        read response
        if [ $response = "y" ]
        then
            touch ~/$JUMP_FILE
        else
            return 1
        fi
    fi
}

# fetch ... don't know what I want to do with this 
function jfetch() {
    CURRENTDIR=$(PWD)
    cd ~/$JUMP_FILE/$1*
    cp $2 $CURRENTDIR
    cd $CURRENTDIR
}

# jump to last location
function jj() {

    if [[ $# -gt 0 ]]; then
      cd $(cat ~/.jumplast.${1})
    else
      cd $(cat ~/.jumplast)
    fi
}

# mark working location
alias jwl="ls -1 ~/.jumplast*"

# mark working location
function jw() {
    lastLocal=$(pwd)
    if [[ $# -gt 0 ]]; then
        # clear it
        echo "$lastLocal" > ~/.jumplast.${1}
    else
        echo "$lastLocal" > ~/.jumplast
    fi
}

function jc() {
    for x in `ls -lt1`;
    do
        # if it's a directory
        if [ -d "$x" ];
        then
            echo "directory $x"
            cd $x
            ls -ltr
            date
            break
        fi
    done
}
