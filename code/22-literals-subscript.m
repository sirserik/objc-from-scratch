#import <Foundation/Foundation.h>

/* Маленькая «полка» с фиксированным числом ячеек.
   Цель — показать, что obj[i] — это просто сахар над методами
   objectAtIndexedSubscript: и setObject:atIndexedSubscript:. */
@interface Shelf : NSObject
- (instancetype)initWithCapacity:(NSUInteger)capacity;
/* эти два метода и включают синтаксис shelf[i] */
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
@end

@implementation Shelf {
    NSMutableArray *_slots;   /* внутри — обычный массив */
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        _slots = [NSMutableArray arrayWithCapacity:capacity];
        for (NSUInteger i = 0; i < capacity; i++) {
            _slots[i] = @"(пусто)";   /* и тут уже работает субскрипт массива */
        }
    }
    return self;
}

/* Чтение: что вернуть на shelf[index] */
- (id)objectAtIndexedSubscript:(NSUInteger)index {
    if (index >= _slots.count) {
        return @"(нет такой полки)";
    }
    return _slots[index];
}

/* Запись: что сделать на shelf[index] = object */
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index {
    if (index < _slots.count) {
        _slots[index] = object;
    }
}

@end

int main(void) {
    @autoreleasepool {
        /* 1. Литералы — каждый это вызов фабричного метода под капотом */
        NSNumber *n      = @42;            /* = [NSNumber numberWithInt:42] */
        NSNumber *flag   = @YES;           /* = [NSNumber numberWithBool:YES] */
        NSNumber *pi     = @3.14;          /* = [NSNumber numberWithDouble:3.14] */
        NSString *s      = @"строка";      /* объект NSString */
        NSArray  *arr    = @[@"a", @"b", @"c"];
        NSDictionary *d  = @{@"one": @1, @"two": @2};
        int x = 7, y = 5;
        NSNumber *boxed  = @(x + y);       /* @() — упаковка выражения */

        NSLog(@"число %@, флаг %@, пи %@", n, flag, pi);
        NSLog(@"строка: %@", s);

        /* 2. Субскрипт коллекций — сахар над методами */
        NSLog(@"arr[1] = %@", arr[1]);            /* objectAtIndex: */
        NSLog(@"d[\"two\"] = %@", d[@"two"]);     /* objectForKeyedSubscript: */
        NSLog(@"сумма в коробке: %@", boxed);

        /* 3. Свой субскрипт */
        Shelf *shelf = [[Shelf alloc] initWithCapacity:3];
        NSLog(@"новая полка[0] = %@", shelf[0]);  /* objectAtIndexedSubscript: */
        shelf[0] = @"книга";                       /* setObject:atIndexedSubscript: */
        shelf[1] = @"чашка";
        NSLog(@"полка[0] = %@, полка[1] = %@", shelf[0], shelf[1]);
        NSLog(@"полка[9] = %@", shelf[9]);        /* выход за границы */
    }
    return 0;
}
