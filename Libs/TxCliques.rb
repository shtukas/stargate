
class TxCliques

    # TxCliques::infinityuuid()
    def self.infinityuuid()
        "9297479b-17de-427e-8622-a7e52f90020c"
    end

    # -------------------------
    # IO

    # TxCliques::interactivelyIssueNewClique()
    def self.interactivelyIssueNewClique()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        engine = TxEngines::interactivelyMakeEngineOrDefault()
        uuid = SecureRandom.uuid
        Solingen::init("TxClique", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "engine", engine)
        Solingen::getItemOrNull(uuid)
    end

    # -------------------------
    # Data

    # TxCliques::cliqueToNxTasks(clique)
    def self.cliqueToNxTasks(clique)
        if clique["uuid"] == TxCliques::infinityuuid() then
            return Solingen::mikuTypeItems("NxTask")
                .select{|item| item["cliqueuuid"].nil? }
                .sort_by{|task| task["position"] }
                .reduce([]){|selected, task|
                    if selected.size >= 6 then
                        selected
                    else
                        if Bank::recoveredAverageHoursPerDay(task["uuid"]) < 1 then
                            selected + [task]
                        else
                            selected
                        end
                    end
                }
        end

        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["cliqueuuid"] == clique["uuid"] }
    end

    # TxCliques::cliqueToNewFirstPosition(clique)
    def self.cliqueToNewFirstPosition(clique)
        positions = TxCliques::cliqueToNxTasks(clique).map{|task| task["position"] }
        return 1 if positions.size == 0
        position = positions.sort.first
        if position > 1 then
            position.to_f / 2
        else
            position - 1
        end
    end

    # TxCliques::cliqueSuffix(item)
    def self.cliqueSuffix(item)
        return "" if item["mikuType"] != "NxTask"
        clique = Solingen::getItemOrNull(item["cliqueuuid"])
        return "" if clique.nil?
        return "" if clique["description"].nil?
        " (#{clique["description"]})".green
    end

    # TxCliques::toString(clique)
    def self.toString(clique)
        padding = XCache::getOrDefaultValue("ba9117eb-7a6f-474c-b53e-1c7a80ac0c6c", "0").to_i
        suffix =
            if clique["engine"] then
                " #{TxEngines::toString1(clique["engine"])}".green
            else
                ""
            end
        "🔹 #{clique["description"].ljust(padding)}#{suffix}"
    end

    # TxCliques::management()
    def self.management()
        padding = Solingen::mikuTypeItems("TxClique").map{|clique| clique["description"].size }.max
        XCache::set("ba9117eb-7a6f-474c-b53e-1c7a80ac0c6c", padding)
    end

    # TxCliques::listingRatio(clique)
    def self.listingRatio(clique)
        engine = clique["engine"]
        0.9 * TxEngines::dayCompletionRatio(engine) + 0.1 * TxEngines::periodCompletionRatio(engine)
    end

    # -------------------------
    # Ops

    # TxCliques::interactivelySelectCliqueOrNull()
    def self.interactivelySelectCliqueOrNull()
        cliques = Solingen::mikuTypeItems("TxClique")
                    .select{|clique| clique["uuid"] != TxCliques::infinityuuid() }
                    .sort_by{|clique| clique["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| TxCliques::toString(clique) })
    end

    # TxCliques::interactivelySelectPositionInClique(clique)
    def self.interactivelySelectPositionInClique(clique)
        tasks = TxCliques::cliqueToNxTasks(clique)
        return 1 if tasks.empty?
        tasks
            .sort_by{|task| task["position"] }
            .each{|item| puts NxTasks::toString(item) }
        puts ""
        position = 0
        loop {
            position = LucilleCore::askQuestionAnswerAsString("position: ")
            next if position == ""
            position = position.to_f
            break
        }
        position
    end

    # TxCliques::program2(clique)
    def self.program2(clique)

        if clique["uuid"] == TxCliques::infinityuuid() then
            puts "You cannot run program on Infinity"
            LucilleCore::pressEnterToContinue()
            return
        end

        loop {
            clique = Solingen::getItemOrNull(clique["uuid"])
            return if clique.nil?
            system("clear")
            items = TxCliques::cliqueToNxTasks(clique)
                        .sort_by{|t| t["position"] }
            store = ItemStore.new()

            puts ""
            puts TxCliques::toString(clique)
            puts ""

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::itemToListingLine(store: store, item: item)
                }

            puts ""
            puts "rename clique | stack items on top | put line at position"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            break if input == ""
            break if input == "exit"

            if input == "rename clique" then
                description = CommonUtils::editTextSynchronously(clique["description"])
                next if description == ""
                Solingen::setAttribute2(clique["uuid"], "description", description)
            end
            if input == "stack items on top" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                text.lines.map{|l| l.strip }.reverse.each{|line|
                    position = TxCliques::cliqueToNewFirstPosition(clique)
                    t = NxTasks::lineToCliqueTask(line, clique["uuid"], position)
                    puts JSON.pretty_generate(t)
                }
            end
            if input == "put line at position" then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                t = NxTasks::lineToCliqueTask(line, clique["uuid"], position)
                puts JSON.pretty_generate(t)
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }

        if TxCliques::cliqueToNxTasks(clique).empty? then
            puts "You are leaving an empty Clique"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to destroy it ? ") then
                Solingen::destroy(clique["uuid"])
            end
        end
    end

    # TxCliques::program3()
    def self.program3()
        loop {
            clique = TxCliques::interactivelySelectCliqueOrNull()
            break if clique.nil?
            TxCliques::program2(clique)
        }
    end
end