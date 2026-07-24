(lambda set-opts [target ...]
  "apply operator to field of vim.opt/vim.opt_local/vim.opt_global at runtime"
  (let [args [...]
        len (length args)]
    (var i 1)
    (while (<= i len)
      (let [k (. args i)
            next-val (. args (+ i 1))
            val-after-next (. args (+ i 2))]
        (if (and (or (= next-val :append)
                     (= next-val :prepend)
                     (= next-val :remove)
                     (= next-val :get))
                 (<= (+ i 2) len))
            (do
              (: (. target k) next-val val-after-next)
              (set i (+ i 3)))
            (do
              (tset target k next-val)
              (set i (+ i 2))))))))

(lambda mt [arr ...]
    (let [keys [...]
        n (length keys)]
        (assert (= 0 (% n 2)) "参数数量必须为偶数")
        (for [i 1 n 2]
            (tset arr (. keys i) (. keys (+ i 1))))
        arr))


(lambda get-path [tbl path]
  (var curr tbl)
  (each [k (path:gmatch "[^%.]+")]
    (set curr (if (= (type curr) :table) (. curr k) nil)))
  curr)

(lambda req-at [mod path]
  "获取模块中的属性。
   mod: 模块名
   path: 属性路径，如 'field.subfield'"
  (let [m (require mod)]
    (get-path m path)))

(lambda call-at [mod path ...]
  "调用模块中的函数。
   mod: 模块名
   path: 函数路径
   ...: 传递给函数的参数"
  (let [target (req-at mod path)]
    (if (= (type target) :function)
        (target ...)
        (error (.. "The property at " path " is not a function")))))

{
: set-opts
: mt
: req-at
: call-at
}
