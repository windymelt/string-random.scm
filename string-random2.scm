(use parser.peg)
(use util.match)

(define %char ($none-of #[\]\)]))
(define %atom ($or ($between ($c #\() ($lazy %regex) ($c #\))) %char))
(define %piece ($do [a %atom] [op ($optional ($one-of #[?*+]))] ($return (if op (cons op (list a)) a))))
(define %branch ($many %piece 1))
(define %regex ($lift (cut cons 'or <>) ($sep-by %branch ($c #\|))))

(print (peg-parse-string %regex "セミの鳴き声です: ( (ミー?ン)+|(ツクツク|ホーシ)+|(ジー?)+)"))

(define s "")
(define (walk tree)
  (match tree
    [('? . xs) ""]
    [('+ . xs) xs]
    [('or . xs) (walk (car xs))]
    [(x . y . (xxs)) (string-append x y (walk xxs))]))

(print (walk (peg-parse-string %regex "セミの鳴き声です: ( (ミー?ン)+|(ツクツク|ホーシ)+|(ジー?)+)")))
