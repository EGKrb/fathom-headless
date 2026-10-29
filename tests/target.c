// Small debuggee for the smoke test: some calls, memory writes and a file access to trace.
#include <windows.h>
#include <stdio.h>

static volatile unsigned int g_values[64];

static unsigned int mix(unsigned int x)
{
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return x;
}

int main(void)
{
    unsigned int seed = 0x12345678;
    for(int i = 0; i < 64; i++)
    {
        seed = mix(seed);
        g_values[i] = seed;
    }
    char path[MAX_PATH];
    GetTempPathA(sizeof(path), path);
    lstrcatA(path, "fathom-headless-smoke.txt");
    HANDLE file = CreateFileA(path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE, NULL);
    if(file != INVALID_HANDLE_VALUE)
        CloseHandle(file);
    printf("%08x\n", g_values[63]);
    return 0;
}
