#import <Foundation/Foundation.h>

/* Добавляем фабричный метод класса — короткий способ создать готовый объект. */
@interface Person : NSObject {
    NSString *_name;
    NSInteger _age;
}
- (instancetype)initWithName:(NSString *)name age:(NSInteger)age;
+ (instancetype)personWithName:(NSString *)name age:(NSInteger)age;  /* фабрика */
- (void)describe;
@end

@implementation Person

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age {
    self = [super init];
    if (self) {
        _name = [name copy];
        _age = age;
    }
    return self;
}

/* Фабричный метод КЛАССА (знак +): сам делает alloc/init и отдаёт объект.
   instancetype → вернётся именно Person, а у наследника — наследник. */
+ (instancetype)personWithName:(NSString *)name age:(NSInteger)age {
    return [[self alloc] initWithName:name age:age];
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
            /* Две записи одного и того же: */
            Person *a = [[Person alloc] initWithName:@"Аружан" age:24];
            Person *b = [Person personWithName:@"Бекжан" age:31];

            [a describe];
            [b describe];
        }   /* dealloc обоих */

        NSLog(@"--- готово ---");
    }
    return 0;
}
