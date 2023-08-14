

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        BladesGI::init("NxTask", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "field11", coredataref)

        BladesGI::itemOrNull(uuid)
    end

    # NxTasks::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)

        position = Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
        return nil if position.nil?
        tx8 = Tx8s::make(parent["uuid"], position)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        BladesGI::init("NxTask", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "field11", coredataref)
        BladesGI::setAttribute2(uuid, "parent", tx8)

        BladesGI::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        BladesGI::init("NxTask", uuid)

        nhash = BladesGI::putDatablob2(uuid, url)
        coredataref = "url:#{nhash}"

        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "field11", coredataref)
        BladesGI::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(location)
    def self.locationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        BladesGI::init("NxTask", uuid)

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "field11", coredataref)
        BladesGI::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        BladesGI::init("NxTask", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask_vX(uuid, description)
    def self.descriptionToTask_vX(uuid, description)
        BladesGI::init("NxTask", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "🔹#{Tx8s::positionInParentSuffix(item)} #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTasks::orphanItems()
    def self.orphanItems()
        BladesGI::mikuType("NxTask")
            .select{|item| item["parent"].nil? }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::pile(task)
    def self.pile(task)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text.lines.to_a.map{|line| line.strip }.select{|line| line != ""}.reverse.each {|line|
            t1 = NxTasks::descriptionToTask(line)
            next if t1.nil?
            puts JSON.pretty_generate(t1)
            t1["parent"] = Tx8s::make(task["uuid"], Tx8s::newFirstPositionAtThisParent(task))
            puts JSON.pretty_generate(t1)
            BladesGI::setAttribute2(t1["uuid"], "parent", t1["parent"])
        }
    end

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::access(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()
        # Ensuring consistency of task parenting targets
        BladesGI::mikuType("NxTask").each{|task|
            next if task["parent"].nil?
            if BladesGI::itemOrNull(task["parent"]["uuid"]).nil? then
                BladesGI::setAttribute2(uuid, "parent", nil)
            end
        }

        # Pick up NxFronts-BufferIn
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataHub/NxFronts-BufferIn").each{|location|
            NxTasks::locationToTask(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        # Feed Infinity using NxIce
        if BladesGI::mikuType("NxTask").size < 100 then
            BladesGI::mikuType("NxIce").take(10).each{|item|
                item["mikuType"] == "NxTask"
                BladesGI::setAttribute2(item["uuid"], "mikuType", "NxTask")
                core = BladesGI::itemOrNull("7cf30bc6-d791-4c0c-b03f-16c728396f22") # Infinity Core
                tx8 = Tx8s::make(parent["uuid"], Tx8s::nextPositionAtThisParent(core))
                BladesGI::setAttribute2(item["uuid"], "parent", tx8)
            }
        end
    end

    # NxTasks::fsck()
    def self.fsck()
        BladesGI::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
