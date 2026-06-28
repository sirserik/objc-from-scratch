#import <Foundation/Foundation.h>

int main(void) {
    @autoreleasepool {
        NSArray *words = @[ @"груша", @"ёж", @"апельсин",
                            @"кот", @"баклажан" ];

        /* sortedArrayUsingComparator: блок-компаратор возвращает
           NSComparisonResult: меньше / равно / больше. */
        NSArray *byLength = [words sortedArrayUsingComparator:
            ^NSComparisonResult(id a, id b) {
                NSUInteger la = [(NSString *)a length];
                NSUInteger lb = [(NSString *)b length];
                if (la < lb) return NSOrderedAscending;
                if (la > lb) return NSOrderedDescending;
                return NSOrderedSame;
            }];
        NSLog(@"по длине: %@",
              [byLength componentsJoinedByString:@", "]);

        /* Сортировка по алфавиту — у строк уже есть готовый компаратор. */
        NSArray *byAbc = [words sortedArrayUsingComparator:
            ^NSComparisonResult(id a, id b) {
                return [(NSString *)a compare:b];
            }];
        NSLog(@"по алфавиту: %@",
              [byAbc componentsJoinedByString:@", "]);

        /* filteredArrayUsingPredicate: оставить подходящие. */
        NSPredicate *longOnes =
            [NSPredicate predicateWithFormat:@"length > 3"];
        NSArray *filtered = [words filteredArrayUsingPredicate:longOnes];
        NSLog(@"длиннее 3 букв: %@",
              [filtered componentsJoinedByString:@", "]);

        /* --- sortUsingDescriptors: на массиве объектов/словарей --- */
        NSMutableArray *people = [@[
            @{ @"name" : @"Аня",   @"age" : @30 },
            @{ @"name" : @"Боря",  @"age" : @22 },
            @{ @"name" : @"Вера",  @"age" : @27 },
        ] mutableCopy];
        NSSortDescriptor *byAge =
            [NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES];
        [people sortUsingDescriptors:@[ byAge ]];

        /* valueForKey: на массиве — KVC-тизер (подробно в гл. 20):
           собирает значение ключа из каждого элемента в новый массив. */
        NSArray *names = [people valueForKey:@"name"];
        NSLog(@"по возрасту: %@",
              [names componentsJoinedByString:@", "]);
        NSArray *ages = [people valueForKey:@"age"];
        NSLog(@"возрасты: %@", ages);
    }
    return 0;
}
