/* Глава 12. Блоки в самом Foundation: обход коллекции и сортировка
   компаратором. Оба метода принимают блок и зовут его за нас. */
#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSArray *fruits = @[@"яблоко", @"груша", @"слива"];
        [fruits enumerateObjectsUsingBlock:^(NSString *item,
                                             NSUInteger idx,
                                             BOOL *stop) {
            NSLog(@"%lu: %@", (unsigned long)idx, item);
            if (idx == 1) { *stop = YES; }   // остановиться после второго
        }];

        NSArray *words = @[@"кит", @"муравей", @"слон", @"ёж"];
        NSArray *sorted = [words sortedArrayUsingComparator:
            ^NSComparisonResult(NSString *a, NSString *b) {
                return [@(a.length) compare:@(b.length)];
            }];
        NSLog(@"по длине: %@", sorted);
        NSLog(@"по длине через componentsJoinedByString: %@",
              [sorted componentsJoinedByString:@", "]);
    }
    return 0;
}
