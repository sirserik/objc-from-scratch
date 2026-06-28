#import <Foundation/Foundation.h>

/* Задача: реализуй NSCopying для своего класса. copyWithZone: должен
   вернуть НЕЗАВИСИМУЮ копию (менять её — не трогать оригинал). */

@interface Vec2 : NSObject <NSCopying>
@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic, copy) NSString *label;
@end

@implementation Vec2
- (id)copyWithZone:(NSZone *)zone {
    Vec2 *copy = [[[self class] allocWithZone:zone] init];
    copy.x = self.x;
    copy.y = self.y;
    copy.label = self.label;   /* свойство copy само снимет снимок строки */
    return copy;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"(%.0f, %.0f) %@",
            self.x, self.y, self.label];
}
@end

int main(void) {
    @autoreleasepool {
        Vec2 *a = [[Vec2 alloc] init];
        a.x = 1; a.y = 2; a.label = @"A";

        Vec2 *b = [a copy];     /* зовёт наш copyWithZone: */
        b.x = 100; b.label = @"B";

        NSLog(@"оригинал: %@", a);   /* (1, 2) A — не задет */
        NSLog(@"копия:    %@", b);    /* (100, 2) B */
        NSLog(@"разные объекты? %@", (a != b) ? @"да" : @"нет");
    }
    return 0;
}
