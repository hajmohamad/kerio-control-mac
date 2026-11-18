#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

void my_CFRelease(CFTypeRef cf) {
    if (cf == NULL) {
        return;
    }
    CFRelease(cf);
}

CFTypeRef my_CFRetain(CFTypeRef cf) {
    if (cf == NULL) {
        return NULL;
    }
    return CFRetain(cf);
}

__attribute__((used, section("__DATA,__interpose")))
static struct {
    const void *replacement;
    const void *original;
} interpose_CF[] = {
    { (const void *)my_CFRelease, (const void *)CFRelease },
    { (const void *)my_CFRetain,  (const void *)CFRetain  }
};
