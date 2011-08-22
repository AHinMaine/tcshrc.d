    # common
    complete emacs                  c/--/"(batch d f funcall i insert kill l load \
                                    no-init-file nw q t u user)"/ \
                                    c/-/"(batch d f funcall i insert kill l load \
                                    no-init-file nw q t u user)"/ \
                                    c/+/x:'<line_number>'/ \
                                    n/-d/x:'<display>'/ \
                                    n/-f/x:'<lisp_function>'/ \
                                    n/-i/f/ \
                                    n@-l@F:$_elispdir@ \
                                    n/-t/x:'<terminal>'/ \
                                    n/-u/u/ \
                                    n/*/f:^*[\#~]/

