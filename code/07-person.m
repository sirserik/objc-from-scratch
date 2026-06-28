#import <Foundation/Foundation.h>

/* Самый первый класс главы: человек с именем и возрастом.
   Свойств (@property) ещё нет — храним данные в ivars напрямую. */
@interface Person : NSObject {
    NSString *_name;
    NSInteger _age;
}
- (instancetype)init;
- (void)describe;
@end

@implementation Person

/* init без аргументов: настраиваем объект значениями по умолчанию. */
- (instancetype)init {
    self = [super init];          /* отдаём родителю настроить базу */
    if (self) {                   /* родитель вернул объект, а не nil */
        _name = @"Без имени";
        _age = 0;
    }
    return self;                  /* возвращаем готовый объект */
}

- (void)describe {
    NSLog(@"Человек: %@, возраст %ld", _name, (long)_age);
}

/* dealloc срабатывает в момент уничтожения объекта.
   Под ARC release руками НЕ зовём — система сама решает, когда сюда зайти. */
- (void)dealloc {
    NSLog(@"dealloc: объект %@ уничтожен", _name);
}

@end

int main(void) {
    @autoreleasepool {
        NSLog(@"--- до создания объекта ---");

        /* Вложенный пул: объект родится и умрёт внутри него. */
        @autoreleasepool {
            Person *p = [[Person alloc] init];
            [p describe];
        }   /* здесь p больше никому не нужен → срабатывает dealloc */

        NSLog(@"--- объект уже уничтожен ---");
    }
    return 0;
}
