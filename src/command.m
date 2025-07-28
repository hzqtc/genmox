#import "command.h"

@implementation Command

@synthesize name, args;

- (id)initWithLaunchString:(NSString *)commandString {
  NSLog(@"Init command: %@", commandString);
  if ([self init]) {
    NSArray *components = [commandString componentsSeparatedByString:@" "];
    self.name = [components objectAtIndex:0];
    NSRange argRange = {.location = 1, .length = [components count] - 1};
    self.args = [components subarrayWithRange:argRange];
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

  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];

  NSFileHandle *file = [pipe fileHandleForReading];

  @try {
    [task launch];
  } @catch (NSException *exception) {
    NSLog(@"Command '%@' execute failed: %@", self, exception);
    return nil;
  }

  return [file readDataToEndOfFile];
}

- (void)execute:(void (^)(NSData *output))completion {
  if (self.name == nil) {
    if (completion)
      completion(nil);
    return;
  }

  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:self.name];
  [task setArguments:self.args];

  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];

  NSFileHandle *file = [pipe fileHandleForReading];

  // Use background reading
  [[NSNotificationCenter defaultCenter]
      addObserverForName:NSFileHandleReadToEndOfFileCompletionNotification
                  object:file
                   queue:[NSOperationQueue mainQueue]
              usingBlock:^(NSNotification *_Nonnull note) {
                NSData *outputData =
                    note.userInfo[NSFileHandleNotificationDataItem];
                if (completion) {
                  completion(outputData);
                }
              }];

  @try {
    [task launch];
    [file readToEndOfFileInBackgroundAndNotify];
  } @catch (NSException *exception) {
    NSLog(@"Command '%@' execute failed: %@", self, exception);
    if (completion)
      completion(nil);
  }
}

- (NSString *)description {
  NSMutableArray *components = [NSMutableArray arrayWithArray:self.args];
  [components insertObject:self.name atIndex:0];
  NSString *desc = [components componentsJoinedByString:@" "];
  return desc;
}

@end

/* vim: set ft=objc: */
