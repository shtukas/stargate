# encoding: UTF-8

class DoneToday

    # DoneToday::setDoneToday(uuid)
    def self.setDoneToday(uuid)
        XCache::setFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{CommonUtils::today()}:#{uuid}", true)
        SystemEvents::issueStargateDrop({
          "mikuType"   => "SetDoneToday",
          "targetuuid" => uuid,
          "targetdate" => CommonUtils::today(),
        })
    end

    # DoneToday::isDoneToday(uuid)
    def self.isDoneToday(uuid)
        XCache::getFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{CommonUtils::today()}:#{uuid}")
    end

    # DoneToday::processEventInternally(event)
    def self.processEventInternally(event)
        if event["mikuType"] == "SetDoneToday" then
            XCache::setFlag("5076cc18-5d74-44f6-a6f9-f6f656b7aac4:#{event["targetdate"]}:#{event["targetuuid"]}", true)
            return
        end
    end
end
