var example = require("example")
console.log(example.sum(1, 2, 3, 4))
example.display()
var a = new example.Async(function () {
    console.log("cb", new Date())
})
var i = 0
var t
t = setInterval(function () {
    a.emit()
    i++
    if (i > 4) {
        clearInterval(t)
    }
}, 1000)
