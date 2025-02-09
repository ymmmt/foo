(in-package :foo.xml)

(defun html->string (sexp)
  (with-output-to-string (s)
    (with-foo-output (s :pretty t)
      (emit-html sexp))))

(defparameter *testfiles* #p"./html-testfiles/")

(deftest test-files ()
  (let ((files (list-directory *testfiles*)))
    (dolist (file files)
      (when (and (string= (pathname-type file) "fhtml")
		 (file-exists-p (make-pathname :type "html" :defaults file)))
	(test-file file)))))

(defun new-tests ()
  (let ((files (list-directory *testfiles*)))
    (dolist (file files)
      (when (and (string= (pathname-type file) "fhtml")
		 (not (file-exists-p (make-pathname :type "html" :defaults file))))
	(format t "No .html file for ~a~%" file)))))

(defun next-number ()
  (let ((files (list-directory *testfiles*))
	(number 0))
    (dolist (file files)
      (when (string= (pathname-type file) "fhtml")
	(let ((num (parse-integer (file-namestring file) :junk-allowed t :start 4)))
	  (setf number (max number num)))))
    (1+ number)))

(defun test-file (input)
  (let ((expected (file-text (make-pathname :type "html" :defaults input)))
	(sexp (with-open-file (in input) (read in))))
    (check (string= (html->string sexp) expected))))

(defun look (number) 
  (let* ((input (make-pathname :directory '(:relative "html-testfiles") :name (format nil "test~3,'0d" number) :type "fhtml"))
	 (output (make-pathname :type "html" :defaults input)))
    (format t "~%fhtml:~%----------~%")
    (with-open-file (in input)
      (loop for line = (read-line in nil nil) while line do (format t "~a~%" line)))
    (format t "~&----------~%")
    (format t "~%expected:~%----------~%")
    (when (probe-file output)
      (with-open-file (in output)
	(loop for line = (read-line in nil nil) while line do (format t "~a~%" line))))
    (format t "~&----------~%")
    (format t "~%got:~%----------~%")
    (with-open-file (in input)
      (format t "~a" (html->string (read in))))
    (format t "~&----------~%"))
  number)


(defun new-test (sexp &optional (number (next-number)))
  (let* ((output (make-pathname :directory '(:relative "html-testfiles") :name (format nil "test~3,'0d" number) :type "fhtml")))
    (with-open-file (out output :direction :output :if-exists :error)
      (prin1 sexp out)))
  (look number))

(defun ok (number) 
  (let* ((input (make-pathname :directory '(:relative "html-testfiles") :name (format nil "test~3,'0d" number) :type "fhtml"))
	 (output (make-pathname :type "html" :defaults input)))
    (with-open-file (out output :direction :output :if-exists :supersede)
	(format out "~a" (with-open-file (in input) (html->string (read in)))))))
