#import <Foundation/Foundation.h>

@interface Command : NSObject

@property(nonatomic) NSString *name;
@property(nonatomic) NSArray *args;

- (id)initWithLaunchString:(NSString *)commandString;
- (id)initWithCommand:(NSString *)command
            arguments:(NSArray<NSString *> *)arguments;
- (NSData *)execute;
- (NSString *)description;

@end

/* vim: set ft=objc: */
