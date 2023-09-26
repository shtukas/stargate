
class SpaceControl

    def initialize(remaining_vertical_space)
        @remaining_vertical_space = remaining_vertical_space
    end

    def putsline(line) # boolean
        vspace = CommonUtils::verticalSize(line)
        return false if vspace > @remaining_vertical_space
        puts line
        @remaining_vertical_space = @remaining_vertical_space - vspace
        true
    end
end

class Speedometer
    def initialize()
    end

    def start_contest()
        @contest = []
    end

    def contest_entry(description, l)
        t1 = Time.new.to_f
        l.call()
        t2 = Time.new.to_f
        @contest << {
            "description" => description,
            "time"        => t2 - t1
        }
    end

    def end_contest()
        @contest
            .sort_by{|entry| entry["time"] }
            .reverse
            .each{|entry| puts "#{"%6.2f" % entry["time"]}: #{entry["description"]}" }
    end

    def start_unit(description)
        @description = description
        @t = Time.new.to_f
    end

    def end_unit()
        puts "#{"%6.2f" % (Time.new.to_f - @t)}: #{@description}"
    end

end

class Listing

    # -----------------------------------------
    # Data

    # Listing::listable(item)
    def self.listable(item)
        return true if NxBalls::itemIsActive(item)
        return false if !DoNotShowUntil::isVisible(item)
        true
    end

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return true if NxBalls::itemIsRunning(item)

        return false if TmpSkip1::isSkipped(item)

        return false if item["mikuType"] == "DesktopTx1"

        return false if item["mikuType"] == "NxBurner"

        return false if item["mikuType"] == "NxPool"

        return false if !DoNotShowUntil::isVisible(item)

        return false if TmpSkip1::isSkipped(item)

        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # Listing::lowWaves()
    def self.lowWaves()
        Waves::listingItems().select{|item| !item["interruption"] }
            .map{|item|
                InMemoryCache::set("d3fded3d-190a-468f-8203-5bedcbf53454:#{item["uuid"]}", "low:waves:51c83743-417e-4cb8")
                item
            }
    end

    # Listing::noEngineItems()
    def self.noEngineItems()
        Todos::noEngineItems()
            .map{|item|
                InMemoryCache::set("d3fded3d-190a-468f-8203-5bedcbf53454:#{item["uuid"]}", "low:todo:9abd3235-2cfa")
                item
            }
    end

    # Listing::cto()
    def self.cto()
        core = Catalyst::itemOrNull("a72e3c37-5456-416c-ab04-7ce0c1971938")
        ratio = Bank::recoveredAverageHoursPerDay(core["uuid"]).to_f/(core["hours"].to_f/6)
        ratio < 1 ? [core] : []
    end

    # Listing::items()
    def self.items()
        lowPriorityWaves = (lambda {
            if Bank::recoveredAverageHoursPerDayCached("low:waves:51c83743-417e-4cb8") < 1 then
                Listing::lowWaves()
            else
                []
            end
        }).call()
        noEngineItems = (lambda {
            if Bank::recoveredAverageHoursPerDayCached("low:todo:9abd3235-2cfa") < 1 then
                Listing::noEngineItems()
            else
                []
            end
        }).call()
        [
            Anniversaries::listingItems(),
            Listing::cto(),
            lowPriorityWaves,
            noEngineItems,
            DropBox::items(),
            PhysicalTargets::listingItems(),
            Catalyst::mikuType("NxLine"),
            Waves::listingItems().select{|item| item["interruption"] },
            NxOndates::listingItems(),
            Backups::listingItems(),
            NxBurners::listingItems(),
            Todos::bufferInItems(),
            Todos::onDateItems(),
            Todos::trajectoryItems(0.5),
            TxCores::listingItems(),
            Listing::lowWaves(),
            Todos::timeCommitmentItems(),
            NxCruises::listingItems(),
            Todos::trajectoryItems(0.4),
            Todos::noEngineItems()
        ]
            .flatten
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{PolyFunctions::lineageSuffix(item).yellow}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # Listing::toString3(thread, store, item)
    def self.toString3(thread, store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{PolyFunctions::lineageSuffix(item).yellow}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # -----------------------------------------
    # Ops

    # Listing::speedTest()
    def self.speedTest()

        spot = Speedometer.new()

        spot.start_contest()
        spot.contest_entry("Anniversaries::listingItems()", lambda { Anniversaries::listingItems() })
        spot.contest_entry("DropBox::items()", lambda { DropBox::items() })
        spot.contest_entry("Catalyst::mikuType(NxLine)", lambda { Catalyst::mikuType("NxLine") })
        spot.contest_entry("NxBalls::runningItems()", lambda{ NxBalls::runningItems() })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxBurners::listingItems()", lambda{ NxBurners::listingItems() })
        spot.contest_entry("Todos::bufferInItems()", lambda{ Todos::bufferInItems() })
        spot.contest_entry("TxCores::listingItems()", lambda{ TxCores::listingItems() })
        spot.contest_entry("Todos::noEngineItems()", lambda{ Todos::noEngineItems() })
        spot.contest_entry("PhysicalTargets::listingItems()", lambda{ PhysicalTargets::listingItems() })
        spot.contest_entry("Waves::listingItems()", lambda{ Waves::listingItems() })

        spot.end_contest()

        puts ""

        spot.start_unit("Listing::maintenance()")
        Listing::maintenance()
        spot.end_unit()

        cores = Catalyst::mikuType("TxCore")
        spot.start_unit("Listing::items()")
        items = Listing::items()
        spot.end_unit()

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
        store = ItemStore.new()

        LucilleCore::pressEnterToContinue()
    end

    # Listing::maintenance()
    def self.maintenance()
        if Config::isPrimaryInstance() then
            puts "> Listing::maintenance() on primary instance"
            NxTasks::maintenance()
            Catalyst::maintenance()
            NxThreads::maintenance()
            TxCores::maintenance2()
            EventTimelineMaintenance::shortenToLowerPing()
            EventTimelineMaintenance::rewriteHistory()
            EventTimelineMaintenance::maintenance()
        end
        TxCores::maintenance3()
    end

    # Listing::launchNxBallMonitor()
    def self.launchNxBallMonitor()
        Thread.new {
            loop {
                sleep 60
                NxBalls::all()
                    .select{|ball| ball["type"] == "running" }
                    .select{|ball| (Time.new.to_f - ball["startunixtime"]) > 3600 }
                    .take(1)
                    .each{ CommonUtils::onScreenNotification("catalyst", "NxBall running for more than one hour") }
            }
        }
    end

    # Listing::checkForCodeUpdates()
    def self.checkForCodeUpdates()
        if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
            puts "Attempting to download new code"
            system("#{File.dirname(__FILE__)}/../pull-from-origin")
        end
    end

    # Listing::main()
    def self.main()

        initialCodeTrace = CommonUtils::catalystTraceCode()

        latestCodeTrace = initialCodeTrace

        Thread.new {
            loop {
                Listing::checkForCodeUpdates()
                sleep 300
            }
        }

        Thread.new {
            loop {
                # Event Timeline
                EventTimelineReader::issueNewFSComputedTraceForCaching()
                EventTimelineMaintenance::publishPing()
                sleep 300
            }
        }

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Listing::maintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            spacecontrol.putsline ""

            desktopItems = Desktop::listingItems()
            if desktopItems.size > 0 then
                desktopItems
                    .each{|item|
                        store.register(item, false)
                        status = spacecontrol.putsline Listing::toString2(store, item)
                        break if !status
                    }
                spacecontrol.putsline ""
            end

            items = NxBalls::runningItems() + Listing::items()
            items = items
                        .reduce([]){|selected, item|
                            if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                                selected
                            else
                                selected + [item]
                            end
                        }
            items = Prefix::prefix(items)

            # This last step is to remove duplicates due to running items
            items = items.reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }

            items
                .each{|item|
                    if item["mikuType"] == "TxEmpty" then
                        spacecontrol.putsline ""
                        next
                    end
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item)
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"

            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
