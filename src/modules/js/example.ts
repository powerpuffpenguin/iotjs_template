/**
 * 一些內置的功能函數
 */
declare namespace _iotjs {
    export function getcwd(): string
}
/**
 * 此模塊單獨依賴的 c 函數
 */
declare namespace deps {
    export const version: string

    export class Async {
        /**
         * 隨便定義一個名稱方便 typescript 可以檢查傳參錯誤
         */
        private readonly __hash_example_async: string
    }
    export function new_async(cb: () => void): Async
    export function emit_async(a: Async): void
}
export function display() {
    console.log("pwd:", _iotjs.getcwd())
    console.log("version:", deps.version)
}

export class Async {
    private async_: deps.Async
    constructor(cb: () => void) {
        this.async_ = deps.new_async(cb)
    }
    emit() {
        deps.emit_async(this.async_)
    }
}