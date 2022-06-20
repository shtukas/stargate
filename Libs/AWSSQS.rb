
# encoding: UTF-8

require 'aws-sdk-sqs'
require 'aws-sdk-sts'

class AWSSQS

    # AWSSQS::sqs_url_or_null(machinesource, machinetarget)
    def self.sqs_url_or_null(machinesource, machinetarget)
        if machinesource == "Lucille18" and machinetarget == "Lucille20" then
            return Config::get("aws.SQS.URL.Lucille18ToLucille20")
        end
        if machinesource == "Lucille20" and machinetarget == "Lucille18" then
            return Config::get("aws.SQS.URL.Lucille20ToLucille18")
        end
        nil
    end

    # AWSSQS::sendEventToTheOtherMachine(event)
    def self.sendEventToTheOtherMachine(event)
        Aws.config.update({
           credentials: Aws::Credentials.new(Config::get("aws.AWS_ACCESS_KEY_ID"), Config::get("aws.AWS_SECRET_ACCESS_KEY"))
        })

        region = 'eu-west-1'

        machinesource = Machines::thisMachine()
        machinetarget = Machines::theOtherMachine()

        sqs_url = AWSSQS::sqs_url_or_null(machinesource, machinetarget)

        if sqs_url.nil? then
            puts "Could not determine queue url"
            return
        end

        sqs_client = Aws::SQS::Client.new(region: region)

        begin 
            sqs_client.send_message(
                queue_url: sqs_url,
                message_body: JSON.generate(event)
            )
        rescue StandardError => e
            puts "Error sending messages: #{e.message}"
        end
    end

    # AWSSQS::pullAndProcessEvents()
    def self.pullAndProcessEvents()

        Aws.config.update({
           credentials: Aws::Credentials.new(Config::get("aws.AWS_ACCESS_KEY_ID"), Config::get("aws.AWS_SECRET_ACCESS_KEY"))
        })

        region = 'eu-west-1'

        machinesource = Machines::theOtherMachine()
        machinetarget = Machines::thisMachine()

        sqs_url = AWSSQS::sqs_url_or_null(machinesource, machinetarget)

        sqs_client = Aws::SQS::Client.new(region: region)

        begin 
            loop {

                receive_message_result = sqs_client.receive_message({
                  queue_url: sqs_url, 
                  message_attribute_names: ["All"], # Receive all custom attributes.
                  max_number_of_messages: 1, # Receive at most one message.
                  wait_time_seconds: 0 # Do not wait to check for the message.
                })

                break if receive_message_result.messages.size == 0

                receive_message_result.messages.each{|message|
                    event = JSON.parse(message.body)

                    puts JSON.pretty_generate(event)

                    Librarian::incomingEventFromOutside(event)

                    sqs_client.delete_message({
                        queue_url: sqs_url,
                        receipt_handle: message.receipt_handle    
                    })
                }
            }
        rescue StandardError => e
            puts "Error sending messages: #{e.message}"
        end
    end
end
