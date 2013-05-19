require 'net/imap'
require 'mail'
require 'yaml'

#Retrieve settings from external file
settings = YAML.load_file('settings.yml')

#Start the actual work
imap = Net::IMAP.new(settings['imap_host'], settings['imap_port'], settings['imap_ssl'], nil, false)
if settings['imap_auth_mechanism'].nil?
  imap.login(settings['imap_user'], settings['imap_password'])
else
  imap.authenticate(settings['imap_auth_mechanism'], settings['imap_user'], settings['imap_password'])
end
imap.select('INBOX')
      
#Select unseen messages only
imap.search(["NOT", "SEEN"]).each do |message_id|
	#Get the full content
	raw = imap.fetch(message_id, "BODY[]")[0].attr["BODY[]"]
	imap.store(message_id, '+FLAGS', [:Seen])
	#Parse it with mail library
	mail = Mail.read_from_string(raw)
	token = mail.to.to_s
	#If multipart or auth token not included, then discard the mail
	if mail.multipart? or (not settings['token_email'].nil? and not token.include?(settings['token_email'].to_s))
    imap.copy(message_id, 'Untreated')
  else
		content = mail.body.decoded
		subject = mail.subject
		date = mail.date.strftime("%Y-%m-%d-%H-%M-%S")
		
		#Adding title (i.e. subject from email)) with dokuwiki syntax
		content = "==== " + subject + " ====\n" + content
		#Formating a link to be inserted in the dokuwiki start page
    link = "[[#{date}|#{subject}]]"

		#Here, create the file and write the content in the dokuwiki folder
		File.open(settings['local_folder']+date+'.txt', 'w') {|f| f.write(content) }
		File.open(settings['local_folder']+'start.txt', 'a') {|f| f.write(link) }
		
		imap.copy(message_id, 'Treated')
	end
    imap.store(message_id, '+FLAGS', [:Deleted])
end
imap.expunge #Delete all mails with deleted flags
imap.close
