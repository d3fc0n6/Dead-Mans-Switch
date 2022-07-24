# Dead Mans Switch
> A dead man's switch is a switch that is designed to be activated or deactivated if the human operator becomes incapacitated, such as through death, loss of consciousness, or being bodily removed from control.

## What it does
In the event you are unable to get access to your system for a certain period of days this script will automatically run any scripts you have provided.

## Setup
Download the script and put it into its own directory. Afterwords put a scripts directory inside of it and add your scripts into it.
Naming scheme must be **DMS-NAMEHERE.sh**

Be sure to edit the script and change the **userName**, **inactiveDays**, and **shouldWait** options.

## Structure

```
└── DMS/
    ├── dms.sh
    └── scripts/
        └── DMS-testscript.sh
```

## Possible issues
* If the user that is listed in the script doesn't have journalctl access we will fall back to using lastlog instead
* May not be compatible with non-systemd systems *(Aslong as your system has lastlog it should be good)*



