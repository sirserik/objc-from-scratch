#include <stdio.h>

int main(void) {
    int apples = 7;
    int people = 2;

    int bad = apples / people;
    printf("Целочисленно: 7 / 2 = %d\n", bad);

    int rest = apples % people;
    printf("Остаток: 7 %% 2 = %d\n", rest);

    double good = (double)apples / people;
    printf("Дробно: 7 / 2 = %f\n", good);
    printf("Дробно (2 знака): %.2f\n", good);

    return 0;
}
