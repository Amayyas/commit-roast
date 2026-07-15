#ifndef CR_ANSI_H
#define CR_ANSI_H

// Every escape code lives here. Nothing else in the codebase writes "\033[" by
// hand, which is what makes --no-color a single switch rather than a hunt.
#define CR_ANSI_RESET   "\033[0m"
#define CR_ANSI_BOLD    "\033[1m"
#define CR_ANSI_DIM     "\033[2m"
#define CR_ANSI_RED     "\033[31m"
#define CR_ANSI_GREEN   "\033[32m"
#define CR_ANSI_YELLOW  "\033[33m"
#define CR_ANSI_CYAN    "\033[36m"
#define CR_ANSI_GRAY    "\033[90m"

#endif /* CR_ANSI_H */
