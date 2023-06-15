
class NxDeadlines

    # NxDeadlines::makeDeadlineCore()
    def self.makeDeadlineCore()
        duration = LucilleCore::askQuestionAnswerAsString("duration in days: ").to_f
        requirementInHours = LucilleCore::askQuestionAnswerAsString("requirement in hours: ").to_f
        {
            "uuid"               => SecureRandom.uuid,
            "start"              => Time.new.to_f,
            "end"                => Time.new.to_f + duration*86400,
            "requirementInHours" => requirementInHours
        }
    end

    # NxDeadlines::interactivelyIssueNewForItem(item)
    def self.interactivelyIssueNewForItem(item)
        uuid = SecureRandom.uuid
        deadlineCore = NxDeadlines::makeDeadlineCore()
        DarkEnergy::init("NxDeadline", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "targetuuid", item["uuid"])
        DarkEnergy::patch(uuid, "deadlineCore", deadlineCore)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxDeadlines::coreIsLate(core)
    def self.coreIsLate(core)
        timeDone = Bank::getValue(core["uuid"])
        timeNeeded = 86400*core["requirementInHours"]*(Time.new.to_f - core["start"]).to_f/(core["end"] - core["start"])
        timeNeeded > timeDone
    end

    # NxDeadlines::deadlineIsLate(item)
    def self.deadlineIsLate(item)
        NxDeadlines::coreIsLate(item["deadlineCore"])
    end

    # NxDeadlines::coreToString(core)
    def self.coreToString(core)
        timeDone = Bank::getValue(core["uuid"])
        timeNeeded = 86400*core["requirementInHours"]*(Time.new.to_f - core["start"]).to_f/(core["end"] - core["start"])
        isLate = timeNeeded > timeDone
        "(done: #{(timeDone.to_f/86400).round(2)} hours, required: #{core["requirementInHours"]} hours, #{isLate ? "😓" : "😎"})"
    end

    # NxDeadlines::toString(item)
    def self.toString(item)
        target = DarkEnergy::itemOrNull(item["targetuuid"])
        if target then
            "⏱️ link: #{PolyFunctions::toString(target)} #{NxDeadlines::coreToString(core)}"
        else
            "⏱️ link: not found 🤔"
        end
    end

    # NxDeadlines::access(item)
    def self.access(item)
        target = DarkEnergy::itemOrNull(item["targetuuid"])
        PolyActions::access(target)
    end

    # NxDeadlines::done(item)
    def self.done(item)
        o1 = "destroy the NxDeadline only"
        o2 = "destroy the deadline and done the target"
        puts "Would you like to #{o1} or #{o2} ?"
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", [o1, o2])
        return if option.nil? 
        if option == o1 then
            if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of '#{NxDeadlines::toString(item)}': ") then
                DarkEnergy::destroy(item["uuid"])
            end
        end
        if option == o2 then
            if LucilleCore::askQuestionAnswerAsBoolean("Confirm ? ") then
                target = DarkEnergy::itemOrNull(item["targetuuid"])
                if target then
                    PolyActions::done(target)
                    DarkEnergy::destroy(item["uuid"])
                end
            end
        end
    end

    # NxDeadlines::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxDeadline")
            .select{|item| NxDeadlines::deadlineIsLate(item) }
    end

    # NxDeadlines::program1(item)
    def self.program1(item)
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["start", "done"])
            return if option.nil?
            if option == "start" then
                PolyActions::start(item)
            end
            if option == "done" then
                PolyActions::done(item)
            end
        }
    end

    # NxDeadlines::program0()
    def self.program0()
        loop {
            items = DarkEnergy::mikuType("NxDeadline")
            if items.empty? then
                puts "no deadline found"
                LucilleCore::pressEnterToContinue()
                return
            end
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("deadline", items, lambda{|item| NxDeadlines::toString(item) })
            return if item.nil?
            NxDeadlines::program1(item)
        }
    end

    # NxDeadlines::attachDeadlineAttempt(item)
    def self.attachDeadlineAttempt(item)
        NxDeadlines::interactivelyIssueNewForItem(item)
    end

    # NxDeadlines::askAndThenAttachDeadlineToItemAttempt(item)
    def self.askAndThenAttachDeadlineToItemAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("> add deadline ? ", false) then
            NxDeadlines::attachDeadlineAttempt(item)
        end
    end

    # NxDeadlines::suffix(item)
    def self.suffix(item)
        return "" if item["deadline"].nil?
        deadline = DarkEnergy::itemOrNull(item["deadline"])
        return "" if deadline.nil?
        " #{NxDeadlines::toString(deadline)}"
    end
end