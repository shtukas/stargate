#!/usr/bin/ruby

# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# This subsystem entire purpose is to receive commands from the user and either:
	# The command is "special" and going to be captured and executed at some point along the code
	# The command is handled by an agent and the signal forwarded to the NSXCatalystObjectsOperator

class NSXGeneralCommandHandler

    # NSXGeneralCommandHandler::putshelp()
    def self.putshelp()
        puts "Special General Commands"
        puts "    help"
        puts "    :<p>        # set the listing reference point"
        puts "    +           # add 1 to the standard listing position"
        puts ""
        puts "    /           # menu of commands"
        puts "    search: <pattern>"
        puts "    require: <name> # set the focus object against that requirement"
        puts "    requirement: <name> # release all the objects against that requirement"
        puts "    line: <line> # new Important Item"
        puts ""
    end

    # NSXGeneralCommandHandler::specialObjectCommandsAsString()
    def self.specialObjectCommandsAsString()
        "Special Object Commands : .. ,, ;; +datetimecode, +<weekdayname>, +<integer>day(s), +<integer>hour(s), +YYYY-MM-DD, expose"
    end

    # NSXGeneralCommandHandler::interactiveMakeNewStreamItem()
    def self.interactiveMakeNewStreamItem()
        description = LucilleCore::askQuestionAnswerAsString("description (can use 'text') or url: ")
        description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
        return if lightThread.nil?
        genericContentsItem = 
            if description.start_with?("http") then
                NSXGenericContents::issueItemURL(description)
            else
                NSXGenericContents::issueItemText(description)
            end
        streamItem = NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(lightThread["streamuuid"], genericContentsItem)
        puts JSON.pretty_generate(streamItem)
    end

    # NSXGeneralCommandHandler::processCommand(object, command)
    def self.processCommand(object, command)

        # no object needed

        if command == 'help' then
            NSXGeneralCommandHandler::putshelp()
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "+" then
            NSXMiscUtils::setStandardListingPosition(NSXMiscUtils::getStandardListingPosition()+1)
            return
        end

        if command == "/" then
            options = [
                "view LightThreads",
                "issue floating",
                "remove floating",                
                "new wave (repeat item)", 
                "new Stream Item", 
                "new LightThread",
                "email-sync",
                "speed"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option:", options)
            return if option.nil?
            if option == "issue floating" then
                NSXFloatings::issueFloating(LucilleCore::askQuestionAnswerAsString("description: "))
            end
            if option == "remove floating" then
                NSXFloatings::interactivelySelectAndRemoveOneFloating()
            end
            if option == "new wave (repeat item)" then
                description = LucilleCore::askQuestionAnswerAsString("description (can use 'text'): ")
                NSXMiscUtils::spawnNewWaveItem(description)
            end
            if option == "new Stream Item" then
                NSXGeneralCommandHandler::interactiveMakeNewStreamItem()
            end
            if option == "new LightThread" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                priorityXp = NSXLightThreadUtils::lightThreadPriorityXPPickerOrNull()
                if priorityXp.nil? then
                    puts "You have not provided a priority. Aborting."
                    LucilleCore::pressEnterToContinue()
                    return
                end
                lightThread = NSXLightThreadUtils::makeNewLightThread(description, priorityXp)
                puts JSON.pretty_generate(lightThread)
            end
            if option == "view LightThreads" then
                NSXLightThreadUtils::lightThreadsDive()
            end
            if option == "email-sync" then
                NSXMiscUtils::emailSync(true)
            end
            if option == "speed" then
                puts "Agents Speed Report"
                NSXBob::agents()
                    .map{|agentinterface| 
                        startTime = Time.new.to_f
                        agentinterface["get-objects"].call()
                        endTime = Time.new.to_f
                        timeSpanInSeconds = endTime - startTime
                        [ agentinterface["agent-name"], timeSpanInSeconds ]
                    }
                    .sort{|p1, p2| p1[1] <=> p2[1] }
                    .reverse
                    .each{|pair|
                        agentName = pair[0]
                        timeSpanInSeconds = pair[1]
                        puts "  - #{agentName}: #{timeSpanInSeconds.round(2)}"
                    }
                LucilleCore::pressEnterToContinue()
            end
            return
        end

        if command.start_with?(":") then
            if NSXMiscUtils::isInteger(command[1, command.size]) then
                position = command[1, command.size].strip.to_i
                NSXMiscUtils::setStandardListingPosition([position, 0].max)
            end
            return
        end

        if command.start_with?("line:") then
            description = command[5, command.size].strip
            genericContentsItem = 
                if description.start_with?("http") then
                    NSXGenericContents::issueItemURL(description)
                else
                    NSXGenericContents::issueItemText(description)
                end
            streamItem = NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem("03b79978bcf7a712953c5543a9df9047", genericContentsItem) # Must All Be Done Today
            puts JSON.pretty_generate(streamItem)
            return
        end

        if command.start_with?("require:") then
            requirementDescription = command[8, command.size].strip
            NSXRequirements::issueRequirementClaim(object["uuid"], requirementDescription)
            return
        end

        if command.start_with?("requirement:") then
            requirementDescription = command[12, command.size].strip
            NSXRequirements::removeClaimsOnDiskIdentifiedByDescription(requirementDescription)
            return
        end

        if command.start_with?("search:") then
            pattern = command[7,command.size].strip
            loop {
                searchobjects1 = NSXCatalystObjectsOperator::getObjects().select{|object| object["uuid"].downcase.include?(pattern.downcase) }
                searchobjects2 = NSXCatalystObjectsOperator::getObjects().select{|object| NSXMiscUtils::objectToOneLineForCatalystDisplay(object).downcase.include?(pattern.downcase) }                
                searchobjects = searchobjects1 + searchobjects2
                break if searchobjects.size==0
                selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", searchobjects, lambda{ |object| NSXMiscUtils::objectToOneLineForCatalystDisplay(object) })
                break if selectedobject.nil?
                NSXDisplayOperator::doPresentObjectInviteAndExecuteCommand(selectedobject)
            }
            return
        end

        return if object.nil?

        # object needed

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command.start_with?('+') then
            code = command
            if (datetime = NSXMiscUtils::codeToDatetimeOrNull(code)) then
                NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
            end
            return
        end
        
        if object["agent-uid"] then
            command.split(";").map{|t| t.strip }
                .each{|command|
                    NSXBob::getAgentDataByAgentUUIDOrNull(object["agent-uid"])["object-command-processor"].call(object, command)
                }
        end
    end

end