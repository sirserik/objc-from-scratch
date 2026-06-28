#import <Foundation/Foundation.h>

/* Контракт: «умею назвать себя и сказать свою цену». */
@protocol Sellable <NSObject>
- (NSString *)title;
- (double)price;
@end

/* Книга принимает контракт Sellable. */
@interface Book : NSObject <Sellable>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *author;
@property (nonatomic) double cost;
- (instancetype)initWithName:(NSString *)name
                      author:(NSString *)author
                        cost:(double)cost;
@end

@implementation Book
- (instancetype)initWithName:(NSString *)name
                      author:(NSString *)author
                        cost:(double)cost {
    self = [super init];
    if (self) {
        _name = [name copy];
        _author = [author copy];
        _cost = cost;
    }
    return self;
}
- (NSString *)title {
    return [NSString stringWithFormat:@"«%@», %@", self.name, self.author];
}
- (double)price {
    return self.cost;
}
@end

/* Подписка — совсем другой класс, не родственник Book,
   но тоже принимает контракт Sellable. */
@interface Subscription : NSObject <Sellable>
@property (nonatomic, copy) NSString *service;
@property (nonatomic) int months;
@property (nonatomic) double perMonth;
- (instancetype)initWithService:(NSString *)service
                         months:(int)months
                       perMonth:(double)perMonth;
@end

@implementation Subscription
- (instancetype)initWithService:(NSString *)service
                         months:(int)months
                       perMonth:(double)perMonth {
    self = [super init];
    if (self) {
        _service = [service copy];
        _months = months;
        _perMonth = perMonth;
    }
    return self;
}
- (NSString *)title {
    return [NSString stringWithFormat:@"Подписка %@ (%d мес.)",
            self.service, self.months];
}
- (double)price {
    return self.months * self.perMonth;
}
@end

/* Функции важно одно: умеет ли объект title и price.
   Какого он класса — её не касается. */
static double cartTotal(NSArray *cart) {
    double total = 0;
    for (id<Sellable> item in cart) {
        NSLog(@"  %@ — %.0f ₸", [item title], [item price]);
        total += [item price];
    }
    return total;
}

int main(void) {
    @autoreleasepool {
        id<Sellable> book = [[Book alloc] initWithName:@"Чистый код"
                                                author:@"Р. Мартин"
                                                  cost:5900];
        id<Sellable> sub  = [[Subscription alloc] initWithService:@"Музыка"
                                                           months:12
                                                         perMonth:1490];

        NSLog(@"Book принял Sellable?         %@",
              [book conformsToProtocol:@protocol(Sellable)] ? @"да" : @"нет");
        NSLog(@"Subscription принял Sellable? %@",
              [sub conformsToProtocol:@protocol(Sellable)] ? @"да" : @"нет");

        NSLog(@"--- корзина ---");
        NSArray *cart = @[ book, sub ];
        double total = cartTotal(cart);
        NSLog(@"Итого: %.0f ₸", total);
    }
    return 0;
}
