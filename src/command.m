#import "command.h"

@implementation Command

@synthesize name, args;

- (id)initWithLaunchString:(NSString *)launchString {
  NSArray<NSString *> *components =
      [launchString componentsSeparatedByString:@" "];
  if (components.count == 0) {
    return nil;
  }

  NSString *command = components[0];
  NSArray<NSString *> *arguments =
      (components.count > 1)
          ? [components subarrayWithRange:NSMakeRange(1, components.count - 1)]
          : @[];

  return [self initWithCommand:command arguments:arguments];
}

- (id)initWithCommand:(NSString *)command
            arguments:(NSArray<NSString *> *)arguments {
  self = [super init];
  if (self) {
    self.name = command;
    self.args = arguments ?: @[];
    NSLog(@"Init command: %@ %@", self.name,
          [self.args componentsJoinedByString:@" "]);
  }
  return self;
}

- (NSData *)execute {
  if (name == nil) {
    return nil;
  }

  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:name];
  [task setArguments:args];

  NSPipe *outputPipe = [NSPipe pipe];
  [task setStandardOutput:outputPipe];

  NSPipe *errorPipe = [NSPipe pipe];
  [task setStandardError:errorPipe];

  NSFileHandle *outputReadHandle = [outputPipe fileHandleForReading];
  NSFileHandle *errorReadHandle = [errorPipe fileHandleForReading];
  NSFileHandle *outputWriteHandle = [outputPipe fileHandleForWriting];
  NSFileHandle *errorWriteHandle = [errorPipe fileHandleForWriting];

  NSError *error = nil;
  if (![task launchAndReturnError:&error]) {
    NSLog(@"Command '%@' execute failed: %@", self, error);
    [outputReadHandle closeFile];
    [errorReadHandle closeFile];
    [outputWriteHandle closeFile];
    [errorWriteHandle closeFile];
    return nil;
  }

  // Close the write ends of the pipes in the parent process. This is crucial.
  // If we don't, readDataToEndOfFile will block forever because the pipe
  // will still have one writer open (the parent process itself).
  [outputWriteHandle closeFile];
  [errorWriteHandle closeFile];

  NSData *outputData = [outputReadHandle readDataToEndOfFile];
  NSData *errorData = [errorReadHandle readDataToEndOfFile];

  // Explicitly close the read handles to avoid file descriptor leaks.
  [outputReadHandle closeFile];
  [errorReadHandle closeFile];

  if ([errorData length] > 0) {
    NSString *errorString =
        [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
    NSLog(@"Command '%@' stderr: %@", self, errorString);
  }

  return outputData;
}

- (NSString *)description {
  return [[@[ self.name ] arrayByAddingObjectsFromArray:self.args]
      componentsJoinedByString:@" "];
}

@end

/* vim: set ft=objc: */
