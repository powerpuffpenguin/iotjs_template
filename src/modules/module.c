#include <iotjs/core/module.h>
#include <modules/module.h>

static __attribute((constructor)) void my_modules_init()
{
    vm_register_native("example", native_example_init);
}