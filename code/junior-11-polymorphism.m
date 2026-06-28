#import <Foundation/Foundation.h>

/* Полиморфизм: метод выбирается во время выполнения по РЕАЛЬНОМУ классу
   объекта, а не по типу переменной. describe объявлен один раз в Animal,
   но печатает разный sound — каждый потомок отвечает по-своему. */
@interface Animal : NSObject
- (NSString *)sound;
- (void)describe;
@end

@implementation Animal
- (NSString *)sound { return @"..."; }
- (void)describe {
    NSLog(@"%@ говорит: %@", NSStringFromClass([self class]), [self sound]);
}
@end

@interface Dog : Animal
@end
@implementation Dog
- (NSString *)sound { return @"Гав"; }
@end

@interface Cat : Animal
@end
@implementation Cat
- (NSString *)sound { return @"Мяу"; }
@end

int main(void) {
    @autoreleasepool {
        NSArray *zoo = @[[Animal new], [Dog new], [Cat new]];
        for (Animal *a in zoo) {
            [a describe];   /* sound выберется по фактическому классу */
        }
    }
    return 0;
}
