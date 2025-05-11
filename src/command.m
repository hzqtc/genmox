#import "command.h"

@implementation Command

@synthesize name, args;

-(id) initWithLaunchString: (NSString *) commandString {
  NSLog(@"Init command: %@", commandString);
  if ([self init]) {
    NSArray *components = [commandString componentsSeparatedByString: @" "];
    self.name = [components objectAtIndex: 0];
    NSRange argRange = {
      .location = 1,
      .length = [components count] - 1
    };
    self.args = [components subarrayWithRange: argRange];
  }
  return self;
}

-(NSData *) execute {
  if (name == nil) {
    return nil;
  }

  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath: name];

  [task setArguments: args];

  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput: pipe];
  NSFileHandle *file = [pipe fileHandleForReading];

  @try {
    [task launch];
  }
  @catch (NSException *exception) {
    NSLog(@"Command '%@' execute failed: %@", self, exception);
    return nil;
  }

  return [file readDataToEndOfFile];
}

-(NSString *) description {
  NSMutableArray *components = [NSMutableArray arrayWithArray: self.args];
  [components insertObject: self.name atIndex: 0];
  NSString *desc = [components componentsJoinedByString: @" "];
  return desc;
}

@end

/* vim: set ft=objc: */
