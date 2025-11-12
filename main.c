#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

extern long init_todo(void);
extern long add_todo(const char *s, long priority, long timestamp);
extern long get_count(void);
extern long get_task(long index, char *outbuf, long bufsize);
extern long get_priority(long index);
extern long get_timestamp(long index);
extern long update_task(long index, const char *newtext);
extern long set_priority(long index, long priority);
extern long remove_todo(long index);

/* Persistence helpers */
void format_time(long ts, char *buf, size_t len);
void save_tasks(const char *fname) {
    FILE *f = fopen(fname, "w");
    if (!f) return;
    long cnt = get_count();
    char buf[256];
    for (long i = 0; i < cnt; ++i) {
        if (get_task(i, buf, sizeof(buf)) == 0) {
            long p = get_priority(i);
            long t = get_timestamp(i);
            char tbuf[64];
            format_time(t, tbuf, sizeof(tbuf));
            fprintf(f, "%ld|%s|%s\n", p, tbuf, buf);
        }
    }
    fclose(f);
}

void load_tasks(const char *fname) {
    FILE *f = fopen(fname, "r");
    if (!f) return;
    char line[512];
    while (fgets(line, sizeof(line), f)) {
        char *p1 = strchr(line, '|');
        if (!p1) continue;
        *p1 = '\0';
        char *p2 = strchr(p1+1, '|');
        if (!p2) continue;
        *p2 = '\0';
        long pr = atol(line);
        /* parse timestamp which may be either epoch or formatted
           expected formatted: YYYY-MM-DD HH:MM:SS */
        long ts = 0;
        int Y, Mo, D, h, m, s;
        if (sscanf(p1+1, "%d-%d-%d %d:%d:%d", &Y, &Mo, &D, &h, &m, &s) == 6) {
            struct tm tm = {0};
            tm.tm_year = Y - 1900;
            tm.tm_mon = Mo - 1;
            tm.tm_mday = D;
            tm.tm_hour = h;
            tm.tm_min = m;
            tm.tm_sec = s;
            /* mktime interprets tm as local time */
            time_t tt = mktime(&tm);
            if (tt != (time_t)-1) ts = (long)tt;
            else ts = atol(p1+1); /* fallback */
        } else {
            ts = atol(p1+1); /* fallback for older numeric epoch file */
        }
        char *text = p2+1;
        size_t ln = strlen(text);
        if (ln && text[ln-1] == '\n') text[ln-1] = '\0';
        add_todo(text, pr, ts);
    }
    fclose(f);
}

/* Format timestamp (seconds since epoch) into YYYY-MM-DD HH:MM:SS
   Fallback: prints integer if formatting fails. */
void format_time(long ts, char *buf, size_t len) {
    time_t t = (time_t)ts;
    struct tm *tm = localtime(&t);
    if (tm) {
        if (strftime(buf, len, "%Y-%m-%d %H:%M:%S", tm) == 0) {
            /* buffer too small or formatting failed */
            snprintf(buf, len, "%ld", ts);
        }
    } else {
        snprintf(buf, len, "%ld", ts);
    }
}

int main(int argc, char **argv) {
    init_todo();
    /* load persisted tasks if present */
    load_tasks("todos.txt");

    if (argc == 2 && strcmp(argv[1], "-test") == 0) {
        /* Non-interactive test mode for automated verification */
        const char *sample = "Example task from test mode";
        long prio = 5;
        long ts = (long)time(NULL);
        if (add_todo(sample, prio, ts) == 0) {
            long cnt = get_count();
            printf("Added sample task. Count = %ld\n", cnt);
            char buf[128];
            if (get_task(0, buf, sizeof(buf)) == 0) {
                long p = get_priority(0);
                long t = get_timestamp(0);
                char tbuf[64];
                format_time(t, tbuf, sizeof(tbuf));
                printf("Task 0: %s\n", buf);
                printf("  priority=%ld timestamp=%s\n", p, tbuf);
            }
        } else {
            printf("Failed to add sample task (full?)\n");
        }
        /* persist the test task so we can inspect todos.txt */
        save_tasks("todos.txt");
        return 0;
    }

    char input[256];
    while (1) {
        printf("\n");
        printf("================================================\n");
        printf("                   TODO MENU\n");
        printf("================================================\n");
        printf("1) Add task\n");
        printf("2) List tasks\n");
        printf("3) Remove task\n");
        printf("4) Quit (saves to todos.txt)\n");
        printf("5) Edit task text\n");
        printf("6) Set priority\n");
        printf("================================================\n");
        printf("> ");
        if (!fgets(input, sizeof(input), stdin)) break;

        int choice = atoi(input);
        if (choice == 1) {
            printf("Enter task: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            /* trim newline */
            size_t ln = strlen(input);
            if (ln && input[ln-1] == '\n') input[ln-1] = '\0';
            printf("Enter priority (1-9): ");
            if (!fgets(input+128, sizeof(input)-128, stdin)) break;
            int prio = atoi(input+128);
            long ts = (long)time(NULL);
            long r = add_todo(input, prio, ts);
            if (r == 0) printf("Task added.\n");
            else printf("Todo list is full.\n");
        } else if (choice == 2) {
            long cnt = get_count();
            printf("\n");
            printf("================================================\n");
            printf("                   TASK LIST\n");
            printf("================================================\n");
            printf("Total tasks: %ld\n", cnt);
            for (long i = 0; i < cnt; ++i) {
                char buf[128];
                if (get_task(i, buf, sizeof(buf)) == 0) {
                    long p = get_priority(i);
                    long t = get_timestamp(i);
                    char tbuf[64];
                    format_time(t, tbuf, sizeof(tbuf));
                    printf("%ld: [Priority %ld] %s (ts=%s)\n", i, p, buf, tbuf);
                }
            }
            printf("================================================\n");
        } else if (choice == 3) {
            printf("Index to remove: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            int idx = atoi(input);
            if (remove_todo(idx) == 0) printf("Removed task %d.\n", idx);
            else printf("Invalid index.\n");
        } else if (choice == 5) {
            /* edit task text */
            printf("Index to edit: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            int idx = atoi(input);
            printf("New text: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            size_t ln = strlen(input);
            if (ln && input[ln-1] == '\n') input[ln-1] = '\0';
            if (update_task(idx, input) == 0) printf("Task updated.\n");
            else printf("Invalid index.\n");
        } else if (choice == 6) {
            /* set priority */
            printf("Index to change priority: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            int idx = atoi(input);
            printf("New priority: ");
            if (!fgets(input, sizeof(input), stdin)) break;
            int pr = atoi(input);
            if (set_priority(idx, pr) == 0) printf("Priority set.\n");
            else printf("Invalid index.\n");
        } else if (choice == 4) {
            save_tasks("todos.txt");
            break;
        } else {
            printf("Unknown option.\n");
        }
    }

    return 0;
}
