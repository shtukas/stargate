
class NxBall

    # NxBall::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/NxBall"
        LucilleCore::locationsAtFolder(folderpath)
                .select{|filepath| filepath[-5, 5] == ".json" }
                .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxBall::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxBall/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxBall::commit(item)
    def self.commit(item)
        filepath = "#{Config::pathToDataCenter()}/NxBall/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxBall::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Config::pathToDataCenter()}/NxBall/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxBall::issue(cx22)
    def self.issue(cx22)
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxBall",
            "unixtime" => Time.new.to_f,
            "announce" => cx22["description"],
            "cx22"     => cx22["uuid"]
        }
        NxBall::commit(item)
        item
    end

    # NxBall::interactivelyIssueNewNxBallOrNothing()
    def self.interactivelyIssueNewNxBallOrNothing()
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if cx22.nil?
        NxBall::issue(cx22)
    end

    # NxBall::commitTimeAndDestroy(item)
    def self.commitTimeAndDestroy(item)
        timespan = Time.new.to_i - item["unixtime"]
        puts "Adding #{(timespan.to_f/3600).round(2)} hours to #{item["announce"]}"
        Bank::put(item["cx22"], timespan)
        NxBall::destroy(item["uuid"])
    end

    # NxBall::access(item)
    def self.access(item)
        if LucilleCore::askQuestionAnswerAsBoolean("stop NxBall '#{item["announce"]}' ? ") then
            NxBall::commitTimeAndDestroy(item)
        end
    end

    # NxBall::toString(item)
    def self.toString(item)
        timespan = Time.new.to_f - item["unixtime"]
        "(nxball) #{item["announce"]} (running for #{(timespan.to_f/3600).round(2)} hours)"
    end
end