
class NxBurners

    # NxBurners::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Solingen::init("NxBurner", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::getItemOrNull(uuid)
    end

    # ------------------------------------
    # Data
    # ------------------------------------

    # NxBurners::toString(item)
    def self.toString(item)
        "🕯️  #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxBurners::itemsForOrbital(orbital)
    def self.itemsForOrbital(orbital)
        Solingen::mikuTypeItems("NxBurner").select{|item| item["cliqueuuid"] == orbital["uuid"] }
    end

    # NxBurners::itemsWithoutOrbital()
    def self.itemsWithoutOrbital()
        Solingen::mikuTypeItems("NxBurner").select{|item| item["cliqueuuid"].nil? }
    end

    # ------------------------------------
    # Ops
    # ------------------------------------

    # NxBurners::maintenance()
    def self.maintenance()
        Solingen::mikuTypeItems("NxBurner")
            .each{|item|
                if item["cliqueuuid"] and Solingen::getItemOrNull(item["cliqueuuid"]).nil? then
                    Solingen::setAttribute2(uuid, "cliqueuuid", nil)
                end
            }
    end

    # NxBurners::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # NxBurners::program1(item)
    def self.program1(item)
        loop {
            puts item["description"].green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["done"])
            return if action.nil?
            if action == "done" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of burner: #{item["description"].green} ? ", true) then
                    Solingen::destroy(item["uuid"])
                end
            end
        }
    end

    # NxBurners::program2()
    def self.program2()
        loop {
            items = Solingen::mikuTypeItems("NxBurner").sort{|w1, w2| w1["unixtime"] <=> w2["unixtime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("burner", items, lambda{|item| item["description"] })
            return if item.nil?
            NxBurners::program1(item)
        }
    end
end
