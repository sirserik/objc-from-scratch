#import <Foundation/Foundation.h>

/* Всё между BEGIN и END считается nonnull по умолчанию.
   Где допустим nil — помечаем явно через nullable. */
NS_ASSUME_NONNULL_BEGIN

/* Статус сотрудника — типобезопасный enum (см. файл 22-enum-options.m). */
typedef NS_ENUM(NSInteger, EmployeeStatus) {
    EmployeeStatusActive,
    EmployeeStatusVacation,
    EmployeeStatusFired,
};

/* Права доступа — битовые флаги. */
typedef NS_OPTIONS(NSUInteger, AccessRights) {
    AccessNone   = 0,
    AccessRead   = 1 << 0,
    AccessWrite  = 1 << 1,
    AccessAdmin  = 1 << 2,
};

/* Современный Person: nullability + дженерики в коллекциях
   + enum-статус + options-права + собственный субскрипт по навыкам. */
@interface Person : NSObject

@property (nonatomic, copy)   NSString *name;        /* всегда есть */
@property (nonatomic, copy, nullable) NSString *email; /* может быть nil */
@property (nonatomic, assign) EmployeeStatus status;
@property (nonatomic, assign) AccessRights rights;

/* Дженерик-коллекции: компилятор знает тип элементов. */
@property (nonatomic, strong) NSMutableArray<NSString *> *skills;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *salaryByYear;

/* Назначенный инициализатор: только через него настраиваем объект. */
- (instancetype)initWithName:(NSString *)name
                      status:(EmployeeStatus)status NS_DESIGNATED_INITIALIZER;

/* Запрещаем голый init: он должен пройти через назначенный. */
- (instancetype)init NS_UNAVAILABLE;

/* Субскрипт по индексу навыка: person[0]. */
- (NSString *)objectAtIndexedSubscript:(NSUInteger)index;

- (void)describe;

@end

@implementation Person

- (instancetype)initWithName:(NSString *)name status:(EmployeeStatus)status {
    self = [super init];
    if (self) {
        _name = [name copy];
        _status = status;
        _email = nil;                  /* nullable — это законно */
        _rights = AccessRead;
        _skills = [NSMutableArray array];
        _salaryByYear = @{};
    }
    return self;
}

- (NSString *)objectAtIndexedSubscript:(NSUInteger)index {
    if (index >= self.skills.count) {
        return @"(нет навыка)";
    }
    return self.skills[index];
}

- (void)describe {
    NSString *mail = self.email ?: @"почта не указана";
    NSString *statusText;
    switch (self.status) {
        case EmployeeStatusActive:   statusText = @"работает"; break;
        case EmployeeStatusVacation: statusText = @"в отпуске"; break;
        case EmployeeStatusFired:    statusText = @"уволен"; break;
    }
    NSLog(@"%@ [%@], %@, навыков: %lu",
          self.name, statusText, mail, (unsigned long)self.skills.count);
    if (self.rights & AccessAdmin) {
        NSLog(@"  -> администратор");
    } else if (self.rights & AccessWrite) {
        NSLog(@"  -> может писать");
    } else {
        NSLog(@"  -> только чтение");
    }
}

@end

NS_ASSUME_NONNULL_END

int main(void) {
    @autoreleasepool {
        Person *p = [[Person alloc] initWithName:@"Айгуль"
                                          status:EmployeeStatusActive];
        p.email = @"aigul@example.kz";    /* nullable — можно задать */
        p.rights = AccessRead | AccessWrite | AccessAdmin;

        /* Дженерик подсказывает тип: addObject ждёт NSString *. */
        [p.skills addObject:@"Objective-C"];
        [p.skills addObject:@"Swift"];
        [p.skills addObject:@"SQL"];

        p.salaryByYear = @{ @"2024": @500000, @"2025": @620000 };

        [p describe];

        /* Субскрипт по навыкам. */
        NSLog(@"первый навык: %@", p[0]);
        NSLog(@"навык №9: %@", p[9]);

        /* Чтение из дженерик-словаря: значение уже NSNumber *. */
        NSNumber *salary2025 = p.salaryByYear[@"2025"];
        NSLog(@"зарплата 2025: %@", salary2025);

        /* email может быть nil — обрабатываем явно. */
        Person *anon = [[Person alloc] initWithName:@"Аноним"
                                             status:EmployeeStatusVacation];
        [anon describe];
    }
    return 0;
}
