require 'net/imap'
require 'mail'
require 'yaml'
require 'time'
require 'tempfile'
require 'open3'

def repeat_try_shell(command={})
    maxtries = 14
    tries ||= maxtries

    stdout_str, stderr_str, status = Open3.capture3(command)

    if status
    else
        puts Time.now.utc.iso8601
        printf(stdout_str)
        printf(stderr_str)
        numsec = 2**(maxtries - tries)
        printf(" ... will retry in %d seconds\n", numsec)
        sleep(numsec)
        raise "Exception within dwpage.php"
    end
rescue Exception => e
    retry unless (tries -= 1).zero?
    raise e
else
end

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
    msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
    mail = Mail.read_from_string msg
    date = mail.date.strftime("%Y-%m-%d-%H-%M-%S")

    #Lock and checkout target file
    repeat_try_shell('../bin/dwpage.php --user automat lock start')
    repeat_try_shell('../bin/dwpage.php --user automat checkout start')

    #Target file path
    file_path = settings['local_folder']+'data/pages/'+'start.txt'

    #Line to find in the target file
    line_to_find = '====== News ======'

    #Line to add into the target file (after the line to find)
    line_to_add = "{{page>mail:"+date+"}}"

    #Work in temporary file
    temp_file = Tempfile.new('start')

    begin
        #Read target file line by line, write each line to temp file and add line if condition met
        File.readlines(file_path).each do |line|
            temp_file.puts(line)
            temp_file.puts(line_to_add) if line.chomp == line_to_find
        end
        temp_file.close

        #Start commiting changes
        repeat_try_shell('../bin/dwpage.php --user automat commit --message "auto update" ' + temp_file.path + ' start')
        repeat_try_shell('../bin/dwpage.php --user automat unlock start')

    ensure
        temp_file.delete
    end

    subject = mail.subject
    plain_part = mail.multipart? ? (mail.text_part ? mail.text_part.body.decoded : nil) : mail.body.decoded
    html_part = mail.html_part ? mail.html_part.body.decoded : nil

#    puts plain_part

    subject.gsub!("sometext","")
    plain_part.gsub!("othertext","")

    #Parse the email to wiki syntax
    parsed_mail = "<WRAP box 100%>\n" + \
                  "<fs 85%><color #AAAAAA>" +  mail.date.to_s + " from " + mail.from.to_s + "</color></fs>\n" + \
                  "==== " + subject + " ====\n\n" + plain_part + "</WRAP>\n"

    #Work in temporary file
    temp_file = Tempfile.new(date)

    begin
        temp_file.puts(parsed_mail)
        temp_file.close

        #Start commiting changes
        repeat_try_shell('../bin/dwpage.php --user automat commit --message "auto update" ' + temp_file.path + ' mail:' + date)

    ensure
        temp_file.delete
    end

    puts Time.now.utc.iso8601
    puts "One message treated"

end

imap.expunge #Delete all mails with deleted flags
imap.close
