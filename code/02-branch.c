#include <stdio.h>
#include <stdbool.h>

int main(void) {
    int score = 75;

    if (score >= 90) {
        printf("Отлично\n");
    } else if (score >= 60) {
        printf("Зачёт\n");
    } else {
        printf("Пересдача\n");
    }

    int age = 20;
    bool hasTicket = true;
    if (age >= 18 && hasTicket) {
        printf("Проходи\n");
    }

    if (!hasTicket || age < 18) {
        printf("Стоп\n");
    } else {
        printf("Всё в порядке\n");
    }

    return 0;
}
