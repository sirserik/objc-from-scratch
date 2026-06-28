#import <Foundation/Foundation.h>

/* Базовый класс. От NSObject наследуются alloc, init, class и десятки
   других базовых умений — поэтому почти всё в Objective-C идёт от него. */
@interface Animal : NSObject
@property (nonatomic, copy) NSString *name;
- (instancetype)initWithName:(NSString *)name;
- (NSString *)speak;     /* что говорит животное — подклассы переопределят */
- (void)describe;
@end

@implementation Animal

/* Назначенный инициализатор: сначала просим родителя (NSObject)
   настроить базу через [super init], потом задаём своё поле. */
- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
    }
    return self;
}

/* Реализация по умолчанию: общий невнятный звук.
   Каждый подкласс заменит её своим. */
- (NSString *)speak {
    return @"...(непонятный звук)";
}

- (void)describe {
    NSLog(@"%@ говорит: %@", self.name, [self speak]);
}

@end

/* Подкласс Dog наследует ВСЁ от Animal (поле _name, свойство name,
   initWithName:, describe) и добавляет/переопределяет своё. */
@interface Dog : Animal
@property (nonatomic, copy) NSString *breed;
- (instancetype)initWithName:(NSString *)name breed:(NSString *)breed;
@end

@implementation Dog

/* Свой инициализатор. Сначала зовём инициализатор родителя через
   [super initWithName:], он настроит name. Потом задаём breed. */
- (instancetype)initWithName:(NSString *)name breed:(NSString *)breed {
    self = [super initWithName:name];
    if (self) {
        _breed = [breed copy];
    }
    return self;
}

/* Переопределяем speak — теперь собака лает. */
- (NSString *)speak {
    return @"Гав-гав!";
}

/* Переопределяем describe и ДОПОЛНЯЕМ родительскую версию:
   сначала [super describe] делает общую работу, потом добавляем своё. */
- (void)describe {
    [super describe];
    NSLog(@"   (порода: %@)", self.breed);
}

@end

/* Ещё один подкласс. Переопределяет только speak. */
@interface Cat : Animal
@end

@implementation Cat
- (NSString *)speak {
    return @"Мяу!";
}
@end

int main(void) {
    @autoreleasepool {
        /* Полиморфизм. Тип переменной — Animal*, а внутри лежит Dog.
           Сообщение speak уйдёт фактическому классу — Dog. */
        Animal *someone = [[Dog alloc] initWithName:@"Рекс"
                                              breed:@"овчарка"];
        NSLog(@"--- одно животное в переменной типа Animal* ---");
        [someone describe];

        /* Массив разных животных. Перебираем — каждый говорит по-своему,
           хотя цикл один и тот же. Runtime сам подбирает нужный speak. */
        NSLog(@"--- зоопарк: один цикл, разные голоса ---");
        NSArray *zoo = @[
            [[Dog alloc] initWithName:@"Рекс" breed:@"овчарка"],
            [[Cat alloc] initWithName:@"Мурка"],
            [[Animal alloc] initWithName:@"Нечто"],
        ];
        for (Animal *a in zoo) {
            [a describe];
        }
    }
    return 0;
}
