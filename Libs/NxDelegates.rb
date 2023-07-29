
class NxDelegates

    # NxDelegates::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        BladesGI::init("NxDelegate", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # NxDelegates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxDelegates::issue(description)
    end

    # NxDelegates::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        position = nil
        if parent["mikuType"] == "NxThread" then
            position = 0
        end
        if parent["mikuType"] == "TxCore" then
            position = 0
        end
        if position.nil? then
            position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        end
        tx8 = Tx8s::make(parent["uuid"], position)
        delegate = NxDelegates::interactivelyIssueNewOrNull()
        return nil if delegate.nil?

        BladesGI::setAttribute2(delegate["uuid"], "parent", tx8)
    end

    # NxDelegates::toString(item)
    def self.toString(item)
        "🐞 #{item["description"]}"
    end

    # NxDelegates::listingItemsForMainListing()
    def self.listingItemsForMainListing()
        BladesGI::mikuType("NxDelegate")
            .select{|delegate| delegate["parent"].nil? }
    end

    # NxDelegates::listingItemsForThread(thread)
    def self.listingItemsForThread(thread)
        BladesGI::mikuType("NxDelegate")
            .select{|delegate| delegate["parent"] and delegate["parent"]["uuid"] == thread["uuid"] }
    end

    # NxDelegates::maintenance()
    def self.maintenance()
        BladesGI::mikuType("NxDelegate")
            .each{|delegate| 
                next if delegate["parent"].nil?
                if BladesGI::itemOrNull(delegate["parent"]["uuid"]).nil? then
                    BladesGI::setAttribute2(delegate["uuid"], "parent", nil)
                end
            }
    end

    # NxDelegates::program1()
    def self.program1()
        loop {
            delegate = LucilleCore::selectEntityFromListOfEntitiesOrNull("delegate", BladesGI::mikuType("NxDelegate"), lambda{|delegate| NxDelegates::toString(delegate) })
            return if delegate.nil?
            PolyActions::access(delegate)
        }
    end
end