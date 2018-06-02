
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Constants.rb"

# ---------------------------------------------------------------------

# EventsMaker::destroyCatalystObject(uuid)
# EventsMaker::catalystObject(object)
# EventsMaker::doNotShowUntilDateTime(uuid, datetime)
# EventsMaker::fKeyValueStoreSet(key, value)

class EventsMaker
    def self.destroyCatalystObject(uuid)
        {
            "event-type"  => "Catalyst:Destroy-Catalyst-Object:1",
            "object-uuid" => uuid
        }
    end

    def self.catalystObject(object)
        {
            "event-type" => "Catalyst:Catalyst-Object:1",
            "object"     => object
        }
    end

    def self.doNotShowUntilDateTime(uuid, datetime)
        {
            "event-type"  => "Catalyst:Metadata:DoNotShowUntilDateTime:1",
            "object-uuid" => uuid,
            "datetime"    => datetime
        }
    end

    def self.fKeyValueStoreSet(key, value)
        {
            "event-type" => "Flock:KeyValueStore:Set:1",
            "key"        => key,
            "value"      => value
        }
    end
end

# EventsManager::pathToActiveEventsIndexFolder()
# EventsManager::commitEventToTimeline(event)
# EventsManager::commitEventToBufferIn(event)
# EventsManager::eventsEnumerator()

class EventsManager
    def self.pathToActiveEventsIndexFolder()
        folder1 = "#{CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d")}/#{Time.new.strftime("%Y%m%d-%H")}"
        FileUtils.mkpath folder1 if !File.exists?(folder1)
        LucilleCore::indexsubfolderpath(folder1)
    end

    def self.commitEventToTimeline(event)
        folderpath = EventsManager::pathToActiveEventsIndexFolder()
        filepath = "#{folderpath}/#{LucilleCore::timeStringL22()}.json"
        File.open(filepath, "w"){ |f| f.write(JSON.pretty_generate(event)) }
    end

    def self.commitEventToBufferIn(event) # To be read only by Lucille18
        filepath = "#{CATALYST_COMMON_PATH_TO_EVENTS_BUFFER_IN}/#{LucilleCore::timeStringL22()}.json"
        File.open(filepath, "w"){ |f| f.write(JSON.pretty_generate(event)) }
    end

    def self.eventsEnumerator()
        Enumerator.new do |events|
            Find.find(CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE) do |path|
                next if !File.file?(path)
                next if File.basename(path)[-5,5] != '.json'
                event = JSON.parse(IO.read(path))
                event[":filepath:"] = path
                events << event
            end
        end
    end
end