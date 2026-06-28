#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int count = 5;

    /* просим у кучи место под count чисел типа int */
    int *arr = malloc(count * sizeof(int));

    /* всегда проверяем: вдруг память не дали */
    if (arr == NULL) {
        printf("Память не выделилась\n");
        return 1;
    }

    /* заполняем выделенный блок и печатаем */
    for (int i = 0; i < count; i++) {
        arr[i] = (i + 1) * 10;
    }
    for (int i = 0; i < count; i++) {
        printf("arr[%d] = %d\n", i, arr[i]);
    }

    printf("sizeof(int) = %zu байт\n", sizeof(int));
    printf("Всего заняли = %zu байт\n", count * sizeof(int));

    /* вернули память системе — без этого была бы утечка */
    free(arr);
    printf("Память освобождена\n");

    return 0;
}
