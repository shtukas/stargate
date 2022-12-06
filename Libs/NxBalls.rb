# encoding: UTF-8

class NxBalls

    # -----------------------------------------
    # IO

    # NxBalls::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxBall/#{uuid}.json"
    end

    # NxBalls::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxBall")
            .select{|filepath| filepath[-5, 5] == ".json" }
    end

    # NxBalls::items()
    def self.items()
        NxBalls::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxBalls::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = NxBalls::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxBalls::commit(item)
    def self.commit(item)
        filepath = NxBalls::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxBalls::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxBalls::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxBalls::issue(accounts)
    def self.issue(accounts)
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBall",
            "unixtime"    => Time.new.to_i,
            "accounts"    => accounts
        }
        NxBalls::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxBalls::toString(item)
    def self.toString(item)
        timespan = (Time.new.to_i - item["unixtime"]).to_f/3600
        "(nxball) #{item["accounts"].map{|account| account["description"]}.join("; ")} (running for #{timespan.round(2)} hours)"
    end

    # --------------------------------------------------
    # Operations

    # NxBalls::close(nxball)
    def self.close(nxball)
        timespan = Time.new.to_i - nxball["unixtime"]
        nxball["accounts"].each{|account|
            puts "Bank: putting #{timespan} seconds into '#{account["description"]}', account: #{account["number"]}"
            Bank::put(account["number"], timespan)
        }
        NxBalls::destroy(nxball["uuid"])
    end

    # NxBalls::start()
    def self.start()
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if cx22.nil?
        NxBalls::issue([{
            "description" => cx22["description"],
            "number"      => cx22["uuid"]
        }])
    end
end
