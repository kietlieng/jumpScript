#!/bin/bash

royal_debug_me=0
royal_last_is_switch=1
royal_last_is_empty=1
royal_do_not_connect=0
royal_list_command="echo "
royal_delimiter_1="\^"
royal_delimiter_2="\^"
royal_last_command=~/lab/scripts/mappings
MODE_FZF=''

alias vijumplast="vim ~/lab/scripts/mappings/.jumplast"
alias psht="jsh -P -tm"
alias psh="jsh -P"
alias jlc="jsh -l -c"
alias jl="jsh -l"
alias jtm="jsh -l -tm -c"
alias jsht="jsh -tm"

export royal_file_target=~/lab/scripts/mappings/all.txt
export royal_file_pass_target=~/lab/scripts/mappings/passall.txt
export royal_file_prod_target=~/lab/scripts/mappings/prodall.txt
export royal_file_prod_pass_target=~/lab/scripts/mappings/passprodall.txt
export royal_last_search_file=~/lab/scripts/mappings/searchstring.txt

function resetroyalsettings() {

  royal_debug_me=0
  royal_last_is_switch=1
  royal_last_is_empty=1
  royal_do_not_connect=0

}

function debugme() {

  if [[ "$royal_debug_me" -eq "1" ]]; then
    echo ">> DEBUG: $1"
  fi

}

function assh() {

  cop $2
  S_HOST=$1
  shift
  shift
  sssh $S_HOST "$@"

}

function nextIsEmpty() {

  royal_last_is_empty=1
  if [[ "$1" = "" ]] ;
  then
    debugme "is empty"
    royal_last_is_empty=0
  fi
  debugme "is not empty"

}

function nextIsASwitch() {

  royal_last_is_switch=1
  pecho "switch statement |$1|"
  if [[ $1 = -* ]] ;
  then
    debugme "is switch"
    royal_last_is_switch=0
  fi
  debugme "is not switch"

}


function jshm(){

  jsh $(tuijsh)

}

# jltm -u -p tmn
function jltm() {

  if [[ "$#" -gt 2 ]];
  then
    jsh -l -c -u $1 -p $2 -tmn $3
  elif [[ "$#" -gt 1 ]];
  then
    jsh -l -c -u $1 -p $2 -tm
  elif [[ "$#" -gt 0 ]];
  then
    jsh -l -c -u $1 -tm
  else
    jsh -l -c -tm
  fi

}

# if something like root@10.231.22.30 we want to separate the root and 10.231.22.30 portion out
function sshIPPortion() {

  if [[ $# -gt 0 ]]; then
    # search for @ in value
    if [[ "$1" == *"@"* ]]; then
      ipPortion=$(echo "$1" | sed -r 's/(.*)@(.*)$/\2/')
      echo "$ipPortion"
      return
    fi
  fi
  echo "$@"

}

function sshUserPortion() {

  if [[ $# -gt 0 ]]; then
    # search for @ in value
    if [[ "$1" == *"@"* ]]; then
      userPortion=$(echo "$1" | sed -r 's/(.*)@(.*)$/\1/')
      echo "$userPortion"
      return
    fi
  fi
  echo "$@"

}


function isAWS() {

# set it to centos if it's currently aws server
case $1 in
  10.80.* ) # dev aws
    echo -n "centos"
    ;;
  10.131.1.* ) # prod aws
    echo -n "centos"
    ;;
  10.131.2.* ) # prod aws
    echo -n "centos"
    ;;
  10.131.4.* ) # prod aws
    echo -n "centos"
    ;;
  10.132.* ) # prod aws
    echo -n "centos"
    ;;
  * )
    ;;
esac

}

