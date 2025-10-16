#!/bin/bash

set -gx royal_debug_me 0
set -gx royal_last_is_switch 1
set -gx royal_last_is_empty 1
set -gx royal_delimiter_1 "\^"
set -gx royal_delimiter_2 "\^"
set -gx royal_last_command ~/lab/scripts/mappings
set -gx MODE_FZF ''

alias vijumplast="vim ~/lab/scripts/mappings/.jumplast"
alias psht="jsh -P -tm"
alias psh="jsh -P"
alias jlc="jsh -l -c"
alias jl="jsh -l"
alias jtm="jsh -l -tm -c"
alias jsht="jsh -tm"
alias jshf="jsh -f"
alias jsf="jsh -f"

set -gx royal_file_target ~/lab/scripts/mappings/devall.txt
set -gx royal_file_pass_target ~/lab/scripts/mappings/passall.txt
set -gx royal_file_prod_target ~/lab/scripts/mappings/prodall.txt
set -gx royal_file_prod_pass_target ~/lab/scripts/mappings/passprodall.txt
set -gx royal_last_search_file ~/lab/scripts/mappings/searchstring.txt

function resetroyalsettings

  set royal_debug_me 0
  set royal_last_is_switch 1
  set royal_last_is_empty 1

end

function debugme

  if [ "$royal_debug_me" -eq "1" ]
    echo ">> DEBUG: $argv[1]"
  end

end

function assh

  cop $argv[2]
  set S_HOST $argv[1]
  set argv $argv[2..-1]
  set argv $argv[2..-1]
  sssh $S_HOST "$argv"

end

function nextIsEmpty

  set royal_last_is_empty 1
  if [ "$argv[1]" = "" ] ;
    debugme "is empty"
    set royal_last_is_empty 0
  end
  debugme "is not empty"

end

function nextIsASwitch

  set royal_last_is_switch 1
  pecho "switch statement |$argv[1]|"
  if string match -q -- '-*' $argv[1]
    debugme "is switch"
    set royal_last_is_switch 0
  end
  debugme "is not switch"

end


function jshm

  jsh $(tuijsh)

end

# jltm -u -p tmn
function jltm

  if test (count $argv) -gt 2
    jsh -l -c -u $argv[1] -p $argv[2] -tmn $argv[3]
  else if test (count $argv) -gt 1
    jsh -l -c -u $argv[1] -p $argv[2] -tm
  else if test (count $argv) -gt 0
    jsh -l -c -u $argv[1] -tm
  else
    jsh -l -c -tm
  end

end

# if something like root@10.231.22.30 we want to separate the root and 10.231.22.30 portion out
function sshIPPortion

  if test (count $argv) -gt 0

    # search for @ in value
    if string match -rq '@' $argv[1]

      set ipPortion (string split '@' $argv[1])[2]
      echo "$ipPortion"
      return

    end
  end
  echo "$argv"

end

function sshUserPortion

  if test (count $argv) -gt 0
    # search for @ in value
    if string match -q '*@*' $argv[1]
      set userPortion $(echo "$argv[1]" | sed -r 's/(.*)@(.*)$/\1/')
      echo "$userPortion"
      return
    end
  end
  echo "$argv"

end


function isAWS

  # set it to centos if it's currently aws server
  switch $argv[1]

    case '10.80.*' # dev aws
      echo -n "centos"
    case '10.131.1.*' # prod aws
      echo -n "centos"
    case '10.131.2.*'  # prod aws
      echo -n "centos"
    case '10.131.4.*' # prod aws
      echo -n "centos"
    case '10.132.*' # prod aws
      echo -n "centos"
  end

end

