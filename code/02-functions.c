#include <stdio.h>

/* прототип: обещаем компилятору, что функция есть */
int square(int x);
int max2(int a, int b);

int main(void) {
    printf("square(5) = %d\n", square(5));
    printf("max2(3, 9) = %d\n", max2(3, 9));
    return 0;
}

/* определение: тело функции */
int square(int x) {
    return x * x;
}

int max2(int a, int b) {
    if (a > b) {
        return a;
    }
    return b;
}
