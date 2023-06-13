#include <iotjs/core/defines.h>
#include <iotjs/core/vm.h>
#include <iotjs/core/js.h>
#include <iotjs/core/async.h>

#include <modules/js/example.h>
#define MY_SNAPSHOT_KEY "MyExample", 9

static duk_ret_t native_sum(duk_context *ctx)
{
    duk_double_t sum = 0;
    duk_idx_t count = duk_get_top(ctx);

    if (count)
    {
        for (duk_idx_t i = 0; i < count; i++)
        {
            sum += duk_require_number(ctx, i);
        }
        duk_pop_n(ctx, count);
    }
    duk_push_number(ctx, sum);
    return 1;
}
typedef struct
{
    int x;
} async_t;
static void async_free(void *p)
{
    async_t *a = p;
    printf("free %d\n", a->x);
}
static duk_ret_t native_new_async(duk_context *ctx)
{
    duk_require_callable(ctx, 0);

    finalizer_t *finalizer = vm_create_finalizer_n(ctx, sizeof(async_t));
    async_t *a = finalizer->p;
    finalizer->free = async_free;

    srand((unsigned)time(NULL));
    a->x = rand() % IOTJS_MAX_UINT32;

    // 爲當前棧 創建快照，最後一個參數指定要爲多少元素創建快照
    vm_snapshot_copy(ctx, MY_SNAPSHOT_KEY, a, 2);
    return 1;
}
static duk_ret_t native_emit_async(duk_context *ctx)
{
    finalizer_t *finalizer = vm_require_finalizer(ctx, 0, async_free);
    async_t *a = finalizer->p;
    // 恢復快照
    vm_restore(ctx, MY_SNAPSHOT_KEY, a, 0);
    // 調用傳入的回調函數
    duk_swap_top(ctx, -2);
    duk_call(ctx, 0);
    return 0;
}
duk_ret_t native_example_init(duk_context *ctx)
{
    duk_swap(ctx, 0, 1);
    duk_pop_2(ctx);

    // 直接註冊 c 函數
    duk_push_c_function(ctx, native_sum, DUK_VARARGS);
    duk_put_prop_lstring(ctx, 0, "sum", 3);

    // 加載 js，返回初始化函數
    duk_eval_lstring(ctx, (const char *)js_modules_js_example_min_js, js_modules_js_example_min_js_len);
    duk_swap_top(ctx, -2);
    // ... func, module

    // 如參 通用模塊 _iotjs
    duk_push_heap_stash(ctx);
    duk_get_prop_lstring(ctx, -1, VM_STASH_KEY_PRIVATE);
    duk_swap_top(ctx, -2);
    duk_pop(ctx);

    // 如參數 模塊依賴
    duk_push_object(ctx);
    {
        duk_push_lstring(ctx, "v1.0.0", 6);
        duk_put_prop_lstring(ctx, -2, "version", 7);

        duk_push_c_lightfunc(ctx, native_new_async, 1, 1, 0);
        duk_put_prop_lstring(ctx, -2, "new_async", 9);
        duk_push_c_lightfunc(ctx, native_emit_async, 1, 1, 0);
        duk_put_prop_lstring(ctx, -2, "emit_async", 10);
    }
    duk_call(ctx, 3);
    return 0;
}