(use parser.peg)

(define %char ($none-of #[\]\)]))
(define %atom ($or ($between ($c #\() ($lazy %regex) ($c #\))) %char))
(define %piece ($do [a %atom] [op ($optional ($one-of #[?*+]))] ($return (if op (cons op (list a)) a))))
(define %branch ($many %piece 1))
(define %regex ($sep-by %branch ($c #\|)))

(print (peg-parse-string %regex "セミの鳴き声です: ( (ミー?ン)+|(ツクツク|ホーシ)+|(ジー?)+)"))
