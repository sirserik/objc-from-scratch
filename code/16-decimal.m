#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* --- Шаг 1. Наивно: складываем цены через double. --- */
        double p1 = 0.10;   /* 10 копеек */
        double p2 = 0.20;   /* 20 копеек */
        double total = p1 + p2;
        NSLog(@"double: 0.10 + 0.20 = %.17f", total);

        if (total == 0.30) {
            NSLog(@"double: сумма точно равна 0.30");
        } else {
            NSLog(@"double: сумма НЕ равна 0.30 (потеряли копейку)");
        }

        /* --- Шаг 2. Точно: NSDecimalNumber. --- */
        NSDecimalNumber *d1 =
            [NSDecimalNumber decimalNumberWithString:@"0.10"];
        NSDecimalNumber *d2 =
            [NSDecimalNumber decimalNumberWithString:@"0.20"];
        NSDecimalNumber *dsum = [d1 decimalNumberByAdding:d2];
        NSLog(@"decimal: 0.10 + 0.20 = %@", dsum);

        NSDecimalNumber *exact =
            [NSDecimalNumber decimalNumberWithString:@"0.30"];
        if ([dsum isEqualToNumber:exact]) {
            NSLog(@"decimal: сумма ТОЧНО равна 0.30");
        }

        /* --- Шаг 3. Чек магазина: складываем список цен. --- */
        NSArray *prices = @[ @"199.99", @"49.50", @"3.30", @"0.01" ];
        NSDecimalNumber *cart = [NSDecimalNumber zero];
        for (NSString *priceText in prices) {
            NSDecimalNumber *price =
                [NSDecimalNumber decimalNumberWithString:priceText];
            cart = [cart decimalNumberByAdding:price];
        }
        NSLog(@"итого по чеку: %@", cart);

        /* Умножение: три одинаковых товара. */
        NSDecimalNumber *one =
            [NSDecimalNumber decimalNumberWithString:@"19.99"];
        NSDecimalNumber *three =
            [one decimalNumberByMultiplyingBy:
                [NSDecimalNumber decimalNumberWithString:@"3"]];
        NSLog(@"три по 19.99 = %@", three);
    }
    return 0;
}
