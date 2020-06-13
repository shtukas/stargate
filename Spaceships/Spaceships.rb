# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Spaceships/Spaceships.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DailyTimes.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Runner.rb"
=begin 
    Runner::isRunning?(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Links.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::value(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

# -----------------------------------------------------------------------------

class Spaceships

    # Spaceships::issueSpaceShipInteractivelyOrNull()
    def self.issueSpaceShipInteractivelyOrNull()
        cargo = Spaceships::makeCargoInteractivelyOrNull()
        return if cargo.nil?
        engine = Spaceships::makeEngineInteractivelyOrNull()
        return if engine.nil?
        Spaceships::issue(cargo, engine)
    end

    # Spaceships::issue(cargo, engine)
    def self.issue(cargo, engine)
        spaceship = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc",
            "creationUnixtime" => Time.new.to_f,
            "cargo"            => cargo,
            "engine"           => engine
        }
        NyxIO::commitToDisk(spaceship)
        spaceship
    end

    # Spaceships::spaceshipToString(spaceship)
    def self.spaceshipToString(spaceship)
        cargoFragment = lambda{|spaceship|
            cargo = spaceship["cargo"]
            if cargo["type"] == "description" then
                return " " + cargo["description"]
            end
            if cargo["type"] == "quark" then
                quark = NyxIO::getOrNull(spaceship["cargo"]["quarkuuid"])
                return quark ? (" " + Quark::quarkToString(quark)) : " [could not find quark]"
            end
            raise "[Spaceships] error: CE8497BB"
        }
        engineFragment = lambda{|spaceship|
            uuid = spaceship["uuid"]
            " (bank: #{(Bank::value(uuid).to_f/3600).round(2)} hours, time ratio: #{Spaceships::rollingTimeRatio(spaceship)})"
        }
        typeAsUserFriendly = lambda {|type|
            return " -> [] ‼️  " if type == "until-completion-high-priority-5b26f145-7ebf-4987-8091-2e78b16fa219"
            return " -> [] " if type == "until-completion-low--priority-17f86e6e-cbd3-4e83-a0f8-224c9e1a7e72"
            return " ⏱️  ‼️  " if type == "singleton-time-commitment-high-priority-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32"
            return " ⏱️ " if type == "singleton-time-commitment-low-priority-6fdd6cd7-0d1e-48da-ae62-ee2c61dfb4ea"
            return " ⛵ " if type == "on-going-commitment-weekly-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada"
        }
        uuid = spaceship["uuid"]
        isRunning = Runner::isRunning?(uuid)
        runningString = 
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "[spaceship] [#{typeAsUserFriendly.call(spaceship["engine"]["type"])}]#{cargoFragment.call(spaceship)}#{engineFragment.call(spaceship)}#{runningString}"
    end

    # Spaceships::makeCargoInteractivelyOrNull()
    def self.makeCargoInteractivelyOrNull()
        options = [
            "description",
            "quark"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("cargo type", options)
        return nil if option.nil?
        if option == "description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return {
                "type"        => "description",
                "description" => description
            }
        end
        if option == "quark" then
            quark = Quark::issueNewQuarkInteractivelyOrNull()
            return nil if quark.nil?
            description = LucilleCore::askQuestionAnswerAsString("spaceship cargo description: ")
            return {
                "type"          => "quark",
                "description"   => description,
                "quarkuuid"     => quark["uuid"]
            }
        end
        nil
    end

    # Spaceships::makeEngineInteractivelyOrNull()
    def self.makeEngineInteractivelyOrNull()
        opt5 = "until completion ‼️       ( until-completion-high-priority-5b26f145-7ebf-4987-8091-2e78b16fa219 )"
        opt1 = "until completion 🏖️       ( until-completion-low--priority-17f86e6e-cbd3-4e83-a0f8-224c9e1a7e72 )"
        opt0 = "single time commitment ‼️ ( singleton-time-commitment-high-priority-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32 )"
        opt2 = "single time commitment 🏖️ ( singleton-time-commitment-low-priority-6fdd6cd7-0d1e-48da-ae62-ee2c61dfb4ea )"
        opt3 = "on-going time commitment  ( on-going-commitment-weekly-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada )"

        options = [
            opt5,
            opt1,
            opt0,
            opt2,
            opt3,
        ]

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", options)
        return nil if option.nil?
        if option == opt5 then
            return {
                "type" => "until-completion-high-priority-5b26f145-7ebf-4987-8091-2e78b16fa219"
            }
        end
        if option == opt1 then
            return {
                "type" => "until-completion-low--priority-17f86e6e-cbd3-4e83-a0f8-224c9e1a7e72"
            }
        end
        if option == opt0 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "singleton-time-commitment-high-priority-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt2 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            return {
                "type"                  => "singleton-time-commitment-low-priority-6fdd6cd7-0d1e-48da-ae62-ee2c61dfb4ea",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        if option == opt3 then
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours per week: ").to_f
            return {
                "type"                  => "on-going-commitment-weekly-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada",
                "timeCommitmentInHours" => timeCommitmentInHours
            }
        end
        nil
    end

    # Spaceships::spaceships()
    def self.spaceships()
        NyxIO::objects("spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc")
    end

    # Spaceships::getSpaceshipsByTargetUUID(targetuuid)
    def self.getSpaceshipsByTargetUUID(targetuuid)
        Spaceships::spaceships()
            .select{|spaceship| spaceship["cargo"]["type"] == "quark" }
            .select{|spaceship| spaceship["cargo"]["quarkuuid"] == targetuuid }
    end

    # Spaceships::recargo(spaceship)
    def self.recargo(spaceship)
        cargo = Spaceships::makeCargoInteractivelyOrNull()
        return if cargo.nil?
        spaceship["cargo"] = cargo
        puts JSON.pretty_generate(spaceship)
        NyxIO::commitToDisk(spaceship)
    end

    # Spaceships::reengine(spaceship)
    def self.reengine(spaceship)
        engine = Spaceships::makeEngineInteractivelyOrNull()
        return if engine.nil?
        spaceship["engine"] = engine
        puts JSON.pretty_generate(spaceship)
        NyxIO::commitToDisk(spaceship)
    end

    # Spaceships::spaceshipDive(spaceship)
    def self.spaceshipDive(spaceship)
        loop {
            system("clear")
            puts Spaceships::spaceshipToString(spaceship).green
            options = [
                "open",
                "start",
                "stop",
                "recargo",
                "reengine",
                "destroy",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                Spaceships::openCargo(spaceship)
                if !Spaceships::isRunning?(spaceship) and LucilleCore::askQuestionAnswerAsBoolean("Would you like to start ? ") then
                    Runner::start(spaceship["uuid"])
                end
            end
            if option == "start" then
                Spaceships::spaceshipStartSequence(spaceship)
            end
            if option == "stop" then
                Spaceships::spaceshipStopSequence(spaceship)
            end
            if option == "recargo" then
                Spaceships::recargo(spaceship)
            end
            if option == "reengine" then
                Spaceships::reengine(spaceship)
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this starship ? ") then
                    Spaceships::spaceshipStopSequence(spaceship)
                    Spaceships::spaceshipDestroySequence(spaceship)
                end
                return
            end
        }
    end

    # Spaceships::rollingTimeRatio(spaceship)
    def self.rollingTimeRatio(spaceship)
        uuid = spaceship["uuid"]
        (1..7)
            .map{|i|
                timedone = Ping::totalOverTimespan(uuid, i*86400) # + Spaceships::runTimeIfAny(spaceship)
                trueTime = i*86400
                timedone.to_f/trueTime
            }
            .max
    end

    # Spaceships::metric(spaceship)
    def self.metric(spaceship)
        uuid = spaceship["uuid"]

        engine = spaceship["engine"]

        return 1 if Spaceships::isRunning?(spaceship)

        # Lucille.txt
        return 0 if (spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" and IO.read("/Users/pascal/Desktop/Lucille.txt").strip.size == 0)

        genericFormula = lambda {|spaceship, baseMetric|
            baseMetric - 0.1*Spaceships::rollingTimeRatio(spaceship) - (baseMetric-0.2)*Ping::totalWithTimeExponentialDecay(uuid, 3*3600).to_f/(3*3600)
                         # Small shift for ordering                    # bigger temporary shift to avoid staying on top
        }

        if engine["type"] == "until-completion-high-priority-5b26f145-7ebf-4987-8091-2e78b16fa219" then
            return genericFormula.call(spaceship, 0.74)
        end

        if engine["type"] == "until-completion-low--priority-17f86e6e-cbd3-4e83-a0f8-224c9e1a7e72" then
            return genericFormula.call(spaceship, 0.65)
        end

        if engine["type"] == "singleton-time-commitment-high-priority-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
            baseMetric = engine["baseMetric"] ? engine["baseMetric"] : 0.74
            return genericFormula.call(spaceship, baseMetric)
        end
 
        if engine["type"] == "singleton-time-commitment-low-priority-6fdd6cd7-0d1e-48da-ae62-ee2c61dfb4ea" then
            return genericFormula.call(spaceship, 0.65)
        end

        if engine["type"] == "on-going-commitment-weekly-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada" then
            if Ping::totalOverTimespan(uuid, 86400*7) >= engine["timeCommitmentInHours"]*86400 then
                return genericFormula.call(spaceship, 0.30)
            else
                return genericFormula.call(spaceship, 0.70)
            end
        end

        raise "[Spaceships] error: 46b84bdb"
    end

    # Spaceships::isLate?(spaceship)
    def self.isLate?(spaceship)
        uuid = spaceship["uuid"]

        engine = spaceship["engine"]

        if engine["type"] == "until-completion-high-priority-5b26f145-7ebf-4987-8091-2e78b16fa219" then
            return true
        end

        if engine["type"] == "until-completion-low--priority-17f86e6e-cbd3-4e83-a0f8-224c9e1a7e72" then
            return false
        end

        if engine["type"] == "singleton-time-commitment-high-priority-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32" then
            return true
        end

        if engine["type"] == "singleton-time-commitment-low-priority-6fdd6cd7-0d1e-48da-ae62-ee2c61dfb4ea" then
            return false
        end

        if engine["type"] == "on-going-commitment-weekly-e79bb5c2-9046-4b86-8a79-eb7dc9e2bada" then
            return Ping::totalOverTimespan(uuid, 86400*7) < engine["timeCommitmentInHours"]*86400
        end

        raise "[Spaceships] error: 46b84bdb"
    end

    # Spaceships::runTimeIfAny(spaceship)
    def self.runTimeIfAny(spaceship)
        uuid = spaceship["uuid"]
        Runner::runTimeInSecondsOrNull(uuid) || 0
    end

    # Spaceships::bankValueLive(spaceship)
    def self.bankValueLive(spaceship)
        uuid = spaceship["uuid"]
        Bank::value(uuid) + Spaceships::runTimeIfAny(spaceship)
    end

    # Spaceships::isRunning?(spaceship)
    def self.isRunning?(spaceship)
        Runner::isRunning?(spaceship["uuid"])
    end

    # Spaceships::isRunningForLong?(spaceship)
    def self.isRunningForLong?(spaceship)
        ( Runner::runTimeInSecondsOrNull(spaceship["uuid"]) || 0 ) > 3600
    end

    # Spaceships::spaceshipToCalalystObject(spaceship)
    def self.spaceshipToCalalystObject(spaceship)
        uuid = spaceship["uuid"]

        getBody = lambda{|spaceship|
            if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" then
                if Spaceships::isRunning?(spaceship) then
                    return "#{Spaceships::spaceshipToString(spaceship)}\n" + IO.read("/Users/pascal/Desktop/Lucille.txt").lines.first(10).join()
                else
                    return Spaceships::spaceshipToString(spaceship)
                end
            end
            Spaceships::spaceshipToString(spaceship)
        }

        {
            "uuid"      => uuid,
            "body"      => getBody.call(spaceship),
            "metric"    => Spaceships::metric(spaceship),
            "execute"   => lambda { Spaceships::spaceshipDive(spaceship) },
            "isFocus"   => Spaceships::isLate?(spaceship),
            "isRunning" => Spaceships::isRunning?(spaceship),
            "isRunningForLong" => Spaceships::isRunningForLong?(spaceship),
            "x-spaceship"      => spaceship
        }
    end

    # Spaceships::catalystObjects()
    def self.catalystObjects()
        if !KeyValueStore::flagIsTrue(nil, "f65f092d-4626-4aa7-bb77-9eae0592910c:#{Time.new.to_s[0, 10]}") then
            Spaceships::issue({
                    "type"        => "description",
                    "description" => "Daily Guardian Work"
                }, {
                "type"                  => "singleton-time-commitment-high-priority-7c67cb4f-77e0-4fdd-bae2-4c3aec31bb32",
                "timeCommitmentInHours" => 6,
                "baseMetric"            => 0.76
            })
            KeyValueStore::setFlagTrue(nil, "f65f092d-4626-4aa7-bb77-9eae0592910c:#{Time.new.to_s[0, 10]}")
        end

        objects = Spaceships::spaceships()
                    .map{|spaceship| Spaceships::spaceshipToCalalystObject(spaceship) }
                    .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                    .reverse
        return [] if objects.empty?
        if objects[0]["uuid"] == "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" then
            objects = objects.reject{|object| object["x-spaceship"]["engine"]["type"] == "until-completion-high-priority-5b26f145-7ebf-4987-8091-2e78b16fa219" and object["x-spaceship"]["uuid"] != "1da6ff24-e81b-4257-b533-0a9e6a5bd1e9" }
        end
        objects
    end

    # Spaceships::spaceshipStartSequence(spaceship)
    def self.spaceshipStartSequence(spaceship)
        return if Spaceships::isRunning?(spaceship)

        if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" then # Lucille.txt
            Runner::start(spaceship["uuid"])
            return
        end

        Spaceships::openCargo(spaceship)

        if LucilleCore::askQuestionAnswerAsBoolean("Carry on with starting ? ", true) then
            Runner::start(spaceship["uuid"])
        else
            if LucilleCore::askQuestionAnswerAsBoolean("Destroy ? ", false) then
                Spaceships::spaceshipStopSequence(spaceship)
                Spaceships::spaceshipDestroySequence(spaceship)
            else
                puts "Hidding this item by one hour"
                DoNotShowUntil::setUnixtime(spaceship["uuid"], Time.new.to_i+3600)
            end
        end
    end

    # Spaceships::spaceshipStopSequence(spaceship)
    def self.spaceshipStopSequence(spaceship)
        return if !Spaceships::isRunning?(spaceship)
        timespan = Runner::stop(spaceship["uuid"])
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        puts "[spaceship] Putting #{timespan.round(2)} secs into Bank (#{spaceship["uuid"]})"
        Bank::put(spaceship["uuid"], timespan)
        puts "[spaceship] Putting #{timespan.round(2)} secs into Ping (#{spaceship["uuid"]})"
        Ping::put(spaceship["uuid"], timespan)

        return if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" # Lucille.txt

        if LucilleCore::askQuestionAnswerAsBoolean("Destroy ? ", false) then
            NyxIO::destroy(spaceship["uuid"])
        end
    end

    # Spaceships::spaceshipDestroySequence(spaceship)
    def self.spaceshipDestroySequence(spaceship)
        if spaceship["uuid"] == "90b4de62-664a-484c-9b8f-459dcab551d4" then
            puts "You cannot destroy this one (Lucille.txt)"
            LucilleCore::pressEnterToContinue()
            return
        end
        NyxIO::destroy(spaceship["uuid"])
    end

    # Spaceships::openCargo(spaceship)
    def self.openCargo(spaceship)
        if spaceship["cargo"]["type"] == "quark" then
            quark = NyxIO::getOrNull(spaceship["cargo"]["quarkuuid"])
            return if quark.nil?
            Quark::openQuark(quark)
        end
    end
end

