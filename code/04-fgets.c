/* Глава 4. Безопасный ввод строки: fgets вместо запрещённого gets. */
#include <stdio.h>
#include <string.h>

int main(void) {
    char name[32];

    printf("Как тебя зовут? ");
    if (fgets(name, sizeof name, stdin) == NULL) {
        printf("Ничего не ввёл.\n");
        return 1;
    }
    name[strcspn(name, "\n")] = '\0';   /* срезаем перевод строки */
    printf("Привет, %s! В имени %zu байт.\n", name, strlen(name));
    return 0;
}
