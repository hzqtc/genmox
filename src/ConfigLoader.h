#import <Foundation/Foundation.h>

@interface ConfigLoader : NSObject

+ (NSArray *)loadConfigFromFile:(NSString *)filePath error:(NSError **)error;

@end