function jsh() {


  # echo -e "test1\ntest2\ntest3"
  # return

  resetroyalsettings

  local sFileTarget="$royal_file_target"
  local sFileProdTarget="$royal_file_prod_target"
  local sFileProdPassTarget="$royal_file_prod_pass_target"
  local sLastFile="$royal_last_command/.jumplast"

  local jshquery=/tmp/jsh-query
  local explain=''
  local explainFile=/tmp/jsh-explain
  echo -n "" >  $explainFile

  local sLastCommand="$@"
  local sLast='false'
  local postfixValues=''

  MODE_FZF=''
  # echo "$@" > $jshquery


  if [[ $# -eq 0 ]] ; then
    echo 'No arguments'
    return 0
  fi

  local key="$1"
  # echo "first $key"

  # for n in $(echo $newKeys); do
  #   echo "arg $n"
  # done

  shift


  if [[ $key == '-fzffeed' ]]; then

    # ignore all output
    while [[ $# -gt 0 ]]; do
      shift
    done

    # leading args into param
    cIndex="1"
    for n in $(cat $jshquery); do
      # echo "index $cIndex $n"
      eval "$cIndex=\"$n\""
      cIndex=$(expr $cIndex + 1)
    done

    # echo "all args $@"
    key="$1"
    shift

  elif [[ $key == '-fzf' ]]; then

    MODE_FZF='t'
    key="$1"

    echo "$@" > $jshquery
    [[ $# -gt 0 ]] && shift

  else

    echo "$@" > $jshquery

  fi

  # we don't want the search string.
  # variable will be useful only for tmux
  local sSearch=$(sshIPPortion $key)

  if [[ "$key" == *"@"* ]]; then
    userPortion=$(sshUserPortion $key)
    #echo "${userPortion}@"
    # remove user from ssh
    sLastCommand=$(echo "$sLastCommand" | sed -r "s/${userPortion}@//g")
    echo "$sLastCommand"
  fi
  #sSearch=$key
  #echo $sLastCommand
  #echo "$sSearch"
  #return

  if [[ "$sSearch" == '-l' ]]; then
    # save all arguements to list z
    # empty out all arguements
    currentArg=""
    while [[ $# -gt 0 ]]; do
      currentArg="$currentArg $key"
      key="$1"
      shift
    done

    paramList="$currentArg"
    # reload args with the .jumplist
    cIndex="1"
    for n in $(cat $sLastFile); do
      eval "$cIndex=\"$n\""
      cIndex=$(expr $cIndex + 1)
    done
    paramList="[$@] $paramList"

    # restore args
    for n in $(echo $currentArg)
    do
      eval "$cIndex=\"$n\""
      cIndex=$(expr $cIndex + 1)
    done
    echo "$paramList"

    # add back in the z arguements
    # reset sSearch value
    sLast='true'
    sSearch=$key

    #echo "$sSearch"
    #    else
    #        echo "$@" > $royal_last_command/.jumplast

  fi
  # shift

  #sAllArgs="${@}"
  sAllArgs=""

  if [[ $sSearch = '-lp' ]]; then
    cat $sFileProdTarget
    return
  fi

  local defaultPing=10
  local sConnect='false'
  local sCopyOutputCommand='false'
  local sDoc=0
  local sExecuteCommand=""
  local sInTM='false'
  local sIndex="0"
  local sList='false'
  local sManual='false'
  local sMysqlCommand=''
  local sMysqlLogin='false'
  local sNotInclude=""
  local sPassword=''
  local sPasswordSwitch='false'
  local sPing='false'
  local sPrettyPrint='false'
  local sRefreshKnownKey='false'
  local sService='web'
  local sServiceEnabled=0
  local sServicePathPost='bin/service.sh'
  local sServicePathPre='/et/services'
  local sServiceType='status'
  local sTmux=''
  local sTmuxName=''
  local sUser=''
  local sUserManuallySet='false'
  local modeProduction=''
  local optHead=0
  local optTail=100
  local optGetDNS=''

  if [[ "'$*'" = *-d* ]]; then
    royal_debug_me=1
    echo "================ SET DEBUG"
  fi

  lastArg1=""
  lastArg2=""
  while [[ $# -gt 0 ]]; do

    key="$1"
    # echo "key $1"
    #echo "starting $sAllArgs"

    # leave space intentionally 
    lastArg1=" $1"
    lastArg2=""

    shift

    case $key in

      # check to see if number
      # +([0-9]) ) 
      #
      #   if [[ $optTail -eq 100 ]]; then
      #     optTail=$key
      #     echo "change end to $key"
      #   else
      #     optHead=$key
      #     optHead=$((optHead + 1))
      #     echo "change start to $key"
      #   fi
      #
      # ;;

      "-fetch" )
        optGetDNS='t'
        echo "fetch value is $key" 
        ;;
      '-f' ) # fake connect
        royal_do_not_connect=1
        echo "-f switch"
        [[ $# -gt 0 ]] && shift
        ;;
      '-s' ) # debug skip it
        [[ $# -gt 0 ]] && shift
        ;;
      '-c' ) # too lazy to type

        sConnect='true'
        echo "connect" >> $explainFile
        # if this hasn't been set already
        if [[ "" == "$sUser" ]]; then
          sUser="etadm"
        fi
        # if this hasn't been set already
        if [[ "" == "$sPassword" ]]; then
          sPassword="p"
        fi

        # remove from list
        sLastCommand="${sLastCommand/\-c/}"
        postfixValues="$postfixValues -c"


        ;;
      '-n' )
        sIndex="$1"

        [[ $# -gt 0 ]] && shift
        ;;
      '-ping' )
        defaultPing=$1
        [[ $# -gt 0 ]] && shift
        ;;
      '-inTM' )
        sInTM='true'
        ;;
      '-list' ) # service
        sList='true'
        ;;
      '-et' ) # service
        # copy this command options to connect
        # if this hasn't been set already
        sConnect='true'
        if [[ "" == "$sUser" ]]; then
          sUser="etadm"
        fi
        # if this hasn't been set already
        if [[ "" == "$sPassword" ]]; then
          sPassword="p"
        fi

        # regular command
        sServiceEnabled=1
        sService="$1"
        lastArg2=" $1"

        [[ $# -gt 0 ]] && shift

        # grab service type
        sServiceType="$1"
        lastArg2="$lastArg2 $1"

        [[ $# -gt 0 ]] && shift

        ;;
      '-tm' )
        sTmux='true'

        # blank out the statements
        lastArg1=""
        lastArg2=""
        echo "tmux" >> $explainFile

        sLastCommand="${sLastCommand/\-tm/}"
        postfixValues="$postfixValues -tm"

        ;;
        # this doesn't work properly

      '-tmu' )
        sTmux='true'
        sConnect='true'
        sUser="$1"

        # add to the last arguement -c because we want to connect
        lastArg1=" -c"
        lastArg2=" -u $sUser"
        echo "tmux multi connect with user $sUser" >> $explainFile

        # if this hasn't been set already
        if [[ "" == "$sUser" ]]; then
          sUser="etadm"
        fi
        # if this hasn't been set already
        if [[ "" == "$sPassword" ]]; then
          sPassword="p"
        fi

        [[ $# -gt 0 ]] && shift

        # remove from list
        sLastCommand="${sLastCommand/\-tmu/}"
        sLastCommand="${sLastCommand/$sUser/}"
        postfixValues="$postfixValues -tmu $sUser"


        ;;

      # this doesn't work properly
      '-tmc' )

        sTmux='true'
        sConnect='true'

        # add to the last arguement -c because we want to connect
        lastArg1=" -c"
        lastArg2=""
        echo "tmux multi connect" >> $explainFile

        # if this hasn't been set already
        if [[ "" == "$sUser" ]]; then
          sUser="etadm"
        fi
        # if this hasn't been set already
        if [[ "" == "$sPassword" ]]; then
          sPassword="p"
        fi

        # remove from list
        sLastCommand="${sLastCommand/\-tmc/}"
        postfixValues="$postfixValues -tmc"

        ;;

      '-tmn' )
        sTmux='true'
        sTmuxName="$1"

        # blank out the statements
        lastArg1=""
        lastArg2=""

        sLastCommand="${sLastCommand/\-tmn $sTmuxName=/}"
        postfixValues="$postfixValues -tmn $sTmuxName"

        [[ $# -gt 0 ]] && shift
        ;;
      '-C' ) sCopyOutputCommand='true' ;;
      '-r' ) sRefreshKnownKey='true' ;;
      '-pretty' ) sPrettyPrint='true' ;;
      '-p' ) # grab password
        debugme "password"
        sPasswordSwitch='true'
        sConnect='true'
        sPassword="$1"
        pecho "next is a value $sPassword"
        lastArg2=" $sPassword"
        [[ $# -gt 0 ]] && shift
        ;;
      '-j' ) # path zk
        export copy_path=""
        case $1 in
          'local' )
            export copy_path="cd /et/local/services"
            ;;
          'serv' )
            export copy_path="cd /et/services"
            ;;
          'soft' )
            export copy_path="cd /et/software/cas"
            ;;
          'install' )
            export copy_path="cd /et/install"
            ;;
          'zkstat' )
            export copy_path="/et/software/zkp/bin/zkServer.sh status"
            ;;
          'zkc' )
            export copy_path="/et/software/zkp/bin/zkCli.sh"
            ;;
          * )
            export copy_path="$1"
            ;;
        esac
        # if you have a command let's tack on the bash
        echo "$copy_path" | pbcopy
        lastArg2="$copy_path"
        [[ $# -gt 0 ]] && shift

        ;;
      '-doc' ) # docker states
        sDoc=1
        ;;
      '-ur' ) # user
        sUser="root"
        sConnect='true'
        sUserManuallySet='true'
        sPassword="e"
        ;;
      '-u' ) # user
        sUser="$1"
        sConnect='true'
        sUserManuallySet='true'
        nextIsASwitch $1
        nextIsEmpty $1
        debugme "last command results is $royal_last_is_switch"

        echo "user: $sUser" >> $explainFile

        [[ $# -gt 0 ]] && shift

        # is a switch then just assign the value
        if [[ "$royal_last_is_switch" -eq "0" ]];
        then
          debugme "is a switch assign etadm"
          sUser="etadm"
        elif [[ "$royal_last_is_empty" -eq "0" ]]; then
          debugme "empty assign etadm"
          sUser="etadm"
        fi

        lastArg2=" $sUser"
        case $sUser in
          'root' )
            echo "root user password"
            sPassword="e"
            ;;
          'oracle' )
            echo "oracle password"
            sPassword="o"
            ;;
          * )
            sPassword="p"
            echo "no password assumed"
            ;;
        esac

        sLastCommand="${sLastCommand/\-u/}"
        sLastCommand="${sLastCommand/$sUser/}"
        postfixValues="$postfixValues -u $sUser"

        debugme "user is $sUser"

        ;;
      '-t' ) # ping it
        sPing='true'
        sLastCommand="${sLastCommand/\-t/}"
        postfixValues="$postfixValues -t"
        echo "ping" >> $explainFile
        ;;
      '-m' ) # manually connect with the string
        sManual='true'
        ;;
      '-a' ) # add on to the search term
        sSearch="$sSearch.*$1"
        debugme $sSearch
        [[ $# -gt 0 ]] && shift

        ;;
      '-v' ) # does not include
        sNotInclude="$1"
        debugme "exclude $sNotInclude"
        [[ $# -gt 0 ]] && shift

        ;;
      '-exec' ) # record and quit
        sExecuteCommand="$1"
        lastArg2=" $sExecuteCommand"
        [[ $# -gt 0 ]] && shift

        ;;
      '-qq' )
        sMysqlCommand='true'
        sMysqlLogin="$1"
        lastArg2=" $1"
        [[ $# -gt 0 ]] && shift

        ;;
      '-q' )
        sMysqlCommand='true'
        ;;
      '-P' ) # use production list
        sFileTarget=$sFileProdTarget
        modeProduction='t'
        ;;
      * )
        debugme "add to search $key"
        lastArg1=""
        lastArg2=""
        sSearch="$sSearch.*$key"
        ;;
    esac

    # collect all args after the fact
    sAllArgs="${sAllArgs}${lastArg1}${lastArg2}"

  done

  # if not recall command and not in tmux
  if [[ "$sLast" = 'false' && "$sInTM" = 'false' ]]; then
    echo "$sLastCommand" > $sLastFile
  fi


  pecho "allargs | ${sAllArgs} |"
  echo "search term: $sSearch" >> $explainFile

  # manual seach
  if [[ "$sSearch" || $sManual = 'true' || $sCopyOutputCommand = 'true' || "$sPing" = 'true' || "$optGetDNS"  ]]; then

    # copy the output
    if [[ $sCopyOutputCommand = 'true' ]]; then
      S_COPY=$(grep -i $sSearch $sFileTarget)
      echo -n "$S_COPY" | awk -F'^' '{ print $NF }' | tr -d '\n' | pbcopy
    fi

    # if true don't interpret anything just run the command
    if [[ $sManual = 'true' ]]; then
      sCurrentURI=$sSearch
      # list jump points
    else
      #echo "grep -i \"$sSearch\" $sFileTarget | grep -o \"${royal_delimiter_1}.*\" | awk -F${royal_delimiter_1} '{ print $2 }' | head -n 1)"
      sCurrentURI=$(grep -i "$sSearch" $sFileTarget | grep -o "${royal_delimiter_1}.*" | awk -F${royal_delimiter_1} '{ print $2 }' | head -n 1)

      if [[ "$sTmux" == "true" ]]; then
        #echo "grep -i \"$sSearch\" $sFileTarget | grep -o \"${royal_delimiter_1}.*\" | awk -F${royal_delimiter_1} '{ print \$2 }'"
        sCurrentURI=$(grep -i "$sSearch" $sFileTarget | tail -n +$optHead | head -n $optTail | grep -o "${royal_delimiter_1}.*" | awk -F${royal_delimiter_1} '{ print $2 }')
        echo "query $sCurrentURI"
      fi

      # not include in connection run command with inverse
      if [[ "$sNotInclude" != "" ]]; then
        debugme "not include is $sNotInclude"
        echo "not include"
        sCurrentURI=$(grep -i "$sSearch" $sFileTarget | grep -o "${royal_delimiter_1}.*" | grep -iv $sNotInclude | awk -F${royal_delimiter_1} '{ print $2 }')
        if [[ $sIndex != "0" ]]; then
          sCurrentURI=$(echo $sCurrentURI ep -o "${royal_delimiter_1}.*" | grep -iv $sNotInclude | awk -F${royal_delimiter_1} '{ print $2 }' | head -n $sIndex | tail -n 1)
        fi

        if [[ "$sTmux" == "true" ]]; then
          sCurrentURI=$(grep -i "$sSearch" $sFileTarget | tail -n +$optHead | head -n $optTail | grep -o "${royal_delimiter_1}.*" | grep -iv $sNotInclude |  awk -F${royal_delimiter_1} '{ print $2 }' )
        fi
      fi
    fi


    if [[ $optGetDNS ]]; then

      echo "ssearch |$sSearch| true"
      local ipAddress=$(nslookup $sSearch | grep -i "server" | head -n 1 | grep -o "[.+0-9]\+")
      local entryOutput="$sSearch^$ipAddress"
      echo "$entryOutput"
      echo -n "$entryOutput" | pbcopy
      return

    elif  [[ $MODE_FZF ]]; then

      # echo "fzf search term: $sSearch" >> $explainFile
      # if it has something to exclude run the exclusion
      if [[ "$sNotInclude" != "" ]]; then
        # echo "blah1"
        grep -i "$sSearch" $sFileTarget | grep -iv $sNotInclude | sed "s/\$/:$postfixValues/"
      else

        if [[ "$sPrettyPrint" = 'true' ]]; then
          # echo "blah2"
          grep -i "$sSearch" $sFileTarget | sed 's/\^.*=/=/g' | sed "s/\$/:$postfixValues/"

        else
          # echo "blah3 $sSearch"
          grep -i "$sSearch" $sFileTarget | sed "s/\$/:$postfixValues/"

        fi

      fi

    # start ping
    elif [[ "$sPing" = 'true' ]]; then

      debugme "ping this $sCurrentURI $defaultPing"
      #fping -c $defaultPing $sCurrentURI

      ping $sCurrentURI

    elif [[ "$sConnect" = 'true' ]]; then

      #echo "counter $counter |$sCurrentURI|"
      # split on
      #echo "tmux value $sTmux"
      # if tmux option is true create the panes by passing the ip of the currentIP variable to jsh.
      # basically using jsh to create tmux sessions that will in affect call jsh
      if [[ "$sTmux" == "true" ]]; then
        #echo "testing blah"
        #tmuxCommand=""
        # takes care of session names
        #                paneName=`date +"%y%m%d_%H%M%S"`
        wondertitle
        paneName="jsh-$RANDOM_TITLE1"
        if [[ $modeProduction ]]; then
          paneName="psh-$RANDOM_TITLE1"
        fi

        if [[ "$sTmuxName" != "" ]]; then
          paneName="$sTmuxName"
        fi
        firstPane="t"

        #echo "blah |$sCurrentURI|"
        # iterate through listing
        for currentIP in $(echo $sCurrentURI | sed 's/:/\n/g')
        do
          if [[ "$firstPane" == "t" ]]; then
            tmux new-session -d -s $paneName
            firstPane="f"
          else
            tmux split-window -h -t $paneName
          fi

          # get the specific entry by recreating sCurrentURI keyed to IP
          # need the end of line to cap off the ip output
          #                    tmCurrentURI=$(grep -i $sSearch $sFileTarget | grep "${currentIP}\$")
          tmCurrentURI=$(grep -i $sSearch $sFileTarget | grep "${currentIP}\$" | sed "s/\^/ /g" )
          becho "mapping $tmCurrentURI | $currentIP"

          # generate the output properly
          #echo "| jsh $tmCurrentURI $sAllArgs |"

          jshCommand="jsh"
          # send command to the output properly
          tmux send-keys -t "$paneName" "$jshCommand $tmCurrentURI $sAllArgs -inTM" Enter

          # have to readjust pane space after you add a new pane
          # (the panes are divided in half between on the current pane so
          # you will eventually get smaller and smaller panes for the next
          # session.  Will run out of pane space after about 7 panes
          # more will not be created
          tmux select-layout -t "$paneName" even-horizontal

          #echo "\"jsh $tmCurrentURI $currentIP\" "
          #tmuxCommand="$tmuxCommand \"jsh $tmCurrentURI $currentIP\" "
        done

        # firstPane to false means there was at least 1 tmux session.
        if [[ "$firstPane" == "f" ]]; then

          # I want to select the left most pane so just go right to warp
          # to the left most pane
          tmux select-pane -t "$paneName" -R

          #tmux select-layout -t "$paneName" tiled
          #tmux select-layout -t "$paneName" even-horizontal
          tmux select-layout -t "$paneName" even-vertical
          tmux set-window-option -t "$paneName" synchronize-panes on
          tmux attach -t "$paneName"

        fi

        # done don't process any other conditionals
        return
      else

        # connect regularly
        debugme "connect string $sSearch"
        debugme "string should be $sCurrentURI";
        #echo "found user $sUser"
        if [[ "$sUser" != "" ]]; then
          sUser="$sUser@"
        fi

        if [[ "$sUserManuallySet" != "true" ]]; then

          # find user based on ip
          foundUser=$(isAWS $sCurrentURI)
          #echo "found user being $foundUser $sCurrentURI"

          if [[ "$foundUser" != "" ]]; then
            sUser="$foundUser@"
          fi

        fi

        if [[ "$sRefreshKnownKey" = 'true' ]]; then

          #ssh-keygen -R $sUser$sCurrentURI
          echo "refresh key $sCurrentURI"
          ssh-keygen -R $sCurrentURI

        fi

        if [[ $sPassword ]]; then

          echo "no pass $sSearch" >> $explainFile
          # echo "login: $sUser$sCurrentURI $sPassword" #'$sExecuteCommand'"
          if [[ $royal_do_not_connect -eq "0" ]]; then
            # restart service
            if [[ $sServiceEnabled -eq "1" ]]; then
              # echo "assh service"
              assh $sUser$sCurrentURI $sPassword "$sServicePathPre/$sService/$sServicePathPost $sServiceType"
            elif [[ "$sList" = "true" ]]; then
              # echo "assh list services"
              assh $sUser$sCurrentURI $sPassword "ls $sServicePathPre"
            elif [[ "$sDoc" -eq "1" ]]; then
              # echo "assh docker"
              assh $sUser$sCurrentURI $sPassword "docker ps"
            elif [[ "$sExecuteCommand" != "" ]]; then
              # echo "assh execute"
              assh $sUser$sCurrentURI $sPassword "$sExecuteCommand"
            else
              # echo "assh "
              assh $sUser$sCurrentURI $sPassword #'$sExecuteCommand'
            fi
          fi

        else

          echo "ssh $sUser$sCurrentURI" >> $explainFile
          if [[ $royal_do_not_connect -eq "0" ]]; then

            if [[ $sServiceEnabled -eq "1" ]]; then
              echo "ssh services"
              ssh $sUser$sCurrentURI "$sServicePathPre/$sService/$sServicePathPost $sServiceType"
            elif [[ "$sDoc" -eq "1" ]]; then
              echo "ssh stats"
              ssh $sUser$sCurrentURI "docker ps"
            elif [[ "$sExecuteCommand" != "" ]]; then
              echo "ssh execute"
              ssh $sUser$sCurrentURI "$sExecuteCommand"
            else
              echo "ssh"
              ssh $sUser$sCurrentURI #'$sExecuteCommand'
            fi

          fi
        fi
      fi

    elif [[ $sMysqlCommand ]]; then

      if [[ "$sMysqlLogin" = 'false' ]]; then
        /usr/local/bin/mysql -h $sCurrentURI -u etadm -e "show databases;"
      else
        /usr/local/bin/mysql -h $sCurrentURI -u etadm $sMysqlLogin
      fi

    else

      # echo "else: $sSearch" >> $explainFile
      # if it has something to exclude run the exclusion
      if [[ "$sNotInclude" != "" ]]; then
        #echo "blah1"
        grep -i "$sSearch" $sFileTarget | grep -iv $sNotInclude
      else

        if [[ "$sPrettyPrint" = 'true' ]]; then
          #echo "blah2"
          grep -i "$sSearch" $sFileTarget | sed 's/\^.*=/=/g'
        else
          #echo "blah3"
          grep -i "$sSearch" $sFileTarget
        fi

      fi

      if [[ $sIndex != "0" ]]; then
        currentOutput=$(grep -i "$sSearch" $sFileTarget | head -n $sIndex | tail -n 1)
        echo "\nindex => $currentOutput"
      fi
    fi

  else

    # echo "cat? $sSearch" >> $explainFile
    cat $sFileTarget

  fi

}

if [[ $# -gt 0 ]]; then
  jsh -fzf $@
fi
