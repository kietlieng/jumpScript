setopt null_glob
# figure out where you will be putting the jump drive location
#export JUMPSCRIPTDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
export JUMPSCRIPTDIR=`cd "$( dirname "${(%):-%N}" )" && pwd`
#export JUMPSCRIPTDIR=`~/scripts`

# jump drive directory name file
export JUMPDIRNAME=".jumpDir"
export JUMP_FZF="false"

# main jump command if no arguements are present list the jump commands
function j () {
  export JUMP_FZF='false'
  start=`date +%s`
  # check to see if directory exists
  if [ "$1" ]
  then
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
      if [ ! -d "$JUMPSCRIPTDIR/$JUMPDIRNAME" ]
      then
        return
      fi

      #DIRRESULT=$(ls -d $JUMPSCRIPTDIR/$JUMPDIRNAME/$1* 2> /dev/null | head -n 1)
      #echo $DIRRESULT
      #return

      #cd $(ls -d $JUMPSCRIPTDIR/$JUMPDIRNAME/$1* | head -n 1)
      export JUMPPATH="$(ls -d $JUMPSCRIPTDIR/$JUMPDIRNAME/$1* 2> /dev/null | head -n 1)"
      if [ "$JUMPPATH" = "./" ]
      then
        echo "no such path $1"
        return
      else
        cd $JUMPPATH
      fi

      # cleaner pwd without the relative path softlink issue.  The trade off is two change directory commands instead of 1.
      cd "$(pwd -P)"
    fi
    shift
    # this will keep iterating through the arguements and diving into the next directory
    # example j xx a b c 
    # this above with use symbol link xx then try to change directory into a* then b* then c*
    while [ "$1" ]
    do
      if [ "$1" = "-" ]
      then
         export JUMP_FZF="true"
      else
        export JUMPPATH="$(ls -d $1* 2> /dev/null | head -n 1)"
        if [ "$JUMPPATH" = "./" ]
        then
          echo "no such path $1"
          return
        else
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
      export JUMP_FULLPATH=$(pwd)
      #echo "full path is $JUMP_FULLPATH/$JUMP_OBJECT"
      # check to see if it is a file
      if [[ -d "${JUMP_FULLPATH}/${JUMP_OBJECT}" ]]; then
        echo "object is directory $JUMP_FULLPATH/$JUMP_OBJECT"
        cd $JUMP_OBJECT
      elif [[ -f "${JUMP_FULLPATH}/${JUMP_OBJECT}" ]]; then
        echo "object is file $JUMP_FULLPATH/$JUMP_OBJECT"
        vim $JUMP_OBJECT
      else 
        echo "full path is $JUMP_FULLPATH/$JUMP_OBJECT is nether file or directory"
      fi
    fi
    pwd;
    if [ "$1" != "list" ]
    then
      ls -ltr;
      #ls
    fi
    end=`date +%s`
  else
    jlist
  fi

end=`date +%s`
runtime=$((end-start))
#echo "run time $runtime"
}

# list jump commands
function jlist () {
  jumpDirectoryExists
  if [ ! -d "$JUMPSCRIPTDIR/$JUMPDIRNAME" ]
  then
    return
  fi
  # we only want to print out symbol links.  We should be able to store things like files is here also, although I do not know why
  #ls -l $JUMPSCRIPTDIR/$JUMPDIRNAME | grep "\->" | cut -c 50-
  #ls -l $JUMPSCRIPTDIR/$JUMPDIRNAME | grep "\->" | awk '{printf "%-1s %-2s %-3s \n", $10, $11, $12 }'
  ls -l $JUMPSCRIPTDIR/$JUMPDIRNAME | grep "\->" | awk '{printf "%-1s %-2s %-3s %-4s\n", $9, $10, $11, $12 }'
}

# add symbol link to jump script
function jadd () {
  jumpDirectoryExists
  if [ ! -d "$JUMPSCRIPTDIR/$JUMPDIRNAME" ]
  then
    return
  fi
  currentLocation=`pwd`
  if [ "$1" ]
  then
    if [ "$2" ]
    then
      /bin/ln -s $currentLocation/$1 $JUMPSCRIPTDIR/$JUMPDIRNAME/$2
    else
      /bin/ln -s "$currentLocation" $JUMPSCRIPTDIR/$JUMPDIRNAME/$1
    fi
  fi
}

# remove symbol link
function jremove () {
  if [ -L "$JUMPSCRIPTDIR/$JUMPDIRNAME/$1" ]
  then
    rm "$JUMPSCRIPTDIR/$JUMPDIRNAME/$1"
  else 
    echo "This symlink doesn't exists in location $JUMPSCRIPTDIR/$JUMPDIRNAME"
  fi
}

# prompt user if symbol link exists
function jumpDirectoryExists() {
  if [ ! -d "$JUMPSCRIPTDIR/$JUMPDIRNAME" ]
  then
    echo $JUMPSCRIPTDIR
    echo "I see the directory doesn't exist would you like to create $JUMPDIRNAME in location $JUMSCRIPTDIR ? [y/n]: "
    read response
    if [ $response = "y" ]
    then
      mkdir $JUMPSCRIPTDIR/$JUMPDIRNAME
    else 
      return 1
    fi
  fi
}

# fetch
function jfetch() {
  CURRENTDIR=$(PWD)
  cd $JUMPSCRIPTDIR/$JUMPDIRNAME/$1*
  cp $2 $CURRENTDIR
  cd $CURRENTDIR 
}
