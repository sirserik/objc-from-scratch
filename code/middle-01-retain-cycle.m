#import <Foundation/Foundation.h>

/* Задача: «найди утечку». Команда держит игроков сильно (владеет),
   а игрок ссылается на команду обратной ссылкой. Если обратная ссылка
   тоже strong — кольцо, dealloc молчит. Чиним одним словом weak. */

@class Team;

@interface Player : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) Team *team;     /* weak: вверх не владеем */
@end

@implementation Player
- (void)dealloc { NSLog(@"dealloc Player (%@)", self.name); }
@end

@interface Team : NSObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, strong) NSMutableArray<Player *> *players; /* владеет */
- (void)addPlayer:(Player *)p;
@end

@implementation Team
- (instancetype)init {
    self = [super init];
    if (self) { _players = [NSMutableArray array]; }
    return self;
}
- (void)addPlayer:(Player *)p {
    p.team = self;              /* обратная ссылка — weak, цикла нет */
    [self.players addObject:p];
}
- (void)dealloc { NSLog(@"dealloc Team (%@)", self.name); }
@end

int main(void) {
    @autoreleasepool {
        @autoreleasepool {
            Team *t = [[Team alloc] init];
            t.name = @"Кайрат";
            Player *a = [[Player alloc] init]; a.name = @"Асет";
            Player *b = [[Player alloc] init]; b.name = @"Болат";
            [t addPlayer:a];
            [t addPlayer:b];
            NSLog(@"%@ играет за %@", a.name, a.team.name);
            NSLog(@"выходим из блока — ждём три dealloc...");
        }   /* t, a, b выходят из видимости */
        NSLog(@"блок закрыт — dealloc были выше, утечки нет");
    }
    return 0;
}
