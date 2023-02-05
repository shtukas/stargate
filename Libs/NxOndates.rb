
class NxOndates

    # NxOndates::items()
    def self.items()
        ObjectStore2::objects("NxOndates")
    end

    # NxOndates::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => datetime,
            "description" => description,
            "field11"     => coredataref
        }
        puts JSON.pretty_generate(item)
        ObjectStore2::commit("NxOndates", item)
        ItemToTimeCommitmentMapping::interactiveProposalToSetMapping(item)
        item
    end

    # NxOndates::listingItems()
    def self.listingItems()
        NxOndates::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
    end

    # NxOndates::toString(item)
    def self.toString(item)
        "(ondate) #{item["description"]} (coredataref: #{item["field11"]})"
    end

    # NxOndates::report()
    def self.report()
        system("clear")
        puts "ondates:"
        NxOndates::items()
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            .each{|item|
                puts NxOndates::toString(item)
            }
        LucilleCore::pressEnterToContinue()
    end
end