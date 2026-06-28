#import <Foundation/Foundation.h>

/* Тот же человек, но теперь умеем задавать имя и возраст при рождении. */
@interface Person : NSObject {
    NSString *_name;
    NSInteger _age;
}
- (instancetype)initWithName:(NSString *)name age:(NSInteger)age;  /* назначенный */
- (instancetype)initWithName:(NSString *)name;                     /* вторичный */
- (instancetype)init;                                              /* вторичный */
- (void)describe;
@end

@implementation Person

/* НАЗНАЧЕННЫЙ инициализатор: один настоящий, через него настраиваются ВСЕ ivars. */
- (instancetype)initWithName:(NSString *)name age:(NSInteger)age {
    self = [super init];
    if (self) {
        _name = [name copy];      /* копию строки — чужую могут поменять */
        _age = age;
    }
    return self;
}

/* ВТОРИЧНЫЙ: подставляет значение по умолчанию и зовёт назначенный. */
- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name age:0];
}

/* ВТОРИЧНЫЙ: совсем без данных — тоже сводится к назначенному. */
- (instancetype)init {
    return [self initWithName:@"Без имени" age:0];
}

- (void)describe {
    NSLog(@"Человек: %@, возраст %ld", _name, (long)_age);
}

- (void)dealloc {
    NSLog(@"dealloc: объект %@ уничтожен", _name);
}

@end

int main(void) {
    @autoreleasepool {
        @autoreleasepool {
            Person *full = [[Person alloc] initWithName:@"Аружан" age:24];
            Person *named = [[Person alloc] initWithName:@"Бекжан"];
            Person *blank = [[Person alloc] init];

            [full describe];
            [named describe];
            [blank describe];
        }   /* все три объекта уничтожаются здесь */

        NSLog(@"--- пул закрыт, все объекты освобождены ---");
    }
    return 0;
}
