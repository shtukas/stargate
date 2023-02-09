# encoding: UTF-8

class NxBoardItems

    # NxBoardItems::items()
    def self.items()
        ObjectStore2::objects("NxBoardItems")
    end

    # NxBoardItems::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxBoardItems", item)
    end

    # NxBoardItems::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxBoardItems", uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxBoardItems::interactivelyIssueNewOrNull(streamOpt)
    def self.interactivelyIssueNewOrNull(streamOpt)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        stream = streamOpt ? streamOpt : NxStreams::interactivelySelectOne()
        boardposition = NxStreams::interactivelyDecideNewStreamPosition(stream)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBoardItem",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"     => stream["uuid"],
            "boardposition" => boardposition
        }
        NxBoardItems::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxBoardItems::toString(item)
    def self.toString(item)
        "(pos: #{"%8.3f" % item["boardposition"]}) #{item["description"]}"
    end

    # NxBoardItems::toStringForFirstItem(item)
    def self.toStringForFirstItem(item)
        "#{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # NxBoardItems::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end