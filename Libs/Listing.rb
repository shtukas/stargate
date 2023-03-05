# encoding: UTF-8

class SpaceControl

    def initialize(remaining_vertical_space)
        @remaining_vertical_space = remaining_vertical_space
    end

    def putsline(line)
        vspace = CommonUtils::verticalSize(line)
        return if vspace > @remaining_vertical_space
        puts line
        @remaining_vertical_space = @remaining_vertical_space - vspace
    end
end

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | landing (<n>) | expose (<n>) | park (<n>) | add time <n> | board (<n>) | note (<n>) | destroy <n>",
            "[makers] anniversary | manual countdown | wave | today | ondate | today | desktop | priority | orbital | tail | cherry pick <n> | cherry line | drop",
            "[divings] anniversaries | ondates | waves | todos | desktop",
            "[NxBalls] start | start * | stop | stop * | pause | pursue",
            "[NxOndate] redate",
            "[NxBoard] holiday <n>",
            "[misc] search | speed | commands",
        ].join("\n")
    end

    # Listing::listingCommandInterpreter(input, store, board or nil)
    def self.listingCommandInterpreter(input, store, board)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match("add time *", input) then
            _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyActions::addTimeToItem(item, timeInHours*3600)
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("anniversary", input) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::dive()
            return
        end

        if Interpreting::match("cherry line", input) then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            nxline = NxLines::issue(line)
            cherrypick = NxCherryPicks::interactivelyIssueNullOrNull(nxline)
            puts JSON.pretty_generate(cherrypick)
            return
        end

        if Interpreting::match("cherry pick *", input) then
            _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            cherrypick = NxCherryPicks::interactivelyIssueNullOrNull(item)
            puts JSON.pretty_generate(cherrypick)
            return
        end

        if Interpreting::match("board", input) then
            item = store.getDefault()
            return if item.nil?
            BoardsAndItems::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("board *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            BoardsAndItems::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("commands", input) then
            puts Listing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("description", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("description *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("desktop", input) then
            system("open '#{Desktop::filepath()}'")
            return
        end

        if Interpreting::match("done", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            if item["parked"] then
                item["parked"] = false
                N3Objects::commit(item)
            end
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("drop", input) then
            PolyActions::dropmaking()
        end

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("tail", input) then
            NxTails::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("holiday *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] != "NxBoard" then
                puts "holiday only apply to NxBoards"
                LucilleCore::pressEnterToContinue()
                return
            end
            unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + 3600*3 # 3 am
            if LucilleCore::askQuestionAnswerAsBoolean("> confirm today holiday for '#{PolyFunctions::toString(item).green}': ") then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
            return
        end

        if Interpreting::match("landing", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::landing(item)
            return
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::landing(item)
            return
        end

        if Interpreting::match("manual countdown", input) then
            TxManualCountDowns::issueNewOrNull()
            return
        end

        if Interpreting::match("netflix", input) then
            title = LucilleCore::askQuestionAnswerAsString("title: ")
            NxTails::netflix(title)
        end

        if Interpreting::match("note", input) then
            item = store.getDefault()
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("note *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::report()
            return
        end

        if Interpreting::match("orbital", input) then
            item = NxOrbitals::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("park", input) then
            item = store.getDefault()
            return if item.nil?
            item["parked"] = true
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("park *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            item["parked"] = true
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("priority", input) then
            item = NxTails::priority()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "redate is reserved for NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxOndates::redate(item)
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("stop", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("search", input) then
            CatalystSearch::run()
            return
        end

        if Interpreting::match("speed", input) then
            Listing::speedTest()
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("today", input) then
            item = NxTodays::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::interactivelyOffersToAttach(item)
            return
        end

        if input == "waves" then
            Waves::dive()
            return
        end

        if Interpreting::match("speed", input) then
            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # Listing::speedTest()
    def self.speedTest()

        tests = [
            {
                "name" => "Anniversaries::listingItems()",
                "lambda" => lambda { Anniversaries::listingItems() }
            },
            {
                "name" => "NxOndates::listingItems()",
                "lambda" => lambda { NxOndates::listingItems() }
            },
            {
                "name" => "TxManualCountDowns::listingItems()",
                "lambda" => lambda { TxManualCountDowns::listingItems() }
            },
            {
                "name" => "NxBoards::listingItems()",
                "lambda" => lambda { NxBoards::listingItems() }
            },
            {
                "name" => "Waves::listingItemsPriority(nil)",
                "lambda" => lambda { Waves::listingItemsPriority(nil) }
            },
            {
                "name" => "Waves::listingItemsLeisure(nil)",
                "lambda" => lambda { Waves::listingItemsLeisure(nil) }
            },
            {
                "name" => "NxTails::listingItems(nil)",
                "lambda" => lambda { NxTails::listingItems(nil) }
            },
            {
                "name" => "The99Percent::getReference()",
                "lambda" => lambda { The99Percent::getReference() }
            },
            {
                "name" => "The99Percent::getCurrentCount()",
                "lambda" => lambda { The99Percent::getCurrentCount() }
            },
            {
                "name" => "NxBoards::boardsOrdered()",
                "lambda" => lambda { NxBoards::boardsOrdered() }
            },
        ]

        runTest = lambda {|test|
            t1 = Time.new.to_f
            (1..3).each{ test["lambda"].call() }
            t2 = Time.new.to_f
            {
                "name" => test["name"],
                "runtime" => (t2 - t1).to_f/3
            }
        }

        printTestResults = lambda{|result, padding|
            puts "- #{result["name"].ljust(padding)} : #{"%6.3f" % result["runtime"]}"
        }

        padding = tests.map{|test| test["name"].size }.max

        # dry run to initialise things

        tests
            .each{|test|
                test["lambda"].call()
            }

        # tests

        results1 = tests
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        results2 = [
            {
                "name" => "Listing::printListing()",
                "lambda" => lambda { Listing::printListing(ItemStore.new()) }
            },
            {
                "name" => "The99Percent::line()",
                "lambda" => lambda { The99Percent::line() }
            },
            {
                "name" => "Listing::items(nil)",
                "lambda" => lambda { Listing::items(nil) }
            },

        ]
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        puts ""

        results1
            .each{|result|
                printTestResults.call(result, padding)
            }

        puts ""

        results2
            .each{|result|
                printTestResults.call(result, padding)
            }

        LucilleCore::pressEnterToContinue()
    end

    # Listing::scheduler1data(board)
    def self.scheduler1data(board)
        [
            {
                "name"      => "low priority Wave",
                "account"   => "d36d653e-80e0-4141-b9ff-f26197bbce2b",
                "generator" => lambda{ Waves::listingItemsLeisure(board) } 
            },
            {
                "name"      => "boardless NxTail",
                "account"   => "cfad053c-bb83-4728-a3c5-4fb357845fd9",
                "generator" => lambda{ NxTails::listingItems(board) } 
            }
        ]
        .map{|packet|
            packet["rt"] = BankUtils::recoveredAverageHoursPerDay(packet["account"])
            packet
        }
        .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
    end

    # Listing::scheduler1line()
    def self.scheduler1line()
        a1 = Listing::scheduler1data(nil).map{|packet| "(#{packet["name"]}: #{packet["rt"].round(2)})" }
        "(scheduler1) #{a1.join(" ")}"
    end

    # Listing::sheduler1ListingItem()
    def self.sheduler1ListingItem()
        {
            "uuid"     => "bdaa4f5b-2a67-42c3-98fc-57d8c7a531bf",
            "mikuType" => "Scheduler1Listing",
            "announce" => Listing::scheduler1line()
        }
    end

    # Listing::scheduler1runningItems()
    def self.scheduler1runningItems()
        Waves::items().select{|item| !item["priority"] }.select{|item| NxBalls::itemIsActive(item["uuid"]) } + NxTails::items().select{|item| NxBalls::itemIsActive(item["uuid"]) }
    end

    # Listing::sheduler1Items(board)
    def self.sheduler1Items(board)
        items = Listing::scheduler1runningItems() + Listing::scheduler1data(board).map{|packet| packet["generator"].call() }.flatten
        items.reduce([]){|selected, item|
            if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                selected
            else
                selected + [item]
            end
        }
    end

    # Listing::items(board)
    def self.items(board)
        [
            Anniversaries::listingItems(),
            NxCherryPicks::listingItems(),
            NxLines::items(), # those will only show up if there are lines that are orphan from garbage collected cherry picking
            [Desktop::listingItem()],
            Waves::listingItemsPriority(board),
            NxOrbitals::listingItems(board),
            NxTodays::listingItems(),
            NxOndates::listingItems(),
            TxManualCountDowns::listingItems(),
            NxBoards::listingItems(),
            [Listing::sheduler1ListingItem()],
            Listing::sheduler1Items(board),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBalls::itemIsActive(item["uuid"]) }
            .reduce([]){|selected, item|
                if selected.map{|i| [i["uuid"], i["targetuuid"]].compact }.flatten.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # Listing::itemToListingLine(store or nil, item)
    def self.itemToListingLine(store, item)
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}"
        if item["parked"] then
            line = "#{line} (parked)".yellow
        end
        if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
            line = line.green
        end
        line
    end

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return false if item["parked"]
        return false if item["mikuType"] == "NxOrbital"
        return false if item["mikuType"] == "Scheduler1Listing"
        true
    end

    # Listing::printListing(store)
    def self.printListing(store)
        system("clear")

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 3 - 3)

        spacecontrol.putsline ""

        Listing::items(nil)
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                spacecontrol.putsline Listing::itemToListingLine(store, item)
            }

        puts The99Percent::line()
        NxBoards::boardsOrdered().each{|item|
            NxBoards::informationDisplay(store, item["uuid"])
        }
    end

    # Listing::mainProgram2Pure()
    def self.mainProgram2Pure()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        loop {

            if CommonUtils::stargateTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("8fba6ab0-ce92-46af-9e6b-ce86371d643d", 3600*12) then
                if Config::isPrimaryInstance() then 
                    system("#{File.dirname(__FILE__)}/../vienna-import")
                end
            end

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTails-FrontElements-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTails::bufferInImport(location)
                    puts "Picked up from NxTails-FrontElements-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            if !Config::isPrimaryInstance() then
                NxBoards::timeManagement()
                NxTimeCapsules::operate()
                NxOpenCycles::dataManagement()
                NxCherryPicks::dataManagement()
            end

            store = ItemStore.new()

            Listing::printListing(store)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
