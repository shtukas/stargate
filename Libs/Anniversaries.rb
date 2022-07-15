
class Anniversaries

    # Anniversaries::dateIsCorrect(date)
    def self.dateIsCorrect(date)
        begin
            Date.parse(date)
            true
        rescue
            false
        end
    end

    # Anniversaries::datePlusNMonthAnniversaryStyle(date: String, shiftInMonths: Integer)
    def self.datePlusNMonthAnniversaryStyle(date, shiftInMonths)
        dateElements = [date[0, 4].to_i, date[5, 2].to_i+shiftInMonths, date[8, 2].to_i]

        while dateElements[1] > 12 do
            dateElements[0] = dateElements[0]+1
            dateElements[1] = dateElements[1] - 12
        end

        date = "#{dateElements[0]}-#{dateElements[1].to_s.rjust(2, "0")}-#{dateElements[2].to_s.rjust(2, "0")}"

        while !Anniversaries::dateIsCorrect(date) do
            date = "#{date[0, 4]}-#{date[5, 2]}-#{(date[8, 2].to_i-1).to_s.rjust(2, "0")}"
        end
        date
    end

    # Anniversaries::computeNextCelebrationDateOrdinal(startdate: String, repeatType: String, lastCelebrationDate: String) # [ date: String, ordinal: Int ]
    def self.computeNextCelebrationDateOrdinal(startdate, repeatType, lastCelebrationDate)
        cursordate = Date.parse(startdate)
        cursorOrdinal = 0
        if repeatType == "weekly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursordate = cursordate + 7
                cursorOrdinal = cursorOrdinal + 1
            }
        end
        if repeatType == "monthly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursorOrdinal = cursorOrdinal + 1
                cursordate = Date.parse(Anniversaries::datePlusNMonthAnniversaryStyle(startdate, cursorOrdinal))
            }
        end
        if repeatType == "yearly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursorOrdinal = cursorOrdinal + 1
                cursordate = "#{startdate[0, 4].to_i+cursorOrdinal}-#{startdate[5, 2]}-#{startdate[8, 2]}"
                while !Anniversaries::dateIsCorrect(cursordate) do
                    cursordate = "#{cursordate[0, 4]}-#{cursordate[5, 2]}-#{(cursordate[8, 2].to_i-1).to_s.rjust(2, "0")}"
                end
            }
        end
    end

    # Anniversaries::accessTests()
    def self.runTests()
        raise "72118532-21b3-4897-a6d1-7c21458b4624" if Anniversaries::datePlusNMonthAnniversaryStyle("2020-11-25", 1) != "2020-12-25"
        raise "279b1ee3-728e-4883-9a4d-abf3b9a494d7" if Anniversaries::datePlusNMonthAnniversaryStyle("2020-12-25", 1) != "2021-01-25"
        raise "5507b102-2651-4b57-ba7b-7e6c217bddba" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-01", 1) != "2021-02-01"
        raise "38e0536a-7943-4649-a002-6f65e9d88c0a" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 1) != "2021-02-28"
        raise "cd8feeec-54bd-4a63-be2c-e279c77390ba" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 2) != "2021-03-31"
        raise "d82394e7-708d-49a8-9d65-792a77093ce5" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 3) != "2021-04-30"
        raise "8bb58535-b435-4bbe-9ded-76cf5d1ce6ad" if Anniversaries::datePlusNMonthAnniversaryStyle("2024-01-31", 1) != "2024-02-29"
        raise "53ac9950-7df9-481d-a3cf-2ec07f566f89" if Anniversaries::datePlusNMonthAnniversaryStyle("2024-01-31", 2) != "2024-03-31"

        raise "ff1f70da-1342-4a20-91cb-f5a86f66a44c" if Anniversaries::computeNextCelebrationDateOrdinal("2021-02-28", "yearly", "2022-01-01").join(", ") != "2022-02-28, 1"
        raise "ff1f70da-1342-4a20-91cb-f5a86f66a44c" if Anniversaries::computeNextCelebrationDateOrdinal("2024-02-29", "yearly", "2025-01-01").join(", ") != "2025-02-28, 1"
    end

    # ----------------------------------------------------------------------------------

    # Anniversaries::anniversaries()
    def self.anniversaries()
        Librarian::getObjectsByMikuType("NxAnniversary")
    end

    # Anniversaries::issueNewAnniversaryOrNullInteractively()
    def self.issueNewAnniversaryOrNullInteractively()

        unixtime = Time.new.to_i

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            return nil
        end

        startdate = LucilleCore::askQuestionAnswerAsString("startdate (empty to abort): ")
        if startdate == "" then
            return nil
        end

        repeatType = LucilleCore::selectEntityFromListOfEntitiesOrNull("repeat type", ["weekly", "monthly", "yearly"])
        if repeatType.nil? then
            return nil
        end

        lastCelebrationDate = LucilleCore::askQuestionAnswerAsString("lastCelebrationDate (default to today): ")
        if lastCelebrationDate == "" then
            lastCelebrationDate = CommonUtils::today()
        end

        item = {
          "uuid"         => SecureRandom.uuid,
          "variant"      => SecureRandom.uuid,
          "mikuType"     => "NxAnniversary",
          "unixtime"     => Time.new.to_i,
          "description"  => description,
          "startdate"    => startdate,
          "repeatType"   => repeatType,
          "lastCelebrationDate" => lastCelebrationDate,
        }
        Librarian::commit(item)
        item
    end

    # Anniversaries::nextDateOrdinal(anniversary) # [ date: String, ordinal: Int ]
    def self.nextDateOrdinal(anniversary)
        Anniversaries::computeNextCelebrationDateOrdinal(anniversary["startdate"], anniversary["repeatType"], anniversary["lastCelebrationDate"] || "2001-01-01")
    end

    # Anniversaries::toString(anniversary)
    def self.toString(anniversary)
        date, n = Anniversaries::nextDateOrdinal(anniversary)
        "(anniversary) [#{anniversary["startdate"]}, #{date}, #{n.to_s.ljust(4)}, #{anniversary["repeatType"].ljust(7)}] #{anniversary["description"]}"
    end

    # Anniversaries::done(anniversary)
    def self.done(anniversary)
        anniversary["lastCelebrationDate"] = Time.new.to_s[0, 10]
        Librarian::commit(anniversary)
    end

    # Anniversaries::access(anniversary)
    def self.access(anniversary)
        puts Anniversaries::toString(anniversary).green
        if LucilleCore::askQuestionAnswerAsBoolean("done ? : ") then
            Anniversaries::done(anniversary)
        end
    end

    # Anniversaries::section2()
    def self.section2()
        Anniversaries::anniversaries()
            .select{|anniversary| Anniversaries::nextDateOrdinal(anniversary)[0] <= CommonUtils::today() }
    end

    # Anniversaries::dailyBriefing()
    def self.dailyBriefing()
        puts "Anniversaries daily briefing:"
        Anniversaries::anniversaries()
            .sort{|i1, i2| Anniversaries::nextDateOrdinal(i1)[0] <=> Anniversaries::nextDateOrdinal(i2)[0] }
            .each{|anniversary|
                puts Anniversaries::toString(anniversary)
            }
        LucilleCore::pressEnterToContinue()
    end

    # Anniversaries::landing(item)
    def self.landing(item)
        loop {

            puts Anniversaries::toString(item).green

            puts "description | update start date | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""

            if Interpreting::match("description", command) then
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                return if description == ""
                item["description"] = description
                Librarian::commit(item)
            end

            if Interpreting::match("update start date", command) then
                startdate = CommonUtils::editTextSynchronously(item["startdate"])
                return if startdate == ""
                item["startdate"] = startdate
                Librarian::commit(item)
            end

            if Interpreting::match("destroy", command) then
                Librarian::destroyClique(item["uuid"])
                break
            end
        }
    end

    # Anniversaries::anniversariesDive()
    def self.anniversariesDive()
        loop {
            anniversaries = Anniversaries::anniversaries()
                        .sort{|i1, i2| Anniversaries::nextDateOrdinal(i1)[0] <=> Anniversaries::nextDateOrdinal(i2)[0] }
            anniversary = LucilleCore::selectEntityFromListOfEntitiesOrNull("anniversary", anniversaries, lambda{|item| Anniversaries::toString(item) })
            return if anniversary.nil?
            Anniversaries::landing(anniversary)
        }
    end

    # Anniversaries::nx20s()
    def self.nx20s()
        Anniversaries::anniversaries().map{|item|
            {
                "announce" => Anniversaries::toString(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end