#import <Foundation/Foundation.h>

/* Задача: реализуй isEqual: + hash правильно. Если hash не согласован с
   isEqual:, объект «теряется» в NSSet/NSDictionary. Показываем оба
   класса: сломанный (без hash) и правильный. */

/* --- Сломанный: переопределил isEqual:, но НЕ hash --- */
@interface BrokenMoney : NSObject
@property (nonatomic) NSInteger amount;
@end
@implementation BrokenMoney
- (BOOL)isEqual:(id)other {
    if (self == other) return YES;
    if (![other isKindOfClass:[BrokenMoney class]]) return NO;
    return self.amount == ((BrokenMoney *)other).amount;
}
/* hash не переопределён → у равных объектов РАЗНЫЙ hash (адрес) */
@end

/* --- Правильный: isEqual: и hash согласованы --- */
@interface Money : NSObject
@property (nonatomic) NSInteger amount;
@end
@implementation Money
- (BOOL)isEqual:(id)other {
    if (self == other) return YES;
    if (![other isKindOfClass:[Money class]]) return NO;
    return self.amount == ((Money *)other).amount;
}
- (NSUInteger)hash { return (NSUInteger)self.amount; }
@end

static BrokenMoney *broken(NSInteger a) {
    BrokenMoney *m = [[BrokenMoney alloc] init]; m.amount = a; return m;
}
static Money *money(NSInteger a) {
    Money *m = [[Money alloc] init]; m.amount = a; return m;
}

int main(void) {
    @autoreleasepool {
        NSLog(@"=== сломанный (hash не согласован) ===");
        NSSet *bs = [NSSet setWithObjects:broken(100), broken(100), nil];
        NSLog(@"в множестве объектов: %lu (ждали 1)",
              (unsigned long)bs.count);
        NSLog(@"containsObject(100)? %@",
              [bs containsObject:broken(100)] ? @"да" : @"НЕТ");

        NSLog(@"=== правильный (isEqual + hash) ===");
        NSSet *ms = [NSSet setWithObjects:money(100), money(100), nil];
        NSLog(@"в множестве объектов: %lu (ждали 1)",
              (unsigned long)ms.count);
        NSLog(@"containsObject(100)? %@",
              [ms containsObject:money(100)] ? @"да" : @"нет");
    }
    return 0;
}
