#include "amfid_handler.h"
#include <stdio.h>
#include <string.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
#include <limits.h>

extern char **environ;

int
main(int argc, const char *argv[])
{
    amfid_patch();

    /* ── spawn fangs ── */
    char fangs_path[PATH_MAX];
    const char *slash = strrchr(argv[0], '/');
    if (slash) {
        size_t dirlen = slash - argv[0];
        snprintf(fangs_path, sizeof(fangs_path),
                 "%.*s/fangs", (int)dirlen, argv[0]);
        if (access(fangs_path, X_OK) != 0)
            snprintf(fangs_path, sizeof(fangs_path), ".build/fangs");
    } else {
        snprintf(fangs_path, sizeof(fangs_path), ".build/fangs");
    }

    pid_t child;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    const char *fangs_argv[argc + 1];
    fangs_argv[0] = "fangs";
    for (int i = 1; i < argc; i++)
        fangs_argv[i] = argv[i];
    fangs_argv[argc] = NULL;

    int ret = posix_spawn(&child, fangs_path, NULL, &attr,
                          (char *const *)fangs_argv, environ);
    posix_spawnattr_destroy(&attr);
    if (ret != 0) {
        fprintf(stderr, "[grant] posix_spawn(%s): %s\n",
                fangs_path, strerror(ret));
        amfid_unpatch();
        return 1;
    }
    printf("[grant] fangs spawned (pid %d)\n", child);

    usleep(500000);
    amfid_unpatch();

    int wstatus;
    waitpid(child, &wstatus, 0);

    if (WIFEXITED(wstatus))
        return WEXITSTATUS(wstatus);
    return 1;
}
