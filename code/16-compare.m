#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        /* Два РАЗНЫХ объекта с одинаковым значением. */
        NSNumber *a = @(1000);
        NSNumber *b = [NSNumber numberWithInt:1000];

        /* == сравнивает адреса, а не значения. */
        if (a == b) {
            NSLog(@"== : a и b это один объект");
        } else {
            NSLog(@"== : a и b разные объекты (адреса не совпали)");
        }

        /* isEqualToNumber: сравнивает ЗНАЧЕНИЯ — то, что нам и нужно. */
        if ([a isEqualToNumber:b]) {
            NSLog(@"isEqualToNumber: значения равны");
        }

        /* compare: для порядка: возвращает -1, 0 или 1. */
        NSNumber *small = @5;
        NSNumber *large = @9;
        NSComparisonResult r = [small compare:large];
        if (r == NSOrderedAscending) {
            NSLog(@"compare: 5 меньше 9");
        }

        /* Ловушка кэширования малых целых. */
        NSNumber *p = @1;
        NSNumber *q = @1;
        NSLog(@"@1 == @1 ? %@", (p == q) ? @"да" : @"нет");

        NSNumber *m = @100000;
        NSNumber *n = @100000;
        NSLog(@"@100000 == @100000 ? %@", (m == n) ? @"да" : @"нет");
    }
    return 0;
}
