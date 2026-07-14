#import "CRGitLogReader.h"

#import "CRError.h"

// %H sha, %an author name, %ae author email, %aI strict ISO 8601 date,
// %s subject, %b body — then a record separator to close the commit.
static NSString *const kCRPrettyFormat =
    @"--pretty=format:%H" @CR_FIELD_SEPARATOR
    @"%an" @CR_FIELD_SEPARATOR
    @"%ae" @CR_FIELD_SEPARATOR
    @"%aI" @CR_FIELD_SEPARATOR
    @"%s" @CR_FIELD_SEPARATOR
    @"%b" @CR_RECORD_SEPARATOR;

// The result of running git once.
typedef struct {
    int status;
    NSData *stdoutData;
    NSString *stderrText;
} CRGitResult;

@implementation CRGitLogReader

#pragma mark - Locating git

// NSTask *raises* if its launch path does not exist — it does not return an
// error. So git is resolved up front, and a missing git becomes a clean NSError
// instead of an uncaught exception that kills the process.
- (NSString *)resolveGitPath
{
    if (_gitPath != nil) {
        return _gitPath;
    }

    NSString *pathVar = [[[NSProcessInfo processInfo] environment] objectForKey:@"PATH"];
    NSArray *directories = [(pathVar ?: @"") componentsSeparatedByString:@":"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSEnumerator *e = [directories objectEnumerator];
    NSString *directory = nil;
    while ((directory = [e nextObject]) != nil) {
        if ([directory length] == 0) {
            continue;
        }
        NSString *candidate = [directory stringByAppendingPathComponent:@"git"];
        if ([fileManager isExecutableFileAtPath:candidate]) {
            _gitPath = [candidate copy];
            return _gitPath;
        }
    }
    return nil;
}

#pragma mark - Running git

- (CRGitResult)runGitWithArguments:(NSArray *)arguments
{
    CRGitResult result;
    result.status = -1;
    result.stdoutData = nil;
    result.stderrText = @"";

    NSTask *task = [[NSTask alloc] init];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];

    [task setLaunchPath:_gitPath];
    [task setArguments:arguments];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];

    // git localizes its messages (this machine reports "n'est pas un dépôt
    // git"). Pinning the locale keeps anything we surface to the user stable and
    // in English — we still never *parse* stderr, only exit codes.
    NSMutableDictionary *env =
        [[[[NSProcessInfo processInfo] environment] mutableCopy] autorelease];
    [env setObject:@"C" forKey:@"LC_ALL"];
    [task setEnvironment:env];

    @try {
        [task launch];
    }
    @catch (NSException *exception) {
        [task release];
        return result;
    }

    // Drain stdout *before* waiting. git streams the log into a pipe whose
    // buffer is finite (64 KiB): on a large history it fills, git blocks on
    // write, and a waitUntilExit here would block forever. Reading to EOF first
    // is what keeps a 10,000-commit repository from deadlocking.
    result.stdoutData = [[[outPipe fileHandleForReading] readDataToEndOfFile] retain];

    NSData *errData = [[errPipe fileHandleForReading] readDataToEndOfFile];
    NSString *errText = [[[NSString alloc] initWithData:errData
                                               encoding:NSUTF8StringEncoding] autorelease];
    result.stderrText = [[(errText ?: @"")
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];

    [task waitUntilExit];
    result.status = [task terminationStatus];

    [task release];
    return result;
}

// Runs git purely for its exit code, e.g. rev-parse probes.
- (int)runGitStatusWithArguments:(NSArray *)arguments
{
    CRGitResult result = [self runGitWithArguments:arguments];
    [result.stdoutData release];
    [result.stderrText release];
    return result.status;
}

#pragma mark - Decoding

// A failed decode returns nil, which would silently look like an empty history.
// Old repositories do carry exotic encodings, so fall back to Latin-1, which
// cannot fail, rather than dropping the whole log on the floor.
- (NSString *)decodeData:(NSData *)data
{
    NSString *text = [[[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding] autorelease];
    if (text != nil) {
        return text;
    }
    text = [[[NSString alloc] initWithData:data
                                  encoding:NSISOLatin1StringEncoding] autorelease];
    return text ?: @"";
}

#pragma mark - Public

- (NSString *)rawLogWithOptions:(CRGitLogOptions *)options error:(NSError **)error
{
    NSString *path = [options repositoryPath];

    if ([self resolveGitPath] == nil) {
        if (error) {
            *error = CRMakeError(CRErrorGitNotFound,
                                 @"git was not found on your PATH. Install git and try again.");
        }
        return nil;
    }

    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]
        || !isDirectory) {
        if (error) {
            *error = CRMakeError(CRErrorRepositoryNotFound,
                                 [NSString stringWithFormat:@"No such directory: %@", path]);
        }
        return nil;
    }

    // Exit codes, not stderr text: git's messages are localized, so matching on
    // them would break on any machine that is not in English.
    NSArray *gitDirArgs = [NSArray arrayWithObjects:@"-C", path, @"rev-parse", @"--git-dir", nil];
    if ([self runGitStatusWithArguments:gitDirArgs] != 0) {
        if (error) {
            *error = CRMakeError(CRErrorNotAGitRepository,
                                 [NSString stringWithFormat:@"Not a git repository: %@", path]);
        }
        return nil;
    }

    // A freshly `git init`ed repository is a repository; it simply has nothing
    // to roast yet. `git log` would exit 128 there, so probe HEAD first and
    // return an empty history rather than an error.
    NSArray *headArgs = [NSArray arrayWithObjects:@"-C", path, @"rev-parse", @"--verify", @"HEAD", nil];
    if ([self runGitStatusWithArguments:headArgs] != 0) {
        return @"";
    }

    // The filters (--limit, --since, --author) are appended as separate array
    // elements, never spliced into a command string. NSTask goes straight to
    // execve, so no shell ever sees them.
    NSMutableArray *logArgs = [NSMutableArray arrayWithObjects:
        @"-C", path, @"--no-pager", @"log", kCRPrettyFormat, nil];
    [logArgs addObjectsFromArray:[options gitLogArguments]];

    CRGitResult result = [self runGitWithArguments:logArgs];
    NSData *out = [result.stdoutData autorelease];
    NSString *errText = [result.stderrText autorelease];

    if (result.status != 0) {
        if (error) {
            NSString *message = ([errText length] > 0)
                ? errText
                : [NSString stringWithFormat:@"git log failed with status %d", result.status];
            *error = CRMakeError(CRErrorGitFailed, message);
        }
        return nil;
    }

    return [self decodeData:out];
}

- (void)dealloc
{
    [_gitPath release];
    [super dealloc];
}

@end
