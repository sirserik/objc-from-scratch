#import <Foundation/Foundation.h>

/* isKindOfClass: — «этот класс ИЛИ его потомок?» (учитывает наследование).
   isMemberOfClass: — «РОВНО этот класс?» (точное совпадение, без потомков). */
@interface Animal : NSObject
@end
@implementation Animal
@end

@interface Dog : Animal
@end
@implementation Dog
@end

int main(void) {
    @autoreleasepool {
        Dog *d = [Dog new];

        NSLog(@"isKindOfClass:Dog      = %d", [d isKindOfClass:[Dog class]]);
        NSLog(@"isKindOfClass:Animal   = %d", [d isKindOfClass:[Animal class]]);
        NSLog(@"isKindOfClass:NSObject = %d", [d isKindOfClass:[NSObject class]]);

        NSLog(@"isMemberOfClass:Dog    = %d", [d isMemberOfClass:[Dog class]]);
        NSLog(@"isMemberOfClass:Animal = %d", [d isMemberOfClass:[Animal class]]);
    }
    return 0;
}
