#import "ConfigLoader.h"

@implementation ConfigLoader

+ (NSArray *)loadConfigFromFile:(NSString *)filePath error:(NSError **)error {
  NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:error];
  if (!data) {
    NSLog(@"Error reading config file: %@", *error);
    return nil;
  }

  NSArray *config = [NSJSONSerialization JSONObjectWithData:data
                                                    options:0
                                                      error:error];
  if (!config) {
    NSLog(@"Error parsing JSON config: %@", *error);
    return nil;
  }

  if (![config isKindOfClass:[NSArray class]]) {
    NSLog(@"Config file root must be an array: %@", config);
    return nil;
  }

  return config;
}

@end
