#import <Foundation/Foundation.h>

/* Класс, который ХОРОШО мостится в Swift.
   Весь публичный интерфейс аннотирован: nullability, дженерики,
   назначенный инициализатор, не-убегающий блок, метод с NSError**.
   Каждая аннотация делает Swift-сторону красивой и безопасной. */

NS_ASSUME_NONNULL_BEGIN   /* всё ниже считается nonnull, кроме явного nullable */

/* Домен ошибок для checkout — в Swift станет частью брошенного Error. */
static NSString *const CartErrorDomain = @"CartErrorDomain";

@interface ShoppingCart : NSObject

/* nonnull (мы внутри ASSUME_NONNULL) -> в Swift это String, НЕ String? */
@property (nonatomic, copy, readonly) NSString *ownerName;

/* дженерик-массив строк -> в Swift это [String], а не [Any] */
@property (nonatomic, copy, readonly) NSArray<NSString *> *items;

/* nullable -> в Swift это String? (опционал) */
@property (nonatomic, copy, nullable) NSString *promoCode;

/* назначенный инициализатор initWithOwner: -> в Swift init(owner:) */
- (instancetype)initWithOwner:(NSString *)ownerName NS_DESIGNATED_INITIALIZER;

/* запрещаем пустой init: в Swift его просто не будет видно */
- (instancetype)init NS_UNAVAILABLE;

/* nonnull-параметр -> в Swift add(_ item: String) без опционала */
- (void)addItem:(NSString *)item;

/* nullable-возврат -> в Swift item(at:) -> String? */
- (nullable NSString *)itemAtIndex:(NSUInteger)index;

/* блок -> в Swift замыкание; NS_NOESCAPE -> не «убегающий»,
   значит в Swift замыкание без @escaping и можно ссылаться на self без self. */
- (void)enumerateItemsUsingBlock:(void (NS_NOESCAPE ^)(NSString *item,
                                                       NSUInteger index))block;

/* метод с последним параметром NSError** -> в Swift throws.
   Возвращаемый nullable NSNumber превращается в НЕ-опциональный Decimal/NSNumber,
   потому что «ошибка» теперь сигналится через throw, а не через nil. */
- (nullable NSNumber *)checkoutWithPricePerItem:(double)price
                                          error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END


@implementation ShoppingCart {
    NSMutableArray<NSString *> *_items;   /* внутреннее хранилище */
}

- (instancetype)initWithOwner:(NSString *)ownerName {
    self = [super init];
    if (self) {
        _ownerName = [ownerName copy];
        _items = [NSMutableArray array];
    }
    return self;
}

- (NSArray<NSString *> *)items {
    return [_items copy];   /* отдаём неизменяемую копию */
}

- (void)addItem:(NSString *)item {
    [_items addObject:item];
}

- (nullable NSString *)itemAtIndex:(NSUInteger)index {
    if (index >= _items.count) {
        return nil;   /* вне диапазона -> nil, в Swift это .none */
    }
    return _items[index];
}

- (void)enumerateItemsUsingBlock:(void (NS_NOESCAPE ^)(NSString *,
                                                       NSUInteger))block {
    [_items enumerateObjectsUsingBlock:^(NSString *item, NSUInteger idx,
                                         BOOL *stop) {
        (void)stop;
        block(item, idx);
    }];
}

- (nullable NSNumber *)checkoutWithPricePerItem:(double)price
                                          error:(NSError **)error {
    if (_items.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:CartErrorDomain
                                         code:1
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Корзина пуста — нечего оформлять"
            }];
        }
        return nil;   /* в Swift это превратится в throw */
    }
    double total = price * (double)_items.count;
    if (self.promoCode != nil) {
        total *= 0.9;   /* промокод -> скидка 10% */
    }
    return @(total);
}

@end


int main(void) {
    @autoreleasepool {
        ShoppingCart *cart = [[ShoppingCart alloc] initWithOwner:@"Алия"];
        [cart addItem:@"Клавиатура"];
        [cart addItem:@"Мышь"];
        [cart addItem:@"Коврик"];

        NSLog(@"Владелец: %@", cart.ownerName);
        NSLog(@"Товаров: %lu", (unsigned long)cart.items.count);

        /* nullable-возврат: есть и нет */
        NSLog(@"Товар 0: %@", [cart itemAtIndex:0]);
        NSLog(@"Товар 99: %@", [cart itemAtIndex:99]);  /* nil */

        /* перебор через блок */
        [cart enumerateItemsUsingBlock:^(NSString *item, NSUInteger index) {
            NSLog(@"  [%lu] %@", (unsigned long)index, item);
        }];

        /* успешный checkout */
        NSError *err = nil;
        NSNumber *total = [cart checkoutWithPricePerItem:1500.0 error:&err];
        if (total) {
            NSLog(@"К оплате: %@ ₸", total);
        }

        /* checkout пустой корзины -> ошибка */
        ShoppingCart *empty = [[ShoppingCart alloc] initWithOwner:@"Бекзат"];
        NSError *err2 = nil;
        NSNumber *t2 = [empty checkoutWithPricePerItem:1000.0 error:&err2];
        if (t2 == nil) {
            NSLog(@"Ошибка checkout: %@", err2.localizedDescription);
        }
    }
    return 0;
}
