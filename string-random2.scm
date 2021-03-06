#!/usr/bin/env gosh
(use parser.peg)
(use util.match)
(use data.random)
(use gauche.generator)
(use gauche.parseopt)

;;; const
(define *max-repeat* 6)

;;; utility
;; (run "(+ 1 2)") => 3
(define (run str) (eval (read (open-input-string str)) (interaction-environment)))
(define (char->symbol c) (string->symbol (list->string (list c))))
(define (chars->number cx) (string->number (list->string cx)))

;;; defining parser
(define %escaped-char
  ($do
   [_ ($c #\\)]
   [label ($one-of #[sdwSDW^\\.\-])]
   ($return (cons 'esc (char->symbol label)))))

(define %char ($or %escaped-char ($none-of #[\[\(\|?+*{}}\)\]])))

(define %posix-charset-literal
  ($do
   [_ ($c #\[)]
   [_ ($c #\:)]
   [label ($many lower)]
   [_ ($c #\:)]
   [_ ($c #\])]
   ($return (append (string->list "[:") label (string->list ":]")))))

(define %char-class-char
  ($do
   [c ($none-of #[\]])]
   ($return (list c))))

(define %char-class
  ($lift
   (^[cs] (cons 'class (run #"#[~(list->string (apply append cs))]")))
   ($between ($c #\[) ($many ($or %posix-charset-literal %char-class-char)) ($c #\]))))

(define %atom ($or ($between ($c #\() ($lazy %regex) ($c #\))) %char %escaped-char %char-class))

(define %bracket-range-form
  ($do
   [bounds ($between ($c #\{) ($sep-by ($many1 digit) ($c #\,)) ($c #\}))]
   ($return
    (case (length bounds)
      [(1)
       (cons
        'times
        (chars->number (car bounds)))]
      [else
       (cons
        'range
        (cons
         (chars->number (car bounds))
         (chars->number (cadr bounds))))]))))

(define %piece
  ($do
   [a %atom]
   [quantifier ($many ($or ($one-of #[?*+]) %bracket-range-form))]
   ($return
    (fold
     (^[q body]
       (cond
        [(char? q) (cons (char->symbol q) body)]
        [(pair? q) (cons q body)]
        [else (cons #f body)]))
     (list a)
     quantifier))))

(define %branch ($many1 %piece))

(define %regex ($lift (cut cons 'or <>) ($sep-by %branch ($c #\|))))

;;; generating string

(define (pop gen) (car (generator->list gen 1)))
(define (popstr gen len) (list->string (generator->list gen len)))

(define (walk tree)
  (match tree
    [() ""]
    [(? char? c) ($ list->string $ list c)]
    [(#f . c) (walk c)]
    [('esc . c) (popstr (chars$ (run #"#[\\~c]")) 1)]
    [('class . cs) (popstr (chars$ cs) 1)]
    [(('range . (a . z)) . xs) (walk (make-list (pop (integers-between$ a z)) xs))]
    [(('times . n) . xs) (walk (make-list n xs))]
    [('? . xs) (if (booleans) (walk xs) "")]
    [('+ . xs) (walk (make-list (pop (integers$ *max-repeat* 1)) xs))]
    [('* . xs) (walk (make-list (pop (integers$ *max-repeat* 0)) xs))]
    [('or . xs) ($ walk $ pop $ samples$ xs)]
    [(x . xs) (string-append (walk x) (walk xs))]))

(define sep-by-nl (cut string-join <> "\n"))

;;; main
(define (main *args*)
  (let-args (cdr *args*)
      ([amount "n=i" 10]
       [seed "seed=i" 0]
       [max-repeat "max-repeat=i" 6]
       . restargs)
    (unless (positive? amount) (raise "n should be natural number."))
    (unless (positive? max-repeat) (raise "max-repeat should be natural number."))
    (set! (random-data-seed) seed)
    (set! *max-repeat* max-repeat)
    (let1
        tgt (car restargs)
      ($ print
         $ sep-by-nl
         $ generator->list
         $ generate
         (^[yield]
           (let loop ([i 0])
             (when (< i amount) ($ yield $ walk $ peg-parse-string %regex tgt) (loop (+ i 1)))
             ))))))

