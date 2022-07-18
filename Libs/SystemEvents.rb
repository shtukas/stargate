
# encoding: UTF-8

=begin
    Mercury2::put(channel, value)
    Mercury2::readOrNull(channel)
    Mercury2::dequeue(channel)
=end

class SystemEvents

    # SystemEvents::processEventInternally(event)
    def self.processEventInternally(event)

        puts "SystemEvent(#{JSON.pretty_generate(event)})"

        if event["mikuType"] == "(object has been updated)" then
            filepath = Fx18Utils::computeLocalFx18Filepath(event["objectuuid"])
            return if !File.exists?(filepath) # object has been updated on one computer but has not yet been put on another
            Fx18Index1::updateIndexForFilepath(filepath)
        end

        if event["mikuType"] == "(object has been deleted)" then
            Fx18Index1::removeRecordForObjectUUID(event["objectuuid"])
        end

        if event["mikuType"] == "NxBankEvent" then
            Bank::processEventInternally(event)
            return
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            DoNotShowUntil::processEventInternally(event)
            return
        end

        if event["mikuType"] == "SetDoneToday" then
            DoneToday::processEventInternally(event)
            return
        end

        if event["mikuType"] == "RemoveFromListing" then
            Listing::remove(event["itemuuid"])
            return
        end

        if event["mikuType"] == "NxDeleted" then
            # Todo:
            return
        end

        if event["mikuType"] == "Fx18 File Event" then
            event["Fx18FileEvent"]["_eventData1_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData1_"])
            event["Fx18FileEvent"]["_eventData2_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData2_"])
            event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData3_"])
            event["Fx18FileEvent"]["_eventData4_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData4_"])
            event["Fx18FileEvent"]["_eventData5_"] = CommonUtils::base64_decode(event["Fx18FileEvent"]["_eventData5_"])
            objectuuid = event["objectuuid"]
            Fx19Data::ensureFileForPut(objectuuid)
            eventi = event["Fx18FileEvent"]
            Fx18File::writeGenericFx18FileEvent(objectuuid, eventi["_eventuuid_"], eventi["_eventTime_"], eventi["_eventData1_"], eventi["_eventData2_"], eventi["_eventData3_"], eventi["_eventData4_"], eventi["_eventData5_"])
            return
        end
    end

    # SystemEvents::issueStargateDrop(event)
    def self.issueStargateDrop(event)
        if event["mikuType"] == "Fx18 File Event" then
            event["Fx18FileEvent"]["_eventData1_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData1_"])
            event["Fx18FileEvent"]["_eventData2_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData2_"])
            event["Fx18FileEvent"]["_eventData3_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData3_"])
            event["Fx18FileEvent"]["_eventData4_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData4_"])
            event["Fx18FileEvent"]["_eventData5_"] = CommonUtils::base64_encode(event["Fx18FileEvent"]["_eventData5_"])
        end
        filename = "#{CommonUtils::nx45()}.json"
        filepath = "/Volumes/Keybase (pascal)/private/0x1021/Stargate-Drops/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(event)) }
    end
end