function jsh

  # echo -e "test1\ntest2\ntest3"
  # return

  resetroyalsettings

  set sFileTarget "$royal_file_target"
  set sFileProdTarget "$royal_file_prod_target"
  set sLastFile "$royal_last_command/.jumplast"
  set modeProduction ''

  set jshquery /tmp/jsh-query
  set explainFile /tmp/jsh-explain
  echo -n "" >  $explainFile

  set sLastCommand "$argv"
  set sLast 'false'
  set postfixValues ''

  set MODE_FZF ''
  # echo "$argv" > $jshquery


  if test (count $argv) -eq 0
    echo "No arguments. Last query: \"$(cat $jshquery)\""
    return 0
  end

  set key "$argv[1]"
  # echo "first $key"

  # for n in $(echo $newKeys); do
  #   echo "arg $n"
  # end

  set argv $argv[2..-1]


  if [ "$key" = '-f' ]

    # ignore all output
    while test (count $argv) -gt 0
      set argv $argv[2..-1]
    end

    echo "$(cat $jshquery)"
    # leading args into param
    set cIndex "1"
    for n in $(cat $jshquery); do
      # echo "index $cIndex $n"
      eval "set cIndex \"$n\""
      set cIndex $(expr $cIndex + 1)
    end

    # echo "all args $argv"
    set key "$argv[1]"
    set argv $argv[2..-1]

  else if [ "$key" = '-fzf' ]

    set MODE_FZF 't'
    set key "$argv[1]"

    if [ $MODE_FZF ]
      echo "$argv" > $jshquery
    end

    if test (count $argv) -gt 0
      set argv $argv[2..-1]
    end

  else if [ "$key" = '-P' ]

    set sFileTarget $sFileProdTarget
    set modeProduction 't'

    set key "$argv[1]"
    if test (count $argv) -gt 0
      set argv $argv[2..-1]
    end

  else

    if [ $MODE_FZF ]
      echo "$argv" > $jshquery
    end

  end

  # we don't want the search string.
  # variable will be useful only for tmux
  set sSearch $(sshIPPortion $key)

  if string match -q '*@*' $key
    set userPortion $(sshUserPortion $key)
    #echo "$userPortion@"
    # remove user from ssh
    set sLastCommand $(echo "$sLastCommand" | sed -r "s/$userPortion@//g")
    echo "$sLastCommand"
  end

  #set sSearch $key
  #echo $sLastCommand
  #echo "$sSearch"
  #return

  if [ "$sSearch" = '-l' ]

    # save all arguements to list z
    # empty out all arguements
    set currentArg ""

    while test (count $argv) -gt 0

      set currentArg "$currentArg $key"
      set key "$argv[1]"
      set argv $argv[2..-1]

    end

    set paramList "$currentArg"
    # reload args with the .jumplist
    set cIndex "1"

    for n in $(cat $sLastFile)

      eval "set cIndex \"$n\""
      set cIndex $(expr $cIndex + 1)

    end
    set paramList "[$argv] $paramList"

    # restore args
    for n in $(echo $currentArg)

      eval "set cIndex \"$n\""
      set cIndex $(expr $cIndex + 1)

    end

    echo "$paramList"

    # add back in the z arguements
    # reset sSearch value
    set sLast 'true'
    set sSearch $key

    #echo "$sSearch"
    #    else
    #        echo "$argv" > $royal_last_command/.jumplast

  end

  # set argv $argv[2..-1]

  #set sAllArgs "${@}"
  set sAllArgs ""

  if [ $sSearch = '-lp' ]
    cat $sFileProdTarget
    return
  end

  set defaultPing 10
  set sConnect 'false'
  set sCopyOutputCommand ''
  set sDoc 0
  set sExecuteCommand ""
  set sInTM 'false'
  set sIndex "0"
  set sList 'false'
  set sManual 'false'
  set sMysqlCommand ''
  set sMysqlLogin 'false'
  set sNotInclude ""
  set sPassword ''
  set sPasswordSwitch 'false'
  set sPing 'false'
  set sPrettyPrint 'false'
  set sRefreshKnownKey 'false'
  set sService 'web'
  set sServiceEnabled 0
  set sServicePathPost 'bin/service.sh'
  set sServicePathPre '/et/services'
  set sServiceType 'status'
  set sTmux ''
  set sTmuxName ''
  set sUser ''
  set sUserManuallySet 'false'
  set optHead 0
  set optTail 100
  set optGetDNS ''
  set modeSCP ''

  if string match -rq -- ' -d ' "$argv"
    set royal_debug_me 1
    echo "================ SET DEBUG"
  end

  set lastArg1 ""
  set lastArg2 ""
  while test (count $argv) -gt 0

    set key "$argv[1]"
    # echo "key $argv[1]"
    #echo "starting $sAllArgs"

    # leave space intentionally 
    set lastArg1 " $argv[1]"
    set lastArg2 ""

    set argv $argv[2..-1]

    switch $key

      # check to see if number
      # +([0-9]) ) 
      #
      #   if [ $optTail -eq 100 ]
      #     set optTail $key
      #     echo "change end to $key"
      #   else
      #     set optHead $key
      #     set optHead $((optHead + 1))
      #     echo "change start to $key"
      #   end
      #

      case "-fetch"
        set optGetDNS 't'
        echo "fetch value is $key" 
      case '-s' # debug skip it
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-c' # too lazy to type

        set sConnect 'true'
        echo "connect" >> $explainFile
        # if this hasn't been set already
        if [ "" = "$sUser" ]
          set sUser "etadm"
        end
        # if this hasn't been set already
        if [ "" = "$sPassword" ]
          set sPassword "p"
        end

        set foundUser $(isAWS $sCurrentURI)
        if [ $foundUser ]
          set sUser $foundUser
        end

        # remove from list
        set sLastCommand string replace "-c" "" $sLastCommand

        set postfixValues "$postfixValues -c"

        echo "-c with user $sUser?" > $explainFile

      case '-scp'
        set modeSCP "$argv[1]"
        set argv $argv[2..-1]
        set postfixValues "$postfixValues -scp $modeSCP"
        echo "scp: path $modeSCP" >> $explainFile

      case '-n'
        set sIndex "$argv[1]"

        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-ping'
        set defaultPing $argv[1]
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-inTM'
        set sInTM 'true'
      case '-list' # service
        set sList 'true'
      case '-et' # service
        # copy this command options to connect
        # if this hasn't been set already
        set sConnect 'true'
        if [ "" = "$sUser" ]
          set sUser "etadm"
        end
        # if this hasn't been set already
        if [ "" = "$sPassword" ]
          set sPassword "p"
        end

        # regular command
        set sServiceEnabled 1
        set sService "$argv[1]"
        set lastArg2 " $argv[1]"

        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end


        # grab service type
        set sServiceType "$argv[1]"
        set lastArg2 "$lastArg2 $argv[1]"

        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end


      case '-tm'

        set sTmux 'true'

        # blank out the statements
        set lastArg1 ""
        set lastArg2 ""
        echo "tmux" >> $explainFile

        set sLastCommand string replace "-tm" "" $sLastCommand
        set postfixValues "$postfixValues -tm"

        # this doesn't work properly

      case '-tmu'
        set sTmux 'true'
        set sConnect 'true'
        set sUser "$argv[1]"

        # add to the last arguement -c because we want to connect
        set lastArg1 " -c"
        set lastArg2 " -u $sUser"
        echo "tmux multi connect with user $sUser" >> $explainFile

        # if this hasn't been set already
        if [ "" = "$sUser" ]
          set sUser "etadm"
        end
        # if this hasn't been set already
        if [ "" = "$sPassword" ]
          set sPassword "p"
        end

        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end


        # remove from list
        set sLastCommand string replace "-tmu" "" $sLastCommand
        set sLastCommand string replace "$sUser" "" $sLastCommand

        set postfixValues "$postfixValues -tmu $sUser"



      # this doesn't work properly
      case '-tmc'

        set sTmux 'true'
        set sConnect 'true'

        # add to the last arguement -c because we want to connect
        set lastArg1 " -c"
        set lastArg2 ""
        echo "tmux multi connect" >> $explainFile

        # if this hasn't been set already
        if [ "" = "$sUser" ]
          set sUser "etadm"
        end
        # if this hasn't been set already
        if [ "" = "$sPassword" ]
          set sPassword "p"
        end

        # remove from list
        set sLastCommand string replace "-tmc" "" $sLastCommand
        set postfixValues "$postfixValues -tmc"


      case '-tmn'
        set sTmux 'true'
        set sTmuxName "$argv[1]"

        # blank out the statements
        set lastArg1 ""
        set lastArg2 ""

        set sLastCommand string replace "-tmn $sTmuxName=" "" $sLastCommand
        set postfixValues "$postfixValues -tmn $sTmuxName"

        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-C' 
        set sCopyOutputCommand 'ip' 
        set postfixValues "$postfixValues -C"
        echo "copy: ip" >> $explainFile
      case '-CC' 
        set sCopyOutputCommand 'hostnameandip' 
        set postfixValues "$postfixValues -C"
        echo "copy: name and ip" >> $explainFile
      case '-r' set sRefreshKnownKey 'true' 
      case '-pretty' set sPrettyPrint 'true' 
      case '-P' # grab password
        debugme "password"
        set sPasswordSwitch 'true'
        set sConnect 'true'
        set sPassword "$argv[1]"
        pecho "next is a value $sPassword"
        set lastArg2 " $sPassword"
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-j' # path zk
        set -gx copy_path ""
        switch $argv[1] 
          case 'local'
            set -gx copy_path "cd /et/local/services"
          case 'serv'
            set -gx copy_path "cd /et/services"
          case 'soft'
            set -gx copy_path "cd /et/software/cas"
          case 'install'
            set -gx copy_path "cd /et/install"
          case 'zkstat'
            set -gx copy_path "/et/software/zkp/bin/zkServer.sh status"
          case 'zkc'
            set -gx copy_path "/et/software/zkp/bin/zkCli.sh"
          case '*'
            set -gx copy_path "$argv[1]"
        end
        # if you have a command let's tack on the bash
        echo "$copy_path" | pbcopy
        set lastArg2 "$copy_path"
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-doc' # docker states
        set sDoc 1
      case '-ur' # user
        set sUser "root"
        set sConnect 'true'
        set sUserManuallySet 'true'
        set sPassword "e"
      case '-u' # user
        set sUser "$argv[1]"
        set sConnect 'true'
        set sUserManuallySet 'true'
        nextIsASwitch $argv[1]
        nextIsEmpty $argv[1]
        debugme "last command results is $royal_last_is_switch"

        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

        # is a switch then just assign the value
        if [ "$royal_last_is_switch" -eq "0" ]
          debugme "is a switch assign etadm"
          set sUser "etadm"
        else if [ "$royal_last_is_empty" -eq "0" ]
          debugme "empty assign etadm"
          set sUser "etadm"
        end

        set lastArg2 " $sUser"
        switch $sUser
          case 'root'
            # echo "root user password"
            set sPassword "e"
          case 'oracle'
            # echo "oracle password"
            set sPassword "o"
          case '*'
            set sPassword "p"
            # echo "no password assumed"
        end

        set sLastCommand string replace "-u" "" $sLastCommand
        set sLastCommand string replace "$sUser" "" $sLastCommand
        set postfixValues "$postfixValues -u $sUser"
        echo "user: $sUser" >> $explainFile

        # debugme "user is $sUser"

      case '-t' # ping it
        set sPing 'true'
        set sLastCommand string replace "-t" "" $sLastCommand
        set postfixValues "$postfixValues -t"
        echo "ping" >> $explainFile
      case '-m' # manually connect with the string
        set sManual 'true'
      case '-a' # add on to the search term
        set sSearch "$sSearch.*$argv[1]"
        debugme $sSearch
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-v' # does not include
        set sNotInclude "$argv[1]"
        debugme "exclude $sNotInclude"
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-exec' # record and quit
        set sExecuteCommand "$argv[1]"
        set lastArg2 " $sExecuteCommand"
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-qq'
        set sMysqlCommand 'true'
        set sMysqlLogin "$argv[1]"
        set lastArg2 " $argv[1]"
        if test (count $argv) -gt 0
          set argv $argv[2..-1]
        end

      case '-q'
        set sMysqlCommand 'true'
      case '-p' # use production list
        set sFileTarget $sFileProdTarget
        set modeProduction 't'
      case '*'
        debugme "add to search $key"
        set lastArg1 ""
        set lastArg2 ""
        set sSearch "$sSearch.*$key"
    end

    # collect all args after the fact
    set sAllArgs "$sAllArgs$lastArg1$lastArg2"

  end

  # if not recall command and not in tmux
  if test "$sLast" = 'false' 
    and test "$sInTM" = 'false'
    echo "$sLastCommand" > $sLastFile
  end


  pecho "allargs | $sAllArgs |"
  echo "search term: $sSearch" >> $explainFile

  # manual seach
  if test "$sSearch" 
    or test $sManual = 'true' 
    or test $sCopyOutputCommand = 'true' 
    or test "$sPing" = 'true' 
    or test "$optGetDNS" 
    or test "$modeSCP"

    # copy the output
    if [ "$sCopyOutputCommand" = 'ip' ]
      set S_COPY $(grep -i $sSearch $sFileTarget)
      echo -n "$S_COPY" | awk -F'^' '{ print $2 }' | pbcopy
    else if [ "$sCopyOutputCommand" = 'hostnameandip' ]
      set S_COPY $(grep -i $sSearch $sFileTarget)
      echo -n "$S_COPY" | awk -F'^' '{ print $argv[1] ": " $2 }' | pbcopy
    end

    # if true don't interpret anything just run the command
    if [ "$sManual" = 'true' ]
      set sCurrentURI $sSearch
      # list jump points
    else
      #echo "grep -i \"$sSearch\" $sFileTarget | grep -o \"$royal_delimiter_1.*\" | awk -F$royal_delimiter_1 '{ print $2 }' | head -n 1)"
      # echo "file is $sFileTarget"
      # echo "searchterm $sSearch"
      set sCurrentURI $(grep -i "$sSearch" $sFileTarget | grep -o "$royal_delimiter_1.*" | awk -F$royal_delimiter_1 '{ print $2 }' | head -n 1)

      if [ "$sTmux" = "true" ]
        # echo "tmux grep -i \"$sSearch\" $sFileTarget | grep -o \"$royal_delimiter_1.*\" | awk -F$royal_delimiter_1 '{ print \$2 }'"
        set sCurrentURI (grep -i "$sSearch" $sFileTarget | tail -n +$optHead | head -n $optTail | grep -o "$royal_delimiter_1.*" | awk -F$royal_delimiter_1 '{ print $2 }' | string collect)
        echo "query $sCurrentURI"
      end

      # not include in connection run command with inverse
      if [ "$sNotInclude" != "" ]
        debugme "not include is $sNotInclude"
        echo "not include"
        set sCurrentURI $(grep -i "$sSearch" $sFileTarget | grep -o "$royal_delimiter_1.*" | grep -iv $sNotInclude | awk -F$royal_delimiter_1 '{ print $2 }')
        if [ $sIndex != "0" ]
          set sCurrentURI $(echo $sCurrentURI ep -o "$royal_delimiter_1.*" | grep -iv $sNotInclude | awk -F$royal_delimiter_1 '{ print $2 }' | head -n $sIndex | tail -n 1)
        end

        if [ "$sTmux" = "true" ]
          set sCurrentURI $(grep -i "$sSearch" $sFileTarget | tail -n +$optHead | head -n $optTail | grep -o "$royal_delimiter_1.*" | grep -iv $sNotInclude |  awk -F$royal_delimiter_1 '{ print $2 }' )
        end
      end
    end


    if [ $modeSCP ]

      scp "$sUser@$sCurrentURI:$modeSCP" .

    else if [ $optGetDNS ]

      echo "ssearch |$sSearch| true"
      set ipAddress $(nslookup $sSearch | grep -i "server" | head -n 1 | grep -o "[.+0-9]\+")
      set entryOutput "$sSearch^$ipAddress"
      echo "$entryOutput"
      echo -n "$entryOutput" | pbcopy
      return

    else if  [ $MODE_FZF ]

      # echo "fzf search term: $sSearch" >> $explainFile
      # if it has something to exclude run the exclusion
      if [ "$sNotInclude" != "" ]
        grep -i "$sSearch" $sFileTarget | grep -iv $sNotInclude | sed "s/\$/:$postfixValues/"
      else

        if [ "$sPrettyPrint" = 'true' ]
          grep -i "$sSearch" $sFileTarget | sed 's/\^.*=/=/g' | sed "s/\$/:$postfixValues/"

        else
          grep -i "$sSearch" $sFileTarget | sed "s/\$/:$postfixValues/"

        end

      end

    # start ping
    else if [ "$sPing" = 'true' ]

      debugme "ping this $sCurrentURI $defaultPing"
      #fping -c $defaultPing $sCurrentURI

      ping $sCurrentURI

    else if [ "$sConnect" = 'true' ]

      #echo "counter $counter |$sCurrentURI|"
      # split on
      #echo "tmux value $sTmux"
      # if tmux option is true create the panes by passing the ip of the currentIP variable to jsh.
      # basically using jsh to create tmux sessions that will in affect call jsh
      if [ "$sTmux" = "true" ]
        #set tmuxCommand ""
        # takes care of session names
        #                set paneName `date +"%y%m%d_%H%M%S"`
        wondertitle
        set paneName "jsh-$RANDOM_TITLE1"
        if [ $modeProduction ]
          set paneName "psh-$RANDOM_TITLE1"
        end

        if [ "$sTmuxName" != "" ]
          set paneName "$sTmuxName"
        end
        set firstPane "t"

        #echo "blah |$sCurrentURI|"
        # iterate through listing
        for currentIP in $(echo -e $sCurrentURI | sed 's/:/\n/g')
          if [ "$firstPane" = "t" ]
            tmux new-session -d -s $paneName
            set firstPane "f"
          else
            tmux split-window -h -t $paneName
          end

          # get the specific entry by recreating sCurrentURI keyed to IP
          # need the end of line to cap off the ip output
          #                    set tmCurrentURI $(grep -i $sSearch $sFileTarget | grep "$currentIP\$")
          set tmCurrentURI $(grep -i $sSearch $sFileTarget | grep "$currentIP\$" | sed "s/\^/ /g" )
          becho "mapping $tmCurrentURI | $currentIP"

          # generate the output properly
          #echo "| jsh $tmCurrentURI $sAllArgs |"

          set jshCommand "jsh"
          # send command to the output properly
          echo "sending command tmux send-keys -t '$paneName' '|$jshCommand| <$tmCurrentURI> #$sAllArgs# -inTM' Enter"
          tmux send-keys -t "$paneName" "$jshCommand $tmCurrentURI $sAllArgs -inTM" Enter
          # return

          # have to readjust pane space after you add a new pane
          # (the panes are divided in half between on the current pane so
          # you will eventually get smaller and smaller panes for the next
          # session.  Will run out of pane space after about 7 panes
          # more will not be created
          tmux select-layout -t "$paneName" even-horizontal

          #echo "\"jsh $tmCurrentURI $currentIP\" "
          #set tmuxCommand "$tmuxCommand \"jsh $tmCurrentURI $currentIP\" "
        end

        # firstPane to false means there was at least 1 tmux session.
        if [ "$firstPane" = "f" ]

          # I want to select the left most pane so just go right to warp
          # to the left most pane
          tmux select-pane -t "$paneName" -R

          #tmux select-layout -t "$paneName" tiled
          #tmux select-layout -t "$paneName" even-horizontal
          tmux select-layout -t "$paneName" even-vertical
          tmux set-window-option -t "$paneName" synchronize-panes on
          tmux attach -t "$paneName"

        end

        # end don't process any other conditionals
        return
      else

        # connect regularly
        debugme "connect string $sSearch"
        debugme "string should be $sCurrentURI";
        #echo "found user $sUser"
        if [ "$sUser" != "" ]
          set sUser "$sUser@"
        end

        if [ "$sUserManuallySet" != "true" ]

          # find user based on ip
          set foundUser $(isAWS $sCurrentURI)
          #echo "found user being $foundUser $sCurrentURI"

          if [ "$foundUser" != "" ]
            set sUser "$foundUser@"
          end

        end

        if [ "$sRefreshKnownKey" = 'true' ]

          #ssh-keygen -R $sUser$sCurrentURI
          echo "refresh key $sCurrentURI"
          ssh-keygen -R $sCurrentURI

        end

        if [ $sPassword ]

          echo "no pass $sSearch" >> $explainFile
          # echo "login: $sUser$sCurrentURI $sPassword" #'$sExecuteCommand'"
          # restart service
          if [ $sServiceEnabled -eq "1" ]
            # echo "assh service"
            assh $sUser$sCurrentURI $sPassword "$sServicePathPre/$sService/$sServicePathPost $sServiceType"
          else if [ "$sList" = "true" ]
            # echo "assh list services"
            assh $sUser$sCurrentURI $sPassword "ls $sServicePathPre"
          else if [ "$sDoc" -eq "1" ]
            # echo "assh docker"
            assh $sUser$sCurrentURI $sPassword "docker ps"
          else if [ "$sExecuteCommand" != "" ]
            # echo "assh execute"
            assh $sUser$sCurrentURI $sPassword "$sExecuteCommand"
          else
            # echo "assh "
            assh $sUser$sCurrentURI $sPassword #'$sExecuteCommand'
          end

        else

          echo "ssh $sUser$sCurrentURI" >> $explainFile
          if [ $sServiceEnabled -eq "1" ]
            echo "ssh services"
            ssh $sUser$sCurrentURI "$sServicePathPre/$sService/$sServicePathPost $sServiceType"
          else if [ "$sDoc" -eq "1" ]
            echo "ssh stats"
            ssh $sUser$sCurrentURI "docker ps"
          else if [ "$sExecuteCommand" != "" ]
            echo "ssh execute"
            ssh $sUser$sCurrentURI "$sExecuteCommand"
          else
            echo "ssh"
            ssh $sUser$sCurrentURI #'$sExecuteCommand'
          end

        end
      end

    else if [ $sMysqlCommand ]

      if [ "$sMysqlLogin" = 'false' ]
        /usr/local/bin/mysql -h $sCurrentURI -u etadm -e "show databases;"
      else
        /usr/local/bin/mysql -h $sCurrentURI -u etadm $sMysqlLogin
      end

    else

      # echo "else: $sSearch" >> $explainFile
      # if it has something to exclude run the exclusion
      if [ "$sNotInclude" != "" ]
        grep -i "$sSearch" $sFileTarget | grep -iv $sNotInclude
      else

        if [ "$sPrettyPrint" = 'true' ]
          grep -i "$sSearch" $sFileTarget | sed 's/\^.*=/=/g'
        else
          grep -i "$sSearch" $sFileTarget
        end

      end

      if [ $sIndex != "0" ]
        set currentOutput $(grep -i "$sSearch" $sFileTarget | head -n $sIndex | tail -n 1)
        echo "\nindex => $currentOutput"
      end
    end

  else

    # echo "cat? $sSearch" >> $explainFile
    cat $sFileTarget

  end

end

if test (count $argv) -gt 0
  jsh -fzf $argv
end

