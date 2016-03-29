;;;; -*- Mode: Lisp -*-
;;;;
;;;; Yet Another 'From Scratch' JSON Parser
;;;;
;;;;---------------------------------------------------------------------------
;;;; JSON Parser

(defun jsonparse (JSONString)
  (let ((chars (del-whitespaces (coerce JSONString 'list))))
    (multiple-value-bind (res rest) (or (parse-object chars) 
                                        (parse-array chars))
      (if (and (not (null res)) (null rest)) res
        (error "~S not an object nor an array" JSONString)))))

;;;;---------------------------------------------------------------------------
;;;; Object parser

(defun parse-object (l)
  (let ((ch (car l)) (ch2 (second l)))
    (if (eql ch #\{)
        (if (eql ch2 #\})
            (values (list 'jsonobj) (cdr (cdr l)))
          (multiple-value-bind (res rest) (parse-member (cdr l))
            (if (eql (car rest) #\})
                (values (remove-duplicates 
                         (cons 'jsonobj res) 
                         :test 'evaluate-pair)
                        (cdr rest))
              (error "Unexpected character ~S" (car rest)))))
      (values nil l))))

;;;;---------------------------------------------------------------------------
;;;; Array parser

(defun parse-array (l)
  (let ((ch (car l)) (ch2 (second l)))
    (if (eql ch #\[)
        (if (eql ch2 #\])
            (values (list 'jsonarray) (cdr (cdr l)))
          (multiple-value-bind (res rest) (parse-element (cdr l))
            (if (eql (car rest) #\])
                (values (cons 'jsonarray res) (cdr rest))
              (error "Unexpected character ~S" (car rest)))))
      (values nil l))))

;;;;---------------------------------------------------------------------------
;;;; Element parser

(defun parse-element (l)
  (multiple-value-bind (res rest) (parse-value l)
    (if (null res)
        (error "Unexpected character ~S" (car l))
      (if (eql (car rest) #\,)
          (multiple-value-bind (res2 rest2)
              (parse-element (cdr rest))
            (if (null res2) 
                (error "Unexpected character ~S" (car (car rest)))
              (values (cons res res2) rest2)))
        (values (cons res nil) rest)))))

;;;;---------------------------------------------------------------------------
;;;; Member parser

(defun parse-member (l)
  (multiple-value-bind (res rest) (parse-pair l)
    (if (null res)
         (error "Unexpected character ~S" (car l))
      (if (eql (car rest) #\,)
          (multiple-value-bind (res2 rest2)
              (parse-member (cdr rest))
            (if (null res2)
                 (error "Unexpected character ~S" (cdr (car rest)))
              (values (cons res res2) rest2)))
        (values (cons res nil) rest)))))

;;;;---------------------------------------------------------------------------
;;;; Pair parser

(defun parse-pair (l)
  (multiple-value-bind (res rest) (parse-pair-i l)
    (if (or (null res) (null rest))
        (error "Unexpected character ~S" (car l))
      (if (eql (car rest) #\:)
          (multiple-value-bind (res2 rest2) (parse-value (cdr rest))
            (if (null res2)
                (error "Unexpected character ~S" (cdr (car rest)))
              (values (list res res2) rest2)))
        (error "Unexpected character ~S" (car rest))))))

(defun parse-pair-i (l)
  (let ((ch (car l)))
    (cond ((or (eql ch #\") (eql ch #\')) (parse-string l))
          ((alpha-char-p ch) (parse-identifier l))
          (T (error 'unexpected-character ch)))))

;;;;---------------------------------------------------------------------------
;;;; Value parser

(defun parse-value (l)
  (let ((ch (car l)))
    (cond ((eql ch #\{) (parse-object l))
          ((eql ch #\[) (parse-array l))
          ((or (eql ch #\") (eql ch #\')) (parse-string l))
          ((or (eql ch #\-) (digit-char-p ch)) (parse-number l))
          (T (error "Unexpected character ~S" ch)))))
    
;;;;---------------------------------------------------------------------------
;;;; String parser

(defun parse-string (l)
  (let ((ch (car l)))
      (if (or (eql ch #\") (eql ch #\'))
          (multiple-value-bind (val rest)
              (parse-string-i (cdr l) ch)
            (values (coerce val 'string) rest))
        (error "Unexpected character ~S" ch))))

(defun parse-string-i (l end)
  (let ((ch (car l)))
    (if (null ch) (error "Unexpected end of chars")
      (cond ((eql ch end) (values nil (cdr l)))
            ((eql ch #\\) (multiple-value-bind (val rest)
                              (parse-string-i (cdr (cdr l)) end)
                            (values (cons (second l) val) rest)))
            (T (multiple-value-bind (val rest)
                   (parse-string-i (cdr l) end)
                 (values (cons ch val) rest)))))))

;;;;---------------------------------------------------------------------------
;;;; Identifier parser

(defun parse-identifier (l)
  (let ((ch (car l)))
    (if (null ch) (error "NIL is not a value")
      (if (alpha-char-p ch)
          (multiple-value-bind (val rest) (parse-identifier-i (cdr l))
            (values (coerce (cons ch val) 'string) rest))
        (error "Unexpected character ~S" ch)))))

(defun parse-identifier-i (l)
  (let ((ch (car l)))
    (if (null ch) nil
      (if (alphanumericp ch)
          (multiple-value-bind (val rest) (parse-identifier-i (cdr l))
            (values (cons ch val) rest))
        (values nil l)))))

;;;;---------------------------------------------------------------------------
;;;; Number parser

(defun parse-number (l)
  (let ((ch (car l)))
    (cond ((digit-char-p ch)
           (multiple-value-bind (val rest) (parse-number-ib (cdr l))
             (values (car (multiple-value-list
                           (read-from-string
                            (coerce (cons ch val) 'string)))) rest)))
          ((eql ch #\-)
           (multiple-value-bind (val rest) (parse-number-ia (cdr l))
             (values (car (multiple-value-list
                           (read-from-string
                            (coerce (cons ch val) 'string)))) rest)))
          (T (error "Unexpected character ~S" ch)))))

(defun parse-number-ia (l)
  (let ((ch (car l)))
    (if (null ch) nil
      (if (digit-char-p ch)
          (multiple-value-bind (val rest) (parse-number-ib (cdr l))
            (values (cons ch val) rest))
        (error "Unexpected character ~S" ch)))))

(defun parse-number-ib (l)
  (let ((ch (car l)))
    (if (null ch) nil
      (cond ((eql ch #\.)
             (multiple-value-bind (val rest) (parse-floatb (cdr l))
               (values (cons ch val) rest)))
            ((digit-char-p ch)
             (multiple-value-bind (val rest) (parse-number-ib (cdr l))
               (values (cons ch val) rest)))
            (T (values nil l))))))

(defun parse-floatb (l)
  (let ((ch (car l)))
    (if (null ch) (error "Unexpected end of chars")
      (if (digit-char-p ch)
          (multiple-value-bind (val rest) (parse-floatb-i (cdr l))
            (values (cons ch val) rest))
        (error "Unexpected character ~S" ch)))))

(defun parse-floatb-i (l)
  (let ((ch (car l)))
    (if (null ch) nil
      (if (digit-char-p ch)
          (multiple-value-bind (val rest) (parse-floatb-i (cdr l))
            (values (cons ch val) rest))
        (values nil l)))))

;;;;---------------------------------------------------------------------------
;;;; JSON Consult

(defun jsonget (json &rest flds)
  (if (null json) (error "JSON object not valid")
    (if (null flds) json
      (if (not (listp json))
          (error "Reached the value ~S, can't find remaining field(s): ~S"
                 json flds)
        (let ((obj (car json)))
          (cond ((eq obj 'jsonobj)
                 (let ((match (assoc (car flds)
                                     (cdr json)
                                     :test 'equalp)))
                   (if (null match) 
                       (error "No matching pair for the following key: ~S"
                              (car flds))
                     (apply 'jsonget
                            (second match)
                            (cdr flds)))))
                ((eq obj 'jsonarray)
                 (if (numberp (car flds))
                     (let ((match (nth (+ 1 (car flds)) json)))
                       (if (null match)
                           (error "Array index out of bounds: ~S"
                                  (car flds))
                         (apply 'jsonget
                                match
                                (cdr flds))))
                   (error "~S is not an array index"
                          (car flds))))))))))

;;;;---------------------------------------------------------------------------
;;;; Read from file

(defun jsonload (filename)
  (with-open-file (in filename
                      :direction :input
                      :if-does-not-exist :error)
    (jsonparse (coerce (read-string-from in) 'string))))
  

(defun read-string-from (s)
  (let ((e (read-char s nil 'eof)))
    (unless (eq e 'eof)
      (cons e (read-string-from s)))))

;;;;---------------------------------------------------------------------------
;;;; Write object on file

(defun jsonwrite (json filename)
  (cond ((null json) (error "JSON is NIL"))
        ((null filename) (error "Filename is NIL"))
        (T (with-open-file (out filename
                                :direction :output
                                :if-exists :supersede
                                :if-does-not-exist :create)
             (format out "~A" (coerce (flatten (or (write-array json)
                                                   (write-object json)))
                                      'string)))))
  filename)

(defun write-array (json)
  (if (eq (car json) 'jsonarray)
      (if (null (cdr json)) (list #\[ #\])
        (list #\[ (write-values (cdr json)) #\]))
    nil))

(defun write-object (json)
  (if (eq (car json) 'jsonobj)
      (if (null (cdr json)) (list #\{ #\})
        (list #\{ (write-pairs (cdr json)) #\}))
    nil))

(defun write-values (json)
  (if (null (cdr json)) (list (write-value (car json)))
    (list (write-value (car json)) #\, (write-values (cdr json)))))

(defun write-value (json)
  (cond ((null json) nil)
        ((numberp json) (coerce (write-to-string json) 'list))
        ((stringp json) (list #\" (write-companion (coerce json 'list)) #\"))
        ((eq (car json) 'jsonarray) (write-array json))
        ((eq (car json) 'jsonobj) (write-object json))))

(defun write-pairs (json)
  (if (null (cdr json)) (list (write-value (car (car json)))
                              #\:
                              (write-value (car (cdr (car json)))))
    (list (write-value (car (car json)))
          #\:
          (write-value (car (cdr (car json))))
          #\,
          (write-pairs (cdr json)))))

;;;;---------------------------------------------------------------------------
;;;; Companion funcs

(defun write-companion (l)
  (cond ((null (car l)) nil)
        ((or (eql (car l) #\") (eql (car l) #\'))
         (cons #\\ (cons (car l) (write-companion (cdr l)))))
        (T (cons (car l) (write-companion (cdr l))))))

(defun evaluate-pair (p1 p2)
  (if (and (listp p1) (listp p2))
      (string= (car p1) (car p2))
    nil))

(defun del-whitespaces (l)
  (let ((ch (car l)))
    (cond ((or (eql ch #\Space)
               (eql ch #\Newline)
               (eql ch #\Tab)) (del-whitespaces (cdr l)))
          ((null ch) nil)
          ((or (eql ch #\")
               (eql ch #\')) (cons ch (del-whitespaces-i (cdr l))))
          (T (cons ch (del-whitespaces (cdr l)))))))

(defun del-whitespaces-i (l)
  (let ((ch (car l)))
    (cond ((null ch) nil)
          ((eql ch #\\)
           (cons (car l)
                 (cons (second l) (del-whitespaces-i (cdr (cdr l))))))
          ((or (eql ch #\")
               (eql ch #\')) (cons ch (del-whitespaces (cdr l))))
          (T (cons ch (del-whitespaces-i (cdr l)))))))

(defun flatten (x)
  (cond ((null x) x)
        ((atom x) (list x))
        (T (append (flatten (first x))
                   (flatten (rest x))))))

;;;; end of file -- json-parsing.lisp --
