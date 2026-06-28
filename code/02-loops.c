#include <stdio.h>

int main(void) {
    int n = 5;

    /* while: считаем сумму от 1 до n */
    int sum = 0;
    int i = 1;
    while (i <= n) {
        sum = sum + i;
        i = i + 1;
    }
    printf("Сумма от 1 до %d = %d\n", n, sum);

    /* for: то же самое короче */
    int sum2 = 0;
    for (int k = 1; k <= n; k++) {
        sum2 = sum2 + k;
    }
    printf("То же через for = %d\n", sum2);

    /* break и continue */
    for (int x = 1; x <= 10; x++) {
        if (x % 2 == 0) {
            continue;   /* чётные пропускаем */
        }
        if (x > 7) {
            break;      /* после 7 выходим совсем */
        }
        printf("нечётное: %d\n", x);
    }

    return 0;
}
