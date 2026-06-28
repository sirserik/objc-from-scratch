#import <Foundation/Foundation.h>

@interface Address : NSObject
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *street;
@end
@implementation Address
@end

@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) Address *address;   /* вложенный объект */
@end
@implementation Person
@end

@interface Product : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic) double price;
@end
@implementation Product

/* удобный фабричный метод, чтобы короче создавать товары */
+ (instancetype)title:(NSString *)t price:(double)p {
    Product *prod = [[Product alloc] init];
    prod.title = t;
    prod.price = p;
    return prod;
}
@end

int main(void) {
    @autoreleasepool {
        /* --- key path: путь сквозь вложенные объекты --- */
        Address *addr = [[Address alloc] init];
        addr.city   = @"Алматы";
        addr.street = @"Абая";

        Person *p = [[Person alloc] init];
        p.name    = @"Серик";
        p.address = addr;

        /* Точка означает «зайди внутрь объекта по ключу». */
        NSLog(@"name           = %@", [p valueForKeyPath:@"name"]);
        NSLog(@"address.city   = %@", [p valueForKeyPath:@"address.city"]);
        NSLog(@"address.street = %@", [p valueForKeyPath:@"address.street"]);

        /* --- KVC и коллекции --- */
        NSArray<Product *> *cart = @[
            [Product title:@"Книга"      price:3500.0],
            [Product title:@"Наушники"   price:9900.0],
            [Product title:@"Чехол"      price:1200.0],
        ];

        /* valueForKey: на массиве собирает значения ключа со ВСЕХ элементов
           в новый массив. */
        NSArray *titles = [cart valueForKey:@"title"];
        NSLog(@"названия = %@", titles);

        NSArray *prices = [cart valueForKeyPath:@"price"];
        NSLog(@"цены     = %@", prices);

        /* Операторы коллекций начинаются с @ и считают по всему массиву. */
        NSNumber *count = [cart valueForKeyPath:@"@count"];
        NSNumber *sum   = [cart valueForKeyPath:@"@sum.price"];
        NSNumber *avg   = [cart valueForKeyPath:@"@avg.price"];
        NSNumber *max   = [cart valueForKeyPath:@"@max.price"];
        NSNumber *min   = [cart valueForKeyPath:@"@min.price"];

        NSLog(@"@count      = %@", count);
        NSLog(@"@sum.price  = %@", sum);
        NSLog(@"@avg.price  = %.2f", [avg doubleValue]);
        NSLog(@"@max.price  = %@", max);
        NSLog(@"@min.price  = %@", min);
    }
    return 0;
}
