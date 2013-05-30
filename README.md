dokuwiki-mail-fetcher
=====================

A script to automate fetching new mails on a dedicated mailbox to populate a dokuwiki instance.

All settings should be configured in settings.yml (how original!).

* imap_host: hostname of the imap server (e.g. imap.google.com)
* imap_port: port of the imap server
* imap_ssl: should ssl be used? (true/false)
* imap_auth_mechanism: which auth mechanism should be used (e.g. PLAIN or LOGIN)
* imap_user: username
* imap_password: password
* token_email: if uncommented, then the token mechanism is activated
* local_folder: path to the dokuwiki instance

Email token mechanism
---------------------
If a token is specified, then the script checks for the presence of the token within the email address to which the email to be parsed was sent.
For example, if token_email is "abcd" then the script will accept an email sent to me+abcd@server.com and disregard any email sent to me@server.com.
