#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Вложенные сообщения: сначала alloc классу, потом init объекту. */
        NSMutableArray *list = [[NSMutableArray alloc] init];

        /* addObject: — кладём объекты в конец. */
        [list addObject:@"яблоко"];
        [list addObject:@"банан"];
        [list addObject:@"вишня"];

        /* count — сколько элементов (сообщение без аргументов). */
        NSUInteger c = [list count];
        NSLog(@"в массиве элементов: %lu", (unsigned long)c);

        /* objectAtIndex: — взять элемент по номеру (с нуля). */
        NSString *first = [list objectAtIndex:0];
        NSLog(@"первый: %@", first);

        NSString *last = [list objectAtIndex:[list count] - 1];
        NSLog(@"последний: %@", last);

        /* Многоаргументный селектор: setObject:forKey: у словаря. */
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:@"красный" forKey:@"яблоко"];
        [dict setObject:@"жёлтый" forKey:@"банан"];
        NSLog(@"цвет яблока: %@", [dict objectForKey:@"яблоко"]);

        /* Перебор: спрашиваем количество, берём по индексу. */
        for (NSUInteger i = 0; i < [list count]; i++) {
            NSLog(@"[%lu] = %@", (unsigned long)i, [list objectAtIndex:i]);
        }
    }
    return 0;
}
