
class Waves

    # --------------------------------------------------
    # IO

    # Waves::items()
    def self.items()
        Librarian::getObjectsByMikuType("Wave")
    end

    # Waves::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        Librarian::getObjectsByMikuTypeAndUniverse("Wave", universe)
    end

    # Waves::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Making

    # Waves::makeScheduleParametersInteractivelyOrNull() # [type, value]
    def self.makeScheduleParametersInteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntitiesOrNull("schedule type: ", scheduleTypes)

        return nil if scheduleType.nil?

        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            return ["sticky", fromHour]
        end

        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            return nil if type.nil?

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
                return [type, value]
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
                return [type, value]
            end
        end
        raise "e45c4622-4501-40e1-a44e-2948544df256"
    end

    # Waves::computeNextShowUp(item)
    def self.computeNextShowUp(item)
        if item["repeatType"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) - 86400) + item["repeatValue"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + item["repeatValue"].to_i*3600
        end
        if item["repeatType"] == 'every-n-hours' then
            return Time.new.to_i+3600 * item["repeatValue"].to_f
        end
        if item["repeatType"] == 'every-n-days' then
            return Time.new.to_i+86400 * item["repeatValue"].to_f
        end
        if item["repeatType"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != item["repeatValue"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if item["repeatType"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != item["repeatValue"] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleString(item)
    def self.scheduleString(item)
        if item["repeatType"] == 'sticky' then
            return "sticky, from: #{item["repeatValue"]}"
        end
        "#{item["repeatType"]}: #{item["repeatValue"]}"
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        return nil if schedule.nil?

        wave = {
            "uuid"        => uuid,
            "mikuType"    => "Wave",
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "i1as"        => [nx111],
        }

        wave["repeatType"]       = schedule[0]
        wave["repeatValue"]      = schedule[1]
        wave["lastDoneDateTime"] = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"

        Librarian::commit(wave)
        wave
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::toString(item)
    def self.toString(item)
        lastDoneDateTime = item["lastDoneDateTime"] || "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"
        ago = "#{((Time.new.to_i - DateTime.parse(lastDoneDateTime).to_time.to_i).to_f/86400).round(2)} days ago"
        "(wave) #{item["description"]} (#{I1as::toStringShort(item["i1as"])}) (#{Waves::scheduleString(item)}) (#{ago}) (#{item["universe"]})"
    end

    # Waves::performDone(item)
    def self.performDone(item)
        puts "done-ing: #{Waves::toString(item)}"
        item["lastDoneDateTime"] = Time.now.utc.iso8601
        Librarian::commit(item)

        unixtime = Waves::computeNextShowUp(item)
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # Waves::landing(item)
    def self.landing(item)
        uuid = item["uuid"]

        loop {

            system("clear")

            store = ItemStore.new()

            uuid = item["uuid"]

            puts "#{Waves::toString(item)}".green

            puts "uuid: #{item["uuid"]}".yellow

            puts "i1as:"
            item["i1as"].each{|nx111|
                puts "    #{Nx111::toString(nx111)}"
            } 

            puts "schedule: #{Waves::scheduleString(item)}".yellow
            puts "last done: #{item["lastDoneDateTime"]}".yellow
            puts "DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts ""

            puts "access | done | <datecode> | description | iam | note | schedule | universe | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if command == "access" then
                EditionDesk::accessItem(item)
                next
            end

            if command == "done" then
                Waves::performDone(item)
                break
            end

            if (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("description", command) then
                item["description"] = CommonUtils::editTextSynchronously(item["description"])
                Librarian::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                item = I1as::manageI1as(item, item["i1as"])
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("schedule", command) then
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                item["repeatType"] = schedule[0]
                item["repeatValue"] = schedule[1]
                Librarian::commit(item)
                next
            end

            if Interpreting::match("universe", command) then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                next
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this wave ? : ") then
                    Waves::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # -------------------------------------------------------------------------
    # Waves

    # Waves::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Waves::items().sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::waves()
    def self.waves()
        loop {
            system("clear")
            wave = Waves::selectWaveOrNull()
            return if wave.nil?
            Waves::landing(wave)
        }
    end

    # -------------------------------------------------------------------------
    # NS16

    # Waves::access(item)
    def self.access(item)
        system("clear")
        uuid = item["uuid"]
        puts Waves::toString(item)
        puts "Starting at #{Time.new.to_s}"

        EditionDesk::accessItem(item)

        loop {
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["done (default)", "landing", "exit"])

            if operation.nil? or operation == "done (default)" then
                Waves::performDone(item)
                NxBallsService::close(uuid, true)
                break
            end
            if operation == "landing" then
                Waves::landing(item)

                # the landing could result in a destruction of the object
                if Librarian::getObjectByUUIDOrNull(item["uuid"]).nil? then
                    break
                end
            end
            if operation == "exit" then
                NxBallsService::close(uuid, true)
                break
            end
        }
    end

    # Waves::toNS16(wave)
    def self.toNS16(wave)
        uuid = wave["uuid"]
        {
            "uuid"       => uuid,
            "mikuType"   => "NS16:Wave",
            "announce"   => Waves::toString(wave),
            "wave"       => wave
        }
    end

    # Waves::ns16s(universe)
    def self.ns16s(universe)
        Librarian::getObjectsByMikuTypeAndPossiblyNullUniverse("Wave", universe)
            .select{|wave| DoNotShowUntil::isVisible(wave["uuid"]) }
            .select{|wave| InternetStatus::ns16ShouldShow(wave["uuid"]) }
            .map{|wave| Waves::toNS16(wave) }
            .sort{|n1, n2| n1["wave"]["lastDoneDateTime"] <=> n2["wave"]["lastDoneDateTime"] }
    end

    # Waves::nx20s()
    def self.nx20s()
        Waves::items().map{|item|
            {
                "announce" => Waves::toString(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
