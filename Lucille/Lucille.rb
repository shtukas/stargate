
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::dequeueFirstValueOrNull(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class LucilleThisCore

    # LucilleThisCore::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------
    # IO (1)

    # LucilleThisCore::pathToItems()
    def self.pathToItems()
        "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/Items"
    end

    # LucilleThisCore::pathToTimelines()
    def self.pathToTimelines()
        "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/Timelines"
    end

    # -----------------------------
    # IO (2)

    # LucilleThisCore::ensureStandardFilenames()
    def self.ensureStandardFilenames()
        LucilleThisCore::locations()
            .each{|location|
                if File.basename(location).include?("'") then
                    location2 = "#{File.dirname(location)}/#{File.basename(location).gsub("'", ",")}"
                    FileUtils.mv(location, location2)
                    location = location2
                end
                next if File.basename(location)[0, 3] == "202"
                location2 = "#{File.dirname(location)}/#{LucilleThisCore::timeStringL22()} #{File.basename(location)}"
                FileUtils.mv(location, location2)
            }
    end

    # LucilleThisCore::deleteTimeLineFileIfExistsForThisLocation(location)
    def self.deleteTimeLineFileIfExistsForThisLocation(location)
        location3 = "#{LucilleThisCore::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        if File.exists?(location3) then
            LucilleCore::removeFileSystemLocation(location3)
        end
    end

    # LucilleThisCore::destroyLucilleLocationManaged(location)
    def self.destroyLucilleLocationManaged(location)
        timeline = LucilleThisCore::getLocationTimeline(location)
        CatalystCommon::copyLocationToCatalystBin(location)
        LucilleCore::removeFileSystemLocation(location)
        LucilleThisCore::deleteTimeLineFileIfExistsForThisLocation(location)
    end

    # -----------------------------
    # Data

    # LucilleThisCore::getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(location)
    def self.getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(location)
        locationIsTextFile = lambda {|location| location[-4, 4] == ".txt" }
        locationTextFileHasOneLine = lambda {|location| IO.read(location).strip.lines.to_a.size == 1  }
        locationTextFileStartWithHTTP = lambda {|location| IO.read(location).strip.start_with?("http")  }
        locationDirectoryOnlySubLocationOrNull = lambda {|location|
            filenames = Dir.entries(location)
                            .reject{|filename| filename[0, 1] == "." }
                            .map{|filename| "#{location}/#{filename}" }
            return nil if filenames.size != 1
            filenames[0]
        }
        if File.file?(location) and locationIsTextFile.call(location) and locationTextFileHasOneLine.call(location) and locationTextFileStartWithHTTP.call(location) then
            return IO.read(location).strip
        end
        if File.file?(location) then
            return File.basename(location)
        end
        # Directory
        sublocation = locationDirectoryOnlySubLocationOrNull.call(location)
        if sublocation then
            LucilleThisCore::getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(sublocation)
        else
            File.basename(location)
        end
    end

    # LucilleThisCore::setDescription(location, description)
    def self.setDescription(location, description)
        descriptionKeySuffix = location # Did that after the migration of Open Cycles to their own app to show solidarity
        KeyValueStore::set(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{descriptionKeySuffix}", description)
    end

    # LucilleThisCore::getBestDescription(location)
    def self.getBestDescription(location)
        descriptionKeySuffix = location # Did that after the migration of Open Cycles to their own app to show solidarity
        description = KeyValueStore::getOrNull(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{descriptionKeySuffix}")
        return description if description
        LucilleThisCore::getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(location)
    end

    # LucilleThisCore::locations()
    def self.locations()
        Dir.entries(LucilleThisCore::pathToItems())
            .reject{|filename| filename[0, 1] == "." }
            .sort
            .map{|filename| "#{LucilleThisCore::pathToItems()}/#{filename}" }
    end

    # LucilleThisCore::timelines()
    def self.timelines()
        LucilleThisCore::locations()
            .map{|location| LucilleThisCore::getLocationTimeline(location) }
            .uniq
            .sort
    end

    # LucilleThisCore::setLocationTimeline(location, timeline)
    def self.setLocationTimeline(location, timeline)
        filepath = "#{LucilleThisCore::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        File.open(filepath, "w"){|f| f.puts(timeline) }
    end

    # LucilleThisCore::getLocationTimeline(location)
    def self.getLocationTimeline(location)
        filepath = "#{LucilleThisCore::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        return "[Inbox]" if !File.exists?(filepath)
        IO.read(filepath).strip
    end

    # LucilleThisCore::getTimelineLocations(timeline)
    def self.getTimelineLocations(timeline)
        LucilleThisCore::locations()
            .select{|location| LucilleThisCore::getLocationTimeline(location) == timeline }
    end

    # -----------------------------
    # Operations

    # LucilleThisCore::openLocation(location)
    def self.openLocation(location)
        openableFileExtensions = [
            ".txt",
            ".jpg",
            ".png",
            ".eml",
            ".webm",
            ".jpeg",
            ".webloc"
        ]

        return if !File.exists?(location)
        if File.directory?(location) then
            system("open '#{location}'")
            return
        end

        if File.file?(location) and location[-4, 4] == ".txt" and IO.read(location).strip.lines.to_a.size == 1 and IO.read(location).strip.start_with?("http") then
            url = IO.read(location).strip
            if ENV["COMPUTERLUCILLENAME"] == "Lucille18" then
                system("open '#{url}'")
            else
                system("open -na 'Google Chrome' --args --new-window '#{url}'")
            end
            return
        end

        if File.file?(location) and openableFileExtensions.any?{|extension| location[-extension.size, extension.size] == extension } then
            system("open '#{location}'")
            return
        end
    end

    # LucilleThisCore::transformIntoNyxItem(location)
    def self.transformIntoNyxItem(location)

        makePermanodeTags = lambda {
            tags = []
            loop {
                tag = LucilleCore::askQuestionAnswerAsString("tag (empty to quit): ")
                break if tag == ""
                tags << tag
            }
            tags
        }

        makePermanodeArrows = lambda {
            arrows = []
            loop {
                item = LucilleCore::askQuestionAnswerAsString("Arrows (empty to quit): ")
                break if item == ""
                arrows << item
            }
            arrows
        }

        return if location.nil?

        nyxfoldername = LucilleThisCore::timeStringL22()
        monthFolderpath = "/Users/pascal/Galaxy/Nyx/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}"
        if !File.exists?(monthFolderpath) then
            FileUtils.mkpath(monthFolderpath)
        end
        nyxfolderpath = "#{monthFolderpath}/#{nyxfoldername}"
        FileUtils.mkdir(nyxfolderpath)

        LucilleCore::copyFileSystemLocation(location, nyxfolderpath)

        permanodeTarget = {
            "uuid"       => SecureRandom.uuid,
            "type"       => "perma-dir-11859659",
            "foldername" => nyxfoldername
        }

        permanodeFilename = "#{LucilleThisCore::timeStringL22()}.json"
        permanodeFilePath = "#{monthFolderpath}/#{permanodeFilename}"

        permanode = {}
        permanode["uuid"] = SecureRandom.uuid
        permanode["filename"] = permanodeFilename
        permanode["creationTimestamp"] = Time.new.to_f
        permanode["referenceDateTime"] = Time.now.utc.iso8601
        permanode["description"] = LucilleCore::askQuestionAnswerAsString("permanode description: ")
        permanode["targets"] = [ permanodeTarget ]
        permanode["tags"] = makePermanodeTags.call()
        permanode["arrows"] = makePermanodeArrows.call()

        File.open(permanodeFilePath, "w"){|f| f.puts(JSON.pretty_generate(permanode)) }

        LucilleCore::removeFileSystemLocation(location)
    end

    # LucilleThisCore::transformLocationFileIntoLocationFolder(location)
    def self.transformLocationFileIntoLocationFolder(location)
        return File.basename(location) if !File.file?(location)
        locationbasename = File.basename(location)
        location2basename = LucilleThisCore::timeStringL22()

        location2 = "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/Items/#{location2basename}" # The new receptacle for the file
        FileUtils.mkdir(location2)
        LucilleCore::copyFileSystemLocation(location, location2)

        loop {
            timelinefilepathbefore = "#{LucilleThisCore::pathToTimelines()}/#{locationbasename}.timeline.txt"
            break if !File.exists?(timelinefilepathbefore)
            timelinefilepathafter = "#{LucilleThisCore::pathToTimelines()}/#{location2basename}.timeline.txt"
            FileUtils.mv(timelinefilepathbefore, timelinefilepathafter)
            break
        }

        loop {
            description = LucilleThisCore::getBestDescription(location)
            break if description.nil?
            LucilleThisCore::setDescription(location2, description)
            break
        }

        LucilleCore::removeFileSystemLocation(location)

        location2
    end

    # LucilleThisCore::selectLocationOrNull()
    def self.selectLocationOrNull()
        loop {
            timelineDiveForSelection = lambda{|timeline|
                puts "-> #{timeline}"
                locations = LucilleThisCore::getTimelineLocations(timeline)
                LucilleCore::selectEntityFromListOfEntitiesOrNull("locations:", locations, lambda {|location| LucilleThisCore::getBestDescription(location) })
            }
            timeline = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline:", LucilleThisCore::timelines())
            return nil if timeline.nil?
            location = timelineDiveForSelection.call(timeline)
            return location if location
        }
    end

end

class LXRunManagement

    # LXRunManagement::getRunUnixtimeOrNull(location)
    def self.getRunUnixtimeOrNull(location)
        value = KeyValueStore::getOrNull(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}")
        return nil if value.nil?
        value.to_i
    end

    # LXRunManagement::locationIsRunning(location)
    def self.locationIsRunning(location)
        !LXRunManagement::getRunUnixtimeOrNull(location).nil?
    end

    # LXRunManagement::startLocation(location)
    def self.startLocation(location)
        return if LXRunManagement::getRunUnixtimeOrNull(location)
        KeyValueStore::set(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}", Time.new.to_i)
    end

    # LXRunManagement::stopLocation(location) # return timespan or null
    def self.stopLocation(location)
        unixtime = LXRunManagement::getRunUnixtimeOrNull(location)
        return nil if unixtime.nil?
        KeyValueStore::destroy(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}")
        Time.new.to_i - unixtime
    end
end

=begin

Cluster is a structure that contains a subset of the locations and the time points 
required for the timeline management. 

Cluster {
    "creationUnixtime"      : Integer
    "creatinoDatetime"      : String
    "locations"             : Array[String] # Locations
    "startingLocationCount" : Int
    "timelinesTimePoints"   : Map[Timeline, Array[TimePoint]]
    "computed"              : Object
}

TimePoint {
    "unixtime" : Int
    "timespan" : Float
}

=end

class LXCluster

    # LXCluster::selectLocationsForCluster()
    def self.selectLocationsForCluster()
        LucilleThisCore::timelines()
            .reject{|timeline| timeline=="[Inbox]"}
            .map{|timeline|
                LucilleThisCore::getTimelineLocations(timeline).first(20)
            }
            .flatten
    end

    # LXCluster::makeNewCluster(locations)
    def self.makeNewCluster(locations)

        dummyTimepoint = lambda {
            {
                "unixtime" => Time.new.to_i,
                "timespan" => 0
            }
        }

        timelinesTimePoints = {}
        locations.each{|location|
            timeline = LucilleThisCore::getLocationTimeline(location)
            timelinesTimePoints[timeline] = [ dummyTimepoint.call() ]
        }
        {
            "creationUnixtime"      => Time.new.to_i,
            "creatinoDatetime"      => Time.new.to_s,
            "locations"             => locations,
            "startingLocationCount" => locations.size,
            "timelinesTimePoints"   => timelinesTimePoints,
            "computed"           => {}
        }
    end

    # LXCluster::commitClusterToDisk(cluster)
    def self.commitClusterToDisk(cluster)
        filename = "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/cluster.json"
        File.open(filename, "w") {|f| f.puts(JSON.pretty_generate(cluster)) }
    end

    # LXCluster::issueNewCluster()
    def self.issueNewCluster()
        locations = LXCluster::selectLocationsForCluster()
        cluster = LXCluster::makeNewCluster(locations)
        LXCluster::commitClusterToDisk(cluster)
    end

    # LXCluster::getClusterFromDisk()
    def self.getClusterFromDisk()
        JSON.parse(IO.read("#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/cluster.json"))
    end

    # LXCluster::curateOrRespawnCluster()
    def self.curateOrRespawnCluster()
        cluster = LXCluster::getClusterFromDisk()

        trace1 = Digest::SHA1.hexdigest(JSON.generate(cluster))

        # Removing location that have disappeared
        cluster["locations"] = cluster["locations"].select{|location| File.exists?(location) }

        # Removing locations that are DoNotShowUntil hidden
        cluster["locations"] = cluster["locations"].select{|location| DoNotShowUntil::isVisible(location) }

        if cluster["locations"].size < 0.5*cluster["startingLocationCount"] then
            cluster = LXCluster::makeNewCluster(LXCluster::selectLocationsForCluster())
            LXCluster::commitClusterToDisk(cluster)
        end

        # We want to remove from cluster["timelinesTimePoints"] the timelines that are no longer 
        # relevant, mostlikely because the corresponding location are gone
        timelines = cluster["locations"].map{|location| LucilleThisCore::getLocationTimeline(location) }

        timelines.each{|timeline|
            if cluster["timelinesTimePoints"][timeline].nil? then
                # This happens when the location was recast and put on a timeline that wasn't originally in the cluster
                cluster["timelinesTimePoints"][timeline] = []
            end
        }

        computeTimelineTimespan = lambda {|cluster, timeline|

            cluster["timelinesTimePoints"][timeline].map{|timepoint| timepoint["timespan"]}.inject(0, :+)
        }

        cluster["computed"] = {}

        cluster["computed"]["timelinesTimespans"] = timelines.map{|timeline| [ timeline , computeTimelineTimespan.call(cluster, timeline) ] }.to_h

        cluster["computed"]["timelineOrdered"] = cluster["computed"]["timelinesTimespans"].to_a.sort{|p1, p2| p1[1]<=>p2[1] }

        cluster["computed"]["locationsForDisplay"] = cluster["computed"]["timelineOrdered"]
                                                        .map{|item| item[0] }
                                                        .map{|timeline|  
                                                            cluster["locations"].select{|location| LucilleThisCore::getLocationTimeline(location) == timeline }
                                                        }
                                                        .flatten

        trace2 = Digest::SHA1.hexdigest(JSON.generate(cluster))
        if trace1 != trace2 then
            LXCluster::commitClusterToDisk(cluster)
        end
        cluster
    end

    # LXCluster::getWorkingCluster()
    def self.getWorkingCluster()
        LXCluster::curateOrRespawnCluster()
    end

    # LXCluster::processIncomingLocationTimespan(location, timespan)
    def self.processIncomingLocationTimespan(location, timespan)
        timeline = LucilleThisCore::getLocationTimeline(location)
        cluster = LXCluster::getClusterFromDisk()
        return if cluster["timelinesTimePoints"][timeline].nil?
        point = {
            "unixtime" => Time.new.to_i,
            "timespan" => timespan
        }
        cluster["timelinesTimePoints"][timeline] << point
        LXCluster::commitClusterToDisk(cluster)
    end
end

class LXUserInterface

    # LXUserInterface::doneLucilleLocation(location)
    def self.doneLucilleLocation(location)
        timespan = LXRunManagement::stopLocation(location)
        if timespan then
            LXCluster::processIncomingLocationTimespan(location, timespan)
        end
        LucilleThisCore::destroyLucilleLocationManaged(location)
        LXCluster::curateOrRespawnCluster()
    end

    # LXUserInterface::recastLucilleLocation(location)
    def self.recastLucilleLocation(location)
        timespan = LXRunManagement::stopLocation(location)
        if timespan then
            LXCluster::processIncomingLocationTimespan(location, timespan)
        end
        timeline = nil
        loop {
            timelines = LucilleThisCore::timelines().reject{|timeline| timeline == "[Inbox]" }
            t = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline", timelines)
            if t then
                timeline = t
                break
            end
            t = LucilleCore::askQuestionAnswerAsString("timeline: ")
            if t.size>0 then
                timeline = t
                break
            end
        }
        LucilleThisCore::setLocationTimeline(location, timeline)
        LXCluster::curateOrRespawnCluster()
    end

    # LXUserInterface::ifcsRegistration(location)
    def self.ifcsRegistration(location)
        # First we start my migrating the location to OpenCycles
        LucilleCore::copyFileSystemLocation(location, "/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/Items")
        # Now we need to create a new ifcs item, the only non trivial step if to decide the position
        makeNewIFCSItemPosition = lambda {
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items`)
                .sort{|i1, i2| i1["position"] <=> i2["position"]}
                .each{|item|
                    puts "   - (#{"%5.3f" % item["position"]}) #{item["description"]}"
                }
            LucilleCore::askQuestionAnswerAsString("position: ").to_f
        }
        position = makeNewIFCSItemPosition.call()
        uuid = SecureRandom.uuid
        item = {
            "uuid"                    => uuid,
            "lucilleLocationBasename" => File.basename(location),
            "position"                => position
        }
        File.open("#{CATALYST_COMMON_CATALYST_FOLDERPATH}/InFlightControlSystem/items/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(item)) }
        LucilleCore::removeFileSystemLocation(location)
        LucilleThisCore::deleteTimeLineFileIfExistsForThisLocation(location)
    end

    # LXUserInterface::locationDive(location)
    def self.locationDive(location)
        loop {
            system("clear")
            puts "location: #{location}"
            puts "description: #{LucilleThisCore::getBestDescription(location)}"
            options = [
                "start",
                "open",
                "stop",
                "done",
                "set-description",
                "export-to-desktop",
                "recast",
                ">ifcs",
                ">lucille-other",
                ">nyx",
                "transmute into folder"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "start" then
                LXRunManagement::startLocation(location)
            end
            if option == "stop" then
                timespan = LXRunManagement::stopLocation(location)
                next if timespan.nil?
                LXCluster::processIncomingLocationTimespan(location, timespan)
                LXCluster::curateOrRespawnCluster()
            end
            if option == "open" then
                LucilleThisCore::openLocation(location)
            end
            if option == "done" then
                LXUserInterface::doneLucilleLocation(location)
                return
            end
            if option == "set-description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                LucilleThisCore::setDescription(location, description)
            end
            if option == "export-to-desktop" then
                LucilleCore::copyFileSystemLocation(location, "/Users/pascal/Desktop")
            end
            if option == "recast" then
                LXUserInterface::recastLucilleLocation(location)
            end
            if option == ">ifcs" then
                LXUserInterface::ifcsRegistration(location)
            end
            if option == ">lucille-other" then
                location2 = LucilleThisCore::selectLocationOrNull()
                return if location2.nil?
                if File.file?(location2) then
                    location2 = LucilleThisCore::transformLocationFileIntoLocationFolder(location2)
                end
                LucilleCore::copyFileSystemLocation(location, location2)
                LucilleCore::removeFileSystemLocation(location)
                return
            end
            if option == ">nyx" then
                LucilleThisCore::transformIntoNyxItem(location)
                return
            end
            if option == "transmute into folder" then
                LucilleThisCore::transformLocationFileIntoLocationFolder(location)
            end
        }
    end

    # LXUserInterface::timelineDive(timeline)
    def self.timelineDive(timeline)
        puts "-> #{timeline}"
        loop {
            locations = LucilleThisCore::getTimelineLocations(timeline)
            location = LucilleCore::selectEntityFromListOfEntitiesOrNull("locations:", locations, lambda {|location| LucilleThisCore::getBestDescription(location) })
            break if location.nil?
            LXUserInterface::locationDive(location)
        }
    end

end
