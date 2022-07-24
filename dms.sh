#!/bin/bash
# Purpose: Dead man's switch.
# In the event of inability to verify if present such as Incapacitation or Death run a set of sub-scripts
# How it works: By taking the SSH logs or login logs (basically the same) we can tell the last time an authorized user has logged in.
# If said user has not logged in for over X amount of days then run through the sub-scripts
# This script isn't the best thing you could write but it'll work great for me

# Changeable settings
# Change username to match main account
userName="Your Username Here"
# Amount of days that we can be inactive for
inactiveDays=30
# Change to 1 to sleep 7 days if we haven't logged in for x Days (inactiveDays)
shouldWait=0

# !!------!! DO NOT CHANGE BELOW !!------!!
# !!------!! DO NOT CHANGE BELOW !!------!!
# !!------!! DO NOT CHANGE BELOW !!------!!

# Get the location of the script https://stackoverflow.com/a/246128
bashScriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Script to run
scriptsDir="$bashScriptDir/scripts"
# Colors
RED=`tput setaf 1`
GRE=`tput setaf 2`
RE=`tput sgr0`

# Check if we have everything we need to actually like run
function CheckFiles()
{
    # If we're lacking in a script directory then let's create it
    if [ ! -d $scriptsDir ]; then
        mkdir $scriptsDir
    fi
    # Loop through all DMS-*.sh files inside of scripts
    for script in $scriptsDir/DMS-*.sh; do
        if [ ! -f $script ]; then
            echo $RED"No scripts found! Add your scripts to $scriptsDir"
            echo "Scripts must start with DMS- and end with .sh"
            echo "Example: DMS-NAMEHERE.sh"$RE
            exit
        fi
    done
}

function GetLastLogin()
{
    # If our username exists in the SSH logs then let's use that; otherwise we'll just use lastlog
    if journalctl /usr/sbin/sshd --lines=10 | grep -q $userName; then
        echo $GRE"Found $userName in ssh logs"$RE
        # Print out all last 10 ssh entries, grep the userName, check if it was accepted, get the last line, cut off just the text part and convert it to an epoch format
        lastLogin=$(journalctl /usr/sbin/sshd --lines=10 | grep $userName | grep Accepted | tail -1 | cut -c1-15 | date -f - +"%s")
    else
        echo $RED"Could not find $userName in SSH logs. Falling back to lastlog"$RE
        # If our username doesn't exist here then it's probably the wrong username
        if lastlog | grep -q $userName; then
            echo $GRE"Found $userName in lastlog"$RE
            # If the user is not listed as never logging in before then let's set lastLogin
            if ! lastlog | grep $userName | grep -q "Never logged in"; then
                # Print last logins from all users, check for userName, trim whitespace, cut it down to just the 4 through 9 blocks and convert to epoch format
                lastLogin=$(lastlog | grep $userName | tr -s ' ' | cut -d ' ' -f4-9 | date -f - +"%s")
            else
                echo $RED"User $userName has never logged in before. Is the username correct?"$RE
                exit
            fi
        else
            echo $RED"Could not find $userName in lastLog. Does the user exist?"$RE
            exit
        fi
    fi
    # Clean format of when we last logged in EX: Fri 1 Jul 2022 01:07:34 PM (timezone)
    lastLoginPretty=$(date -d @$lastLogin)
    # Get the epoch format X days ago
    dateRange=$(date --date="$inactiveDays days ago" +"%s")
}
CheckFiles
GetLastLogin

# If the user has logged in within the inactiveDays period
if [ $lastLogin -ge $dateRange ]; then
    echo "User $userName has logged in within $inactiveDays days (Last Login: $lastLoginPretty)"
else # If the user hasn't logged in within the inactiveDays period then let's run all of our scripts
    echo $RED"User $userName has not logged in for $inactiveDays days (Last Login: $lastLoginPretty)"
    # If shouldWait is true then sleep for 7 days and then recheck. If we still happen to be dead then let's continue
    if [ $shouldWait -eq 1 ]; then
        sleep 7d
        # Update lastlogin data
        GetLastLogin
        # Check if we've logged in the x Days in inactiveDays (If this fails then we'll run the scripts)
        if [ $lastLogin -ge $dateRange ]; then
            echo $GRE"We've logged in!"$RE
            exit
        fi
    fi
    
    echo "Running all scripts in $scriptsDir"$RE
    # Loop through all the scripts in our script directories and run them
    # whilst I don't believe this script has any logic issues its on u if it breaks ur shit
    for script in $scriptsDir/DMS-*.sh; do
        bash $script
    done
fi
