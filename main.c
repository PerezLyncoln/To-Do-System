#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern long init_todo(void);
extern long add_todo(const char *s);
extern long get_count(void);
extern long get_task(long index, char *outbuf, long bufsize);
extern long remove_todo(long index);

int main(int argc, char **argv) {
    init_todo();

    if (argc == 2 && strcmp(argv[1], "-test") == 0) {
        /* Non-interactive test mode for automated verification */
        const char *sample = "Example task from test mode";
        if (add_todo(sample) == 0) {
            long cnt = get_count();
            printf("Added sample task. Count = %ld\n", cnt);
            char buf[128];
            if (get_task(0, buf, sizeof(buf)) == 0) {
                printf("Task 0: %s\n", buf);
            }
        } else {
            printf("Failed to add sample task (full?)\n");
        }
        return 0;
    }

    char input[256];
    while (1) {
        printf("\nTodo Menu:\n");
        printf("1) Add task\n");
        printf("2) List tasks\n");
        printf("3) Remove task\n");
        printf("4) Quit\n");
        printf("> ");
        if (!fgets(input, sizeof(input), stdin)) break;

        int choice = atoi(input);
        if (choice == 1) {
            printf("Enter task: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            /* trim newline */
            size_t ln = strlen(input);
            if (ln && input[ln-1] == '\n') input[ln-1] = '\0';
            long r = add_todo(input);
            if (r == 0) printf("Task added.\n");
            else printf("Todo list is full.\n");
        } else if (choice == 2) {
            long cnt = get_count();
            printf("Total tasks: %ld\n", cnt);
            for (long i = 0; i < cnt; ++i) {
                char buf[128];
                if (get_task(i, buf, sizeof(buf)) == 0) {
                    printf("%ld: %s\n", i, buf);
                }
            }
        } else if (choice == 3) {
            printf("Index to remove: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            int idx = atoi(input);
            if (remove_todo(idx) == 0) printf("Removed task %d.\n", idx);
            else printf("Invalid index.\n");
        } else if (choice == 4) {
            break;
        } else {
            printf("Unknown option.\n");
        }
    }

    return 0;
}
