(ert-deftest tandem-message-new-patches ()
  (should
   (equal
    (tandem-message-new-patches
     (list (tandem-agent-report-local-write '(0 . 0) '(0 . 1) "h")))
    '("new-patches" (patch_list ((start (row . 0) (column . 0))
                                 (end (row . 0) (column . 1))
                                 (text . "h")))))))

(ert-deftest tandem-message-session-info ()
  (should
   (equal (tandem-message-session-info 100) '("session-info" (session_id . 100)))))

(ert-deftest tandem-message-session-info-serialize-deserialize ()
  (should
   (equal
    (tandem-message-session-info 100)
    (tandem-message-deserialize
     (tandem-message-serialize (tandem-message-session-info 100))))))

(ert-deftest tandem-message-session-info-serialize ()
  (should
   (string= (tandem-message-serialize (tandem-message-session-info 100))
         "{\"type\":\"session-info\",\"payload\":{\"session_id\":100},\"version\":1}")))


(ert-deftest tandem-serialize-deserialize ()
  (should
   (equal
    (tandem-message-deserialize (tandem-message-serialize
                                (tandem-message-new-patches
                                 (list (tandem-agent-report-local-write '(0 . 0)
                                                                        '(0 . 1)
                                                                        "h")))))
  '("new-patches" (patch_list
                   . [((start (row . 0) (column . 0))
                       (end (row . 0) (column . 1))
                       (text . "h"))]))))))
