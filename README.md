dokuwiki-mail-fetcher
=====================

A script to automate fetching new mails on a dedicated mailbox to populate a dokuwiki instance. The mail content is formated and inserted into the DokuWiki start page after a selected line.

Features
--------
 * Prevents DokiWiki External Edit issue.
 * Employment of [DokuWiki PHP CLI](https://www.dokuwiki.org/cli)
 * Error management (e.g. due to a page being edited at the moment)

Configuration
-------------
* imap_host: hostname of the imap server (e.g. imap.google.com)
* imap_port: port of the imap server
* imap_ssl: should ssl be used? (true/false)
* imap_auth_mechanism: which auth mechanism should be used (e.g. PLAIN or LOGIN)
* imap_user: username
* imap_password: password
* local_folder: path to the dokuwiki instance


Usage
-----
* **Important**: Allways run the script as www-data (or equivalent) user. Otherwise it will mess up file permissions.
* **Required**: Install the [DokuWiki include plugin](https://www.dokuwiki.org/plugin:include).

To run the script e.g. every 5 minutes, set up root cron to

```bash
*/5 * * * * cd /var/www/your-web-folder/mail-fetcher/; sudo -u www-data ruby2.0 fetcher.rb >> fetch.log
```
