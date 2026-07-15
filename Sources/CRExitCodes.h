#ifndef CR_EXIT_CODES_H
#define CR_EXIT_CODES_H

// Locked in for the whole project.
//
// The 2-for-usage split matters: a script running `commit-roast --format json`
// can tell "your repo scored badly" (never happens — success is 0) from "you
// called me wrong" (2) from "git blew up" (1), without parsing any text.
enum {
    CRExitSuccess = 0,   // ran, produced a report
    CRExitRuntimeError = 1,   // repo not found, git missing, git failed
    CRExitUsageError = 2    // bad flag, bad value, bad format
};

#endif /* CR_EXIT_CODES_H */
