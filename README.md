# fix-crashplan

Script to fix crashplan after auto-install, that does not work on debian (but used to do).

## Background

Since version 10, Crashplan has broken on every auto-update for me (and others as well), because I run
it on a non-supported platform (Debian 11).

This script, "works-for-me" (TM) and fixes it. I made this script, because I wanted to make it quicker for me to fix Crashplan after updates, and because I really can't be bothered to remember the steps, or adjust them for every minor release. Also, my backup may break at times when I will be hard pressed for time. This way, I can quickly fix it.

For more information about the underlying problem, see these posts on Reddit:

* [greg_12000's 10.0 script fix](https://www.reddit.com/r/Crashplan/comments/upjjk3/fix_v10_fix_login_issue_missing_libuawso/)
* [my own 10.2 post](https://www.reddit.com/r/Crashplan/comments/w12lcb/fix_v102_crash_with_sigsegv/)

**Note:** You will have to change the variable `CRASHPLAN_NATIVE_LIBS_SOURCE` in the code, if you are not compatible with `ubuntu20`. 

## Warning

**This script is, obviously, "Run at your own risk". Please review it before running it. It does require *root* to stop and start the service, and to copy the native libs. You should not run random scripts from the internet.**

I added a lot of checks, and comments, and stuff. Do read it before running it.

## Usage
```bash
./fix-crashplan.sh
Usage: ./fix-crashplan.sh <crashplan-install-file>

Example: ./fix-crashplan.sh /tmp/CrashPlanSmb_10.2.1_15252000061021_16_Linux.tgz

You can get the install file from here: https://console.us2.crashplanpro.com/app/#/console/app-downloads
Note, that it requires login.
```

It will ask for "Ok to proceed", before actually doing anything:

```bash
./fix-crashplan.sh CrashPlanSmb_10.2.1_15252000061021_16_Linux.tgz
[fix-crashplan] 20:32:08 INFO: All tests passed
[fix-crashplan] 20:32:08 INFO: Starting installing of native libs from version 10.2.1, from ubuntu20 files.
[fix-crashplan] 20:32:08 INFO: Press return to proceed or Ctrl+C to abort
```
so you can check that its tests passes, and version number and source seems legit.

