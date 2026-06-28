#import <Foundation/Foundation.h>

/* Починка цикла: ссылку ребёнка на родителя делаем WEAK.
   weak не владеет и не добавляет к счётчику — цикла больше нет.
   Бонус: weak сам обнуляется в nil, когда объект умирает. */

@class Child;

@interface Parent : NSObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, strong) Child *child;    /* сильная: родитель владеет */
@end

@interface Child : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) Parent *parent;    /* WEAK: не владеет, нет цикла */
@end

@implementation Parent
- (void)dealloc { NSLog(@"dealloc Parent (%@)", self.name); }
@end

@implementation Child
- (void)dealloc { NSLog(@"dealloc Child (%@)", self.name); }
@end

int main(void) {
    @autoreleasepool {
        /* --- Сценарий 1: цикл починен, оба dealloc срабатывают --- */
        NSLog(@"=== Сценарий 1: цикл разорван weak ===");
        @autoreleasepool {
            Parent *mom = [Parent new];
            mom.name = @"Мама";
            Child *kid = [Child new];
            kid.name = @"Дочь";

            mom.child  = kid;    /* сильная: +1 к счётчику kid */
            kid.parent = mom;    /* weak:   счётчик mom НЕ меняется */

            NSLog(@"выходим из вложенного блока — ждём два dealloc...");
        }   /* mom и kid освобождаются: ничто не держит их по кругу */
        NSLog(@"оба dealloc были выше — утечки нет");

        /* --- Сценарий 2: weak сам обнуляется в nil --- */
        NSLog(@"=== Сценарий 2: weak обнуляется автоматически ===");
        Child *observer = [Child new];
        observer.name = @"Наблюдатель";
        @autoreleasepool {
            Parent *temp = [Parent new];
            temp.name = @"Времянка";
            observer.parent = temp;   /* weak-ссылка на temp */
            NSLog(@"пока temp жив: observer.parent = %@", observer.parent.name);
        }   /* temp выходит из видимости и умирает */
        /* weak-ссылка сама стала nil — висячего указателя НЕТ */
        NSLog(@"temp умер: observer.parent = %@", observer.parent);
    }
    return 0;
}
