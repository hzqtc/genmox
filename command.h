#import <Foundation/Foundation.h>

@interface Command: NSObject

@property NSString *name;
@property NSArray *args;

-(id) initWithLaunchString: (NSString *) commandString;
-(NSData *) execute;
-(NSString *) description;

@end

/* vim: set ft=objc: */
