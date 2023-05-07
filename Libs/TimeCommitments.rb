
class TimeCommitments

    # TimeCommitments::listingitems()
    def self.listingitems()
        (NxBoards::listingItems() + NxMonitor1s::listingItems())
            .select{|item| TxEngines::completionRatio(item["engine"]) < 1 }
            .sort_by{|item| TxEngines::completionRatio(item["engine"]) }
    end

    # TimeCommitments::activeItems()
    def self.activeItems()
        [
            Solingen::mikuTypeItems("NxBoard")
                .map{|board| NxTasksBoarded::items(board).select{|item| NxBalls::itemIsActive(item)}}
                .flatten,
            Solingen::mikuTypeItems("NxLong").select{|item| NxBalls::itemIsActive(item) },
            NxTasksBoardless::items()
                .sort_by{|item| item["position"] }
                .first(100)
                .select{|item| NxBalls::itemIsActive(item) }
        ]
            .flatten
    end

    # TimeCommitments::firstItem()
    def self.firstItem()
        active = TimeCommitments::activeItems()
        return active if active.size > 0

        TimeCommitments::listingitems().each{|domain|
            if domain["mikuType"] == "NxBoard" then
                board = domain
                NxBoards::itemsForProgram1(board)
                    .each{|item|
                        next if !DoNotShowUntil::isVisible(item)
                        return [item]
                    }
            end
            if domain["mikuType"] == "NxMonitor1" then
                if domain["uuid"] == "347fe760-3c19-4618-8bf3-9854129b5009" then # Long Running Projects
                    Solingen::mikuTypeItems("NxLong")
                        .select{|item| item["active"] }
                        .sort_by{|item| TxEngines::completionRatio(item["engine"]) }
                        .each{|item|
                            next if !DoNotShowUntil::isVisible(item)
                            return [item]
                        }
                end
                if domain["uuid"] == "bea0e9c7-f609-47e7-beea-70e433e0c82e" then # NxTasks (boardless)
                    NxTasksBoardless::items()
                        .sort_by{|item| item["position"] }
                        .each{|item|
                            next if !DoNotShowUntil::isVisible(item)
                            next if NxTasks::completionRatio(item) >= 1
                            return [item]
                        }
                end
            end
        }
    end
end