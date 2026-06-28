#import <Foundation/Foundation.h>

/* Абстрактный базовый класс «по соглашению»: создавать Shape напрямую
   нельзя, но язык это не запрещает. Поэтому базовый -area — заглушка,
   которая громко падает, если подкласс забыл его переопределить. */
@interface Shape : NSObject
- (double)area;
@end

@implementation Shape
- (double)area {
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ обязан переопределить -area", [self class]];
    return 0;   /* сюда выполнение уже не дойдёт */
}
@end

@interface Circle : Shape
@property (nonatomic) double radius;
- (instancetype)initWithRadius:(double)radius;
@end

@implementation Circle
- (instancetype)initWithRadius:(double)radius {
    self = [super init];
    if (self) {
        _radius = radius;
    }
    return self;
}
- (double)area {
    return M_PI * self.radius * self.radius;
}
@end

@interface Square : Shape
@property (nonatomic) double side;
- (instancetype)initWithSide:(double)side;
@end

@implementation Square
- (instancetype)initWithSide:(double)side {
    self = [super init];
    if (self) {
        _side = side;
    }
    return self;
}
- (double)area {
    return self.side * self.side;
}
@end

int main(void) {
    @autoreleasepool {
        /* Полиморфизм: перебираем фигуры через тип базы Shape*,
           каждая считает площадь по-своему. */
        NSArray *shapes = @[ [[Circle alloc] initWithRadius:2.0],
                             [[Square alloc] initWithSide:3.0] ];
        for (Shape *s in shapes) {
            NSLog(@"%@: площадь = %.2f", [s class], [s area]);
        }

        /* А вот что будет, если создать «голую» базу и спросить площадь. */
        @try {
            Shape *raw = [[Shape alloc] init];
            [raw area];
        } @catch (NSException *ex) {
            NSLog(@"Поймали исключение: %@", ex.reason);
        }
    }
    return 0;
}
