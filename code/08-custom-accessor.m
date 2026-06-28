#import <Foundation/Foundation.h>

@interface Account : NSObject
/* Своё имя геттеру: для BOOL принято isPaid вместо paid. */
@property (nonatomic, assign, getter=isPaid) BOOL paid;
/* Это свойство мы аксессируем вручную: храним сумму в тиынах,
   а наружу отдаём тенге. readonly — снаружи только читают. */
@property (nonatomic, readonly) double balance;
@end

@implementation Account {
    NSInteger _tiyn;   /* свой ivar: 1 тенге = 100 тиын */
}

/* Ручной геттер для balance. @property(readonly) обещал его наличие,
   мы его пишем сами — компилятор автосинтез не делает. */
- (double)balance {
    return _tiyn / 100.0;
}

/* Свой метод, который меняет приватный ivar напрямую. */
- (void)depositTenge:(double)tenge {
    _tiyn += (NSInteger)(tenge * 100);
}

@end

int main(void) {
    @autoreleasepool {
        Account *a = [[Account alloc] init];

        [a depositTenge:150.50];
        a.paid = YES;

        /* a.balance вызывает наш ручной геттер. */
        NSLog(@"баланс: %.2f тг", a.balance);
        /* getter=isPaid: точка зовёт isPaid, а не paid. */
        NSLog(@"оплачено: %@", a.isPaid ? @"да" : @"нет");
    }
    return 0;
}
