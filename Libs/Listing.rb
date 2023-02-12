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
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | landing (<n>) | expose (<n>) | >> skip default | lock (<n>) | add time (<n>) | board (<n>) | destroy",
            "[makers] anniversary | manual countdown | wave | today | ondate | drop | top | desktop",
            "[divings] anniversaries | ondates | waves | todos | desktop | open",
            "[NxBalls] start | start * | stop | stop * | pause | pursue",
            "[NxOndate] redate",
            "[NxBoard] holiday",
            "[misc] search | speed | commands | nyx",
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

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Skips::skip(item["uuid"], Time.new.to_f + 3600*1.5)
            return
        end

        if Interpreting::match("add time", input) then
            item = store.getDefault()
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyFunctions::itemsToBankingAccounts(item).each{|account|
                puts "Adding #{timeInHours*3600} seconds to item: #{account["description"]}"
                BankCore::put(account["number"], timeInHours*3600)
            }
        end

        if Interpreting::match("add time *", input) then
            _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyFunctions::itemsToBankingAccounts(item).each{|account|
                puts "Adding #{timeInHours*3600} seconds to item: #{account["description"]}"
                BankCore::put(account["number"], timeInHours*3600)
            }
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

        if Interpreting::match("board", input) then
            item = store.getDefault()
            return if item.nil?
            NxBoards::interactivelyOffersToAttachBoard(item)
            return
        end

        if Interpreting::match("board *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBoards::interactivelyOffersToAttachBoard(item)
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
            puts "edit description:"
            item["description"] = CommonUtils::editTextSynchronously(item["description"])
            raise "not implemented"
            return
        end

        if Interpreting::match("description *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "edit description:"
            item["description"] = CommonUtils::editTextSynchronously(item["description"])
            raise "not implemented"
            return
        end

        if Interpreting::match("desktop", input) then
            system("open '#{Desktop::desktopFolderPath()}'")
            return
        end

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            raise "not implemented"
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
                
            end
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            raise "not implemented"
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
                
            end
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
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("drop", input) then
            options = ["NxBoard", "NxList"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "NxBoard" then
                NxBoardItems::interactivelyIssueNewOrNull()
            end
            if option == "NxList" then
                NxHeads::interactivelyIssueNewOrNull()
            end
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

        if Interpreting::match("holiday", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxBoard" then
                puts "holiday only apply to NxBoards"
                LucilleCore::pressEnterToContinue()
                return
            end
            timespanInHours = item["hours"].to_f/5
            puts "Adding #{timespanInHours*3600} seconds to #{item["description"]}"
            BankCore::put(item["uuid"], timespanInHours*3600)
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

        if Interpreting::match("lock", input) then
            item = store.getDefault()
            return if item.nil?
            domain = LucilleCore::askQuestionAnswerAsString("domain: ")
            Locks::lock(item["uuid"], domain)
            return
        end

        if Interpreting::match("manual countdown", input) then
            TxManualCountDowns::issueNewOrNull()
            return
        end

        if Interpreting::match("nyx", input) then
            Nyx::main()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::report()
            return
        end

        if Interpreting::match("open", input) then
            item = NxOpens::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
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
            SearchCatalyst::run()
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
            return
        end

        if Interpreting::match("top", input) then
            item = NxTops::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "wave" then
            Waves::issueNewWaveInteractivelyOrNull()
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
                "name" => "Waves::topItems()",
                "lambda" => lambda { Waves::topItems() }
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
                "name" => "Waves::listingItems(ns:today-or-tomorrow)",
                "lambda" => lambda { Waves::listingItems("ns:today-or-tomorrow") }
            },
            {
                "name" => "Waves::leisureItemsWithCircuitBreaker()",
                "lambda" => lambda { Waves::leisureItemsWithCircuitBreaker() }
            },
            {
                "name" => "NxHeads::listingItems()",
                "lambda" => lambda { NxHeads::listingItems() }
            },
            {
                "name" => "Waves::listingItems(ns:leisure)",
                "lambda" => lambda { Waves::listingItems("ns:leisure") }
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
            }
        ]
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        puts ""

        (results1 + results2)
            .each{|result|
                printTestResults.call(result, padding)
            }

        LucilleCore::pressEnterToContinue()
    end

    # Listing::items()
    def self.items()
        [
            Anniversaries::listingItems(),
            NxOndates::listingItems(),
            Waves::topItems(),
            TxManualCountDowns::listingItems(),
            NxBoards::listingItems(),
            Waves::listingItems("ns:today-or-tomorrow"),
            Waves::leisureItemsWithCircuitBreaker(),
            NxHeads::listingItems(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Listing::printDesktop(spacecontrol)
    def self.printDesktop(spacecontrol)
        dskt = Desktop::contentsOrNull()
        if dskt and dskt.size > 0 then
            dskt = dskt.lines.map{|line| "      #{line}" }.join()
            spacecontrol.putsline "(-->) Desktop:".green
            spacecontrol.putsline dskts
        end
    end

    # Listing::itemToListingLine(store or nil, item)
    def self.itemToListingLine(store, item)
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxBoards::toStringSuffix(item)}"
        if Locks::isLocked(item["uuid"]) then
            line = "#{line} [lock: #{Locks::locknameOrNull(item["uuid"])}]".yellow
        end
        if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
            line = line.green
        end
        line
    end

    # Listing::printListing(store)
    def self.printListing(store)
        system("clear")

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 3)

        items = Listing::items()

        lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

        spacecontrol.putsline ""
        NxOpens::itemsForBoard(nil).each{|o|
            store.register(o, false)
            spacecontrol.putsline "(#{store.prefixString()}) (open) #{o["description"]}".yellow
        }

        NxTops::itemsInOrder()
            .each{|item|
                bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
                next if !bx.nil?
                store.register(item, true)
                spacecontrol.putsline Listing::itemToListingLine(store, item)
            }

        Listing::printDesktop(spacecontrol)

        runningItems, items = items.partition{|item| NxBalls::itemIsRunning(item) }

        (runningItems + items.take(12))
            .each{|item|

                if item["mikuType"] == "NxBoard" then
                    NxBoards::listingDisplay(store, spacecontrol, item["uuid"])
                    next
                end

                store.register(item, !Skips::isSkipped(item["uuid"]))
                spacecontrol.putsline Listing::itemToListingLine(store, item)
            }

        if lockedItems.size > 0 then
            spacecontrol.putsline ""
            spacecontrol.putsline "locked:"
            lockedItems
                .each{|item|
                    store.register(item, false)
                    spacecontrol.putsline Listing::itemToListingLine(store, item)
                }
        end

        spacecontrol.putsline ""
        spacecontrol.putsline "boards:"
        NxBoards::bottomItems().each{|item|
            NxBoards::bottomDisplay(store, spacecontrol, item["uuid"])
        }

        spacecontrol.putsline ""
        spacecontrol.putsline The99Percent::line() + " (mid point: #{NxList::midposition()})"
        spacecontrol.putsline "> anniversary | manual countdown | wave | today | ondate | drop | top | desktop".yellow

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
                if Config::thisInstanceId() == "Lucille20-pascal" then 
                    system("#{File.dirname(__FILE__)}/bin/vienna-import")
                end
            end

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTails-FrontElements-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTails::bufferInImport(location)
                    puts "Picked up from NxTails-FrontElements-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            NxBoards::timeManagement()
            NxList::dataManagement()

            store = ItemStore.new()

            Listing::printListing(store)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
