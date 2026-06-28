#include <stdio.h>

/* struct — собственный составной тип: точка с двумя полями */
struct Point {
    int x;
    int y;
};

int main(void) {
    /* сама переменная-struct: к полям обращаемся через точку */
    struct Point a;
    a.x = 3;
    a.y = 4;
    printf("a = (%d, %d)\n", a.x, a.y);

    /* указатель на struct: к полям обращаемся через стрелку -> */
    struct Point *p = &a;
    p->x = 10;
    printf("После p->x = 10: a = (%d, %d)\n", a.x, a.y);
    printf("Через стрелку:   p->y = %d\n", p->y);

    /* (*p).y — это ровно то же, что p->y, но писать громоздко */
    printf("Через (*p).y =   %d\n", (*p).y);

    return 0;
}
