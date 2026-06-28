#import <Foundation/Foundation.h>

/* Задача: KVC — доступ по строковому имени, keyPath и коллекционные
   операторы @sum / @avg / @max. Что выведет? */

@interface Address : NSObject
@property (nonatomic, copy) NSString *city;
@end
@implementation Address
@end

@interface Employee : NSObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic)         NSInteger salary;
@property (nonatomic, strong) Address *address;
@end
@implementation Employee
@end

static Employee *emp(NSString *name, NSInteger salary, NSString *city) {
    Employee *e = [[Employee alloc] init];
    e.name = name;
    e.salary = salary;
    e.address = [[Address alloc] init];
    e.address.city = city;
    return e;
}

int main(void) {
    @autoreleasepool {
        Employee *e = emp(@"Асет", 300000, @"Алматы");

        /* чтение/запись по строковому имени */
        NSLog(@"valueForKey name = %@", [e valueForKey:@"name"]);
        [e setValue:@350000 forKey:@"salary"];   /* int упакован в NSNumber */
        NSLog(@"после setValue salary = %ld", (long)e.salary);

        /* keyPath сквозь вложенный объект */
        NSLog(@"keyPath city = %@", [e valueForKeyPath:@"address.city"]);

        NSArray<Employee *> *team = @[
            emp(@"Асет",  300000, @"Алматы"),
            emp(@"Болат", 500000, @"Астана"),
            emp(@"Дана",  400000, @"Алматы"),
        ];

        /* собрать все значения ключа из массива */
        NSLog(@"все имена: %@", [team valueForKey:@"name"]);

        /* коллекционные операторы — @ перед оператором */
        NSLog(@"@sum.salary = %@", [team valueForKeyPath:@"@sum.salary"]);
        NSLog(@"@avg.salary = %@", [team valueForKeyPath:@"@avg.salary"]);
        NSLog(@"@max.salary = %@", [team valueForKeyPath:@"@max.salary"]);
        NSLog(@"@count       = %@", [team valueForKeyPath:@"@count"]);
    }
    return 0;
}
