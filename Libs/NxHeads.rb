# encoding: UTF-8

class NxHeads

    # NxHeads::items()
    def self.items()
        N3Objects::getMikuType("NxHead")
    end

    # NxHeads::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxHeads::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxHeads::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxHeads::interactivelyIssueNewOrNull(useCoreData: true)
    def self.interactivelyIssueNewOrNull(useCoreData: true)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = useCoreData ? CoreData::interactivelyMakeNewReferenceStringOrNull(uuid) : nil
        board = NxBoards::interactivelySelectOneOrNull()
        if board then
            position = NxBoards::interactivelyDecideNewBoardPosition(board)
            item = {
                "uuid"        => uuid,
                "mikuType"    => "NxHead",
                "unixtime"    => Time.new.to_i,
                "datetime"    => Time.new.utc.iso8601,
                "description" => description,
                "field11"     => coredataref,
                "position"    => position,
                "boarduuid"   => board["uuid"],
            }
        else
            position = NxHeads::endPositionNext()
            item = {
                "uuid"        => uuid,
                "mikuType"    => "NxHead",
                "unixtime"    => Time.new.to_i,
                "datetime"    => Time.new.utc.iso8601,
                "description" => description,
                "field11"     => coredataref,
                "position"    => position,
                "boarduuid"   => nil,
            }
        end
        NxHeads::commit(item)
        item
    end

    # NxHeads::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        position = NxHeads::endPositionNext()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Watch '#{title}' on Netflix",
            "field11"     => nil,
            "position"    => position,
            "boarduuid"   => nil,
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{N1Data::putBlob(url)}"
        position = NxHeads::endPositionNext()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => board["uuid"],
        }
        N3Objects::commit(item)
        item
    end

    # NxHeads::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(N1DataElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        position = NxHeads::endPositionNext()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => nil,
        }
        N3Objects::commit(item)
        item
    end

    # NxHeads::priority()
    def self.priority()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxHeads::startPosition() - 1
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => nil,
        }
        NxHeads::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxHeads::bItemsOrdered(boarduuid or nil)
    def self.bItemsOrdered(boarduuid)
        NxHeads::items()
            .select{|item| item["boarduuid"] == boarduuid }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # NxHeads::isBoarded(item)
    def self.isBoarded(item)
        !item["boarduuid"].nil?
    end

    # NxHeads::toString(item)
    def self.toString(item)
        if NxHeads::isBoarded(item) then
            "(head) (pos: #{item["position"].round(3)}) #{item["description"]}"
        else
            rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
            "(head) (#{"%5.2f" % rt}) #{item["description"]}"
        end
    end

    # NxHeads::startPosition()
    def self.startPosition()
        positions = NxHeads::items().map{|item| item["position"] }
        return 1 if positions.empty?
        positions.min
    end

    # NxHeads::endPosition()
    def self.endPosition()
        positions = NxHeads::items().map{|item| item["position"] }
        return 1 if positions.empty?
        positions.max
    end

    # NxHeads::endPositionNext()
    def self.endPositionNext()
        NxHeads::endPosition() + 0.5 + 0.5*rand
    end

    # NxHeads::listingItems(boarduuid or nil)
    def self.listingItems(boarduuid)
        if boarduuid.nil? then
            items = NxHeads::bItemsOrdered(nil)
    
            i1s = items.take(3)
            i2s = items.drop(3).take(3)

            i1s = i1s
                    .map {|item|
                        {
                            "item" => item,
                            "rt"   => BankUtils::recoveredAverageHoursPerDay(item["uuid"])
                        }
                    }
                    .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
                    .map {|packet| packet["item"] }

            return i1s + i2s
        else
            NxHeads::bItemsOrdered(boarduuid)
                .sort{|i1, i2| i1["position"] <=> i2["position"] }
        end
    end

    # NxHeads::listingRunningItems()
    def self.listingRunningItems()
        NxHeads::items().select{|item| NxBalls::itemIsActive(item) }
    end

    # --------------------------------------------------
    # Operations

    # NxHeads::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
