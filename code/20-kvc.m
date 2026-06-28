#import <Foundation/Foundation.h>

/* Обычный класс со свойствами. Ничего особенного — KVC работает с любым
   наследником NSObject «из коробки», специально включать его не надо. */
@interface Account : NSObject
@property (nonatomic, copy) NSString *owner;
@property (nonatomic) double balance;      /* примитив double */
@end

@implementation Account
@end

/* Класс БЕЗ свойств — только голое поле (ivar). Нужен, чтобы показать,
   что KVC умеет добраться даже до ivar, у которого нет ни геттера, ни
   сеттера. */
@interface Box : NSObject {
    NSString *_secret;                     /* только ivar */
}
@end

@implementation Box
@end

int main(void) {
    @autoreleasepool {
        Account *acc = [[Account alloc] init];

        /* Запись по строковому имени. Имя свойства — обычная NSString. */
        [acc setValue:@"Серик" forKey:@"owner"];
        [acc setValue:@1500.50 forKey:@"balance"];   /* @1500.50 — NSNumber */

        /* Чтение по строковому имени. */
        NSString *owner = [acc valueForKey:@"owner"];
        id balance      = [acc valueForKey:@"balance"];

        NSLog(@"владелец = %@", owner);
        NSLog(@"баланс   = %@  (класс %@)", balance, [balance class]);
        NSLog(@"баланс как double = %.2f", [balance doubleValue]);

        /* Для сравнения — те же данные через обычный доступ к свойству. */
        NSLog(@"через свойство: owner=%@ balance=%.2f",
              acc.owner, acc.balance);

        /* Теперь — доступ к голому ivar без свойства. */
        Box *box = [[Box alloc] init];
        [box setValue:@"пароль" forKey:@"secret"];   /* пишем прямо в _secret */
        NSLog(@"секрет из ivar = %@", [box valueForKey:@"secret"]);
    }
    return 0;
}
